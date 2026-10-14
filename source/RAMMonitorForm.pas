unit RAMMonitorForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Forms, Vcl.Controls, Vcl.Grids, Vcl.ExtCtrls, Vcl.Graphics,
  RAMFileForm;

type
  TFrmRAMMonitor = class(TForm)
  published
    FGrid: TDrawGrid;
    FTimer: TTimer;
    procedure FormDeactivateHandler(Sender: TObject);
    procedure DrawCell(Sender: TObject; ACol, ARow: Integer;
      R: TRect; State: TGridDrawState);
    procedure ViewScrolled(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure FormCloseHandler(Sender: TObject; var Action: TCloseAction);

  private
    FMemory: PRAM64K;
    FLastImage: array[0..65535] of Byte;
    FHaveImage: Boolean;
    procedure RefreshView(Force: Boolean);

  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateForMemory(AOwner: TComponent; AMemory: PRAM64K);
    procedure ForceRefresh;
  end;

implementation

{$R *.dfm}

procedure TFrmRAMMonitor.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
  Params.WndParent := 0;
end;

constructor TFrmRAMMonitor.CreateForMemory(AOwner: TComponent; AMemory: PRAM64K);
begin
  inherited Create(AOwner);
  FMemory := AMemory;
  FGrid.Canvas.Font.Assign(FGrid.Font);
  FGrid.DefaultRowHeight := FGrid.Canvas.TextHeight('0')+6;
  FGrid.ColWidths[0] := FGrid.Canvas.TextWidth('ADDRESS')+16;
  FGrid.ColWidths[1] := FGrid.Canvas.TextWidth('00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F')+16;
  FGrid.ColWidths[2] := FGrid.Canvas.TextWidth('................')+16;
  ClientWidth := FGrid.ColWidths[0]+FGrid.ColWidths[1]+FGrid.ColWidths[2]+
    3*FGrid.GridLineWidth+GetSystemMetrics(SM_CXVSCROLL)+4;
  Constraints.MinWidth := Width;
  FTimer.Enabled := True;
  RefreshView(True);
end;

procedure TFrmRAMMonitor.FormCloseHandler(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TFrmRAMMonitor.TimerTick(Sender: TObject);
begin
  if Visible then RefreshView(False);
end;

procedure TFrmRAMMonitor.ViewScrolled(Sender: TObject);
begin
  ForceRefresh;
end;

procedure TFrmRAMMonitor.ForceRefresh;
begin
  RefreshView(True);
end;

procedure TFrmRAMMonitor.RefreshView(Force: Boolean);
var First, Count: Integer;
begin
  if FMemory=nil then Exit;
  First := (FGrid.TopRow-1)*16;
  if First<0 then First:=0;
  Count := (FGrid.ClientHeight div FGrid.DefaultRowHeight+2)*16;
  if First+Count>65536 then Count:=65536-First;
  { Only visible bytes are checked. A snapshot copy costs 64KB, with no
    byte-to-text conversion for off-screen rows and no memo reallocation. }
  if not Force and FHaveImage and
    CompareMem(@FLastImage[First],@FMemory^[First],Count) then Exit;
  Move(FMemory^[0],FLastImage[0],65536);
  FHaveImage := True;
  FGrid.Invalidate;
end;

procedure TFrmRAMMonitor.DrawCell(Sender: TObject; ACol, ARow: Integer;
  R: TRect; State: TGridDrawState);
const Digits='0123456789ABCDEF';
var S:string; A,I:Integer; B:Byte;
begin
  FGrid.Canvas.Font.Assign(FGrid.Font);
  if gdFixed in State then begin
    FGrid.Canvas.Brush.Color:=clBtnFace;
    FGrid.Canvas.Font.Color:=clWindowText;
  end else if gdSelected in State then begin
    FGrid.Canvas.Brush.Color:=clHighlight;
    FGrid.Canvas.Font.Color:=clHighlightText;
  end else begin
    FGrid.Canvas.Brush.Color:=FGrid.Color;
    FGrid.Canvas.Font.Color:=clWindowText;
  end;
  FGrid.Canvas.FillRect(R);
  S:='';
  if ARow=0 then begin
    case ACol of
      0:S:='ADDRESS';
      1:S:='00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F';
      2:S:='ASCII';
    end;
  end else if FHaveImage then begin
    A:=(ARow-1)*16;
    case ACol of
      0:S:=IntToHex(A,4);
      1:begin
        SetLength(S,47);
        for I:=0 to 15 do begin
          B:=FLastImage[A+I];
          S[I*3+1]:=Digits[(B shr 4)+1];
          S[I*3+2]:=Digits[(B and $0F)+1];
          if I<15 then S[I*3+3]:=' ';
        end;
      end;
      2:begin
        SetLength(S,16);
        for I:=0 to 15 do begin
          B:=FLastImage[A+I];
          if(B>=$20)and(B<=$7E)then S[I+1]:=Char(B) else S[I+1]:='.';
        end;
      end;
    end;
  end;
  FGrid.Canvas.TextRect(R,R.Left+8,R.Top+3,S);
end;

procedure TFrmRAMMonitor.FormDeactivateHandler(Sender: TObject);
begin
  if (Owner is TForm) and Assigned(TForm(Owner).OnDeactivate) then
    TForm(Owner).OnDeactivate(Sender);
end;

end.
