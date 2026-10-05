object FrmRAMMonitor: TFrmRAMMonitor
  Caption = #923'-1 RAM'#12514#12491#12479' - 64KB ($0000-$FFFF)'
  ClientWidth = 650
  ClientHeight = 680
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Meiryo UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  Constraints.MinHeight = 300
  OnClose = FormCloseHandler
  OnDeactivate = FormDeactivateHandler
  object FGrid: TDrawGrid
    Left = 0
    Top = 0
    Width = 650
    Height = 680
    Align = alClient
    Font.Name = 'Consolas'
    Font.Height = -13
    ParentFont = False
    Color = 16054520
    ColCount = 3
    FixedCols = 0
    FixedRows = 1
    RowCount = 4097
    DefaultDrawing = False
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]
    ScrollBars = ssVertical
    TabOrder = 0
    OnDrawCell = DrawCell
    OnTopLeftChanged = ViewScrolled
  end
  object FTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = TimerTick
    Left = 16
    Top = 16
  end
end
