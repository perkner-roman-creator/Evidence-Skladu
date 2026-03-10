program InventoryApp;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  SysUtils,
  MainForm in 'MainForm.pas' {FormMain},
  DatabaseModule in 'DatabaseModule.pas' {DataModule1},
  WarehouseForm in 'WarehouseForm.pas' {FormWarehouse},
  SupplierForm in 'SupplierForm.pas' {FormSupplier},
  StatisticsForm in 'StatisticsForm.pas' {FormStatistics};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Skladova Evidence';
  DataModule1 := TDataModule1.Create;
  try
    Application.CreateForm(TFormMain, FormMain);
    Application.Run;
  finally
    FreeAndNil(DataModule1);
  end;
end.
