unit MC6821Expansion;
interface
type
  TC2Event = procedure(HighLevel:Boolean) of object;
  TExpansionPort = class
  private
    FIsB:Boolean;
    FDDR,FOutput,FControl,FInputs:Byte;
    FC1,FC2Input,FC2Output,FIRQ1,FIRQ2:Boolean;
    FPulseCycles:Integer;
    FOnC2:TC2Event;
    procedure DriveC2(HighLevel:Boolean);
    procedure Strobe;
  public
    constructor Create(IsB:Boolean);
    procedure Reset;
    function ReadData:Byte;
    function ReadControl:Byte;
    procedure WriteData(Value:Byte);
    procedure WriteControl(Value:Byte);
    procedure SetC1(HighLevel:Boolean);
    procedure SetC2Input(HighLevel:Boolean);
    procedure Advance(Cycles:Integer);
    function OutputPins:Byte;
    function IRQHigh:Boolean;
    property Inputs:Byte read FInputs write FInputs;
    property C2Output:Boolean read FC2Output;
    property OnC2:TC2Event read FOnC2 write FOnC2;
  end;
  TMC6821Expansion = class
  public
    PortA,PortB:TExpansionPort;
    constructor Create;
    destructor Destroy;override;
    procedure Reset;
    function ReadRegister(Offset:Byte):Byte;
    procedure WriteRegister(Offset,Value:Byte);
    procedure Advance(Cycles:Integer);
  end;
implementation
constructor TExpansionPort.Create(IsB:Boolean);
begin inherited Create;FIsB:=IsB;FInputs:=$FF;FC1:=True;FC2Input:=True;FC2Output:=True;Reset end;
procedure TExpansionPort.Reset;
begin FDDR:=0;FOutput:=0;FControl:=0;FIRQ1:=False;FIRQ2:=False;FPulseCycles:=0;FC2Output:=True end;
procedure TExpansionPort.DriveC2(HighLevel:Boolean);
begin
 if FC2Output=HighLevel then Exit;
 FC2Output:=HighLevel;
 if Assigned(FOnC2) then FOnC2(HighLevel);
end;
procedure TExpansionPort.Strobe;
begin
 if (FControl and $30)<>$20 then Exit;
 DriveC2(False);
 if (FControl and $08)<>0 then FPulseCycles:=1;
end;
function TExpansionPort.OutputPins:Byte;
begin Result:=(FOutput and FDDR) or (FInputs and not FDDR) end;
function TExpansionPort.IRQHigh:Boolean;
begin Result:=not ((FIRQ1 and ((FControl and 1)<>0)) or
 (FIRQ2 and ((FControl and $20)=0) and ((FControl and 8)<>0))) end;
function TExpansionPort.ReadData:Byte;
begin
 if (FControl and 4)=0 then Exit(FDDR);
 Result:=OutputPins;
 FIRQ1:=False;FIRQ2:=False;
 if not FIsB then Strobe;
end;
function TExpansionPort.ReadControl:Byte;
begin Result:=FControl;if FIRQ1 then Result:=Result or $80;
 if FIRQ2 and ((FControl and $20)=0) then Result:=Result or $40 end;
procedure TExpansionPort.WriteData(Value:Byte);
begin
 if (FControl and 4)=0 then FDDR:=Value
 else begin FOutput:=Value;if FIsB then Strobe end;
end;
procedure TExpansionPort.WriteControl(Value:Byte);
var OldMode:Byte;
begin
 OldMode:=FControl and $38;FControl:=Value and $3F;
 if (FControl and $20)<>0 then begin
  FIRQ2:=False;
  if (FControl and $10)<>0 then begin FPulseCycles:=0;DriveC2((FControl and 8)<>0) end
  else if OldMode<>(FControl and $38) then begin FPulseCycles:=0;DriveC2(True) end;
 end else begin FPulseCycles:=0;FC2Output:=True end;
end;
procedure TExpansionPort.SetC1(HighLevel:Boolean);
var WasFlag:Boolean;
begin
 if FC1=HighLevel then Exit;FC1:=HighLevel;
 if HighLevel=((FControl and 2)<>0) then begin
  WasFlag:=FIRQ1;FIRQ1:=True;
  { Motorola Fig.18: CB1 restore requires IRQB1 cleared by a data read first. }
  if ((FControl and $38)=$20) and (not FIsB or not WasFlag) then DriveC2(True);
 end;
end;
procedure TExpansionPort.SetC2Input(HighLevel:Boolean);
begin
 if FC2Input=HighLevel then Exit;FC2Input:=HighLevel;
 if ((FControl and $20)=0) and (HighLevel=((FControl and $10)<>0)) then FIRQ2:=True;
end;
procedure TExpansionPort.Advance(Cycles:Integer);
begin
 if (Cycles<=0) or (FPulseCycles=0) then Exit;
 Dec(FPulseCycles,Cycles);if FPulseCycles<=0 then begin FPulseCycles:=0;DriveC2(True) end;
end;
constructor TMC6821Expansion.Create;
begin inherited Create;PortA:=TExpansionPort.Create(False);PortB:=TExpansionPort.Create(True) end;
destructor TMC6821Expansion.Destroy;
begin PortB.Free;PortA.Free;inherited end;
procedure TMC6821Expansion.Reset;
begin PortA.Reset;PortB.Reset end;
function TMC6821Expansion.ReadRegister(Offset:Byte):Byte;
begin case Offset and 3 of 0:Result:=PortA.ReadData;1:Result:=PortA.ReadControl;
 2:Result:=PortB.ReadData;else Result:=PortB.ReadControl end end;
procedure TMC6821Expansion.WriteRegister(Offset,Value:Byte);
begin case Offset and 3 of 0:PortA.WriteData(Value);1:PortA.WriteControl(Value);
 2:PortB.WriteData(Value);3:PortB.WriteControl(Value) end end;
procedure TMC6821Expansion.Advance(Cycles:Integer);
begin PortA.Advance(Cycles);PortB.Advance(Cycles) end;
end.
