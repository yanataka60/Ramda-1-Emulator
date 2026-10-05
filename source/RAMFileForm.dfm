object FrmRAMFile: TFrmRAMFile
  Caption = 'RAM '#12496#12452#12490#12522#12501#12449#12452#12523#20837#20986#21147
  ClientWidth = 470
  ClientHeight = 265
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Yu Gothic UI'
  Font.Style = []
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  BorderStyle = bsDialog
  object LblLoad: TLabel
    Left = 24
    Top = 24
    Width = 330
    Height = 20
    AutoSize = False
    Caption = #12496#12452#12490#12522#12501#12449#12452#12523#12434'RAM'#12408'LOAD'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Yu Gothic UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LblLoadAddr: TLabel
    Left = 24
    Top = 56
    Width = 330
    Height = 20
    AutoSize = False
    Caption = 'LOAD'#38283#22987#12450#12489#12524#12473' (HEX):'
  end
  object LblSave: TLabel
    Left = 24
    Top = 103
    Width = 330
    Height = 20
    AutoSize = False
    Caption = 'RAM'#12398#20869#23481#12434#12496#12452#12490#12522#12501#12449#12452#12523#12408'SAVE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Yu Gothic UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LblSaveStart: TLabel
    Left = 24
    Top = 137
    Width = 330
    Height = 20
    AutoSize = False
    Caption = #38283#22987#12450#12489#12524#12473' (HEX):'
  end
  object LblSaveEnd: TLabel
    Left = 24
    Top = 169
    Width = 330
    Height = 20
    AutoSize = False
    Caption = #32066#20102#12450#12489#12524#12473' (HEX):'
  end
  object LblStatus: TLabel
    Left = 24
    Top = 210
    Width = 330
    Height = 20
    AutoSize = False
    Caption = '64KB RAM: $0000-$FFFF'
  end
  object EdLoadAddr: TEdit
    Left = 190
    Top = 52
    Width = 80
    Height = 25
    TabOrder = 0
    Text = '0000'
  end
  object EdSaveStart: TEdit
    Left = 190
    Top = 133
    Width = 80
    Height = 25
    TabOrder = 1
    Text = '0000'
  end
  object EdSaveEnd: TEdit
    Left = 190
    Top = 165
    Width = 80
    Height = 25
    TabOrder = 2
    Text = 'FFFF'
  end
  object BtnLoad: TButton
    Left = 292
    Top = 50
    Width = 145
    Height = 28
    Caption = #12501#12449#12452#12523#12434'LOAD...'
    TabOrder = 3
    OnClick = LoadClick
  end
  object BtnSave: TButton
    Left = 292
    Top = 148
    Width = 145
    Height = 28
    Caption = #12501#12449#12452#12523#12408'SAVE...'
    TabOrder = 4
    OnClick = SaveClick
  end
  object BtnClose: TButton
    Left = 362
    Top = 215
    Width = 75
    Height = 28
    Caption = #38281#12376#12427
    TabOrder = 5
    OnClick = CloseClick
  end
  object OpenDlg: TOpenDialog
    Title = 'RAM'#12408'LOAD'#12377#12427#12496#12452#12490#12522#12501#12449#12452#12523#12434#36984#25246
    Filter = #12496#12452#12490#12522#12501#12449#12452#12523' (*.bin)|*.bin|'#12377#12409#12390#12398#12501#12449#12452#12523' (*.*)|*.*'
    Left = 16
    Top = 16
  end
  object SaveDlg: TSaveDialog
    Title = 'RAM'#20869#23481#12398#20445#23384#20808#12434#36984#25246
    Filter = #12496#12452#12490#12522#12501#12449#12452#12523' (*.bin)|*.bin|'#12377#12409#12390#12398#12501#12449#12452#12523' (*.*)|*.*'
    DefaultExt = 'bin'
    Left = 16
    Top = 16
  end
end
