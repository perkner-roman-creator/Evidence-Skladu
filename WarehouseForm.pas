unit WarehouseForm;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, 
  DB, DBGrids, ExtCtrls, DatabaseModule, SQLDB;

type
  TFormWarehouse = class(TForm)
    PanelTop: TPanel;
    LabelName: TLabel;
    EditName: TEdit;
    LabelLocation: TLabel;
    EditLocation: TEdit;
    LabelDescription: TLabel;
    MemoDescription: TMemo;
    ButtonAdd: TButton;
    ButtonUpdate: TButton;
    ButtonDelete: TButton;
    ButtonClose: TButton;
    DBGridWarehouses: TDBGrid;
    DataSourceWarehouses: TDataSource;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure DBGridWarehousesCellClick(Column: TColumn);
  private
    FWarehouseQuery: TSQLQuery;
    procedure RefreshWarehouses;
    procedure ClearInputs;
  end;

var
  FormWarehouse: TFormWarehouse;

implementation

{$R *.lfm}

procedure TFormWarehouse.FormCreate(Sender: TObject);
begin
  Caption := 'Správa skladů';
  
  // Nastavení českých popisků
  LabelName.Caption := 'Název skladu:';
  LabelLocation.Caption := 'Umístění:';
  LabelDescription.Caption := 'Popis:';
  ButtonAdd.Caption := 'Přidat';
  ButtonUpdate.Caption := 'Aktualizovat';
  ButtonDelete.Caption := 'Smazat';
  ButtonClose.Caption := 'Zavřít';
  
  // Načtení dat
  RefreshWarehouses;
end;

procedure TFormWarehouse.FormDestroy(Sender: TObject);
begin
  if Assigned(FWarehouseQuery) then
    FWarehouseQuery.Free;
end;

procedure TFormWarehouse.RefreshWarehouses;
begin
  DataSourceWarehouses.DataSet := nil;
  if Assigned(FWarehouseQuery) then
    FWarehouseQuery.Free;
    
  FWarehouseQuery := DataModule1.GetWarehouses;
  DataSourceWarehouses.DataSet := FWarehouseQuery;
  
  // Nastavení českých názvů sloupců
  if Assigned(FWarehouseQuery.FindField('id')) then
    FWarehouseQuery.FieldByName('id').DisplayLabel := 'ID';
  if Assigned(FWarehouseQuery.FindField('name')) then
    FWarehouseQuery.FieldByName('name').DisplayLabel := 'Název';
  if Assigned(FWarehouseQuery.FindField('location')) then
    FWarehouseQuery.FieldByName('location').DisplayLabel := 'Umístění';
  if Assigned(FWarehouseQuery.FindField('description')) then
    FWarehouseQuery.FieldByName('description').DisplayLabel := 'Popis';
  if Assigned(FWarehouseQuery.FindField('created_at')) then
    FWarehouseQuery.FieldByName('created_at').DisplayLabel := 'Vytvořeno';
end;

procedure TFormWarehouse.ClearInputs;
begin
  EditName.Text := '';
  EditLocation.Text := '';
  MemoDescription.Lines.Clear;
end;

procedure TFormWarehouse.ButtonAddClick(Sender: TObject);
begin
  if Trim(EditName.Text) = '' then
  begin
    ShowMessage('Zadejte název skladu!');
    Exit;
  end;
  
  if DataModule1.AddWarehouse(EditName.Text, EditLocation.Text, MemoDescription.Lines.Text) then
  begin
    ShowMessage('Sklad byl úspěšně přidán.');
    RefreshWarehouses;
    ClearInputs;
  end;
end;

procedure TFormWarehouse.ButtonUpdateClick(Sender: TObject);
var
  WarehouseID: Integer;
begin
  if not Assigned(FWarehouseQuery) or FWarehouseQuery.EOF then
  begin
    ShowMessage('Vyberte sklad ke změně.');
    Exit;
  end;
  
  if Trim(EditName.Text) = '' then
  begin
    ShowMessage('Zadejte název skladu!');
    Exit;
  end;
  
  WarehouseID := FWarehouseQuery.FieldByName('id').AsInteger;
  
  if DataModule1.UpdateWarehouse(WarehouseID, EditName.Text, EditLocation.Text, 
     MemoDescription.Lines.Text) then
  begin
    ShowMessage('Sklad byl aktualizován.');
    RefreshWarehouses;
  end;
end;

procedure TFormWarehouse.ButtonDeleteClick(Sender: TObject);
var
  WarehouseID: Integer;
begin
  if not Assigned(FWarehouseQuery) or FWarehouseQuery.EOF then
  begin
    ShowMessage('Vyberte sklad ke smazání.');
    Exit;
  end;
  
  if MessageDlg('Opravdu chcete smazat tento sklad?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    WarehouseID := FWarehouseQuery.FieldByName('id').AsInteger;
    
    if DataModule1.DeleteWarehouse(WarehouseID) then
    begin
      ShowMessage('Sklad byl smazán.');
      RefreshWarehouses;
      ClearInputs;
    end;
  end;
end;

procedure TFormWarehouse.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormWarehouse.DBGridWarehousesCellClick(Column: TColumn);
begin
  if not Assigned(Column) then
    Exit;

  if Assigned(FWarehouseQuery) and not FWarehouseQuery.EOF then
  begin
    EditName.Text := FWarehouseQuery.FieldByName('name').AsString;
    EditLocation.Text := FWarehouseQuery.FieldByName('location').AsString;
    MemoDescription.Lines.Text := FWarehouseQuery.FieldByName('description').AsString;
  end;
end;

end.
