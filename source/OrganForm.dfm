object FrmOrgan: TFrmOrgan
  Caption = #38651#23376#12458#12523#12460#12531
  ClientWidth = 640
  ClientHeight = 246
  BorderStyle = bsSingle
  BorderIcons = [biSystemMenu, biMinimize]
  Position = poDesigned
  KeyPreview = True
  Font.Name = 'Meiryo UI'
  Font.Height = -12
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnDeactivate = FormDeactivateHandler
  OnClose = FormCloseHandler
  object Explanation: TLabel
    Left = 16
    Top = 12
    Width = 608
    Height = 40
    AutoSize = False
    WordWrap = True
    Caption = #25163#21205#28436#22863#65306#12461#12540#12434#25276#12377#12363#12289#12371#12398#30011#38754#12391' Z X C V B N M , '#12434#25276#12375#12390#12367#12384#12373#12356#12290#21516#26178#30330#38899#21487#12290
  end
  object Keys: TPaintBox
    Left = 16
    Top = 60
    Width = 608
    Height = 125
    OnPaint = PaintKeys
    OnMouseDown = KeysMouseDown
    OnMouseUp = KeysMouseUp
  end
  object RouteStatus: TLabel
    Left = 16
    Top = 196
    Width = 608
    Height = 17
    AutoSize = False
    Caption = ''
  end
  object Status: TLabel
    Left = 16
    Top = 221
    Width = 608
    Height = 17
    AutoSize = False
    Caption = ''
  end
  object RefreshTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = RefreshTimerTick
    Left = 568
    Top = 8
  end
end
