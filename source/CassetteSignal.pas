unit CassetteSignal;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses SysUtils,Classes,Math;
type
 TCassetteLevelEvent=procedure(HighLevel:Boolean) of object;
 TSignalEdge=record Cycle:Int64; HighLevel:Boolean end;
 TCassetteSignal=class
 private
  FCPUHz:Integer; FSampleRate:Integer; FSamples:array of SmallInt;
  FPosition:Integer; FPhase:Int64; FMotor,FPlaying,FRecording,FOutputHigh,FInputHigh,FInvert:Boolean;
  FTransportGeneration:Cardinal;
  FResumeOnMotor:Boolean; FRecordCycles:Int64; FEdges:array of TSignalEdge; FOnInput:TCassetteLevelEvent;
  procedure SetInput(HighLevel:Boolean);
 public
  constructor Create;
  procedure LoadWav(const FileName:string);
  procedure Play; procedure StopPlayback; procedure PausePlayback; procedure Rewind;
  procedure ArmRecording; procedure CancelRecording;
  procedure SaveRecording(const FileName:string);
  procedure SetMotor(OnState:Boolean);
  procedure SetOutput(HighLevel:Boolean);
  procedure Advance(Cycles:Integer);
  property CPUHz:Integer read FCPUHz;
  property InvertPlayback:Boolean read FInvert write FInvert;
  property OnInput:TCassetteLevelEvent read FOnInput write FOnInput;
  property InputHigh:Boolean read FInputHigh;
  property Motor:Boolean read FMotor;
  property Playing:Boolean read FPlaying;
  function TransportReady:Boolean;
  property TransportGeneration:Cardinal read FTransportGeneration;
  property Recording:Boolean read FRecording;
  property Position:Integer read FPosition;
  function DurationSeconds:Double;
  function PositionSeconds:Double;
  function RecordingSeconds:Double;
 end;
implementation
constructor TCassetteSignal.Create;
begin inherited;FCPUHz:=1000000;FOutputHigh:=True;FInputHigh:=True end;
procedure TCassetteSignal.SetInput(HighLevel:Boolean);
begin
 if FInputHigh=HighLevel then Exit;
 FInputHigh:=HighLevel;if Assigned(FOnInput)then FOnInput(HighLevel);
end;
procedure TCassetteSignal.LoadWav(const FileName:string);
var S:TFileStream; ID:array[0..3]of AnsiChar; Size,Rate,DataSize:Cardinal;
 Fmt,Channels,Bits,Align:Word; DataPos,NextPos:Int64; I,J,N:Integer;
 V:Integer; Sum:Int64; Raw:array[0..3]of Byte; Sample:Integer;
 function FourCC:AnsiString;
 begin SetString(Result,PAnsiChar(@ID[0]),4) end;
 function U16:Word;
 var B:array[0..1]of Byte;
 begin S.ReadBuffer(B,2);Result:=B[0]or(Word(B[1])shl 8) end;
 function U32:Cardinal;
 var B:array[0..3]of Byte;
 begin S.ReadBuffer(B,4);Result:=B[0]or(Cardinal(B[1])shl 8)or(Cardinal(B[2])shl 16)or(Cardinal(B[3])shl 24)end;
begin
 StopPlayback;S:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
 try
  S.ReadBuffer(ID,4);if FourCC<>'RIFF'then raise Exception.Create('RIFF WAVではありません');
  U32;S.ReadBuffer(ID,4);if FourCC<>'WAVE'then raise Exception.Create('WAVEではありません');
  Fmt:=0;Channels:=0;Bits:=0;Align:=0;Rate:=0;DataPos:=0;DataSize:=0;
  while S.Position+8<=S.Size do begin
   S.ReadBuffer(ID,4);Size:=U32;NextPos:=S.Position+Int64(Size)+(Size and 1);
   if S.Position+Int64(Size)>S.Size then raise Exception.Create('WAVチャンクが途中で切れています');
   if FourCC='fmt 'then begin
    if Size<16 then raise Exception.Create('WAV fmtが短すぎます');
    Fmt:=U16;Channels:=U16;Rate:=U32;U32;Align:=U16;Bits:=U16;
   end else if(FourCC='data')and(DataPos=0)then begin DataPos:=S.Position;DataSize:=Size end;
   S.Position:=NextPos;
  end;
  if(Fmt<>1)or not(Channels in[1,2])or not(Bits in[8,16,24,32])or
    (Rate<8000)or(Rate>192000)or(Align<>Channels*(Bits div 8))or(DataPos=0)then
   raise Exception.Create('PCM 8/16/24/32bit、モノラル/ステレオWAVを指定してください');
  if DataSize>128*1024*1024 then raise Exception.Create('WAVデータは128MiB以内で指定してください');
  N:=DataSize div Align;SetLength(FSamples,N);S.Position:=DataPos;
  for I:=0 to N-1 do begin
   Sum:=0;
   for J:=1 to Channels do begin
    FillChar(Raw,SizeOf(Raw),0);S.ReadBuffer(Raw,Bits div 8);
    case Bits of
     8:Sample:=(Integer(Raw[0])-128)*256;
     16:Sample:=SmallInt(Word(Raw[0])or(Word(Raw[1])shl 8));
     24:Sample:=SmallInt(Word(Raw[1])or(Word(Raw[2])shl 8));
    else Sample:=SmallInt(Word(Raw[2])or(Word(Raw[3])shl 8));end;
    Sum:=Sum+Sample;
   end;
   V:=Sum div Channels;FSamples[I]:=V;
  end;
  { Normalized analogue input is compared with zero; zero retains the prior level. }
  FSampleRate:=Rate;Rewind;
 finally S.Free end;
end;
procedure TCassetteSignal.Play;
begin if FRecording then raise Exception.Create('先に録音を終了してください');if Length(FSamples)=0 then raise Exception.Create('再生WAVを指定してください');FResumeOnMotor:=False;FPlaying:=True;Inc(FTransportGeneration) end;
procedure TCassetteSignal.StopPlayback;
begin FResumeOnMotor:=False;FPlaying:=False;SetInput(True) end;
procedure TCassetteSignal.PausePlayback;
begin
 FPlaying:=False;FResumeOnMotor:=Length(FSamples)>0;Inc(FTransportGeneration);SetInput(True);
end;
procedure TCassetteSignal.Rewind;
begin FPosition:=0;FPhase:=0;SetInput(True)end;
procedure TCassetteSignal.ArmRecording;
begin StopPlayback;FRecordCycles:=0;SetLength(FEdges,0);FRecording:=True;Inc(FTransportGeneration) end;
procedure TCassetteSignal.CancelRecording;
begin FRecording:=False;SetLength(FEdges,0);FRecordCycles:=0 end;
function TCassetteSignal.TransportReady:Boolean;
begin Result:=FRecording or FPlaying or FResumeOnMotor end;
procedure TCassetteSignal.SetMotor(OnState:Boolean);
begin
 { A fresh relay ON resumes a manually stopped tape. No monitor-PC recognition. }
 if OnState and not FMotor and FResumeOnMotor and not FRecording then begin
  FResumeOnMotor:=False;FPlaying:=True;
 end;
 FMotor:=OnState;
end;
procedure TCassetteSignal.SetOutput(HighLevel:Boolean);
var N:Integer;
begin
 if HighLevel=FOutputHigh then Exit;
 FOutputHigh:=HighLevel;
 if FRecording and FMotor then begin
  N:=Length(FEdges);SetLength(FEdges,N+1);FEdges[N].Cycle:=FRecordCycles;FEdges[N].HighLevel:=HighLevel;
 end;
end;
procedure TCassetteSignal.Advance(Cycles:Integer);
var Count,I:Integer; V:SmallInt;
begin
 if(Cycles<=0)or(FCPUHz<=0)or not FMotor then Exit;
 if FRecording then Inc(FRecordCycles,Cycles);
 if FPlaying then begin
  Inc(FPhase,Int64(Cycles)*FSampleRate);Count:=FPhase div FCPUHz;FPhase:=FPhase mod FCPUHz;
  for I:=1 to Count do begin
   if FPosition>=Length(FSamples)then begin FPlaying:=False;Break end;
   V:=FSamples[FPosition];Inc(FPosition);
   if V<>0 then SetInput((V<0)xor FInvert);
  end;
 end;
end;
function TCassetteSignal.DurationSeconds:Double;
begin if FSampleRate=0 then Result:=0 else Result:=Length(FSamples)/FSampleRate end;
function TCassetteSignal.PositionSeconds:Double;
begin if FSampleRate=0 then Result:=0 else Result:=FPosition/FSampleRate end;
function TCassetteSignal.RecordingSeconds:Double;
begin Result:=FRecordCycles/FCPUHz end;
procedure TCassetteSignal.SaveRecording(const FileName:string);
const Rate=48000;
var S:TFileStream; I,N,E:Integer; Cycle:Int64; Level:Boolean; Value:SmallInt;
 procedure ID(const Text:AnsiString);
 begin S.WriteBuffer(Text[1],4)end;
 procedure U16(V:Word);
 var B:array[0..1]of Byte;
 begin B[0]:=Byte(V);B[1]:=Byte(V shr 8);S.WriteBuffer(B,2)end;
 procedure U32(V:Cardinal);
 var B:array[0..3]of Byte;
 begin B[0]:=Byte(V);B[1]:=Byte(V shr 8);B[2]:=Byte(V shr 16);B[3]:=Byte(V shr 24);S.WriteBuffer(B,4)end;
begin
 if FRecordCycles=0 then raise Exception.Create('録音波形がありません');
 N:=FRecordCycles*Rate div FCPUHz;
 S:=TFileStream.Create(FileName,fmCreate);
 try
  ID('RIFF');U32(36+Cardinal(N)*2);ID('WAVE');ID('fmt ');U32(16);U16(1);U16(1);
  U32(Rate);U32(Rate*2);U16(2);U16(16);ID('data');U32(Cardinal(N)*2);
  E:=0;Level:=True;
  for I:=0 to N-1 do begin
   Cycle:=Int64(I)*FCPUHz div Rate;
   while(E<Length(FEdges))and(FEdges[E].Cycle<=Cycle)do begin Level:=FEdges[E].HighLevel;Inc(E)end;
   if E=0 then Value:=0 else if Level then Value:=-14000 else Value:=14000;
   U16(Word(Value));
  end;
  FRecording:=False;
 finally S.Free end;
end;
end.
