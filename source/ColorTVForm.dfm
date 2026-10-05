object FrmColorTV: TFrmColorTV
  Caption = #923'-1 '#12459#12521#12540'TV'#12487#12451#12473#12503#12524#12452
  ClientWidth = 620
  ClientHeight = 500
  Color = 2106147
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Meiryo UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  DoubleBuffered = True
  OnDeactivate = FormDeactivateHandler
  object FScreen: TPaintBox
    Left = 0
    Top = 0
    Width = 620
    Height = 500
    Align = alClient
    OnPaint = PaintScreen
  end
  object FTimer: TTimer
    Enabled = False
    Interval = 33
    OnTimer = TimerTick
    Left = 16
    Top = 16
  end
end
