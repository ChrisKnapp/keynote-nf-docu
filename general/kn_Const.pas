unit kn_Const;

(****** LICENSE INFORMATION **************************************************

 - This Source Code Form is subject to the terms of the Mozilla Public
 - License, v. 2.0. If a copy of the MPL was not distributed with this
 - file, You can obtain one at http://mozilla.org/MPL/2.0/.

------------------------------------------------------------------------------
 (c) 2007-2024 Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain) [^]
 (c) 2000-2005 Marek Jedlinski <marek@tranglos.com> (Poland)

 [^]: Changes since v. 1.7.0. Fore more information, please see 'README.md'
     and 'doc/README_SourceCode.txt' in https://github.com/dpradov/keynote-nf

 *****************************************************************************)


interface
uses
   Winapi.Windows,
   Winapi.ShellAPI,
   Winapi.Messages,
   System.Zip,
   Vcl.Graphics,
   ZLibEx,
   SynGdiPlus,
   knt.RS;


procedure DefineConst;

const
  Program_Name     = 'KeyNote NF';
  Program_Version  = '2.0.0 Beta 8';
  Program_Version_Number  = '2.0.0.8';
  Program_Version_Date    = '23/11/2024';
  Program_License  = 'Free software, Open Source (Mozilla Public License 2.0)';

  Program_URL            = 'https://github.com/dpradov/keynote-nf'; //'http://keynote.prv.pl';
  Program_URL_LatestRelease  = '/releases/latest';
  Program_URL_Donations  = '/tree/master#donations';
  Program_URL_RawFiles = 'https://raw.githubusercontent.com/dpradov/keynote-nf/master';
  Program_URL_History_txt  = '/doc/history.txt';
  Program_URL_API_LatestRelease = 'https://api.github.com/repos/dpradov/keynote-nf/releases/latest';

  Program_Email1  = 'dprado.keynote@gmail.com';
  Program_Email2  = 'marekjed@users.sourceforge.net';
  Program_Credit1 = 'Copyright � 2007-24  Daniel Prado Velasco   (since 1.7.0)';
  Program_Credit2 = 'Copyright � 2000-05  Marek Jedlinski';
  Hint_Support = 'Thanks for using KeyNote NF. You can show your appreciation and support future development by donating!';

  // UniqueAppName_KEYNOTE10   = 'GFKeyNote10';       // Moved to knt_Msgs

const
  URL_Issues = 'https://github.com/dpradov/keynote-nf/issues';

const
  _GF_CLWINDOW = $D0D0D0;
  _GF_NAVY     = clNavy;
  _GF_PURPLE   = clPurple;
  _GF_BLUE     = clBlue;
  _GF_BLACK    = clBlack;


{ Experimental stuff for RichEdit v.3 }
const
  EM_GETZOOM = WM_USER+224;
  EM_SETZOOM = WM_USER+225;
  EM_SETTYPOGRAPHYOPTIONS	= WM_USER + 202;
  TO_ADVANCEDTYPOGRAPHY = 1;

const
  // various global declarations
  _IS_OLD_KEYNOTE_FILE_FORMAT  : boolean = false;
  _USE_OLD_KEYNOTE_FILE_FORMAT : boolean = false;
  _TEST_KEYNOTE_FILE_VERSION   : boolean = true;
  _ALLOW_VCL_UPDATES           : boolean = false;
  _ALLOW_TREE_FONT_COLOR       : boolean = true;
  _OTHER_INSTANCE_HANDLE       : hwnd = 0;
  _SAVE_RESTORE_CARETPOS       : boolean = false;
  _DEFAULT_KEY_REPLAY_DELAY    : integer = 250; // miliseconds!!
  _LISTBOX_ALT_COLOR           : TColor = clInfoBk;

const
  _PLUGIN_FOLDER     = 'plugins\';
  _MACRO_FOLDER      = 'macros\';
  _TEMPLATE_FOLDER   = 'templates\';
  _LANGUAGE_FOLDER   = 'Lang\';
  _DEFAULT_PROFILE_FOLDER   = 'Profiles\Default\';
  _HELP_PROFILE_FOLDER   = 'Profiles\Help\';
  _KNT_HELP_FILE = 'Help\KeyNoteNF_Help.knt';
  _KNT_HELP_FILE_NOTE_ID = 8;
  _KNT_HELP_FILE_NOTE_WHATSNEW_ID = 14;
  _KNT_HELP_FILE_DEFAULT_NODE_ID = 2;   // Welcome to KeyNote NF
  _KNT_LAUNCHER = 'kntLauncher.exe';
  _KNT_HELP_TITLE = 'KeyNote NF Topics';

const
  // help file topics
  _HLP_KNTFILES      = 70;
  // _HELP_DRAGDROP     = ??;

const
  TOKEN_NEWLINE = '\n';
  TOKEN_TAB     = '\t';

const
  _REMOVABLE_MEDIA_VNODES_DENY  = 0;
  _REMOVABLE_MEDIA_VNODES_WARN  = 1;
  _REMOVABLE_MEDIA_VNODES_ALLOW = 2;

const
  NFHDR_ID           = 'GFKNT'; // KeyNote file header ID
  NFHDR_ID_OLD       = 'GFKNX'; // KeyNote token text file header ID
  NFHDR_ID_ENCRYPTED = 'GFKNE'; // encrypted KeyNote file header ID
  NFHDR_ID_COMPRESSED = 'GFKNZ'; // compressed KeyNote file header ID
  NFILEVERSION_MAJOR = '3';     // and version numbers
  // NFILEVERSION_MAJOR = '1';     // non-tree version ID, obsolete
  NFILEVERSION_MINOR = '0';     
 
 // 2.1 : Since version 1.9.3.1: Use of GID as note identifier, with a new default internal Knt Links format, based on GIDs
 // 3.0 : New major version associated to an important rework: TNote, TNoteNode, TNoteEntry, ...

const
  FLAGS_STRING_LENGTH  = 24; // can store up to 24 booleans
  DEFAULT_FLAGS_STRING = '000000000000000000000000';

type
  TFlagsString = string[FLAGS_STRING_LENGTH];

const // IDs for older file versions
  NFILEVERSION_MAJOR_NOTREE = '1'; // MAJOR version number for new format files that do NOT have trees
  NFILEVERSION_MAJOR_OLD    = '1'; // version numbers for old-style file format
  NFILEVERSION_MINOR_OLD    = '0'; // DO NOT CHANGE!

const
  _NF_AID = '!'; // Application ID
  _NF_DCR = 'C'; // Date Created
  _NF_CNT = '*'; // Count of notes
  _NF_FCO = '?'; // File comment
  _NF_FDE = '/'; // File description
  _NF_ACT = '$'; // Active note
  _NF_ReadOnlyOpen  = 'R'; // open file as read-only
  _NF_ShowTabIcons  = 'I'; // per-FILE setting
  _NF_ClipCapFolder   = 'L'; // index of ClipCapFolder
  _NF_TrayIconFile  = 'T'; // tray icon file to load
  _NF_TabIconsFile  = 'F'; // tab icons file to load
  _NF_FileFlags     = '^'; // "flags" string (24 boolean values)

const
  _NF_Icons_BuiltIn = '@';


const
  BOOLEANSTR            : array[false..true] of AnsiChar = ( '0', '1' );
  DEF_INDENT_LEN        = 12;
  MIN_COMBO_LENGTH      = 15;
  DEF_TAB_SIZE          = 4;  // default tab size
  DEF_UNDO_LIMIT        = 32; // undo levels
  TABNOTE_NAME_LENGTH   = 50; // max name length for the note title (ie Tab caption)
  TREENODE_NAME_LENGTH  = 255; // max name length for a tree node
  TREENODE_NAME_LENGTH_CAPTURE  = 60; // max name length for a tree node, when capturing from Clipboard or from a selection (new node from selection)
  MAX_COMMENT_LENGTH    = 80;
  MAX_FILENAME_LENGTH   = 127;
  MAX_BOOKMARKS         = 9; // ZERO-based!
  DEFAULT_CAPACITY      = 255; // default capacity for RTF Lines property (to speed up loading)
  DEFAULT_NEW_FOLDER_NAME : string = sINFDefaults1; // default name for new folders
  DEFAULT_NEW_NOTE_NAME : string = sINFDefaults2; // default name for new tree nodes
  DEFAULT_NODE_IMGINDEX : integer = 0;
  TRRENODE_SELIDX       = 4;
  MIN_PASS_LEN          = 5; // minimum length of file access passphrase
  MAX_BACKUP_LEVEL      = 9; // max number of backup files to keep
  MAX_NAVHISTORY_COUNT  = 100; // number of navigation history locations to maintain

const
  _TokenChar            = '%';

const
  // tokens for new tree nodes
  NODEINSDATE           = '%D'; // expands to current date
  NODEINSTIME           = '%T'; // expands to current time
  NODECOUNT             = '%C'; // expands to count of nodes
  NODELEVEL             = '%L'; // expands to node's level
  NODEABSINDEX          = '%A'; // expands to node's absolute index
  NODEINDEX             = '%I'; // expands to node's index
  NODEPARENT            = '%P'; // expands to node's parent's name
  NODENOTENAME          = '%N'; // expands to name of current note
  NODEFILENAME          = '%F'; // expands to current file name

const
  // tokens for exporting to text and rtf
  EXP_FOLDERNAME        = 'N';   // Note folder
  EXP_NODENAME          = 'D';
  EXP_NODELEVEL         = 'L';
  EXP_NODEINDEX         = 'I';
  EXP_FILENAME          = 'F';
  EXP_NODELEVELSYMB_INC = '<';
  EXP_NODELEVELSYMB_DEC = '>';
  EXP_LINE_BREAK        = '^';
  EXP_RTF_HEADING       = _TokenChar + 'HEADING';

  _DefaultNodeHeading = '--- ' + _TokenChar + EXP_NODENAME + ' ---';
  _DefaultNoteHeading = '=== ' + _TokenChar + EXP_FOLDERNAME + ' ===';



const

  _Default_FolderHeadingTpl =   AnsiString(
    '{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset1{\*\fname Tahoma;}Tahoma;}}' + #13#10 +
    '{\colortbl ;\red96\green96\blue96;}' + #13#10 +
    '\viewkind4\uc1\pard\cf1\f0\fs32\par' + #13#10 +
    '\b %HEADING\par' + #13#10 +
    '\b0\par' + #13#10 +
    '}');
  _Default_NodeHeadingTpl =  AnsiString(
    '{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset1{\*\fname Tahoma;}Tahoma;}}' + #13#10 +
    '{\colortbl ;\red96\green96\blue96;}' + #13#10 +
    '\viewkind4\uc1\pard\cf1\f0\fs24\par' + #13#10 +
    '\ul\b %HEADING\ulnone\b0\par' + #13#10 +
    '\par' + #13#10 +
    '}');

const
  _VIRTUAL_NODE_ERROR_CHAR = '?';
  _ZOOM_STEP = 10;
  _ZOOM_MIN = 5;

const
{
   *1  If source URL will not be shown, then it will also be ignored the text included between the enclosure delimiters.
       It is possible to define several fragments enclosed with that delimiters.
       More info in: 'Improvements on Clip Web and Clipboard Capture #532' (https://github.com/dpradov/keynote-nf/issues/532)
   *2  It will try to get the title for the URL with WebBrowser (offline, using cache), without time limit (6 seconds, for security..)
   *3  As *2, but trying only for a limited time (for now 2 seconds)

   Normally the title will be figured out in very short time, but in the event that the delay is annoying, it is possible to
   use %s instead of %S, to wait for 2 seconds as much. Or even, to use %U, to not try to get Title.
   Besides, KeyNote will cache the last URLs/Titles (20/10) to agilize the paste in case you need to paste several times,
   possibly intercalating from several pages

   *4  Only if URL will not visible, because a hyperlink will be created showing the title, and if the server/domain of the URL
       is not contained in the title, then that server domain will be shown, in square brackets. Some examples:

      'https://www.teoria.com/en/tutorials/functions/intro/03-dom-sub.php', 'Harmonic Functions : The Dominant and Subdominant'  => [teoria.com]
      'https://musicnetmaterials.wordpress.com/analisis-musical/', 'An�lisis musical | Musicnetmaterials'                        => ''
      'https://stackoverflow.com/questions/1549145/case-insensitive-pos', 'delphi - case insensitive Pos - Stack Overflow'       => ''
      'https://martinfowler.com/eaaCatalog/', 'Catalog of Patterns of Enterprise Application Architecture'                       => [martinfowler.com]
      'https://en.wikipedia.org/wiki/Johann_Sebastian_Bach', 'Johann Sebastian Bach - Wikipedia'                                 => ''
      'https://www.youtube.com/watch?v=r0R6gMw2s44', 'El C�rculo de Quintas: Una explicaci�n detallada | Versi�n 2.0'            => [YouTube]

   *5 Delimits a divider string for the second and following consecutive paste from the same page (same URL). 
      KNT will remember the last URL from wich pasted in the current [Clipboard Capture] session
}

  // tokens for clipboard capture separator line
  CLIPDIVCHAR           = '^';  // replaced with 1 line break
  CLIPDATECHAR          = NODEINSDATE; // inserts date
  CLIPTIMECHAR          = NODEINSTIME; // inserts time
  CLIPSOURCEDELIMITER   = '%|';   // Encloses source (optional)                    *1
  CLIPSOURCE            = '%S';   // insert Source URL (with title)                *2
  CLIPSOURCE_LIMITED    = '%s';   // insert source URL (with title, limited time)  *3
  CLIPSOURCE_ONLY_URL   = '%U';   // insert source URL (without title)
  CLIPSOURCE_DOMAIN     = '%d';   // insert Source server/domain                   *4
  CLIPSECONDDIV         = '%%';   // delimits divider for 2nd+ (same URL)          *5



const
  // tokens for the MailOptions.FirstLine string
  // (placed as first line of the email sent from keyNote)
  // These tokens may also be used in the Subject line of the email
  MAILFILENAME          = '%F'; // expands to name of attached file (not: KeyNote file, because that is irrelevant)
  MAILNOTENAME          = '%N'; // expands to name of current note
  MAILKEYNOTEVERSION    = '%V'; // expands to KeyNote plug
  MAILNOTECOUNT         = '%C'; // expands to number of notes being sent

const
  // Used on files with NFILEVERSION_MAJOR < 3
  _NF_TabFolder       = '%';    // end-of-record (new simple folder begins)
  _NF_RTF             = '%:';   // end of note header; RTF data follows
  _NF_TreeFolder      = '%+';   // tree folder begins
  _NF_TRN             = '%-';   // Tree node begins (many tree nodes within a single note)

  // Used on files with NFILEVERSION_MAJOR >= 3
  _NumNotes = 'N:';       // Number of notes
  _NF_Note = '%*';        // TNote begins
  _NF_NEntry = '%.';      // TNoteEntry begins
  _NF_NEntry_Beta = '%�';      // � is not an adequate character (see https://github.com/dpradov/keynote-nf/discussions/739#discussioncomment-11140153)
  _NF_Folder = '%+';      // TKntFolder begins
  _NF_TxtContent  = '%>'; // end of TNoteEntry header; Plain Text data follows
  _NF_RTFContent  = '%:'; // end of TNoteEntry header; RTF data follows
  _NF_NNode = '%-';       // TNoteNode begins
  _NumNNodes = 'n:';      // Number of note nodes (in folder)



  _NF_EOF             = '%%';   // end-of-file (last line in file)
  _NF_COMMENT         = '#';    // comment, but this is really used for file header information
  _NF_WARNING         = _NF_COMMENT + ' This is an automatically generated file. Do not edit.';
  _NF_PLAINTEXTLEADER = ';';
  _NF_StoragesDEF     = '%S';
  _NF_StorageMode     = 'SM';
  _NF_ImagesDEF       = '%I';
  _NF_IDNextImage     = 'II';
  _NF_EmbeddedIMAGES  = '%EI';
  _NF_Bookmarks       = '%BK';
  _NF_Bookmark        = 'BK';


const
  _SHORTDATEFMT  = 'dd-MM-yyyy'; // all these are only internal defaults
  _LONGDATEFMT   = 'd MMMM yyyy';
  _LONGTIMEFMT   = 'HH:mm:ss';
  _DATESEPARATOR = '-';
  _TIMESEPARATOR = ':';

  {
   Old Knt files have been using _LONG_DATETIME_TOFILE format when serializing creation date of file and folders
   Will keep using that format for those objects, to maintain compatibility.
   But for notes (last modified) and note entry (created) dates, new metadata added from format 3.0 of KNT,
   will use a more compact format, as there will be much more objects serialized
   Ex.  '05-10-2024 08:50:48'   => '0510240850'

   The compact format will also be used with alarms dates serialized
  }
  _LONG_DATETIME_TOFILE    = _SHORTDATEFMT + ' ' + _LONGTIMEFMT;
  _COMPACT_DATETIME_TOFILE = 'ddMMyyHHmm';

  _CRLF          = #13#10;


const
  _NODE_COLOR_COUNT = 8; // times 2, dark and bright shades
  _NODE_COLORS_DARK : array[0.._NODE_COLOR_COUNT] of TColor = (
    clDefault, // 0
    clBlack,   // 1
    clMaroon,  // 2
    clGreen,   // 3
    clOlive,   // 4
    clNavy,    // 5
    clPurple,  // 6
    clTeal,    // 7
    clGray     // 8
  );

  _NODE_COLORS_LIGHT : array[0.._NODE_COLOR_COUNT] of TColor = (
    clDefault, // 9 (unused!)
    clSilver,  // 10
    clRed,     // 11
    clLime,    // 12
    clYellow,  // 13
    clBlue,    // 14
    clFuchsia, // 15
    clAqua,    // 16
    clWhite    // 17
  );

{$IFDEF WITH_DART}
const
  // Dart Notes specific defines
  _DART_STOP  = #7;
  _DART_ID    = 'Notes';
  _DART_VER   = '1670';
  _DART_VEROK = '871';
{$ENDIF}

const
  // indices for tree node icons
  ICON_FOLDER          = 0;
  ICON_BOOK            = 2;
  ICON_NOTE            = 4;
  ICON_VIRTUAL         = 6;
  ICON_VIRTUAL_KNT_NODE = 8;

  {
  ICON_VIRTUALTEXT     = 6; // same as ICON_VIRTUAL
  ICON_VIRTUALRTF      = 8;
  ICON_VIRTUALHTML     = 10;
  }
  ICON_VIRTUALIELOCAL  = 8;  { not implemented }
  ICON_VIRTUALIEREMOTE = 10; { not implemented }

type
  TVirtualMode = (
    vmNone, vmText, vmRTF, vmHTML, vmIELocal, vmIERemote, vmKNTNode
  );


const
  // menu item tags for dynamically associated commands
  ITEM_STYLE_APPLY = 90;
  ITEM_STYLE_RENAME = 91;
  ITEM_STYLE_DELETE = 92;
  ITEM_STYLE_REDEFINE = 93;
  ITEM_STYLE_DESCRIBE = 94;

  ITEM_TAG_TRIMLEFT  = 1;
  ITEM_TAG_TRIMRIGHT = 2;
  ITEM_TAG_TRIMBOTH  = 3;


type

  // WITH_DART: From now, DartNotes format is unsupported by default

  // supported save/load formats
  TKntFileFormat = (
    nffKeyNote, nffKeyNoteZip, nffEncrypted {$IFDEF WITH_DART}, nffDartNotes{$ENDIF}
  );

type
{  // Obsolete
  TNoteType = (
    ntRTF, // standard RichEdit control
    ntTree // tree panel plus richedit control (tree-type note)
  );
}
  TNextBlock = (
    nbNotes,      // Used on files with NFILEVERSION_MAJOR >= 3
    nbRTF,        // = ntRTF                  (old knt files)
    nbTree,       // = ntTree                 (= Folder)
    nbImages,     // = Images Definition
    nbBookmarks
  );
  //TNoteNameStr = String[TABNOTE_NAME_LENGTH];
  TNoteNameStr = string;

type
  TNavDirection = (
    navUp, navDown, navLeft, navRight
  );

type
  TSearchMode = (
    smPhrase, smAll, smAny
  );

type
  TSearchScope = (
    ssOnlyNodeName, ssOnlyContent, ssContentsAndNodeName
  );

type
  TSearchCheckMode = (
    scOnlyNonChecked, scOnlyChecked, scAll
  );


type
  TPasteNodeNameMode = (
    pnnClipboard, pnnDate, pnnTime, pnnDateTime, pnnSelection
  );

type
  TTreeSelection = (
    tsNode, tsSubtree, tsCheckedNodes, tsFullTree
  );

const
  TREE_SELECTION_NAMES : array[TTreeSelection] of string = (
    sINFTreeSel1, sINFTreeSel2, sINFTreeSel3, sINFTreeSel4
  );

type
  TExportFmt = (
    xfPlainText, xfRTF, xfHTML,
    xfKeyNote,
    xfTreePad
  );

const
  EXPORT_FORMAT_NAMES : array[TExportFmt] of string = (
    sINFExptFrmt1,
    sINFExptFrmt2,
    'HTML',
    sINFExptFrmt3,
    'TreePad'
  );

type
  TExportSource = (
    expCurrentNote, expAllNotes, expSelectedNotes
  );

type
  TNodeIconKind = (
    niNone, niStandard, niCustom 
  );

const
  NODE_ICON_KINDS : array[TNodeIconKind] of string = (
    sINFIconKind1, sINFIconKind2, sINFIconKind3
  );

{
const
  KNT_URL_PREFIX = 'knt://'; NOT USED
}

type
  TLinkType = (
    lnkURL, lnkEmail, lnkFile, lnkKNT
  );
  // IMPORTANT: lnkKNT MUST be LAST in the sequence, i.e.
  // must be equal to "high( TLinkType )"
  // kn_Hyperlink.pas relies on it while creating the form controls

const
  LINK_TYPES : array[TLinkType] of string = (
    sINFLinkType1,
    sINFLinkType2,
    sINFLinkType3,
    sINFLinkType4
  );


const
  KNTLOCATION_MARK_OLD = '?'; // old style links to KNT locations: use folder and note names
  KNTLOCATION_MARK_NEW = '*'; // new style links to KNT locations: use folder and note IDs
  KNTLOCATION_MARK_NEW2 = '<'; // newer style links to KNT locations: use note GIDs

  LINK_RELATIVE_SETUP = '>>';  // Ex.:  file:///>>Profiles\Profiles.txt

type
  TKntLinkFormat = (
    lfOld, lfNew, lfNew2, lfNone
  );

  (*
    *1
    The hidden strings used by KNT will have a variable length, but will normally have a maximum of the form maximum: HT999999H
    where H:KNT_RTF_HIDDEN_MARK_CHAR, T: Type (B:Bookmark, T:Tag, ...)
    A target bookmark will normally be something like HB5H, HB15H, ... In this second example it is assumed that there would be
    at least 15 different destinations of internal KNT links in the node.
    But we can use the format to record other hidden information to process, such as perhaps a tag to associate with a
    text selection. If we save the ID of the tag, it would not be normal for us to go from an ID > 999999.
    In any case, the objective of this constant is to identify the presence of the character that we use as the beginning of the
    the hidden string, in a -we assume- non-hidden way, by not finding the closing character at an expected distance.
    We could make sure that the character is really hidden by asking the RichEdit control, but since it's a character
    totally unusual to find in a text, we will follow this criterion in principle.

   Example: \v\'11B5\'12\v0   In Delphi, debugging, it is shown as '#$11'B5'#$12' (counted '#$11' or '#$12' as one character)
   Although we can write RTF in an equivalent way ( {\v\'11B5\'12} ), the RichEdit control will translate it in the old way, with \v and \v0

   *2
   With image management and conversion between storage modes, I can end up saving to the nodes (or notes) stream without going
   through the editor. In those cases, if I generate as RTF {\v ...} I should take it into account when having to eliminate hidden
   characters (for example when converting to smEmbRTF), since I could have RTFs in that format and others like \v. .. \v0, which
   is how the control converts them. To avoid all these problems I will insert directly in the last way, with \v and \v0
  *)

const

  KNT_RTF_HIDDEN_MARK_L = '\''11';
  KNT_RTF_HIDDEN_MARK_R = '\''12';
  KNT_RTF_HIDDEN_MARK_L_CHAR = Chr(17);    // 17 ($11): DC1 (Device Control 1)
  KNT_RTF_HIDDEN_MARK_R_CHAR = Chr(18);    // 18 ($12): DC2 (Device Control 2)
  KNT_RTF_HIDDEN_BOOKMARK = 'B';
  KNT_RTF_HIDDEN_Bookmark09 = 'b';       // Used with 9 bookmarks set with Search|Set Bookmark
  KNT_RTF_HIDDEN_IMAGE = 'I';
  KNT_RTF_HIDDEN_MAX_LENGHT_CHAR = 10;         // *1
  (* *2
  KNT_RTF_BMK_HIDDEN_MARK = '{\v' + KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_BOOKMARK + '%d'+ KNT_RTF_HIDDEN_MARK_R + '}';
  KNT_RTF_IMG_HIDDEN_MARK = '{\v' + KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_IMAGE    + '%d'+ KNT_RTF_HIDDEN_MARK_R + '}';
  *)
  KNT_RTF_BMK_HIDDEN_MARK = '\v' + KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_BOOKMARK + '%d'+ KNT_RTF_HIDDEN_MARK_R + '\v0';
  KNT_RTF_Bmk09_HIDDEN_MARK = '\v' + KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_Bookmark09 + '%d'+ KNT_RTF_HIDDEN_MARK_R + '\v0';
  KNT_RTF_IMG_HIDDEN_MARK = '\v' + KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_IMAGE    + '%d'+ KNT_RTF_HIDDEN_MARK_R + '\v0';
  KNT_RTF_IMG_HIDDEN_MARK_CONTENT = KNT_RTF_HIDDEN_MARK_L + KNT_RTF_HIDDEN_IMAGE    + '%d'+ KNT_RTF_HIDDEN_MARK_R;

  KNT_RTF_IMG_HIDDEN_MARK_CHAR =    KNT_RTF_HIDDEN_MARK_L_CHAR + KNT_RTF_HIDDEN_IMAGE + '%d' + KNT_RTF_HIDDEN_MARK_R_CHAR;

  {
     \v\'11T999999\'12\v0    -> 20 max (If necessary we can increase it)
	   \'11T999999\'12         -> 15 max
  }
  KNT_RTF_HIDDEN_MAX_LENGHT = 20;
  KNT_RTF_HIDDEN_MAX_LENGHT_CONTENT = 15;

  KNT_IMG_LINK_PREFIX = '{\field{\*\fldinst{HYPERLINK "img:';
  //KNT_IMG_LINK = KNT_IMG_LINK_PREFIX + '%d,%d,%d"}}{\fldrslt{\ul\cf0 %s}}}';    // {\field{\*\fldinst{HYPERLINK "img:ImgID,WGoal,HGoal"}}{\fldrslt{\ul\cf1 textOfHyperlink}}}
  KNT_IMG_LINK = KNT_IMG_LINK_PREFIX + '%d,%d,%d"}}{\fldrslt {%s}}}';    // If used {\fldrslt{\ul\cf0 %s} it ends up with something like {\fldrslt{\ul\cf0\cf0\ul %s}. (Idem with \ul\cf1 .. \cf1\ul etc)



type
  TKNTURL = (
    // urlKNT, UNUSED custom knt:// URL scheme which we use for internal keynote links (only used with version 3 of riched20.dll)
    urlUndefined,
    urlFile, urlHTTP, urlHTTPS, urlFTP, urlMailto,
    urlTelnet, urlNews, urlNNTP, urlGopher, urlWais, urlProspero,
    urlNotes, urlCallto, urlOnenote, urlOutlook, urlTel, urlWebcal,
    urlKNTImage,
    urlOTHER
  );

const
  KNT_URLS : array[TKNTURL] of AnsiString = (
    '',
    {'knt:', } 'file:', 'http:', 'https:', 'ftp:', 'mailto:',
    'telnet:', 'news:', 'nntp:', 'gopher:', 'wais:', 'prospero:',
    'notes:', 'callto:', 'onenote:', 'outlook:', 'tel:', 'webcal:',
    'img:',
    '????:'
  );

type
  // supported enbcryption algorithms.
  // KeyNote uses DCPCrypt library by David Barton
  // http://www.devarchive.com/DCPcrypt.html
  // (do a web search for "DCPCrypt" if this link goes 404)
  TCryptMethod = (
    tcmBlowfish, tcmIdea
  );

const
  CRYPT_METHOD_NAMES : array[TCryptMethod] of string = (
    'Blowfish', 'Idea'
  );

const
  ID_STR_LENGTH = 5; // GFKNT, GFKNX, GFKNE, GFKNZ, Notes

type
  // In encrypted files, this is saved in cleartext
  TKntFileVersion = packed record
    ID : array[1..ID_STR_LENGTH] of AnsiChar;
    Major, Minor : AnsiChar;
  end;

type
  // In encrypted files, this is saved in cleartext
  TEncryptedFileInfo = packed record
    Method : TCryptMethod;
    DataSize : integer;
    NoteCount : integer;
  end;

type
  TCommentStr = String;

type
  TNodeInsertMode = (
    tnTop,       //                   -> AddChild(nil)
    tnAddAbove,  // Add Above         -> InsertNode, TVTNodeAttachMode.amInsertBefore   - insert node just before destination (as sibling of destination)
    tnAddChild,  // Add child         -> AddChild(Node) - Adds a node as the last child of the given node.
    tnAddBelow,  // Add Below         -> InsertNode, TVTNodeAttachMode.amInsertAfter    - insert node just after destionation (as sibling of destination)
    tnAddLast    // Add Last sibling  -> AddChild(ParentNode) - Adds a node as the last child of the given node.
  );

type
  TTreeExpandMode = (
    txmFullCollapse, // show tree fully collapsed
    txmActiveNode, // expand only the node that was last active
    txmTopLevelOnly, // expand only top level nodes
    txmExact, // show nodes expanded or collapsed exactly as saved
    txmFullExpand // show tree fully expanded
  );

const
  TREE_EXPAND_MODES : array[TTreeExpandMode] of string = (
    sINFExpnd1,
    sINFExpnd2,
    sINFExpnd3,
    sINFExpnd4,
    sINFExpnd5
  );



type
  TImagesStorageMode = (smEmbRTF, smEmbKNT, smExternal, smExternalAndEmbKNT);  // Emb: Embedeed

const
  IMAGES_STORAGE_MODE : array[TImagesStorageMode] of string = (
     sINFImgSM1,
     sINFImgSM2,
     sINFImgSM3,
     sINFImgSM4
  );


type
  TImagesExternalStorage =  (issFolder, issZIP );

const
   EXTERNAL_STORAGE_TYPE : array[TImagesExternalStorage] of string = (
     sINFImgExtSt1,
     sINFImgExtSt2
   );

type
  TImagesStorageModeOnExport = (smeEmbRTF, smeEmbKNT, smeNone);

const
  IMAGES_STORAGE_MODE_ON_EXPORT : array[TImagesStorageModeOnExport] of string = (
     sINFImgSM1,
     sINFImgSM2,
     sINFImgSM5
  );


type
  TZipCompressionSelec = (
    zcsStored,
    zcsDeflate,
    zcsDeflate64
  );

const
  ZIP_COMPRESSION_SELEC : array[TZipCompressionSelec] of string = (
    'Stored',
    'Deflate',
    'Deflate64'
  );


type
  TImagesMode = (imImage, imLink);
  TImageIDs = Array of integer;

const
 IMAGE_FORMATS : array[TImageFormat] of string = (
    'gif',
    'png',
    'jpg',
    'bmp',
    'tif',
    'wmf',
    'emf',
    '*'
  );


type
  TRTFImageFormat    =  (rtfwmetafile8, rtfEmfblip, rtfPngblip, rtfJpegblip );

const
  RTF_IMAGE_FORMATS : array[TRTFImageFormat] of AnsiString = (
    'wmetafile8',
    'emfblip',
    'pngblip',
    'jpegblip'
  );

type
  TImageFormatFromClipb = (imcPNG, imcJPG);

const
  IMAGE_FORMATS_FROM_CLIPB : array[TImageFormatFromClipb] of string = (
    'png',
    'jpg'
  );


type
  TImageFormatToRTF  =  (ifWmetafile8, ifAccordingImage );

  TPixelFormatSelec = (
    pfs15bit,
    pfs24bit,
    pfs32bit
  );

const
  PIXEL_FORMAT_SELEC : array[TPixelFormatSelec] of string = (
    '15 bit',
    '24 bit',
    '32 bit'
  );


{
TCtrlUpDownMode: Defines behaviour of Ctrl+Up/Down shortcut keys:

 cudDefault:         Moves the cursor to the beginning of the previous (up) or the next (down) paragraph
 cudShiftLine:       Shift the entre document one line down or up. The cursor will be in the same place.
 cudShiftScrollbar:  Smoothly move the scroll bar vertically. The cursor won't change.
}

type
   TCtrlUpDownMode = (cudDefault, cudShiftLine, cudShiftScrollbar);


const
  CTRL_UP_DOWN_MODE : array[TCtrlUpDownMode] of string = (
     sINFCtrlUD1,
     sINFCtrlUD2,
     sINFCtrlUD3
  );


type
  TClipNodeNaming = (
    clnDefault, clnClipboard, clnDateTime
  );

const
  CLIP_NODE_NAMINGS : array[TClipNodeNaming] of string = (
    sINFClipNdNam1,
    sINFClipNdNam2,
    sINFClipNdNam3
  );


type
  TClipPlainTextMode = (
    clptPlainText,        // paste without any formatting
    clptAllowHyperlink,   // paste without any formatting, just allowing hyperlinks
    clptAllowFontStyle,   // Allow only font styles like bold and italic, e.g
    clptAllowFont         // disallow paragraph formatting, but allow font formatting
  );

const
  CLIP_PLAIN_TEXT_MODE : array[TClipPlainTextMode] of string = (
    sINFClipPlainTxt1,
    sINFClipPlainTxt2,
    sINFClipPlainTxt3,
    sINFClipPlainTxt4
  );


type
   TCopyFormatMode = (cfDisabled, cfEnabled, cfEnabledMulti );

const
   crCopyFormat = 1;


const
  // TREEPAD export/import constants
  _TREEPAD_HEADER_TXT = '<Treepad version 2.7>';
  _TREEPAD_HEADER_RTF = '<Treepad version 3.1>';
  _TREEPAD_MAGIC      = '5P9i0s8y19Z';
  _TREEPAD_NODE       = '<node>';
  _TREEPAD_ENDNODE    = '<end node> ' + _TREEPAD_MAGIC;
  _TREEPAD_TXTNODE    = 'dt=text';
  _TREEPAD_RTFNODE    = 'dt=RTF';

type
  TFocusMemory = ( focNil, focRTF, focTree );

type
  TDropFileAction = (
    factUnknown,
    factOpen,
    factExecute, // macros and plugins only
    factMerge,
    factHyperlink,
    factImportAsFolder,
    factImportAsNode,
    factMakeVirtualNode,
    factInsertContent
    {$IFDEF WITH_IE}
    ,
    factMakeVirtualIENode
    {$ENDIF}

  );
  TDropFileActions = array[TDropFileAction] of boolean;

const
  FactStrings : array[TDropFileAction] of string = (
    '',
    sINFDrop1,
    sINFDrop2,
    sINFDrop3,
    sINFDrop5,
    sINFDrop4,
    sINFDrop6,
    sINFDrop7,
    sINFDrop9
    {$IFDEF WITH_IE}
    ,
    sINFDrop8
    {$ENDIF}

  );


type
  THTMLImportMethod = (
    htmlSource, htmlSharedTextConv, htmlMSWord, htmlIE
  );

  THTMLExportMethod = (
    htmlExpMicrosoftHTMLConverter, htmlExpMSWord
  );


type
  TDartNotesHdr = packed record
    BlockLen : integer;
    ID : array[1..ID_STR_LENGTH] of char;
    TabCount : integer; // NOT IN DART NOTES FILE HEADER!
    Ver : integer;
    MinVer1 : integer;
    MinVer2 : integer;
    LastTabIdx : integer;
  end;

type
  TNoteChromeIniStr = record
    Section,
    BGColor,
    BGHiColor,
    FontCharset,
    FontColor,
    FontHiColor,
    FontHiStyle,
    FontName,
    FontSize,
    FontStyle : string;
  end;

const
  NoteChromeIniStr : TNoteChromeIniStr = (
    Section : 'NoteChrome';
    BGColor : 'BGColor';
    BGHiColor : 'BGHiColor';
    FontCharset : 'FontCharset';
    FontColor : 'FontColor';
    FontHiColor : 'FontHiColor';
    FontHiStyle : 'FontHiStyle';
    FontName : 'FontName';
    FontSize : 'FontSize';
    FontStyle : 'FontStyle'
  );

const
  // Tokens for all Folders
  //--------------------------------
  //_AutoIndent = 'AI';       // Unused
  //_BookMarks = 'BM';        // Unused
  _CHBGColor = 'BG';
  _CHBGHiColor = 'BH';
  _CHFontCHarset = 'CH';
  _CHFontColor = 'FC';
  _CHFontHiColor = 'FH';
  _CHFontHiStyle = 'SH';
  _CHFontName = 'FN';
  _CHFontSize = 'FS';
  _CHFontStyle = 'ST';
  _CHLanguage = 'LN';
  _DateCreated = 'DC';
  _ImageIndex = 'II';
  //_Info = 'NI';             // Unused
  _LineCount = 'LC';
  _Lines = 'LI';
  _FolderKind = 'NK';
  _FolderName = 'NN';
  _FolderID = 'ID';
  //_PosX = 'CX';             // Unused
  //_POSY = 'CY';             // Unused
  _TabIndex = 'TI';
  _TabSize = 'TS';
  _Flags = 'FL';

  // Tokens for folders (tree folders..)
  _SelectedNode = 'SN';
  _TreeWidth = 'TW';
  _TreeMaxWidth = 'TM';
  _DefaultNoteName = 'EN';
  _CHTRBGColor = 'TB';
  _CHTRFontCharset = 'TH';
  _CHTRFontColor = 'TC';
  _CHTRFontName = 'TN';
  _CHTRFontSize = 'TZ';
  _CHTRFontStyle = 'TY';


  (* UNUSED, replaced by _Flags: *)
  {_ReadOnly = 'RO';
  _WordWrap = 'WW';
  _URLDetect = 'UD';
  _Visible = 'NV';
  _UseTabChar = 'UT';

  _AutoNumberNodes = 'AN';
  _ShowCheckBoxes = 'SC';
  _ShowIcons = 'SI';
  }

const
  // Tokens for notes
  _NoteName = 'ND';
  _NoteGID = 'GI';
  _NoteAlias = 'AL';
  _NoteState = 'Ns';
  _LastModified = 'LM';
  _NoteSelEntry = 'SE';
  _NEntrySelStart = 'SS';
  _NoteResources = 'NR';
  _VirtualFN = 'VF';
  _RelativeVirtualFN = 'RV';

  // Tokens for note entries
  _NEntryID = 'id';
  _NEntryState = 'NS';
  //DC=21-05-2003 15:25:25       Date and time the entry was created

  // Tokens for note nodes (in folder)
  //GI=2  Optional: Global ID (GID) of the note referenced by the Node.
  _NodeGID = 'gi';
  _NodeID = 'DI';
  _NodeLevel = 'LV';
  _NodeState = 'ns';
  _NodeEditorBGColor = 'BC';
  _NodeColor = 'HC';
  _NodeBGColor = 'HB';
  _NodeFontFace = 'FF';
  _NodeImageIndex = 'IX';
  _NodeAlarm = 'NA';        // [dpv]

  _VirtualNode = 'VN';      // Replaced by normal "linked" nodes (TNoteNode) since NFILEVERSION_MAJOR >= 3
  _NodeFlags = 'NF';        // => NFILEVERSION_MAJOR < 3


const
  // special FlagsStr constant characters
  _FlagHasNodeColor = 'N';
  _FlagHasNodeBGColor = 'B';
  _FlagHasNodeColorBoth = 'A';
  _FlagHasNodeColorNone = '0';

const
  // tokens related to image processing
  _StorageDEF = 'SD';
  _ImageDEF   = 'PD';      // Picture definition
  _EmbeddedImage = 'EI';
  _END_OF_EMBEDDED_IMAGE = '##END_IMAGE##';


const
  alph13 = AnsiString('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz');
  alph13UP = AnsiString('ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ');

{$IFDEF WITH_IE}
type
  TIECommand = (
    ieNone, ieNavigate, ieStop, ieRefresh,
    ieGoHome, ieGoBack, ieGoNext, ieGoBlank
  );
{$ENDIF}

(*
t - ShortTieFormat
tt - LongTimeFormat

c - ShortDateFormat + LongTimeFormat

ddddd - ShortDateFormat
dddddd - LongDateFormat


=====================


*)


type
  TSymbolCode = record
    Code : byte;
    Name : string;
  end;

const
  SYMBOL_CODE_LIST : array[1..10] of char = (
    #128, // Euro
    #169, // copy
    #174, // reg
    #153, // tm
    #167, // para
    #176, // deg
    #177, // plusminus
    #133, // dots
    #171, // left french brace
    #187 // right french brace
  );

var
  FILE_FORMAT_NAMES : array[TKntFileFormat] of string;
  FILE_COMPRESSION_LEVEL : array[TZCompressionLevel] of string;
  SEARCH_MODES : array[TSearchMode] of string;
  SEARCH_SCOPES : array[TSearchScope] of string;
  SEARCH_CHKMODES : array[TSearchCheckMode] of string;
  SYMBOL_NAME_LIST : array[1..10] of string;
  HTMLImportMethods : array[THTMLImportMethod] of string;
  HTMLExportMethods : array[THTMLExportMethod] of string;

implementation

procedure DefineConst;
begin
  FILE_FORMAT_NAMES[nffKeyNote]:=  sINFFormats1;
  FILE_FORMAT_NAMES[nffKeyNoteZip]:=   sINFFormats3;
  FILE_FORMAT_NAMES[nffEncrypted]:=    sINFFormats2;
{$IFDEF WITH_DART}
  FILE_FORMAT_NAMES[nffDartNotes]:=    sINFFormats4;
{$ENDIF}
  FILE_COMPRESSION_LEVEL[zcNone]:= sINFCompres1;
  FILE_COMPRESSION_LEVEL[zcFastest]:= sINFCompres2;
  FILE_COMPRESSION_LEVEL[zcDefault]:= sINFCompres3;
  FILE_COMPRESSION_LEVEL[zcMax]:= sINFCompres4;


  SEARCH_MODES[smPhrase] := sINFSrchMode1;
  SEARCH_MODES[smAll] := sINFSrchMode2;
  SEARCH_MODES[smAny] := sINFSrchMode3;

  SEARCH_SCOPES[ssOnlyNodeName ]:= sINFSrchScope1;
  SEARCH_SCOPES[ssOnlyContent] := sINFSrchScope2;
  SEARCH_SCOPES[ssContentsAndNodeName] := sINFSrchScope3;

  SEARCH_CHKMODES[scOnlyNonChecked]:= sINFSrchChk1;
  SEARCH_CHKMODES[scOnlyChecked]:= sINFSrchChk2;
  SEARCH_CHKMODES[scAll]:= sINFSrchChk3;

  SYMBOL_NAME_LIST[1]:=   sINFSymb0;
  SYMBOL_NAME_LIST[2]:=   sINFSymb1;
  SYMBOL_NAME_LIST[3]:=   sINFSymb2;
  SYMBOL_NAME_LIST[4]:=   sINFSymb3;
  SYMBOL_NAME_LIST[5]:=   sINFSymb4;
  SYMBOL_NAME_LIST[6]:=   sINFSymb5;
  SYMBOL_NAME_LIST[7]:=   sINFSymb6;
  SYMBOL_NAME_LIST[8]:=   sINFSymb7;
  SYMBOL_NAME_LIST[9]:=   sINFSymb8;
  SYMBOL_NAME_LIST[10]:=  sINFSymb9;

  HTMLImportMethods[htmlSource]:=         sINFImpHTML1;
  HTMLImportMethods[htmlSharedTextConv]:= sINFImpHTML2;
  HTMLImportMethods[htmlMSWord]:=         sINFImpHTML3;
  HTMLImportMethods[htmlIE]:=             sINFImpHTML4;

  HTMLExportMethods[htmlExpMicrosoftHTMLConverter]:= sINFImpHTML5;
  HTMLExportMethods[htmlExpMSWord]:=                 sINFImpHTML3;
end;

Initialization
  DefineConst;

end.


