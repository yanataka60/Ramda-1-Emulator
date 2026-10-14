unit OrganAudio;
interface
uses Winapi.Windows, Winapi.MMSystem, OrganSynth;
type
  TOrganAudio = class
  private
    FHandle: HWAVEOUT;
    FHeaders: array[0..5] of TWaveHdr;
    FBuffers: array[0..5,0..479] of SmallInt;
    FPrepared: array[0..5] of Boolean;
    FResult: MMRESULT;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Pump(Synth: TOrganSynth);
    property LastResult: MMRESULT read FResult;
    function Active: Boolean;
  end;
implementation
constructor TOrganAudio.Create;
var Format: TWaveFormatEx;
begin
 inherited;
 FillChar(Format,SizeOf(Format),0);
 Format.wFormatTag:=WAVE_FORMAT_PCM;Format.nChannels:=1;
 Format.nSamplesPerSec:=OrganSampleRate;Format.wBitsPerSample:=16;
 Format.nBlockAlign:=2;Format.nAvgBytesPerSec:=OrganSampleRate*2;
 FResult:=waveOutOpen(@FHandle,WAVE_MAPPER,@Format,0,0,CALLBACK_NULL);
 if FResult<>MMSYSERR_NOERROR then FHandle:=0;
end;
function TOrganAudio.Active:Boolean;
begin Result:=FHandle<>0 end;
procedure TOrganAudio.Pump(Synth:TOrganSynth);
var I:Integer;
begin
 if not Active then begin Synth.ClearPending;Exit end;
 for I:=0 to High(FHeaders) do
 begin
  if FPrepared[I] and ((FHeaders[I].dwFlags and WHDR_DONE)<>0) then
   if waveOutUnprepareHeader(FHandle,@FHeaders[I],SizeOf(TWaveHdr))=MMSYSERR_NOERROR then
    FPrepared[I]:=False;
  if (not FPrepared[I]) and (Synth.PendingSamples>=Length(FBuffers[I])) then
  begin
   Synth.ReadSamples(FBuffers[I],Length(FBuffers[I]));
   FillChar(FHeaders[I],SizeOf(TWaveHdr),0);
   FHeaders[I].lpData:=PAnsiChar(@FBuffers[I,0]);
   FHeaders[I].dwBufferLength:=SizeOf(FBuffers[I]);
   FResult:=waveOutPrepareHeader(FHandle,@FHeaders[I],SizeOf(TWaveHdr));
   if FResult=MMSYSERR_NOERROR then
   begin
    FPrepared[I]:=True;
    FResult:=waveOutWrite(FHandle,@FHeaders[I],SizeOf(TWaveHdr));
    if FResult<>MMSYSERR_NOERROR then
    begin
     waveOutUnprepareHeader(FHandle,@FHeaders[I],SizeOf(TWaveHdr));FPrepared[I]:=False;
    end;
   end;
  end;
 end;
end;
destructor TOrganAudio.Destroy;
var I:Integer;
begin
 if Active then
 begin
  waveOutReset(FHandle);
  for I:=0 to High(FHeaders) do
   if FPrepared[I] then waveOutUnprepareHeader(FHandle,@FHeaders[I],SizeOf(TWaveHdr));
  waveOutClose(FHandle);
 end;
 inherited;
end;
end.
