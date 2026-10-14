unit EmulatorSettings;
interface
uses SysUtils, Classes, IniFiles;
type
 TRamda1Settings=class
 private
  FIniFileName,FExeDirectory:string;
  function DefaultDirectory(const Value:string):string;
 public
  AutoPanelStop:Boolean;
  BinLoadFile,BinSaveFile,CassetteInputFile,CassetteOutputFile:string;
  BinLoadDirectory,BinSaveDirectory,CassetteInputDirectory,CassetteOutputDirectory:string;
  constructor Create(const ExeFileName:string);
  procedure Load;
  procedure Save;
  function ResolveFileName(const Name,Directory:string):string;
  procedure RememberFile(var FileName,Directory:string;const Value:string);
  property IniFileName:string read FIniFileName;
  property ExeDirectory:string read FExeDirectory;
 end;
var Ramda1Settings:TRamda1Settings;
implementation
constructor TRamda1Settings.Create(const ExeFileName:string);
begin
 inherited Create;
 FExeDirectory:=IncludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(ExeFileName)));
 FIniFileName:=ChangeFileExt(ExpandFileName(ExeFileName),'.ini');
 Load;
end;
function TRamda1Settings.DefaultDirectory(const Value:string):string;
begin
 if(Value<>'')and DirectoryExists(Value)then Result:=IncludeTrailingPathDelimiter(Value)
 else Result:=FExeDirectory;
end;
function TRamda1Settings.ResolveFileName(const Name,Directory:string):string;
begin
 Result:=Trim(Name);
 if Result=''then Exit;
 if(ExtractFileDrive(Result)='')and(Result[1]<>PathDelim)then
  Result:=IncludeTrailingPathDelimiter(DefaultDirectory(Directory))+Result;
 Result:=ExpandFileName(Result);
end;
procedure TRamda1Settings.RememberFile(var FileName,Directory:string;const Value:string);
begin
 FileName:=ResolveFileName(Value,Directory);
 if FileName<>''then Directory:=ExtractFilePath(FileName);
end;
procedure TRamda1Settings.Load;
var Ini:TMemIniFile;
begin
 {$IFDEF FPC}Ini:=TMemIniFile.Create(FIniFileName);{$ELSE}Ini:=TMemIniFile.Create(FIniFileName,TEncoding.UTF8);{$ENDIF}
 try
  AutoPanelStop:=Ini.ReadBool('Panel','AutoStop',True);
  BinLoadDirectory:=DefaultDirectory(Ini.ReadString('Binary','LoadDirectory',''));
  BinSaveDirectory:=DefaultDirectory(Ini.ReadString('Binary','SaveDirectory',''));
  CassetteInputDirectory:=DefaultDirectory(Ini.ReadString('Cassette','InputDirectory',''));
  CassetteOutputDirectory:=DefaultDirectory(Ini.ReadString('Cassette','OutputDirectory',''));
  BinLoadFile:=Ini.ReadString('Binary','LoadFile','');
  BinSaveFile:=Ini.ReadString('Binary','SaveFile','');
  CassetteInputFile:=Ini.ReadString('Cassette','InputFile','');
  CassetteOutputFile:=Ini.ReadString('Cassette','OutputFile','');
 finally Ini.Free end;
end;
procedure TRamda1Settings.Save;
var Ini:TMemIniFile;
 procedure WriteFile(const Section,Key,Value:string);
 begin
  if Value<>''then Ini.WriteString(Section,Key,Value)else Ini.DeleteKey(Section,Key);
 end;
begin
 {$IFDEF FPC}Ini:=TMemIniFile.Create(FIniFileName);{$ELSE}Ini:=TMemIniFile.Create(FIniFileName,TEncoding.UTF8);{$ENDIF}
 try
  Ini.WriteBool('Panel','AutoStop',AutoPanelStop);
  Ini.WriteString('Binary','LoadDirectory',BinLoadDirectory);
  Ini.WriteString('Binary','SaveDirectory',BinSaveDirectory);
  Ini.WriteString('Cassette','InputDirectory',CassetteInputDirectory);
  Ini.WriteString('Cassette','OutputDirectory',CassetteOutputDirectory);
  WriteFile('Binary','LoadFile',BinLoadFile);WriteFile('Binary','SaveFile',BinSaveFile);
  WriteFile('Cassette','InputFile',CassetteInputFile);WriteFile('Cassette','OutputFile',CassetteOutputFile);
  Ini.UpdateFile;
 finally Ini.Free end;
end;
initialization
 Ramda1Settings:=TRamda1Settings.Create(ParamStr(0));
finalization
 Ramda1Settings.Free;
end.
