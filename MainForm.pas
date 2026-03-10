unit MainForm;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, DB,
  Grids, DBGrids, ExtCtrls, DatabaseModule, ComCtrls, SQLDB, WarehouseForm,
  SupplierForm, StatisticsForm, fphttpclient;

type
  TFormMain = class(TForm)
    PanelTop: TPanel;
    PanelGrid: TPanel;
    DBGrid1: TDBGrid;
    Label1: TLabel;
    EditCode: TEdit;
    Label2: TLabel;
    EditName: TEdit;
    Label3: TLabel;
    ComboCategory: TComboBox;
    Label4: TLabel;
    EditQuantity: TEdit;
    Label5: TLabel;
    EditPrice: TEdit;
    ButtonAdd: TButton;
    ButtonUpdate: TButton;
    ButtonDelete: TButton;
    ButtonClear: TButton;
    StatusBar1: TStatusBar;
    LabelTitle: TLabel;
    EditMinQuantity: TEdit;
    ButtonExport: TButton;
    ButtonImport: TButton;
    ButtonBackup: TButton;
    ButtonStatistics: TButton;
    ButtonAuditLog: TButton;
    ComboWarehouse: TComboBox;
    ComboSupplier: TComboBox;
    Label9: TLabel;
    Label10: TLabel;
    LabelLanguage: TLabel;
    ButtonWarehouses: TButton;
    ButtonSuppliers: TButton;
    ButtonExportExcel: TButton;
    ButtonPrint: TButton;
    ButtonGenerateQR: TButton;
    ImageQR: TImage;
    PanelQR: TPanel;
    ComboLanguage: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormShow(Sender: TObject);
    procedure ButtonExportClick(Sender: TObject);
    procedure ButtonImportClick(Sender: TObject);
    procedure ButtonBackupClick(Sender: TObject);
    procedure ButtonStatisticsClick(Sender: TObject);
    procedure ButtonAuditLogClick(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure ButtonWarehousesClick(Sender: TObject);
    procedure ButtonSuppliersClick(Sender: TObject);
    procedure ButtonExportExcelClick(Sender: TObject);
    procedure ButtonPrintClick(Sender: TObject);
    procedure ButtonGenerateQRClick(Sender: TObject);
    procedure ComboWarehouseChange(Sender: TObject);
    procedure ComboSupplierChange(Sender: TObject);
    procedure ComboLanguageChange(Sender: TObject);
  private
    FCurrentLanguage: string;
    procedure ClearInputs;
    procedure LoadSelectedItem;
    function ValidateInputs: Boolean;
    procedure UpdateStatusBar;
    procedure CheckLowStock;
    procedure ShowStatistics;
    procedure LoadWarehouses;
    procedure LoadSuppliers;
    procedure ApplyLanguage(const ALang: string);
    function L(const CZ, EN, DE: string): string;
    function UrlEncode(const AValue: string): string;
    function GetSelectedItemCode: string;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

function TFormMain.L(const CZ, EN, DE: string): string;
begin
  case UpperCase(FCurrentLanguage) of
    'EN': Result := EN;
    'DE': Result := DE;
  else
    Result := CZ;
  end;
end;

function TFormMain.UrlEncode(const AValue: string): string;
const
  SafeChars = ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'];
var
  I: Integer;
  U: UTF8String;
  C: Byte;
begin
  Result := '';
  U := UTF8Encode(AValue);
  for I := 1 to Length(U) do
  begin
    C := Byte(U[I]);
    if Char(C) in SafeChars then
      Result := Result + Char(C)
    else
      Result := Result + '%' + IntToHex(C, 2);
  end;
end;

function TFormMain.GetSelectedItemCode: string;
begin
  Result := Trim(EditCode.Text);
  if (Result = '') and (not DataModule1.FDTable1.IsEmpty) then
    Result := DataModule1.FDTable1.FieldByName('code').AsString;
end;

procedure TFormMain.ApplyLanguage(const ALang: string);
begin
  FCurrentLanguage := UpperCase(ALang);
  if (FCurrentLanguage <> 'CZ') and (FCurrentLanguage <> 'EN') and (FCurrentLanguage <> 'DE') then
    FCurrentLanguage := 'CZ';

  Caption := L('Skladová Evidence - Delphi Aplikace [PRO]',
               'Inventory Management - Delphi App [PRO]',
               'Lagerverwaltung - Delphi Anwendung [PRO]');
  LabelTitle.Caption := L('Skladová Evidence PRO', 'Inventory Management PRO', 'Lagerverwaltung PRO');
  Label1.Caption := L('Kód položky:', 'Item Code:', 'Artikelcode:');
  Label2.Caption := L('Název položky:', 'Item Name:', 'Artikelname:');
  Label3.Caption := L('Kategorie:', 'Category:', 'Kategorie:');
  Label4.Caption := L('Množství:', 'Quantity:', 'Menge:');
  Label5.Caption := L('Cena (Kč):', 'Price (CZK):', 'Preis (CZK):');
  Label9.Caption := L('Sklad:', 'Warehouse:', 'Lager:');
  Label10.Caption := L('Dodavatel:', 'Supplier:', 'Lieferant:');
  LabelLanguage.Caption := L('Jazyk:', 'Language:', 'Sprache:');

  ButtonAdd.Caption := L('Přidat', 'Add', 'Hinzufugen');
  ButtonUpdate.Caption := L('Upravit', 'Update', 'Bearbeiten');
  ButtonDelete.Caption := L('Smazat', 'Delete', 'Loschen');
  ButtonClear.Caption := L('Vyčistit', 'Clear', 'Leeren');
  ButtonExport.Caption := L('Export CSV', 'Export CSV', 'CSV Export');
  ButtonImport.Caption := L('Import CSV', 'Import CSV', 'CSV Import');
  ButtonBackup.Caption := L('Záloha DB', 'DB Backup', 'DB Sicherung');
  ButtonStatistics.Caption := L('Statistiky', 'Statistics', 'Statistiken');
  ButtonAuditLog.Caption := L('Audit Log', 'Audit Log', 'Audit-Log');
  ButtonWarehouses.Caption := L('Sklady', 'Warehouses', 'Lager');
  ButtonSuppliers.Caption := L('Dodavatelé', 'Suppliers', 'Lieferanten');
  ButtonExportExcel.Caption := L('Export Excel', 'Export Excel', 'Excel Export');
  ButtonPrint.Caption := L('Tisk', 'Print', 'Drucken');
  ButtonGenerateQR.Caption := L('QR kód', 'QR Code', 'QR-Code');

  if ComboWarehouse.Items.Count > 0 then
    ComboWarehouse.Items[0] := L('-- Žádný --', '-- None --', '-- Kein --');
  if ComboSupplier.Items.Count > 0 then
    ComboSupplier.Items[0] := L('-- Žádný --', '-- None --', '-- Kein --');

  UpdateStatusBar;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // Vynutit konzistentni rozlozeni cele horni sekce (oprava prekryvani prvku)
  Label1.SetBounds(16, 56, Label1.Width, Label1.Height);
  EditCode.SetBounds(16, 72, 260, 21);
  Label2.SetBounds(16, 104, Label2.Width, Label2.Height);
  EditName.SetBounds(16, 120, 260, 21);
  Label3.SetBounds(16, 152, Label3.Width, Label3.Height);
  ComboCategory.SetBounds(16, 168, 260, 21);

  Label9.SetBounds(16, 218, Label9.Width, Label9.Height);
  ComboWarehouse.SetBounds(16, 234, 180, 21);
  Label10.SetBounds(206, 218, Label10.Width, Label10.Height);
  ComboSupplier.SetBounds(206, 234, 220, 21);

  Label4.SetBounds(300, 104, Label4.Width, Label4.Height);
  EditQuantity.SetBounds(300, 120, 120, 21);
  Label5.SetBounds(300, 152, Label5.Width, Label5.Height);
  EditPrice.SetBounds(300, 168, 120, 21);
  EditMinQuantity.SetBounds(300, 200, 120, 21);

  LabelLanguage.SetBounds(850, 22, LabelLanguage.Width, LabelLanguage.Height);
  ComboLanguage.SetBounds(930, 18, 140, 21);

  ButtonAdd.SetBounds(460, 88, 110, 30);
  ButtonUpdate.SetBounds(580, 88, 110, 30);
  ButtonDelete.SetBounds(460, 120, 110, 30);
  ButtonClear.SetBounds(580, 120, 110, 30);
  ButtonWarehouses.SetBounds(460, 152, 110, 30);
  ButtonSuppliers.SetBounds(580, 152, 110, 30);

  PanelQR.SetBounds(702, 80, 136, 168);
  ImageQR.SetBounds(10, 10, 116, 116);
  ButtonGenerateQR.SetBounds(13, 132, 110, 30);

  ButtonExport.SetBounds(850, 72, 110, 30);
  ButtonImport.SetBounds(970, 72, 110, 30);
  ButtonBackup.SetBounds(850, 104, 110, 30);
  ButtonStatistics.SetBounds(970, 104, 110, 30);
  ButtonAuditLog.SetBounds(850, 136, 110, 30);
  ButtonExportExcel.SetBounds(850, 168, 110, 30);
  ButtonPrint.SetBounds(970, 168, 110, 30);
  
  // Naplnění ComboBoxu kategoriemi
  ComboCategory.Items.Clear;
  ComboCategory.Items.Add('Elektronika');
  ComboCategory.Items.Add('Nábytek');
  ComboCategory.Items.Add('Oblečení');
  ComboCategory.Items.Add('Potraviny');
  ComboCategory.Items.Add('Nářadí');
  ComboCategory.Items.Add('Kancelářské potřeby');
  
  // Propojení DataSource s DBGrid
  DBGrid1.DataSource := DataModule1.DataSource1;

  // České názvy sloupců pomocí DisplayLabel
  if Assigned(DataModule1.DataSource1.DataSet) and (DataModule1.DataSource1.DataSet.Active) then
  begin
    if Assigned(DataModule1.DataSource1.DataSet.FindField('id')) then
      DataModule1.DataSource1.DataSet.FieldByName('id').DisplayLabel := 'ID';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('code')) then
      DataModule1.DataSource1.DataSet.FieldByName('code').DisplayLabel := 'Kód';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('name')) then
      DataModule1.DataSource1.DataSet.FieldByName('name').DisplayLabel := 'Název';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('category')) then
      DataModule1.DataSource1.DataSet.FieldByName('category').DisplayLabel := 'Kategorie';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('quantity')) then
      DataModule1.DataSource1.DataSet.FieldByName('quantity').DisplayLabel := 'Množství';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('price')) then
      DataModule1.DataSource1.DataSet.FieldByName('price').DisplayLabel := 'Cena';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('min_quantity')) then
      DataModule1.DataSource1.DataSet.FieldByName('min_quantity').DisplayLabel := 'Min. ks';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('created_at')) then
      DataModule1.DataSource1.DataSet.FieldByName('created_at').DisplayLabel := 'Vytvořeno';
    if Assigned(DataModule1.DataSource1.DataSet.FindField('updated_at')) then
      DataModule1.DataSource1.DataSet.FieldByName('updated_at').DisplayLabel := 'Upraveno';
  end;
  
  // Načtení skladů a dodavatelů
  LoadWarehouses;
  LoadSuppliers;

  ComboLanguage.Items.Clear;
  ComboLanguage.Items.Add('CZ');
  ComboLanguage.Items.Add('EN');
  ComboLanguage.Items.Add('DE');
  ComboLanguage.ItemIndex := 0;
  FCurrentLanguage := 'CZ';
  ApplyLanguage(FCurrentLanguage);
  
  // Nastavit event handlery pro filtry
  ComboWarehouse.OnChange := @ComboWarehouseChange;
  ComboSupplier.OnChange := @ComboSupplierChange;
  
  ClearInputs;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  UpdateStatusBar;
  CheckLowStock;
end;

procedure TFormMain.ClearInputs;
begin
  EditCode.Text := '';
  EditName.Text := '';
  ComboCategory.ItemIndex := -1;
  EditQuantity.Text := '0';
  EditPrice.Text := '0';
  EditMinQuantity.Text := '5';
  ImageQR.Picture.Clear;
end;

procedure TFormMain.LoadSelectedItem;
begin
  if not DataModule1.FDTable1.IsEmpty then
  begin
    EditCode.Text := DataModule1.FDTable1.FieldByName('code').AsString;
    EditName.Text := DataModule1.FDTable1.FieldByName('name').AsString;
    ComboCategory.Text := DataModule1.FDTable1.FieldByName('category').AsString;
    EditQuantity.Text := DataModule1.FDTable1.FieldByName('quantity').AsString;
    EditPrice.Text := FormatFloat('0.00', DataModule1.FDTable1.FieldByName('price').AsFloat);
    
    // Načíst min_quantity pokud existuje
    try
      EditMinQuantity.Text := DataModule1.FDTable1.FieldByName('min_quantity').AsString;
    except
      EditMinQuantity.Text := '5';
    end;
    

  end;
end;

function TFormMain.ValidateInputs: Boolean;
var
  Quantity, Price: Double;
begin
  Result := False;
  
  if Trim(EditCode.Text) = '' then
  begin
    ShowMessage('Vyplňte kód položky');
    EditCode.SetFocus;
    Exit;
  end;
  
  // Kontrola duplikátního kódu (jen při přidávání nové položky)
  if DataModule1.FDTable1.IsEmpty or (DataModule1.FDTable1.FieldByName('code').AsString <> EditCode.Text) then
  begin
    if DataModule1.CodeExists(Trim(EditCode.Text)) then
    begin
      ShowMessage('Položka s tímto kódem již existuje!');
      EditCode.SetFocus;
      Exit;
    end;
  end;
  
  if Trim(EditName.Text) = '' then
  begin
    ShowMessage('Vyplňte název položky');
    EditName.SetFocus;
    Exit;
  end;
  
  if ComboCategory.ItemIndex = -1 then
  begin
    ShowMessage('Vyberte kategorii');
    ComboCategory.SetFocus;
    Exit;
  end;
  
  try
    Quantity := StrToFloat(EditQuantity.Text);
    if Quantity < 0 then
    begin
      ShowMessage('Množství nesmí být záporné');
      EditQuantity.SetFocus;
      Exit;
    end;
  except
    ShowMessage('Množství musí být číslo');
    EditQuantity.SetFocus;
    Exit;
  end;
  
  try
    Price := StrToFloat(EditPrice.Text);
    if Price < 0 then
    begin
      ShowMessage('Cena nesmí být záporná');
      EditPrice.SetFocus;
      Exit;
    end;
  except
    ShowMessage('Cena musí být číslo');
    EditPrice.SetFocus;
    Exit;
  end;
  
  Result := True;
end;

procedure TFormMain.UpdateStatusBar;
var
  TotalItems: Integer;
  TotalValue: Double;
  LowStockCount: Integer;
begin
  TotalItems := DataModule1.GetTotalItems;
  TotalValue := DataModule1.GetTotalValue;
  LowStockCount := DataModule1.GetLowStockItems;
  
  StatusBar1.Panels[0].Text := Format(L('Položek: %d', 'Items: %d', 'Artikel: %d'), [TotalItems]);
  StatusBar1.Panels[1].Text := Format(L('Celková hodnota: %s Kč', 'Total value: %s CZK', 'Gesamtwert: %s CZK'),
    [FormatFloat('#,##0.00', TotalValue)]);
  
  if LowStockCount > 0 then
  begin
    StatusBar1.Panels[2].Text := Format(L('Nizky stav: %d', 'Low stock: %d', 'Niedriger Bestand: %d'), [LowStockCount]);
    StatusBar1.Panels[2].Style := psOwnerDraw;
  end
  else
  begin
    StatusBar1.Panels[2].Text := 'OK';
  end;
end;

procedure TFormMain.CheckLowStock;
var
  LowStockCount: Integer;
  Msg: string;
begin
  LowStockCount := DataModule1.GetLowStockItems;
  
  if LowStockCount > 0 then
  begin
    Msg := Format('Varování: %d položek má nízký stav na skladě (množství ≤ min. množství)!', 
                  [LowStockCount]);
    MessageDlg(Msg, mtWarning, [mbOK], 0);
  end;
end;

procedure TFormMain.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Quantity, MinQuantity: Integer;
begin
  // Zvýraznit řádky s nízkým stavem červeně
  if (Column.FieldName = 'quantity') or (Column.FieldName = 'min_quantity') then
  begin
    try
      Quantity := DataModule1.FDTable1.FieldByName('quantity').AsInteger;
      MinQuantity := DataModule1.FDTable1.FieldByName('min_quantity').AsInteger;
      
      if Quantity <= MinQuantity then
      begin
        if not (gdSelected in State) then
        begin
          DBGrid1.Canvas.Brush.Color := $8080FF; // Světle červená
          DBGrid1.Canvas.Font.Color := clBlack;
        end;
      end;
    except
      // Ignorovat chyby
    end;
  end;
  
  DBGrid1.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TFormMain.ButtonAddClick(Sender: TObject);
var
  WarehouseID, SupplierID: Integer;
  PhotoPath: string;
begin
  if not ValidateInputs then
    Exit;
  
  // Získání ID skladu a dodavatele z ComboBoxů
  if ComboWarehouse.ItemIndex > 0 then
    WarehouseID := PtrInt(ComboWarehouse.Items.Objects[ComboWarehouse.ItemIndex])
  else
    WarehouseID := 0;
  
  if ComboSupplier.ItemIndex > 0 then
    SupplierID := PtrInt(ComboSupplier.Items.Objects[ComboSupplier.ItemIndex])
  else
    SupplierID := 0;
  
  // Cesta k fotce (uložená v Hint během výběru)
  PhotoPath := EditCode.Hint;
    
  try
    if DataModule1.AddItem(
      Trim(EditCode.Text),
      Trim(EditName.Text),
      ComboCategory.Text,
      StrToInt(EditQuantity.Text),
      StrToFloat(EditPrice.Text),
      StrToIntDef(EditMinQuantity.Text, 5),
      WarehouseID,
      SupplierID,
      PhotoPath
    ) then
    begin
      ShowMessage('Položka byla úspěšně přidána');
      ClearInputs;
      UpdateStatusBar;
      CheckLowStock;
    end;
  except
    on E: Exception do
      ShowMessage('Chyba: ' + E.Message);
  end;
end;

procedure TFormMain.ButtonUpdateClick(Sender: TObject);
var
  ItemID, WarehouseID, SupplierID: Integer;
  PhotoPath: string;
begin
  if DataModule1.FDTable1.IsEmpty then
  begin
    ShowMessage('Vyberte položku k aktualizaci');
    Exit;
  end;
  
  if not ValidateInputs then
    Exit;
  
  // Získání ID skladu a dodavatele z ComboBoxů
  if ComboWarehouse.ItemIndex > 0 then
    WarehouseID := PtrInt(ComboWarehouse.Items.Objects[ComboWarehouse.ItemIndex])
  else
    WarehouseID := 0;
  
  if ComboSupplier.ItemIndex > 0 then
    SupplierID := PtrInt(ComboSupplier.Items.Objects[ComboSupplier.ItemIndex])
  else
    SupplierID := 0;
  
  // Cesta k fotce (pokud byla vybrána)
  PhotoPath := EditCode.Hint;
    
  try
    ItemID := DataModule1.FDTable1.FieldByName('id').AsInteger;
    
    if DataModule1.UpdateItem(
      ItemID,
      Trim(EditCode.Text),
      Trim(EditName.Text),
      ComboCategory.Text,
      StrToInt(EditQuantity.Text),
      StrToFloat(EditPrice.Text),
      StrToIntDef(EditMinQuantity.Text, 5),
      WarehouseID,
      SupplierID,
      PhotoPath
    ) then
    begin
      ShowMessage('Položka byla úspěšně aktualizována');
      ClearInputs;
      UpdateStatusBar;
      CheckLowStock;
    end;
  except
    on E: Exception do
      ShowMessage('Chyba: ' + E.Message);
  end;
end;

procedure TFormMain.ButtonDeleteClick(Sender: TObject);
var
  ItemID: Integer;
  ItemName: string;
begin
  if DataModule1.FDTable1.IsEmpty then
  begin
    ShowMessage('Vyberte položku ke smazání');
    Exit;
  end;
  
  ItemID := DataModule1.FDTable1.FieldByName('id').AsInteger;
  ItemName := DataModule1.FDTable1.FieldByName('name').AsString;
  
  if MessageDlg('Opravdu chcete smazat položku "' + ItemName + '"?', 
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      if DataModule1.DeleteItem(ItemID) then
      begin
        ShowMessage('Položka byla úspěšně smazána');
        ClearInputs;
        UpdateStatusBar;
      end;
    except
      on E: Exception do
        ShowMessage('Chyba: ' + E.Message);
    end;
  end;
end;

procedure TFormMain.ButtonClearClick(Sender: TObject);
begin
  ClearInputs;
  DataModule1.SearchItems('');
  UpdateStatusBar;
end;

procedure TFormMain.ButtonExportClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  FileName: string;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Title := 'Export do CSV';
    SaveDialog.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory (*.*)|*.*';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := Format('export_sklad_%s.csv', 
      [FormatDateTime('yyyymmdd_hhnnss', Now)]);
    
    if SaveDialog.Execute then
    begin
      FileName := SaveDialog.FileName;
      try
        if DataModule1.ExportToCSV(FileName) then
          ShowMessage('Data byla úspěšně exportována do: ' + FileName)
        else
          ShowMessage('Export se nezdařil');
      except
        on E: Exception do
          ShowMessage('Chyba při exportu: ' + E.Message);
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TFormMain.ButtonImportClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  FileName: string;
begin
  if MessageDlg('Opravdu chcete importovat data? Duplicitní kódy budou přeskočeny.',
                mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;
    
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Title := 'Import z CSV';
    OpenDialog.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory (*.*)|*.*';
    OpenDialog.DefaultExt := 'csv';
    
    if OpenDialog.Execute then
    begin
      FileName := OpenDialog.FileName;
      try
        if DataModule1.ImportFromCSV(FileName) then
        begin
          ShowMessage('Data byla úspěšně importována');
          UpdateStatusBar;
          CheckLowStock;
        end
        else
          ShowMessage('Import se nezdařil nebo nebyla importována žádná data');
      except
        on E: Exception do
          ShowMessage('Chyba při importu: ' + E.Message);
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TFormMain.ButtonBackupClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  BackupPath: string;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Title := 'Zálohovat databázi';
    SaveDialog.Filter := 'SQLite databáze (*.db)|*.db|Všechny soubory (*.*)|*.*';
    SaveDialog.DefaultExt := 'db';
    SaveDialog.FileName := Format('backup_inventory_%s.db', 
      [FormatDateTime('yyyymmdd_hhnnss', Now)]);
    
    if SaveDialog.Execute then
    begin
      BackupPath := SaveDialog.FileName;
      try
        if DataModule1.BackupDatabase(BackupPath) then
          ShowMessage('Záloha byla úspěšně vytvořena: ' + BackupPath)
        else
          ShowMessage('Záloha se nezdařila');
      except
        on E: Exception do
          ShowMessage('Chyba při zálohování: ' + E.Message);
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TFormMain.ShowStatistics;
begin
  Application.CreateForm(TFormStatistics, FormStatistics);
  try
    FormStatistics.ShowModal;
  finally
    FormStatistics.Free;
  end;
end;

procedure TFormMain.ButtonStatisticsClick(Sender: TObject);
begin
  ShowStatistics;
end;

procedure TFormMain.ButtonAuditLogClick(Sender: TObject);
var
  AuditQuery: TSQLQuery;
  LogText: string;
  Count: Integer;
begin
  AuditQuery := nil;
  try
    AuditQuery := DataModule1.GetAuditLog(-1); // Všechny záznamy
    Count := 0;
    
    LogText := '═══ AUDITNÍ LOG (posledních 20 záznamů) ═══' + sLineBreak + sLineBreak;
    
    AuditQuery.First;
    while (not AuditQuery.Eof) and (Count < 20) do
    begin
      LogText := LogText + Format('[%s] %s', [
        AuditQuery.FieldByName('created_at').AsString,
        AuditQuery.FieldByName('action').AsString
      ]);
      
      if not AuditQuery.FieldByName('field_name').IsNull then
        LogText := LogText + Format(' - %s: "%s" → "%s"', [
          AuditQuery.FieldByName('field_name').AsString,
          AuditQuery.FieldByName('old_value').AsString,
          AuditQuery.FieldByName('new_value').AsString
        ]);
      
      LogText := LogText + sLineBreak;
      
      Inc(Count);
      AuditQuery.Next;
    end;
    
    if Count = 0 then
      LogText := LogText + 'Žádné záznamy v logu'
    else
      LogText := LogText + sLineBreak + Format('Zobrazeno %d z celkem záznamů', [Count]);
    
    MessageDlg(LogText, mtInformation, [mbOK], 0);
  finally
    if Assigned(AuditQuery) then
      AuditQuery.Free;
  end;
end;

procedure TFormMain.DBGrid1CellClick(Column: TColumn);
begin
  if Column = nil then; // Suppress hint
  LoadSelectedItem;
end;

procedure TFormMain.LoadWarehouses;
var
  Query: TSQLQuery;
begin
  ComboWarehouse.Clear;
  ComboWarehouse.Items.Add(L('-- Žádný --', '-- None --', '-- Kein --'));
  
  Query := DataModule1.GetWarehouses;
  try
    while not Query.EOF do
    begin
      ComboWarehouse.Items.AddObject(Query.FieldByName('name').AsString, 
        TObject(PtrInt(Query.FieldByName('id').AsInteger)));
      Query.Next;
    end;
    ComboWarehouse.ItemIndex := 0;
  finally
    Query.Free;
  end;
end;

procedure TFormMain.LoadSuppliers;
var
  Query: TSQLQuery;
begin
  ComboSupplier.Clear;
  ComboSupplier.Items.Add(L('-- Žádný --', '-- None --', '-- Kein --'));
  
  Query := DataModule1.GetSuppliers;
  try
    while not Query.EOF do
    begin
      ComboSupplier.Items.AddObject(Query.FieldByName('name').AsString, 
        TObject(PtrInt(Query.FieldByName('id').AsInteger)));
      Query.Next;
    end;
    ComboSupplier.ItemIndex := 0;
  finally
    Query.Free;
  end;
end;

procedure TFormMain.ButtonWarehousesClick(Sender: TObject);
begin
  Application.CreateForm(TFormWarehouse, FormWarehouse);
  try
    FormWarehouse.ShowModal;
    LoadWarehouses; // Refresh po zavření
  finally
    FormWarehouse.Free;
  end;
end;

procedure TFormMain.ButtonSuppliersClick(Sender: TObject);
begin
  Application.CreateForm(TFormSupplier, FormSupplier);
  try
    FormSupplier.ShowModal;
    LoadSuppliers; // Refresh po zavření
  finally
    FormSupplier.Free;
  end;
end;

procedure TFormMain.ButtonExportExcelClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Filter := 'CSV soubory (Excel)|*.csv|Všechny soubory|*.*';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := 'export_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.csv';
    
    if SaveDialog.Execute then
    begin
      if DataModule1.ExportToExcel(SaveDialog.FileName) then
        ShowMessage('Export dokončen!');
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TFormMain.ButtonGenerateQRClick(Sender: TObject);
var
  ItemCode: string;
  QrPayload: string;
  Url: string;
  TempFile: string;
  HttpClient: TFPHTTPClient;
  FileStream: TFileStream;
begin
  ItemCode := GetSelectedItemCode;
  if ItemCode = '' then
  begin
    ShowMessage(L('Vyberte položku nebo vyplňte kód položky.',
                  'Select an item or fill in the item code.',
                  'Wahlen Sie einen Artikel oder geben Sie den Artikelcode ein.'));
    Exit;
  end;

  // Pouzivame online API pro tvorbu skutecneho QR kodu bez externe knihovny.
  QrPayload := 'INV:' + ItemCode;
  Url := 'http://api.qrserver.com/v1/create-qr-code/?size=220x220&data=' + UrlEncode(QrPayload);
  TempFile := GetTempDir(False) + 'inventory_qr_preview.png';

  HttpClient := TFPHTTPClient.Create(nil);
  try
    HttpClient.AllowRedirect := True;
    FileStream := TFileStream.Create(TempFile, fmCreate);
    try
      HttpClient.Get(Url, FileStream);
    finally
      FileStream.Free;
    end;

    ImageQR.Picture.LoadFromFile(TempFile);
    ImageQR.Stretch := True;
    ImageQR.Center := True;
    ShowMessage(L('QR kód byl vygenerován pro položku: ',
                  'QR code generated for item: ',
                  'QR-Code wurde fur Artikel erstellt: ') + ItemCode);
  except
    on E: Exception do
      ShowMessage(L('Nepodařilo se vygenerovat QR kód. Zkontrolujte internetové připojení.' + sLineBreak + E.Message,
                    'Failed to generate QR code. Check internet connection.' + sLineBreak + E.Message,
                    'QR-Code konnte nicht erstellt werden. Prufen Sie die Internetverbindung.' + sLineBreak + E.Message));
  end;
  HttpClient.Free;
end;

procedure TFormMain.ComboWarehouseChange(Sender: TObject);
begin
  if ComboWarehouse.ItemIndex = 0 then
    DataModule1.FilterByWarehouse(-1)  // Žádný filtr
  else
    DataModule1.FilterByWarehouse(PtrInt(ComboWarehouse.Items.Objects[ComboWarehouse.ItemIndex]));
  UpdateStatusBar;
end;

procedure TFormMain.ComboSupplierChange(Sender: TObject);
begin
  if ComboSupplier.ItemIndex = 0 then
    DataModule1.FilterBySupplier(-1)  // Žádný filtr
  else
    DataModule1.FilterBySupplier(PtrInt(ComboSupplier.Items.Objects[ComboSupplier.ItemIndex]));
  UpdateStatusBar;
end;

procedure TFormMain.ComboLanguageChange(Sender: TObject);
begin
  if ComboLanguage.ItemIndex >= 0 then
    ApplyLanguage(ComboLanguage.Items[ComboLanguage.ItemIndex]);
end;


procedure TFormMain.ButtonPrintClick(Sender: TObject);
begin
  DataModule1.PrintInventory;
end;

end.
