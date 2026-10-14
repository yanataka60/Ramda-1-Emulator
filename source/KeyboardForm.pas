unit KeyboardForm;
interface
uses Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics;
type
  TKeyboardSendEvent = procedure(Code: Byte) of object;
  TAttentionLevelEvent = procedure(HighLevel: Boolean) of object;
  TFrmKeyboard = class(TForm)
  published
    Key01: TPaintBox;
    Key02: TPaintBox;
    Key03: TPaintBox;
    Key04: TPaintBox;
    Key05: TPaintBox;
    Key06: TPaintBox;
    Key07: TPaintBox;
    Key08: TPaintBox;
    Key09: TPaintBox;
    Key10: TPaintBox;
    Key11: TPaintBox;
    Key12: TPaintBox;
    Key13: TPaintBox;
    Key14: TPaintBox;
    Key15: TPaintBox;
    Key16: TPaintBox;
    Key17: TPaintBox;
    Key18: TPaintBox;
    Key19: TPaintBox;
    Key20: TPaintBox;
    Key21: TPaintBox;
    Key22: TPaintBox;
    Key23: TPaintBox;
    Key24: TPaintBox;
    Key25: TPaintBox;
    Key26: TPaintBox;
    Key27: TPaintBox;
    Key28: TPaintBox;
    Key29: TPaintBox;
    Key30: TPaintBox;
    Key31: TPaintBox;
    Key32: TPaintBox;
    Key33: TPaintBox;
    Key34: TPaintBox;
    Key35: TPaintBox;
    Key36: TPaintBox;
    Key37: TPaintBox;
    Key38: TPaintBox;
    Key39: TPaintBox;
    Key40: TPaintBox;
    Key41: TPaintBox;
    Key42: TPaintBox;
    Key43: TPaintBox;
    Key44: TPaintBox;
    Key45: TPaintBox;
    Key46: TPaintBox;
    Key47: TPaintBox;
    Key48: TPaintBox;
    Key49: TPaintBox;
    Key50: TPaintBox;
    Key51: TPaintBox;
    Key52: TPaintBox;
    Key53: TPaintBox;
    Key54: TPaintBox;
    Key55: TPaintBox;
    Key56: TPaintBox;
    Key57: TPaintBox;
    Key58: TPaintBox;
    procedure KeyPaint(Sender: TObject);
    procedure KeyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure KeyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure KeyCapClick(Sender: TObject);
    procedure FormDeactivateHandler(Sender: TObject);
    procedure FormCloseHandler(Sender: TObject; var Action: TCloseAction);
  private
    FOnSendKey: TKeyboardSendEvent;
    FOnAttentionLevel: TAttentionLevelEvent;
    FPressedKey: TPaintBox;
    procedure ReleasePressedKey;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateKeyboard(AOwner: TComponent; AOnSendKey: TKeyboardSendEvent; AOnAttentionLevel: TAttentionLevelEvent);
  end;
implementation
{$R *.dfm}

type
  { Access to the inherited protected property only. The DFM components
    remain standard TPaintBox objects; no component registration is needed. }
  TPaintBoxAccess = class(TPaintBox);

procedure TFrmKeyboard.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
  Params.WndParent := 0;
end;
constructor TFrmKeyboard.CreateKeyboard(AOwner: TComponent; AOnSendKey: TKeyboardSendEvent; AOnAttentionLevel: TAttentionLevelEvent);
begin
  inherited Create(AOwner);
  FOnSendKey := AOnSendKey;
  FOnAttentionLevel := AOnAttentionLevel;
end;
procedure TFrmKeyboard.KeyPaint(Sender: TObject);
var
  B: TPaintBox;
  R: TRect;
  P, BaseCol, HiCol, LoCol: TColor;
  S1, S2: string;
  N: Integer;
begin
  B := TPaintBox(Sender);
  R := B.ClientRect;
  if ((B.Tag and $100) <> 0) then BaseCol := RGB(154, 151, 142)
                 else BaseCol := RGB(92, 91, 86);
  HiCol := RGB(205, 202, 192);
  LoCol := RGB(38, 38, 36);
  if (FPressedKey = B) then begin P:=HiCol; HiCol:=LoCol; LoCol:=P end;

  B.Canvas.Brush.Color := RGB(30, 30, 28);
  B.Canvas.Pen.Style := psClear;
  B.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 5, 5);

  InflateRect(R, -2, -2);
  B.Canvas.Brush.Color := BaseCol;
  B.Canvas.Pen.Color := LoCol;
  B.Canvas.Pen.Style := psSolid;
  B.Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);
  B.Canvas.Pen.Color := HiCol;
  B.Canvas.MoveTo(R.Left+2, R.Bottom-2);
  B.Canvas.LineTo(R.Left+2, R.Top+2);
  B.Canvas.LineTo(R.Right-2, R.Top+2);

  B.Canvas.Brush.Style := bsClear;
  B.Canvas.Font.Assign(B.Font);

  N := Pos(#10, B.Hint);
  if N > 0 then begin
    S1 := Copy(B.Hint,1,N-1); S2 := Copy(B.Hint,N+1,MaxInt);
    B.Canvas.TextOut((B.Width-B.Canvas.TextWidth(S1)) div 2, 4, S1);
    B.Canvas.TextOut((B.Width-B.Canvas.TextWidth(S2)) div 2, B.Height-B.Canvas.TextHeight(S2)-4, S2);
  end else begin
    B.Canvas.TextOut((B.Width-B.Canvas.TextWidth(B.Hint)) div 2,
      (B.Height-B.Canvas.TextHeight(B.Hint)) div 2, B.Hint);
  end;
end;

procedure TFrmKeyboard.ReleasePressedKey;
var B: TPaintBox;
begin
  B := FPressedKey;
  FPressedKey := nil;
  if B = nil then Exit;
  TPaintBoxAccess(B).MouseCapture := False;
  if ((B.Tag and $FF) = $FF) and Assigned(FOnAttentionLevel) then
    FOnAttentionLevel(True);
  B.Invalidate;
end;
procedure TFrmKeyboard.KeyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  if Button <> mbLeft then Exit;
  ReleasePressedKey;
  FPressedKey := TPaintBox(Sender);
  TPaintBoxAccess(FPressedKey).MouseCapture := True;
  if ((FPressedKey.Tag and $FF) = $FF) and Assigned(FOnAttentionLevel) then
    FOnAttentionLevel(False);
  FPressedKey.Invalidate;
end;
procedure TFrmKeyboard.KeyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  if Button = mbLeft then ReleasePressedKey;
end;
procedure TFrmKeyboard.KeyCapClick(Sender: TObject);
begin
  if Assigned(FOnSendKey) then FOnSendKey(Byte(TPaintBox(Sender).Tag and $FF));
end;
procedure TFrmKeyboard.FormDeactivateHandler(Sender: TObject);
begin
  ReleasePressedKey;
  if Assigned(FOnAttentionLevel) then FOnAttentionLevel(True);
end;
procedure TFrmKeyboard.FormCloseHandler(Sender: TObject; var Action: TCloseAction);
begin
  FormDeactivateHandler(Self);
  Action := caHide;
end;
end.
