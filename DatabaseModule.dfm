object DataModule1: TDataModule1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 300
  Width = 400
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=inventory.db'
      'DriverID=SQLite')
    Connected = True
    LoginPrompt = False
    Left = 48
    Top = 24
  end
  object FDTable1: TFDTable
    Active = True
    IndexFieldNames = 'id'
    Connection = FDConnection1
    TableName = 'items'
    Left = 48
    Top = 96
  end
  object DataSource1: TDataSource
    DataSet = FDTable1
    Left = 48
    Top = 168
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    Left = 152
    Top = 24
  end
end
