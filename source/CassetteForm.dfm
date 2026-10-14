object FrmCassette: TFrmCassette
  Caption = 'Ramda1 '#12459#12475#12483#12488' / WAV'
  ClientWidth = 640
  ClientHeight = 370
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Meiryo UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  Constraints.MinWidth = 656
  Constraints.MinHeight = 409
  OnClose = CloseHandler
  object LblInput: TLabel
    Left = 12
    Top = 12
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #20877#29983'WAV'#65288'CHICK-BUG'#12398'L'#12467#12510#12531#12489#12391#35501#12415#36796#12415#65289
  end
  object LblInputHelp: TLabel
    Left = 12
    Top = 112
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #12501#12449#12452#12523#36984#25246#65295#30452#25509#20837#21147'(Enter) '#8594' CHICK-BUG'#12391'L'
  end
  object LblOutput: TLabel
    Left = 12
    Top = 148
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #37682#38899'WAV'#65288'CHICK-BUG'#12398'S'#12467#12510#12531#12489#12398#20986#21147#12434#37682#38899#65289
  end
  object LblOutputHelp: TLabel
    Left = 12
    Top = 248
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #20986#21147#12501#12449#12452#12523#25351#23450' '#8594' '#37682#38899#24453#27231' '#8594' CHICK-BUG'#12391'S'
  end
  object LblClock: TLabel
    Left = 12
    Top = 282
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = 'CPU'#12539'PIA E'#12463#12525#12483#12463' 1MHz'#22266#23450#65295#12514#12540#12479#12540'ON'#12398#38291#12384#12369#36914#12415#12414#12377#12290
  end
  object FStatus: TLabel
    Left = 12
    Top = 316
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #20572#27490#20013
  end
  object FTimes: TLabel
    Left = 12
    Top = 344
    Width = 616
    Height = 24
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akTop, akRight]
    Caption = #20877#29983' 0.0 / 0.0 '#31186'    '#37682#38899' 0.0 '#31186
  end
  object FInput: TEdit
    Left = 12
    Top = 38
    Width = 500
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = InputChanged
    OnExit = InputExit
    OnKeyPress = InputKeyPress
  end
  object FOutput: TEdit
    Left = 12
    Top = 174
    Width = 500
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnChange = OutputChanged
  end
  object FOpen: TButton
    Left = 524
    Top = 35
    Width = 104
    Height = 32
    Caption = #21442#29031'...'
    TabOrder = 2
    OnClick = OpenClick
    Anchors = [akTop, akRight]
  end
  object FPlay: TButton
    Left = 12
    Top = 74
    Width = 120
    Height = 32
    Caption = #20572#27490
    TabOrder = 3
    OnClick = PlayClick
    Enabled = False
  end
  object FRewind: TButton
    Left = 144
    Top = 74
    Width = 120
    Height = 32
    Caption = #24059#12365#25147#12375
    TabOrder = 4
    OnClick = RewindClick
    Enabled = False
  end
  object FOutputBrowse: TButton
    Left = 524
    Top = 171
    Width = 104
    Height = 32
    Caption = #21442#29031'...'
    TabOrder = 5
    OnClick = BrowseOutputClick
    Anchors = [akTop, akRight]
  end
  object FRecord: TButton
    Left = 12
    Top = 210
    Width = 120
    Height = 32
    Caption = #37682#38899#24453#27231
    TabOrder = 6
    OnClick = RecordClick
    Enabled = False
  end
  object FSave: TButton
    Left = 144
    Top = 210
    Width = 164
    Height = 32
    Caption = #37682#38899#32066#20102#12539#20445#23384
    TabOrder = 7
    OnClick = SaveClick
    Enabled = False
  end
  object FPolarity: TCheckBox
    Left = 284
    Top = 78
    Width = 220
    Height = 24
    Caption = #20877#29983#26997#24615#12434#21453#36578
    TabOrder = 8
    OnClick = PolarityClick
  end
  object StatusTimer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = StatusTick
    Left = 16
    Top = 16
  end
  object InputDialog: TOpenDialog
    Filter = 'WAV (*.wav)|*.wav'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 48
    Top = 16
  end
  object OutputDialog: TSaveDialog
    Filter = 'WAV (*.wav)|*.wav'
    DefaultExt = 'wav'
    Options = [ofHideReadOnly, ofEnableSizing]
    Left = 80
    Top = 16
  end
end
