unit PrinterForm;
interface
uses Winapi.Windows,Winapi.Messages,System.SysUtils,System.Classes,Vcl.Forms,Vcl.Controls,
 Vcl.StdCtrls,Vcl.ExtCtrls,Vcl.Dialogs,PrinterDevice,PrinterTextBuffer;
type
 TFrmPrinter=class(TForm)
 published
  OutputMemo:TMemo;
  SaveText:TCheckBox;
  PathEdit:TEdit;
  Browse:TButton;
  Description:TLabel;
  Status:TLabel;
  SaveDialog:TSaveDialog;
  RefreshTimer:TTimer;
  procedure SaveTextClick(Sender:TObject);
  procedure BrowseClick(Sender:TObject);
  procedure PathKeyDown(Sender:TObject;var Key:Word;Shift:TShiftState);
  procedure RefreshTimerTick(Sender:TObject);
  procedure FormCloseHandler(Sender:TObject;var Action:TCloseAction);
 private
  FPrinter:TPrinterDevice;
  FUpdating:Boolean;
  FOutput:TPrinterTextBuffer;
  procedure RefreshStatus;
  procedure RefreshOutput;
 protected
  procedure CreateParams(var Params:TCreateParams);override;
 public
  constructor CreateForPrinter(AOwner:TComponent;APrinter:TPrinterDevice);
  destructor Destroy;override;
 end;
implementation
{$R *.dfm}
procedure TFrmPrinter.CreateParams(var Params:TCreateParams);
begin
 inherited CreateParams(Params);
 Params.ExStyle:=(Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
 Params.WndParent:=0;
end;
constructor TFrmPrinter.CreateForPrinter(AOwner:TComponent;APrinter:TPrinterDevice);
begin
 inherited Create(AOwner);FPrinter:=APrinter;FOutput:=TPrinterTextBuffer.Create;
 RefreshOutput;RefreshStatus;RefreshTimer.Enabled:=True;
end;
destructor TFrmPrinter.Destroy;
begin if Assigned(RefreshTimer)then RefreshTimer.Enabled:=False;FOutput.Free;inherited end;
procedure TFrmPrinter.RefreshOutput;
var Data:AnsiString;
begin
 if not Assigned(FPrinter)then Exit;
 Data:=FPrinter.TakeDisplayData;
 if Data=''then Exit;
 FOutput.Append(Data);
 OutputMemo.Text:=FOutput.Text;
 OutputMemo.SelStart:=Length(OutputMemo.Text);
 OutputMemo.Perform(EM_SCROLLCARET,0,0);
end;
procedure TFrmPrinter.RefreshStatus;
begin
 if not Assigned(FPrinter) then Exit;
 FUpdating:=True;
 try SaveText.Checked:=FPrinter.Saving finally FUpdating:=False end;
 PathEdit.Enabled:=not FPrinter.Saving;Browse.Enabled:=not FPrinter.Saving;
 if FPrinter.LastError<>'' then Status.Caption:='保存エラー（画面への出力は継続）: '+FPrinter.LastError
 else if FPrinter.Saving then Status.Caption:='画面表示＋ファイル出力中 / 受信 '+IntToStr(FPrinter.Received)+' バイト'
 else Status.Caption:='画面表示中 / 受信 '+IntToStr(FPrinter.Received)+' バイト';
 if FPrinter.DisplayDropped>0 then Status.Caption:=Status.Caption+' / 表示待ちの旧データ省略 '+IntToStr(FPrinter.DisplayDropped)+' バイト';
end;
procedure TFrmPrinter.SaveTextClick(Sender:TObject);
begin
 if FUpdating or not Assigned(FPrinter) then Exit;
 if SaveText.Checked and not FPrinter.Saving then begin
  try
   if FileExists(PathEdit.Text) then
    if MessageDlg('既存ファイルを上書きしますか？',mtConfirmation,[mbYes,mbNo],0)<>mrYes then begin SaveText.Checked:=False;Exit end;
   FPrinter.StartTextFile(PathEdit.Text);
  except on E:Exception do begin SaveText.Checked:=False;MessageDlg(E.Message,mtError,[mbOK],0) end end;
 end else if not SaveText.Checked then FPrinter.StopTextFile;
 RefreshStatus;
end;
procedure TFrmPrinter.BrowseClick(Sender:TObject);
begin
 SaveDialog.FileName:=PathEdit.Text;
 if SaveDialog.Execute then PathEdit.Text:=SaveDialog.FileName;
end;
procedure TFrmPrinter.PathKeyDown(Sender:TObject;var Key:Word;Shift:TShiftState);
begin if Key=VK_RETURN then begin Key:=0;SaveText.SetFocus end end;
procedure TFrmPrinter.RefreshTimerTick(Sender:TObject);
begin RefreshOutput;if Visible then RefreshStatus end;
procedure TFrmPrinter.FormCloseHandler(Sender:TObject;var Action:TCloseAction);
begin Action:=caHide end;
end.
