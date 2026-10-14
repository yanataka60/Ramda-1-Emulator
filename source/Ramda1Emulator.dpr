program Ramda1Emulator;

{$R 'Ramda1Icon.res'}

uses
  Vcl.Forms,
  EmulatorSettings in 'EmulatorSettings.pas',
  ExternalROM in 'ExternalROM.pas',
  MC6821Expansion in 'MC6821Expansion.pas',
  PrinterDevice in 'PrinterDevice.pas',
  PrinterTextBuffer in 'PrinterTextBuffer.pas',
  PrinterForm in 'PrinterForm.pas' {FrmPrinter},
  PeripheralRoute in 'PeripheralRoute.pas',
  OrganSynth in 'OrganSynth.pas',
  OrganAudio in 'OrganAudio.pas',
  OrganForm in 'OrganForm.pas' {FrmOrgan},
  MainForm in 'MainForm.pas' {FrmMain},
  MC6800 in 'MC6800.pas',
  MC6821PortA in 'MC6821PortA.pas',
  MC6821PortB in 'MC6821PortB.pas',
  CassetteSignal in 'CassetteSignal.pas',
  CassetteForm in 'CassetteForm.pas',
  MC6847Sync in 'MC6847Sync.pas',
  MC6847Display in 'MC6847Display.pas',
  RAMFileForm in 'RAMFileForm.pas',
  RAMMonitorForm in 'RAMMonitorForm.pas',
  ColorTVForm in 'ColorTVForm.pas',
  KeyboardForm in 'KeyboardForm.pas',
  AppIcon in 'AppIcon.pas';


begin
  Application.Initialize;
  InstallApplicationIcon;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Ramda1 Emulator';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
