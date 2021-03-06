unit utable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, DBGrids,
  DBCtrls, StdCtrls, ComCtrls, ExtCtrls, IniFiles, db, sqldb, odbcconn,
  FileUtil;

type

  TTeampoints = array[1..2]of real;

  { Tfm_table_view }

  Tfm_table_view = class(TForm)
    bt_delete_team: TButton;
    bt_edit_team: TButton;
    bt_insert_game: TButton;
    bt_add_team: TButton;
    dblcb_delete_team: TDBLookupComboBox;
    dblcb_edit_team: TDBLookupComboBox;
    db_source_team1: TDataSource;
    db_source_team2: TDataSource;
    db_source_teams: TDataSource;
    dblcb_team1: TDBLookupComboBox;
    dblcb_team2: TDBLookupComboBox;
    ed_edit_teamname: TEdit;
    ed_add_teamname: TEdit;
    ed_search: TEdit;
    ed_points_team1: TEdit;
    ed_points_team2: TEdit;
    gb_delete_team: TGroupBox;
    gb_edit_team: TGroupBox;
    gb_team: TGroupBox;
    gb_points: TGroupBox;
    gb_add_team: TGroupBox;
    search_icon: TImage;
    lb_sport: TLabel;
    Sportimage: TImage;
    lb_add_teamname: TLabel;
    lb_edit_old_teamname: TLabel;
    lb_edit_new_teamname: TLabel;
    lb_search: TLabel;
    lb_delete_teamname: TLabel;
    lb_vs: TLabel;
    menu_german: TMenuItem;
    menu_english: TMenuItem;
    db_source_table: TDataSource;
    dbgrid: TDBGrid;
    menu_export: TMenuItem;
    menu_option: TMenuItem;
    menu_close: TMenuItem;
    menu_language: TMenuItem;
    menu_back: TMenuItem;
    menu_main: TMainMenu;
    db_query_table: TSQLQuery;
    db_query_teams: TSQLQuery;
    pc_controlles: TPageControl;
    sd_export: TSaveDialog;
    db_query_team1: TSQLQuery;
    db_query_team2: TSQLQuery;
    db_query_change: TSQLQuery;
    tab1: TTabSheet;
    tab2: TTabSheet;
    procedure bt_add_teamClick(Sender: TObject);
    procedure bt_delete_teamClick(Sender: TObject);
    procedure bt_edit_teamClick(Sender: TObject);
    procedure bt_insert_gameClick(Sender: TObject);
    procedure dbgridTitleClick(Column: TColumn);
    procedure dblcb_delete_teamClick(Sender: TObject);
    procedure dblcb_edit_teamClick(Sender: TObject);
    procedure dblcb_team1Click(Sender: TObject);
    procedure dblcb_team1Exit(Sender: TObject);
    procedure dblcb_team1KeyPress(Sender: TObject; var Key: char);
    procedure dblcb_team2Click(Sender: TObject);
    procedure dblcb_team2Exit(Sender: TObject);
    procedure ed_edit_teamnameKeyPress(Sender: TObject; var Key: char);
    procedure ed_points_team1KeyPress(Sender: TObject; var Key: char);
    procedure ed_points_team2KeyPress(Sender: TObject; var Key: char);
    procedure ed_searchChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure menu_backClick(Sender: TObject);
    procedure menu_closeClick(Sender: TObject);
    procedure menu_englishClick(Sender: TObject);
    procedure menu_exportClick(Sender: TObject);
    procedure menu_germanClick(Sender: TObject);
  private
    procedure FixGridColWidth;
    procedure SqlExecute(statement:AnsiString;var connector:TODBCConnection;var transaction:TSQLTransaction);
    procedure FormatGUI;
    procedure TableSelection;
    procedure ConnectDatabase;
    procedure TeamSelection;
    procedure ExportTable(const grid:TDBGrid;const path:string);
    function Pointdifference(const points_team1,points_team2,sport:string):TTeampoints;
    procedure ReconnectDatabase(const active_table_index:integer);
    procedure LoadImages;
  public
  protected
    table_sorted:boolean; //Da die Komponente TDBGrid nicht alle Funktionen wie TStringGrid
                          //benötigen wir eine globale variable zur Sortierung der Tabelle
                          //um den wechsel zwischen ASC und DESC zu realisieren
  end;

var
  fm_table_view: Tfm_table_view;

implementation

uses umain;

//preprocessing commands werden vor dem Aufruf des Compilers ausgeführt
{$R *.lfm}
{$macro on}
{$define ACTIVE_TABLE := fm_tournament.dblcb_tables.Items[fm_tournament.dblcb_tables.ItemIndex]}
{$define LOAD_TRANSLATION := fm_tournament.language.ReadString}

{ Tfm_table_view }

procedure Tfm_table_view.FormActivate(Sender: TObject);
begin
  table_sorted:=false;

  ConnectDatabase;
  TableSelection;
  TeamSelection;
  FormatGUI;
  LoadImages;
  FixGridColWidth;
end;

procedure Tfm_table_view.ed_searchChange(Sender: TObject);
begin
  //Suchleiste nach Namen
  fm_tournament.SqlQuery('SELECT * FROM ' + ACTIVE_TABLE + ' WHERE Teamname like '+#39+'%'+ ed_search.text + '%' +#39+ ';', db_query_table);
  FixGridColWidth;
end;

procedure Tfm_table_view.dblcb_team1Exit(Sender: TObject);
var
  lastteam:string;
  i,index:integer;
begin
  //Sorgt dafür, dass ein Team sobald es ausgewählt wurde, nicht in der anderen
  //combobox ausgewählt werden kann

  lastteam:='';
  index:=0;

  //das aktuelle Team wird sich gemerkt
  if(dblcb_team2.ItemIndex<>-1)then lastteam:=dblcb_team2.items[dblcb_team2.ItemIndex];

  //ändern des SQL Befehls um ausgewähltes Team zu enfernen
  if(dblcb_team1.ItemIndex<>-1)then
  begin
    fm_tournament.SqlQuery('SELECT Teamname FROM ' + ACTIVE_TABLE + ' WHERE NOT Teamname = ' + #39 + dblcb_team1.Text + #39 + ';', db_query_team2);
    dblcb_team2.ListSource:=db_source_team2;
    dblcb_team2.KeyField:='Teamname';
  end;

  //finden des neuen Index für das ausgewähte Team
  for i:=0 to dblcb_team2.Items.Count-1 do
  begin
    if(dblcb_team2.Items[i]=lastteam)then index:=i;
  end;

  dblcb_team2.ItemIndex:=index;
end;

procedure Tfm_table_view.dblcb_team1KeyPress(Sender: TObject; var Key: char);
begin
  key:=#0;
end;

procedure Tfm_table_view.dblcb_team2Click(Sender: TObject);
begin
  dblcb_team2.DroppedDown:=true;
end;

procedure Tfm_table_view.bt_insert_gameClick(Sender: TObject);
var temp:AnsiString;
    temp_index:integer; 
    Teampoints:TTeampoints;
begin
  //sorgt für das Eintragen eines Spiels

  //check ob alle Felder gefühlt sind
  if(dblcb_team1.text='')or(dblcb_team2.text='')or(ed_points_team1.text='')or(ed_points_team2.text='')then
  begin
    ShowMessage(LOAD_TRANSLATION('Info','inf_fields_empty',''));
  end
  else
  begin
    Teampoints:=Pointdifference(ed_points_team1.text,ed_points_team2.text,ACTIVE_TABLE);
    DecimalSeparator:='.';

    //Da die Verbindung währen dem Ändern der Einträge unterbrochen wird muss die
    //Referenz, welche Tabelle ausgewählt ist, zwischengespeichert werden
    temp_index:=fm_tournament.dblcb_tables.ItemIndex;
    temp:=ACTIVE_TABLE;

    if((StrtoInt(ed_points_team1.text))=(StrtoInt(ed_points_team2.text)))then
    begin
      //gleichstand

      //Ranglistenpunktzahl eintragen
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[1]) + ' WHERE Teamname=' + #39 + dblcb_team1.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[2]) + ' WHERE Teamname=' + #39 + dblcb_team2.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
    end
    else if((StrtoInt(ed_points_team1.text))<(StrtoInt(ed_points_team2.text)))then
    begin
      //Siege und Niederlagen um 1 erhöhen
      SqlExecute('UPDATE ' + temp + ' SET Siege=Siege+1 WHERE Teamname=' + #39 + dblcb_team2.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
      SqlExecute('UPDATE ' + temp + ' SET Niederlagen=Niederlagen+1 WHERE Teamname=' + #39 + dblcb_team1.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);

      //Ranglistenpunktzahl eintragen
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[1]) + ' WHERE Teamname=' + #39 + dblcb_team1.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[2]) + ' WHERE Teamname=' + #39 + dblcb_team2.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
    end
    else
    begin
      //Siege und Niederlagen um 1 erhöhen
      SqlExecute('UPDATE ' + temp + ' SET Siege=Siege+1 WHERE Teamname=' + #39 + dblcb_team1.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
      SqlExecute('UPDATE ' + temp + ' SET Niederlagen=Niederlagen+1 WHERE Teamname=' + #39 + dblcb_team2.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);

      //Ranglistenpunkte eintragen
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[1]) + ' WHERE Teamname=' + #39 + dblcb_team1.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
      SqlExecute('UPDATE ' + temp + ' SET Punktzahl=Punktzahl+' + Floattostr(Teampoints[2]) + ' WHERE Teamname=' + #39 + dblcb_team2.text + #39 + ';',fm_tournament.db_connector,fm_tournament.db_transaction);
    end;

    //Da beim Hochladen der Information der Datenstrom in die andere Richtung geht muss nach der Änderung die Verbindung neu Aktiviert werden
    ReconnectDatabase(temp_index);
  end;

  //leeren der Felder
  dblcb_team1.ListFieldIndex:=-1;
  dblcb_team2.ListFieldIndex:=-1;
  ed_points_team1.Text:=''; 
  ed_points_team2.Text:='';
end;

procedure Tfm_table_view.bt_edit_teamClick(Sender: TObject);
var temp_index:integer;
    temp:string;
begin
  //Änderung des Namens eines Teams

  //zwischenspeichern der Referenz
  temp:=ACTIVE_TABLE;
  temp_index:=fm_tournament.dblcb_tables.ItemIndex;

  //Ändern des Namens
  if (ed_edit_teamname.text<>'')then
  begin
    SqlExecute('UPDATE '+temp+' SET Teamname='+#39+ed_edit_teamname.text+#39+' WHERE Teamname='+#39+dblcb_edit_team.Text+#39+';',fm_tournament.db_connector,fm_tournament.db_transaction);
  end;

  ReconnectDatabase(temp_index);

  //Zurücksetzten der Felder
  dblcb_edit_team.ListFieldIndex:=-1;
  ed_edit_teamname.Text:='';
end;

procedure Tfm_table_view.bt_delete_teamClick(Sender: TObject);
var temp_index:integer;
    temp:string;
begin
  //Löschen eines Teams

  //zwischenspeichern der Referenz
  temp:=ACTIVE_TABLE;
  temp_index:=fm_tournament.dblcb_tables.ItemIndex;

  //löschen des Eintrages
  if(dblcb_delete_team.text<>'')then
  begin
    SqlExecute('DELETE FROM '+temp+' WHERE Teamname='+#39+dblcb_delete_team.text+#39+';',fm_tournament.db_connector,fm_tournament.db_transaction);
  end;

  ReconnectDatabase(temp_index);

  //Zurücksetzten der Felder
  dblcb_edit_team.ListFieldIndex:=-1;
  dblcb_delete_team.ListFieldIndex:=-1;
end;

procedure Tfm_table_view.bt_add_teamClick(Sender: TObject);
var temp_index:integer;
    temp:string;
begin
  //Hinzufügen eines Teams mit genullten Werten

  //zwischenspeichern der Referenz
  temp:=ACTIVE_TABLE;
  temp_index:=fm_tournament.dblcb_tables.ItemIndex;

  //Hinzufügend es Teams
  if(ed_add_teamname.text<>'')then
  begin
    SqlExecute('INSERT INTO '+temp+' (Teamname,Punktzahl,Siege,Niederlagen) VALUES('+#39+ed_add_teamname.text+#39+',0,0,0);',fm_tournament.db_connector,fm_tournament.db_transaction);
  end;

  ReconnectDatabase(temp_index);

  //Zurücksetzten der Felder
  dblcb_edit_team.ListFieldIndex:=-1;
  ed_add_teamname.Text:='';
end;

procedure Tfm_table_view.dbgridTitleClick(Column: TColumn);
begin
  //Sortieren der Tabelle nach dem Attribut auf welches geclickt wird

  //wenn die Tabelle bereits nach dem selben Attribut sortiert wurde wird sie aufsteigend sortiert
  if(table_sorted) then
  begin
    fm_tournament.SqlQuery('SELECT * FROM '+ACTIVE_TABLE+' ORDER BY '+Column.FieldName+' ASC;', db_query_table);
    table_sorted:=false;
  end
  else
  begin
    //wenn die Tabelle noch nicht nach dem selben Attribut sortiert wurde wird sie absteigend sortiert
    fm_tournament.SqlQuery('SELECT * FROM '+ACTIVE_TABLE+' ORDER BY '+Column.FieldName+' DESC;', db_query_table);
    table_sorted:=true;
  end;
  FixGridColWidth;
end;

procedure Tfm_table_view.dblcb_delete_teamClick(Sender: TObject);
begin
  dblcb_delete_team.DroppedDown:=true;
end;

procedure Tfm_table_view.dblcb_edit_teamClick(Sender: TObject);
begin
  dblcb_edit_team.DroppedDown:=true;
end;

procedure Tfm_table_view.dblcb_team1Click(Sender: TObject);
begin
  dblcb_team1.DroppedDown:=true;
end;

procedure Tfm_table_view.dblcb_team2Exit(Sender: TObject);
var
  lastteam:string;
  i,index:integer;
begin
  //Sorgt dafür, dass ein Team sobald es ausgewählt wurde, nicht in der anderen
  //combobox ausgewählt werden kann

  lastteam:='';
  index:=0;

  //das aktuelle Team wird sich gemerkt
  if(dblcb_team1.ItemIndex<>-1) then lastteam:=dblcb_team1.items[dblcb_team1.ItemIndex];

  //ändern des SQL Befehls um ausgewähltes Team zu enfernen
  if(dblcb_team2.ItemIndex<>-1)then
  begin
    fm_tournament.SqlQuery('SELECT Teamname FROM ' + ACTIVE_TABLE + ' WHERE NOT Teamname = ' + #39 + dblcb_team2.Text + #39 + ';', db_query_team1);
    dblcb_team1.ListSource:=db_source_team1;
    dblcb_team1.KeyField:='Teamname';
  end;

  //finden des neuen Index für das ausgewähte Team
  for i:=0 to dblcb_team1.Items.Count-1 do
  begin
    if(dblcb_team1.Items[i]=lastteam)then index:=i;
  end;
  dblcb_team1.ItemIndex:=index;
end;

procedure Tfm_table_view.ed_edit_teamnameKeyPress(Sender: TObject; var Key: char
  );
begin
  //Limitierung der Länge des eingegebenen STrings
  if((Length(ed_edit_teamname.Text)>35) and (key<>#8))then key:=#0;

  //Nur Buchstaben, Zahlen, Punkte, und Backspace ist erlaubt
  if(not(key IN [#8,#32,#46,#48..#57,#65..#90,#97..#122]))then key:=#0;
end;

procedure Tfm_table_view.ed_points_team1KeyPress(Sender: TObject; var Key: char
  );
begin
  if ((Length(ed_points_team1.text)>3) and (key<>#8))then key:=#0;
  if not(key IN ['0'..'9',#8])then key:=#0;
end;

procedure Tfm_table_view.ed_points_team2KeyPress(Sender: TObject; var Key: char
  );
begin
  //Limitierung der Größe der eingegebenen Punkte
  if ((Length(ed_points_team2.text)>3) and (key<>#8))then key:=#0;

  //bur Zahlen und Backspace ist erlaubt
  if not(key IN ['0'..'9',#8])then key:=#0;
end;

procedure Tfm_table_view.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  fm_tournament.close;
end;

procedure Tfm_table_view.FormCreate(Sender: TObject);
begin
  //Formatierung des Formulars
  fm_table_view.BorderIcons:=[biSystemMenu];
  fm_table_view.Top:=50;
  fm_table_view.Left:=50;
  fm_table_view.dbgrid.Align:=alNone;
  fm_table_view.Constraints.MinHeight:=576;
  fm_table_view.Constraints.MaxHeight:=576;
  fm_table_view.Constraints.MinWidth:=910;
  fm_table_view.Constraints.MaxWidth:=910;
  pc_controlles.TabIndex:=0;
end;

procedure Tfm_table_view.menu_backClick(Sender: TObject);
begin
  fm_tournament.Enabled:=true;
  fm_table_view.hide;
end;

procedure Tfm_table_view.menu_closeClick(Sender: TObject);
begin
  fm_table_view.close;
  fm_tournament.close;
end;

procedure Tfm_table_view.menu_englishClick(Sender: TObject);
begin
  //Sprachauswahl wird realisiert
  fm_tournament.AssignLanguageFile('data\englisch.ini');
  FormatGUI;
end;

procedure Tfm_table_view.menu_exportClick(Sender: TObject);
begin
  if (sd_export.Execute) then
  begin
    try
      ExportTable(dbgrid, sd_export.FileName+'.csv');
    except
      on e: Exception do
      ShowMessage(LOAD_TRANSLATION('Info','inf_save_fail',''));
    end;
    ShowMessage(LOAD_TRANSLATION('Info','inf_save_success',''));
  end;
end;

procedure Tfm_table_view.menu_germanClick(Sender: TObject);
begin      
  //Sprachauswahl wird realisiert
  fm_tournament.AssignLanguageFile('data\deutsch.ini');  
  FormatGUI;
end;

procedure Tfm_table_view.FixGridColWidth;
begin
  //passt die Breiten der Zeilen an
  dbgrid.Columns.Items[0].Width:=245;
  dbgrid.Columns.Items[1].Width:=80;
  dbgrid.Columns.Items[2].Width:=80;
  dbgrid.Columns.Items[3].Width:=80;
end;

procedure Tfm_table_view.SqlExecute(statement: AnsiString;
  var connector: TODBCConnection; var transaction: TSQLTransaction);
begin
  //Funktion zum ausführen eines SQL Befehls
  connector.ExecuteDirect(statement);
  transaction.Commit;
end;

procedure Tfm_table_view.FormatGUI;
begin
  //Legt die Formatierungen für alle GUI-Elemente fest
  //Spracheinstellungen
  fm_table_view.Caption:=LOAD_TRANSLATION('GUI','fm_table_view','');
  menu_language.Caption:=LOAD_TRANSLATION('GUI','menu_language','');
  menu_option.Caption:=LOAD_TRANSLATION('GUI','menu_option','');
  menu_back.Caption:=LOAD_TRANSLATION('GUI','menu_back','');
  menu_close.Caption:=LOAD_TRANSLATION('GUI','menu_close','');
  menu_export.Caption:=LOAD_TRANSLATION('GUI','menu_export','');
  menu_german.Caption:=LOAD_TRANSLATION('GUI','menu_german','');
  menu_english.Caption:=LOAD_TRANSLATION('GUI','menu_english','');
  lb_vs.Caption:=LOAD_TRANSLATION('GUI', 'lb_vs','');
  gb_team.Caption:=LOAD_TRANSLATION('GUI','gb_team','');
  gb_points.Caption:=LOAD_TRANSLATION('GUI','gb_points','');
  lb_search.Caption:=LOAD_TRANSLATION('GUI','lb_search','');
  tab1.Caption:=LOAD_TRANSLATION('GUI','tab1','');
  tab2.Caption:=LOAD_TRANSLATION('GUI','tab2','');
  bt_insert_game.Caption:=LOAD_TRANSLATION('GUI','bt_insert_game','');
  lb_add_teamname.Caption:=LOAD_TRANSLATION('GUI','lb_add_teamname','');
  gb_add_team.Caption:=LOAD_TRANSLATION('GUI','gb_add_team','');
  bt_add_team.Caption:=LOAD_TRANSLATION('GUI','bt_add_team','');      
  lb_delete_teamname.Caption:=LOAD_TRANSLATION('GUI','lb_delete_teamname','');
  gb_delete_team.Caption:=LOAD_TRANSLATION('GUI','gb_delete_team','');
  bt_delete_team.Caption:=LOAD_TRANSLATION('GUI','bt_delete_team','');
  lb_edit_old_teamname.Caption:=LOAD_TRANSLATION('GUI','lb_edit_old_teamname','');
  lb_edit_new_teamname.Caption:=LOAD_TRANSLATION('GUI','lb_edit_new_teamname','');
  gb_edit_team.Caption:=LOAD_TRANSLATION('GUI','gb_edit_team','');
  bt_edit_team.Caption:=LOAD_TRANSLATION('GUI','bt_edit_team','');
  lb_sport.Caption:=LOAD_TRANSLATION('GUI','lb_sport_'+ACTIVE_TABLE,'');;

  //Objektdarstellung
  //grid
  dbgrid.FastEditing:=false;
  dbgrid.Top:=146; //30 mehr als pagecontroller und Suchleiste
  dbgrid.Left:=10;
  dbgrid.Width:=500;
  dbgrid.Height:=400;
  dbgrid.ScrollBars:=ssNone;
  dbgrid.ReadOnly:=true;

  //edits
  ed_points_team1.text:='';
  ed_points_team2.text:='';
  ed_search.Text:='';
  ed_search.Top:=116;
  ed_search.Left:=lb_search.Width+lb_search.Left+50;
  ed_search.Width:=dbgrid.Width-lb_search.width-50;
  ed_edit_teamname.Text:='';
  ed_add_teamname.Text:='';

  //Labels
  lb_search.Top:=120;
  lb_search.Left:=10;
  lb_sport.Top:=32;
  lb_sport.Left:=64;

  //pagecontroller
  pc_controlles.Top:=10;
  pc_controlles.Left:=530;
  pc_controlles.Width:=370;
  pc_controlles.Height:=536;//430

  //images
  Sportimage.Top:=10;
  Sportimage.width:=96;
  search_icon.Top:=ed_search.Top;
  search_icon.Left:=ed_search.Left-search_icon.width-2;
end;

procedure Tfm_table_view.TableSelection;
begin
  //Anzeigen der ausgewählten Tabelle im grid
  fm_tournament.SqlQuery('SELECT * FROM ' + ACTIVE_TABLE + ';', db_query_table);
  fm_tournament.SqlQuery('SELECT * FROM ' + ACTIVE_TABLE + ';', db_query_change);
  dbgrid.DataSource:=db_source_table;
end;

procedure Tfm_table_view.ConnectDatabase;
begin
  //Legt die Verbindung mit der Datenbank
  //Query
  db_query_table.Transaction:=fm_tournament.db_transaction;
  db_query_table.DataBase:=fm_tournament.db_connector;
  db_query_teams.Transaction:=fm_tournament.db_transaction;
  db_query_teams.DataBase:=fm_tournament.db_connector;

  db_query_team1.Transaction:=fm_tournament.db_transaction;
  db_query_team1.DataBase:=fm_tournament.db_connector;
  db_query_team2.Transaction:=fm_tournament.db_transaction;
  db_query_team2.DataBase:=fm_tournament.db_connector;

  db_query_change.Transaction:=fm_tournament.db_transaction;
  db_query_change.DataBase:=fm_tournament.db_connector;
  db_query_change.Options:=[sqoAutoApplyUpdates,sqoAutoCommit];

  //Datasource
  db_source_table.DataSet:=db_query_table;
  db_source_teams.DataSet:=db_query_teams;
  db_source_team1.DataSet:=db_query_team1;
  db_source_team2.DataSet:=db_query_team2;

  //grid
  dbgrid.DataSource:=fm_table_view.db_source_table;

  //lookupcombobox
  dblcb_team1.ListSource:=db_source_teams;
  dblcb_team1.KeyField:='Teamname';
  dblcb_team2.ListSource:=db_source_teams;
  dblcb_team2.KeyField:='Teamname';
  dblcb_delete_team.ListSource:=db_source_teams;
  dblcb_delete_team.KeyField:='Teamname';
  dblcb_edit_team.ListSource:=db_source_teams;
  dblcb_edit_team.KeyField:='Teamname';
end;

procedure Tfm_table_view.TeamSelection;
begin
  //Lässt alle Teams anzeigen (für comboboxen)
  fm_tournament.SqlQuery('SELECT Teamname FROM ' + ACTIVE_TABLE + ';', db_query_teams);
  fm_tournament.SqlQuery('SELECT * FROM '+ ACTIVE_TABLE+ ';',db_query_team1);          
  fm_tournament.SqlQuery('SELECT * FROM '+ ACTIVE_TABLE+ ';',db_query_team2);
end;

procedure Tfm_table_view.ExportTable(const grid: TDBGrid; const path: string);
var i,j:integer;
    sl:TStringList;
begin
  //Exportieren einer Tabelle als CSV

  sl:= TStringList.Create;
  grid.DataSource.DataSet.First; //pointer wird an Begin des Datensatzes gesetz

  //Der Datensatz der Tabelle wird reihenweise in die Stringlist gespeichert
  for i:= 1 to  grid.DataSource.DataSet.RecordCount do
  begin
    sl.Add('');
    grid.DataSource.DataSet.RecNo := i;
    for j := 0 to grid.DataSource.DataSet.Fields.Count - 1 do
      sl[SL.Count - 1]:= sl[sl.Count - 1] + grid.DataSource.DataSet.Fields[j].AsString + ';';
  end;

  //Speichern der Stringlist
  sl.SaveToFile(path);
  sl.Free;
end;

function Tfm_table_view.Pointdifference(const points_team1, points_team2,
  sport: string): TTeampoints;
var
  difference:integer;
  Teampoints:TTeampoints;
begin
  //Berechnet den Punkteunterschied für die verschiedenen Sportarten

  if(sport='basketballrangliste')then
  begin
    //sport ist die aktuell ausgewählte Tabelle in der ersten Form
    //Gibt die Ranglistenpunkte anhand der Korbdifferenz(Punktedifferenz) eine Basketballspiels aus
    difference:=StrtoInt(points_team1)-StrtoInt(points_team2);
    if (difference=0)then
    begin
      Teampoints[1]:=500;
      Teampoints[2]:=500;
    end
    else if(difference>0)then
    //Team 1 Gewinnt
    begin
      if(difference<10)then
      begin
        Teampoints[1]:=600;
        Teampoints[2]:=400;
      end
      else if(difference<20)then
      begin
        Teampoints[2]:=700;
        Teampoints[1]:=300;
      end
      else Teampoints[1]:=800;Teampoints[2]:=200;
    end
    else if(difference<0)then
    //Team 2 Gewinnt
    begin
      if(difference>-10)then
      begin
        Teampoints[2]:=600;
        Teampoints[1]:=400;
      end
      else if(difference>-20)then
      begin
        Teampoints[2]:=700;
        Teampoints[1]:=300;
      end
      else Teampoints[2]:=800;Teampoints[1]:=200;
    end;
    Result:=Teampoints;
  end
  else if(sport='fussballrangliste')then
  begin
    //Gibt die Ranglistenpunkte anhand der Tore aus
    difference:=StrtoInt(points_team1)-StrtoInt(points_team2);
    if (difference=0)then
    begin
      Teampoints[1]:=0.5;
      Teampoints[2]:=0.5;
    end
    else if(difference>0)then
    //Team 1 Gewinnt
    begin
      Teampoints[1]:=1;
      Teampoints[2]:=0;
    end
    else if(difference<0)then
    //Team 2 Gewinnt
    begin
      Teampoints[2]:=1;
      Teampoints[1]:=0;
    end;
    Result:=Teampoints;
  end;
end;

procedure Tfm_table_view.ReconnectDatabase(const active_table_index: integer);
begin
  //Stellt die Verbindung zur Datenbank nach Änderungen wieder her
  fm_tournament.db_transaction.Active:=true;
  fm_tournament.db_query_start.Active:=true;
  fm_tournament.dblcb_tables.ItemIndex:=active_table_index;
  db_query_table.Active:=true;
  db_query_change.Active:=true;
  db_query_team1.Active:=true;
  db_query_team2.Active:=true;
  db_query_teams.Active:=true; 
  FixGridColWidth;
end;

procedure Tfm_table_view.LoadImages;
begin
  //dynamisches Laden der Bilder passend zur Sportart
   if(ACTIVE_TABLE='basketballrangliste')then
  begin
    Sportimage.Picture.LoadFromFile('data\basketball.png');
  end
  else if(ACTIVE_TABLE='fussballrangliste')then
  begin
    Sportimage.Picture.LoadFromFile('data\soccer.png');
  end;
  Sportimage.Left:=round((fm_table_view.Width/2)-(Sportimage.width/2));

  //Bild vor der Suchleiste
  search_icon.Picture.LoadFromFile('data\search.png');
end;

end.

