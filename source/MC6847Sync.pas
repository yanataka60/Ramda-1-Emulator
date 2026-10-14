unit MC6847Sync;

interface

type
  { MC6847 field-sync pin only. This is independent of the CPU and GUI paint. }
  TMC6847Sync = class
  private
    FCounterFrequency, FLastCounter, FFraction, FHalfClocks: Int64;
  public
    constructor Create(CounterFrequency, InitialCounter: Int64);
    procedure AdvanceTo(Counter: Int64);
    function FSHigh: Boolean;
  end;

implementation

const
  VDG_HALF_CLOCK_HZ = 7159090; { 2 * 3.579545 MHz }
  HALF_CLOCKS_PER_LINE = 455; { 227.5 crystal clocks }
  FIELD_HALF_CLOCKS = 262 * HALF_CLOCKS_PER_LINE;
  FS_LOW_HALF_CLOCKS = 32 * HALF_CLOCKS_PER_LINE;

constructor TMC6847Sync.Create(CounterFrequency, InitialCounter: Int64);
begin
  inherited Create;
  FCounterFrequency := CounterFrequency;
  FLastCounter := InitialCounter;
  FFraction := 0;
  FHalfClocks := 0; { arbitrary power-on phase, beginning of FS low }
end;

procedure TMC6847Sync.AdvanceTo(Counter: Int64);
var Delta, Seconds, Part, Numerator, Clocks: Int64;
begin
  Delta := Counter - FLastCounter;
  if Delta <= 0 then Exit;
  FLastCounter := Counter;
  Seconds := Delta div FCounterFrequency;
  Part := Delta mod FCounterFrequency;
  { Reduce whole seconds before multiplication, to avoid long-uptime overflow.
    Windows QPC frequency is well within Int64's bound for Part * 7159090. }
  Clocks := ((Seconds mod FIELD_HALF_CLOCKS) * VDG_HALF_CLOCK_HZ)
            mod FIELD_HALF_CLOCKS;
  Numerator := Part * Int64(VDG_HALF_CLOCK_HZ) + FFraction;
  Clocks := Clocks + Numerator div FCounterFrequency;
  FFraction := Numerator mod FCounterFrequency;
  FHalfClocks := (FHalfClocks + Clocks) mod FIELD_HALF_CLOCKS;
end;

function TMC6847Sync.FSHigh: Boolean;
begin
  Result := FHalfClocks >= FS_LOW_HALF_CLOCKS;
end;

end.
