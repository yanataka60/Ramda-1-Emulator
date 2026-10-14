unit ExternalROM;
interface
uses SysUtils, Classes;
type
 TExternalMemory=array[0..65535]of Byte;
 PExternalMemory=^TExternalMemory;
 TExternalROM=class
 private
  FUtilityLoaded,FAssemblerLoaded,FTinyBasicLoaded,FMenuPatched:Boolean;
  FWarnings:string;
  procedure Warning(const Text:string);
  function LoadFile(const Directory,Name:string;Memory:PExternalMemory;
                    Base:Word;Capacity:Integer):Boolean;
  procedure ConnectTinyBasic(Memory:PExternalMemory);
 public
  procedure LoadStartup(const Directory:string;Memory:PExternalMemory);
  function IsReadOnly(Address:Word):Boolean;
  property UtilityLoaded:Boolean read FUtilityLoaded;
  property AssemblerLoaded:Boolean read FAssemblerLoaded;
  property TinyBasicLoaded:Boolean read FTinyBasicLoaded;
  property MenuPatched:Boolean read FMenuPatched;
  property Warnings:string read FWarnings;
 end;
implementation
procedure TExternalROM.Warning(const Text:string);
begin
 if FWarnings<>''then FWarnings:=FWarnings+sLineBreak;
 FWarnings:=FWarnings+Text;
end;
function TExternalROM.LoadFile(const Directory,Name:string;Memory:PExternalMemory;
                              Base:Word;Capacity:Integer):Boolean;
var FileName:string;Stream:TFileStream;Data:TBytes;Count:Integer;
begin
 Result:=False;
 FileName:=IncludeTrailingPathDelimiter(Directory)+Name;
 if not FileExists(FileName)then Exit;
 try
  Stream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
   if(Stream.Size<=0)or(Stream.Size>Capacity)then
    raise Exception.CreateFmt('Invalid ROM size: %d (1..%d bytes required)',[Stream.Size,Capacity]);
   Count:=Integer(Stream.Size);SetLength(Data,Count);Stream.ReadBuffer(Data[0],Count);
  finally Stream.Free end;
  { Commit only after a complete read. The caller's existing RAM is preserved on error. }
  if Base=$A000 then FillChar(Memory^[$A000],$1000,$FF)
  else if Base=$B000 then FillChar(Memory^[$B000],$1000,$FF)
  else if (Base=$A700)and not FUtilityLoaded then FillChar(Memory^[$A000],$1000,$FF);
  Move(Data[0],Memory^[Base],Count);Result:=True;
 except on E:Exception do Warning(Name+': '+E.Message) end;
end;
procedure TExternalROM.ConnectTinyBasic(Memory:PExternalMemory);
begin
 if not(FUtilityLoaded and FTinyBasicLoaded)then Exit;
 { Recognize the restored original dispatch table and ADX instruction, before
   changing the single Tiny-BASIC vector. Never alter an unknown UTILITY. }
 if (Memory^[$A270]=$FC)and(Memory^[$A271]=$F7)and(Memory^[$A272]=$60)and
    (Memory^[$A27A]=$A0)and(Memory^[$A27B]=$E2)and
    (Memory^[$A282]=$B0)and(Memory^[$A283]=$00)then begin
  if(Memory^[$A284]=$A2)and(Memory^[$A285]=$77)then begin
   Memory^[$A284]:=$A7;Memory^[$A285]:=$00;FMenuPatched:=True;Exit;
  end;
  if(Memory^[$A284]=$A7)and(Memory^[$A285]=$00)then Exit;
 end;
 Warning('UTILITY.bin: menu 6 vector was not changed (unrecognized program).');
end;
procedure TExternalROM.LoadStartup(const Directory:string;Memory:PExternalMemory);
begin
 FWarnings:='';FMenuPatched:=False;
 FUtilityLoaded:=LoadFile(Directory,'UTILITY.bin',Memory,$A000,$1000);
 FAssemblerLoaded:=LoadFile(Directory,'Assembler.bin',Memory,$B000,$1000);
 FTinyBasicLoaded:=LoadFile(Directory,'TinyBasic.bin',Memory,$A700,$0900);
 ConnectTinyBasic(Memory);
 { Optional native F-BASIC image; all runtime support is inside the BIN.
   Keep 8000-9FFF as ordinary RAM, as in the original v1.45. }
 LoadFile(Directory,'CassetteFloatBasic.bin',Memory,$8000,$2000);
end;
function TExternalROM.IsReadOnly(Address:Word):Boolean;
begin
 { Physical external ROM slots: unused bytes are still ROM when fitted.
   Tiny-BASIC's RAM probe must stop at A000 even if UTILITY is absent. }
 Result:=((Address>=$A000)and(Address<=$AFFF)and(FUtilityLoaded or FTinyBasicLoaded))or
         ((Address>=$B000)and(Address<=$BFFF)and FAssemblerLoaded);
end;
end.
