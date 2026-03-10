unit DatabaseModule;

interface

uses
  SysUtils, Classes, DB, SQLDB, SQLite3Conn, FileUtil;

type
  TDataModule1 = class(TObject)
  private
    FCurrentSearch: string;
    FCurrentCategory: string;
    procedure InitializeDatabase;
    procedure CreateTables;
    procedure InsertSampleData;
    procedure ApplyFilters;
    procedure PrepareQuery(AQuery: TSQLQuery; const ASQL: string);
  public
    SQLiteConnection1: TSQLite3Connection;
    SQLTransaction1: TSQLTransaction;
    FDTable1: TSQLQuery;
    DataSource1: TDataSource;
    FDQuery1: TSQLQuery;

    constructor Create; reintroduce;
    procedure DataModuleCreate(Sender: TObject);
    procedure RefreshData;
    function AddItem(const ACode, AName, ACategory: string;
      AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5): Boolean;
    function UpdateItem(AID: Integer; const ACode, AName, ACategory: string;
      AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5): Boolean;
    function DeleteItem(AID: Integer): Boolean;
    procedure SearchItems(const ASearchText: string);
    procedure FilterByCategory(const ACategory: string);
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
  SQLiteConnection1 := TSQLite3Connection.Create(Self);
  SQLTransaction1 := TSQLTransaction.Create(Self);
  FDTable1 := TSQLQuery.Create(Self);
  FDQuery1 := TSQLQuery.Create(Self);
  DataSource1 := TDataSource.Create(Self);

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
    RefreshData;
  except
    on E: Exception do
      raise Exception.Create('Chyba při připojení k databázi: ' + E.Message);
  end;
end;

procedure TDataModule1.CreateTables;
begin
  SQLiteConnection1.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS items (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  code VARCHAR(50) UNIQUE NOT NULL,' +
    '  name VARCHAR(200) NOT NULL,' +
    '  category VARCHAR(50) NOT NULL,' +
    '  quantity INTEGER DEFAULT 0,' +
    '  price DECIMAL(10,2) DEFAULT 0,' +
    '  min_quantity INTEGER DEFAULT 5,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
    '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
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

  try
    SQLiteConnection1.ExecuteDirect('ALTER TABLE items ADD COLUMN min_quantity INTEGER DEFAULT 5');
  except
    // already exists
  end;

  try
    SQLiteConnection1.ExecuteDirect('ALTER TABLE items ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP');
  except
    // already exists
  end;

  SQLTransaction1.Commit;
end;

procedure TDataModule1.InsertSampleData;
begin
  SQLiteConnection1.ExecuteDirect(
    'INSERT INTO items (code, name, category, quantity, price, min_quantity) VALUES ' +
    '(''ELEC001'', ''Notebook Dell XPS 13'', ''Elektronika'', 5, 28990.00, 3),' +
    '(''ELEC002'', ''Myš Logitech MX Master'', ''Elektronika'', 12, 2490.00, 5),' +
    '(''ELEC003'', ''Monitor LG 27"'', ''Elektronika'', 2, 7990.00, 3),' +
    '(''FURN001'', ''Kancelářská židle ErgoMax'', ''Nábytek'', 8, 4590.00, 4),' +
    '(''FURN002'', ''Psací stůl 160x80 cm'', ''Nábytek'', 3, 5990.00, 2),' +
    '(''TOOL001'', ''Šroubovák sada 12 ks'', ''Nářadí'', 20, 450.00, 10),' +
    '(''FOOD001'', ''Káva arabika 500g'', ''Potraviny'', 4, 199.00, 10),' +
    '(''OFFI001'', ''Papír A4 500 listů'', ''Kancelářské potřeby'', 15, 89.00, 20)'
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
  AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5): Boolean;
var
  NewID: Integer;
begin
  Result := False;

  if CodeExists(ACode, -1) then
    raise Exception.Create('Položka s kódem "' + ACode + '" již existuje!');

  try
    PrepareQuery(FDQuery1,
      'INSERT INTO items (code, name, category, quantity, price, min_quantity) ' +
      'VALUES (:code, :name, :category, :quantity, :price, :min_quantity)');
    FDQuery1.ParamByName('code').AsString := ACode;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('category').AsString := ACategory;
    FDQuery1.ParamByName('quantity').AsInteger := AQuantity;
    FDQuery1.ParamByName('price').AsFloat := APrice;
    FDQuery1.ParamByName('min_quantity').AsInteger := AMinQuantity;
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
  AQuantity: Integer; APrice: Double; AMinQuantity: Integer = 5): Boolean;
var
  OldCode, OldName, OldCategory: string;
  OldQuantity, OldMinQuantity: Integer;
  OldPrice: Double;
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

    PrepareQuery(FDQuery1,
      'UPDATE items SET code=:code, name=:name, category=:category, quantity=:quantity, ' +
      'price=:price, min_quantity=:min_quantity, updated_at=CURRENT_TIMESTAMP WHERE id=:id');
    FDQuery1.ParamByName('id').AsInteger := AID;
    FDQuery1.ParamByName('code').AsString := ACode;
    FDQuery1.ParamByName('name').AsString := AName;
    FDQuery1.ParamByName('category').AsString := ACategory;
    FDQuery1.ParamByName('quantity').AsInteger := AQuantity;
    FDQuery1.ParamByName('price').AsFloat := APrice;
    FDQuery1.ParamByName('min_quantity').AsInteger := AMinQuantity;
    FDQuery1.ExecSQL;
    SQLTransaction1.Commit;

    if OldCode <> ACode then LogAction(AID, 'UPDATE', 'code', OldCode, ACode);
    if OldName <> AName then LogAction(AID, 'UPDATE', 'name', OldName, AName);
    if OldCategory <> ACategory then LogAction(AID, 'UPDATE', 'category', OldCategory, ACategory);
    if OldQuantity <> AQuantity then LogAction(AID, 'UPDATE', 'quantity', IntToStr(OldQuantity), IntToStr(AQuantity));
    if Abs(OldPrice - APrice) > 0.0001 then LogAction(AID, 'UPDATE', 'price', FormatFloat('0.00', OldPrice), FormatFloat('0.00', APrice));
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

end.
