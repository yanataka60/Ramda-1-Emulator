unit PrinterDevice;
interface
uses SysUtils,Classes,MC6821Expansion;
const PrinterAckDelayCycles=10; PrinterAckWidthCycles=5; PrinterDisplayQueueSize=65536;
type
  TPrinterDevice = class
  private
    FPIA:TMC6821Expansion;
    FFile:TFileStream;
    FFileName,FError:string;
    FReceived:Int64;
    FBusy:Boolean;
    FDisplayQueue:array[0..PrinterDisplayQueueSize-1]of Byte;
    FDisplayHead,FDisplayCount:Integer;
    FDisplayDropped:Int64;
    FAckStage,FAckCycles:Integer;
    procedure StrobeChanged(HighLevel:Boolean);
  public
    constructor Create;
    destructor Destroy;override;
    procedure Reset;
    function ReadRegister(Offset:Byte):Byte;
    procedure WriteRegister(Offset,Value:Byte);
    procedure Advance(Cycles:Integer);
    procedure StartTextFile(const FileName:string);
    procedure StopTextFile;
    function Saving:Boolean;
    function TakeDisplayData:AnsiString;
    property DisplayDropped:Int64 read FDisplayDropped;
    property PIA:TMC6821Expansion read FPIA;
    property Received:Int64 read FReceived;
    property LastError:string read FError;
    property FileName:string read FFileName;
  end;
implementation
constructor TPrinterDevice.Create;
begin inherited Create;FPIA:=TMC6821Expansion.Create;FPIA.PortB.OnC2:=StrobeChanged end;
destructor TPrinterDevice.Destroy;
begin StopTextFile;FPIA.Free;inherited end;
procedure TPrinterDevice.Reset;
begin FPIA.Reset;FBusy:=False;FAckStage:=0;FAckCycles:=0;FPIA.PortB.SetC1(True);FPIA.Reset end;
function TPrinterDevice.ReadRegister(Offset:Byte):Byte;
begin Result:=FPIA.ReadRegister(Offset) end;
procedure TPrinterDevice.WriteRegister(Offset,Value:Byte);
begin FPIA.WriteRegister(Offset,Value) end;
procedure TPrinterDevice.StrobeChanged(HighLevel:Boolean);
var Value:Byte;
begin
 if HighLevel or FBusy then Exit;
 Value:=FPIA.PortB.OutputPins;
 Inc(FReceived);
 { A bounded display queue is independent of optional file output. No UI work
   or text conversion occurs in the emulated STROBE/ACK path. }
 if FDisplayCount=PrinterDisplayQueueSize then begin
  FDisplayHead:=(FDisplayHead+1)mod PrinterDisplayQueueSize;
  Dec(FDisplayCount);Inc(FDisplayDropped);
 end;
 FDisplayQueue[(FDisplayHead+FDisplayCount)mod PrinterDisplayQueueSize]:=Value;
 Inc(FDisplayCount);
 if Assigned(FFile) then try FFile.WriteBuffer(Value,1)
 except on E:Exception do begin FError:=E.Message;StopTextFile end end;
 FBusy:=True;FAckStage:=1;FAckCycles:=PrinterAckDelayCycles;
end;
procedure TPrinterDevice.Advance(Cycles:Integer);
var Step:Integer;
begin
 if Cycles<=0 then Exit;
 { Discrete E cycles prevent an instruction-sized advance from swallowing ACK. }
 while Cycles>0 do begin
  if FAckStage=0 then begin FPIA.Advance(Cycles);Exit end;
  Step:=1;FPIA.Advance(Step);
  if FAckStage<>0 then begin
   Dec(FAckCycles);
   if FAckCycles=0 then case FAckStage of
    1:begin FPIA.PortB.SetC1(False);FAckStage:=2;FAckCycles:=PrinterAckWidthCycles end;
    2:begin FPIA.PortB.SetC1(True);FAckStage:=0;FBusy:=False end;
   end;
  end;
  Dec(Cycles,Step);
 end;
end;
procedure TPrinterDevice.StartTextFile(const FileName:string);
var NewFile:TFileStream;
begin
 if Trim(FileName)='' then raise Exception.Create('出力ファイルを指定してください。');
 NewFile:=TFileStream.Create(FileName,fmCreate or fmShareDenyWrite);
 StopTextFile;FFile:=NewFile;FFileName:=FileName;FError:='';
end;
procedure TPrinterDevice.StopTextFile;
begin FreeAndNil(FFile) end;
function TPrinterDevice.TakeDisplayData:AnsiString;
var I:Integer;
begin
 SetLength(Result,FDisplayCount);
 for I:=0 to FDisplayCount-1 do
  Result[I+1]:=AnsiChar(FDisplayQueue[(FDisplayHead+I)mod PrinterDisplayQueueSize]);
 FDisplayHead:=0;FDisplayCount:=0;
end;
function TPrinterDevice.Saving:Boolean;
begin Result:=Assigned(FFile) end;
end.
