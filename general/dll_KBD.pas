unit dll_KBD;

(****** LICENSE INFORMATION **************************************************
 
 - This Source Code Form is subject to the terms of the Mozilla Public
 - License, v. 2.0. If a copy of the MPL was not distributed with this
 - file, You can obtain one at http://mozilla.org/MPL/2.0/.           
 
------------------------------------------------------------------------------
 (c) 2000-2005 Marek Jedlinski <marek@tranglos.com> (Poland)
 (c) 2007-2024 Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain) [^]

 [^]: Changes since v. 1.7.0. Fore more information, please see 'README.md'
     and 'doc/README_SourceCode.txt' in https://github.com/dpradov/keynote-nf      
   
 *****************************************************************************)

interface

uses
   Winapi.Windows,
   Winapi.Messages,
   Winapi.ShellAPI,
   System.SysUtils,
   System.Classes,
   Vcl.Graphics,
   Vcl.Controls,
   Vcl.Forms,
   Vcl.Dialogs,
   Vcl.ComCtrls,
   Vcl.StdCtrls,
   Vcl.ExtCtrls,
   Vcl.Menus,
   RxCombos,
   gf_strings,
   dll_HotKey,
   dll_Keyboard;

type
  TForm_KBD = class(TForm)
    Btn_OK: TButton;
    Btn_Cancel: TButton;
    GroupBox1: TGroupBox;
    LB_Cmd: TLabel;
    LB_Shortcut: TLabel;
    Label4: TLabel;
    List_Commands: TListBox;
    Btn_Assign: TButton;
    Btn_Remove: TButton;
    Btn_ResetAll: TButton;
    Btn_List: TButton;
    lblAssig: TLabel;
    GroupBox2: TGroupBox;
    LB_CurrentlyAssignedTo: TLabel;
    LB_CmdHint: TLabel;
    Edit_Current: TEdit;

    Menu_Items: TPopupMenu;
    N1: TMenuItem;
    MMListUnassigned: TMenuItem;
    Btn_Help: TButton;
    Edit_Filter: TEdit;
    Label1: TLabel;
    RBShowMainMenu: TRadioButton;
    RBShowTreeMenu: TRadioButton;
    MMConsiderDescriptionOnFilter: TMenuItem;
    RBShowMacros: TRadioButton;
    RBShowPlugins: TRadioButton;
    RBShowTemplates: TRadioButton;
    RBShowStyles: TRadioButton;
    RBShowFonts: TRadioButton;
    Combo_Font: TFontComboBox;
    Pnl: TPanel;
    Edit1: TEdit;
    procedure MMConsiderDescriptionOnFilterClick(Sender: TObject);
    procedure RBShowCommandsCategoryClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Edit_FilterExit(Sender: TObject);
    procedure Edit_FilterKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure List_CommandsClick(Sender: TObject);
    procedure Edit_HotKeyKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Btn_RemoveClick(Sender: TObject);
    procedure Btn_AssignClick(Sender: TObject);
    procedure Btn_ListClick(Sender: TObject);
    procedure Btn_ResetAllClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Edit_HotKeyEnter(Sender: TObject);
    procedure Edit_HotKeyExit(Sender: TObject);
    procedure MMListUnassignedClick(Sender: TObject);
    procedure Btn_HelpClick(Sender: TObject);
    procedure Combo_FontChange(Sender: TObject);
    procedure MessageShortcutInvalid (aShortcut : TShortcut);
    procedure CleanEdit_Hotkey;
  private
    { Private declarations }
  public
    { Public declarations }

    myKeyList : TList;
    OtherCommandsList: TList;

    KeyNoteActivationHotkey : TShortCut;
    myKBD_FN : string;

    HaveNewKey : boolean;
    UserShortcut : TShortCut;

    IsModified : boolean;

    Edit_HotKey: TKNTHotKey;

    procedure ApplySort;
    procedure DisplayCommands;
    procedure ShowCommandInfo;

    function GetSelectedItem : TKeyCommandItem;
    function GetItemByShortcut( SelItem : TKeyCommandItem; const aShortcut : TShortcut;
             searchInAllCategories: boolean=false ) : TKeyCommandItem;
    function IsValidShortcut( const aItem : TKeyCommandItem; const aShortcut : TShortcut ) : boolean;

    procedure EnableAccelerators( const DoEnable : boolean );

  end;



implementation
uses
{$IFDEF EMBED_UTILS_DLL}
  kn_Global,
{$ENDIF}
  gf_miscvcl,
  knt.App;

{$R *.DFM}

const
  _HELP_PROFILE_FOLDER   = 'Profiles\Help\';
  _KNT_HELP_FILE = 'Help\KeyNoteNF_Help.knt';
  _KNT_HELP_FILE_NOTE_ID = 8;
  _KNT_HELP_FILE_NOTE_WHATSNEW_ID = 14;
  _KNT_LAUNCHER = 'kntLauncher.exe';
  _KNT_HELP_TITLE = 'KeyNote NF Topics';

{$IFDEF EMBED_UTILS_DLL}
{$ELSE}
function ActiveKeyNoteHelp(Folder, Node, Marker: integer): Boolean;
var
  Args: string;
  sMarker: string;
  HelpINI_FN, Help_FN: string;
  ExeFilePath, Launcher_FN: string;
begin

   try
      ExeFilePath:= ExtractFilePath(Application.ExeName);
      Help_FN := ExeFilePath + _KNT_HELP_FILE;
      HelpINI_FN := ExeFilePath + _HELP_PROFILE_FOLDER + 'keynote.ini';
      Launcher_FN := ExeFilePath + _KNT_LAUNCHER;

      //  file:///*FolderID|NodeID|CursorPosition|SelectionLength|MarkID  -> Ex: file:///*3|16|5|0|1
      {if Marker > 0 then
         sMarker:= '|0|0|' + Marker.ToString;
      }
      sMarker:= '';

      Args:= Format('"%s" "%s" -jmp"file:///*%d|%d%s" -title"%s"', [Help_FN, HelpINI_FN, Folder, Node, sMarker, _KNT_HELP_TITLE]);
      ShellExecute( 0, 'open', PChar(Launcher_FN), PChar(Args), nil, SW_HIDE );
   except
   end;
end;
{$ENDIF}


function IsValidShortcut( const AShortcut : TShortCut ) : boolean;
begin
  result := true;
end; // IsValidShortcut

procedure TForm_KBD.FormCreate(Sender: TObject);
begin
  myKeyList := nil;
  HaveNewKey := false;
  UserShortcut := 0;
  myKBD_FN := '';
  Edit_HotKey := TKNTHotKey.Create( self );
  Edit_HotKey.Parent := Pnl;
  Edit_HotKey.Left := Edit1.Left;
  Edit_HotKey.Top :=  Edit1.Top;
  Edit_HotKey.Width := Edit1.Width;
  Edit_HotKey.InvalidKeys := [hcNone];
  Edit_HotKey.Modifiers := [hkCtrl];
  Edit_HotKey.OnEnter := Edit_HotKeyEnter;
  Edit_HotKey.OnExit := Edit_HotKeyExit;
  Edit_HotKey.OnKeyUp := Edit_HotKeyKeyUp;
  Edit_HotKey.Visible := true;

  Edit_Hotkey.HotKey := 0;
  LB_CurrentlyAssignedTo.Font.Style := [fsBold];
end;

procedure TForm_KBD.ApplySort;
begin
    myKeyList.Sort( CompareKeyItemsByPath )
end;

// Create

procedure TForm_KBD.FormActivate(Sender: TObject);
begin
  OnActivate := nil;

  self.Constraints.MinHeight := self.Height;

  if assigned( myKeyList ) then begin
    ApplySort;
    DisplayCommands;
    try
      List_Commands.SetFocus;
    except
    end;
  end
  else
    postmessage( self.handle, WM_CLOSE, 0, 0 );

  IsModified := false;

end; // Activate


procedure TForm_KBD.DisplayCommands ();
var
  i, cnt : integer;
  item : TKeyCommandItem;
  CategorySelected: TCommandCategory;
  itemStr: string;
  Filter: string;
begin
  cnt := myKeyList.Count;
  Filter:= Edit_Filter.Text;

  CleanEdit_Hotkey;

  if RBShowMainMenu.Checked then
     CategorySelected:= ccMenuMain
  else
  if RBShowTreeMenu.Checked then
     CategorySelected:= ccMenuTree
  else
  if RBShowMacros.Checked then
     CategorySelected:= ccMacro
  else
  if RBShowPlugins.Checked then
     CategorySelected:= ccPlugin
  else
  if RBShowTemplates.Checked then
     CategorySelected:= ccTemplate
  else
  if RBShowStyles.Checked then
     CategorySelected:= ccStyle
  else
  if RBShowFonts.Checked then
     CategorySelected:= ccFont;


  Combo_Font.Visible:= (CategorySelected = ccFont);

  List_Commands.Items.BeginUpdate;
  try
    List_Commands.Items.Clear;

    for i := 1 to cnt do begin
      item := TKeyCommandItem( myKeyList[pred( i )] );

      itemStr:= item.Path;
      if item.Category <> CategorySelected then continue;

      if (Filter <> '') and (
          (pos(AnsiLowercase(Filter), AnsiLowercase(itemStr)) = 0)  and
          (not MMConsiderDescriptionOnFilter.Checked or (pos(AnsiLowercase(Filter), AnsiLowercase(item.Hint)) = 0))
          ) then
         continue;

      List_Commands.Items.AddObject( itemStr, item );
    end;

    if ( List_Commands.Items.Count > 0 ) then
       List_Commands.ItemIndex := 0;

    if CategorySelected = ccFont then
      List_CommandsClick(nil)
    else
      ShowCommandInfo;

  finally
    List_Commands.Items.EndUpdate;
  end;
end; // DisplayCommands


procedure TForm_KBD.ShowCommandInfo;
var
  item : TKeyCommandItem;
begin

  CleanEdit_Hotkey;

  LB_CurrentlyAssignedTo.Caption := 'None';
  LB_CurrentlyAssignedTo.Hint := '';

  item := GetSelectedItem;
  if assigned( item ) then begin
    LB_CmdHint.Caption := item.Hint;
    Edit_Current.Text := ShortCutToText( item.ShortCut );
  end
  else begin
    LB_CmdHint.Caption := '';
    Edit_Current.Text := '';
  end;

end; // ShowCommandInfo

procedure TForm_KBD.List_CommandsClick(Sender: TObject);
var
   i: integer;
begin
   ShowCommandInfo;

  if RBShowFonts.Checked then begin
     if List_Commands.ItemIndex >= 0 then
        i:= Combo_Font.items.IndexOf(List_Commands.Items[List_Commands.ItemIndex])
     else
        i:= -1;

     Combo_Font.ItemIndex:= i;
  end;

end;

procedure TForm_KBD.Combo_FontChange(Sender: TObject);
var
   fi, i: integer;
begin
   fi:= Combo_Font.ItemIndex;
   i:= List_Commands.items.IndexOf(Combo_Font.Items[fi]);

   if i >= 0 then
      List_Commands.ItemIndex:= i

   else begin
      Edit_Filter.Text:= '';
      DisplayCommands;
      List_Commands.ItemIndex:= fi;
      Combo_Font.ItemIndex:= fi;
   end;
end;

procedure TForm_KBD.CleanEdit_Hotkey;
begin
   Edit_Hotkey.HotKey:= 0;
   lblAssig.Visible := false;
   LB_CurrentlyAssignedTo.visible:= false;
   Pnl.Font.Style := [];
end;


procedure TForm_KBD.Edit_HotKeyKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  selItem, item : TKeyCommandItem;
  Caption: string;
begin
    LB_CurrentlyAssignedTo.Hint := '';
    UserShortcut := Edit_HotKey.HotKey;

    if ( UserShortcut <> 0 ) then begin
      selItem:= GetSelectedItem;
      // Edit_HotKey.Text := ShortcutToText( UserShortcut );
      if IsValidShortcut( selItem, UserShortcut ) then begin
         item := GetItemByShortcut( nil, UserShortcut, (selItem.Group= cgOther) );
         if assigned( item ) then begin
            Caption:= Item.Caption;
            if selItem.Group = cgOther then
               Caption:= KeyboardConfigSections[item.Category] + ' | ' + Caption;
            LB_CurrentlyAssignedTo.Caption := Caption;
            LB_CurrentlyAssignedTo.Hint := item.Hint;
        end
        else
           LB_CurrentlyAssignedTo.Caption := 'None';
      end
      else begin
         MessageShortcutInvalid (UserShortcut);
         UserShortcut:= 0;
      end;
    end;

    lblAssig.Visible := ( UserShortcut <> 0 );
    LB_CurrentlyAssignedTo.visible:= ( UserShortcut <> 0 );
    if UserShortcut <> 0 then
       Pnl.Font.Style := [fsBold]
    else
       Pnl.Font.Style := [];

end;

function TForm_KBD.GetSelectedItem: TKeyCommandItem;
var
  i : integer;
begin
  i := List_Commands.ItemIndex;
  if ( i >= 0 ) then
    result := TKeyCommandItem( List_Commands.Items.Objects[i] )
  else
    result := nil;
end; // GetSelectedItem


function TForm_KBD.GetItemByShortcut( SelItem: TKeyCommandItem;
  const aShortcut: TShortcut; searchInAllCategories: boolean=false): TKeyCommandItem;
var
  i, cnt : integer;
  Item : TKeyCommandItem;
begin
  result := nil;
  cnt := myKeyList.Count;

  if ( SelItem = nil ) then
    SelItem := GetSelectedItem;

  if ( not assigned( SelItem )) then
    exit;

  for i := 1 to cnt do begin
    item := TKeyCommandItem( myKeyList[pred( i )] );
    if (( Item <> SelItem ) and (searchInAllCategories or  (Item.Group = SelItem.Group) )) then begin
      if ( Item.Shortcut = aShortcut ) then begin
        result := Item;
        break;
      end;
    end;
  end;
end; // GetItemByShortcut

function TForm_KBD.IsValidShortcut(const aItem: TKeyCommandItem;
  const aShortcut: TShortcut): boolean;
var
  Key : Word;
  Shift : TShiftState;
begin
  result := false;

  if ( aShortcut = 0 ) then exit;

  ShortcutToKey( aShortcut, Key, Shift );

  if ( key = 0 ) then exit;

  if (key = VK_F4) and ( Shift = [ssAlt]) then exit;

  if (( ssAlt in Shift ) or ( ssCtrl in Shift )) then begin
    result := true;
    exit;
  end;

  if aItem.Category = ccMenuTree then
     result:= true
  else begin
    if ( key in [VK_F1..VK_F12, VK_INSERT, VK_DELETE, VK_HOME, VK_END, VK_PRIOR, VK_NEXT] ) then
        result := true;
  end;

end; // IsValidShortcut

procedure TForm_KBD.Btn_RemoveClick(Sender: TObject);
var
  item : TKeyCommandItem;
begin
  item := GetSelectedItem;
  if ( assigned( item ) and ( item.Shortcut <> 0 )) then begin
    IsModified := true;
    item.Shortcut := 0;
    ShowCommandInfo;
  end;
end;

procedure TForm_KBD.MessageShortcutInvalid (aShortcut : TShortcut);
var
  Str: string;
begin
   Str:= ShortcutToText( aShortcut );
   {if (aShortcut <> 0) and (Str = '') then
      Str:= ShortcutToText( KeyNoteActivationHotkey );  }

    App.WarningPopup( Format('"%s" is not a valid keyboard shortcut for the selected command.', [Str]));

   CleanEdit_Hotkey;
end;

procedure TForm_KBD.Btn_AssignClick(Sender: TObject);
var
  item, olditem : TKeyCommandItem;
  newShortcut : TShortcut;
begin
  item := GetSelectedItem;

  if ( not assigned( item )) then exit;

  newShortcut := Edit_Hotkey.Hotkey;

  if newShortcut = 0 then exit;

  if ( not IsValidShortcut( item, newShortcut )) then begin
    MessageShortcutInvalid (newShortcut);
    exit;
  end;

  if item.Group= cgOther then begin
     oldItem := GetItemByShortcut( item, newShortcut, true );
     if assigned(oldItem) and (oldItem.Group <> cgOther) then
       if App.DoMessageBox('The menu shortcut will not be deleted and will take priority over this shortcut. CONTINUE?' + #13#13 +
                    '(You can remove the menu shortcut selecting the corresponding command category)',
            mtConfirmation, [mbYes,mbNo,mbCancel], def3 ) <> mrYes then
          exit;
  end;

  oldItem := GetItemByShortcut( item, newShortcut );

  if assigned( oldItem ) and ((item.Group <> cgOther) or (oldItem.Group = cgOther)) then
    oldItem.Shortcut := 0;

  IsModified := true;
  item.Shortcut := newShortcut;

  CleanEdit_Hotkey;

  ShowCommandInfo;
end;


procedure TForm_KBD.Btn_ListClick(Sender: TObject);
var
  kbdlist_fn : string;
begin
  screen.Cursor := crHourGlass;
  try
    try
      kbdlist_fn := extractfilepath( myKBD_FN ) + 'keyboard.html';
      ListKeyboardShortcuts( kbdlist_fn, MMListUnassigned.Checked, myKeyList );
      shellexecute( 0, 'open', PChar( kbdlist_fn ), nil, nil, SW_NORMAL );
    except
      on E : Exception do
        App.ErrorPopup(E.Message);
    end;

  finally
    screen.Cursor := crDefault;
  end;
end;

procedure TForm_KBD.Btn_ResetAllClick(Sender: TObject);
begin
  if ( not fileexists( myKBD_FN )) then begin
    App.InfoPopup( Format(
      'Keyboard configuration file "%s" does not exist. KeyNote is currently using default keyboard configuration.',
      [myKBD_FN] ));
    exit;
  end;

  if ( App.DoMessageBox(
    'Existing keyboard configuration file will be deleted.'+ #13 + 'ORIGINAL keyboard SHORTCUTS will be RESTORED AFTER you RESTART KeyNote' + #13#13 + 'Continue?', mtWarning, [mbOK,mbCancel], def2 ) = mrOK ) then
  begin
    if deletefile( myKBD_FN ) then begin
      IsModified := false;
      ModalResult := mrCancel;
    end
    else
       App.ErrorPopup( Format( 'Could not delete keyboard configuration file "%s"', [myKBD_FN] ));
  end;

end;

procedure TForm_KBD.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if ( IsModified and ( ModalResult = mrCancel )) then
    CanClose := ( App.DoMessageBox(
      'Keyboard configuration has changed. Are you sure you want to discard these changes?', mtConfirmation, [mbOK, mbCancel], def2 )  = mrOK );
end;

procedure TForm_KBD.EnableAccelerators(const DoEnable: boolean);
begin
  if DoEnable then begin
    LB_Cmd.Caption := '&Commands:';
    LB_Shortcut.Caption := '&New keyboard shortcut:';
    Btn_Assign.Caption := '&Assign';
    Btn_Remove.Caption := '&Remove';
    Btn_ResetAll.Caption := 'R&eset All';
    Btn_List.Caption := '&List';
  end
  else begin
    LB_Cmd.Caption := RemoveAccelChar( LB_Cmd.Caption );
    LB_Shortcut.Caption := RemoveAccelChar( LB_Shortcut.Caption );
    Btn_Assign.Caption := RemoveAccelChar( Btn_Assign.Caption );
    Btn_Remove.Caption := RemoveAccelChar( Btn_Remove.Caption );
    Btn_ResetAll.Caption := RemoveAccelChar( Btn_ResetAll.Caption );
    Btn_List.Caption := RemoveAccelChar( Btn_List.Caption );
  end;
end; // EnableAccelerators

procedure TForm_KBD.Edit_FilterExit(Sender: TObject);
begin
   DisplayCommands;
end;

procedure TForm_KBD.Edit_FilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   if key= 13 then
      DisplayCommands;
end;


procedure TForm_KBD.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if (key = 13) and (Edit_Filter.Focused ) then begin
       DisplayCommands;
    end
    else if (Key = VK_F1) and (Shift = []) then begin
       Key:= 0;
       ActiveKeyNoteHelp(105, 0);
    end;
end;


procedure TForm_KBD.Edit_HotKeyEnter(Sender: TObject);
begin
  EnableAccelerators( false );
end;

procedure TForm_KBD.Edit_HotKeyExit(Sender: TObject);
begin
  EnableAccelerators( true );
end;

procedure TForm_KBD.MMConsiderDescriptionOnFilterClick(Sender: TObject);
begin
   MMConsiderDescriptionOnFilter.Checked := not MMConsiderDescriptionOnFilter.Checked;
   DisplayCommands;
end;

procedure TForm_KBD.MMListUnassignedClick(Sender: TObject);
begin
  MMListUnassigned.Checked := ( not MMListUnassigned.Checked );
end;

procedure TForm_KBD.RBShowCommandsCategoryClick(Sender: TObject);
begin
    Edit_Filter.Text:= '';
    DisplayCommands;
end;


procedure TForm_KBD.Btn_HelpClick(Sender: TObject);
begin
   ActiveKeyNoteHelp(105, 0);
  //Application.HelpCommand( HELP_CONTEXT, 610 );
end;

end.
