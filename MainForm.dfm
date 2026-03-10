object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = #205#165' Skladov'#195#161' Evidence - Delphi Aplikace [PRO]'
  ClientHeight = 650
  ClientWidth = 1100
  Color = 15132390
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Size = 9
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 280
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object LabelTitle: TLabel
      Left = 16
      Top = 16
      Width = 380
      Height = 23
      Caption = #205#165' Skladov'#195#161' Evidence PRO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3556608
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Size = 11
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 16
      Top = 56
      Width = 53
      Height = 13
      Caption = 'K'#195#179'd polo'#197#190'ky:'
    end
    object Label2: TLabel
      Left = 16
      Top = 96
      Width = 68
      Height = 13
      Caption = 'N'#195#161'zev polo'#197#190'ky:'
    end
    object Label3: TLabel
      Left = 16
      Top = 136
      Width = 51
      Height = 13
      Caption = 'Kategorie:'
    end
    object Label4: TLabel
      Left = 400
      Top = 56
      Width = 52
      Height = 13
      Caption = 'Mno'#197#190'stv'#195#173':'
    end
    object Label5: TLabel
      Left = 400
      Top = 96
      Width = 61
      Height = 13
      Caption = 'Cena (K'#196#141'):'
    end
    object Label6: TLabel
      Left = 16
      Top = 210
      Width = 60
      Height = 13
      Caption = 'Vyhled'#195#161'v'#195#161'n'#195#173':'
    end
    object Label7: TLabel
      Left = 400
      Top = 136
      Width = 98
      Height = 13
      Caption = 'Min. mno'#197#190'stv'#195#173' (varování):'
    end
    object Label8: TLabel
      Left = 600
      Top = 176
      Width = 93
      Height = 13
      Caption = 'Filtr podle kategorie:'
    end
    object EditCode: TEdit
      Left = 16
      Top = 70
      Width = 350
      Height = 21
      TabOrder = 0
    end
    object EditName: TEdit
      Left = 16
      Top = 110
      Width = 350
      Height = 21
      TabOrder = 1
    end
    object ComboCategory: TComboBox
      Left = 16
      Top = 150
      Width = 350
      Height = 21
      Style = csDropDownList
      TabOrder = 2
    end
    object EditQuantity: TEdit
      Left = 400
      Top = 70
      Width = 150
      Height = 21
      TabOrder = 3
      Text = '0'
    end
    object EditPrice: TEdit
      Left = 400
      Top = 110
      Width = 150
      Height = 21
      TabOrder = 4
      Text = '0'
    end
    object EditMinQuantity: TEdit
      Left = 400
      Top = 150
      Width = 150
      Height = 21
      TabOrder = 5
      Text = '5'
    end
    object ButtonAdd: TButton
      Left = 600
      Top = 56
      Width = 120
      Height = 33
      Caption = #10#159' P'#197#153'idat'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Size = 10
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = ButtonAddClick
    end
    object ButtonUpdate: TButton
      Left = 736
      Top = 56
      Width = 120
      Height = 33
      Caption = #9998#65039' Upravit'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Size = 10
      ParentFont = False
      TabOrder = 7
      OnClick = ButtonUpdateClick
    end
    object ButtonDelete: TButton
      Left = 600
      Top = 104
      Width = 120
      Height = 33
      Caption = #197#151#65039' Smazat'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Size = 10
      ParentFont = False
      TabOrder = 8
      OnClick = ButtonDeleteClick
    end
    object ButtonClear: TButton
      Left = 736
      Top = 104
      Width = 120
      Height = 33
      Caption = #10#060' Vy'#196#141'istit'
      TabOrder = 9
      OnClick = ButtonClearClick
    end
    object ButtonExport: TButton
      Left = 880
      Top = 56
      Width = 100
      Height = 33
      Caption = #205#159' Export CSV'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 9
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
      OnClick = ButtonExportClick
    end
    object ButtonImport: TButton
      Left = 992
      Top = 56
      Width = 100
      Height = 33
      Caption = #205#158' Import CSV'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 9
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
      OnClick = ButtonImportClick
    end
    object ButtonBackup: TButton
      Left = 880
      Top = 104
      Width = 100
      Height = 33
      Caption = #205#158' Z'#195#161'loha DB'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clPurple
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 9
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 12
      OnClick = ButtonBackupClick
    end
    object ButtonStatistics: TButton
      Left = 992
      Top = 104
      Width = 100
      Height = 33
      Caption = #205#159' Statistiky'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 9
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 13
      OnClick = ButtonStatisticsClick
    end
    object ButtonAuditLog: TButton
      Left = 880
      Top = 152
      Width = 212
      Height = 33
      Caption = #205#158' Audit Log (Historie zm'#196#155'n)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8388608
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 9
      ParentFont = False
      TabOrder = 14
      OnClick = ButtonAuditLogClick
    end
    object EditSearch: TEdit
      Left = 16
      Top = 224
      Width = 534
      Height = 21
      TabOrder = 15
      OnChange = EditSearchChange
    end
    object ButtonSearch: TButton
      Left = 570
      Top = 219
      Width = 150
      Height = 30
      Caption = #205#159' Hledat'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Size = 10
      ParentFont = False
      TabOrder = 16
      OnClick = ButtonSearchClick
    end
    object ComboFilterCategory: TComboBox
      Left = 600
      Top = 190
      Width = 260
      Height = 21
      Style = csDropDownList
      TabOrder = 17
      OnChange = ComboFilterCategoryChange
    end
  end
  object PanelGrid: TPanel
    Left = 0
    Top = 280
    Width = 1100
    Height = 351
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object DBGrid1: TDBGrid
      Left = 0
      Top = 0
      Width = 1100
      Height = 351
      Align = alClient
      DataSource = DataModule1.DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Size = 9
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
      OnCellClick = DBGrid1CellClick
      OnDrawColumnCell = DBGrid1DrawColumnCell
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 631
    Width = 1100
    Height = 19
    Panels = <
      item
        Width = 200
      end
      item
        Width = 300
      end
      item
        Width = 200
      end>
  end
end
