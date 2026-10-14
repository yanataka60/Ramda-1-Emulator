unit CassetteForm;
interface
uses EmulatorSettings,Winapi.Windows,System.SysUtils,System.Classes,System.UITypes,Vcl.Forms,Vcl.Controls,
 Vcl.StdCtrls,Vcl.ExtCtrls,Vcl.Dialogs,CassetteSignal;
type
 TFrmCassette=class(TForm)
  published
    LblInput: TLabel;
    LblInputHelp: TLabel;
    LblOutput: TLabel;
    LblOutputHelp: TLabel;
    LblClock: TLabel;
    FInput: TEdit;
    FOutput: TEdit;
    FPolarity: TCheckBox;
    FStatus: TLabel;
    FTimes: TLabel;
    FPlay: TButton;
    FRewind: TButton;
    FRecord: TButton;
    FSave: TButton;
    FOpen: TButton;
    FOutputBrowse: TButton;
    StatusTimer: TTimer;
    InputDialog: TOpenDialog;
    OutputDialog: TSaveDialog;
    procedure OpenClick(Sender:TObject);
    procedure PlayClick(Sender:TObject);
    procedure RewindClick(Sender:TObject);
    procedure RecordClick(Sender:TObject);
    procedure SaveClick(Sender:TObject);
    procedure BrowseOutputClick(Sender:TObject);
    procedure StatusTick(Sender:TObject);
    procedure PolarityClick(Sender:TObject);
    procedure InputChanged(Sender:TObject);
    procedure InputExit(Sender:TObject);
    procedure InputKeyPress(Sender:TObject;var Key:Char);
    procedure OutputChanged(Sender:TObject);
    procedure CloseHandler(Sender:TObject;var Action:TCloseAction);

 private
  FTape:TCassetteSignal;

  FLoadedInput,FRecordFile,FLastResult:string;
  FAutoSaveFailed,FUpdating:Boolean;

  function PreparePlayback:Boolean;
  procedure FinishRecording;

 protected procedure CreateParams(var Params:TCreateParams);override;
 public constructor CreateForTape(AOwner:TComponent;ATape:TCassetteSignal);
 end;
implementation

{$R *.dfm}
procedure TFrmCassette.CreateParams(var Params:TCreateParams);
begin inherited;Params.ExStyle:=(Params.ExStyle or WS_EX_APPWINDOW)and not WS_EX_TOOLWINDOW;Params.WndParent:=0 end;
constructor TFrmCassette.CreateForTape(AOwner:TComponent;ATape:TCassetteSignal);
begin
 inherited Create(AOwner);FTape:=ATape;
 FUpdating:=True;
 try
  FInput.Text:=Ramda1Settings.CassetteInputFile;
  FOutput.Text:=Ramda1Settings.CassetteOutputFile;
  InputDialog.InitialDir:=Ramda1Settings.CassetteInputDirectory;
  InputDialog.FileName:=Ramda1Settings.CassetteInputFile;
  OutputDialog.InitialDir:=Ramda1Settings.CassetteOutputDirectory;
  OutputDialog.FileName:=Ramda1Settings.CassetteOutputFile;
  InputDialog.Options:=InputDialog.Options+[ofNoChangeDir];
  OutputDialog.Options:=OutputDialog.Options+[ofNoChangeDir];
 finally FUpdating:=False end;
 StatusTick(Self);StatusTimer.Enabled:=True;
end;
procedure TFrmCassette.InputChanged(Sender:TObject);
begin
 if (FTape=nil) or FUpdating then Exit;
 Ramda1Settings.RememberFile(Ramda1Settings.CassetteInputFile,Ramda1Settings.CassetteInputDirectory,FInput.Text);
 FTape.StopPlayback;FLoadedInput:='';FLastResult:='再生ファイルを入力後、Enterで確定してください';
 StatusTick(Self);
end;
procedure TFrmCassette.OutputChanged(Sender:TObject);
begin
 if (FTape<>nil) and not FUpdating then begin
  Ramda1Settings.RememberFile(Ramda1Settings.CassetteOutputFile,Ramda1Settings.CassetteOutputDirectory,FOutput.Text);
  StatusTick(Self);
 end;
end;
function TFrmCassette.PreparePlayback:Boolean;
var Name:string;
begin
 Result:=False;
 if FTape.Recording then Exit;
 Name:=Trim(FInput.Text);if Name=''then Exit;
 try
  Name:=Ramda1Settings.ResolveFileName(Name,Ramda1Settings.CassetteInputDirectory);
  if Name<>FLoadedInput then begin
   FTape.LoadWav(Name);FLoadedInput:=Name;
   FUpdating:=True;
   try FInput.Text:=Name finally FUpdating:=False end;
   FTape.Play;
  end;
  Ramda1Settings.RememberFile(Ramda1Settings.CassetteInputFile,Ramda1Settings.CassetteInputDirectory,Name);
  FLastResult:='';Result:=True;
 except on E:Exception do begin
  FLoadedInput:='';FLastResult:='再生ファイルを読み込めません';ShowMessage(E.Message);
 end end;
 StatusTick(Self);
end;
procedure TFrmCassette.InputExit(Sender:TObject);
begin
 if(FLoadedInput='')and(Trim(FInput.Text)<>'')then PreparePlayback;
end;
procedure TFrmCassette.InputKeyPress(Sender:TObject;var Key:Char);
begin if Key=#13 then begin Key:=#0;PreparePlayback end end;
procedure TFrmCassette.OpenClick(Sender:TObject);
begin
 if FTape.Recording then Exit;
 InputDialog.InitialDir:=Ramda1Settings.CassetteInputDirectory;
 InputDialog.FileName:=Ramda1Settings.CassetteInputFile;
 if InputDialog.Execute then begin
   Ramda1Settings.RememberFile(Ramda1Settings.CassetteInputFile,Ramda1Settings.CassetteInputDirectory,InputDialog.FileName);
   FUpdating:=True;
   try FInput.Text:=InputDialog.FileName finally FUpdating:=False end;
   FLoadedInput:='';PreparePlayback;
 end;
end;
procedure TFrmCassette.BrowseOutputClick(Sender:TObject);
begin
 if FTape.Recording then Exit;
 OutputDialog.InitialDir:=Ramda1Settings.CassetteOutputDirectory;
 OutputDialog.FileName:=Ramda1Settings.CassetteOutputFile;
 if OutputDialog.Execute then FOutput.Text:=OutputDialog.FileName;
 StatusTick(Self);
end;
procedure TFrmCassette.PlayClick(Sender:TObject);
begin
 FTape.PausePlayback;FLastResult:='停止中（次のモーターONで再開）';
 StatusTick(Self);
end;
procedure TFrmCassette.RewindClick(Sender:TObject);
begin
 if FTape.Recording then Exit;
 if PreparePlayback then begin FTape.PausePlayback;FTape.Rewind end;
 FLastResult:='巻き戻し済み（CHICK-BUGでLを入力）';
 StatusTick(Self);
end;
procedure TFrmCassette.RecordClick(Sender:TObject);
var Name:string;
begin
 if FTape.Recording then Exit;
 Name:=Trim(FOutput.Text);if Name=''then Exit;
 try
  if ExtractFileExt(Name)=''then Name:=Name+'.wav';
  Name:=Ramda1Settings.ResolveFileName(Name,Ramda1Settings.CassetteOutputDirectory);
  if not DirectoryExists(ExtractFilePath(Name))then
   raise Exception.Create('出力フォルダが存在しません');
  if FileExists(Name)then
   if MessageDlg('既存のWAVを上書きしますか？',System.UITypes.TMsgDlgType.mtConfirmation,
     [System.UITypes.TMsgDlgBtn.mbYes,System.UITypes.TMsgDlgBtn.mbNo],0)<>System.UITypes.mrYes then Exit;
  FRecordFile:=Name;FOutput.Text:=Name;FAutoSaveFailed:=False;FLastResult:='';
  FTape.ArmRecording;
 except on E:Exception do ShowMessage(E.Message)end;
 StatusTick(Self);
end;
procedure TFrmCassette.FinishRecording;
begin
 if not FTape.Recording then Exit;
 if FTape.RecordingSeconds=0 then begin
  FTape.CancelRecording;FLastResult:='録音待機を解除しました';
 end else begin
  FTape.SaveRecording(FRecordFile);FLastResult:='WAVを保存しました';
 end;
 FAutoSaveFailed:=False;
end;
procedure TFrmCassette.SaveClick(Sender:TObject);
begin
 try FinishRecording
 except on E:Exception do begin FAutoSaveFailed:=True;FLastResult:='保存失敗（終了・保存で再試行）';ShowMessage(E.Message)end end;
 StatusTick(Self);
end;
procedure TFrmCassette.PolarityClick(Sender:TObject);
begin FTape.InvertPlayback:=FPolarity.Checked end;
procedure TFrmCassette.StatusTick(Sender:TObject);
var State:string;
begin
 if FTape.Recording and not FTape.Motor and(FTape.RecordingSeconds>0)and not FAutoSaveFailed then begin
  try FinishRecording
  except on E:Exception do begin FAutoSaveFailed:=True;FLastResult:='保存失敗（終了・保存で再試行）';ShowMessage(E.Message)end end;
 end;
 FRecord.Enabled:=not FTape.Recording and(Trim(FOutput.Text)<>'');
 FSave.Enabled:=FTape.Recording;
 FOutput.Enabled:=not FTape.Recording;FOutputBrowse.Enabled:=not FTape.Recording;
 FInput.Enabled:=not FTape.Recording;FOpen.Enabled:=not FTape.Recording;
 FRewind.Enabled:=not FTape.Recording and(FLoadedInput<>'');
 FPlay.Enabled:=FRewind.Enabled and FTape.Playing;
 FPolarity.Enabled:=not FTape.Recording;
 if FTape.Recording then begin
  if FAutoSaveFailed then State:=FLastResult
  else if FTape.Motor then State:='録音中'
  else State:='録音待機中（CHICK-BUGでSを入力）';
 end else if FTape.Playing then begin
  if FTape.Motor then State:='再生中'else State:='再生準備完了（CHICK-BUGでLを入力）';
 end else if FLastResult<>''then State:=FLastResult
 else State:='停止中';
 FStatus.Caption:=State;
 FTimes.Caption:=Format('再生 %.1f / %.1f 秒    録音 %.1f 秒',
  [FTape.PositionSeconds,FTape.DurationSeconds,FTape.RecordingSeconds]);
end;
procedure TFrmCassette.CloseHandler(Sender:TObject;var Action:TCloseAction);
begin Action:=caHide end;
end.
