# 📝 Changelog - Skladová Evidence

Historie verzí a změn.

---

## [2.0 PRO] - 2026-03-08

### 🎉 Velká aktualizace - Všechna vylepšení implementována!

### ➕ Přidáno

#### 🗄️ Databáze
- **Audit log tabulka** - sledování všech změn v databázi
- **Sloupec `min_quantity`** - minimální množství pro varování
- **Sloupec `updated_at`** - timestamp poslední aktualizace
- **Automatický upgrade existujících databází** - ALTER TABLE při startu

#### 💾 Export/Import
- **Export do CSV** - export všech položek do CSV souboru (UTF-8)
- **Import z CSV** - hromadný import s ochranou proti duplicitám
- **Automatické časové značky** v názvech souborů

#### 🔒 Zálohovací systém
- **Backup databáze** - kopie SQLite souboru na vybrané místo
- **Bezpečné odpojení/připojení** během zálohy
- **Časové razítko** v názvu backup souboru

#### 📊 Statistiky
- **Celková hodnota skladu** - suma všech položek × ceny
- **Průměrná cena položky**
- **Nejdražší položka** - název a cena
- **Počet položek s nízkým stavem**
- **Statistické dialogy** - přehledné zobrazení dat

#### 📜 Auditní log
- **Automatické logování** všech CRUD operací
- **Detailní tracking změn** - field_name, old_value, new_value
- **Historie zobrazení** - posledních 20 záznamů
- **Časové razítko** každé operace

#### ⚠️ Varování
- **Automatické varování při spuštění** - upozornění na nízký stav
- **Barevné zvýraznění** v gridu (červená = nízký stav)
- **Status bar indikace** - počet položek pod minimem
- **Nastavitelná hranice** pro každou položku zvlášť

#### 🔍 Pokročilé filtrování
- **Filtr podle kategorie** - ComboBox s okamžitým filtrováním
- **Kombinace s live search** - filtrování + vyhledávání současně

#### ✅ Validace
- **Kontrola duplicitních kódů** - před přidáním i úpravou
- **Lepší chybové hlášky** - uživatelsky přívětivé texty
- **Validace číselných polí** s ošetřením chyb

#### 🎨 UI/UX vylepšení
- **Modernizovaný layout** - 1100×650 px
- **Barevné kódování tlačítek**:
  - 🟢 Zelená - Export
  - 🔵 Modrá - Import
  - 🟣 Fialová - Záloha
  - 🔷 Tyrkysová - Statistiky
  - 🔴 Červená - Mazání
- **Rozšířený status bar** - 3 panely s informacemi
- **Lepší barvy formuláře** - světle šedé pozadí, bílý panel
- **Nový nadpis** - "Skladová Evidence PRO" s tmavě modrou barvou
- **Více prostoru** - širší okno pro více informací

#### 🆕 Nové komponenty
- `Label7` + `EditMinQuantity` - pole pro min. množství
- `Label8` + `ComboFilterCategory` - filtr kategorií
- `ButtonExport` - tlačítko pro export CSV
- `ButtonImport` - tlačítko pro import CSV
- `ButtonBackup` - tlačítko pro zálohu DB
- `ButtonStatistics` - tlačítko pro statistiky
- `ButtonAuditLog` - tlačítko pro audit log

### 🔧 Změněno

#### DatabaseModule.pas
- **Rozšířený interface** - 18 public metod (původně 6)
- **AddItem** - přidán parametr `AMinQuantity`, kontrola duplicit, logování
- **UpdateItem** - přidán parametr `AMinQuantity`, detailní tracking změn
- **DeleteItem** - přidáno logování smazání
- **CreateTables** - vytváří 2 tabulky místo 1, přidány sloupce
- **InsertSampleData** - více ukázkových dat (8 položek místo 5)

#### MainForm.pas
- **Rozšířený interface** - 6 nových event handlerů
- **FormCreate** - inicializace filtru kategorií, aktualizovaná konfigurace gridu
- **FormShow** - přidáno volání `CheckLowStock()`
- **UpdateStatusBar** - zobrazuje 3 informace místo 2
- **ButtonAddClick/UpdateClick** - přidán `EditMinQuantity` parametr, `CheckLowStock()`
- **Nové metody**:
  - `ComboFilterCategoryChange()` - filtrování podle kategorie
  - `ButtonExportClick()` - export CSV
  - `ButtonImportClick()` - import CSV
  - `ButtonBackupClick()` - záloha databáze
  - `ButtonStatisticsClick()` - zobrazení statistik
  - `ButtonAuditLogClick()` - zobrazení audit logu
  - `CheckLowStock()` - kontrola nízkého stavu
  - `ShowStatistics()` - formátování statistik
  - `DBGrid1DrawColumnCell()` - barevné zvýraznění

#### MainForm.dfm
- **ClientHeight** - 650 (původně 621)
- **ClientWidth** - 1100 (původně 984)
- **Caption** - "PRO" verze
- **Color** - `15132390` (světle šedá, původně `clBtnFace`)
- **PanelTop.Height** - 280 (původně 249)
- **Přidáno 7 nových komponent** - viz výše
- **DBGrid** - přidán `OnDrawColumnCell` event
- **StatusBar** - třetí panel širší (200px místo 50px)

### 📚 Dokumentace

#### README.md
- **Kompletní přepis** - nová struktura a obsah
- **Přidány sekce**:
  - Pokročilé funkce (4 hlavní oblasti)
  - Barevné kódování
  - Bezpečnost
  - Databázová struktura
  - Budoucí vylepšení
  - Poznámky
- **Rozšířené příklady** - CSV formát, použití funkcí
- **Lepší formátování** - emoji, tabulky, code bloky

#### FEATURES.md (NOVÝ)
- **Detailní popis všech funkcí**
- **Technické detaily implementace**
- **Code snippets** - ukázky kódu
- **Příklady výstupů** - jak vypadají výsledky
- **Statistiky kódu** - počet řádků, metod
- **Performance metriky**
- **Plány budoucího rozvoje**

#### CHANGELOG.md (TENTO SOUBOR)
- **Historie změn** - dokumentace vývoje

### 🐛 Opraveno
- **Žádné známé bugy** - čistý projekt bez chyb
- **Error handling** - try-except bloky všude
- **Null safety** - kontrola IsNull tam, kde je potřeba

### 🔒 Bezpečnost
- **SQL Injection ochrana** - parametrizované dotazy všude
- **Validace vstupů** - kontrola všech polí před uložením
- **Potvrzovací dialogy** - před kritickými operacemi

---

## [1.0] - 2026-03-07

### 🎉 Počáteční verze

#### ✅ Základní funkce
- CRUD operace (Create, Read, Update, Delete)
- Živé vyhledávání podle názvu nebo kódu
- SQLite databáze s FireDAC
- DataGrid zobrazení
- Status bar s počtem položek a celkovou hodnotou
- Ukázková data při prvním spuštění
- 6 kategorií položek
- Základní validace vstupů

#### 🗄️ Databáze
- Tabulka `items` se sloupci:
  - id, code, name, category, quantity, price, created_at

#### 🎨 UI
- Panel pro vstupní formulář (249px)
- DataGrid pro zobrazení (353px)
- Status bar (2 panely)
- 8 základních komponent
- Rozlišení: 984×621

#### 📚 Dokumentace
- README.md s instalačními pokyny
- Popis základních funkcí
- Struktura projektu

---

## 📊 Srovnání verzí

| Funkce | v1.0 | v2.0 PRO |
|--------|------|----------|
| CRUD operace | ✅ | ✅ |
| Vyhledávání | ✅ | ✅ |
| Filtrování | ❌ | ✅ |
| Export CSV | ❌ | ✅ |
| Import CSV | ❌ | ✅ |
| Záloha DB | ❌ | ✅ |
| Statistiky | Základní | Pokročilé |
| Audit log | ❌ | ✅ |
| Varování | ❌ | ✅ |
| Barevné zvýraznění | ❌ | ✅ |
| Validace duplicit | ❌ | ✅ |
| Min. množství | ❌ | ✅ |
| Počet komponent | 8 | 15 |
| Řádků kódu | ~400 | ~1000 |
| Metod v DatabaseModule | 6 | 18 |
| Tabulek v DB | 1 | 2 |
| StatusBar panelů | 2 | 3 |
| Dokumentačních souborů | 1 | 3 |

---

## 🔮 Plánované ve v3.0

- [ ] Grafické grafy (Chart.js nebo VCL Charts)
- [ ] Tiskové reporty (FastReport)
- [ ] Multi-user podpora s přihlášením
- [ ] REST API pro mobilní aplikace
- [ ] Sledování šarží a expiračních dat
- [ ] Email notifikace při kritickém stavu
- [ ] Inventura režim
- [ ] Skenování čárových kódů
- [ ] Dashboard s přehlednými grafy
- [ ] Export do PDF/Excel

---

**Verzování:** Semantic Versioning (MAJOR.MINOR)  
**Repository:** Portfolio-Projekty/evidence-skladu-delphi/  
**Autor:** Portfolio projekt  
**Jazyk:** Delphi/Object Pascal
