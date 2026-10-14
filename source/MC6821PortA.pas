unit MC6821PortA;

interface

type
  TPIAIRQEvent = procedure(HighLevel: Boolean) of object;
  { Port A register/input/IRQA model. CA2 output handshake timing is outside
    this unit's scope; output mode disables CA2 as an interrupt input. }
  TMC6821PortA = class
  private
    FDDR, FORA, FCRA, FInputPins: Byte;
    FCA1High, FCA2High, FIRQ1, FIRQ2, FIRQAHigh: Boolean;
    FOnIRQA: TPIAIRQEvent;
    procedure UpdateIRQA;
  public
    constructor Create;
    procedure Reset;
    function ReadData: Byte;
    function ReadControl: Byte;
    procedure WriteData(Value: Byte);
    procedure WriteControl(Value: Byte);
    procedure SetCA1Level(HighLevel: Boolean);
    procedure SetCA2Level(HighLevel: Boolean);
    property InputPins: Byte read FInputPins write FInputPins;
    property IRQAHigh: Boolean read FIRQAHigh;
    property OnIRQA: TPIAIRQEvent read FOnIRQA write FOnIRQA;
  end;

implementation

constructor TMC6821PortA.Create;
begin
  inherited Create;
  FIRQAHigh := True;
  FCA1High := True;
  FCA2High := True;
  FInputPins := $FF;
  Reset;
end;

procedure TMC6821PortA.Reset;
begin
  { RESET clears registers, not levels supplied by external circuitry. }
  FDDR := 0; FORA := 0; FCRA := 0;
  FIRQ1 := False; FIRQ2 := False;
  UpdateIRQA;
end;

procedure TMC6821PortA.UpdateIRQA;
var HighLevel: Boolean;
begin
  HighLevel := not ((FIRQ1 and ((FCRA and $01) <> 0)) or
    (FIRQ2 and ((FCRA and $20) = 0) and ((FCRA and $08) <> 0)));
  if HighLevel <> FIRQAHigh then begin
    FIRQAHigh := HighLevel;
    if Assigned(FOnIRQA) then FOnIRQA(HighLevel);
  end;
end;

function TMC6821PortA.ReadData: Byte;
begin
  if (FCRA and $04) = 0 then Result := FDDR
  else begin
    Result := (FORA and FDDR) or (FInputPins and not FDDR);
    FIRQ1 := False;
    FIRQ2 := False;
    UpdateIRQA;
  end;
end;

function TMC6821PortA.ReadControl: Byte;
begin
  Result := FCRA;
  if FIRQ1 then Result := Result or $80;
  if FIRQ2 and ((FCRA and $20) = 0) then Result := Result or $40;
end;

procedure TMC6821PortA.WriteData(Value: Byte);
begin
  if (FCRA and $04) = 0 then FDDR := Value else FORA := Value;
end;

procedure TMC6821PortA.WriteControl(Value: Byte);
begin
  FCRA := Value and $3F;
  UpdateIRQA; { recompute for enable AND input/output mode changes }
end;

procedure TMC6821PortA.SetCA1Level(HighLevel: Boolean);
begin
  if HighLevel = FCA1High then Exit;
  FCA1High := HighLevel;
  if HighLevel = ((FCRA and $02) <> 0) then FIRQ1 := True;
  UpdateIRQA;
end;

procedure TMC6821PortA.SetCA2Level(HighLevel: Boolean);
begin
  if HighLevel = FCA2High then Exit;
  FCA2High := HighLevel;
  if ((FCRA and $20) = 0) and
     (HighLevel = ((FCRA and $10) <> 0)) then FIRQ2 := True;
  UpdateIRQA;
end;

end.
