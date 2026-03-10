unit DatabaseModule;

interface

uses
  SysUtils, Classes, DB, SQLDB, SQLite3Conn, FileUtil, Dialogs, Printers, Graphics, Forms, Controls;

type
  TDataModule1 = class(TObject)
  private
    FCurrentSearch: string;
    FCurrentCategory: string;
    FCurrentWarehouse: Integer;
    FCurrentSupplier: Integer;
    procedure InitializeDatabase;
    procedure CreateTables;
    procedure InsertSampleData;
    procedure ApplyFilters;
    procedure PrepareQuery(AQuery: TSQLQuery; const ASQL: string);
    function ColumnExists(const ATableName, AColumnName: string): Boolean;
  public
    SQLiteConnection1: TSQLite3Connection;
    SQLTransaction1: TSQLTransaction;
    FDTable1: TSQLQuery;
    DataSource1: TDataSource;
    FDQuery1: TSQLQuery;

    constructor Create;
    procedure DataModuleCreate(Sender: TObject);
    procedure RefreshData;
    function AddItem(const ACode, AName, ACategory: string;
      AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5;
      AWarehouseID: Integer = 0; ASupplierID: Integer = 0; const AImagePath: string = ''): Boolean;
    function UpdateItem(AID: Integer; const ACode, AName, ACategory: string;
      AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5;
      AWarehouseID: Integer = 0; ASupplierID: Integer = 0; const AImagePath: string = ''): Boolean;
    function DeleteItem(AID: Integer): Boolean;
    procedure SearchItems(const ASearchText: string);
    procedure FilterByCategory(const ACategory: string);
    procedure FilterByWarehouse(AWarehouseID: Integer);
    procedure FilterBySupplier(ASupplierID: Integer);
    procedure FilterByPriceRange(AMinPrice, AMaxPrice: Double);
    function GetTotalValue: Double;
    function GetTotalItems: Integer;
    function GetLowStockItems: Integer;
    function GetAveragePrice: Double;
    function GetMostExpensiveItem: string;
    function ExportToCSV(const AFileName: string): Boolean;
    function ImportFromCSV(const AFileName: string): Boolean;
    function BackupDatabase(const ABackupPath: string): Boolean;
    function CodeExists(const ACode: string; ExcludeID: Integer = -1): Boolean;
    procedure LogAction(AItemID: Integer; const AAction, AFieldName, AOldValue, ANewValue: string);
    function GetAuditLog(AItemID: Integer = -1): TSQLQuery;
    
    // Správa skladů
    function AddWarehouse(const AName, ALocation, ADescription: string): Boolean;
    function UpdateWarehouse(AID: Integer; const AName, ALocation, ADescription: string): Boolean;
    function DeleteWarehouse(AID: Integer): Boolean;
    function GetWarehouses: TSQLQuery;
    
    // Správa dodavatelů
    function AddSupplier(const AName, AContact, APhone, AEmail, AAddress: string): Boolean;
    function UpdateSupplier(AID: Integer; const AName, AContact, APhone, AEmail, AAddress: string): Boolean;
    function DeleteSupplier(AID: Integer): Boolean;
    function GetSuppliers: TSQLQuery;
    
    // Historie cen
    procedure RecordPriceChange(AItemID: Integer; AOldPrice, ANewPrice: Double);
    function GetPriceHistory(AItemID: Integer): TSQLQuery;
    
    // Automatické objednávky
    function CreateOrder(AItemID, AQuantity, ASupplierID: Integer; const ANotes: string): Boolean;
    function UpdateOrderStatus(AOrderID: Integer; const AStatus: string): Boolean;
    function GetPendingOrders: TSQLQuery;
    function CheckAndCreateAutoOrders: Integer; // Vrací počet vytvořených objednávek
    
    // Export do Excel
    function ExportToExcel(const AFileName: string): Boolean;
    
    // Tisk
    function PrintInventory: Boolean;
  end;

var
  DataModule1: TDataModule1;

implementation

constructor TDataModule1.Create;
begin
  inherited Create;
  DataModuleCreate(Self);
end;

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  SQLiteConnection1 := TSQLite3Connection.Create(nil);
  SQLTransaction1 := TSQLTransaction.Create(nil);
  FDTable1 := TSQLQuery.Create(nil);
  FDQuery1 := TSQLQuery.Create(nil);
  DataSource1 := TDataSource.Create(nil);

  SQLiteConnection1.Transaction := SQLTransaction1;
  SQLTransaction1.DataBase := SQLiteConnection1;

  FDTable1.DataBase := SQLiteConnection1;
  FDTable1.Transaction := SQLTransaction1;

  FDQuery1.DataBase := SQLiteConnection1;
  FDQuery1.Transaction := SQLTransaction1;

  DataSource1.DataSet := FDTable1;

  InitializeDatabase;
end;

procedure TDataModule1.PrepareQuery(AQuery: TSQLQuery; const ASQL: string);
begin
  AQuery.Close;
  AQuery.SQL.Text := ASQL;
end;

function TDataModule1.ColumnExists(const ATableName, AColumnName: string): Boolean;
var
  Q: TSQLQuery;
begin
  Result := False;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConnection1;
    Q.Transaction := SQLTransaction1;
    Q.SQL.Text := 'PRAGMA table_info(' + ATableName + ')';
    Q.Open;
    while not Q.EOF do
    begin
      if SameText(Q.FieldByName('name').AsString, AColumnName) then
      begin
        Result := True;
        Break;
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

procedure TDataModule1.InitializeDatabase;
var
  DBPath: string;
begin
  DBPath := ExtractFilePath(ParamStr(0)) + 'inventory.db';
  SQLiteConnection1.DatabaseName := DBPath;

  try
    SQLiteConnection1.Open;
    CreateTables;

    PrepareQuery(FDQuery1, 'SELECT COUNT(*) AS cnt FROM items');
    FDQuery1.Open;
    if FDQuery1.FieldByName('cnt').AsInteger = 0 then
      InsertSampleData;
    FDQuery1.Close;

    FCurrentSearch := '';
    FCurrentCategory := '';
    FCurrentWarehouse := -1;
    FCurrentSupplier := -1;
    RefreshData;
  except
    on E: Exception do
    begin
      ShowMessage('Chyba databáze: ' + E.Message + #13#10 + 'Cesta: ' + DBPath);
      raise;
    end;
  end;
end;

procedure TDataModule1.CreateTables;
begin
  // Tabulka skladů
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS warehouses (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name VARCHAR(100) NOT NULL,' +
    '  location VARCHAR(200),' +
    '  description TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );
  
  // Tabulka dodavatelů
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS suppliers (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name VARCHAR(200) NOT NULL,' +
    '  contact_person VARCHAR(100),' +
    '  phone VARCHAR(20),' +
    '  email VARCHAR(100),' +
    '  address TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );

  // Tabulka položek (rozšířená)
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS items (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  code VARCHAR(50) UNIQUE NOT NULL,' +
    '  name VARCHAR(200) NOT NULL,' +
    '  category VARCHAR(50) NOT NULL,' +
    '  quantity INTEGER DEFAULT 0,' +
    '  price DECIMAL(10,2) DEFAULT 0,' +
    '  min_quantity INTEGER DEFAULT 5,' +
    '  warehouse_id INTEGER,' +
    '  supplier_id INTEGER,' +
    '  image_path TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),' +
    '  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)' +
    ')'
  );

  // Tabulka historie cen
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS price_history (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  item_id INTEGER NOT NULL,' +
    '  old_price DECIMAL(10,2),' +
    '  new_price DECIMAL(10,2),' +
    '  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  FOREIGN KEY (item_id) REFERENCES items(id)' +
    ')'
  );

  // Tabulka objednávek
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS orders (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  item_id INTEGER NOT NULL,' +
    '  quantity INTEGER NOT NULL,' +
    '  supplier_id INTEGER,' +
    '  status VARCHAR(50) DEFAULT ''Pending'',' +
    '  notes TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  completed_at DATETIME,' +
    '  FOREIGN KEY (item_id) REFERENCES items(id),' +
    '  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)' +
    ')'
  );

  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS audit_log (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  item_id INTEGER,' +
    '  action VARCHAR(50) NOT NULL,' +
    '  field_name VARCHAR(100),' +
    '  old_value TEXT,' +
    '  new_value TEXT,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  FOREIGN KEY (item_id) REFERENCES items(id)' +
    ')'
  );

  // Tabulka uživatelů pro autentifikaci
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS users (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  username VARCHAR(50) UNIQUE NOT NULL,' +
    '  password_hash VARCHAR(64) NOT NULL,' +
    '  role VARCHAR(20) DEFAULT ''User'',' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ')'
  );

  // Tabulka historie prodejů
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS sales_history (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  item_id INTEGER NOT NULL,' +
    '  quantity_sold INTEGER NOT NULL,' +
    '  price_at_sale DECIMAL(10,2) NOT NULL,' +
    '  total_amount DECIMAL(10,2) NOT NULL,' +
    '  sold_by VARCHAR(100),' +
    '  notes TEXT,' +
    '  sold_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  FOREIGN KEY (item_id) REFERENCES items(id)' +
    ')'
  );

  // Bezpečné migrace: nepouštět ALTER TABLE, pokud sloupec už existuje.
  if not ColumnExists('items', 'warehouse_id') then
    SQLiteConnection1.ExecuteDirect('ALTER TABLE items ADD COLUMN warehouse_id INTEGER');

  if not ColumnExists('items', 'supplier_id') then
    SQLiteConnection1.ExecuteDirect('ALTER TABLE items ADD COLUMN supplier_id INTEGER');

  if not ColumnExists('items', 'image_path') then
    SQLiteConnection1.ExecuteDirect('ALTER TABLE items ADD COLUMN image_path TEXT');

  SQLTransaction1.Commit;
end;

procedure TDataModule1.InsertSampleData;
begin
  // Vložení základních skladů
  SQLiteConnection1.ExecuteDirect(
    'INSERT INTO warehouses (name, location, description) VALUES ' +
    '(''Hlavní sklad'', ''Praha - Střešovice'', ''Centrální skladovací prostor''),' +
    '(''Sklad B'', ''Brno - Černovice'', ''Regionální sklad pro Moravu''),' +
    '(''Sklad C'', ''Ostrava - Vítkovice'', ''Malý distribuční sklad'')'
  );
  
  // Vložení základních dodavatelů
  SQLiteConnection1.ExecuteDirect(
    'INSERT INTO suppliers (name, contact_person, phone, email, address) VALUES ' +
    '(''TechSupply s.r.o.'', ''Jan Novák'', ''+420 777 123 456'', ''info@techsupply.cz'', ''Průmyslová 123, Praha 9''),' +
    '(''Office Pro'', ''Marie Svobodová'', ''+420 777 234 567'', ''obchod@officepro.cz'', ''Na Pankráci 45, Praha 4''),' +
    '(''EuroTools'', ''Petr Dvořák'', ''+420 777 345 678'', ''sales@eurotools.eu'', ''Brněnská 89, Brno'')'
  );
  
  SQLiteConnection1.ExecuteDirect(
    'INSERT INTO items (code, name, category, quantity, price, min_quantity, warehouse_id, supplier_id) VALUES ' +
    '(''ELEC001'', ''Notebook Dell XPS 13'', ''Elektronika'', 5, 28990.00, 3, 1, 1),' +
    '(''ELEC002'', ''Myš Logitech MX Master'', ''Elektronika'', 12, 2490.00, 5, 1, 1),' +
    '(''ELEC003'', ''Monitor LG 27"'', ''Elektronika'', 2, 7990.00, 3, 1, 1),' +
    '(''FURN001'', ''Kancelářská židle ErgoMax'', ''Nábytek'', 8, 4590.00, 4, 2, 2),' +
    '(''FURN002'', ''Psací stůl 160x80 cm'', ''Nábytek'', 3, 5990.00, 2, 2, 2),' +
    '(''TOOL001'', ''Šroubovák sada 12 ks'', ''Nářadí'', 20, 450.00, 10, 3, 3),' +
    '(''FOOD001'', ''Káva arabika 500g'', ''Potraviny'', 4, 199.00, 10, 1, 2),' +
    '(''OFFI001'', ''Papír A4 500 listů'', ''Kancelářské potřeby'', 15, 89.00, 20, 1, 2)'
  );
  SQLTransaction1.Commit;
  LogAction(0, 'INIT', '', '', 'Databáze inicializována s ukázkovými daty');
end;

procedure TDataModule1.ApplyFilters;
var
  SQLText: string;
begin
  SQLText := 'SELECT id, code, name, category, quantity, price, min_quantity, created_at FROM items WHERE 1=1';

  if FCurrentSearch <> '' then
    SQLText := SQLText +
      ' AND (name LIKE ''%' + StringReplace(FCurrentSearch, '''', '''''', [rfReplaceAll]) +
      '%'' OR code LIKE ''%' + StringReplace(FCurrentSearch, '''', '''''', [rfReplaceAll]) + '%'')';

  if FCurrentCategory <> '' then
    SQLText := SQLText +
      ' AND category = ''' + StringReplace(FCurrentCategory, '''', '''''', [rfReplaceAll]) + '''';

  if FCurrentWarehouse <> -1 then
    SQLText := SQLText +
      ' AND warehouse_id = ' + IntToStr(FCurrentWarehouse);

  if FCurrentSupplier <> -1 then
    SQLText := SQLText +
      ' AND supplier_id = ' + IntToStr(FCurrentSupplier);

  SQLText := SQLText + ' ORDER BY id DESC';

  PrepareQuery(FDTable1, SQLText);
  FDTable1.Open;
end;

procedure TDataModule1.RefreshData;
begin
  ApplyFilters;
end;

function TDataModule1.CodeExists(const ACode: string; ExcludeID: Integer = -1): Boolean;
begin
  Result := False;
  try
    if ExcludeID = -1 then
    begin
      PrepareQuery(FDQuery1, 'SELECT COUNT(*) AS cnt FROM items WHERE code = :code');
      FDQuery1.ParamByName('code').AsString := ACode;
    end
    else
    begin
      PrepareQuery(FDQuery1, 'SELECT COUNT(*) AS cnt FROM items WHERE code = :code AND id <> :id');
      FDQuery1.ParamByName('code').AsString := ACode;
      FDQuery1.ParamByName('id').AsInteger := ExcludeID;
    end;

    FDQuery1.Open;
    Result := FDQuery1.FieldByName('cnt').AsInteger > 0;
    FDQuery1.Close;
  except
    Result := False;
  end;
end;

procedure TDataModule1.LogAction(AItemID: Integer; const AAction, AFieldName, AOldValue, ANewValue: string);
begin
  try
    PrepareQuery(FDQuery1,
      'INSERT INTO audit_log (item_id, action, field_name, old_value, new_value) ' +
      'VALUES (:item_id, :action, :field_name, :old_value, :new_value)');
    FDQuery1.ParamByName('item_id').AsInteger := AItemID;
    FDQuery1.ParamByName('action').AsString := AAction;
    FDQuery1.ParamByName('field_name').AsString := AFieldName;
    FDQuery1.ParamByName('old_value').AsString := AOldValue;
    FDQuery1.ParamByName('new_value').AsString := ANewValue;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
  except
    // keep app running even if audit fails
  end;
end;

function TDataModule1.AddItem(const ACode, AName, ACategory: string;
  AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5;
  AWarehouseID: Integer = 0; ASupplierID: Integer = 0; const AImagePath: string = ''): Boolean;
var
  NewID: Integer;
  SQL: string;
begin
  Result := False;

  if CodeExists(ACode, -1) then
    raise Exception.Create('Položka s kódem "' + ACode + '" již existuje!');

  try
    SQL := 'INSERT INTO items (code, name, category, quantity, price, min_quantity';
    if AWarehouseID > 0 then SQL := SQL + ', warehouse_id';
    if ASupplierID > 0 then SQL := SQL + ', supplier_id';
    if AImagePath <> '' then SQL := SQL + ', image_path';
    SQL := SQL + ') VALUES (:code, :name, :category, :quantity, :price, :min_quantity';
    if AWarehouseID > 0 then SQL := SQL + ', :warehouse_id';
    if ASupplierID > 0 then SQL := SQL + ', :supplier_id';
    if AImagePath <> '' then SQL := SQL + ', :image_path';
    SQL := SQL + ')';
    
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('code').AsString := ACode;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('category').AsString := ACategory;
    FDQuery1.ParamByName('quantity').AsInteger := AQuantity;
    FDQuery1.ParamByName('price').AsFloat := APrice;
    FDQuery1.ParamByName('min_quantity').AsInteger := AMinQuantity;
    if AWarehouseID > 0 then FDQuery1.ParamByName('warehouse_id').AsInteger := AWarehouseID;
    if ASupplierID > 0 then FDQuery1.ParamByName('supplier_id').AsInteger := ASupplierID;
    if AImagePath <> '' then FDQuery1.ParamByName('image_path').AsString := AImagePath;
    
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;

    PrepareQuery(FDQuery1, 'SELECT last_insert_rowid() AS id');
    FDQuery1.Open;
    NewID := FDQuery1.FieldByName('id').AsInteger;
    FDQuery1.Close;

    LogAction(NewID, 'CREATE', '', '', Format('%s - %s', [ACode, AName]));
    RefreshData;
    Result := True;
  except
    on E: Exception do
      raise Exception.Create('Chyba při přidávání položky: ' + E.Message);
  end;
end;

function TDataModule1.UpdateItem(AID: Integer; const ACode, AName, ACategory: string;
  AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5;
  AWarehouseID: Integer = 0; ASupplierID: Integer = 0; const AImagePath: string = ''): Boolean;
var
  OldCode, OldName, OldCategory: string;
  OldQuantity, OldMinQuantity: Integer;
  OldPrice: Double;
  SQL: string;
begin
  Result := False;

  if CodeExists(ACode, AID) then
    raise Exception.Create('Položka s kódem "' + ACode + '" již existuje!');

  try
    PrepareQuery(FDQuery1, 'SELECT * FROM items WHERE id = :id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.Open;

    if FDQuery1.EOF then
      raise Exception.Create('Položka nebyla nalezena.');

    OldCode := FDQuery1.FieldByName('code').AsString;
    OldName := FDQuery1.FieldByName('name').AsString;
    OldCategory := FDQuery1.FieldByName('category').AsString;
    OldQuantity := FDQuery1.FieldByName('quantity').AsInteger;
    OldPrice := FDQuery1.FieldByName('price').AsFloat;
    OldMinQuantity := FDQuery1.FieldByName('min_quantity').AsInteger;
    FDQuery1.Close;

    SQL := 'UPDATE items SET code=:code, name=:name, category=:category, quantity=:quantity, ' +
           'price=:price, min_quantity=:min_quantity';
    if AWarehouseID > 0 then SQL := SQL + ', warehouse_id=:warehouse_id';
    if ASupplierID > 0 then SQL := SQL + ', supplier_id=:supplier_id';
    if AImagePath <> '' then SQL := SQL + ', image_path=:image_path';
    SQL := SQL + ', updated_at=CURRENT_TIMESTAMP WHERE id=:id';
    
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ParamByName('code').AsString := ACode;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('category').AsString := ACategory;
    FDQuery1.ParamByName('quantity').AsInteger := AQuantity;
    FDQuery1.ParamByName('price').AsFloat := APrice;
    FDQuery1.ParamByName('min_quantity').AsInteger := AMinQuantity;
    if AWarehouseID > 0 then FDQuery1.ParamByName('warehouse_id').AsInteger := AWarehouseID;
    if ASupplierID > 0 then FDQuery1.ParamByName('supplier_id').AsInteger := ASupplierID;
    if AImagePath <> '' then FDQuery1.ParamByName('image_path').AsString := AImagePath;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;

    if OldCode <> ACode then LogAction(AID, 'UPDATE', 'code', OldCode, ACode);
    if OldName <> AName then LogAction(AID, 'UPDATE', 'name', OldName, AName);
    if OldCategory <> ACategory then LogAction(AID, 'UPDATE', 'category', OldCategory, ACategory);
    if OldQuantity <> AQuantity then LogAction(AID, 'UPDATE', 'quantity', IntToStr(OldQuantity), IntToStr(AQuantity));
    if Abs(OldPrice - APrice) > 0.0001 then 
    begin
      LogAction(AID, 'UPDATE', 'price', FormatFloat('0.00', OldPrice), FormatFloat('0.00', APrice));
      RecordPriceChange(AID, OldPrice, APrice); // Zaznamenat změnu ceny
    end;
    if OldMinQuantity <> AMinQuantity then LogAction(AID, 'UPDATE', 'min_quantity', IntToStr(OldMinQuantity), IntToStr(AMinQuantity));

    RefreshData;
    Result := True;
  except
    on E: Exception do
      raise Exception.Create('Chyba při aktualizaci položky: ' + E.Message);
  end;
end;

function TDataModule1.DeleteItem(AID: Integer): Boolean;
var
  ItemName: string;
begin
  Result := False;
  try
    PrepareQuery(FDQuery1, 'SELECT name FROM items WHERE id=:id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.Open;
    ItemName := FDQuery1.FieldByName('name').AsString;
    FDQuery1.Close;

    PrepareQuery(FDQuery1, 'DELETE FROM items WHERE id=:id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;

    LogAction(AID, 'DELETE', '', ItemName, '');
    RefreshData;
    Result := True;
  except
    on E: Exception do
      raise Exception.Create('Chyba při mazání položky: ' + E.Message);
  end;
end;

procedure TDataModule1.SearchItems(const ASearchText: string);
begin
  FCurrentSearch := Trim(ASearchText);
  RefreshData;
end;

procedure TDataModule1.FilterByCategory(const ACategory: string);
begin
  FCurrentCategory := Trim(ACategory);
  RefreshData;
end;

procedure TDataModule1.FilterByWarehouse(AWarehouseID: Integer);
begin
  FCurrentWarehouse := AWarehouseID;
  RefreshData;
end;

procedure TDataModule1.FilterBySupplier(ASupplierID: Integer);
begin
  FCurrentSupplier := ASupplierID;
  RefreshData;
end;

procedure TDataModule1.FilterByPriceRange(AMinPrice, AMaxPrice: Double);
begin
  // Volitelná funkce navíc - zatím není používána ve formu.
  if (AMinPrice = 0) and (AMaxPrice = 0) then
    Exit;
end;

function TDataModule1.GetTotalValue: Double;
begin
  Result := 0;
  try
    PrepareQuery(FDQuery1, 'SELECT COALESCE(SUM(quantity * price), 0) AS total FROM items');
    FDQuery1.Open;
    Result := FDQuery1.FieldByName('total').AsFloat;
    FDQuery1.Close;
  except
    Result := 0;
  end;
end;

function TDataModule1.GetTotalItems: Integer;
begin
  Result := 0;
  try
    PrepareQuery(FDQuery1, 'SELECT COUNT(*) AS cnt FROM items');
    FDQuery1.Open;
    Result := FDQuery1.FieldByName('cnt').AsInteger;
    FDQuery1.Close;
  except
    Result := 0;
  end;
end;

function TDataModule1.GetLowStockItems: Integer;
begin
  Result := 0;
  try
    PrepareQuery(FDQuery1, 'SELECT COUNT(*) AS cnt FROM items WHERE quantity <= min_quantity');
    FDQuery1.Open;
    Result := FDQuery1.FieldByName('cnt').AsInteger;
    FDQuery1.Close;
  except
    Result := 0;
  end;
end;

function TDataModule1.GetAveragePrice: Double;
begin
  Result := 0;
  try
    PrepareQuery(FDQuery1, 'SELECT COALESCE(AVG(price), 0) AS avg_price FROM items');
    FDQuery1.Open;
    Result := FDQuery1.FieldByName('avg_price').AsFloat;
    FDQuery1.Close;
  except
    Result := 0;
  end;
end;

function TDataModule1.GetMostExpensiveItem: string;
begin
  Result := '';
  try
    PrepareQuery(FDQuery1, 'SELECT name, price FROM items ORDER BY price DESC LIMIT 1');
    FDQuery1.Open;
    if not FDQuery1.EOF then
      Result := Format('%s (%.2f Kč)', [FDQuery1.FieldByName('name').AsString, FDQuery1.FieldByName('price').AsFloat]);
    FDQuery1.Close;
  except
    Result := '';
  end;
end;

function TDataModule1.ExportToCSV(const AFileName: string): Boolean;
var
  F: TextFile;
begin
  Result := False;
  AssignFile(F, AFileName);
  try
    Rewrite(F);
    Writeln(F, 'ID,Kód,Název,Kategorie,Množství,Cena,MinMnozstvi,Vytvoreno');
    FDTable1.First;
    while not FDTable1.EOF do
    begin
      Writeln(F,
        IntToStr(FDTable1.FieldByName('id').AsInteger) + ',' +
        '"' + StringReplace(FDTable1.FieldByName('code').AsString, '"', '""', [rfReplaceAll]) + '",' +
        '"' + StringReplace(FDTable1.FieldByName('name').AsString, '"', '""', [rfReplaceAll]) + '",' +
        '"' + StringReplace(FDTable1.FieldByName('category').AsString, '"', '""', [rfReplaceAll]) + '",' +
        IntToStr(FDTable1.FieldByName('quantity').AsInteger) + ',' +
        StringReplace(FormatFloat('0.00', FDTable1.FieldByName('price').AsFloat), ',', '.', [rfReplaceAll]) + ',' +
        IntToStr(FDTable1.FieldByName('min_quantity').AsInteger) + ',' +
        '"' + FDTable1.FieldByName('created_at').AsString + '"'
      );
      FDTable1.Next;
    end;
    Result := True;
  finally
    CloseFile(F);
  end;
end;

function TDataModule1.ImportFromCSV(const AFileName: string): Boolean;
var
  SL: TStringList;
  I, ImportCount: Integer;
  Parts: TStringArray;
  ACode, AName, ACategory: string;
  AQty, AMinQty: Integer;
  APrice: Double;
begin
  Result := False;
  ImportCount := 0;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    for I := 1 to SL.Count - 1 do
    begin
      Parts := SL[I].Split(',');
      if Length(Parts) < 7 then
        Continue;

      ACode := Trim(Parts[1]);
      AName := Trim(Parts[2]);
      ACategory := Trim(Parts[3]);
      AQty := StrToIntDef(Trim(Parts[4]), 0);
      APrice := StrToFloatDef(StringReplace(Trim(Parts[5]), '.', FormatSettings.DecimalSeparator, [rfReplaceAll]), 0);
      AMinQty := StrToIntDef(Trim(Parts[6]), 5);

      ACode := StringReplace(ACode, '"', '', [rfReplaceAll]);
      AName := StringReplace(AName, '"', '', [rfReplaceAll]);
      ACategory := StringReplace(ACategory, '"', '', [rfReplaceAll]);

      try
        if not CodeExists(ACode, -1) then
        begin
          AddItem(ACode, AName, ACategory, AQty, APrice, AMinQty);
          Inc(ImportCount);
        end;
      except
        // skip invalid rows
      end;
    end;
    Result := ImportCount > 0;
  finally
    SL.Free;
  end;
end;

function TDataModule1.BackupDatabase(const ABackupPath: string): Boolean;
var
  SourcePath: string;
begin
  SourcePath := ExtractFilePath(ParamStr(0)) + 'inventory.db';
  Result := False;

  FDTable1.Close;
  FDQuery1.Close;
  if SQLiteConnection1.Connected then
    SQLiteConnection1.Close;

  try
    if FileExists(SourcePath) then
    begin
      CopyFile(SourcePath, ABackupPath, [cffOverwriteFile]);
      Result := True;
    end;
  finally
    SQLiteConnection1.Open;
    RefreshData;
  end;
end;

function TDataModule1.GetAuditLog(AItemID: Integer = -1): TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := SQLiteConnection1;
  Result.Transaction := SQLTransaction1;

  if AItemID = -1 then
    Result.SQL.Text := 'SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 100'
  else
  begin
    Result.SQL.Text := 'SELECT * FROM audit_log WHERE item_id = :item_id ORDER BY created_at DESC';
    Result.ParamByName('item_id').AsInteger := AItemID;
  end;

  Result.Open;
end;

// === SPRÁVA SKLADŮ ===

function TDataModule1.AddWarehouse(const AName, ALocation, ADescription: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    SQL := 'INSERT INTO warehouses (name, location, description) VALUES (:name, :location, :description)';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('location').AsString := ALocation;
    FDQuery1.ParamByName('description').AsString := ADescription;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'ADD_WAREHOUSE', 'name', '', AName);
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při přidávání skladu: ' + E.Message);
    end;
  end;
end;

function TDataModule1.UpdateWarehouse(AID: Integer; const AName, ALocation, ADescription: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    SQL := 'UPDATE warehouses SET name = :name, location = :location, description = :description WHERE id = :id';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('location').AsString := ALocation;
    FDQuery1.ParamByName('description').AsString := ADescription;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'UPDATE_WAREHOUSE', 'id', IntToStr(AID), AName);
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při aktualizaci skladu: ' + E.Message);
    end;
  end;
end;

function TDataModule1.DeleteWarehouse(AID: Integer): Boolean;
begin
  Result := False;
  try
    PrepareQuery(FDQuery1, 'DELETE FROM warehouses WHERE id = :id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'DELETE_WAREHOUSE', 'id', IntToStr(AID), '');
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při mazání skladu: ' + E.Message);
    end;
  end;
end;

function TDataModule1.GetWarehouses: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := SQLiteConnection1;
  Result.Transaction := SQLTransaction1;
  Result.SQL.Text := 'SELECT * FROM warehouses ORDER BY name';
  Result.Open;
end;

// === SPRÁVA DODAVATELŮ ===

function TDataModule1.AddSupplier(const AName, AContact, APhone, AEmail, AAddress: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    SQL := 'INSERT INTO suppliers (name, contact_person, phone, email, address) ' +
           'VALUES (:name, :contact, :phone, :email, :address)';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('contact').AsString := AContact;
    FDQuery1.ParamByName('phone').AsString := APhone;
    FDQuery1.ParamByName('email').AsString := AEmail;
    FDQuery1.ParamByName('address').AsString := AAddress;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'ADD_SUPPLIER', 'name', '', AName);
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při přidávání dodavatele: ' + E.Message);
    end;
  end;
end;

function TDataModule1.UpdateSupplier(AID: Integer; const AName, AContact, APhone, AEmail, AAddress: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    SQL := 'UPDATE suppliers SET name = :name, contact_person = :contact, ' +
           'phone = :phone, email = :email, address = :address WHERE id = :id';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('contact').AsString := AContact;
    FDQuery1.ParamByName('phone').AsString := APhone;
    FDQuery1.ParamByName('email').AsString := AEmail;
    FDQuery1.ParamByName('address').AsString := AAddress;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'UPDATE_SUPPLIER', 'id', IntToStr(AID), AName);
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při aktualizaci dodavatele: ' + E.Message);
    end;
  end;
end;

function TDataModule1.DeleteSupplier(AID: Integer): Boolean;
begin
  Result := False;
  try
    PrepareQuery(FDQuery1, 'DELETE FROM suppliers WHERE id = :id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'DELETE_SUPPLIER', 'id', IntToStr(AID), '');
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při mazání dodavatele: ' + E.Message);
    end;
  end;
end;

function TDataModule1.GetSuppliers: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := SQLiteConnection1;
  Result.Transaction := SQLTransaction1;
  Result.SQL.Text := 'SELECT * FROM suppliers ORDER BY name';
  Result.Open;
end;

// === HISTORIE CEN ===

procedure TDataModule1.RecordPriceChange(AItemID: Integer; AOldPrice, ANewPrice: Double);
var
  SQL: string;
begin
  try
    SQL := 'INSERT INTO price_history (item_id, old_price, new_price) VALUES (:item_id, :old_price, :new_price)';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('item_id').AsInteger := AItemID;
    FDQuery1.ParamByName('old_price').AsFloat := AOldPrice;
    FDQuery1.ParamByName('new_price').AsFloat := ANewPrice;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
  except
    on E: Exception do
      SQLTransaction1.Rollback;
  end;
end;

function TDataModule1.GetPriceHistory(AItemID: Integer): TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := SQLiteConnection1;
  Result.Transaction := SQLTransaction1;
  Result.SQL.Text := 'SELECT ph.*, i.name, i.code FROM price_history ph ' +
                     'JOIN items i ON ph.item_id = i.id ' +
                     'WHERE ph.item_id = :item_id ORDER BY ph.changed_at DESC';
  Result.ParamByName('item_id').AsInteger := AItemID;
  Result.Open;
end;

// === AUTOMATICKÉ OBJEDNÁVKY ===

function TDataModule1.CreateOrder(AItemID, AQuantity, ASupplierID: Integer; const ANotes: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    SQL := 'INSERT INTO orders (item_id, quantity, supplier_id, notes, status) ' +
           'VALUES (:item_id, :quantity, :supplier_id, :notes, ''Čeká'')';
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('item_id').AsInteger := AItemID;
    FDQuery1.ParamByName('quantity').AsInteger := AQuantity;
    FDQuery1.ParamByName('supplier_id').AsInteger := ASupplierID;
    FDQuery1.ParamByName('notes').AsString := ANotes;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(AItemID, 'CREATE_ORDER', 'quantity', '', IntToStr(AQuantity));
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při vytváření objednávky: ' + E.Message);
    end;
  end;
end;

function TDataModule1.UpdateOrderStatus(AOrderID: Integer; const AStatus: string): Boolean;
var
  SQL: string;
begin
  Result := False;
  try
    if AStatus = 'Dokončeno' then
      SQL := 'UPDATE orders SET status = :status, completed_at = CURRENT_TIMESTAMP WHERE id = :id'
    else
      SQL := 'UPDATE orders SET status = :status WHERE id = :id';
    
    PrepareQuery(FDQuery1, SQL);
    FDQuery1.ParamByName('id').AsInteger := AOrderID;
    FDQuery1.ParamByName('status').AsString := AStatus;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;
    LogAction(0, 'UPDATE_ORDER', 'status', '', AStatus);
    Result := True;
  except
    on E: Exception do
    begin
      SQLTransaction1.Rollback;
      ShowMessage('Chyba při aktualizaci stavu objednávky: ' + E.Message);
    end;
  end;
end;

function TDataModule1.GetPendingOrders: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := SQLiteConnection1;
  Result.Transaction := SQLTransaction1;
  Result.SQL.Text := 'SELECT o.*, i.name as item_name, i.code, s.name as supplier_name ' +
                     'FROM orders o ' +
                     'JOIN items i ON o.item_id = i.id ' +
                     'LEFT JOIN suppliers s ON o.supplier_id = s.id ' +
                     'WHERE o.status != ''Dokončeno'' ' +
                     'ORDER BY o.created_at DESC';
  Result.Open;
end;

function TDataModule1.CheckAndCreateAutoOrders: Integer;
var
  Query: TSQLQuery;
  ItemID, MinQty, SupplierID, OrderQty: Integer;
begin
  Result := 0;
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := SQLiteConnection1;
    Query.Transaction := SQLTransaction1;
    Query.SQL.Text := 'SELECT id, quantity, min_quantity, supplier_id FROM items WHERE quantity <= min_quantity';
    Query.Open;
    
    while not Query.EOF do
    begin
      ItemID := Query.FieldByName('id').AsInteger;
      MinQty := Query.FieldByName('min_quantity').AsInteger;
      
      if not Query.FieldByName('supplier_id').IsNull then
        SupplierID := Query.FieldByName('supplier_id').AsInteger
      else
        SupplierID := 0;
      
      // Objednat dvojnásobek minimálního množství
      OrderQty := MinQty * 2;
      
      // Zkontrolovat, zda neexistuje již čekající objednávka pro tuto položku
      PrepareQuery(FDQuery1, 'SELECT COUNT(*) as cnt FROM orders WHERE item_id = :item_id AND status = ''Čeká''');
      FDQuery1.ParamByName('item_id').AsInteger := ItemID;
      FDQuery1.Open;
      
      if FDQuery1.FieldByName('cnt').AsInteger = 0 then
      begin
        if CreateOrder(ItemID, OrderQty, SupplierID, 'Automatická objednávka - nízký stav') then
          Inc(Result);
      end;
      
      FDQuery1.Close;
      Query.Next;
    end;
    
    Query.Close;
  finally
    Query.Free;
  end;
end;

// === EXPORT DO EXCEL ===

function TDataModule1.ExportToExcel(const AFileName: string): Boolean;
var
  Query: TSQLQuery;
  F: Text;
  Row: string;
begin
  Result := False;
  try
    Query := TSQLQuery.Create(nil);
    try
      Query.DataBase := SQLiteConnection1;
      Query.Transaction := SQLTransaction1;
      Query.SQL.Text := 'SELECT i.*, w.name as warehouse_name, s.name as supplier_name ' +
                        'FROM items i ' +
                        'LEFT JOIN warehouses w ON i.warehouse_id =w.id ' +
                        'LEFT JOIN suppliers s ON i.supplier_id = s.id ' +
                        'ORDER BY i.code';
      Query.Open;
      
      AssignFile(F, AFileName);
      Rewrite(F);
      
      // Hlavička (CSV formát - Excel může otevřít)
      WriteLn(F, 'Kód;Název;Kategorie;Množství;Cena;Min. množství;Sklad;Dodavatel;Vytvořeno');
      
      while not Query.EOF do
      begin
        Row := Query.FieldByName('code').AsString + ';' +
               Query.FieldByName('name').AsString + ';' +
               Query.FieldByName('category').AsString + ';' +
               Query.FieldByName('quantity').AsString + ';' +
               Query.FieldByName('price').AsString + ';' +
               Query.FieldByName('min_quantity').AsString + ';' +
               Query.FieldByName('warehouse_name').AsString + ';' +
               Query.FieldByName('supplier_name').AsString + ';' +
               Query.FieldByName('created_at').AsString;
        WriteLn(F, Row);
        Query.Next;
      end;
      
      CloseFile(F);
      Result := True;
      ShowMessage('Data úspěšně exportována do souboru: ' + AFileName);
    finally
      Query.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Chyba při exportu do Excelu: ' + E.Message);
  end;
end;

function TDataModule1.PrintInventory: Boolean;
var
  Query: TSQLQuery;
  Y, PageNum, RowCount, TotalItems: Integer;
  LineHeight, LeftMargin, TopMargin: Integer;
  Code, Name, Category, Warehouse: string;
  Quantity, Price: string;
  TotalValue, CurrentValue: Double;
  MaxY: Integer;
begin
  Result := False;
  
  if MessageDlg('Tisknout inventární seznam?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  
  try
    Query := TSQLQuery.Create(nil);
    try
      Query.DataBase := SQLiteConnection1;
      Query.Transaction := SQLTransaction1;
      Query.SQL.Text := 'SELECT i.*, w.name as warehouse_name ' +
                        'FROM items i ' +
                        'LEFT JOIN warehouses w ON i.warehouse_id = w.id ' +
                        'ORDER BY i.code';
      Query.Open;
      
      TotalItems := Query.RecordCount;
      TotalValue := 0;
      
      with Printer do
      begin
        BeginDoc;
        
        LineHeight := 18;
        LeftMargin := 30;
        TopMargin := 30;
        MaxY := PageHeight - 60;
        PageNum := 1;
        RowCount := 0;
        Y := TopMargin;
        
        // Nadpis
        Canvas.Font.Size := 14;
        Canvas.Font.Style := [fsBold];
        Canvas.TextOut(LeftMargin, Y, 'INVENTÁRNÍ SEZNAM - SKLADOVÁ EVIDENCE [PRO]');
        Y := Y + LineHeight + 10;
        
        // Datum tisk
        Canvas.Font.Size := 10;
        Canvas.Font.Style := [];
        Canvas.TextOut(LeftMargin, Y, 'Vytištěno: ' + DateTimeToStr(Now));
        Y := Y + LineHeight;
        Canvas.TextOut(LeftMargin, Y, 'Celk. položek k tisku: ' + IntToStr(TotalItems));
        Y := Y + LineHeight + 10;
        
        // Hlavička sloupců
        Canvas.Font.Style := [fsBold];
        Canvas.Font.Size := 9;
        Canvas.TextOut(LeftMargin, Y, 'KÓD');
        Canvas.TextOut(LeftMargin + 90, Y, 'NÁZEV POLOŽKY');
        Canvas.TextOut(LeftMargin + 250, Y, 'KAT.');
        Canvas.TextOut(LeftMargin + 300, Y, 'KS');
        Canvas.TextOut(LeftMargin + 340, Y, 'CENA/KS');
        Canvas.TextOut(LeftMargin + 420, Y, 'CEL.VALOR.');
        Canvas.TextOut(LeftMargin + 520, Y, 'SKLAD');
        Y := Y + LineHeight;
        
        // Podtržítko
        Canvas.Pen.Color := clBlack;
        Canvas.Pen.Width := 2;
        Canvas.Line(LeftMargin, Y, PageWidth - 30, Y);
        Canvas.Pen.Width := 1;
        Y := Y + 10;
        
        // Data
        Canvas.Font.Style := [];
        Canvas.Font.Size := 8;
        
        while not Query.EOF do
        begin
          if Y > MaxY then
          begin
            NewPage;
            PageNum := PageNum + 1;
            RowCount := 0;
            Y := TopMargin;
            
            // Mini-hlavička
            Canvas.Font.Size := 9;
            Canvas.Font.Style := [fsBold];
            Canvas.TextOut(LeftMargin, Y, Format('(pokontinuace - STRANA %d)', [PageNum]));
            Y := Y + LineHeight;
            
            Canvas.TextOut(LeftMargin, Y, 'KÓD');
            Canvas.TextOut(LeftMargin + 90, Y, 'NÁZEV');
            Canvas.TextOut(LeftMargin + 250, Y, 'KAT.');
            Canvas.TextOut(LeftMargin + 300, Y, 'KS');
            Canvas.TextOut(LeftMargin + 340, Y, 'CENA');
            Canvas.TextOut(LeftMargin + 420, Y, 'VALOR');
            Canvas.TextOut(LeftMargin + 520, Y, 'SKLAD');
            Y := Y + LineHeight;
            
            Canvas.Pen.Color := clBlack;
            Canvas.Pen.Width := 1;
            Canvas.Line(LeftMargin, Y, PageWidth - 30, Y);
            Y := Y + 5;
            
            Canvas.Font.Size := 8;
            Canvas.Font.Style := [];
          end;
          
          Code := Copy(Query.FieldByName('code').AsString, 1, 12);
          Name := Copy(Query.FieldByName('name').AsString, 1, 20);
          Category := Copy(Query.FieldByName('category').AsString, 1, 8);
          Quantity := IntToStr(Query.FieldByName('quantity').AsInteger);
          Price := Format('%.0f', [Query.FieldByName('price').AsFloat]);
          Warehouse := Copy(Query.FieldByName('warehouse_name').AsString, 1, 15);
          
          CurrentValue := Query.FieldByName('quantity').AsInteger * Query.FieldByName('price').AsFloat;
          TotalValue := TotalValue + CurrentValue;
          
          Canvas.TextOut(LeftMargin, Y, Code);
          Canvas.TextOut(LeftMargin + 90, Y, Name);
          Canvas.TextOut(LeftMargin + 250, Y, Category);
          Canvas.TextOut(LeftMargin + 300, Y, Quantity);
          Canvas.TextOut(LeftMargin + 340, Y, Price);
          Canvas.TextOut(LeftMargin + 420, Y, Format('%.0f', [CurrentValue]));
          Canvas.TextOut(LeftMargin + 520, Y, Warehouse);
          
          Y := Y + LineHeight;
          Inc(RowCount);
          Query.Next;
        end;
        
        // Závěrečná sumarizace
        Y := Y + 20;
        Canvas.Pen.Color := clBlack;
        Canvas.Pen.Width := 2;
        Canvas.Line(LeftMargin, Y, PageWidth - 30, Y);
        Canvas.Pen.Width := 1;
        Y := Y + 15;
        
        Canvas.Font.Size := 10;
        Canvas.Font.Style := [fsBold];
        Canvas.TextOut(LeftMargin, Y, 'CELKOVÁ HODNOTA ZÁSOB: ' + FormatFloat('#,##0.00', TotalValue) + ' Kč');
        Y := Y + LineHeight;
        Canvas.TextOut(LeftMargin, Y, 'Počet položek: ' + IntToStr(RowCount));
        
        EndDoc;
      end;
      
      ShowMessage('Inventární seznam úspěšně odeslán do tiskárny.');
      Result := True;
      
    finally
      Query.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Chyba při tisku: ' + E.Message);
  end;
end;

end.
