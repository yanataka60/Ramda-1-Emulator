object FrmPrinter: TFrmPrinter
  Caption = #12503#12522#12531#12479#65288#25313#24373#80#73#65#32#35#50#65289
  ClientWidth = 500
  ClientHeight = 520
  BorderStyle = bsSizeable
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  Constraints.MinWidth = 500
  Constraints.MinHeight = 400
  Position = poDesigned
  Font.Name = 'Meiryo UI'
  Font.Height = -12
  OnClose = FormCloseHandler
  object SaveText: TCheckBox
    Left = 16
    Top = 12
    Width = 468
    Anchors = [akLeft, akTop, akRight]
    Height = 24
    Caption = #21463#20449#12487#12540#12479#12434#12486#12461#12473#12488#12501#12449#12452#12523#12395#26360#12365#20986#12377
    TabOrder = 0
    OnClick = SaveTextClick
  end
  object PathEdit: TEdit
    Left = 16
    Top = 45
    Width = 372
    Anchors = [akLeft, akTop, akRight]
    Height = 24
    TabOrder = 1
    OnKeyDown = PathKeyDown
  end
  object Browse: TButton
    Left = 400
    Anchors = [akTop, akRight]
    Top = 44
    Width = 84
    Height = 27
    Caption = #21442#29031#46#46#46
    TabOrder = 2
    OnClick = BrowseClick
  end
  object Description: TLabel
    Left = 16
    Top = 82
    Width = 468
    Anchors = [akLeft, akTop, akRight]
    Height = 42
    AutoSize = False
    WordWrap = True
    Caption = #12503#12522#12531#12479#20986#21147#12434#19979#12395#34920#31034#12375#12414#12377#12290#12501#12449#12452#12523#25351#23450#24460#12289#12481#12455#12483#12463#12434#20837#12428#12427#12392#34920#31034#12392#20445#23384#12364#26377#21177#12395#12394#12426#12414#12377#12290#12481#12455#12483#12463#12434#22806#12377#12392#20445#23384#12384#12369#32066#20102#12375#12414#12377#12290
  end
  object Status: TLabel
    Left = 16
    Top = 128
    Width = 468
    Anchors = [akLeft, akTop, akRight]
    Height = 20
    AutoSize = False
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 160
    Width = 468
    Height = 344
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clWhite
    Font.Name = 'Consolas'
    Font.Height = -14
    ParentFont = False
    MaxLength = 65536
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
    TabOrder = 3
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Text (*.txt)|*.txt|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 400
    Top = 100
  end
  object RefreshTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = RefreshTimerTick
    Left = 440
    Top = 100
  end
end
