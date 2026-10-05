object FrmMain: TFrmMain
  Caption = #923'-1 Emulator v1.45 - Delphi 12'
  ClientWidth = 640
  ClientHeight = 720
  Color = 986124
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Meiryo UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  DoubleBuffered = True
  Constraints.MinWidth = 656
  Constraints.MinHeight = 759
  Menu = MainMenu
  OnActivate = MainActivate
  OnShow = MainShow
  OnDeactivate = MainDeactivate
  object Panel: TPaintBox
    Left = 0
    Top = 0
    Width = 640
    Height = 720
    Align = alClient
    OnPaint = PaintPanel
    OnMouseDown = PanelMouseDown
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
      object RAMMonitorItem: TMenuItem
        Caption = '64KB RAM'#12514#12491#12479'(&M)'
        OnClick = RAMMonitorMenuClick
      end
      object TVItem: TMenuItem
        Caption = #923'-1 '#12459#12521#12540'TV'#12487#12451#12473#12503#12524#12452'(&T)...'
        OnClick = ColorTVMenuClick
      end
      object KeyboardItem: TMenuItem
        Caption = #923'-1 '#12501#12523#12461#12540#12508#12540#12489'(&K)'
        OnClick = KeyboardMenuClick
      end
      object PrinterItem: TMenuItem
        Caption = #12503#12522#12531#12479#40#38#80#41#46#46#46
        OnClick = PrinterMenuClick
      end
      object OrganItem: TMenuItem
        Caption = #38651#23376#12458#12523#12460#12531'(&O)...'
        OnClick = OrganMenuClick
      end
      object CassetteItem: TMenuItem
        Caption = #12459#12475#12483#12488' / WAV(&C)...'
        OnClick = CassetteMenuClick
      end
    end
  end
end
