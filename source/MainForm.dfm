object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Ramda1 Emulator v1.45'
  ClientHeight = 720
  ClientWidth = 640
  Color = 986124
  Constraints.MinHeight = 759
  Constraints.MinWidth = 656
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Meiryo UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnActivate = MainActivate
  OnDeactivate = MainDeactivate
  OnShow = MainShow
  TextHeight = 15
  object Panel: TPaintBox
    Left = 0
    Top = 0
    Width = 640
    Height = 720
    Align = alClient
    OnMouseDown = PanelMouseDown
    OnPaint = PaintPanel
  end
  object Timer: TTimer
    Enabled = False
    Interval = 10
    OnTimer = Tick
    Left = 16
    Top = 16
  end
  object FAppEvents: TApplicationEvents
    OnMessage = ApplicationMessage
    Left = 48
    Top = 16
  end
  object MainMenu: TMainMenu
    Left = 80
    Top = 16
    object FileMenu: TMenuItem
      Caption = #12501#12449#12452#12523'(&F)'
      object RAMItem: TMenuItem
        Caption = 'RAM '#12496#12452#12490#12522#20837#20986#21147'(&R)...'
        OnClick = RAMFileMenuClick
      end
      object CassetteItem: TMenuItem
        Caption = #12459#12475#12483#12488' / WAV(&C)...'
        OnClick = CassetteMenuClick
      end
    end
    object RunMenu: TMenuItem
      Caption = #23455#34892'(&E)'
      object ResetItem: TMenuItem
        Caption = #12522#12475#12483#12488'(&R)'
        OnClick = ResetMenuClick
      end
    end
    object ViewMenu: TMenuItem
      Caption = #34920#31034'(&V)'
      object PanelAutoStopItem: TMenuItem
        Caption = #20877#25551#30011#33258#21205#20572#27490'(&A)'
        Checked = True
        OnClick = PanelAutoStopMenuClick
      end
      object PanelRedrawItem: TMenuItem
        Caption = #21069#38754#12497#12493#12523#20877#25551#30011'(&P)'
        Checked = True
        OnClick = PanelRedrawMenuClick
      end
      object RAMMonitorItem: TMenuItem
        Caption = '64KB RAM'#12514#12491#12479'(&M)'
        OnClick = RAMMonitorMenuClick
      end
      object TVItem: TMenuItem
        Caption = 'Ramda1 '#12459#12521#12540'TV'#12487#12451#12473#12503#12524#12452'(&T)...'
        OnClick = ColorTVMenuClick
      end
      object KeyboardItem: TMenuItem
        Caption = 'Ramda1 '#12501#12523#12461#12540#12508#12540#12489'(&K)'
        OnClick = KeyboardMenuClick
      end
      object PrinterItem: TMenuItem
        Caption = #12503#12522#12531#12479'(&P)...'
        OnClick = PrinterMenuClick
      end
      object OrganItem: TMenuItem
        Caption = #38651#23376#12458#12523#12460#12531'(&O)...'
        OnClick = OrganMenuClick
      end
    end
  end
end
