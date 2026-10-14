unit MainForm;
interface
uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types, System.UITypes,
 Vcl.AppEvnts, Vcl.Forms, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Menus,
 EmulatorSettings, ExternalROM, PrinterDevice, PrinterForm, PeripheralRoute, OrganSynth, OrganAudio, OrganForm, MC6800, MC6821PortA, MC6821PortB, MC6847Sync, MC6847Display, CassetteSignal, CassetteForm, RAMFileForm, RAMMonitorForm, ColorTVForm, KeyboardForm;
const
 WM_SHOW_STARTUP_TV = WM_APP + $101;
type
 TFrmMain=class(TForm)
  published
    FileMenu: TMenuItem;
    RAMItem: TMenuItem;
    RunMenu: TMenuItem;
    ResetItem: TMenuItem;
    ViewMenu: TMenuItem;
    PanelRedrawItem: TMenuItem;
    PanelAutoStopItem: TMenuItem;
    RAMMonitorItem: TMenuItem;
    TVItem: TMenuItem;
    KeyboardItem: TMenuItem;
    CassetteItem: TMenuItem;
    OrganItem: TMenuItem;
    PrinterItem: TMenuItem;
    Panel: TPaintBox;
    Timer: TTimer;
    FAppEvents: TApplicationEvents;
    MainMenu: TMainMenu;
    procedure PanelRedrawMenuClick(Sender:TObject);
    procedure PanelAutoStopMenuClick(Sender:TObject);
    procedure PrinterMenuClick(Sender:TObject);
    procedure OrganMenuClick(Sender:TObject);
    procedure Tick(Sender:TObject);
    procedure PaintPanel(Sender:TObject);
    procedure PanelMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    procedure MainDeactivate(Sender:TObject);
    procedure MainActivate(Sender:TObject);
    procedure MainShow(Sender:TObject);
    procedure ApplicationMessage(var Msg:TMsg;var Handled:Boolean);
    procedure RAMFileMenuClick(Sender:TObject);
    procedure ResetMenuClick(Sender:TObject);
    procedure RAMMonitorMenuClick(Sender:TObject);
    procedure ColorTVMenuClick(Sender:TObject);
    procedure KeyboardMenuClick(Sender:TObject);
    procedure CassetteMenuClick(Sender:TObject);

 private
  FPanelRedrawEnabled,FPanelRefreshOnce,FAutoPanelStop:Boolean;
  FPanelSnapshot:TBitmap;
  FPanelSnapshotValid:Boolean;
  FStartupTVPending:Boolean;
  FVramBase:Word;
  FExternalROM:TExternalROM;
  FPrinter:TPrinterDevice; FPrinterForm:TFrmPrinter;
  FPeripheralRoute:TPeripheralRoute;
  FOrganSynth:TOrganSynth; FOrganAudio:TOrganAudio; FOrgan:TFrmOrgan; FOrganIdleCycles:Double;
  FCPU:TMC6800; FMem:array[0..65535] of Byte; FData:Byte; FAddr:Word; FTVControl:Byte; FTV:TFrmColorTV; FRAMMonitor:TFrmRAMMonitor; FKeyboard:TFrmKeyboard;
  FKbdData:Byte;
  FPIAB:TMC6821PortB; FTape:TCassetteSignal; FCassette:TFrmCassette;
  FCPUCounter,FCPUCounterFrequency:Int64; FCPUBudget:Double;
  FPIAA:TMC6821PortA; FVideoSync:TMC6847Sync;
  FDataSw:array[0..7] of Boolean; FAddrSw:array[0..15] of Boolean;
  FRun,FHalt:Boolean; FReadPulse,FWritePulse,FAddressPulse:Integer;
  function HandlePanelFunctionMessage(const Msg:TMsg;Root:HWND):Boolean;
  procedure ShowStartupTV(var Msg:TMessage); message WM_SHOW_STARTUP_TV;
  function Read8(A:Word):Byte; procedure Write8(A:Word;V:Byte);

  procedure DrawToggle(C:TCanvas;R:TRect;OnState:Boolean;Blue:Boolean;const Caption:string; Momentary:Boolean=False);
  procedure DrawMetalToggle(C:TCanvas;R:TRect;OnState:Boolean;const Caption:string; Momentary:Boolean=False);
  procedure Draw7Seg(C:TCanvas;X,Y:Integer;V:Integer);
  procedure DrawPanelLogo(C:TCanvas;X,Y:Integer);
  procedure RefreshPanelOnce;
  procedure SetPanelRedrawEnabled(Enabled:Boolean);
  procedure CheckMonitorPanelRedraw;
  procedure UpdateFromSwitches; procedure DMARead; procedure DMAWrite; procedure DoReset;

  procedure KeyboardInput(Code:Byte);

  procedure RaiseRelatedWindows;
  procedure PlaceBesideMain(F:TForm;RightSide:Boolean);
  procedure EnsurePanelOnScreen(F:TForm);
  procedure PIAIRQAChanged(HighLevel:Boolean);
  procedure AttentionLevel(HighLevel:Boolean);
  procedure UpdateVideoPins;
  function LoadStartupMonitor:Boolean;

  procedure TapeInputLevel(HighLevel:Boolean);
  procedure UpdatePortBOutputs;
 protected
  procedure CreateParams(var Params: TCreateParams); override;
 public constructor Create(AOwner:TComponent); override; destructor Destroy; override;
 end;
var FrmMain:TFrmMain;
implementation

{$R *.dfm}
procedure TFrmMain.CreateParams(var Params: TCreateParams);
begin
 inherited CreateParams(Params);
 { Main window: force a normal top-level application window so Windows gives
   Ramda1 its own taskbar button. }
 Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
 Params.WndParent := 0;
end;
constructor TFrmMain.Create(AOwner:TComponent);
var Counter,Frequency:Int64;
begin
 inherited Create(AOwner);
 Icon.Assign(Application.Icon);
 FPanelSnapshot:=TBitmap.Create;
 FPanelSnapshotValid:=False;
 FPanelRedrawEnabled:=True;
 FAutoPanelStop:=Ramda1Settings.AutoPanelStop;
 PanelAutoStopItem.Checked:=FAutoPanelStop;
 FPrinter:=TPrinterDevice.Create;
 FPeripheralRoute:=TPeripheralRoute.Create;
 FOrganSynth:=TOrganSynth.Create; FOrganAudio:=nil; FOrgan:=nil;
 FTVControl:=0; FTV:=nil; FRAMMonitor:=nil; FKeyboard:=nil;
 FKbdData:=$7F; FCassette:=nil;
 FPIAB:=TMC6821PortB.Create; FTape:=TCassetteSignal.Create; FTape.OnInput:=TapeInputLevel;
 QueryPerformanceFrequency(Frequency); QueryPerformanceCounter(Counter);
 FVideoSync:=TMC6847Sync.Create(Frequency,Counter);
 FCPUCounterFrequency:=Frequency; FCPUCounter:=Counter; FCPUBudget:=0;
 FPIAA:=TMC6821PortA.Create;

 FStartupTVPending:=LoadStartupMonitor;
 FVramBase:=$F800;
 if FStartupTVPending then FVramBase:=$F000;
 FExternalROM:=TExternalROM.Create;
 FExternalROM.LoadStartup(ExtractFilePath(ParamStr(0)),PExternalMemory(@FMem));
 if FExternalROM.Warnings<>''then
  MessageDlg(FExternalROM.Warnings,mtWarning,[mbOK],0);
 FCPU:=TMC6800.Create(Read8,Write8);
 FPIAA.OnIRQA:=PIAIRQAChanged;

 Timer.Enabled:=True; DoReset;
end;
procedure TFrmMain.TapeInputLevel(HighLevel:Boolean);
begin
 if HighLevel then FPIAB.InputPins:=FPIAB.InputPins or $80
 else FPIAB.InputPins:=FPIAB.InputPins and $7F;
 FPIAB.SetCB1Level(HighLevel);
end;

procedure TFrmMain.UpdatePortBOutputs;
var Pins:Byte;
begin
 Pins:=FPIAB.OutputPins;
 FPeripheralRoute.Update(Pins,FTape.TransportReady,FTape.TransportGeneration);
 FOrganSynth.SetConnected(FPeripheralRoute.OrganConnected);
 FOrganSynth.SetPortPins(Pins);
 if Assigned(FOrgan) then FOrgan.SetRouteStatus(FPeripheralRoute.OrganConnected,
                                              FPeripheralRoute.CassetteActive);
 if FOrganSynth.Connected then begin
  FTVControl:=0; FTape.SetMotor(False); FTape.SetOutput(True); Exit;
 end;
 FTVControl:=Ramda1TVControl(Pins);
 FTape.SetOutput((Pins and $01)<>0);
 FTape.SetMotor((Pins and $02)=0);
end;

procedure TFrmMain.PrinterMenuClick(Sender:TObject);
begin
 if not Assigned(FPrinterForm) then begin
  FPrinterForm:=TFrmPrinter.CreateForPrinter(Self,FPrinter);
  PlaceBesideMain(FPrinterForm,False);
 end;
 EnsurePanelOnScreen(FPrinterForm); FPrinterForm.Show;FPrinterForm.BringToFront;
end;
procedure TFrmMain.OrganMenuClick(Sender:TObject);
begin
 if not Assigned(FOrgan) then begin
  FOrgan:=TFrmOrgan.CreateForOrgan(Self,FOrganSynth);
  PlaceBesideMain(FOrgan,True);
 end;
 if not Assigned(FOrganAudio) then begin
  FOrganSynth.ClearPending;FOrganAudio:=TOrganAudio.Create;
 end;
 UpdatePortBOutputs;
 FOrgan.SetAudioStatus(FOrganAudio.Active,FOrganAudio.LastResult);
 EnsurePanelOnScreen(FOrgan); FOrgan.Show;FOrgan.BringToFront;
end;

procedure TFrmMain.CassetteMenuClick(Sender:TObject);
begin
 if not Assigned(FCassette)then begin
  FCassette:=TFrmCassette.CreateForTape(Self,FTape); PlaceBesideMain(FCassette,False);
 end;
 EnsurePanelOnScreen(FCassette); FCassette.Show;FCassette.BringToFront;
end;

function TFrmMain.LoadStartupMonitor:Boolean;
var FileName:string; Stream:TFileStream; Count:Integer;
begin
 Result:=False;
 FileName:=ExtractFilePath(ParamStr(0))+'CHICK-BUG.bin';
 if not FileExists(FileName) then Exit;
 Stream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
 try
  { F800h..FFFFh can hold at most 2048 bytes. }
  if Stream.Size>2048 then Count:=2048 else Count:=Integer(Stream.Size);
  if Count>0 then begin
   Stream.ReadBuffer(FMem[$F800],Count);
   Result:=True;
  end;
 finally
  Stream.Free;
 end;
end;

destructor TFrmMain.Destroy;
begin
  Timer.Enabled:=False;
  Ramda1Settings.AutoPanelStop:=FAutoPanelStop;
  try Ramda1Settings.Save
  except on E:Exception do MessageDlg('設定を保存できません: '+E.Message,mtError,[mbOK],0)end;
  { Auxiliary windows are owned by the main form.  Free them while the
    owner and RAM pointers are still valid, and clear the references to
    prevent a second destruction during application shutdown. }
  FreeAndNil(FPanelSnapshot);
  FreeAndNil(FAppEvents);
  FreeAndNil(FExternalROM);
  FreeAndNil(FPrinterForm);
  FreeAndNil(FPrinter);
  FreeAndNil(FOrgan);
  FreeAndNil(FOrganAudio);
  FreeAndNil(FOrganSynth);
  FreeAndNil(FPeripheralRoute);
  FreeAndNil(FCassette);
  FreeAndNil(FTape);
  FreeAndNil(FPIAB);
  FreeAndNil(FKeyboard);
  FreeAndNil(FRAMMonitor);
  FreeAndNil(FTV);
  FreeAndNil(FPIAA);
  FreeAndNil(FVideoSync);
  FreeAndNil(FCPU);
  inherited;
end;
procedure TFrmMain.PIAIRQAChanged(HighLevel:Boolean);
begin
 { Physical IRQA -> NMI wiring, including deassertion. }
 FCPU.SetNMILevel(HighLevel);
end;

procedure TFrmMain.AttentionLevel(HighLevel:Boolean);
begin
 FPIAA.SetCA2Level(HighLevel);
end;

procedure TFrmMain.UpdateVideoPins;
var Counter:Int64; Pins:Byte;
begin
 QueryPerformanceCounter(Counter);
 FVideoSync.AdvanceTo(Counter);
 Pins:=FKbdData and $7F;
 if FVideoSync.FSHigh then Pins:=Pins or $80;
 FPIAA.InputPins:=Pins;
end;

function TFrmMain.Read8(A:Word):Byte;
begin
 case A of
  $D008..$D00B: Result:=FPrinter.ReadRegister(Byte(A-$D008));
  $EE00: begin UpdateVideoPins; Result:=FPIAA.ReadData end;
  $EE01: Result:=FPIAA.ReadControl;
  $EE02: Result:=FPIAB.ReadData;
  $EE03: Result:=FPIAB.ReadControl;
 else Result:=FMem[A];
 end;
end;

procedure TFrmMain.Write8(A:Word;V:Byte);
begin
 case A of
  $D008..$D00B: FPrinter.WriteRegister(Byte(A-$D008),V);
  $EE00: FPIAA.WriteData(V);
  $EE01: FPIAA.WriteControl(V);
  $EE02: begin FPIAB.WriteData(V); UpdatePortBOutputs end;
  $EE03: begin FPIAB.WriteControl(V); UpdatePortBOutputs end;
 else if not FExternalROM.IsReadOnly(A)then FMem[A]:=V;
 end;
end;

procedure TFrmMain.RefreshPanelOnce;
begin
 FPanelRefreshOnce:=True;
 Panel.Invalidate;
end;
procedure TFrmMain.PanelAutoStopMenuClick(Sender:TObject);
begin
 FAutoPanelStop:=not FAutoPanelStop;
 PanelAutoStopItem.Checked:=FAutoPanelStop;
 if not FAutoPanelStop then SetPanelRedrawEnabled(True);
end;
procedure TFrmMain.SetPanelRedrawEnabled(Enabled:Boolean);
begin
 FPanelRedrawEnabled:=Enabled;
 PanelRedrawItem.Checked:=Enabled;
 RefreshPanelOnce;
end;
procedure TFrmMain.PanelRedrawMenuClick(Sender:TObject);
begin
 SetPanelRedrawEnabled(not FPanelRedrawEnabled);
end;
procedure TFrmMain.CheckMonitorPanelRedraw;
begin
 { Detect actual CHICK-BUG cold/warm entry, not its display subroutines.
   RESET only restores redraw; it is stopped when monitor execution starts. }
 if FAutoPanelStop and FPanelRedrawEnabled and(FVramBase=$F000)and
    ((FCPU.PC=$FE78)or(FCPU.PC=$FE88))and
    (FMem[FCPU.PC]=$8E)and(FMem[FCPU.PC+1]=$F7)and(FMem[FCPU.PC+2]=$FF)then
  SetPanelRedrawEnabled(False);
end;

procedure TFrmMain.DoReset;
begin
 { Emulator-only RESET.  Keep RAM/VRAM intact, as a hardware CPU reset does not
   erase memory.  The MC6800 core fetches the reset vector from FFFE/FFFF. }
 SetPanelRedrawEnabled(True);
 FPrinter.Reset;
 FPIAB.Reset; UpdatePortBOutputs; FCPUBudget:=0;
 FPIAA.Reset; { video oscillator and external keyboard pins keep their state }
 FAddr:=0; FData:=0; FRun:=False; FHalt:=True;
 FReadPulse:=0; FWritePulse:=0; FAddressPulse:=0;
 FCPU.Reset;
 FCPU.SetNMILevel(FPIAA.IRQAHigh);
 FAddr:=FCPU.PC;
 FData:=FMem[FAddr];
 if Assigned(FTV) then FTV.Invalidate;
 RefreshPanelOnce;
end;
procedure TFrmMain.UpdateFromSwitches; var i:Integer; begin FData:=0;for i:=0 to 7 do if FDataSw[i] then FData:=FData or (1 shl i);end;
procedure TFrmMain.DMARead;
begin
 FAddr:=Word((Cardinal(FAddr)+1)and $FFFF);
 FData:=FMem[FAddr];
 RefreshPanelOnce;
end;
procedure TFrmMain.DMAWrite;
begin
 { Write the value currently shown, then advance and read the next address. }
 if not FExternalROM.IsReadOnly(FAddr)then FMem[FAddr]:=FData;
 FAddr:=Word((Cardinal(FAddr)+1)and $FFFF);
 FData:=FMem[FAddr];
 RefreshPanelOnce;
end;
procedure TFrmMain.Tick(Sender:TObject); var Cycles,Instructions:Integer; Counter:Int64; changed:Boolean; begin
 UpdateVideoPins;
 UpdatePortBOutputs;
 changed:=False;
 if FReadPulse>0 then begin Dec(FReadPulse); if FReadPulse=0 then changed:=True end;
 if FWritePulse>0 then begin Dec(FWritePulse); if FWritePulse=0 then changed:=True end;
 if FAddressPulse>0 then begin Dec(FAddressPulse); if FAddressPulse=0 then changed:=True end;
 QueryPerformanceCounter(Counter);
 if FRun and not FHalt then begin
  FCPUBudget:=FCPUBudget+(Counter-FCPUCounter)*FTape.CPUHz/FCPUCounterFrequency;
  Instructions:=0;
  while (FCPUBudget>0)and(Instructions<20000) do begin
   if(FCPU.PC=$FE78)or(FCPU.PC=$FE88)then CheckMonitorPanelRedraw;
   Cycles:=FCPU.Step; FCPUBudget:=FCPUBudget-Cycles; FTape.Advance(Cycles);FOrganSynth.Advance(Cycles);FPrinter.Advance(Cycles);Inc(Instructions);
  end;
  FAddr:=FCPU.PC;FData:=FMem[FAddr];changed:=True;
 end else begin
  FCPUBudget:=0;
  { OSC board keeps running even while the CPU is halted. }
  FOrganIdleCycles:=FOrganIdleCycles+(Counter-FCPUCounter)*OrganCPUHz/FCPUCounterFrequency;
  Cycles:=Trunc(FOrganIdleCycles);FOrganIdleCycles:=FOrganIdleCycles-Cycles;
  FOrganSynth.Advance(Cycles);FPrinter.Advance(Cycles);
 end;
 if Assigned(FOrganAudio) then FOrganAudio.Pump(FOrganSynth)
 else FOrganSynth.ClearPending;
 FCPUCounter:=Counter;
 if changed and FPanelRedrawEnabled then RefreshPanelOnce;
end;
procedure TFrmMain.DrawToggle(C:TCanvas;R:TRect;OnState:Boolean;Blue:Boolean;const Caption:string; Momentary:Boolean=False);
var body,side,light,tip:TColor; cx,cy:Integer;
    base:array[0..3] of TPoint; face:array[0..3] of TPoint;
begin
 C.Pen.Style:=psSolid;
 C.Font.Name:='Arial'; C.Font.Size:=7; C.Font.Style:=[]; C.Font.Color:=RGB(210,205,190); C.Brush.Style:=bsClear;
 C.TextOut(R.Left+(R.Width-C.TextWidth(Caption)) div 2,R.Top-18,Caption);
 { fixed recessed switch body }
 C.Brush.Style:=bsSolid; C.Pen.Color:=RGB(4,4,4); C.Brush.Color:=RGB(8,8,8);
 C.Rectangle(R.Left-5,R.Top-5,R.Right+5,R.Bottom+5);
 C.Pen.Color:=RGB(58,57,52); C.Brush.Color:=RGB(20,20,18);
 C.Rectangle(R.Left,R.Top,R.Right,R.Bottom);
 cx:=(R.Left+R.Right) div 2; cy:=R.Top+17;
 { fixed pivot: the paddle rotates around this point instead of sliding }
 C.Pen.Color:=RGB(126,123,113); C.Brush.Color:=RGB(64,62,56); C.Ellipse(cx-8,cy-7,cx+8,cy+7);
 C.Pen.Color:=RGB(225,222,207); C.Brush.Color:=RGB(150,147,135); C.Ellipse(cx-5,cy-4,cx+5,cy+4);
 if Blue then begin body:=RGB(30,143,229);side:=RGB(7,68,124);light:=RGB(181,228,255);tip:=RGB(20,112,190) end
 else begin body:=RGB(246,241,213);side:=RGB(143,136,108);light:=RGB(255,255,247);tip:=RGB(220,214,183) end;
 { perspective paddle.  The hinge stays fixed; only the free end swings. }
 if OnState then begin
  { lever thrown upward: short visible top face, lower edge recedes into pivot }
  base[0]:=Point(cx-8,cy+1); base[1]:=Point(cx+8,cy-1);
  base[2]:=Point(cx+12,R.Top+5); base[3]:=Point(cx-10,R.Top+8);
  face[0]:=Point(cx-10,R.Top+8); face[1]:=Point(cx+12,R.Top+5);
  face[2]:=Point(cx+10,R.Top+16); face[3]:=Point(cx-11,R.Top+19);
 end else begin
  { lever thrown toward viewer/down: long projecting paddle }
  base[0]:=Point(cx-8,cy-1); base[1]:=Point(cx+8,cy+1);
  base[2]:=Point(cx+13,R.Bottom-7); base[3]:=Point(cx-12,R.Bottom-3);
  face[0]:=Point(cx-12,cy+5); face[1]:=Point(cx+10,cy+3);
  face[2]:=Point(cx+13,R.Bottom-7); face[3]:=Point(cx-12,R.Bottom-3);
 end;
 { heavy shadow separates the projecting lever from the panel }
 C.Pen.Color:=RGB(2,2,2); C.Brush.Color:=RGB(2,2,2);
 C.Polygon([Point(base[0].X+3,base[0].Y+4),Point(base[1].X+3,base[1].Y+4),Point(base[2].X+3,base[2].Y+4),Point(base[3].X+3,base[3].Y+4)]);
 C.Pen.Color:=RGB(4,4,4); C.Brush.Color:=side; C.Polygon(base);
 C.Pen.Color:=light; C.Brush.Color:=body; C.Polygon(face);
 { bright edge and thick free-end face make the paddle look three-dimensional }
 C.Pen.Color:=light; C.Pen.Width:=2; C.MoveTo(face[0].X+1,face[0].Y+1); C.LineTo(face[1].X-1,face[1].Y+1); C.Pen.Width:=1;
 if OnState then begin
  C.Pen.Color:=side; C.Brush.Color:=tip; C.Polygon([Point(cx-10,R.Top+8),Point(cx+12,R.Top+5),Point(cx+10,R.Top+10),Point(cx-9,R.Top+13)]);
 end else begin
  C.Pen.Color:=side; C.Brush.Color:=tip; C.Polygon([Point(cx-12,R.Bottom-3),Point(cx+13,R.Bottom-7),Point(cx+11,R.Bottom),Point(cx-10,R.Bottom+2)]);
 end;
 { pivot cap is drawn last so the lever visibly emerges from a fixed hinge }
 C.Pen.Color:=RGB(238,235,220); C.Brush.Color:=RGB(112,109,99); C.Ellipse(cx-3,cy-3,cx+3,cy+3);
end;
procedure TFrmMain.DrawMetalToggle(C:TCanvas;R:TRect;OnState:Boolean;const Caption:string; Momentary:Boolean=False);
var cx,cy,tx,ty:Integer; ang:Double; dx,dy,nx,ny,len:Double;
begin
 C.Pen.Style:=psSolid; { essential: otherwise toggle shaft is invisible after 7-seg drawing }
 C.Font.Name:='Arial'; C.Font.Size:=7; C.Font.Style:=[]; C.Font.Color:=RGB(232,230,220); C.Brush.Style:=bsClear;
 C.TextOut(R.Left+(R.Width-C.TextWidth(Caption)) div 2,R.Top-19,Caption);
 cx:=(R.Left+R.Right) div 2; cy:=(R.Top+R.Bottom) div 2+3;
 { Make the mounting hardware visible against the original dark panel. }
 C.Brush.Style:=bsSolid; C.Pen.Width:=1;
 C.Pen.Color:=RGB(8,8,8); C.Brush.Color:=RGB(22,22,21); C.Ellipse(cx-16,cy-16,cx+16,cy+16);
 C.Pen.Color:=RGB(232,230,220); C.Brush.Color:=RGB(122,120,112); C.Ellipse(cx-13,cy-13,cx+13,cy+13);
 C.Pen.Color:=RGB(74,72,67); C.Brush.Color:=RGB(178,175,164); C.Ellipse(cx-10,cy-10,cx+10,cy+10);
 C.Pen.Color:=RGB(248,247,240); C.Arc(cx-9,cy-9,cx+9,cy+9,cx-7,cy-7,cx+6,cy-8);
 C.Pen.Color:=RGB(5,5,5); C.Brush.Color:=RGB(20,20,19); C.Ellipse(cx-6,cy-6,cx+6,cy+6);
 { Longer, thicker bright lever.  Its direction is the state indicator. }
 if OnState then ang:=-0.88 else ang:=0.72;
 tx:=cx+Round(Cos(ang)*31); ty:=cy+Round(Sin(ang)*31);
 dx:=tx-cx; dy:=ty-cy; len:=Sqrt(dx*dx+dy*dy);
 if len<1 then len:=1;
 nx:=-dy/len; ny:=dx/len;
 { dark drop shadow }
 C.Pen.Width:=10; C.Pen.Color:=RGB(4,4,4); C.MoveTo(cx+3,cy+4); C.LineTo(tx+3,ty+4);
 { steel body }
 C.Pen.Width:=8; C.Pen.Color:=RGB(126,125,120); C.MoveTo(cx,cy); C.LineTo(tx,ty);
 C.Pen.Width:=6; C.Pen.Color:=RGB(218,217,211); C.MoveTo(cx-Round(nx),cy-Round(ny)); C.LineTo(tx-Round(nx),ty-Round(ny));
 { specular highlight makes the shaft readable on black }
 C.Pen.Width:=2; C.Pen.Color:=RGB(255,255,252); C.MoveTo(cx+Round(nx*2),cy+Round(ny*2)); C.LineTo(tx+Round(nx*2),ty+Round(ny*2));
 { larger cylindrical knob }
 C.Pen.Width:=1; C.Pen.Color:=RGB(54,53,50); C.Brush.Color:=RGB(210,209,203); C.Ellipse(tx-7,ty-7,tx+7,ty+7);
 C.Pen.Color:=RGB(255,255,252); C.Brush.Color:=RGB(242,241,235); C.Ellipse(tx-5,ty-5,tx+4,ty+4);
 C.Pen.Color:=RGB(132,130,124); C.MoveTo(tx+4,ty-4); C.LineTo(tx+6,ty+4);
 { subtle direction marks }
 C.Font.Size:=6; C.Font.Color:=RGB(190,187,176); C.Brush.Style:=bsClear;
 C.TextOut(cx-3,R.Top-2,'↑'); C.TextOut(cx-3,R.Bottom-8,'↓');
 C.Pen.Width:=1;
end;

procedure TFrmMain.Draw7Seg(C:TCanvas;X,Y,V:Integer);const seg:array[0..15]of Byte=($3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$77,$7C,$39,$5E,$79,$71);var s:Byte;
 procedure Bar(x1,y1,x2,y2:Integer;onx:Boolean);begin if onx then C.Brush.Color:=RGB(255,38,18) else C.Brush.Color:=RGB(54,5,3);C.Pen.Style:=psClear;C.FillRect(Rect(X+x1,Y+y1,X+x2,Y+y2));end;
begin s:=seg[V and 15];Bar(4,0,21,4,(s and 1)<>0);Bar(21,4,25,20,(s and 2)<>0);Bar(21,24,25,40,(s and 4)<>0);Bar(4,40,21,44,(s and 8)<>0);Bar(0,24,4,40,(s and 16)<>0);Bar(0,4,4,20,(s and 32)<>0);Bar(4,20,21,24,(s and 64)<>0);C.Pen.Style:=psSolid;end;
procedure TFrmMain.DrawPanelLogo(C:TCanvas;X,Y:Integer);
var SavedPen:TPen; SavedBrush:TBrush;
begin
 SavedPen:=TPen.Create; SavedBrush:=TBrush.Create;
 try
  SavedPen.Assign(C.Pen); SavedBrush.Assign(C.Brush);
  C.Pen.Style:=psClear;
  C.Brush.Style:=bsSolid; C.Brush.Color:=RGB(206,190,146);
  { Entire Lambda-1 mark is geometry: no font or Unicode glyph required. }
  C.Polygon([Point(X,Y+66),Point(X+25,Y),Point(X+39,Y),
             Point(X+64,Y+66),Point(X+50,Y+66),Point(X+32,Y+17),
             Point(X+14,Y+66)]);
  C.FillRect(Rect(X+76,Y+32,X+103,Y+42));
  C.Polygon([Point(X+120,Y+13),Point(X+140,Y),Point(X+153,Y),
             Point(X+153,Y+55),Point(X+169,Y+55),Point(X+169,Y+66),
             Point(X+122,Y+66),Point(X+122,Y+55),Point(X+140,Y+55),
             Point(X+140,Y+16),Point(X+120,Y+28)]);
 finally
  C.Pen.Assign(SavedPen); C.Brush.Assign(SavedBrush);
  SavedBrush.Free; SavedPen.Free;
 end;
end;
procedure TFrmMain.PaintPanel(Sender:TObject);var C:TCanvas;i,x:Integer;begin
 if not FPanelRedrawEnabled and not FPanelRefreshOnce and FPanelSnapshotValid and
    (FPanelSnapshot.Width=Panel.Width)and(FPanelSnapshot.Height=Panel.Height)then begin
  { Expose/reveal still paints the saved image, without rebuilding the panel. }
  Panel.Canvas.Draw(0,0,FPanelSnapshot);Exit;
 end;
 FPanelSnapshot.SetSize(Panel.Width,Panel.Height);
 C:=FPanelSnapshot.Canvas;C.Brush.Color:=RGB(12,12,15);C.FillRect(Panel.ClientRect);
 { blue-grey cabinet edge and black original-style face plate }
 C.Pen.Width:=5;C.Pen.Color:=RGB(62,92,105);C.Brush.Style:=bsClear;C.Rectangle(7,7,Panel.Width-7,Panel.Height-7);
 C.Pen.Width:=2;C.Pen.Color:=RGB(42,40,38);C.Rectangle(20,20,Panel.Width-20,Panel.Height-20);C.Brush.Style:=bsSolid;
 { corner screws }
 C.Brush.Color:=RGB(49,47,39);C.Pen.Color:=RGB(95,91,70);for i:=0 to 3 do begin case i of 0:x:=32;1:x:=Panel.Width-38;2:x:=32;else x:=Panel.Width-38;end;if i<2 then C.Ellipse(x,30,x+12,42) else C.Ellipse(x,Panel.Height-43,x+12,Panel.Height-31);end;
 { LED display - compact upper-left as on original }
 C.Brush.Color:=RGB(29,10,9);C.Pen.Color:=RGB(71,48,37);C.Rectangle(64,92,306,157);C.Brush.Color:=RGB(7,3,3);C.Rectangle(70,98,300,151);
 for i:=0 to 3 do Draw7Seg(C,79+i*33,108,(FAddr shr ((3-i)*4)) and $F);for i:=0 to 1 do Draw7Seg(C,224+i*33,108,(FData shr ((1-i)*4)) and $F);
 { Ramda1 mark }
 DrawPanelLogo(C,382,64);
 C.Font.Name:='Arial';C.Font.Color:=RGB(206,190,146);C.Brush.Style:=bsClear;C.Font.Size:=8;C.Font.Style:=[];C.TextOut(391,135,'MICROCOMPUTER SYSTEM');
 { right control bank: ADDRESS SET / HALT-RUN / GO-RESET }
 DrawMetalToggle(C,Rect(405,238,438,294),FAddressPulse>0,'ADDRESS',True);DrawMetalToggle(C,Rect(455,238,488,294),FHalt,'HALT');DrawMetalToggle(C,Rect(505,238,538,294),FRun,'GO');
 C.Font.Size:=6;C.Font.Color:=RGB(180,172,146);C.TextOut(410,296,'SET');C.TextOut(460,296,'RUN');C.TextOut(507,296,'RESET');
 { READ / WRITE below }
 DrawMetalToggle(C,Rect(430,365,463,421),FReadPulse>0,'READ',True);DrawMetalToggle(C,Rect(486,365,519,421),FWritePulse>0,'WRITE',True);
 { data switches low and left, 7..0; cream for 7..4, blue for 3..0 }
 for i:=7 downto 0 do begin x:=72+(7-i)*47;DrawToggle(C,Rect(x,472,x+31,529),FDataSw[i],i<=3,IntToStr(i));end;
 { only a discreet status line; keep face panel visually close to original }
 C.Font.Name:='Consolas';C.Font.Size:=8;C.Font.Style:=[];C.Font.Color:=RGB(93,91,80);C.Brush.Style:=bsClear;
 C.TextOut(64,615,Format('PC %4.4X   A %2.2X   B %2.2X   X %4.4X   SP %4.4X',[FCPU.PC,FCPU.A,FCPU.B,FCPU.X,FCPU.SP]));
 FPanelSnapshotValid:=True;
 FPanelRefreshOnce:=False;
 Panel.Canvas.Draw(0,0,FPanelSnapshot);
end;
procedure TFrmMain.RAMFileMenuClick(Sender:TObject);
var F:TFrmRAMFile;
begin
 F:=TFrmRAMFile.CreateForMemory(Self,PRAM64K(@FMem));
 try
  PlaceBesideMain(F,False);
  EnsurePanelOnScreen(F); F.ShowModal;
  { RAM file I/O uses its own address fields.  After a successful LOAD,
    show the loaded start address on the front panel for immediate verification/run. }
  if F.LastLoadStart >= 0 then
    FAddr := Word(F.LastLoadStart);
  FData:=FMem[FAddr];
  if Assigned(FRAMMonitor) then FRAMMonitor.ForceRefresh;
  RefreshPanelOnce;
 finally
  F.Free;
 end;
end;

procedure TFrmMain.RAMMonitorMenuClick(Sender:TObject);
begin
 if not Assigned(FRAMMonitor) then begin
  FRAMMonitor:=TFrmRAMMonitor.CreateForMemory(Self,PRAM64K(@FMem));
  PlaceBesideMain(FRAMMonitor,False);
 end;
 if FRAMMonitor.Visible then
  FRAMMonitor.Hide
 else begin
  FRAMMonitor.ForceRefresh;
  EnsurePanelOnScreen(FRAMMonitor); FRAMMonitor.Show;
  FRAMMonitor.BringToFront;
 end;
end;

procedure TFrmMain.ResetMenuClick(Sender:TObject);
begin
 DoReset;
end;

procedure TFrmMain.KeyboardInput(Code:Byte);
begin
 { The UI supplies an encoder strobe event, with no input queue. }
 if Code=$FF then Exit; { ATTENTION uses its separate press/release line }
 FKbdData:=(not Code) and $7F;
 UpdateVideoPins;
 FPIAA.SetCA1Level(False); { AKB3420 active-low STROBE }
 FPIAA.SetCA1Level(True);
end;

procedure TFrmMain.EnsurePanelOnScreen(F:TForm);
var Work:TRect; X,Y:Integer;
begin
 Work:=F.Monitor.WorkareaRect;
 X:=F.Left; Y:=F.Top;
 if X+F.Width>Work.Right then X:=Work.Right-F.Width;
 if Y+F.Height>Work.Bottom then Y:=Work.Bottom-F.Height;
 if X<Work.Left then X:=Work.Left;
 if Y<Work.Top then Y:=Work.Top;
 F.SetBounds(X,Y,F.Width,F.Height);
end;
procedure TFrmMain.PlaceBesideMain(F:TForm;RightSide:Boolean);
const Gap=8;
var Other:TForm; I,Y:Integer; Work:TRect;
begin
 F.Position:=poDesigned; F.DefaultMonitor:=dmDesktop; Y:=Top;
 if RightSide then F.Left:=Left+Width+Gap else F.Left:=Left-F.Width-Gap;
 { Stack only newly opened windows. Existing windows keep their positions. }
 for I:=0 to Screen.FormCount-1 do begin
  Other:=Screen.Forms[I];
  if (Other<>Self)and(Other<>F)and(Other.Owner=Self)and Other.Visible then
   if ((RightSide and(Other.Left>=Left+Width))or
       (not RightSide and(Other.Left+Other.Width<=Left)))and
      (Other.Top+Other.Height+Gap>Y)then Y:=Other.Top+Other.Height+Gap;
 end;
 Work:=Monitor.WorkareaRect;
 if Y+F.Height>Work.Bottom then Y:=Work.Bottom-F.Height;
 if Y<Work.Top then Y:=Work.Top;
 F.Top:=Y;
end;

procedure TFrmMain.RaiseRelatedWindows;
var I:Integer; F:TForm;
begin
 { Raise the group without making it always-on-top or moving keyboard focus. }
 for I:=Screen.FormCount-1 downto 0 do begin
  F:=Screen.Forms[I];
  if (F<>Self)and(F.Owner=Self)and F.Visible and F.HandleAllocated then
   SetWindowPos(F.Handle,HWND_TOP,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
 end;
 if HandleAllocated then
  SetWindowPos(Handle,HWND_TOP,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TFrmMain.MainActivate(Sender:TObject);
begin RaiseRelatedWindows end;

function TFrmMain.HandlePanelFunctionMessage(const Msg:TMsg;Root:HWND):Boolean;
var Key:Word;
begin
 Result:=False;
 if not HandleAllocated then Exit;
 if (Root<>Handle)or(GetAncestor(GetFocus,GA_ROOT)<>Handle)then Exit;
 if (Msg.message<>WM_KEYDOWN)and(Msg.message<>WM_KEYUP)then begin
  { Windows sends bare F10 as a system key too. Preserve Alt shortcuts:
    lParam bit 29 denotes the Alt context. }
  if (Msg.message<>WM_SYSKEYDOWN)and(Msg.message<>WM_SYSKEYUP)then Exit;
  if (Msg.wParam<>VK_F10)or((Msg.lParam and $20000000)<>0)then Exit;
 end;
 if (Msg.wParam<VK_F1)or(Msg.wParam>VK_F12)then Exit;
 { Consume key-down and key-up so F1/F10 do not trigger Help or menu activation.
   Bit 30 is set on repeated key-down messages: one operation per physical press. }
 Result:=True;
 if (Msg.message=WM_KEYUP)or(Msg.message=WM_SYSKEYUP)or
    ((Msg.lParam and $40000000)<>0)then Exit;
 Key:=Word(Msg.wParam);
 case Key of
  VK_F1..VK_F8:PanelMouseDown(nil,mbLeft,[],87+47*(Key-VK_F1),500);
  VK_F9:PanelMouseDown(nil,mbLeft,[],421,266);
  VK_F10:PanelMouseDown(nil,mbLeft,[],446,393);
  VK_F11:PanelMouseDown(nil,mbLeft,[],502,393);
  VK_F12:if FRun and not FHalt then PanelMouseDown(nil,mbLeft,[],471,266)
          else PanelMouseDown(nil,mbLeft,[],521,266);
 end;
end;

procedure TFrmMain.ApplicationMessage(var Msg:TMsg;var Handled:Boolean);
var Root:HWND; IsInput:Boolean; C:Byte;
begin
 if Handled then Exit;
 Root:=GetAncestor(Msg.hwnd,GA_ROOT);
 if HandlePanelFunctionMessage(Msg,Root)then begin Handled:=True;Exit end;
 if HandleAllocated and(Root=Handle)and
    ((Msg.message=WM_LBUTTONDOWN)or(Msg.message=WM_NCLBUTTONDOWN))then
  RaiseRelatedWindows;
 IsInput:=HandleAllocated and(Root=Handle);
 if Assigned(FTV)and FTV.HandleAllocated then IsInput:=IsInput or(Root=FTV.Handle);
 if Assigned(FKeyboard)and FKeyboard.HandleAllocated then IsInput:=IsInput or(Root=FKeyboard.Handle);
 if Assigned(FRAMMonitor)and FRAMMonitor.HandleAllocated then IsInput:=IsInput or(Root=FRAMMonitor.Handle);
 if not IsInput then Exit;
 { File/address edits and system menu shortcuts are left to their own windows. }
 case Msg.message of
  WM_KEYDOWN:begin
   case Msg.wParam of
    VK_UP:KeyboardInput($09);
    VK_DOWN:KeyboardInput($0A);
    VK_HOME:AttentionLevel(False);
    VK_TAB:KeyboardInput($09);
    VK_RETURN:KeyboardInput($0D);
    VK_BACK:KeyboardInput($08);
    VK_ESCAPE:KeyboardInput($1B);
   else Exit end;
   Handled:=True;
  end;
  WM_KEYUP:if Msg.wParam=VK_HOME then begin AttentionLevel(True);Handled:=True end;
  WM_CHAR:if(Msg.wParam>0)and(Msg.wParam<=255)then begin
   C:=Byte(Msg.wParam);
   if(C>=Ord('a'))and(C<=Ord('z'))then Dec(C,32);
   KeyboardInput(C);Handled:=True;
  end;
 end;
end;

procedure TFrmMain.MainShow(Sender:TObject);
begin
 EnsurePanelOnScreen(Self);
 { OnShow runs before the native main window has finished appearing.
   Defer TV creation until that operation returns to the message loop. }
 if not FStartupTVPending then Exit;
 if PostMessage(Handle,WM_SHOW_STARTUP_TV,0,0)then FStartupTVPending:=False;
end;

procedure TFrmMain.ShowStartupTV(var Msg:TMessage);
begin
 if csDestroying in ComponentState then Exit;
 if not Visible then begin FStartupTVPending:=True;Exit end;
 { Paint the now-visible main panel first; its final position is the basis
   for PlaceBesideMain when ColorTVMenuClick creates the TV window. }
 UpdateWindow(Handle);
 ColorTVMenuClick(nil);
 { Startup should finish with the panel ready for its function keys. }
 BringToFront;
 if CanFocus then SetFocus;
end;

procedure TFrmMain.MainDeactivate(Sender:TObject);
begin AttentionLevel(True) end;

procedure TFrmMain.KeyboardMenuClick(Sender:TObject);
begin
 if not Assigned(FKeyboard) then begin
  FKeyboard:=TFrmKeyboard.CreateKeyboard(Self,KeyboardInput,AttentionLevel);
  { PC keys are routed before VCL dialog navigation, once per message. }
  PlaceBesideMain(FKeyboard,True);
 end;
 if FKeyboard.Visible then FKeyboard.Hide
 else begin EnsurePanelOnScreen(FKeyboard); FKeyboard.Show; FKeyboard.BringToFront end;
end;

procedure TFrmMain.ColorTVMenuClick(Sender:TObject);
begin
 if not Assigned(FTV) then begin
  FTV:=TFrmColorTV.CreateForMemory(Self,@FMem[0],@FTVControl,FVramBase);
  PlaceBesideMain(FTV,True);
 end;
 if not FTV.Visible then begin EnsurePanelOnScreen(FTV); FTV.Show end else begin FTV.BringToFront; FTV.SetFocus end;
end;
procedure TFrmMain.PanelMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Integer);var i,sx:Integer;begin
 if (Y>=472)and(Y<=529) then for i:=7 downto 0 do begin sx:=72+(7-i)*47;if(X>=sx)and(X<=sx+31)then begin FDataSw[i]:=not FDataSw[i];UpdateFromSwitches;RefreshPanelOnce;Exit end end;
 if(X>=405)and(X<=438)and(Y>=238)and(Y<=294)then begin
  { ADDRESS SET: the front-panel entry byte is shifted into the 16-bit
    DMA address register.  Press once with the high byte on S7..S0,
    then set the low byte and press again: HH -> HHLL. }
  UpdateFromSwitches;
  FAddr:=Word(((Cardinal(FAddr)shl 8)or Cardinal(FData))and $FFFF);
  FData:=FMem[FAddr];
  FAddressPulse:=12; { about 120 ms: visible press, then spring return }
  RefreshPanelOnce;
  Exit
 end;
 if(X>=455)and(X<=488)and(Y>=238)and(Y<=294)then begin FHalt:=True;FRun:=False;RefreshPanelOnce;Exit end;
 if(X>=505)and(X<=538)and(Y>=238)and(Y<=294)then begin if ssShift in Shift then DoReset else begin FCPU.PC:=FAddr;FHalt:=False;FRun:=True;RefreshPanelOnce end;Exit end;
 if(X>=430)and(X<=463)and(Y>=365)and(Y<=421)then begin FReadPulse:=12;DMARead;Exit end;
 if(X>=486)and(X<=519)and(Y>=365)and(Y<=421)then begin FWritePulse:=12;DMAWrite;Exit end;
end;
end.
