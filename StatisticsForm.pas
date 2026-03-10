unit StatisticsForm;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, 
  ExtCtrls, ComCtrls, DatabaseModule, DB, SQLDB;

type
  TFormStatistics = class(TForm)
    Panel1: TPanel;
    PaintBox1: TPaintBox;
    LabelTitle: TLabel;
    ButtonClose: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
  private
    procedure LoadStatistics;
  end;

var
  FormStatistics: TFormStatistics;

implementation

{$R *.lfm}

procedure TFormStatistics.FormCreate(Sender: TObject);
begin
  Caption := 'Statistiky skladové evidence';
  LabelTitle.Caption := 'Přehled kategorií a jejich průměrných cen';
  ButtonClose.Caption := 'Zavřít';
  
  LoadStatistics;
end;

procedure TFormStatistics.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormStatistics.PaintBox1Paint(Sender: TObject);
var
  Query: TSQLQuery;
  AvgPrice: Double;
  MaxPrice: Double;
  X, Y, BarHeight, BarWidth: Integer;
  Categories: TStringList;
  Prices: array of Integer;
  I: Integer;
begin
  Prices := nil; // Initialize managed type
  Query := TSQLQuery.Create(nil);
  Categories := TStringList.Create;
  SetLength(Prices, 0);
  MaxPrice := 0;
  
  try
    Query.DataBase := DataModule1.SQLiteConnection1;
    Query.Transaction := DataModule1.SQLTransaction1;
    Query.SQL.Text := 'SELECT category, AVG(price) as avg_price FROM items GROUP BY category ORDER BY avg_price DESC';
    Query.Open;
    
    while not Query.EOF do
    begin
      Categories.Add(Query.FieldByName('category').AsString);
      AvgPrice := Query.FieldByName('avg_price').AsFloat;
      SetLength(Prices, Length(Prices) + 1);
      Prices[High(Prices)] := Round(AvgPrice * 100);
      if AvgPrice > MaxPrice then
        MaxPrice := AvgPrice;
      Query.Next;
    end;
    Query.Close;
    
    with PaintBox1.Canvas do
    begin
      Brush.Color := clWhite;
      FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));
      
      Font.Color := clBlack;
      Pen.Color := clBlack;
      Pen.Width := 2;
      BarWidth := (PaintBox1.Width - 150) div Categories.Count;
      Y := PaintBox1.Height - 60;
      
      Line(30, 20, 30, Y);
      Line(30, Y, PaintBox1.Width - 20, Y);
      
      X := 50;
      for I := 0 to Categories.Count - 1 do
      begin
        AvgPrice := Prices[I] / 100;
        BarHeight := Round((AvgPrice / MaxPrice) * (Y - 40));
        
        Brush.Color := clBlue;
        FillRect(Rect(X, Y - BarHeight, X + BarWidth - 10, Y));
        
        Brush.Color := clWhite;
        Font.Color := clBlack;
        TextOut(X - 10, Y + 10, Categories[I]);
        TextOut(X, Y - BarHeight - 20, Format('%.0f Kč', [AvgPrice]));
        
        X := X + BarWidth;
      end;
    end;
    
  finally
    Query.Free;
    Categories.Free;
  end;
end;

procedure TFormStatistics.LoadStatistics;
var
  Query: TSQLQuery;
  Category: string;
  AvgPrice: Double;
  TotalItems: Integer;
  TotalValue: Double;
  StatsText: string;
begin
  Memo1.Clear;
  
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := DataModule1.SQLiteConnection1;
    Query.Transaction := DataModule1.SQLTransaction1;
    Query.SQL.Text := 'SELECT category, AVG(price) as avg_price, COUNT(*) as items_count, SUM(quantity) as total_qty ' +
                      'FROM items GROUP BY category ORDER BY avg_price DESC';
    Query.Open;
    
    StatsText := 'STATISTIKY KATEGORIÍ' + sLineBreak + sLineBreak;
    
    while not Query.EOF do
    begin
      Category := Query.FieldByName('category').AsString;
      AvgPrice := Query.FieldByName('avg_price').AsFloat;
      TotalItems := Query.FieldByName('items_count').AsInteger;
      
      StatsText := StatsText + Format('%s:', [Category]) + sLineBreak +
                   Format('  Průměrná cena: %.2f Kč', [AvgPrice]) + sLineBreak +
                   Format('  Počet položek: %d', [TotalItems]) + sLineBreak +
                   sLineBreak;
      
      Query.Next;
    end;
    
    Query.Close;
    Query.SQL.Text := 'SELECT COUNT(*) as total_items, SUM(quantity * price) as total_value, AVG(price) as avg_all FROM items';
    Query.Open;
    
    if not Query.IsEmpty then
    begin
      TotalItems := Query.FieldByName('total_items').AsInteger;
      TotalValue := Query.FieldByName('total_value').AsFloat;
      
      StatsText := StatsText + sLineBreak +  '=== CELKOVÉ STATISTIKY ===' + sLineBreak +
                   Format('Celkem položek: %d', [TotalItems]) + sLineBreak +
                   Format('Celková hodnota: %.2f Kč', [TotalValue]) + sLineBreak +
                   Format('Průměrná cena: %.2f Kč', [Query.FieldByName('avg_all').AsFloat]);
    end;
    
    Query.Close;
    Memo1.Text := StatsText;
    PaintBox1.Invalidate;
    
  finally
    Query.Free;
  end;
end;

end.
