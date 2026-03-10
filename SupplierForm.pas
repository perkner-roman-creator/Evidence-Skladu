unit SupplierForm;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  DB, DBGrids, ExtCtrls, DatabaseModule, SQLDB;

type
  TFormSupplier = class(TForm)
    PanelTop: TPanel;
    LabelName: TLabel;
    EditName: TEdit;
    LabelContact: TLabel;
    EditContact: TEdit;
    LabelPhone: TLabel;
    EditPhone: TEdit;
    LabelEmail: TLabel;
    EditEmail: TEdit;
    LabelAddress: TLabel;
    MemoAddress: TMemo;
    ButtonAdd: TButton;
    ButtonUpdate: TButton;
    ButtonDelete: TButton;
    ButtonClose: TButton;
    DBGridSuppliers: TDBGrid;
    DataSourceSuppliers: TDataSource;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure DBGridSuppliersCellClick(Column: TColumn);
  private
    FSupplierQuery: TSQLQuery;
    procedure RefreshSuppliers;
    procedure ClearInputs;
  end;

var
  FormSupplier: TFormSupplier;

implementation

{$R *.lfm}

procedure TFormSupplier.FormCreate(Sender: TObject);
begin
  Caption := 'Správa dodavatelů';
  
  // Nastavení českých popisků
  LabelName.Caption := 'Název firmy:';
  LabelContact.Caption := 'Kontaktní osoba:';
  LabelPhone.Caption := 'Telefon:';
  LabelEmail.Caption := 'E-mail:';
  LabelAddress.Caption := 'Adresa:';
  ButtonAdd.Caption := 'Přidat';
  ButtonUpdate.Caption := 'Aktualizovat';
  ButtonDelete.Caption := 'Smazat';
  ButtonClose.Caption := 'Zavřít';
  
  // Načtení dat
  RefreshSuppliers;
end;

procedure TFormSupplier.FormDestroy(Sender: TObject);
begin
  if Assigned(FSupplierQuery) then
    FSupplierQuery.Free;
end;

procedure TFormSupplier.RefreshSuppliers;
begin
  DataSourceSuppliers.DataSet := nil;
  if Assigned(FSupplierQuery) then
    FSupplierQuery.Free;
    
  FSupplierQuery := DataModule1.GetSuppliers;
  DataSourceSuppliers.DataSet := FSupplierQuery;
  
  // Nastavení českých názvů sloupců
  if Assigned(FSupplierQuery.FindField('id')) then
    FSupplierQuery.FieldByName('id').DisplayLabel := 'ID';
  if Assigned(FSupplierQuery.FindField('name')) then
    FSupplierQuery.FieldByName('name').DisplayLabel := 'Název';
  if Assigned(FSupplierQuery.FindField('contact_person')) then
    FSupplierQuery.FieldByName('contact_person').DisplayLabel := 'Kontakt';
  if Assigned(FSupplierQuery.FindField('phone')) then
    FSupplierQuery.FieldByName('phone').DisplayLabel := 'Telefon';
  if Assigned(FSupplierQuery.FindField('email')) then
    FSupplierQuery.FieldByName('email').DisplayLabel := 'E-mail';
  if Assigned(FSupplierQuery.FindField('address')) then
    FSupplierQuery.FieldByName('address').DisplayLabel := 'Adresa';
end;

procedure TFormSupplier.ClearInputs;
begin
  EditName.Text := '';
  EditContact.Text := '';
  EditPhone.Text := '';
  EditEmail.Text := '';
  MemoAddress.Lines.Clear;
end;

procedure TFormSupplier.ButtonAddClick(Sender: TObject);
begin
  if Trim(EditName.Text) = '' then
  begin
    ShowMessage('Zadejte název dodavatele!');
    Exit;
  end;
  
  if DataModule1.AddSupplier(EditName.Text, EditContact.Text, EditPhone.Text,
     EditEmail.Text, MemoAddress.Lines.Text) then
  begin
    ShowMessage('Dodavatel byl úspěšně přidán.');
    RefreshSuppliers;
    ClearInputs;
  end;
end;

procedure TFormSupplier.ButtonUpdateClick(Sender: TObject);
var
  SupplierID: Integer;
begin
  if not Assigned(FSupplierQuery) or FSupplierQuery.EOF then
  begin
    ShowMessage('Vyberte dodavatele ke změně.');
    Exit;
  end;
  
  if Trim(EditName.Text) = '' then
  begin
    ShowMessage('Zadejte název dodavatele!');
    Exit;
  end;
  
  SupplierID := FSupplierQuery.FieldByName('id').AsInteger;
  
  if DataModule1.UpdateSupplier(SupplierID, EditName.Text, EditContact.Text,
     EditPhone.Text, EditEmail.Text, MemoAddress.Lines.Text) then
  begin
    ShowMessage('Dodavatel byl aktualizován.');
    RefreshSuppliers;
  end;
end;

procedure TFormSupplier.ButtonDeleteClick(Sender: TObject);
var
  SupplierID: Integer;
begin
  if not Assigned(FSupplierQuery) or FSupplierQuery.EOF then
  begin
    ShowMessage('Vyberte dodavatele ke smazání.');
    Exit;
  end;
  
  if MessageDlg('Opravdu chcete smazat tohoto dodavatele?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SupplierID := FSupplierQuery.FieldByName('id').AsInteger;
    
    if DataModule1.DeleteSupplier(SupplierID) then
    begin
      ShowMessage('Dodavatel byl smazán.');
      RefreshSuppliers;
      ClearInputs;
    end;
  end;
end;

procedure TFormSupplier.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormSupplier.DBGridSuppliersCellClick(Column: TColumn);
begin
  if not Assigned(Column) then
    Exit;

  if Assigned(FSupplierQuery) and not FSupplierQuery.EOF then
  begin
    EditName.Text := FSupplierQuery.FieldByName('name').AsString;
    if not FSupplierQuery.FieldByName('contact_person').IsNull then
      EditContact.Text := FSupplierQuery.FieldByName('contact_person').AsString;
    if not FSupplierQuery.FieldByName('phone').IsNull then
      EditPhone.Text := FSupplierQuery.FieldByName('phone').AsString;
    if not FSupplierQuery.FieldByName('email').IsNull then
      EditEmail.Text := FSupplierQuery.FieldByName('email').AsString;
    if not FSupplierQuery.FieldByName('address').IsNull then
      MemoAddress.Lines.Text := FSupplierQuery.FieldByName('address').AsString;
  end;
end;

end.
