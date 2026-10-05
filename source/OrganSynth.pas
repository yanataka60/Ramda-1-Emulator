unit OrganSynth;
interface
const
  OrganSampleRate = 48000;
  OrganCPUHz = 1000000;
  OrganFrequencies: array[0..7] of Integer = (262,294,330,349,392,440,494,523);
type
  TOrganSynth = class
  private
    FConnected: Boolean;
    FPins, FManual, FGate: Byte;
    FPhase: array[0..7] of Integer;
    FClockRemainder: Int64;
    FBuffer: array[0..95999] of SmallInt;
    FRead, FWrite, FCount: Integer;
    FPreviousInput, FPreviousOutput: Double;
    procedure UpdateGates;
    function MakeSample: SmallInt;
    procedure Append(Value: SmallInt);
  public
    constructor Create;
    procedure SetConnected(Value: Boolean);
    procedure SetPortPins(Value: Byte);
    procedure SetManualMask(Value: Byte);
    procedure Advance(Cycles: Integer);
    function ReadSamples(var Samples; Count: Integer): Integer;
    procedure ClearPending;
    property Connected: Boolean read FConnected;
    property GateMask: Byte read FGate;
    property ManualMask: Byte read FManual;
    property PendingSamples: Integer read FCount;
  end;
implementation
constructor TOrganSynth.Create;
begin
  inherited;
  FPins := $FF;
  { All disabled NAND oscillator outputs settle high. Seed the AC coupling
    filter at that DC level to avoid an artificial power-up audio impulse. }
  FPreviousInput := 12000;
end;
procedure TOrganSynth.UpdateGates;
var Pins: Byte;
begin
  Pins := $FF;
  if FConnected then Pins := FPins;
  { Fig.7: NAND(PIA pin, manual key pulled high). A LOW from either starts OSC. }
  FGate := (not Pins) or FManual;
end;
procedure TOrganSynth.SetConnected(Value: Boolean);
begin FConnected:=Value;UpdateGates end;
procedure TOrganSynth.SetPortPins(Value: Byte);
begin FPins:=Value;UpdateGates end;
procedure TOrganSynth.SetManualMask(Value: Byte);
begin FManual:=Value;UpdateGates end;
function TOrganSynth.MakeSample: SmallInt;
const
  { C9=10uF, eight 470k summing resistors and nominal 50k volume load.
    This models ideal AC coupling; CMOS thresholds and amplifier are not simulated. }
  ACDecay = 0.999980843095071;
var I, Sum: Integer; V: Double;
begin
  Sum := 0;
  for I:=0 to 7 do
  begin
    if (FGate and (1 shl I))=0 then
    begin FPhase[I]:=0; Inc(Sum,1500) end
    else begin
      if FPhase[I]<OrganSampleRate div 2 then Inc(Sum,1500)
      else Dec(Sum,1500);
      Inc(FPhase[I],OrganFrequencies[I]);
      if FPhase[I]>=OrganSampleRate then Dec(FPhase[I],OrganSampleRate);
    end;
  end;
  { Equal resistors: constant gain per oscillator, never normalize by voice count. }
  V := ACDecay * (FPreviousOutput + Sum - FPreviousInput);
  FPreviousInput := Sum; FPreviousOutput := V;
  if V>32767 then Result:=32767
  else if V< -32768 then Result:=-32768 else Result:=Round(V);
end;
procedure TOrganSynth.Append(Value: SmallInt);
begin
  if FCount=Length(FBuffer) then
  begin FRead:=(FRead+1) mod Length(FBuffer); Dec(FCount) end;
  FBuffer[FWrite]:=Value;FWrite:=(FWrite+1) mod Length(FBuffer);Inc(FCount);
end;
procedure TOrganSynth.Advance(Cycles: Integer);
var Count: Int64;
begin
  if Cycles<=0 then Exit;
  Inc(FClockRemainder,Int64(Cycles)*OrganSampleRate);
  Count:=FClockRemainder div OrganCPUHz;
  FClockRemainder:=FClockRemainder mod OrganCPUHz;
  while Count>0 do begin Append(MakeSample);Dec(Count) end;
end;
function TOrganSynth.ReadSamples(var Samples; Count: Integer): Integer;
var I: Integer; P: PSmallInt;
begin
  Result:=Count;if Result>FCount then Result:=FCount;
  if Result<0 then Result:=0;
  P:=@Samples;
  for I:=0 to Result-1 do
  begin P^:=FBuffer[FRead];Inc(P);FRead:=(FRead+1) mod Length(FBuffer) end;
  Dec(FCount,Result);
end;
procedure TOrganSynth.ClearPending;
begin FRead:=0;FWrite:=0;FCount:=0 end;
end.
