unit RAMFileForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs, Vcl.Graphics;

type
  TRAM64K = array[0..65535] of Byte;
  PRAM64K = ^TRAM64K;

  TFrmRAMFile = class(TForm)
  published
    LblLoad: TLabel;
    LblLoadAddr: TLabel;
    LblSave: TLabel;
    LblSaveStart: TLabel;
    LblSaveEnd: TLabel;
    BtnLoad: TButton;
    BtnSave: TButton;
    BtnClose: TButton;
    EdLoadAddr: TEdit;
    EdSaveStart: TEdit;
    EdSaveEnd: TEdit;
    LblStatus: TLabel;
    OpenDlg: TOpenDialog;
    SaveDlg: TSaveDialog;
    procedure LoadClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);

  private
    FMemory: PRAM64K;
    FLastLoadStart: Integer;

    function ParseHexEdit(E: TEdit; const What: string): Integer;

  public
    constructor CreateForMemory(AOwner: TComponent; AMemory: PRAM64K);
    property LastLoadStart: Integer read FLastLoadStart;
  end;

implementation

{$R *.dfm}

constructor TFrmRAMFile.CreateForMemory(AOwner: TComponent; AMemory: PRAM64K);
begin
  inherited Create(AOwner);
  FMemory := AMemory;
  FLastLoadStart := -1;
end;

function TFrmRAMFile.ParseHexEdit(E: TEdit; const What: string): Integer;
var
  S: string;
begin
  S := Trim(E.Text);
  if (Length(S) > 0) and (S[1] = '$') then Delete(S, 1, 1);
  if not TryStrToInt('$' + S, Result) or (Result < 0) or (Result > $FFFF) then
    raise Exception.Create(What + 'は0000～FFFFの16進数で指定してください。');
end;

procedure TFrmRAMFile.LoadClick(Sender: TObject);
var
  FS: TFileStream;
  StartAddr, Count: Integer;
begin
  try
    StartAddr := ParseHexEdit(EdLoadAddr, 'LOAD開始アドレス');
    if not OpenDlg.Execute then Exit;
    FS := TFileStream.Create(OpenDlg.FileName, fmOpenRead or fmShareDenyWrite);
    try
      if FS.Size > (65536 - StartAddr) then
      begin
        MessageDlg(Format('ファイルサイズ %d byte は $%.4X からRAM末尾までに収まりません。'#13#10 +
          'RAMを越えるLOADは行いません。', [FS.Size, StartAddr]), mtError, [mbOK], 0);
        Exit;
      end;
      Count := Integer(FS.Size);
      if Count > 0 then
        FS.ReadBuffer(FMemory^[StartAddr], Count);
      FLastLoadStart := StartAddr;
      LblStatus.Caption := Format('LOAD完了: $%.4X-$%.4X  (%d byte)', [StartAddr, StartAddr + Count - 1, Count]);
    finally
      FS.Free;
    end;
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmRAMFile.SaveClick(Sender: TObject);
var
  FS: TFileStream;
  StartAddr, EndAddr, Count: Integer;
begin
  try
    StartAddr := ParseHexEdit(EdSaveStart, 'SAVE開始アドレス');
    EndAddr := ParseHexEdit(EdSaveEnd, 'SAVE終了アドレス');
    if EndAddr < StartAddr then
      raise Exception.Create('SAVE終了アドレスは開始アドレス以上にしてください。');
    if not SaveDlg.Execute then Exit;
    Count := EndAddr - StartAddr + 1;
    FS := TFileStream.Create(SaveDlg.FileName, fmCreate);
    try
      FS.WriteBuffer(FMemory^[StartAddr], Count);
    finally
      FS.Free;
    end;
    LblStatus.Caption := Format('SAVE完了: $%.4X-$%.4X  (%d byte)', [StartAddr, EndAddr, Count]);
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFrmRAMFile.CloseClick(Sender: TObject);
begin
  Close;
end;

end.
