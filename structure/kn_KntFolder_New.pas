unit kn_KntFolder_New;

(****** LICENSE INFORMATION **************************************************
 
 - This Source Code Form is subject to the terms of the Mozilla Public
 - License, v. 2.0. If a copy of the MPL was not distributed with this
 - file, You can obtain one at http://mozilla.org/MPL/2.0/.           
 
------------------------------------------------------------------------------
 (c) 2000-2005 Marek Jedlinski <marek@tranglos.com> (Poland)
 (c) 2007-2015 Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain) [^]

 [^]: Changes since v. 1.7.0. Fore more information, please see 'README.md'
     and 'doc/README_SourceCode.txt' in https://github.com/dpradov/keynote-nf      
   
 *****************************************************************************) 


interface

uses
   Winapi.Windows,
   Winapi.Messages,
   System.SysUtils,
   System.Classes,
   Vcl.Graphics,
   Vcl.Controls,
   Vcl.Forms,
   Vcl.Dialogs,
   Vcl.StdCtrls,
   cmpGFXComboBox,
   kn_Info,
   kn_Const
   ;


type
  TForm_NewKntFolder = class(TForm)
    Button_OK: TButton;
    Button_Cancel: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Combo_TabName: TComboBox;
    Button_Properties: TButton;
    Combo_Icons: TGFXComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button_OKClick(Sender: TObject);
    procedure Button_CancelClick(Sender: TObject);
    procedure Combo_TabNameChange(Sender: TObject);
    procedure Button_PropertiesClick(Sender: TObject);
    procedure Combo_TabNameKeyPress(Sender: TObject; var Key: Char);
    function FormHelp(Command: Word; Data: NativeInt;
      var CallHelp: Boolean): Boolean;
  private
    { Private declarations }
  public
    { Public declarations }
    OK_Click : boolean;
    TAB_CHANGEABLE : boolean;
    Initializing : boolean;
    // State : TTextControlState;
    StateChanged : boolean;

    myChrome : TChrome;
    myEditorProperties : TFolderEditorProperties;
    myTabProperties : TFolderTabProperties;
    myTreeProperties : TFolderTreeProperties;
    myTreeChrome : TChrome;
    myTreeOptions : TKntTreeOptions;

    myTabNameHistory : string;
    myHistoryCnt : integer;
    myNodeNameHistory : string;

    function Verify : boolean;
    procedure ExecuteEditProperties;
  end;

implementation

{$R *.DFM}

uses
   gf_strings,
   kn_Defaults,
   kn_global,
   kn_INI,
   kn_Chest,
   kn_Main,
   knt.App,
   knt.RS;


procedure TForm_NewKntFolder.FormCreate(Sender: TObject);
var
  i : integer;
begin
  Initializing := true;
  OK_Click := false;

  App.ApplyBiDiModeOnForm(Self);

  InitializeChrome( myChrome );
  InitializeFolderEditorProperties( myEditorProperties );
  InitializeFolderTabProperties( myTabProperties );
  InitializeChrome( myTreeChrome );
  InitializeFolderTreeProperties( myTreeProperties );
  InitializeTreeOptions( myTreeOptions );

  TAB_CHANGEABLE := true;
  StateChanged := false;
  myTabNameHistory := '';
  myHistoryCnt := DEFAULT_HISTORY_COUNT;
  myNodeNameHistory := '';

  Combo_TabName.MaxLength := TABNOTE_NAME_LENGTH;

  Combo_Icons.ImageList := Chest.IMG_Categories;
  Combo_Icons.AddItem( GetRS(sFldN01), -1 );
  for i := 0 to pred( Chest.IMG_Categories.Count ) do
    Combo_Icons.AddItem( ' - ' + inttostr( succ( i )), i );
  Combo_Icons.ItemIndex := 0;

end; function TForm_NewKntFolder.FormHelp(Command: Word; Data: NativeInt;
  var CallHelp: Boolean): Boolean;
begin
   CallHelp:= False;
   ActiveKeyNoteHelp_FormHelp(Command, Data);
end;

// FORM_CREATE

procedure TForm_NewKntFolder.FormActivate(Sender: TObject);
begin
  if ( not Initializing ) then exit;
  Initializing := false;
  if ( not TAB_CHANGEABLE ) then
  begin
    Caption := GetRS(sFldN02);
  end;

  Combo_TabName.Items.BeginUpdate;
  try
    DelimTextToStrs( Combo_TabName.Items, myTabNameHistory, HISTORY_SEPARATOR );
  finally
    Combo_TabName.Items.EndUpdate;
  end;

  // Combo_TabName.Items.Insert( 0, DEFAULT_NEW_NOTE_NAME );
  Combo_TabName.Text := myTabProperties.Name;
  Combo_Icons.ItemIndex := succ( myTabProperties.ImageIndex );

  Button_Properties.Enabled := ( Combo_TabName.Text <> '' );

  try
    Combo_TabName.SetFocus;
    Combo_TabName.SelectAll;
  except
  end;

end; // FORM_ACTIVATE

function TForm_NewKntFolder.Verify : boolean;
begin
  result := false;
  if ( trim( Combo_TabName.Text ) = '' ) then
  begin
    App.ErrorPopup( GetRS(sFldN03));
    Combo_TabName.SetFocus;
    exit;
  end;

  if ( pos( KNTLINK_SEPARATOR, Combo_TabName.Text ) > 0 ) then
  begin
    App.ErrorPopup( Format(GetRS(sFldN04),[KNTLINK_SEPARATOR]));
    Combo_TabName.SetFocus;
    exit;
  end;

  result := true;
end; // Verify

procedure TForm_NewKntFolder.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  i : integer;
begin
  if OK_Click then
  begin
    CanClose := Verify;
    if CanClose then
    begin
      myTabProperties.Name := trim( Combo_TabName.Text );
      myTabProperties.ImageIndex := pred( Combo_Icons.ItemIndex );

      myTabNameHistory := AnsiQuotedStr( Combo_TabName.Text, '"' );
      for i := 0 to pred( Combo_TabName.Items.Count ) do
      begin
        if ( i >= myHistoryCnt ) then break;
        if ( Combo_TabName.Items[i] <> Combo_TabName.Text ) then
          myTabNameHistory :=  myTabNameHistory + HISTORY_SEPARATOR + AnsiQuotedStr( Combo_TabName.Items[i], '"' );
      end;
    end;
  end;
  OK_Click := false;
end; // FORM_CLOSEQUERY

procedure TForm_NewKntFolder.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    27 : if (( shift = [] ) and ( not ( Combo_TabName.DroppedDown or Combo_Icons.DroppedDown ))) then
    begin
      key := 0;
      OK_Click := false;
      Close;
    end;
  end;
end; // FORM_KEYDOWN

procedure TForm_NewKntFolder.Button_OKClick(Sender: TObject);
begin
  OK_Click := true;
end;

procedure TForm_NewKntFolder.Button_CancelClick(Sender: TObject);
begin
  OK_Click := false;
end;

procedure TForm_NewKntFolder.Combo_TabNameChange(Sender: TObject);
begin
  // Button_Properties.Enabled := ( Combo_TabName.Text <> '' );
end;

procedure TForm_NewKntFolder.ExecuteEditProperties;
var
  Form_Defaults : TForm_Defaults;
begin
  myTabProperties.Name := trim( Combo_TabName.Text );
  myTabProperties.ImageIndex := pred( Combo_Icons.ItemIndex );

  Form_Defaults := TForm_Defaults.Create(Form_Main);
  try
    Form_Defaults.myCurrentFileName:= '';
    if assigned(ActiveFile) and (ActiveFile.FileName <> '') then
       Form_Defaults.myCurrentFileName := ActiveFile.File_Name;

    Form_Defaults.StartWithEditorTab := true;
    Form_Defaults.Action := propThisFolder;
    Form_Defaults.myEditorChrome := myChrome;
    Form_Defaults.myTabProperties := myTabProperties;
    Form_Defaults.myEditorProperties := myEditorProperties;
    Form_Defaults.myTabNameHistory := myTabNameHistory;
    Form_Defaults.myNodeNameHistory := myNodeNameHistory;
    Form_Defaults.myTreeProperties := myTreeProperties;
    Form_Defaults.myTreeChrome := myTreeChrome;

    // Form_Defaults.Defaults := false;
    if ( Form_Defaults.ShowModal = mrOK ) then begin
      myChrome := Form_Defaults.myEditorChrome;
      myTabProperties := Form_Defaults.myTabProperties;
      myEditorProperties := Form_Defaults.myEditorProperties;

      myTreeProperties := Form_Defaults.myTreeProperties;
      myTreeChrome := Form_Defaults.myTreeChrome;

      Combo_TabName.Text := myTabProperties.Name;
      Combo_Icons.ItemIndex := succ( myTabProperties.ImageIndex );
    end;
  finally
    Form_Defaults.Free;
  end;
end; // ExecuteEditProperties

procedure TForm_NewKntFolder.Button_PropertiesClick(Sender: TObject);
begin
  ExecuteEditProperties;
end;

procedure TForm_NewKntFolder.Combo_TabNameKeyPress(Sender: TObject;
  var Key: Char);
begin
  if ( Key = KNTLINK_SEPARATOR ) then
    Key := #0;
end; // Combo_TabNameKeyPress

end.
