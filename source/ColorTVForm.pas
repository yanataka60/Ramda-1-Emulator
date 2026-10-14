unit ColorTVForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Forms, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls,
  MC6847Display;

type
  TFrmColorTV = class(TForm)
  published
    FScreen: TPaintBox;
    FTimer: TTimer;
    procedure FormDeactivateHandler(Sender: TObject);
    procedure PaintScreen(Sender: TObject);
    procedure TimerTick(Sender: TObject);

  private
    FMem: PByte;
    FControl: PByte;
    FVramBase: Word;

    function MemByte(A: Word): Byte;
    function VramByte(Ofs: Integer): Byte;
    function Mode: Integer;
    function VramRangeText: string;
    procedure DrawDisplay(C: TCanvas; const R: TRect);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateForMemory(AOwner: TComponent; AMem, AControl: PByte; AVramBase: Word);
  end;

implementation

{$R *.dfm}

const
  VRAM_SIZE = $0400; { 1KB display RAM; text uses its first 512 bytes. }

procedure TFrmColorTV.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
  { Independent top-level window: do not keep the main panel permanently behind it. }
  Params.WndParent := 0;
end;

constructor TFrmColorTV.CreateForMemory(AOwner: TComponent; AMem, AControl: PByte; AVramBase: Word);
begin
  inherited Create(AOwner);
  FMem := AMem;
  FControl := AControl;
  FVramBase := AVramBase;
  FTimer.Enabled := True;
end;

function TFrmColorTV.MemByte(A: Word): Byte;
begin
  Result := PByte(NativeUInt(FMem) + A)^;
end;

function TFrmColorTV.VramByte(Ofs: Integer): Byte;
begin
  Result := MemByte(FVramBase + Word(Ofs and (VRAM_SIZE - 1)));
end;

function TFrmColorTV.Mode: Integer;
begin
  if FControl = nil then Exit(0);
  if (FControl^ and $01) = 0 then Result := 0
  else if (FControl^ and $02) = 0 then Result := 1
  else Result := 2;
end;

function TFrmColorTV.VramRangeText: string;
var LastOffset:Word;
begin
 if Mode=0 then LastOffset:=$01FF else LastOffset:=$03FF;
 Result:=IntToHex(FVramBase,4)+'-'+IntToHex(FVramBase+LastOffset,4);
end;

procedure TFrmColorTV.TimerTick(Sender: TObject);
begin
  if Visible then FScreen.Invalidate;
end;

procedure TFrmColorTV.DrawDisplay(C: TCanvas; const R: TRect);
const
  Colours: array[0..8] of TColor = (
    $0000D200, $0000DCE6, $00EB5028, $002328E1,
    $00AFDCEB, $00D2D200, $00D72DD7, $001491F5, clBlack);
type
  TPixelRow = array[0..MC6847Width - 1] of Cardinal;
  PPixelRow = ^TPixelRow;
var
  X, Y, Offset, OldStretchMode, DisplayMode: Integer;
  Data, Colour: Byte;
  CSS: Boolean;
  Bitmap: TBitmap;
  Pixels: PPixelRow;
  RGBValue: Cardinal;
  NativeColours: array[0..8] of Cardinal;
  Snapshot: array[0..VRAM_SIZE - 1] of Byte;
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;
  DisplayMode := Mode;
  CSS := (FControl <> nil) and ((FControl^ and $08) <> 0);
  for Offset := 0 to VRAM_SIZE - 1 do Snapshot[Offset] := VramByte(Offset);
  for X := 0 to 8 do
  begin
    RGBValue := Cardinal(ColorToRGB(Colours[X]));
    { TColor is 00BBGGRR, while a 32-bit DIB stores bytes B,G,R,0. }
    NativeColours[X] := ((RGBValue and $FF) shl 16) or
                        (RGBValue and $FF00) or ((RGBValue shr 16) and $FF);
  end;
  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf32bit;
    Bitmap.SetSize(MC6847Width, MC6847Height);
    for Y := 0 to MC6847Height - 1 do
    begin
      Pixels := Bitmap.ScanLine[Y];
      for X := 0 to MC6847Width - 1 do
      begin
        if DisplayMode = 0 then
        begin
          Offset := MC6847TextOffset(X, Y);
          Data := Snapshot[Offset];
          Colour := MC6847CellPixel(Data, X mod MC6847CellWidth,
                                   Y mod MC6847CellHeight, CSS);
        end
        else
        begin
          Offset := MC6847GraphicsOffset(DisplayMode = 2, X, Y);
          Data := Snapshot[Offset];
          Colour := MC6847GraphicsPixel(Data, X, CSS, DisplayMode = 2);
        end;
        Pixels^[X] := NativeColours[Colour];
      end;
    end;
    { One blit per frame; exact native pixels, without per-dot GDI calls. }
    OldStretchMode := SetStretchBltMode(C.Handle, COLORONCOLOR);
    try
      C.StretchDraw(R, Bitmap);
    finally
      SetStretchBltMode(C.Handle, OldStretchMode);
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TFrmColorTV.PaintScreen(Sender: TObject);
var C:TCanvas; bezel,crt:TRect; m:Integer; labelText:string; BorderColour:TColor;
begin
  C:=FScreen.Canvas;
  C.Brush.Color:=RGB(46,44,40); C.FillRect(FScreen.ClientRect);
  bezel:=Rect(38,28,FScreen.Width-38,FScreen.Height-48);
  C.Pen.Width:=5; C.Pen.Color:=RGB(20,20,18); C.Brush.Color:=RGB(72,69,61); C.RoundRect(bezel.Left,bezel.Top,bezel.Right,bezel.Bottom,24,24);
  crt:=Rect(bezel.Left+28,bezel.Top+25,bezel.Right-28,bezel.Bottom-25);
  BorderColour:=clBlack;
  if FControl<>nil then
    case MC6847BorderColour(FControl^) of
      0: BorderColour:=RGB(0,210,0);
      4: BorderColour:=RGB(235,220,175);
    end;
  C.Pen.Width:=3; C.Pen.Color:=RGB(110,108,100); C.Brush.Color:=BorderColour; C.RoundRect(crt.Left,crt.Top,crt.Right,crt.Bottom,28,28);
  InflateRect(crt,-12,-10);
  m:=Mode;
  DrawDisplay(C,crt);
  C.Brush.Style:=bsClear; C.Font.Name:='Arial'; C.Font.Size:=8; C.Font.Color:=RGB(205,200,184);
  case m of
    0: labelText:='CHARACTER / SG4';
    1: labelText:='GRAPHICS 64x64';
  else labelText:='GRAPHICS 128x64'; end;
  labelText:=labelText+'   VRAM '+VramRangeText;
  C.TextOut(48,FScreen.Height-37,Format('Ramda1 COLOR TV   %s',[labelText]));
end;

procedure TFrmColorTV.FormDeactivateHandler(Sender: TObject);
begin
  if (Owner is TForm) and Assigned(TForm(Owner).OnDeactivate) then
    TForm(Owner).OnDeactivate(Sender);
end;

end.
