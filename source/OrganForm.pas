unit OrganForm;
interface
uses Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, OrganSynth;
type
  TFrmOrgan = class(TForm)
  published
    Explanation: TLabel;
    Keys: TPaintBox;
    Status: TLabel;
    RouteStatus: TLabel;
    RefreshTimer: TTimer;
    procedure PaintKeys(Sender: TObject);
    procedure KeysMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure KeysMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDeactivateHandler(Sender: TObject);
    procedure FormCloseHandler(Sender: TObject; var Action: TCloseAction);
    procedure RefreshTimerTick(Sender: TObject);
  private
    FSynth: TOrganSynth;
    FPCMask, FMouseMask: Byte;
    procedure UpdateManual;
    function KeyIndex(Key: Word): Integer;
  protected
    procedure CreateParams(var Params:TCreateParams); override;
  public
    constructor CreateForOrgan(AOwner: TComponent; ASynth: TOrganSynth);
    procedure SetRouteStatus(OrganConnected,CassetteActive:Boolean);
    procedure SetAudioStatus(Available: Boolean; ErrorCode: Cardinal);
  end;
implementation
{$R *.dfm}
type TPaintBoxAccess = class(TPaintBox);
procedure TFrmOrgan.CreateParams(var Params:TCreateParams);
begin
 inherited CreateParams(Params);
 Params.ExStyle:=(Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
 Params.WndParent:=0;
end;
constructor TFrmOrgan.CreateForOrgan(AOwner:TComponent;ASynth:TOrganSynth);
begin
 inherited Create(AOwner);
 FSynth:=ASynth;
 RefreshTimer.Enabled:=True;
end;
procedure TFrmOrgan.SetRouteStatus(OrganConnected,CassetteActive:Boolean);
begin
 if CassetteActive then RouteStatus.Caption:='現在の接続: カセット/WAV（モーターOFFで自動復帰）'
 else if OrganConnected then RouteStatus.Caption:='現在の接続: 電子オルガン'
 else RouteStatus.Caption:='現在の接続: TV・カセット/WAV';
end;
procedure TFrmOrgan.SetAudioStatus(Available:Boolean;ErrorCode:Cardinal);
begin
 if Available then Status.Caption:='音声出力: 有効（48 kHz）'
 else Status.Caption:=Format('音声出力を開けません（エラー %d）',[ErrorCode]);
end;
function TFrmOrgan.KeyIndex(Key:Word):Integer;
const VK:array[0..7] of Word=(Ord('Z'),Ord('X'),Ord('C'),Ord('V'),Ord('B'),Ord('N'),Ord('M'),VK_OEM_COMMA);
var I:Integer;
begin Result:=-1;for I:=0 to 7 do if Key=VK[I] then Exit(I) end;
procedure TFrmOrgan.UpdateManual;
begin
 if Assigned(FSynth) then FSynth.SetManualMask(FPCMask or FMouseMask);
 if Assigned(Keys) then Keys.Invalidate;
end;
procedure TFrmOrgan.FormKeyDown(Sender:TObject;var Key:Word;Shift:TShiftState);
var I:Integer;
begin
 I:=KeyIndex(Key);if (I<0) or (ssAlt in Shift) or (ssCtrl in Shift) then Exit;
 FPCMask:=FPCMask or (1 shl I);UpdateManual;Key:=0;
end;
procedure TFrmOrgan.FormKeyUp(Sender:TObject;var Key:Word;Shift:TShiftState);
var I:Integer;
begin I:=KeyIndex(Key);if I<0 then Exit;FPCMask:=FPCMask and not (1 shl I);UpdateManual;Key:=0 end;
procedure TFrmOrgan.KeysMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var I:Integer;
begin
 if Button<>mbLeft then Exit;
 I:=X*8 div Keys.Width;if (I<0) or (I>7) then Exit;
 TPaintBoxAccess(Keys).MouseCapture:=True;
 FMouseMask:=1 shl I;UpdateManual;
end;
procedure TFrmOrgan.KeysMouseUp(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
begin TPaintBoxAccess(Keys).MouseCapture:=False;FMouseMask:=0;UpdateManual end;
procedure TFrmOrgan.FormDeactivateHandler(Sender:TObject);
begin
 if Assigned(Keys) then TPaintBoxAccess(Keys).MouseCapture:=False;
 FPCMask:=0;FMouseMask:=0;UpdateManual;
end;
procedure TFrmOrgan.FormCloseHandler(Sender:TObject;var Action:TCloseAction);
begin FormDeactivateHandler(Sender);Action:=caHide end;
procedure TFrmOrgan.RefreshTimerTick(Sender:TObject);
begin if Visible then Keys.Invalidate end;
procedure TFrmOrgan.PaintKeys(Sender:TObject);
const Names:array[0..7] of string=('ド','レ','ミ','ファ','ソ','ラ','シ','ド');
      PC:array[0..7] of string=('Z','X','C','V','B','N','M',',');
var I,L,R:Integer;C:TCanvas;
begin
 if FSynth=nil then Exit;C:=Keys.Canvas;
 C.Font.Name:='Meiryo UI';C.Font.Size:=10;C.Pen.Color:=clGray;
 for I:=0 to 7 do
 begin
  L:=I*Keys.Width div 8;R:=(I+1)*Keys.Width div 8;
  if (FSynth.GateMask and (1 shl I))<>0 then C.Brush.Color:=$00B8E8FF
  else C.Brush.Color:=clWhite;
  C.Rectangle(L,0,R,Keys.Height);
  C.Font.Color:=clBlack;C.Brush.Style:=bsClear;
  C.TextOut(L+10,20,Names[I]);C.TextOut(L+10,55,IntToStr(OrganFrequencies[I])+' Hz');
  C.TextOut(L+10,90,PC[I]);C.Brush.Style:=bsSolid;
 end;
end;
end.
