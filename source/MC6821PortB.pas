unit MC6821PortB;

interface

type
  TPIAIRQEvent = procedure(HighLevel: Boolean) of object;
  { Port B register/input/IRQB model. CB2 output handshake timing is outside
    this unit's scope; output mode disables CB2 as an interrupt input. }
  TMC6821PortB = class
  private
    FDDR, FORB, FCRB, FInputPins: Byte;
    FCB1High, FCB2High, FIRQ1, FIRQ2, FIRQBHigh: Boolean;
    FOnIRQB: TPIAIRQEvent;
    procedure UpdateIRQB;
  public
    constructor Create;
    procedure Reset;
    function ReadData: Byte;
    function ReadControl: Byte;
    procedure WriteData(Value: Byte);
    procedure WriteControl(Value: Byte);
    procedure SetCB1Level(HighLevel: Boolean);
    procedure SetCB2Level(HighLevel: Boolean);
    function OutputPins: Byte;
    property DDR: Byte read FDDR;
    property InputPins: Byte read FInputPins write FInputPins;
    property IRQBHigh: Boolean read FIRQBHigh;
    property OnIRQB: TPIAIRQEvent read FOnIRQB write FOnIRQB;
  end;

implementation

function TMC6821PortB.OutputPins: Byte;
begin Result := (FORB and FDDR) or ($FF and not FDDR) end;

constructor TMC6821PortB.Create;
begin
  inherited Create;
  FIRQBHigh := True;
  FCB1High := True;
  FCB2High := True;
  FInputPins := $FF;
  Reset;
end;

procedure TMC6821PortB.Reset;
begin
  { RESET clears registers, not levels supplied by external circuitry. }
  FDDR := 0; FORB := 0; FCRB := 0;
  FIRQ1 := False; FIRQ2 := False;
  UpdateIRQB;
end;

procedure TMC6821PortB.UpdateIRQB;
var HighLevel: Boolean;
begin
  HighLevel := not ((FIRQ1 and ((FCRB and $01) <> 0)) or
    (FIRQ2 and ((FCRB and $20) = 0) and ((FCRB and $08) <> 0)));
  if HighLevel <> FIRQBHigh then begin
    FIRQBHigh := HighLevel;
    if Assigned(FOnIRQB) then FOnIRQB(HighLevel);
  end;
end;

function TMC6821PortB.ReadData: Byte;
begin
  if (FCRB and $04) = 0 then Result := FDDR
  else begin
    Result := (FORB and FDDR) or (FInputPins and not FDDR);
    FIRQ1 := False;
    FIRQ2 := False;
    UpdateIRQB;
  end;
end;

function TMC6821PortB.ReadControl: Byte;
begin
  Result := FCRB;
  if FIRQ1 then Result := Result or $80;
  if FIRQ2 and ((FCRB and $20) = 0) then Result := Result or $40;
end;

procedure TMC6821PortB.WriteData(Value: Byte);
begin
  if (FCRB and $04) = 0 then FDDR := Value else FORB := Value;
end;

procedure TMC6821PortB.WriteControl(Value: Byte);
begin
  FCRB := Value and $3F;
  UpdateIRQB; { recompute for enable AND input/output mode changes }
end;

procedure TMC6821PortB.SetCB1Level(HighLevel: Boolean);
begin
  if HighLevel = FCB1High then Exit;
  FCB1High := HighLevel;
  if HighLevel = ((FCRB and $02) <> 0) then FIRQ1 := True;
  UpdateIRQB;
end;

procedure TMC6821PortB.SetCB2Level(HighLevel: Boolean);
begin
  if HighLevel = FCB2High then Exit;
  FCB2High := HighLevel;
  if ((FCRB and $20) = 0) and
     (HighLevel = ((FCRB and $10) <> 0)) then FIRQ2 := True;
  UpdateIRQB;
end;

end.
