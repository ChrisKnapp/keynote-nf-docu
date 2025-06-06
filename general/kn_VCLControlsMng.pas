unit kn_VCLControlsMng;

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
   Winapi.RichEdit,
   Winapi.ShellAPI,
   Winapi.MMSystem,
   Winapi.ActiveX,
   System.SysUtils,
   System.Classes,
   System.IniFiles,
   System.Win.ComObj,
   Vcl.Controls,
   Vcl.ComCtrls,
   Vcl.Graphics,
   Vcl.Forms,
   Vcl.Dialogs,
   Vcl.Menus,
   Vcl.StdCtrls,
   Vcl.ExtCtrls,

   ComCtrls95,
   TB97Ctls,

   kn_KntFolder,
   knt.model.note
;



    // dynamically create and destroy controls (folder tabs, RichEdits, trees, etc)
    procedure SetUpVCLControls( aFolder : TKntFolder ); // sets up VCL controls for knt folder (events, menus, etc - only stuff that is handled in this unit, not stuff that TTabNote handles internally)
    procedure CreateVCLControls; // creates VCL controls for ALL folders in ActiveFile object
    procedure CreateScratchEditor;
    procedure SetupAndShowVCLControls;
    procedure CreateVCLControlsForFolder( const aFolder : TKntFolder ); // creates VCL controls for specified folder
    procedure DestroyVCLControls; // destroys VCL controls for ALL notes in ActiveFile object
    procedure DestroyVCLControlsForFolder( const aFolder : TKntFolder; const KillTabSheet : boolean ); // destroys VCL contols for specified folder

    // VCL updates when config loaded or changed
    procedure UpdateFormState;
    procedure UpdateTabState;

    procedure UpdateResPanelState;
    procedure SetResPanelPosition;
    procedure HideOrShowResPanel( const DoShow : boolean );
    procedure UpdateResPanelContents (ChangedVisibility: boolean);
    procedure LoadResScratchFile;
    procedure StoreResScratchFile;
    function CheckResourcePanelVisible( const DoWarn : boolean ) : boolean;
    procedure RecreateResourcePanel;
    procedure FocusResourcePanel;
    procedure CheckTagsField(Edit: TEdit; FindTags: TFindTags);

    procedure SelectStatusbarGlyph( const HaveKntFile : boolean );
    procedure SetFilenameInStatusbar(const FN : string );
    procedure SetStatusbarGlyph(const Value: TPicture);
    procedure FocusActiveEditor;
    procedure FocusActiveKntFolder;
    procedure SortTabs;

    procedure LoadTrayIcon( const UseAltIcon : boolean; DoProcessMessage: boolean= true );
    procedure LoadTabImages( const ForceReload : boolean );
{$IFDEF KNT_DEBUG}
    procedure SaveMenusAndButtons;
{$ENDIF}

    procedure EnableCopyFormat(value: Boolean);


type
  TDropTarget = class(TInterfacedObject, IDropTarget)
  private
    FControl: TWinControl;
  public
    constructor Create(AControl: TWinControl);
    function DragEnter(const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    function DragOver(grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    function DragLeave: HResult; stdcall;
    function Drop(const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
  end;

procedure UnregisterDropTarget(AControl: TWinControl); forward;
procedure RegisterDropTarget(AControl: TWinControl); forward;


var
  SBGlyph: TPicture;
  SavedChromeScratchFile: boolean;


implementation
uses
   MRUFList,
   RxRichEd,
   gf_misc,
   gf_files,
   gf_streams,
   gf_strings,
   gf_miscvcl,
   kn_Global,
   kn_Main,
   kn_Info,
   kn_Const,
   kn_Macro,
   kn_Chest,
   kn_EditorUtils,
   knt.ui.editor,
   knt.ui.tree,
   knt.ui.note,
   kn_MacroMng,
   kn_PluginsMng,
   kn_FavoritesMng,
   kn_TemplateMng,
   kn_FindReplaceMng,
   kn_NoteFileMng,
   kn_KntFile,
   knt.App,
   knt.RS;



//=================================================================
// SetUpVCLControls
//=================================================================
procedure SetUpVCLControls( aFolder : TKntFolder );
begin

  with Form_Main do begin
      FindAllResults.OnSelectionChange:= RxFindAllResultsSelectionChange;
      FindAllResults.ShowHint:= False;
      FindAllResults.AutoURLDetect:= False;

      if assigned( aFolder.Editor ) then begin
        with aFolder.Editor do begin
          PopUpMenu := Menu_RTF;
          OnChangedSelection:= RxChangedSelection;

          OnKeyDown:= RxRTFKeyDown;
          OnKeyPress:= RxRTFKeyPress;
          OnFileDropped := Form_Main.OnFileDropped;

          // AllowObjects := true;                      // Should be assigned when creating the control, to not lead to recreate its window
          // AllowInPlace := false;
          HelpContext:= 20;  // KeyNote Editor
        end;
      end;

      // enable "advanced typography options" for the richedit;
      // this gives us full justification and other goodies.
      if ( _LoadedRichEditVersion > 2 ) then
        SendMessage( aFolder.Editor.Handle, EM_SETTYPOGRAPHYOPTIONS, TO_ADVANCEDTYPOGRAPHY, TO_ADVANCEDTYPOGRAPHY );

      aFolder.TV.Perform(WM_HSCROLL, SB_TOP, 0);  // scroll to left border

      aFolder.Editor.SetZoom(DefaultEditorProperties.DefaultZoom, '' );
  end;

end; // SetUpVCLControls

//=================================================================
// CreateVCLControls
//=================================================================

procedure ScratchEditorApplyFontChrome;
begin
   with Form_Main.Res_RTF do begin
     Font.Charset := Chrome.Font.Charset;  // ANSI_CHARSET;
     Font.Color   := Chrome.Font.Color;    //clWindowText;
     Font.Size    := Chrome.Font.Size;     //-12;
     Font.Name    := Chrome.Font.Name;     //'Tahoma';
   end;
end;

procedure ScratchEditorSaveFontChrome;
var
  tempChrome: TChrome;
  SS, SL: integer;
begin
   with Form_Main.Res_RTF do begin
     SS:= SelStart;
     SL:= SelLength;
     SelStart:= Form_Main.Res_RTF.TextLength;
     SelLength:= 0;
     tempChrome.Font.Charset := SelAttributes.Charset;
     tempChrome.Font.Color   := SelAttributes.Color;
     tempChrome.Font.Size    := SelAttributes.Size;
     tempChrome.Font.Name    := SelAttributes.Name;
     Chrome:= tempChrome;
     SavedChromeScratchFile:= True;

     SelStart:= SS;
     SelLength:= SL;
   end;
end;


procedure CreateScratchEditor;
begin
  Form_Main.Res_RTF := TKntRichEdit.Create( Form_Main.ResTab_RTF );
  with Form_Main.Res_RTF do begin
     Parent := Form_Main.ResTab_RTF;
     Hint := 'Right-click for menu';
     DrawEndPage := False;
     Align := alClient;
     AllowInPlace := False;
     Chrome:= Knt.App.DefaultEditorChrome;
     ScratchEditorApplyFontChrome;
     Color:= KeyOptions.ScratchBGColor;
     //Font.Style := [];
     HideSelection := False;
     ParentFont := False;
     //PopupMenu := Form_Main.Menu_StdEdit;
     PopupMenu := Form_Main.Menu_RTF;
     UndoLimit := 10;
     WantTabs := True;
     OnChangedSelection:= Form_Main.RxChangedSelection;
     OnFileDropped := Form_Main.OnFileDropped;
     OnEnter:= App.AuxEditorFocused;
     OnKeyPress:= Form_Main.RxResTabRTFKeyPress;
     OnKeyDown:= Form_Main.RxResTabRTFKeyDown;

     SetVinculatedObjs(nil, nil, nil, nil);

     PlainText:= False;
     SupportsRegisteredImages:= True;
     SupportsImages:= True;
   end;
end;

procedure CreateVCLControls;
// creates all VCL controls for a newly loaded Notes file
var
  i : integer;
  myFolder : TKntFolder;
begin
  with Form_Main do begin
      if (( not assigned( ActiveFile )) or ( ActiveFile.Folders.Count = 0 )) then exit;

      for i := 0 to pred( ActiveFile.Folders.Count ) do begin
         myFolder := ActiveFile.Folders[i];
         CreateVCLControlsForFolder( myFolder );
      end;

  end;

end; // CreateVCLControls

//=================================================================
// ShowVCLControls
//=================================================================
procedure SetupAndShowVCLControls;
// Finalize setup and visualization of all VCL controls for a newly loaded Notes file
var
  i : integer;
  myFolder : TKntFolder;
begin
  if (( not assigned( ActiveFile )) or ( ActiveFile.Folders.Count = 0 )) then exit;

  try

    for i := 0 to pred( ActiveFile.Folders.Count ) do begin
      myFolder := ActiveFile.Folders[i];
      myFolder.LoadEditorFromNNode(myFolder.FocusedNNode, False);
      SetUpVCLControls( myFolder );
    end;

  finally
    with Form_Main do begin
       // show all tabs (they were created hidden)
       if (Pages.PageCount > 0) then
          for i := 0 to pred( Pages.PageCount ) do
             Pages.Pages[i].TabVisible := true;
    end;
  end;

  // The folder that was active when file was previously saved will be restored in
  // KntFileOpen (see comment *1)

end; // SetupAndShowVCLControls



//=================================================================
// CreateVCLControlsForFolder
//=================================================================
procedure CreateVCLControlsForFolder( const aFolder : TKntFolder );
var
  myTab : TTab95Sheet;
  myTreeUI: TKntTreeUI;
  myNoteUI: TKntNoteUI;
  mySplitter : TSplitter;
  myFolder : TKntFolder;
  {$IFDEF WITH_IE}
  myPanel : TPanel;
  myBrowser : TWebBrowser;
  {$ENDIF}


begin
  Log_StoreTick( 'CreateVCLControlsForFolder - Begin', 2, +1);

  with Form_Main do begin
        _ALLOW_VCL_UPDATES := false;
        myFolder := nil;
        {$IFDEF WITH_IE}
        myPanel := nil;
        {$ENDIF}

        try
          myFolder := aFolder;

          if ( aFolder.FocusMemory = focNil ) then
             aFolder.FocusMemory := focTree;


          // TabSheet --------------
          if ( aFolder.TabSheet = nil ) then begin
            myTab := TTab95Sheet.Create( Form_Main );
            with myTab do begin
              TabVisible := false; // hide tabs initially
              Parent := Pages;
              PageControl := Pages;

              if _TABS_ARE_DRAGGABLE then begin
                Dragable := true;
                FloatOnTop := false;
              end;

            end;
            aFolder.TabSheet := myTab;
          end
          else
            myTab := aFolder.TabSheet;


          // TreeUI --------------
          myTreeUI:= TKntTreeUI.Create(myTab);
          myTreeUI.Parent:= myTab;
          myTreeUI.PopupMenu := Form_Main.Menu_TV;

          // Splitter --------------
          mySplitter := TSplitter.Create( myTab );
          with mySplitter do begin
            Parent := myTab;
            Align := alNone;
            if myFolder.VerticalLayout then begin
              Top := myTreeUI.Height + 5;
              Align := alTop;
              Cursor := crVSplit;
              Height := 3;
            end
            else begin
              Left := myTreeUI.Width + 5;
              Align := alLeft;
              Cursor := crHSplit;
              Width := 4;
            end;
            Hint := GetRS(sVCL00);
          end;

          myTreeUI.SplitterNote := mySplitter;
          myFolder.Splitter := mySplitter;
          myFolder.TreeUI:= myTreeUI;


         {$IFDEF WITH_IE}
           myPanel := TPanel.Create( myTab );
           with myPanel do begin
            parent := myTab;
            Align := alClient;
            Caption := '';
            ParentFont := false;
            BevelInner := bvNone;
            BevelOuter := bvNone;
            BorderWidth := 1; // [?]
            Visible := true;
           end;

           myFolder.MainPanel := myPanel;

           if _IE4Available then begin
              myBrowser := TWebBrowser.Create( myPanel );
              TControl( myBrowser ).Parent := myPanel;
              with myBrowser do begin
                Align := alClient;
                Visible := false;
              end;
              myFolder.WebBrowser := myBrowser;
           end
           else
            myFolder.WebBrowser := nil;

         {$ENDIF}


          // Editor (KntRichEdit) ----------------------------

          myNoteUI:= TKntNoteUI.Create( myTab, aFolder );
          myNoteUI.Parent:= myTab;

          aFolder.NoteUI := myNoteUI;
          myTab.PrimaryObject := aFolder;

          Log_StoreTick( 'After Created TKntNoteUI', 3 );

          aFolder.UpdateTabSheet;
          myTreeUI.Folder:= myFolder;  // => PopulateTree...


        finally
          _ALLOW_VCL_UPDATES := true;
        end;
  end;

  Log_StoreTick( 'CreateVCLControlsForFolder - End', 3, -1 );

end; // CreateVCLControlsForFolder


//=================================================================
// DestroyVCLControlsForFolder
//=================================================================
procedure DestroyVCLControlsForFolder( const aFolder : TKntFolder; const KillTabSheet : boolean );
begin
   if not assigned( aFolder ) then exit;

   _ALLOW_VCL_UPDATES := false;
   try
     aFolder.NoteUI:= nil;       // Unbind interface before releasing object (which is done after aFolder.TabSheet.Free;)

     if assigned( aFolder.Splitter ) then
       FreeAndNil(aFolder.Splitter);

     if assigned(aFolder.TreeUI) then
       FreeAndNil(aFolder.TreeUI);

     if ( KillTabSheet and assigned(aFolder.TabSheet)) then
        aFolder.TabSheet.Free;

   finally
     _ALLOW_VCL_UPDATES := true;
   end;

end; // DestroyVCLControlsForFolder

//=================================================================
// DestroyVCLControls
//=================================================================
procedure DestroyVCLControls;
var
  i : integer;
  s : string;
begin
  with Form_Main do begin
     if ( pages.pagecount > 0 ) then begin
       for i := pred( pages.pagecount ) downto 0 do begin
           try
             s := pages.pages[i].Caption;
             pages.pages[i].Free;
           except
             on E : Exception do
                App.ErrorPopup(E, GetRS(sVCL01) + s);
           end;
       end;
     end;
  end;

end; // DestroyVCLControls


//=================================================================
// UpdateFormState
//=================================================================
procedure UpdateFormState;
var
   aux: integer;
begin
  with Form_Main do begin
     _SAVE_RESTORE_CARETPOS := EditorOptions.SaveCaretPos;

     Combo_Font.DropDownCount := KeyOptions.ComboDropDownCount;
     Combo_FontSize.DropDownCount := KeyOptions.ComboDropDownCount;
     Combo_Style.DropDownCount := KeyOptions.ComboDropDownCount;
     Combo_ResFind.DropDownCount := KeyOptions.ComboDropDownCount;
     Combo_Zoom.DropDownCount := KeyOptions.ComboDropDownCount;

     with KeyOptions do begin

       // apply settings to VCL stuff

       if ColorDlgBig then
         ColorDlg.Options := [cdFullOpen,cdSolidColor,cdAnyColor]
       else
         ColorDlg.Options := [cdSolidColor,cdAnyColor];

       if LongCombos then begin
         Combo_Font.Width := OriginalComboLen + ( OriginalComboLen DIV 4 );
         Combo_Style.Width := Combo_Font.Width;
       end
       else begin
          if ( ComboFontLen > MIN_COMBO_LENGTH ) then begin  //***  Directamente da un error interno al compilar �??
             //Combo_Font.Width := ComboFontLen;
               aux:= ComboFontLen;
               Combo_Font.Width := aux;
          end;

          if ( ComboStyleLen > MIN_COMBO_LENGTH ) then begin
            //Combo_Style.Width := ComboStyleLen;
            aux:= ComboStyleLen;
            Combo_Style.Width:= aux;
          end;
       end;

       // [style]
       if StyleShowSamples then
         Combo_Style.ItemHeight := 19
       else
         Combo_Style.ItemHeight := 16;


       PlainDefaultPaste_Toggled;

       if EditorOptions.TrackStyle then begin
         case EditorOptions.TrackStyleRange of
           srFont : MMViewFormatFont.Checked := true;
           srParagraph : MMViewFormatPara.Checked := true;
           srBoth : MMViewFormatBoth.Checked := true;
         end;
       end
       else
         MMViewFormatNone.Checked := true;

       if UseOldColorDlg then begin
         MMFormatTextColor.Hint := GetRS(sVCL02);
         MMFormatHighlight.Caption := GetRS(sVCL03);
         MMFormatHighlight.Hint := GetRS(sVCL04);
       end
       else begin
         MMFormatTextColor.Hint := GetRS(sVCL05);
         MMFormatHighlight.Caption := GetRS(sVCL06);
         MMFormatHighlight.Hint := GetRS(sVCL07);
       end;

       AppLastActiveTime := now;
       if ( TimerMinimize or TimerClose ) then
         Form_Main.AssignOnMessage
       else
         Application.OnMessage := nil;

       ShowHint := ShowTooltips;
       TrayIcon.Active := UseTray;
       AutoSaveToggled;

       Toolbar_Main.Visible := ToolbarMainShow;
       MMViewTBMain.Checked := ToolbarMainShow;

       Toolbar_Format.Visible := ToolbarFormatShow;
       MMViewTBFormat.Checked := ToolbarFormatShow;

       Toolbar_Insert.Visible := ToolbarInsertShow;
       MMViewTBInsert.Checked := ToolbarInsertShow;

       Toolbar_Macro.Visible := true; // ToolbarMacroShow;
       MMToolsMacroRun.Enabled := Toolbar_Macro.Visible;

       MMViewTBTree.Checked := ToolbarTreeShow;

       Toolbar_Style.Visible := ToolbarStyleShow;
       MMViewTBStyle.Checked := ToolbarStyleShow;

       { // Removed TB_Exit button
       if MinimizeOnClose then
         TB_Exit.Hint := GetRS(sVCL08
       else
         TB_Exit.Hint := GetRS(sVCL09;
       }

     end;

     if KeyOptions.MRUUse then begin
       with KeyOptions do begin
         MRU.Maximum := MRUCount;
         MRU.AutoSave := true;
         MRU.UseSubmenu := MRUSubmenu;
         if MRUFullPaths then
           MRU.MRUDisplay := mdFullPath
         else
           MRU.MRUDisplay := mdFileNameExt;
       end;
     end
     else begin
       with KeyOptions do begin
        MRU.Maximum := 0;
        MRU.RemoveAllItems;
        MRU.AutoSave := false;
       end;
     end;

     CB_ResFind_CaseSens.Checked := FindOptions.MatchCase;
     CB_ResFind_WholeWords.Checked := FindOptions.WholeWordsOnly;
     CB_ResFind_AllNotes.Checked := FindOptions.AllTabs;
     CB_ResFind_CurrentNodeAndSubtree.Checked := FindOptions.CurrentNodeAndSubtree;
     CB_ResFind_CurrentNodeAndSubtree.Enabled:= not FindOptions.AllTabs;
     RG_ResFind_Scope.ItemIndex := ord( FindOptions.SearchScope );
     RG_ResFind_Type.ItemIndex := ord( FindOptions.SearchMode );
     RG_ResFind_ChkMode.ItemIndex := ord( FindOptions.CheckMode );
     CB_ResFind_PathInNames.Checked := FindOptions.SearchPathInNodeNames;
     CB_ResFind_PathInNames.Enabled:= ( TSearchScope( RG_ResFind_Scope.ItemIndex ) <> ssOnlyContent );
     CbFindFoldedMode.ItemIndex:= ord( FindOptions.FoldedMode);
  end;


end; // UpdateFormState

//=================================================================
// UpdateTabState
//=================================================================
procedure UpdateTabState;
begin
  with Form_Main do begin
     Pages.ButtonStyle := false;
     Pages.AllowTabShifting := true;
     Pages.HotTrack := TabOptions.HotTrack;

     if ( TabOptions.Images and MMViewTabIcons.Enabled ) then
       Pages.Images := Chest.IMG_Categories
     else
       Pages.Images := nil;
     MMViewTabIcons.Checked := TabOptions.Images;


     // update these settings only if Initializing, ie before we have any notes loaded. This is
     // to prevent loss of RTF text formatting when tabsheets are recreated. Changes made to these
     // settings will take effect after restarting KeyNote.

     if ( Initializing or ( not KeyOptions.RichEditv3 )) then begin
       case TabOptions.TabOrientation of
         tabposTop : begin
           Pages.TabPosition := tpTopLeft;
           Pages.VerticalTabs := false;
           Pages.TextRotation := trHorizontal;
         end;
         tabposBottom : begin
           Pages.TabPosition := tpBottomRight;
           Pages.VerticalTabs := false;
           Pages.TextRotation := trHorizontal;
         end;
         tabposLeft : begin
           Pages.TabPosition := tpTopLeft;
           Pages.VerticalTabs := true;
           Pages.TextRotation := trVertical;
         end;
         tabposRight : begin
           Pages.TabPosition := tpBottomRight;
           Pages.VerticalTabs := true;
           Pages.TextRotation := trVertical;
         end;
       end;
       Pages.MultiLine := TabOptions.Stacked;
       Splitter_ResMoved( Splitter_Res );
     end;

     with Pages.Font do begin
       Name := TabOptions.Font.FName;
       Size := TabOptions.Font.FSize;
       Color := TabOptions.Font.FColor;
       Style := TabOptions.Font.FStyle;
       Charset := TabOptions.Font.FCharset;
     end;

     with Pages.TabInactiveFont do begin
       Name := TabOptions.Font.FName;
       Size := TabOptions.Font.FSize;
       if TabOptions.ColorAllTabs then
         Color := TabOptions.Font.FColor
       else
         Color := clWindowText;
       Style := [];
       Charset := TabOptions.Font.FCharset;
     end;

     Pages.Color := TabOptions.ActiveColor;
     Pages.TabInactiveColor := TabOptions.InactiveColor;
  end;

end; // UpdateTabState



//======================
//      ResPanel
//======================

procedure HideOrShowResPanel( const DoShow : boolean );
begin
  with Form_Main do begin
      if ( DoShow = Pages_Res.Visible ) then exit;

      try
        if KeyOptions.ResPanelLeft then begin
           Splitter_Res.Visible := DoShow;
           Pages_Res.Visible := DoShow;
        End
        else begin
           Pages_Res.Visible := DoShow;
           Splitter_Res.Visible := DoShow;
        end;

      finally
        // must redraw editor, otherwise it displays garbage
        if assigned(ActiveFolder) then
          ActiveFolder.Editor.Invalidate;
      end;
  end;

end; // HideOrShowResPanel


procedure SetResPanelPosition;
begin
  with Form_Main do begin
      if ( KeyOptions.ResPanelLeft and ( Splitter_Res.Align = alLeft )) or
         (( not KeyOptions.ResPanelLeft ) and ( Splitter_Res.Align = alRight )) then
        exit;

      // these settings must be applied in order.
      // Will be much easier in D5.

      case KeyOptions.ResPanelLeft of
        false : begin
          Pages.Align := alNone;
          Splitter_Res.Align := alNone;
          Pages_Res.Align := alRight;
          Pages.Align := alClient;
          Splitter_Res.Align := alRight;
        end;
        true : begin
          Pages.Align := alNone;
          Splitter_Res.Align := alNone;
          Pages_Res.Align := alLeft;
          Pages.Align := alClient;
          Splitter_Res.Align := alLeft;
        end;
      end;
  end;
end; // SetResPanelPosition


procedure UpdateResPanelState;
begin
  with Form_Main do begin
        with Pages_Res do begin
          Images := nil;
          ButtonStyle := false;
          // AllowTabShifting := false;
          HotTrack := TabOptions.HotTrack;

          // update these settings only if Initializing,
          // ie before we have any notes loaded. This is
          // to prevent loss of RTF text formatting when
          // tabsheets are recreated
          if Initializing then begin

            SetResPanelPosition;

            ResMPluginTabClick( nil ); // with nil, settings will not be changed, but tabs will be shown or hidden (normally this is called by TMenuItem)

            MultiLine := ResPanelOptions.Stacked;

            case ResPanelOptions.TabOrientation of
              tabposTop : begin
                TabPosition := tpTopLeft;
                VerticalTabs := false;
                TextRotation := trHorizontal;
              end;
              tabposBottom : begin
                TabPosition := tpBottomRight;
                VerticalTabs := false;
                TextRotation := trHorizontal;
              end;
              tabposLeft : begin
                TabPosition := tpTopLeft;
                VerticalTabs := true;
                TextRotation := trVertical;
              end;
              tabposRight : begin
                TabPosition := tpBottomRight;
                VerticalTabs := true;
                TextRotation := trVertical;
              end;
            end;

            {
            // custom draw for List_ResFind
            if ResPanelOptions.ColorFindList then
            begin
              List_ResFind.Style := lbOwnerDrawFixed;
              List_ResFind.OnDrawItem := List_ResFindDrawItem;
              List_ResFind.ItemHeight := ScaleFromSmallFontsDimension(List_ResFind.ItemHeight);   // http://stackoverflow.com/questions/8296784/how-do-i-make-my-gui-behave-well-when-windows-font-scaling-is-greater-than-100
            end;
            }

            // add history to combo
            DelimTextToStrs( Combo_ResFind.Items, FindOptions.FindAllHistory, HISTORY_SEPARATOR );
            CB_ResFind_AllNotes.Checked := FindOptions.AllTabs;
          end;

          Font.Assign( Form_Main.Pages.Font );
          TabInactiveFont.Assign( Form_Main.Pages.TabInactiveFont );
          Color := TabOptions.ActiveColor;
          TabInactiveColor := TabOptions.InactiveColor;
        end;

        MMViewResPanel.Checked := KeyOptions.ResPanelShow;
        if KeyOptions.ResPanelShow then
          ResMHidepanel.Caption := GetRS(sVCL12)
        else
          ResMHidepanel.Caption := GetRS(sVCL13);
        TB_ResPanel.Down := MMViewResPanel.Checked;
  end;

end; // UpdateResPanelState


procedure CheckTagsField(Edit: TEdit; FindTags: TFindTags);
var
   txt: string;
begin
   txt:= Trim(Edit.Text);
   if (txt <> '') and (txt <> EMPTY_TAGS) and (FindTags = nil) then begin
      Edit.SetFocus;
      Form_Main.cbTagFindMode.SetFocus;
   end;
end;


procedure UpdateResPanelContents (ChangedVisibility: boolean);
var
   SS, SL: integer;
begin
  // General idea: do not load all resource panel information
  // when KeyNote starts. Instead, load data only when
  // a tab is viewed, if the tab contains no data. For example,
  // when user clicks the Macros tab and the list of macros
  // is empty, we load he macros.

  // [dpv]
  // As macros, plugins and templates can be inserted via keyboard shortcuts it seems not a good idea
  // to not load that resources at the beginning or to unload them later.
  // However only list of macros needs to be loaded to be able to execute a particular macro.
  // This is done at the beginning, in InitializeKeyNote.MacroInitialize (-> LoadMacroList)
  // Templates can be inserted with shortcuts even if the list of templates is not loaded
  // At the beginning, in kn_ConfigMng.LoadCustomKeyboard, the application loads from Keyboard.ini
  // the custom commands. In the case of templates, the name of the file is the command.
  //
  // KeyOptions.ResPanelActiveUpdate = 1 is used to to reload the resources from disk  (for the selected tab).
  // Eg. if a macro file was copied to macros folder while KeyNote is running, simply hiding and then
  // showing the resource panel will load the new macro (press F9 twice)

  with Form_Main do begin
     if KeyOptions.ResPanelShow then begin

        MMToolsPluginRun.Enabled := ResTab_Plugins.TabVisible;
        MMToolsMacroRun.Enabled := ResTab_Macro.TabVisible;

        if ( Pages_Res.ActivePage = ResTab_Find ) then begin
          // Make sure the labels are interpreted according to this file
           CheckTagsField(txtTagsIncl, FindTagsIncl);
           CheckTagsField(txtTagsExcl, FindTagsExcl);
        end
        else
        if ( Pages_Res.ActivePage = ResTab_RTF ) then begin
          Res_RTF.BeginUpdate;
          SS:= Res_RTF.SelStart;
          SL:= Res_RTF.SelLength;
          if not Initializing and KeyOptions.ResPanelActiveUpdate and ChangedVisibility then begin
             if Res_RTF.Modified then
                StoreResScratchFile;
             Res_RTF.GetAndRememberCurrentZoom;
          end;

          if (ChangedVisibility and not Initializing) or (not SavedChromeScratchFile) then begin
            LoadResScratchFile;
            Res_RTF.SelStart:= SS;
            Res_RTF.SelLength:= SL;
          end;

          if (Res_RTF.ZoomCurrent < 0) and (ImageMng.StorageMode <> smEmbRTF) then
             Res_RTF.ReconsiderImages(false, imImage);

          Res_RTF.EndUpdate;
        end
        else
        if ( Pages_Res.ActivePage = ResTab_Macro ) then begin
          if not Initializing and KeyOptions.ResPanelActiveUpdate then begin
             // if a macro file was copied to macros folder while KeyNote is running, simply hiding and then
             // showing the resource panel will load the new macro (press F9 twice)
             ListBox_ResMacro.Items.Clear;
             ClearMacroList;
          end;
          // load macros
          if ( ListBox_ResMacro.Items.Count = 0 ) then
            EnumerateMacros;
        end
        else
        if ( Pages_Res.ActivePage = ResTab_Template ) then begin
          if not Initializing and KeyOptions.ResPanelActiveUpdate then
             ListBox_ResTpl.Items.Clear;
          // load templates
          if ( ListBox_ResTpl.Items.Count = 0 ) then
            LoadTemplateList;
        end
        else
        if ( Pages_Res.ActivePage = ResTab_Plugins ) then begin
          // List of plugns does NOT get cleared, because it takes a long time to initialize.
          // Once loaded, the list remains available even after the resource panel is hidden. To reload
          // the list of current plugins, use the "Reload plugins" menu command.
          {if not Initializing and KeyOptions.ResPanelActiveUpdate then
             ListBox_ResPlugins.Items.Clear; }
          if ( ListBox_ResPlugins.Items.Count = 0 ) then
            DisplayPlugins;
        end
        else
        if ( Pages_Res.ActivePage = ResTab_Favorites ) then begin
          if not Initializing and KeyOptions.ResPanelActiveUpdate then
             ListBox_ResFav.Items.Clear;
          if ( ListBox_ResFav.Items.Count = 0 ) then
            DisplayFavorites;
        end
        else
        if ( Pages_Res.ActivePage = ResTab_Tags ) then begin
           var TS: TTagsState:= App.TagsState;
           App.TagsState := tsVisible;
           if (TS = tsPendingUpdate) or chkFilteronTags.Checked then
              App.TagsUpdated;
        end;

     end
     else begin
        MMToolsPluginRun.Enabled := false;
        MMToolsMacroRun.Enabled := false;

        try
          if assigned(Res_RTF) and Res_RTF.Modified then
            StoreResScratchFile;
        except
        end;
     end;

     if ( Pages_Res.ActivePage <> ResTab_Tags ) and (App.TagsState = tsVisible) then
         App.TagsState:= tsHidden;

  end;


end; // UpdateResPanelContents


procedure RecreateResourcePanel;
begin
  with Form_Main do begin
      KeyOptions.ResPanelShow := false;
      Pages_ResChange( Pages_Res );

      try

        with Pages_Res do begin
          MultiLine := ResPanelOptions.Stacked;

          case ResPanelOptions.TabOrientation of
            tabposTop : begin
              TabPosition := tpTopLeft;
              VerticalTabs := false;
              TextRotation := trHorizontal;
            end;
            tabposBottom : begin
              TabPosition := tpBottomRight;
              VerticalTabs := false;
              TextRotation := trHorizontal;
            end;
            tabposLeft : begin
              TabPosition := tpTopLeft;
              VerticalTabs := true;
              TextRotation := trVertical;
            end;
            tabposRight : begin
              TabPosition := tpBottomRight;
              VerticalTabs := true;
              TextRotation := trVertical;
            end;
          end;
          Splitter_ResMoved( Splitter_Res );
        end;

      finally
        KeyOptions.ResPanelShow := true;
        Pages_ResChange( Pages_Res );
      end;
  end;
end; // RecreateResourcePanel


procedure FocusResourcePanel;
begin
  with Form_Main do begin
      if Pages_Res.Visible then begin
        try
          if ( Pages_Res.ActivePage = ResTab_Find ) then
            Combo_ResFind.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_RTF ) then
            Res_RTF.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_Macro ) then
            ListBox_ResMacro.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_Template ) then
            ListBox_ResTpl.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_Plugins ) then
            ListBox_ResPlugins.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_Favorites ) then
            ListBox_ResFav.SetFocus
          else
          if ( Pages_Res.ActivePage = ResTab_Tags ) then
            TVTags.SetFocus;

        except
          // nothing
        end;
      end;
  end;
end; // FocusResourcePanel


function CheckResourcePanelVisible( const DoWarn : boolean ) : boolean;
begin
  result := Form_Main.Pages_Res.Visible;
  if ( not result ) then begin
    if DoWarn then  begin
      case App.DoMessageBox(GetRS(sVCL14), mtConfirmation, [mbYes,mbNo]) of
        mrYes : begin
          Form_Main.MMViewResPanelClick( Form_Main.MMViewResPanel );
        end;
      end;
    end;
    exit;
  end;
end; // CheckResourcePanelVisible


procedure LoadResScratchFile;
var
   WasSavedChromeScratchFile: boolean;
begin

  with Form_Main do begin
      if fileexists( Scratch_FN ) then begin
        Res_RTF.BeginUpdate;
        try
          try
            WasSavedChromeScratchFile:= SavedChromeScratchFile;
            ScratchEditorApplyFontChrome;
            Res_RTF.Lines.LoadFromFile( Scratch_FN );
            ScratchEditorSaveFontChrome;                 // Considering the last position in editor
            if not WasSavedChromeScratchFile then begin
               // We make sure that if the Scratchpad is visible at startup and all content is deleted, the font used in it is respected.
               Res_RTF.Clear;
               ScratchEditorApplyFontChrome;
               Res_RTF.Lines.LoadFromFile( Scratch_FN );
            end;

          except
          end;

        finally
          Res_RTF.RestoreZoomCurrent;
          Res_RTF.EndUpdate;
          Res_RTF.Modified:= false;
        end;
      end
      else
         if ActiveFolder <> nil then begin
            Res_RTF.Chrome:= ActiveFolder.EditorChrome;
            ScratchEditorApplyFontChrome;
            SavedChromeScratchFile:= True;
            Res_RTF.Modified:= False;
         end;
  end;
end; // LoadResScratchFile


procedure StoreResScratchFile;
begin
  try
    Form_Main.Res_RTF.Lines.SaveToFile( Scratch_FN );
    ScratchEditorSaveFontChrome;                          // Considering the last position in editor
    Form_Main.Res_RTF.Modified:= False;

  except
    // may throw exception e.g. if file is locked by another app,
    // we don't worry about scratchpad errors
  end;
end; // StoreResScratchFile


procedure SortTabs;
var
  p, i, j : integer;
  namei, namej : string;
begin
  with Form_Main do begin
     if ( Pages.PageCount < 2 ) then exit;

     Pages.Enabled := false;
     try

       for i := 0 to Pages.PageCount - 1 do begin
         for j := succ(i) to Pages.PageCount - 1 do begin
           namei := pages.Pages[i].Caption;
           namej := pages.Pages[j].Caption;
           p := pos( '&', namei );
           if p > 0 then
              delete( namei, p, 1 );
           p := pos( '&', namej );
           if p > 0 then
              delete( namej, p, 1 );
           if ( ansicomparetext( namei, namej ) > 0 ) then
              Pages.Pages[j].PageIndex := i;
         end;
       end;

       // must reassign images, because they get lost on sort
       if ( Pages.Images <> nil ) then begin
         for i := 0 to Pages.PageCount - 1 do
            Pages.Pages[i].ImageIndex := TKntFolder(Pages.Pages[i].PrimaryObject).ImageIndex;
       end;

     finally
       Pages.Enabled := true;
       App.ActivateFolder(ActiveFolder);
       ActiveFile.Modified := true;
     end;
  end;

end; // SortTabs


procedure FocusActiveEditor;
begin
   if not assigned(ActiveEditor) then exit;
   ActiveFolder.SetFocusOnNoteEditor;
end;

procedure FocusActiveKntFolder;
begin
   if assigned(ActiveFolder) and (not Initializing) then begin
      if ActiveFolder.TreeUI.Visible and (ActiveFolder.FocusMemory = focTree) then
         ActiveFolder.SetFocusOnTree
      else
         ActiveFolder.SetFocusOnNoteEditor;
   end;
end; // FocusActiveKntFolder


procedure SetStatusbarGlyph(const Value: TPicture);
begin
   SBGlyph.Assign(Value);

   // This way we force that panel to be updated (and only that panel).
   // If we used .Repaint, .Refresh, .Invalidate or .Update on the StatusBar, it would be updated too,
   // but all the panels would be affected, and also (don't know why), text panel would show bold, until form resized..
   Form_Main.StatusBar.Panels[PANEL_FILEICON].Width:= 10;

end;


procedure SetFilenameInStatusbar(const FN : string );
begin
   with Form_Main.StatusBar do begin
      Panels[PANEL_FILENAME].Text:= FN;
      Panels[PANEL_FILENAME].Width := Canvas.TextWidth(Panels[PANEL_FILENAME].Text) + 8;
   end;
end;


procedure SelectStatusbarGlyph( const HaveKntFile : boolean );
var
  Glyph : TPicture;
  Index: integer;
begin

  // indicate file state or special program activity
  // with a cute little icon on statusbar

  Glyph := TPicture.Create;
  try

    Index:= NODEIMG_BLANK;

    if HaveKntFile then begin

      if IsRecordingMacro then
         Index:= NODEIMG_MACROREC
      else
      if IsRunningMacro then
         Index:= NODEIMG_MACRORUN
      else
      if ActiveFile.ReadOnly then begin
        case ActiveFile.FileFormat of
          nffKeyNote :   Index:= NODEIMG_TKN_RO;
          nffKeyNoteZip: Index:= NODEIMG_TKNZIP_RO;
          nffEncrypted : Index:= NODEIMG_ENC_RO;
{$IFDEF WITH_DART}
          nffDartNotes : Index:= NODEIMG_DART_RO;
{$ENDIF}
        end;
      end
      else begin
        case ActiveFile.FileFormat of
          nffKeyNote :   Index:= NODEIMG_TKN;
          nffKeyNoteZip: Index:= NODEIMG_TKNZIP;
          nffEncrypted : Index:= NODEIMG_ENC;
{$IFDEF WITH_DART}
          nffDartNotes : Index:= NODEIMG_DART;
{$ENDIF}
        end;
      end;

    end;

    Chest.MGRImages.GetBitmap( Index, Glyph.Bitmap );
    SetStatusbarGlyph(Glyph);

  finally
    Glyph.Free;
  end;
end; // SelectStatusbarGlyph


procedure LoadTrayIcon( const UseAltIcon : boolean; DoProcessMessage: boolean= true );
var
  Icon: TIcon;
  UseIcon: integer;
  IconFN: string;
  myFile: TKntFile;
begin
{
 If Application.MainFormOnTaskBar=True -> we need to change the icon of the main form
 If it is False -> we need to change the icon of the Application object

 Application.MainFormOnTaskbar= False by default. If we need to set True
   -> After Application.Initialize and before the main form creation
}

  myFile:= ActiveFile;

  with Form_Main do begin
      UseIcon:= 0;

      if UseAltIcon then
         UseIcon:= 1        // we're capturing clipboard, so indicate this by using the alternate (orange) tray icon
      else
      if assigned(myFile) and (myFile.TrayIconFN <> '' ) then begin
         IconFN:= GetAbsolutePath(myFile.File_Path, myFile.TrayIconFN);
         if FileExists( IconFN ) then
            try
              TrayIcon.Icon.LoadFromFile( IconFN );
              UseIcon:= 2;
            except
            end
         else
            myFile.TrayIconFN := '';
      end;

      if UseIcon in [0, 1] then
         TrayIcon.Icon:= TrayIcon.Icons[UseIcon];

      Application.Icon:= TrayIcon.Icon;   //Application.Icon -> Form_Main.Icon  (MainFormOnTaskbar := True)
      if DoProcessMessage then
         Application.ProcessMessages;
      sleep( 100 );                        // <- Important. Without this line, the icon of the main window changes, but the icon in the taskbar doesn't
  end;


end; // LoadTrayIcon


procedure LoadTabImages( const ForceReload : boolean );
// Typically, we only reload the tab icon file if necessary, i.e.
// if the required set of icons is different from the already loaded
// set. ForceReload tells us to reload anyway.
var
  LoadSuccess : boolean;
begin
  LoadSuccess := false;
  if assigned( ActiveFile ) then begin
     if (( _LOADED_ICON_FILE <> ActiveFile.TabIconsFN ) or ForceReload ) then begin
       if ( ActiveFile.TabIconsFN = '' ) then // means: use KeyNote default
         LoadSuccess := LoadCategoryBitmapsUser( ICN_FN )
       else begin
         if ( ActiveFile.TabIconsFN <> _NF_Icons_BuiltIn ) then
            LoadSuccess := LoadCategoryBitmapsUser( ActiveFile.TabIconsFN );
       end;
       if ( not LoadSuccess ) then
         LoadSuccess := LoadCategoryBitmapsBuiltIn;
     end;
  end
  else begin
     if ( App.opt_NoUserIcons or ( not LoadCategoryBitmapsUser( ICN_FN ))) then
        LoadCategoryBitmapsBuiltIn;
  end;

end; // LoadTabImages


{$IFDEF KNT_DEBUG}
procedure SaveMenusAndButtons;
var
  bl, ml : TStringList;
  comp : TComponent;
  i, cnt : integer;
  fn, s : string;
  tb : TToolbarButton97;
  mi : TMenuItem;
begin
  with Form_Main do begin
     bl := TStringList.Create;
     ml := TStringList.Create;

     try
       try
         bl.Sorted := true;
         ml.Sorted := true;

         cnt := pred( Form_Main.ComponentCount );
         for i := 0 to cnt do begin
           comp := Form_Main.Components[i];
           if comp is TMenuItem then begin
             mi := ( comp as TMenuItem );
             s := format('%s = %s = %s = %s',
                         [mi.Name, mi.Caption, mi.Hint, ShortcutToText( mi.Shortcut ) ] );
             ml.Add( s );
           end
           else
           if comp is TToolbarButton97 then begin
             tb := ( comp as TToolbarButton97 );
             s := Format('%s = %s = %s', [tb.Name, tb.Caption, tb.Hint]);
             bl.add( s );
           end;
         end;

         fn := extractfilepath( application.exename ) + 'buttonnames.txt';
         bl.savetofile( fn );
         fn := extractfilepath( application.exename ) + 'menunames.txt';
         ml.savetofile( fn );

       except
       end;

     finally
       bl.Free;
       ml.Free;
     end;
  end;
end; // SaveMenusAndButtons
{$ENDIF}


procedure EnableCopyFormat(value: Boolean);
var
  i : integer;
  Str: String;
  myCursor: TCursor;
begin
    Form_Main.TB_CopyFormat.Down:= value;

    if value then begin
       Screen.Cursors[crCopyFormat] := LoadCursor(hInstance,'CPFORMAT');
       if (ParaFormatToCopy.dySpaceBefore >= 0) then
          Str:= GetRS(sVCL16)
       else
          Str:= GetRS(sVCL17);
       App.ShowInfoInStatusBar(Format(GetRS(sVCL15), [Str]));
    end
    else begin
       CopyFormatMode:= cfDisabled;
       App.ShowInfoInStatusBar('');
    end;

    with ActiveFile do
       for i := 0 to Folders.Count - 1 do begin
          myCursor:= crDefault;
          if value then
             myCursor:= crCopyFormat;
          Folders[i].Editor.Cursor:= myCursor;
       end;

end;

// ============================
//     TDropTarget
// ============================

constructor TDropTarget.Create(AControl: TWinControl);
begin
  inherited Create;
  FControl := AControl;
end;

function TDropTarget.DragEnter(const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
begin
  Result := S_OK;
end;

function TDropTarget.DragOver(grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
var
  i: integer;

   function GetShiftState: TShiftState;
   begin
     Result := [];
     if (GetKeyState(VK_SHIFT) < 0) then Include(Result, ssShift);
     if (GetKeyState(VK_CONTROL) < 0) then Include(Result, ssCtrl);
     if (GetKeyState(VK_MENU) < 0) then Include(Result, ssAlt);
   end;

  procedure DetermineEffect;      // Determine the drop effect to use if the source is a Virtual Treeview.
  var
    Shift: TShiftState;
  begin
    Shift:= GetShiftState;

    if (Shift = [ssAlt]) or (Shift = [ssCtrl, ssAlt]) then
      dwEffect := DROPEFFECT_LINK
    else
      if Shift = [ssCtrl] then
        dwEffect := DROPEFFECT_COPY
      else
        dwEffect := DROPEFFECT_MOVE;
  end;

begin
  Result := S_OK;
  DetermineEffect;

  pt:= Form_Main.Pages.ScreenToClient(pt);

  i := Form_Main.Pages.GetTabAt(pt.X, pt.Y);
  if i >= 0 then
    App.ActivateFolder(i);
end;

function TDropTarget.DragLeave: HRESULT;
begin
//  Result := S_OK;
end;

function TDropTarget.Drop(const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint; var dwEffect: Longint): HResult; stdcall;
begin
//  Result := S_OK;
//  dwEffect := DROPEFFECT_COPY; // Sets the allowed drag effect
end;

procedure RegisterDropTarget(AControl: TWinControl);
var
  DropTarget: IDropTarget;
begin
  DropTarget := TDropTarget.Create(AControl);
  OleCheck(RegisterDragDrop(AControl.Handle, DropTarget));
end;
procedure UnregisterDropTarget(AControl: TWinControl);
begin
   try
     OleCheck(RevokeDragDrop(AControl.Handle));
   except
   end;
end;

initialization
  SavedChromeScratchFile:= False;

end.
