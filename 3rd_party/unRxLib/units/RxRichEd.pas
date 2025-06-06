﻿{*******************************************************}
{                                                       }
{         Delphi VCL Extensions (RX)                    }
{                                                       }
{         Copyright (c) 1998 Master-Bank                }
{                                                       }
{ Revision and enhancements added by JB.                }
{*******************************************************}

(* ------------------------------------------------------
  + Changes by Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain) [dpv]
  + Changes by Marek Jedlinski <marek@tranglos.com> (Poland) [mj]

   >> Changes to original source code available in KeyNote NF project.
   >> Fore more information, please see 'README.md' and 'doc/README_SourceCode.txt'
      in https://github.com/dpradov/keynote-nf
--------------------- -----------------------------------*)

unit RxRichEd;

{$I RX.INC}

{.$DEFINE RICHEDIT_VER_10}
{$DEFINE RX_ENH} {last enhancement}
{$DEFINE RX_ENHPRINT} {for better print preview}

{$DEFINE RX_LANGUAGE}                     // [dpv]
{$DEFINE RX_SELECTDLL}                    // [dpv] Allow to select another DLL available, for example if we have MS Office installed.  See notes at the end of GetDLLProductVersion procedure
{$DEFINE GetSetAttributes_PUBLIC}         // [dpv]

{$R-}

interface

uses Windows, {$IFDEF RX_D3} ActiveX, ComObj {$ELSE} Ole2, OleAuto {$ENDIF},
  CommCtrl, Messages, SysUtils, Classes, Controls, Forms, Graphics, StdCtrls,
  {$IFDEF RX_D6}Types, {$ENDIF} {$IFDEF RX_D16}System.UITypes,{$ENDIF}
  {$IFDEF RX_D18}System.AnsiStrings,{$ENDIF}
  Dialogs, RichEdit, Menus, ComCtrls;


type
{$IFNDEF RX_SELECTDLL}
   TRichEditVersion = 1..4;
{$ELSE}
   TRichEditVersion = 1..8;          // [dpv] See notes at the end of GetDLLProductVersion procedure
{$ENDIF}

{                                  // [dpv]   See comment *5
var
  list: TStringList;
  st1, st2: TMemoryStream;
}

{$IFNDEF RX_D3}
  TCharFormat2A = record
    cbSize: UINT;
    dwMask: DWORD;
    dwEffects: DWORD;
    yHeight: Longint;
    yOffset: Longint;
    crTextColor: TColorRef;
    bCharSet: Byte;
    bPitchAndFamily: Byte;
    szFaceName: array[0..LF_FACESIZE - 1] of AnsiChar;
    { new fields in version 2.0 }
    wWeight: Word;                   { Font weight (LOGFONT value)             }
    sSpacing: Smallint;              { Amount to space between letters         }
    crBackColor: TColorRef;          { Background color                        }
    lid: LCID;                       { Locale ID                               }
    dwReserved: DWORD;               { Reserved. Must be 0                     }
    sStyle: Smallint;                { Style handle                            }
    wKerning: Word;                  { Twip size above which to kern char pair }
    bUnderlineType: Byte;            { Underline type                          }
    bAnimation: Byte;                { Animated text like marching ants        }
    bRevAuthor: Byte;                { Revision author index                   }
    bReserved1: Byte;
  end;
  TCharFormat2 = TCharFormat2A;

  TParaFormat2 = record
    cbSize: UINT;
    dwMask: DWORD;
    wNumbering: Word;
    wReserved: Word;
    dxStartIndent: Longint;
    dxRightIndent: Longint;
    dxOffset: Longint;
    wAlignment: Word;
    cTabCount: Smallint;
    rgxTabs: array [0..MAX_TAB_STOPS - 1] of Longint;
    { new fields in version 2.0 }
    dySpaceBefore: Longint;     { Vertical spacing before paragraph      }
    dySpaceAfter: Longint;      { Vertical spacing after paragraph       }
    dyLineSpacing: Longint;     { Line spacing depending on Rule         }
    sStyle: Smallint;           { Style handle                           }
    bLineSpacingRule: Byte;     { Rule for line spacing (see tom.doc)    }
    bCRC: Byte;                 { Reserved for CRC for rapid searching   }
    wShadingWeight: Word;       { Shading in hundredths of a per cent    }
    wShadingStyle: Word;        { Nibble 0: style, 1: cfpat, 2: cbpat    }
    wNumberingStart: Word;      { Starting value for numbering           }
    wNumberingStyle: Word;      { Alignment, roman/arabic, (), ), ., etc.}
    wNumberingTab: Word;        { Space bet 1st indent and 1st-line text }
    wBorderSpace: Word;         { Space between border and text (twips)  }
    wBorderWidth: Word;         { Border pen width (twips)               }
    wBorders: Word;             { Byte 0: bits specify which borders     }
                                { Nibble 2: border style, 3: color index }
  end;

{$ENDIF RX_D3}

{$IFDEF RX_LANGUAGE}
type
  TLanguage = 0..$FFFF;                                          // [dpv]

{$ENDIF}


{$IFDEF RX_D5}
  TCharFormat2 = TCharFormat2A;
{$ENDIF}

type
  TRxCustomRichEdit = class;

{ TRxTextAttributes }

  TRxAttributeType = (atDefaultText, atSelected, atWord);                // EM_SETCHARFORMAT -> SCF_DEFAULT, SCF_SELECTION, SCF_WORD, ...
  TRxConsistentAttribute = (caBold, caColor, caFace, caItalic, caSize,
    caStrikeOut, caUnderline, caProtected, caOffset, caHidden, caLink,
    caBackColor, caDisabled, caWeight, caSubscript, caRevAuthor,
    caLanguage, caIndexKind, caSpacing, caKerning, caULType, caAnimation,
    caSmallCaps, caAllCaps, caOutline, caShadow, caEmboss, caImprint, caURL);
  TRxConsistentAttributes = set of TRxConsistentAttribute;
  TSubscriptStyle = (ssNone, ssSubscript, ssSuperscript);
  TUnderlineType = (utNone, utSolid, utWord, utDouble, utDotted, utWave);
  TAnimationType = (aniNone, aniLasVegas, aniBlink, aniSparkle, aniBlackAnts,
                    aniRedAnts, aniShimmer);
  TRxLinkStyle = (lsNone, lsLink, lsMixed);                     // [dpv]

  TRxTextAttributes = class(TPersistent)
  private
    RichEdit: TRxCustomRichEdit;
    FType: TRxAttributeType;
    procedure AssignFont(Font: TFont);
{$IFNDEF GetSetAttributes_PUBLIC}                               // [mj]
    procedure GetAttributes(var Format: TCharFormat2);
    procedure SetAttributes(var Format: TCharFormat2);
{$ENDIF}
{$IFNDEF VER90}
    function GetCharset: TFontCharset;
    procedure SetCharset(Value: TFontCharset);
{$ENDIF}
    function GetSubscriptStyle: TSubscriptStyle;
    procedure SetSubscriptStyle(Value: TSubscriptStyle);
    function GetBackColor: TColor;
    function GetColor: TColor;
    function GetConsistentAttributes: TRxConsistentAttributes;
    function GetHeight: Integer;
    function GetHidden: Boolean;
{$IFDEF RX_LANGUAGE}
    function  GetLanguage : TLanguage;                          // [mj]
    procedure SetLanguage(Value: TLanguage);                    // [mj]
{$ENDIF}
    function GetDisabled: Boolean;
    function GetLink: Boolean;
    function GetLinkStyle: TRxLinkStyle;                        // [dpv]
    function GetName: TFontName;
    function GetOffset: Integer;
    function GetPitch: TFontPitch;
    function GetProtected: Boolean;
    function GetRevAuthorIndex: Byte;
    function GetSize: Integer;
    function GetStyle: TFontStyles;
    function GetSpacing: Double;
    procedure SetSpacing(Value: Double);
    function GetKerning: Double;
    procedure SetKerning(Value: Double);
    function GetUnderlineType: TUnderlineType;
    function GetAnimation: TAnimationType;
    procedure SetAnimation(Value: TAnimationType);
    procedure SetBackColor(Value: TColor);
    procedure SetColor(Value: TColor);
    procedure SetDisabled(Value: Boolean);
    procedure SetHeight(Value: Integer);
    procedure SetHidden(Value: Boolean);
    procedure SetLink(Value: Boolean);
    procedure SetName(Value: TFontName);
    procedure SetOffset(Value: Integer);
    procedure SetPitch(Value: TFontPitch);
    procedure SetProtected(Value: Boolean);
    procedure SetRevAuthorIndex(Value: Byte);
    procedure SetSize(Value: Integer);
    procedure SetStyle(Value: TFontStyles);
    procedure SetUnderlineType(Value: TUnderlineType);
    function GetSmallCaps: Boolean;
    procedure SetSmallCaps(Value: Boolean);
    function GetAllCaps: Boolean;
    procedure SetAllCaps(Value: Boolean);
    function GetOutline: Boolean;
    procedure SetOutline(Value: Boolean);
    function GetShadow: Boolean;
    procedure SetShadow(Value: Boolean);
    function GetEmboss: Boolean;
    procedure SetEmboss(Value: Boolean);
    function GetImprint: Boolean;
    procedure SetImprint(Value: Boolean);
  protected
    procedure InitFormat(var Format: TCharFormat2);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TRxCustomRichEdit; AttributeType: TRxAttributeType);
    procedure Assign(Source: TPersistent); override;
{$IFDEF GetSetAttributes_PUBLIC}                                  // [mj] -> Public
    procedure GetAttributes(var Format: TCharFormat2);
    procedure SetAttributes(var Format: TCharFormat2);
{$ENDIF}
{$IFNDEF VER90}
    property Charset: TFontCharset read GetCharset write SetCharset;
{$ENDIF}
    property BackColor: TColor read GetBackColor write SetBackColor;
    property Color: TColor read GetColor write SetColor;
    property ConsistentAttributes: TRxConsistentAttributes read GetConsistentAttributes;
    property Disabled: Boolean read GetDisabled write SetDisabled;
    property Hidden: Boolean read GetHidden write SetHidden;
{$IFDEF RX_LANGUAGE}
   	{ Language: Has no effect on the text displayed by a rich edit control, but spelling and grammar checkers can use it to deal with language-dependent problems
	    https://learn.microsoft.com/en-us/windows/win32/api/richedit/ns-richedit-charformat2a_1    (LCID) }
    property Language: TLanguage read GetLanguage write SetLanguage;  // [mj]
{$ENDIF}
    property Link: Boolean read GetLink write SetLink;
    property LinkStyle: TRxLinkStyle read GetLinkStyle;               // [dpv]
    property Name: TFontName read GetName write SetName;
    property Offset: Integer read GetOffset write SetOffset;
    property Pitch: TFontPitch read GetPitch write SetPitch;
    property Protected: Boolean read GetProtected write SetProtected;
    property RevAuthorIndex: Byte read GetRevAuthorIndex write SetRevAuthorIndex;
    property SubscriptStyle: TSubscriptStyle read GetSubscriptStyle write SetSubscriptStyle;
    property Size: Integer read GetSize write SetSize;
    property Style: TFontStyles read GetStyle write SetStyle;
    property Height: Integer read GetHeight write SetHeight;
    property Spacing: Double read GetSpacing write SetSpacing;
    property Kerning: Double read GetKerning write SetKerning;
    property UnderlineType: TUnderlineType read GetUnderlineType write SetUnderlineType;
    property Animation: TAnimationType read GetAnimation write SetAnimation;
    property SmallCaps: Boolean read GetSmallCaps write SetSmallCaps;
    property AllCaps: Boolean read GetAllCaps write SetAllCaps;
    property Outline: Boolean read GetOutline write SetOutline;
    property Shadow: Boolean read GetShadow write SetShadow;
    property Emboss: Boolean read GetEmboss write SetEmboss;
    property Imprint: Boolean read GetImprint write SetImprint;
    procedure SetBold(Value: boolean);                                // [mj]
    procedure SetItalic(Value: boolean);                              // [mj]
    procedure SetUnderline(Value: boolean);                           // [mj]
    procedure SetStrikeOut(Value: boolean);                           // [mj]
  end;

{ TRxParaAttributes }

  TRxNumbering = (nsNone, nsBullet, nsArabicNumbers, nsLoCaseLetter,
    nsUpCaseLetter, nsLoCaseRoman, nsUpCaseRoman);
  //TRxNumberingStyle = (nsParenthesis, nsPeriod, nsEnclosed, nsSimple);
  TRxNumberingStyle = (nsParenthesis=$0000, nsEnclosed=$0100, nsPeriod=$0200,
                       nsSimple=$0300, nsNoNumber=$0400, nsNewNumber=$8000);  // [dpv] http://msdn.microsoft.com/en-us/library/bb787942%28VS.85%29.aspx
  TParaAlignment = (paLeftJustify, paRightJustify, paCenter, paJustify);
  TLineSpacingRule = (lsSingle, lsOneAndHalf, lsDouble, lsSpecifiedOrMore,
    lsSpecified, lsMultiple);
  THeadingStyle = 0..9;
  TParaTableStyle = (tsNone, tsTableRow, tsTableCellEnd, tsTableCell);

  TRxParaAttributes = class(TPersistent)
  private
    RichEdit: TRxCustomRichEdit;
{$IFNDEF GetSetAttributes_PUBLIC}                                       // [mj]
    procedure GetAttributes(var Paragraph: TParaFormat2);
	procedure SetAttributes(var Paragraph: TParaFormat2);
{$ENDIF}
    function GetRTL: Boolean;                                           // [dpv]
    function GetAlignment: TParaAlignment;
    function GetFirstIndent: Longint;
    function GetHeadingStyle: THeadingStyle;
    function GetLeftIndent: Longint;
    function GetRightIndent: Longint;
    function GetSpaceAfter: Longint;
    function GetSpaceBefore: Longint;
    function GetLineSpacing: Longint;
    function GetLineSpacingRule: TLineSpacingRule;
    function GetNumbering: TRxNumbering;
    function GetNumberingStyle: TRxNumberingStyle;
    function GetNumberingTab: Word;
    function GetTab(Index: Byte): Longint;
    function GetTabCount: Integer;
    function GetTableStyle: TParaTableStyle;
    procedure SetRTL(Value: Boolean);                                   // [dpv]
    procedure SetAlignment(Value: TParaAlignment);
    procedure SetFirstIndent(Value: Longint);
    procedure SetFirstIndentRelative(Value: Longint);                   // [dpv]
    procedure SetHeadingStyle(Value: THeadingStyle);
    procedure SetLeftIndent(Value: Longint);
    procedure SetRightIndent(Value: Longint);
    procedure SetSpaceAfter(Value: Longint);
    procedure SetSpaceBefore(Value: Longint);
    procedure SetLineSpacing(Value: Longint);
    procedure SetLineSpacingRule(Value: TLineSpacingRule);
    procedure SetNumbering(Value: TRxNumbering);
    function  GetNumberingStart : integer;                              // [dpv]
    procedure SetNumberingStart( Value : integer );                     // [dpv]
    procedure SetNumberingStyle(Value: TRxNumberingStyle);
    procedure SetNumberingTab(Value: Word);
    procedure SetTab(Index: Byte; Value: Longint);
    procedure SetTabCount(Value: Integer);
    procedure SetTableStyle(Value: TParaTableStyle);
  protected
    procedure InitPara(var Paragraph: TParaFormat2);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TRxCustomRichEdit);
    procedure Assign(Source: TPersistent); override;
{$IFDEF GetSetAttributes_PUBLIC}                                                                 // [mj] -> public
    procedure GetAttributes(var Paragraph: TParaFormat2);
    procedure SetAttributes(var Paragraph: TParaFormat2);
{$ENDIF}
    property RTL: Boolean read GetRTL write SetRTL;                                              // [dpv]
    property Alignment: TParaAlignment read GetAlignment write SetAlignment;
    property FirstIndent: Longint read GetFirstIndent write SetFirstIndent;
    property FirstIndentRelative: Longint write SetFirstIndentRelative;                          // [dpv]
    property HeadingStyle: THeadingStyle read GetHeadingStyle write SetHeadingStyle;
    property LeftIndent: Longint read GetLeftIndent write SetLeftIndent;
    property LineSpacing: Longint read GetLineSpacing write SetLineSpacing;
    property LineSpacingRule: TLineSpacingRule read GetLineSpacingRule write SetLineSpacingRule;
    property Numbering: TRxNumbering read GetNumbering write SetNumbering;
    property NumberingStart : integer read GetNumberingStart write SetNumberingStart;            // [dpv]
    property NumberingStyle: TRxNumberingStyle read GetNumberingStyle write SetNumberingStyle;
    property NumberingTab: Word read GetNumberingTab write SetNumberingTab;
   	procedure SetNumberingList(numbering: TRxNumbering;
                               numberingStyle: TRxNumberingStyle;
                               numberingStart: integer; LeftIndent: integer);                    // [mj]
    property RightIndent: Longint read GetRightIndent write SetRightIndent;
    property SpaceAfter: Longint read GetSpaceAfter write SetSpaceAfter;
    property SpaceBefore: Longint read GetSpaceBefore write SetSpaceBefore;
    property Tab[Index: Byte]: Longint read GetTab write SetTab;
    property TabCount: Integer read GetTabCount write SetTabCount;
    property TableStyle: TParaTableStyle read GetTableStyle write SetTableStyle;
  end;

{ TOEMConversion }

  TOEMConversion = class(TConversion)
  public
{$IFDEF RX_D12}
    function ConvertReadStream(Stream: TStream; Buffer: TConversionBuffer; BufSize: Integer): Integer; override;
    function ConvertWriteStream(Stream: TStream; Buffer: TConversionBuffer; BufSize: Integer): Integer; override;
{$ELSE}
    function ConvertReadStream(Stream: TStream; Buffer: PChar; BufSize: Integer): Integer; override;
    function ConvertWriteStream(Stream: TStream; Buffer: PChar; BufSize: Integer): Integer; override;
{$ENDIF}
  end;

{ TRxCustomRichEdit }

  TUndoName = (unUnknown, unTyping, unDelete, unDragDrop, unCut, unPaste);
  TRichSearchType = (stWholeWord, stMatchCase, stBackward, stSetSelection);
  TRichSearchTypes = set of TRichSearchType;
  TRichSelection = (stText, stObject, stMultiChar, stMultiObject);
  TRichSelectionType = set of TRichSelection;
  TRichLangOption = (rlAutoKeyboard, rlAutoFont, rlImeCancelComplete,
    rlImeAlwaysSendNotify);
  TRichLangOptions = set of TRichLangOption;
  TRichStreamFormat = (sfDefault, sfRichText, sfPlainText);
  TRichStreamMode = (smSelection, smPlainRtf, smNoObjects{$IFNDEF RX_D12}, smUnicode{$ENDIF});
  TRichStreamModes = set of TRichStreamMode;
  TRichEditURLClickEvent = procedure(Sender: TObject; const URLText: string;
    Button: TMouseButton) of object;
  TRichEditURLMouseMoveEvent = procedure(Sender: TObject; WParam: WPARAM) of object;   // [dpv]

  TRichEditProtectChangeEx = procedure(Sender: TObject; const Message: TMessage;
    StartPos, EndPos: Integer; var AllowChange: Boolean) of object;
  TRichEditFindErrorEvent = procedure(Sender: TObject; const FindText: string) of object;
  TRichEditFileDroppedEvent = procedure( sender : Tobject; FileList : TStringList ) of object;        // [dpv]
{$IFDEF RX_D3}
  TRichEditFindCloseEvent = procedure(Sender: TObject; Dialog: TFindDialog) of object;
{$ENDIF}

  PRichConversionFormat = ^TRichConversionFormat;
  TRichConversionFormat = record
    ConversionClass: TConversionClass;
    Extension: string;
    PlainText: Boolean;
    Next: PRichConversionFormat;
  end;

  {$IFDEF RX_D16}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$ENDIF}
  TRxCustomRichEdit = class(TCustomMemo)
  private
  {$IFDEF RX_ENHPRINT}
    fdrawendpage : boolean;
  {$ENDIF RX_ENHPRINT}
    FHideScrollBars: Boolean;
    FSelectionBar: Boolean;
    FAutoURLDetect: Boolean;
    FWordSelection: Boolean;
    FPlainText: Boolean;
    FSelAttributes: TRxTextAttributes;
    FDefAttributes: TRxTextAttributes;
    FWordAttributes: TRxTextAttributes;
    FParagraph: TRxParaAttributes;
    FOldParaAlignment: TParaAlignment;
    FScreenLogPixels: Integer;
    FUndoLimit: Integer;
    FRichEditStrings: TStrings;
    FMemStream: TMemoryStream;
    FHideSelection: Boolean;
    FLangOptions: TRichLangOptions;
    FModified: Boolean;
    FLinesUpdating: Boolean;
    FPageRect: TRect;
    FClickRange: TCharRange;
    FClickBtn: TMouseButton;
    FFindDialog: TFindDialog;
    FReplaceDialog: TReplaceDialog;
    FLastFind: TFindDialog;
    FAllowObjects: Boolean;
    FCallback: TObject;
    FRichEditOle: IUnknown;
    FPopupVerbMenu: TPopupMenu;
    FTitle: string;
    FAutoVerbMenu: Boolean;
{$IFDEF RX_D3}
    FAllowInPlace: Boolean;
{$ENDIF}
    FDefaultConverter: TConversionClass;
    FOnSelChange: TNotifyEvent;
    FOnResizeRequest: TRichEditResizeEvent;
    FOnProtectChange: TRichEditProtectChange;
    FOnProtectChangeEx: TRichEditProtectChangeEx;
    FOnSaveClipboard: TRichEditSaveClipboard;
    FOnURLClick: TRichEditURLClickEvent;
    FOnURLMouseMove: TRichEditURLMouseMoveEvent;
    FOnFileDropped: TRichEditFileDroppedEvent;      // [dpv]
    FOnTextNotFound: TRichEditFindErrorEvent;
{$IFDEF RX_D3}
    FOnCloseFindDialog: TRichEditFindCloseEvent;
{$ENDIF}
    FOldEventMask: integer;                         // [dpv]   ,,
    function GetAutoURLDetect: Boolean;
    function GetWordSelection: Boolean;
    function GetLangOptions: TRichLangOptions;
    function GetCanRedo: Boolean;
    function GetCanPaste: Boolean;
{$IFNDEF RX_V110}
    function GetCanUndo: Boolean;
{$ENDIF}
    function GetRedoName: TUndoName;
    function GetUndoName: TUndoName;
    function GetStreamFormat: TRichStreamFormat;
    function GetStreamMode: TRichStreamModes;
    function GetSelectionType: TRichSelectionType;
    procedure PopupVerbClick(Sender: TObject);
    procedure ObjectPropsClick(Sender: TObject);
    procedure CloseObjects;
    procedure UpdateHostNames;
    procedure SetAllowObjects(Value: Boolean);
    procedure SetOnFileDropped(Value: TRichEditFileDroppedEvent);                       // [dpv]
    procedure SetStreamFormat(Value: TRichStreamFormat);
    procedure SetStreamMode(Value: TRichStreamModes);
    procedure SetAutoURLDetect(Value: Boolean);
    procedure SetWordSelection(Value: Boolean);
    procedure SetHideScrollBars(Value: Boolean);
    procedure SetHideSelection(Value: Boolean);
    procedure SetTitle(const Value: string);
    procedure SetLangOptions(Value: TRichLangOptions);
    procedure SetRichEditStrings(Value: TStrings);
    procedure SetDefAttributes(Value: TRxTextAttributes);
    procedure SetSelAttributes(Value: TRxTextAttributes);
    procedure SetWordAttributes(Value: TRxTextAttributes);
    procedure SetSelectionBar(Value: Boolean);
    procedure SetUndoLimit(Value: Integer);
    procedure UpdateTextModes(Plain: Boolean);
    procedure AdjustFindDialogPosition(Dialog: TFindDialog);
    procedure SetupFindDialog(Dialog: TFindDialog; const SearchStr,
      ReplaceStr: string);
    function FindEditText(Dialog: TFindDialog; AdjustPos, Events: Boolean): Boolean;
    function GetCanFindNext: Boolean;
    procedure FindDialogFind(Sender: TObject);
    procedure ReplaceDialogReplace(Sender: TObject);
{$IFDEF RX_D3}
    procedure FindDialogClose(Sender: TObject);
    procedure SetUIActive(Active: Boolean);
    procedure CMDocWindowActivate(var Message: TMessage); message CM_DOCWINDOWACTIVATE;
    procedure CMUIDeactivate(var Message: TMessage); message CM_UIDEACTIVATE;
{$ENDIF}
{$IFDEF RX_D4}
    procedure CMBiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
{$ENDIF}
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CNNotify(var Message: TWMNotify); message CN_NOTIFY;
    procedure EMReplaceSel(var Message: TMessage); message EM_REPLACESEL;
    procedure WMDestroy(var Msg: TWMDestroy); message WM_DESTROY;
    procedure WMMouseMove(var Message: TMessage); message WM_MOUSEMOVE;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFont(var Message: TWMSetFont); message WM_SETFONT;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;        // [dpv]  See comment *3

{$IFDEF RX_D5}
    procedure WMRButtonUp(var Message: TMessage); message WM_RBUTTONUP;
{$ENDIF}
{$IFDEF RX_ENH}
    function  GetRtfSelText: String;
    procedure SetRtfSelText(const sRtf: String);
    function  GetRtfText: AnsiString;                       // [dpv]
    procedure SetRtfText(const sRtf: AnsiString);           // [dpv]
{$ENDIF}

  protected
    FUpdating: integer;                             // [dpv] For use with BeginUpdate/EndUpdate

    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    function GetPopupMenu: TPopupMenu; override;
    procedure TextNotFound(Dialog: TFindDialog); virtual;
    procedure RequestSize(const Rect: TRect); virtual;
    procedure SelectionChange; dynamic;
    function ProtectChange(const Message: TMessage; StartPos,
      EndPos: Integer): Boolean; dynamic;
    function SaveClipboard(NumObj, NumChars: Integer): Boolean; dynamic;
    procedure URLClick(const URLText: string; Button: TMouseButton); dynamic;
    procedure URLMouseMove(WParam: WPARAM); dynamic;                                     // [dpv]
    {procedure FileDropped(EndDropFiles: TEndDropFiles); dynamic;                        // [dpv]  See comment *3 }
    procedure SetPlainText(Value: Boolean); virtual;
{$IFDEF RX_D3}
    procedure CloseFindDialog(Dialog: TFindDialog); virtual;
    procedure DoSetMaxLength(Value: Integer); override;
    function GetSelLength: Integer; override;
    function GetSelStart: Integer; override;
    function GetSelText: string; override;
    procedure SetSelLength(Value: Integer); override;
    procedure SetSelStart(Value: Integer); override;
    function GetSelVisibleText: string;                                                   // [dpv]
    function GetVisibleText: string;                                                      // [dpv]
    property AllowInPlace: Boolean read FAllowInPlace write FAllowInPlace default True;
{$ENDIF}
    property AllowObjects: Boolean read FAllowObjects write SetAllowObjects default True;
    property AutoURLDetect: Boolean read GetAutoURLDetect write SetAutoURLDetect default True;
    property AutoVerbMenu: Boolean read FAutoVerbMenu write FAutoVerbMenu default True;
    property HideSelection: Boolean read FHideSelection write SetHideSelection default True;
    property HideScrollBars: Boolean read FHideScrollBars
      write SetHideScrollBars default True;
    property Title: string read FTitle write SetTitle;
    property LangOptions: TRichLangOptions read GetLangOptions write SetLangOptions default [rlAutoFont];
    property Lines: TStrings read FRichEditStrings write SetRichEditStrings;
    property PlainText: Boolean read FPlainText write SetPlainText default False;
    property SelectionBar: Boolean read FSelectionBar write SetSelectionBar default True;
    property StreamFormat: TRichStreamFormat read GetStreamFormat write SetStreamFormat default sfDefault;
    property StreamMode: TRichStreamModes read GetStreamMode write SetStreamMode default [];
    property UndoLimit: Integer read FUndoLimit write SetUndoLimit default 100;
    property WordSelection: Boolean read GetWordSelection write SetWordSelection default True;
    property ScrollBars default ssBoth;
    property TabStop default True;
    property OnSaveClipboard: TRichEditSaveClipboard read FOnSaveClipboard
      write FOnSaveClipboard;
    property OnSelectionChange: TNotifyEvent read FOnSelChange write FOnSelChange;
    property OnProtectChange: TRichEditProtectChange read FOnProtectChange
      write FOnProtectChange; { obsolete }
    property OnProtectChangeEx: TRichEditProtectChangeEx read FOnProtectChangeEx
      write FOnProtectChangeEx;
    property OnResizeRequest: TRichEditResizeEvent read FOnResizeRequest
      write FOnResizeRequest;
    property OnURLClick: TRichEditURLClickEvent read FOnURLClick write FOnURLClick;
    property OnURLMouseMove: TRichEditURLMouseMoveEvent read FOnURLMouseMove write FOnURLMouseMove;                      // [dpv]
    property OnFileDropped: TRichEditFileDroppedEvent read FOnFileDropped write SetOnFileDropped;        // [dpv]  See comment *3
    property OnTextNotFound: TRichEditFindErrorEvent read FOnTextNotFound write FOnTextNotFound;
{$IFDEF RX_D3}
    property OnCloseFindDialog: TRichEditFindCloseEvent read FOnCloseFindDialog
      write FOnCloseFindDialog;
{$ENDIF}
  public
  {$IFDEF RX_ENHPRINT}
    PercentDone:byte;
    PrnPreviews:TList;
    PrnPreview:Tmetafile;
  {$ENDIF RX_ENHPRINT}
    PageNum: Integer;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear; {$IFDEF RX_D3} override; {$ENDIF}
    procedure SetSelection(StartPos, EndPos: Longint; ScrollCaret: Boolean);
    function GetSelection: TCharRange;
    function GetTextRange(StartPos, EndPos: Longint): string;
    function LineFromChar(CharIndex: Integer): Integer;
    function GetLineIndex(LineNo: Integer): Integer;
    function GetLineLength(CharIndex: Integer): Integer;
    function GetFirstVisibleLine: Integer;                            // [dpv]
    property SelVisibleText: string read GetSelVisibleText;           // [dpv]
    property VisibleText: string read GetVisibleText;                 // [dpv]
    function TextLength: integer;                                     // [dpv]
    function TextPlain (Selection: boolean= False): string;           // [dpv] Alternative to TCumstomEdit.Text (GetText), returning RAWTEXT
    procedure AddText(const Str: String);                             // [dpv]
    procedure SetMargins(Left, Right: integer);                       // [dpv]
    function WordAtCursor: string;
    function FindText(const SearchStr: string;
      StartPos, Length: Integer; Options: TRichSearchTypes): Integer;
    function GetSelTextBuf(Buffer: PChar; BufSize: Integer): Integer;
      {$IFDEF RX_D3} override; {$ENDIF}
    function GetCaretPos: TPoint; {$IFDEF RX_V110} override; {$ENDIF}
    function GetCharPos(CharIndex: Integer): TPoint;
    function GetCharFromPos(Point: TPoint): integer;                   // [dpv]
    procedure ScrollLinesBy(inc: integer);                             // [dpv]
    procedure SetScrollPosInEditor(Point: TPoint);                     // [dpv]
    function GetScrollPosInEditor: TPoint;                             // [dpv]
    function InsertObjectDialog: Boolean;
    function ObjectPropertiesDialog: Boolean;
    //function PasteSpecialDialog: boolean;
    function PasteSpecialDialog (PasteImg: boolean= true): integer;               // [dpv]
    function PasteIRichEditOLE(cfFormat: TClipFormat): Boolean;        // [dpv]
    function FindDialog(const SearchStr: string): TFindDialog;
    function ReplaceDialog(const SearchStr, ReplaceStr: string): TReplaceDialog;
    function FindNext: Boolean;

    procedure PrintPageNumberAndHeader(Canvas: TCanvas;
                                       PageWidth, PageHeight: integer; PageRect: TRect;
                                       PageNum: Integer; ShowNumPage: boolean; Header: String = '');    // [dpv]

    //function Print(const Caption: string): integer; virtual;
    function Print(const Caption: string;
                   ShowNumPage: boolean= true; StartNumPage: boolean= true;
                   OwnPrintJob: boolean= true; FirstPageMarginTop: integer = -1;
                   const Header: string = ''): integer; virtual;                    // [dpv]
  {$IFDEF RX_ENHPRINT}
    //procedure CreatePrnPrew(const Caption: string); virtual;
    function CreatePrnPrew(const Caption: string;
                           ShowNumPage: boolean= true;
                           FirstPageMarginTop: integer = -1;
                           ScreenDPI: Integer= 96;
                           const Header: string = ''): Integer;                    // [dpv]

  {$ENDIF RX_ENHPRINT}
    class procedure RegisterConversionFormat(const AExtension: string;
      APlainText: Boolean; AConversionClass: TConversionClass);
    procedure ClearUndo;
    procedure SuspendUndo;                                             // [dpv]
    procedure ResumeUndo;                                              // [dpv]
    procedure Redo;
    procedure StopGroupTyping;
    procedure BeginUpdate;                                             // [dpv]
    procedure EndUpdate (InvalidateAndRefresh: boolean= true);         // [dpv]
    procedure RemoveMargins;                                           // [dpv]
    property CanFindNext: Boolean read GetCanFindNext;
    property CanRedo: Boolean read GetCanRedo;
    property CanPaste: Boolean read GetCanPaste;
{$IFNDEF RX_V110}
    procedure Undo;
    property CanUndo: Boolean read GetCanUndo;
    property CaretPos: TPoint read GetCaretPos;
{$ENDIF}
    property RedoName: TUndoName read GetRedoName;
    property UndoName: TUndoName read GetUndoName;
    property DefaultConverter: TConversionClass read FDefaultConverter
      write FDefaultConverter;
    property DefAttributes: TRxTextAttributes read FDefAttributes write SetDefAttributes;
    property SelAttributes: TRxTextAttributes read FSelAttributes write SetSelAttributes;
    property WordAttributes: TRxTextAttributes read FWordAttributes write SetWordAttributes;
    property PageRect: TRect read FPageRect write FPageRect;
    property Paragraph: TRxParaAttributes read FParagraph;
    property SelectionType: TRichSelectionType read GetSelectionType;
{$IFDEF RX_ENH}
    property LinesUpdating: Boolean read FLinesUpdating write FLinesUpdating; //when assembling a string from pieces so that the selection does not flicker (при сборке строки из кусочков, чтобы не мерцало выделение)
    property RtfSelText: String read GetRtfSelText write SetRtfSelText;       //selected text in native format (RTF)  (выделеный текст в native формате)
    property LinkClickRange: TCharRange read FClickRange;                     //+GetTextRange  What was clicked on  (на чём кликнули)

    property RtfText: AnsiString read GetRtfText write SetRtfText;                                                 // [dpv]
    procedure PutRtfText (const sRTF: string; const DoInsert: boolean;
                          const SelectionOnly: boolean = true; const KeepSelected: boolean = false); overload;     // [dpv]
    procedure PutRtfText (const sRTF: RawByteString; const DoInsert: boolean;
                          const SelectionOnly: boolean = true; const KeepSelected: boolean = false); overload;     // [dpv]
{$ENDIF}


  {$IFDEF RX_ENHPRINT}
    property DrawEndPage: Boolean read FDrawEndPage write FDrawEndPage;
  {$ENDIF RX_ENHPRINT}
  end;

  {$IFDEF RX_D16}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$ENDIF}
  TRxRichEdit = class(TRxCustomRichEdit)
  published
  {$IFDEF RX_ENHPRINT}
    property DrawEndPage;
  {$ENDIF RX_ENHPRINT}
    property Align;
    property Alignment;
    property AutoURLDetect;
    property AutoVerbMenu;
    property AllowObjects;
{$IFDEF RX_D3}
    property AllowInPlace;
{$ENDIF}
{$IFDEF RX_D4}
    property Anchors;
    property BiDiMode;
    property BorderWidth;
    property DragKind;
{$ENDIF}
    property BorderStyle;
    property Color;
    property Ctl3D;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property HideScrollBars;
    property Title;
{$IFNDEF VER90}
    property ImeMode;
    property ImeName;
{$ENDIF}
{$IFDEF RX_D4}
    property Constraints;
    property ParentBiDiMode;
{$ENDIF}
    property LangOptions;
    property Lines;
    property MaxLength;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PlainText;
    property PopupMenu;
    property ReadOnly;
    property ScrollBars;
    property SelectionBar;
    property ShowHint;
    property StreamFormat;
    property StreamMode;
    property TabOrder;
    property TabStop;
    property UndoLimit;
    property Visible;
    property WantTabs;
    property WantReturns;
    property WordSelection;
    property WordWrap;
    property OnChange;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
{$IFDEF RX_D5}
    property OnContextPopup;
{$ENDIF}
{$IFDEF RX_D4}
    property OnEndDock;
    property OnStartDock;
{$ENDIF}
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
{$IFDEF RX_D4}
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
{$ENDIF}
    property OnProtectChange; { obsolete }
    property OnProtectChangeEx;
    property OnResizeRequest;
    property OnSaveClipboard;
    property OnSelectionChange;
    property OnStartDrag;
    property OnTextNotFound;
{$IFDEF RX_D3}
    property OnCloseFindDialog;
{$ENDIF}
    property OnURLClick;
    property OnFileDropped;                           // [dpv]
  end;

{$IFDEF RX_SELECTDLL}                                                                          // [dpv]
  procedure GetDLLProductVersion (out sModulePath: string;
                                  out DLLProductVersion: Single;
                                  out RichEditVersion: TRichEditVersion);
  function LoadRichEditDLL(const RichEditLibraryPath: string = ''): TRichEditVersion;
{$ENDIF}

var
  RichEditVersion: TRichEditVersion;

implementation

uses
 Vcl.Printers, Vcl.ComStrs, Vcl.OleConst, Winapi.OleDlg, {$IFDEF RX_D3} Vcl.OleCtnrs, {$ENDIF}
  {$IFDEF RX_D12}Winapi.CommDlg,{$ENDIF}
  RxMaxMin,
  Vcl.Clipbrd, tom_TLB,                                                       // [dpv]  tom_TLB -> ITextDocument
  ShellAPI                                                                    // [dpv]  ShellAPI -> DragAcceptFiles
  {$IFDEF KNT_DEBUG}
  , GFLog, kn_Global                                                                          // [dpv]
  {$ENDIF}
  //, IOUtils                                                                                 // [dpv] See comment *5
  ;


{$IFDEF RX_ENH}
function CanSaveAsANSI(const cad: string): boolean;
var
   ch: Char;
begin
  for ch in cad do
    if Ord (ch) >= 256 then begin
       Result:= false;
       exit;
     end;

   Result:= true;
end;
{$ENDIF}


function GetDropFiles(hDrop: THANDLE): TStringList;
var
  CFileName : array[0..MAX_PATH] of Char;
  FileList : TStringList;
  i, count : integer;
begin
  FileList := TStringList.Create;

  try
    count := DragQueryFile( hDrop, $FFFFFFFF, CFileName, MAX_PATH );

    if ( count > 0 ) then begin
      for i := 0 to count-1 do begin
        DragQueryFile( hDrop, i, CFileName, MAX_PATH );
        FileList.Add( CFileName );
      end;
    end;

    Result:= FileList;

  finally
    DragFinish(hDrop);
  end;

end;





{  *3  NOTES ON USING DRAG AND DROP IN RxRichEdit                         [dpv]

 Using the existing AllowObjects (FAllowObjects) property affects how objects that are dragged into the control are treated, as well as whether
 or not inserting objects through the InsertObjectDialog is allowed.
 Viewed individually it seems reasonable: if set to True, objects will be allowed to be added by dragging or via InsertObjectDialog,
 treating files that can be interpreted as images differently (except for MetaFiles, which always treats them as objects). 
 Set to False, files that are not interpreted as images (including Metafiles) are ignored and cannot be added to the editor.
    But this behavior can get confusing if combined with the result returned by TRichEditOleCallback.QueryAcceptData
 When QueryAcceptData = SR_FALSE, insertion of any file is only prevented precisely if FAllowObjects=True
 If FAllowObjects=False, regardless of the result of QueryAcceptData, you can drag files (that are interpreted as an image)


 * FAllowObjects=True and QueryAcceptData = SR_FALSE
     => Dragging any file (of any type) is not allowed. It also does not allow dragging texts (or anything), neither from outside nor inside the application
     => Yes it is allowed to insert objects through the InsertObjectDialog window
     * If DragAcceptFiles(..,true) was called
        --> the WM_DROPFILES message will be received. Default handling is allowed (not intercepting it or with a custom handler that calls inherited)
        --> All files will be embedded as objects, even if they are of image type.

 * FAllowObjects=True and QueryAcceptData = SR_OK
   => It is allowed to drag (or insert with InsertObjectDialog) any type of file, as well as texts, etc., from outside or inside the application
    -> image files will be embedded as images, and the rest as objects (the usual behavior until now)
     * Even if DragAcceptFiles(..,true) had been called --> the WM_DROPFILES message will NOT be received (nor CN_DROPFILES if we had configured it)

 * FAllowObjects=False and QueryAcceptData = SR_OK
    => Allows dragging files that can be converted to images, but does not allow dragging (or InsertObjectDialog) other files (.txt, .wmf, .emf...)
    => Allows you to drag text from other applications (and from the editor itself)
    * If DragAcceptFiles was called...
      -> The WM_DROPFILES message will only be received for files that are not image files (Those that are image files will be directly embedded as such.)
        Even if we allow default processing of WM_DROPFILES the remaining files will be ignored

 * FAllowObjects=False and QueryAcceptData = SR_FALSE
   => Same behavior as FAllowObjects=False and QueryAcceptData = SR_OK


=> NOTE: If image files and other non-image files are dragged, they will all be treated as if they were not image files (regarding the treatment
      indicated before WM_DROPFILES). Querying DragQueryFile will return all files, whether image or not, and regardless of whether FAllowObjects 
      is True or False

----

  We want to allow the Host application of this control to decide how to manage the dragged files, through a new
  event: OnFileDropped. That event will return a list with the names of all the files dragged into the editor.
  The objective is, for example, to allow the insertion of dragged image files to be done in a controlled manner, processing 
  the images to be inserted as appropriate, and making the necessary format conversions.
  Obtaining the list of names has been obtained through calls to calls to DragQueryFile, using the handler received in
  the WM_DROPFILES event.

  In order to receive that message we need to have previously enabled it by calling DragAcceptFiles(Handle, True)
    (In principle it would also have been possible to obtain that list directly from the received IDataObject object
       TRichEditOleCallback.QueryAcceptData or using the IDropTarget interface (Winapi.ActiveX unit)
       https://stackoverflow.com/questions/21245887/retrieving-filename-from-idataobject-in-delphi
       https://www.freepascal.org/~michael/articles/dragdrop3/dragdrop3.pdf
     )

  Not calling DragAcceptFiles(Handle, True) means that the WM_DROPFILES event will not be raised and there will be no option to allow default handling.
  But it can be seen that even if that message is enabled, it will only be received in certain situations (see above).
  In any case, even if the RxRichEdit control receives the WM_DROPFILES message it will not call the handler by default, and will only call OnFileDropped 
  when (logically) it is assigned to the application's interest in controlling it.

  We'll assume that if the application offers a handler for our OnFileDropped event, it will want to be able to handle all files
  that are dragged, regardless of whether they can be converted to an image or not.
  Therefore, we will take into account whether a handler has been defined for OnFileDropped:
   - NOT assigned(OnFileDropped) -> QueryAcceptData = SR_OK. We will leave the operation described as established for FAllowObjects
         -> The behavior will be as expected: the images will be embedded. And objects will be allowed based on FAllowObjects

   - assigned(OnFileDropped)
       -> QueryAcceptData: SR_FALSE if files have been dragged, SR_OK otherwise.
       -> FAllowObjects will always be treated as True, regardless of what is set by the user.

  ------------------
  We will not use EN_DROPFILES. WM_DROPFILES is enough for us. The TEndDropFiles parameter of the EN_DROPFILES notification gives us more information
  than the TWMDropFiles parameter of WM_DROPFILES (such as the position at which it would be inserted and whether it is text with the protected flag),
  But it is information that we can easily find out if we need it, and also, to receive the notification we must call the handler
  default of WM_DROPFILES, which does not interest us.
  -> We will not use the FileDropped(EndDropFiles: TEndDropFiles);

  ---------------
  Note: We could also receive the WM_DROPFILES and CN_DROPFILES events if we set the ES_NOOLEDRAGDROP style
  (Disables support for dragging and dropping OLE objects.) during control creation, but we are not interested in this.
  At the very least, this would make it difficult to simply select an inserted object (even if you inserted it via code, using RTF code).

  From Create it's done, at the end, FCallback := TRichEditOleCallback.Create(Self);
  If RevokeDragDrop(Handle) were subsequently called -> unregister default IDropTarget interface of Rich Edit
  and we would also receive the WM_DROPFILES and CN_DROPFILES events, but we would lose all functionality
  from that interface, so we could not, among other things, drag text from another application, e.g.
  (would receive those events if DragMode=dmAutomatic or if it was dmManual and BeginDrag... is called)

  -------------------
  References:
  https://www.freepascal.org/~michael/articles/dragdrop2/dragdrop2.pdf (y dragdrop.pdf, dragdrop3.pdf)
    CF_HDROP This data format signifies existing files in the system

	https://www.freepascal.org/~michael/articles/dragdrop/dragdrop.pdf
	https://www.freepascal.org/~michael/articles/dragdrop3/dragdrop3.pdf

	https://stackoverflow.com/questions/21245887/retrieving-filename-from-idataobject-in-delphi

   Shell Clipboard Formats - Win32 apps | Microsoft Learn
   https://learn.microsoft.com/en-us/windows/win32/shell/clipboard?redirectedfrom=MSDN
	Standard clipboard format identifiers have the form CF_XXX. A common example is CF_TEXT, which is used for transferring ANSI text data.
	These identifiers have predefined values and can be used directly with FORMATETC structures. With the exception of CF_HDROP, Shell format
	identifiers are not predefined. With the exception of DragWindow, they have the form CFSTR_XXX. To differentiate these values from predefined
	formats, they are often referred to as simply formats. However, unlike predefined formats, they must be registered by both source and target
	before they can be used to transfer data. To register a Shell format, include the Shlobj.h header file and pass the CFSTR_XXX format identifier
	to RegisterClipboardFormat. This function returns a valid clipboard format value, which can then be used as the cfFormat member of a FORMATETC structure.

----------
*4  OnStartDrag, OnEndDrag, called from TRichEditOleCallback.QueryAcceptData.
    It is not a clean solution, but it works for our needs. Events are not firing exactly when they should
     (at least OnEndDrag) and we are not providing all the parameters to the handler.
     If we did  DragMode := dmManual  then we could use the events OnStartDrag and OnEndDrag of RichEdit, but would
     lose the behaviour of TRichEditOleCallback, configured as described above
}



const
  RTFConversionFormat: TRichConversionFormat = (
    ConversionClass: TConversion;
    Extension: 'rtf';
    PlainText: False;
    Next: nil);
  TextConversionFormat: TRichConversionFormat = (
    ConversionClass: TConversion;
    Extension: 'txt';
    PlainText: True;
    Next: @RTFConversionFormat);

var
  ConversionFormatList: PRichConversionFormat = @TextConversionFormat;

const
  RichEdit10ModuleName = 'RICHED32.DLL';
  RichEdit20ModuleName = 'RICHED20.DLL';
  RichEdit41ModuleName = 'MSFTEDIT.DLL';
{$IFNDEF RX_D3}
  RICHEDIT_CLASSA      = 'RichEdit20A';     { Richedit 2.0 Window Class }
  RICHEDIT_CLASSW      = 'RichEdit20W';     { Richedit 2.0 Unicode }
  RICHEDIT_CLASS10A    = 'RICHEDIT';        { Richedit 1.0 }
  RICHEDIT_CLASS       = RICHEDIT_CLASSA;
{$ENDIF}
  MSFTEDIT_CLASS       = 'RichEdit50W'; //comes with RichEdit 4.1 (beginning in Win XP SP2)

  RICHEDIT_CLASS50W    = 'RichEdit50W';      // [dpv]
  RICHEDIT_CLASS60W    = 'RichEdit60W';      // [dpv]


{$IFNDEF RX_D3}

const
  EM_SETUNDOLIMIT                     = WM_USER + 82;
  EM_REDO                             = WM_USER + 84;
  EM_CANREDO                          = WM_USER + 85;
  EM_GETUNDONAME                      = WM_USER + 86;
  EM_GETREDONAME                      = WM_USER + 87;
  EM_STOPGROUPTYPING                  = WM_USER + 88;
  EM_SETTEXTMODE                      = WM_USER + 89;
  EM_GETTEXTMODE                      = WM_USER + 90; 

{ for use with EM_GET/SETTEXTMODE }

  TM_PLAINTEXT                       = 1; 
  TM_RICHTEXT                        = 2;     { default behavior }
  TM_SINGLELEVELUNDO                 = 4;
  TM_MULTILEVELUNDO                  = 8;     { default behavior }
  TM_SINGLECODEPAGE                  = 16; 
  TM_MULTICODEPAGE                   = 32;    { default behavior }

  EM_AUTOURLDETECT                    = WM_USER + 91; 
  EM_GETAUTOURLDETECT                 = WM_USER + 92;
  EM_SETPALETTE                       = WM_USER + 93;
  EM_GETTEXTEX                        = WM_USER + 94; 
  EM_GETTEXTLENGTHEX                  = WM_USER + 95; 

  EM_SETLANGOPTIONS                   = WM_USER + 120;
  EM_GETLANGOPTIONS                   = WM_USER + 121;
  EM_GETIMECOMPMODE                   = WM_USER + 122;

{ Options for EM_SETLANGOPTIONS and EM_GETLANGOPTIONS }

  IMF_AUTOKEYBOARD            = $0001;
  IMF_AUTOFONT                = $0002;
  IMF_IMECANCELCOMPLETE       = $0004;  { high completes the comp string when aborting, low cancels. }
  IMF_IMEALWAYSSENDNOTIFY     = $0008;

  { https://learn.microsoft.com/en-us/windows/win32/controls/em-getlangoptions
    IMF_AUTOFONT
       If this flag is set, the control automatically changes fonts when the user explicitly changes to a different keyboard layout.
       It is useful to turn off IMF_AUTOFONT for universal Unicode fonts. This option is turned on by default (1).

    IMF_AUTOFONTSIZEADJUST
       If this flag is set, the control scales font-bound font sizes from insertion point size according to script. For example,
       Asian fonts are slightly larger than Western ones. This option is turned on by default (1).

    IMF_AUTOKEYBOARD
      If this flag is set, the control automatically changes the keyboard layout when the user explicitly changes to a different font,
      or when the user explicitly changes the insertion point to a new location in the text.
      ** Will be turned on automatically for bidirectional controls. For all other controls, it is turned off by default.
      This option is turned off by default (0).
  }


{ New notifications }

  EN_OLEOPFAILED                      = $0709;
  EN_OBJECTPOSITIONS                  = $070A;
  EN_LINK                             = $070B;
  EN_DRAGDROPDONE                     = $070C;

{ Event notification masks }

  ENM_SCROLLEVENTS                    = $00000008;
  ENM_DRAGDROPDONE                    = $00000010;
  ENM_LANGCHANGE                      = $01000000; 
  ENM_OBJECTPOSITIONS                 = $02000000; 
  ENM_LINK                            = $04000000;

{ New edit control styles }

  ES_NOOLEDRAGDROP                    = $00000008;

const
  CFM_LINK = $00000020;  { Exchange hyperlink extension }

  CFM_EFFECTS = CFM_BOLD or CFM_ITALIC or CFM_UNDERLINE or CFM_COLOR or
    CFM_STRIKEOUT or CFE_PROTECTED or CFM_LINK;
  CFM_ALL = CFM_EFFECTS or CFM_SIZE or CFM_FACE or CFM_OFFSET or CFM_CHARSET;
  PFM_ALL = PFM_STARTINDENT or PFM_RIGHTINDENT or PFM_OFFSET or
    PFM_ALIGNMENT or PFM_TABSTOPS or PFM_NUMBERING or PFM_OFFSETINDENT;

{ New masks and effects -- a parenthesized asterisk indicates that
   the data is stored by RichEdit2.0, but not displayed }

  CFM_SMALLCAPS               = $0040;                  { (*)    }
  CFM_ALLCAPS                 = $0080;                  { (*)    }
  CFM_HIDDEN                  = $0100;                  { (*)    }
  CFM_OUTLINE                 = $0200;                  { (*)    }
  CFM_SHADOW                  = $0400;                  { (*)    }
  CFM_EMBOSS                  = $0800;                  { (*)    }
  CFM_IMPRINT                 = $1000;                  { (*)    }
  CFM_DISABLED                = $2000;
  CFM_REVISED                 = $4000;

  CFM_BACKCOLOR               = $04000000; 
  CFM_LCID                    = $02000000; 
  CFM_UNDERLINETYPE           = $00800000;              { (*)    }
  CFM_WEIGHT                  = $00400000;
  CFM_SPACING                 = $00200000;              { (*)    }
  CFM_KERNING                 = $00100000;              { (*)    }
  CFM_STYLE                   = $00080000;              { (*)    }
  CFM_ANIMATION               = $00040000;              { (*)    }
  CFM_REVAUTHOR               = $00008000; 

  CFE_LINK                    = $00000020;
  CFE_AUTOCOLOR               = $40000000;   { NOTE: this corresponds to CFM_COLOR, }
                                             { which controls it }
  CFE_SUBSCRIPT               = $00010000;   { Superscript and subscript are }
  CFE_SUPERSCRIPT             = $00020000;   { mutually exclusive            }

  CFM_SUBSCRIPT               = CFE_SUBSCRIPT or CFE_SUPERSCRIPT;
  CFM_SUPERSCRIPT             = CFM_SUBSCRIPT;

  CFM_EFFECTS2 = CFM_EFFECTS or CFM_DISABLED or CFM_SMALLCAPS or CFM_ALLCAPS or 
    CFM_HIDDEN  or CFM_OUTLINE or CFM_SHADOW or CFM_EMBOSS or 
    CFM_IMPRINT or CFM_DISABLED or CFM_REVISED or 
    CFM_SUBSCRIPT or CFM_SUPERSCRIPT or CFM_BACKCOLOR;

  CFM_ALL2 = CFM_ALL or CFM_EFFECTS2 or CFM_BACKCOLOR or CFM_LCID or 
    CFM_UNDERLINETYPE or CFM_WEIGHT or CFM_REVAUTHOR or 
    CFM_SPACING or CFM_KERNING or CFM_STYLE or CFM_ANIMATION;

  CFE_SMALLCAPS               = CFM_SMALLCAPS; 
  CFE_ALLCAPS                 = CFM_ALLCAPS; 
  CFE_HIDDEN                  = CFM_HIDDEN; 
  CFE_OUTLINE                 = CFM_OUTLINE;
  CFE_SHADOW                  = CFM_SHADOW; 
  CFE_EMBOSS                  = CFM_EMBOSS;
  CFE_IMPRINT                 = CFM_IMPRINT;
  CFE_DISABLED                = CFM_DISABLED;
  CFE_REVISED                 = CFM_REVISED;

  CFE_AUTOBACKCOLOR           = CFM_BACKCOLOR;

{ Underline types }

  CFU_CF1UNDERLINE            = $FF;    { map charformat's bit underline to CF2. }
  CFU_INVERT                  = $FE;    { For IME composition fake a selection.  }
  CFU_UNDERLINEDOTTED         = $4;     { (*) displayed as ordinary underline    }
  CFU_UNDERLINEDOUBLE         = $3;     { (*) displayed as ordinary underline    }
  CFU_UNDERLINEWORD           = $2;     { (*) displayed as ordinary underline    }
  CFU_UNDERLINE               = $1; 
  CFU_UNDERLINENONE           = 0; 

{ PARAFORMAT 2.0 masks and effects }

const
  PFM_SPACEBEFORE                     = $00000040;
  PFM_SPACEAFTER                      = $00000080;
  PFM_LINESPACING                     = $00000100; 
  PFM_STYLE                           = $00000400;
  PFM_BORDER                          = $00000800;      { (*)    }
  PFM_SHADING                         = $00001000;      { (*)    }
  PFM_NUMBERINGSTYLE                  = $00002000;      { (*)    }
  PFM_NUMBERINGTAB                    = $00004000;      { (*)    }
  PFM_NUMBERINGSTART                  = $00008000;      { (*)    }

  PFM_RTLPARA                         = $00010000; 
  PFM_KEEP                            = $00020000;      { (*)    }
  PFM_KEEPNEXT                        = $00040000;      { (*)    }
  PFM_PAGEBREAKBEFORE                 = $00080000;      { (*)    }
  PFM_NOLINENUMBER                    = $00100000;      { (*)    }
  PFM_NOWIDOWCONTROL                  = $00200000;      { (*)    }
  PFM_DONOTHYPHEN                     = $00400000;      { (*)    }
  PFM_SIDEBYSIDE                      = $00800000;      { (*)    }

  PFM_TABLE                           = $C0000000;      { (*)    }

{ Note: PARAFORMAT has no effects }

  PFM_EFFECTS = PFM_RTLPARA or PFM_KEEP or PFM_KEEPNEXT or PFM_TABLE or
    PFM_PAGEBREAKBEFORE or PFM_NOLINENUMBER or 
    PFM_NOWIDOWCONTROL or PFM_DONOTHYPHEN or PFM_SIDEBYSIDE or PFM_TABLE; 

  PFM_ALL2 = PFM_ALL or PFM_EFFECTS or PFM_SPACEBEFORE or PFM_SPACEAFTER or
    PFM_LINESPACING or PFM_STYLE or PFM_SHADING or PFM_BORDER or 
    PFM_NUMBERINGTAB or PFM_NUMBERINGSTART or PFM_NUMBERINGSTYLE;

  PFE_RTLPARA                         = PFM_RTLPARA              shr 16;
  PFE_KEEP                            = PFM_KEEP                 shr 16;    { (*)    }
  PFE_KEEPNEXT                        = PFM_KEEPNEXT             shr 16;    { (*)    }
  PFE_PAGEBREAKBEFORE                 = PFM_PAGEBREAKBEFORE      shr 16;    { (*)    }
  PFE_NOLINENUMBER                    = PFM_NOLINENUMBER         shr 16;    { (*)    }
  PFE_NOWIDOWCONTROL                  = PFM_NOWIDOWCONTROL       shr 16;    { (*)    }
  PFE_DONOTHYPHEN                     = PFM_DONOTHYPHEN          shr 16;    { (*)    }
  PFE_SIDEBYSIDE                      = PFM_SIDEBYSIDE           shr 16;    { (*)    }

  PFE_TABLEROW                        = $C000;          { These 3 options are mutually   }
  PFE_TABLECELLEND                    = $8000;          {  exclusive and each imply      }
  PFE_TABLECELL                       = $4000;          {  that para is part of a table  }

  PFA_JUSTIFY                         = 4;      { New paragraph-alignment option 2.0 (*) }

const
  SF_UNICODE = $0010;  { Unicode file of some kind }

type
  TFindTextExA = record
    chrg: TCharRange;
    lpstrText: PAnsiChar;
    chrgText: TCharRange;
  end;

  TObjectPositions = packed record 
    nmhdr: TNMHdr;
    cObjectCount: Longint;
    pcpPositions: PLongint;
  end;

  TENLink = record
    nmhdr: TNMHdr;
    msg: UINT;
    wParam: WPARAM;
    lParam: LPARAM;
    chrg: TCharRange;
  end;

  TENOleOpFailed = packed record 
    nmhdr: TNMHdr;
    iob: Longint;
    lOper: Longint;
    hr: HRESULT;
  end;

{ flags for the GETTEXTLENGTHEX data structure }

const
  GTL_DEFAULT         = 0;      { do the default (return # of chars)        }
  GTL_USECRLF         = 1;      { compute answer using CRLFs for paragraphs }
  GTL_PRECISE         = 2;      { compute a precise answer                  }
  GTL_CLOSE           = 4;      { fast computation of a "close" answer      }
  GTL_NUMCHARS        = 8;      { return the number of characters           }
  GTL_NUMBYTES        = 16;     { return the number of _bytes_              }

{ EM_GETTEXTLENGTHEX info; this struct is passed in the wparam of the msg }

type
  TGetTextLengthEx = record
    flags: DWORD;              { flags (see GTL_XXX defines)  }
    codepage: UINT;            { code page for translation    }
  end;

const
  OLEOP_DOVERB = 1;

{$ENDIF RX_D3}


{$IFDEF RX_LANGUAGE}

function CodePageFromLocale(Language: TLanguage): Integer;                // [dpv]
var
  Buf: array[0..6] of Char;
begin
  GetLocaleInfo(Language, LOCALE_IDefaultAnsiCodePage, Buf, 6);
  Result:= StrToIntDef(Buf, GetACP);
end;

function CharSetFromLocale(Language: TLanguage): TFontCharSet;           // [dpv]
var
  CP: Cardinal;
  tag: tagCHARSETINFO;
begin
  CP:= CodePageFromLocale(Language);
  TranslateCharsetInfo(CP, tag, TCI_SRCCODEPAGE);
  Result:= tag.ciCharset;
end;

{$ENDIF}


{$IFDEF RX_ENH}                          // [dpv] For use with PutRtfText

const
  EM_SETTEXTEX =       WM_USER + 97;     // https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex
  ST_DEFAULT =         $00000000;
  ST_KEEPUNDO =        $00000001;
  ST_SELECTION =       $00000002;

type
  _SetTextEx = record
    flags: DWORD;              {Option flags. It can be any reasonable combination of the following flags:
                                ST_DEFAULT:   Deletes the undo stack, discards rich-text formatting, replaces all text.
                                ST_KEEPUNDO:  Keeps the undo stack.
                                ST_SELECTION: Replaces selection and keeps rich-text formatting.  }
    codepage: UINT;            { code page for translation (CP_ACP for default, 1200 for Unicode  }
  end;
  TSetTextEX = _SetTextEx;

{$ENDIF}


const
  FT_DOWN = 1;

type
  PENLink = ^TENLink;
  PENOleOpFailed = ^TENOleOpFailed;
{  See comment *3
  ENDDROPFILES = ^TEndDropFiles;                                               // [dpv]
}
  TFindTextEx = {$IFDEF RX_D12}TFindTextExW{$ELSE}TFindTextExA{$ENDIF};

const
  EM_FINDTEXTEX = {$IFDEF RX_D12}EM_FINDTEXTEXW{$ELSE}EM_FINDTEXTEX{$ENDIF};   // [dpv] TFindTextExA => EM_FINDTEXTEX  TFindTextExW => EM_FINDTEXEXTW

type
  TTextRangeA = record
    chrg: TCharRange;
    lpstrText: PAnsiChar;
  end;
  TTextRangeW = record
    chrg: TCharRange;
    lpstrText: PWideChar;
  end;
  TTextRange = {$IFDEF RX_D12}TTextRangeW{$ELSE}TTextRangeA{$ENDIF};

{$IFDEF RX_D3}
function ResStr(const Ident: string): string;
begin
  Result := Ident;
end;
{$ELSE}
function ResStr(Ident: Cardinal): string;
begin
  Result := LoadStr(Ident);
end;
{$ENDIF}

{ TRxTextAttributes }

const
  AttrFlags: array[TRxAttributeType] of Word = (0, SCF_SELECTION,
    SCF_WORD or SCF_SELECTION);

constructor TRxTextAttributes.Create(AOwner: TRxCustomRichEdit;
  AttributeType: TRxAttributeType);
begin
  inherited Create;
  RichEdit := AOwner;
  FType := AttributeType;
end;

procedure TRxTextAttributes.InitFormat(var Format: TCharFormat2);
begin
  FillChar(Format, SizeOf(Format), 0);
  if RichEditVersion >= 2 then Format.cbSize := SizeOf(Format)
  else Format.cbSize := SizeOf(TCharFormat);
end;

function TRxTextAttributes.GetConsistentAttributes: TRxConsistentAttributes;
var
  Format: TCharFormat2;
begin
  Result := [];
  if RichEdit.HandleAllocated and (FType <> atDefaultText) then begin
    InitFormat(Format);
    SendMessage(RichEdit.Handle, EM_GETCHARFORMAT, AttrFlags[FType], LPARAM(@Format));
    with Format do begin
      if (dwMask and CFM_BOLD) <> 0 then Include(Result, caBold);
      if (dwMask and CFM_COLOR) <> 0 then Include(Result, caColor);
      if (dwMask and CFM_FACE) <> 0 then Include(Result, caFace);
      if (dwMask and CFM_ITALIC) <> 0 then Include(Result, caItalic);
      if (dwMask and CFM_SIZE) <> 0 then Include(Result, caSize);
      if (dwMask and CFM_STRIKEOUT) <> 0 then Include(Result, caStrikeOut);
      if (dwMask and CFM_UNDERLINE) <> 0 then Include(Result, caUnderline);
      if (dwMask and CFM_PROTECTED) <> 0 then Include(Result, caProtected);
      if (dwMask and CFM_OFFSET) <> 0 then Include(Result, caOffset);
      if (dwMask and CFM_SPACING) <> 0 then Include(Result, caSpacing);
      if (dwMask and CFM_KERNING) <> 0 then Include(Result, caKerning);
      if (dwMask and CFM_UNDERLINETYPE) <> 0 then Include(Result, caULType);
      if (dwMask and CFM_ANIMATION) <> 0 then Include(Result, caAnimation);
      if (dwMask and CFM_SMALLCAPS) <> 0 then Include(Result, caSmallCaps);
      if (dwMask and CFM_ALLCAPS) <> 0 then Include(Result, caAllCaps);
      if (dwMask and CFM_HIDDEN) <> 0 then Include(Result, caHidden);
      if (dwMask and CFM_OUTLINE) <> 0 then Include(Result, caOutline);
      if (dwMask and CFM_SHADOW) <> 0 then Include(Result, caShadow);
      if (dwMask and CFM_EMBOSS) <> 0 then Include(Result, caEmboss);
      if (dwMask and CFM_IMPRINT) <> 0 then Include(Result, caImprint);
      if (dwMask and CFM_HIDDEN) <> 0 then Include(result, caHidden);
      if RichEditVersion >= 2 then begin
        if (dwMask and CFM_LCID) <> 0 then Include(Result, caLanguage);             // [mj]
        if (dwMask and CFM_LINK) <> 0 then Include(Result, caLink);
        if (dwMask and CFM_BACKCOLOR) <> 0 then Include(Result, caBackColor);
        if (dwMask and CFM_DISABLED) <> 0 then Include(Result, caDisabled);
        if (dwMask and CFM_WEIGHT) <> 0 then Include(Result, caWeight);
        if (dwMask and CFM_SUBSCRIPT) <> 0 then Include(Result, caSubscript);
        if (dwMask and CFM_REVAUTHOR) <> 0 then Include(Result, caRevAuthor);
      end;
    end;
  end;
end;

procedure TRxTextAttributes.GetAttributes(var Format: TCharFormat2);
begin
  InitFormat(Format);
  if RichEdit.HandleAllocated then
    SendMessage(RichEdit.Handle, EM_GETCHARFORMAT, AttrFlags[FType], LPARAM(@Format));
end;

procedure TRxTextAttributes.SetAttributes(var Format: TCharFormat2);
begin
  if RichEdit.HandleAllocated then
    SendMessage(RichEdit.Handle, EM_SETCHARFORMAT, AttrFlags[FType], LPARAM(@Format));
end;

{$IFNDEF VER90}
function TRxTextAttributes.GetCharset: TFontCharset;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  Result := Format.bCharset;
end;

procedure TRxTextAttributes.SetCharset(Value: TFontCharset);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do
  begin
    //dwMask := CFM_CHARSET;
    dwMask := dwMask or CFM_CHARSET;                          // [mj]
    bCharSet := Value;
  end;
  SetAttributes(Format);
end;
{$ENDIF}

function TRxTextAttributes.GetProtected: Boolean;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  with Format do
    Result := (dwEffects and CFE_PROTECTED) <> 0;
end;

procedure TRxTextAttributes.SetProtected(Value: Boolean);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_PROTECTED;
    if Value then dwEffects := CFE_PROTECTED;
  end;
  SetAttributes(Format);
end;


 {Return link style from selection: link style not set (lsNone), link style set (lsLink), link style mixed (partially set) (lsMixed) }
function TRxTextAttributes.GetLinkStyle: TRxLinkStyle;
var
  Format: TCharFormat2;
begin
  Result := lsNone;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  if (Format.dwMask and CFE_LINK) = 0 then
      Result:=  lsMixed
  else
      if (Format.dwEffects and CFE_LINK) <> 0 then
        Result:= lsLink;
end;


function TRxTextAttributes.GetLink: Boolean;
var
  Format: TCharFormat2;
begin
  Result := False;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  with Format do Result := (dwEffects and CFE_LINK) <> 0;
end;

procedure TRxTextAttributes.SetLink(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_LINK;
    if Value then dwEffects := CFE_LINK;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetRevAuthorIndex: Byte;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  Result := Format.bRevAuthor;
end;

procedure TRxTextAttributes.SetRevAuthorIndex(Value: Byte);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_REVAUTHOR;
    bRevAuthor := Value;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetHidden: Boolean;
var
  Format: TCharFormat2;
begin
  Result := False;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_HIDDEN <> 0;
end;

procedure TRxTextAttributes.SetHidden(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_HIDDEN;
    if Value then dwEffects := CFE_HIDDEN;
  end;
  SetAttributes(Format);
end;


{$IFDEF RX_LANGUAGE}

function TRxTextAttributes.GetLanguage : TLanguage;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
  begin
    result := 1033; // US English
    Exit;
  end;
  GetAttributes(Format);
  Result := Format.lid;
end;

procedure TRxTextAttributes.SetLanguage(Value: TLanguage);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_LCID;
    lid := Value;
  end;
  SetAttributes(Format);
end;

{$ENDIF}


function TRxTextAttributes.GetDisabled: Boolean;
var
  Format: TCharFormat2;
begin
  Result := False;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_DISABLED <> 0;
end;

procedure TRxTextAttributes.SetDisabled(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_DISABLED;
    if Value then dwEffects := CFE_DISABLED;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetColor: TColor;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  with Format do
    if (dwEffects and CFE_AUTOCOLOR) <> 0 then Result := clWindowText
    else Result := crTextColor;
end;

procedure TRxTextAttributes.SetColor(Value: TColor);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_COLOR;
    if (Value = clWindowText) or (Value = clDefault) then
      dwEffects := CFE_AUTOCOLOR
    else crTextColor := ColorToRGB(Value);
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetBackColor: TColor;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then begin
    Result := clWindow;
    Exit;
  end;
  GetAttributes(Format);
  with Format do
    if (dwEffects and CFE_AUTOBACKCOLOR) <> 0 then Result := clWindow
    else Result := crBackColor;
end;

procedure TRxTextAttributes.SetBackColor(Value: TColor);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_BACKCOLOR;
    if (Value = clWindow) or (Value = clDefault) then
      dwEffects := CFE_AUTOBACKCOLOR
    else crBackColor := ColorToRGB(Value);
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetName: TFontName;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  Result := TFontName(Format.szFaceName);
end;

procedure TRxTextAttributes.SetName(Value: TFontName);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_FACE;
    {$IFDEF RX_D18}System.AnsiStrings.{$ENDIF}StrPLCopy(szFaceName, AnsiString(Value), SizeOf(szFaceName));
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetStyle: TFontStyles;
var
  Format: TCharFormat2;
begin
  Result := [];
  GetAttributes(Format);
  with Format do begin
    if (dwEffects and CFE_BOLD) <> 0 then Include(Result, fsBold);
    if (dwEffects and CFE_ITALIC) <> 0 then Include(Result, fsItalic);
    if (dwEffects and CFE_UNDERLINE) <> 0 then Include(Result, fsUnderline);
    if (dwEffects and CFE_STRIKEOUT) <> 0 then Include(Result, fsStrikeOut);
  end;
end;

procedure TRxTextAttributes.SetStyle(Value: TFontStyles);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_BOLD or CFM_ITALIC or CFM_UNDERLINE or CFM_STRIKEOUT;
    if fsBold in Value then dwEffects := dwEffects or CFE_BOLD;
    if fsItalic in Value then dwEffects := dwEffects or CFE_ITALIC;
    if fsUnderline in Value then dwEffects := dwEffects or CFE_UNDERLINE;
    if fsStrikeOut in Value then dwEffects := dwEffects or CFE_STRIKEOUT;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.SetBold(Value: boolean);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_BOLD;
    if Value then dwEffects := CFE_BOLD;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.SetItalic(Value: boolean);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_ITALIC;
    if Value then dwEffects := CFE_ITALIC;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.SetUnderline(Value: boolean);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_UNDERLINE;
    if Value then dwEffects := CFE_UNDERLINE;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.SetStrikeOut(Value: boolean);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_STRIKEOUT;
    if Value then dwEffects := CFE_STRIKEOUT;
  end;
  SetAttributes(Format);
end;


function TRxTextAttributes.GetSpacing: Double;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= 0;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.sSpacing/20;
end;

procedure TRxTextAttributes.SetSpacing(Value: Double);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_SPACING;
    sSpacing := Round(Value*20);
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetKerning: Double;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= 0;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.wKerning/20;
end;

procedure TRxTextAttributes.SetKerning(Value: Double);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_KERNING;
    wKerning := Round(Value*20);
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetUnderlineType: TUnderlineType;
var
  Format: TCharFormat2;
begin
  Result := utNone;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  with Format do begin
    if (dwEffects and CFE_UNDERLINE <> 0) and
      (dwMask and CFM_UNDERLINETYPE = CFM_UNDERLINETYPE) then
      Result := TUnderlineType(bUnderlineType);
  end;
end;

procedure TRxTextAttributes.SetUnderlineType(Value: TUnderlineType);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := CFM_UNDERLINETYPE or CFM_UNDERLINE;
    bUnderlineType := Ord(Value);
    if Value <> utNone then dwEffects := dwEffects or CFE_UNDERLINE;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetSmallCaps: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_SMALLCAPS <>0;
end;

procedure TRxTextAttributes.SetSmallCaps(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_SMALLCAPS;
    if Value then
      dwEffects:= CFE_SMALLCAPS;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetAllCaps: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_ALLCAPS <>0;
end;

procedure TRxTextAttributes.SetAllCaps(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_ALLCAPS;
    if Value then
      dwEffects:= CFE_ALLCAPS;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetOutline: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_OUTLINE <>0;
end;

procedure TRxTextAttributes.SetOutline(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_OUTLINE;
    if Value then
      dwEffects:= CFE_OUTLINE;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetShadow: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_SHADOW <>0;
end;

procedure TRxTextAttributes.SetShadow(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_SHADOW;
    if Value then
      dwEffects:= CFE_SHADOW;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetEmboss: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_EMBOSS <>0;
end;

procedure TRxTextAttributes.SetEmboss(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_EMBOSS;
    if Value then
      dwEffects:= CFE_EMBOSS;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetImprint: Boolean;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= False;
      Exit;
    end;
  GetAttributes(Format);
  Result := Format.dwEffects and CFE_IMPRINT <>0;
end;

procedure TRxTextAttributes.SetImprint(Value: Boolean);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_IMPRINT;
    if Value then
      dwEffects:= CFE_IMPRINT;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetAnimation: TAnimationType;
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    begin
      Result:= aniNone;
      Exit;
    end;
  GetAttributes(Format);
  Result := TAnimationType(Format.bAnimation);
end;

procedure TRxTextAttributes.SetAnimation(Value: TAnimationType);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then
    Exit;
  InitFormat(Format);
  with Format do
  begin
    dwMask := CFM_ANIMATION;
    bAnimation := Byte(Value);
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetOffset: Integer;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  Result := Format.yOffset div 20;
end;

procedure TRxTextAttributes.SetOffset(Value: Integer);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := DWORD(CFM_OFFSET);
    yOffset := Value * 20;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetSize: Integer;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  Result := Format.yHeight div 20;
end;

procedure TRxTextAttributes.SetSize(Value: Integer);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    dwMask := DWORD(CFM_SIZE);
    yHeight := Value * 20;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetHeight: Integer;
begin
  Result := MulDiv(Size, RichEdit.FScreenLogPixels, 72);
end;

procedure TRxTextAttributes.SetHeight(Value: Integer);
begin
  Size := MulDiv(Value, 72, RichEdit.FScreenLogPixels);
end;

function TRxTextAttributes.GetPitch: TFontPitch;
var
  Format: TCharFormat2;
begin
  GetAttributes(Format);
  case (Format.bPitchAndFamily and $03) of
    DEFAULT_PITCH: Result := fpDefault;
    VARIABLE_PITCH: Result := fpVariable;
    FIXED_PITCH: Result := fpFixed;
    else Result := fpDefault;
  end;
end;

procedure TRxTextAttributes.SetPitch(Value: TFontPitch);
var
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    case Value of
      fpVariable: bPitchAndFamily := VARIABLE_PITCH;
      fpFixed: bPitchAndFamily := FIXED_PITCH;
      else bPitchAndFamily := DEFAULT_PITCH;
    end;
  end;
  SetAttributes(Format);
end;

function TRxTextAttributes.GetSubscriptStyle: TSubscriptStyle;
var
  Format: TCharFormat2;
begin
  Result := ssNone;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Format);
  with Format do begin
    if (dwEffects and CFE_SUBSCRIPT) <> 0 then
      Result := ssSubscript
    else if (dwEffects and CFE_SUPERSCRIPT) <> 0 then
      Result := ssSuperscript;
  end;
end;

procedure TRxTextAttributes.SetSubscriptStyle(Value: TSubscriptStyle);
var
  Format: TCharFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitFormat(Format);
  with Format do begin
    dwMask := DWORD(CFM_SUBSCRIPT);
    case Value of
      ssSubscript: dwEffects := CFE_SUBSCRIPT;
      ssSuperscript: dwEffects := CFE_SUPERSCRIPT;
    end;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.AssignFont(Font: TFont);
var
  LogFont: TLogFont;
  Format: TCharFormat2;
begin
  InitFormat(Format);
  with Format do begin
    case Font.Pitch of
      fpVariable: bPitchAndFamily := VARIABLE_PITCH;
      fpFixed: bPitchAndFamily := FIXED_PITCH;
      else bPitchAndFamily := DEFAULT_PITCH;
    end;
    dwMask := dwMask or CFM_SIZE or CFM_BOLD or CFM_ITALIC or
      CFM_UNDERLINE or CFM_STRIKEOUT or CFM_FACE or CFM_COLOR;
    yHeight := Font.Size * 20;
    if fsBold in Font.Style then dwEffects := dwEffects or CFE_BOLD;
    if fsItalic in Font.Style then dwEffects := dwEffects or CFE_ITALIC;
    if fsUnderline in Font.Style then dwEffects := dwEffects or CFE_UNDERLINE;
    if fsStrikeOut in Font.Style then dwEffects := dwEffects or CFE_STRIKEOUT;
    {$IFDEF RX_D18}System.AnsiStrings.{$ENDIF}StrPLCopy(szFaceName, Ansistring(Font.Name), SizeOf(szFaceName));
    if (Font.Color = clWindowText) or (Font.Color = clDefault) then
      dwEffects := CFE_AUTOCOLOR
    else crTextColor := ColorToRGB(Font.Color);
{$IFNDEF VER90}
    dwMask := dwMask or CFM_CHARSET;
    bCharSet := Font.Charset;
{$ENDIF}
    if GetObject(Font.Handle, SizeOf(LogFont), @LogFont) <> 0 then begin
      dwMask := dwMask or DWORD(CFM_WEIGHT);
      wWeight := Word(LogFont.lfWeight);
    end;
  end;
  SetAttributes(Format);
end;

procedure TRxTextAttributes.Assign(Source: TPersistent);
var
  Format: TCharFormat2;
begin
  if Source is TFont then AssignFont(TFont(Source))
  else if Source is TTextAttributes then begin
    Name := TTextAttributes(Source).Name;
{$IFDEF RX_D3}
    Charset := TTextAttributes(Source).Charset;
{$ENDIF}
    Style := TTextAttributes(Source).Style;
    Pitch := TTextAttributes(Source).Pitch;
    Color := TTextAttributes(Source).Color;
  end
  else if Source is TRxTextAttributes then begin
    TRxTextAttributes(Source).GetAttributes(Format);
    SetAttributes(Format);

{$IFDEF RX_LANGUAGE}
    { Although in SetAttributes() Format has dwMask set to CMF_ALL2, lid (Language) is ignored.
	  However, if we call EM_SETCHARFORMAT with dwMask = CFM_LCID then it is applied  [dpv] }
    Language := TRxTextAttributes(Source).Language;                 // [mj]
{$ENDIF}
  end
  else inherited Assign(Source);
end;

procedure TRxTextAttributes.AssignTo(Dest: TPersistent);
begin
  if Dest is TFont then begin
{$IFDEF RX_LANGUAGE}
    TFont(Dest).Charset := CharsetFromLocale(Language);             // [mj]
{$ENDIF}
    TFont(Dest).Color := Color;
    TFont(Dest).Name := Name;
{$IFNDEF VER90}
    TFont(Dest).Charset := Charset;
{$ENDIF}
    TFont(Dest).Style := Style;
    TFont(Dest).Size := Size;
    TFont(Dest).Pitch := Pitch;
  end
{$IFDEF RX_LANGUAGE}
  else
  if Dest is TRxTextAttributes then                                // [mj]
  begin
    TRxTextAttributes(Dest).Language := Language;
  end
{$ENDIF}
  else
  if Dest is TTextAttributes then
  begin
    TTextAttributes(Dest).Color := Color;
    TTextAttributes(Dest).Name := Name;
{$IFDEF RX_D3}
    TTextAttributes(Dest).Charset := Charset;
{$ENDIF}
{$IFDEF RX_LANGUAGE}
    TTextAttributes(Dest).Charset := CharsetFromLocale(Language);  // [mj]
{$ENDIF}
    TTextAttributes(Dest).Style := Style;
    TTextAttributes(Dest).Pitch := Pitch;
  end
  else inherited AssignTo(Dest);
end;

{ TRxParaAttributes }

constructor TRxParaAttributes.Create(AOwner: TRxCustomRichEdit);
begin
  inherited Create;
  RichEdit := AOwner;
end;

procedure TRxParaAttributes.InitPara(var Paragraph: TParaFormat2);
begin
  FillChar(Paragraph, SizeOf(Paragraph), 0);
  if RichEditVersion >= 2 then
    Paragraph.cbSize := SizeOf(Paragraph)
  else
    Paragraph.cbSize := SizeOf(TParaFormat);
end;

procedure TRxParaAttributes.GetAttributes(var Paragraph: TParaFormat2);
begin
  InitPara(Paragraph);
  if RichEdit.HandleAllocated then
    SendMessage(RichEdit.Handle, EM_GETPARAFORMAT, 0, LPARAM(@Paragraph));
end;

procedure TRxParaAttributes.SetAttributes(var Paragraph: TParaFormat2);
begin
{$IFDEF RX_D4}
  RichEdit.HandleNeeded; { we REALLY need the handle for BiDi }
{$ENDIF}
  if RichEdit.HandleAllocated then begin
{$IFDEF RX_D4}
    if RichEdit.UseRightToLeftAlignment then
      if Paragraph.wAlignment = PFA_LEFT then
        Paragraph.wAlignment := PFA_RIGHT
      else if Paragraph.wAlignment = PFA_RIGHT then
        Paragraph.wAlignment := PFA_LEFT;
{$ENDIF}
    SendMessage(RichEdit.Handle, EM_SETPARAFORMAT, 0, LPARAM(@Paragraph));
  end;
end;

function TRxParaAttributes.GetRTL: Boolean;                              // [dpv]
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := (Paragraph.wReserved and PFE_RTLPARA) <> 0;
end;

procedure TRxParaAttributes.SetRTL(Value: Boolean);                      // [dpv]
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);

  with Paragraph do
  begin
    dwMask := PFM_RTLPARA;
    wReserved := 0;                 // wEffects is also known as wReserved for Rich Edit 1.0 because it was reserved
    if Value then
       wReserved := PFE_RTLPARA;
  end;

  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetAlignment: TParaAlignment;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := TParaAlignment(Paragraph.wAlignment - 1);
end;

procedure TRxParaAttributes.SetAlignment(Value: TParaAlignment);
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_ALIGNMENT;
    wAlignment := Ord(Value) + 1;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetNumbering: TRxNumbering;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := TRxNumbering(Paragraph.wNumbering);
  if RichEditVersion = 1 then
    if Result <> nsNone then Result := nsBullet;
end;

function TRxParaAttributes.GetNumberingStart: integer;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := integer(Paragraph.wNumberingStart);
  if RichEditVersion = 1 then
     result := 0;
end;


procedure TRxParaAttributes.SetNumberingStart( Value : integer );
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion = 1 then exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_NUMBERINGSTART;
    wNumberingStart := value;
  end;
  SetAttributes(Paragraph);
end;


procedure TRxParaAttributes.SetNumbering(Value: TRxNumbering);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion = 1 then
    if Value <> nsNone then Value := TRxNumbering(PFN_BULLET);
  case Value of
    nsNone: LeftIndent := 0;
    else if LeftIndent < 10 then LeftIndent := 10;
  end;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_NUMBERING;
    wNumbering := Ord(Value);
    wNumberingStart := 1;                                      // [mj]
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetNumberingStyle: TRxNumberingStyle;
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then
    Result := nsSimple
  else begin
    GetAttributes(Paragraph);
    Result := TRxNumberingStyle(Paragraph.wNumberingStyle);
  end;
end;

procedure TRxParaAttributes.SetNumberingStyle(Value: TRxNumberingStyle);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_NUMBERINGSTYLE;
    wNumberingStyle := Ord(Value);
  end;
  SetAttributes(Paragraph);
end;

procedure TRxParaAttributes.SetNumberingList(numbering: TRxNumbering;
                                             numberingStyle: TRxNumberingStyle;
                                             numberingStart: integer;
                                             LeftIndent: integer);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion = 1 then
    if numbering <> nsNone then numbering := TRxNumbering(PFN_BULLET);

  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_NUMBERING or PFM_NUMBERINGSTYLE or PFM_NUMBERINGSTART or PFM_OFFSET;
    wNumberingStyle := word(numberingStyle);
    wNumbering := Ord(numbering);
    wNumberingStart := numberingStart;
    dxOffset := LeftIndent * 20;
  end;
  SetAttributes(Paragraph);
end;


function TRxParaAttributes.GetNumberingTab: Word;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.wNumberingTab div 20;
end;

procedure TRxParaAttributes.SetNumberingTab(Value: Word);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_NUMBERINGTAB;
    wNumberingTab := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetFirstIndent: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dxStartIndent div 20;
end;

{   Indentation of the paragraph's first line, in points.
    The indentation of subsequent lines depends on the dxOffset member (LeftIndent property).
 => The indentation specified is an absolute indentation from the left margin.}
procedure TRxParaAttributes.SetFirstIndent(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_STARTINDENT;
    dxStartIndent := Value * 20;
  end;
  SetAttributes(Paragraph);
end;


{  Indentation of the paragraph's first line, in points.
   The indentation of subsequent lines depends on the dxOffset member (LeftIndent property).
=> The indentation specified is relative to the paragraph's current indentation. }
procedure TRxParaAttributes.SetFirstIndentRelative(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_OFFSETINDENT;
    dxStartIndent := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetHeadingStyle: THeadingStyle;
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 3 then Result := 0
  else begin
    GetAttributes(Paragraph);
    Result := Paragraph.sStyle;
  end;
end;

procedure TRxParaAttributes.SetHeadingStyle(Value: THeadingStyle);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 3 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_STYLE;
    sStyle := Value;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetLeftIndent: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dxOffset div 20;
end;

procedure TRxParaAttributes.SetLeftIndent(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_OFFSET;
    dxOffset := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetRightIndent: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dxRightIndent div 20;
end;

procedure TRxParaAttributes.SetRightIndent(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  InitPara(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_RIGHTINDENT;
    dxRightIndent := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetSpaceAfter: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dySpaceAfter div 20;
end;

procedure TRxParaAttributes.SetSpaceAfter(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_SPACEAFTER;
    dySpaceAfter := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetSpaceBefore: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dySpaceBefore div 20;
end;

procedure TRxParaAttributes.SetSpaceBefore(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_SPACEBEFORE;
    dySpaceBefore := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetLineSpacing: Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.dyLineSpacing div 20;
end;

procedure TRxParaAttributes.SetLineSpacing(Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  GetAttributes(Paragraph);
  with Paragraph do begin
    dwMask := PFM_LINESPACING;
    dyLineSpacing := Value * 20;
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetLineSpacingRule: TLineSpacingRule;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := TLineSpacingRule(Paragraph.bLineSpacingRule);
end;

procedure TRxParaAttributes.SetLineSpacingRule(Value: TLineSpacingRule);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  GetAttributes(Paragraph);
  with Paragraph do begin
    dwMask := PFM_LINESPACING;
    bLineSpacingRule := Ord(Value);
  end;
  SetAttributes(Paragraph);
end;

function TRxParaAttributes.GetTab(Index: Byte): Longint;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.rgxTabs[Index] div 20;
end;

procedure TRxParaAttributes.SetTab(Index: Byte; Value: Longint);
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  with Paragraph do
  begin
    rgxTabs[Index] := Value * 20;
    dwMask := PFM_TABSTOPS;
    if cTabCount < Index then cTabCount := Index;
    SetAttributes(Paragraph);
  end;
end;

function TRxParaAttributes.GetTabCount: Integer;
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  Result := Paragraph.cTabCount;
end;

procedure TRxParaAttributes.SetTabCount(Value: Integer);
var
  Paragraph: TParaFormat2;
begin
  GetAttributes(Paragraph);
  with Paragraph do
  begin
    dwMask := PFM_TABSTOPS;
    cTabCount := Value;
    SetAttributes(Paragraph);
  end;
end;

function TRxParaAttributes.GetTableStyle: TParaTableStyle;
var
  Paragraph: TParaFormat2;
begin
  Result := tsNone;
  if RichEditVersion < 2 then Exit;
  GetAttributes(Paragraph);
  with Paragraph do begin
    if (wReserved and PFE_TABLEROW) <> 0 then
      Result := tsTableRow
    else if (wReserved and PFE_TABLECELLEND) <> 0 then
      Result := tsTableCellEnd
    else if (wReserved and PFE_TABLECELL) <> 0 then
      Result := tsTableCell;
  end;
end;

procedure TRxParaAttributes.SetTableStyle(Value: TParaTableStyle);
var
  Paragraph: TParaFormat2;
begin
  if RichEditVersion < 2 then Exit;
  InitPara(Paragraph);
  with Paragraph do begin
    dwMask := PFM_TABLE;
    case Value of
      tsTableRow: wReserved := PFE_TABLEROW;
      tsTableCellEnd: wReserved := PFE_TABLECELLEND;
      tsTableCell: wReserved := PFE_TABLECELL;
    end;
  end;
  SetAttributes(Paragraph);
end;

procedure TRxParaAttributes.AssignTo(Dest: TPersistent);
var
  I: Integer;
begin
  if Dest is TParaAttributes then begin
    with TParaAttributes(Dest) do begin
      if Self.Alignment = paJustify then Alignment := taLeftJustify
      else Alignment := TAlignment(Self.Alignment);
      FirstIndent := Self.FirstIndent;
      LeftIndent := Self.LeftIndent;
      RightIndent := Self.RightIndent;
      if Self.Numbering <> nsNone then
        Numbering := TNumberingStyle(nsBullet)
      else Numbering := TNumberingStyle(nsNone);
      for I := 0 to MAX_TAB_STOPS - 1 do
        Tab[I] := Self.Tab[I];
    end;
  end
  else inherited AssignTo(Dest);
end;

procedure TRxParaAttributes.Assign(Source: TPersistent);
var
  I: Integer;
  Paragraph: TParaFormat2;
begin
  if Source is TParaAttributes then begin
    Alignment := TParaAlignment(TParaAttributes(Source).Alignment);
    FirstIndent := TParaAttributes(Source).FirstIndent;
    LeftIndent := TParaAttributes(Source).LeftIndent;
    RightIndent := TParaAttributes(Source).RightIndent;
    Numbering := TRxNumbering(TParaAttributes(Source).Numbering);
    for I := 0 to MAX_TAB_STOPS - 1 do
      Tab[I] := TParaAttributes(Source).Tab[I];
  end
  else if Source is TRxParaAttributes then begin
    TRxParaAttributes(Source).GetAttributes(Paragraph);
    SetAttributes(Paragraph);
  end
  else inherited Assign(Source);
end;

{ OLE utility routines }

function WStrLen(Str: PWideChar): Integer;
begin
  Result := 0;
  while Str[Result] <> #0 do Inc(Result);
end;

procedure ReleaseObject(var Obj);
begin
  if IUnknown(Obj) <> nil then begin
{$IFNDEF RX_D3}
    IUnknown(Obj).Release;
{$ENDIF}
    IUnknown(Obj) := nil;
  end;
end;

procedure CreateStorage(var Storage: IStorage);
var
  LockBytes: ILockBytes;
begin
  OleCheck(CreateILockBytesOnHGlobal(0, True, LockBytes));
  try
    OleCheck(StgCreateDocfileOnILockBytes(LockBytes, STGM_READWRITE
      or STGM_SHARE_EXCLUSIVE or STGM_CREATE, 0, Storage));
  finally
    ReleaseObject(LockBytes);
  end;
end;

procedure DestroyMetaPict(MetaPict: HGlobal);
begin
  if MetaPict <> 0 then begin
    DeleteMetaFile(PMetaFilePict(GlobalLock(MetaPict))^.hMF);
    GlobalUnlock(MetaPict);
    GlobalFree(MetaPict);
  end;
end;

function OleSetDrawAspect(OleObject: IOleObject; Iconic: Boolean;
  IconMetaPict: HGlobal; var DrawAspect: Longint): HResult;
var
  OleCache: IOleCache;
  EnumStatData: IEnumStatData;
  OldAspect, AdviseFlags, Connection: Longint;
  TempMetaPict: HGlobal;
  FormatEtc: TFormatEtc;
  Medium: TStgMedium;
  ClassID: TCLSID;
  StatData: TStatData;
begin
  Result := S_OK;
  OldAspect := DrawAspect;
  if Iconic then begin
    DrawAspect := DVASPECT_ICON;
    AdviseFlags := ADVF_NODATA;
  end
  else begin
    DrawAspect := DVASPECT_CONTENT;
    AdviseFlags := ADVF_PRIMEFIRST;
  end;
  if (DrawAspect <> OldAspect) or (DrawAspect = DVASPECT_ICON) then begin
{$IFDEF RX_D3}
    Result := OleObject.QueryInterface(IOleCache, OleCache);
{$ELSE}
    Result := OleObject.QueryInterface(IID_IOleCache, OleCache);
{$ENDIF}
    if Succeeded(Result) then
    try
      if DrawAspect <> OldAspect then begin
        { Setup new cache with the new aspect }
        FillChar(FormatEtc, SizeOf(FormatEtc), 0);
        FormatEtc.dwAspect := DrawAspect;
        FormatEtc.lIndex := -1;
        Result := OleCache.Cache(FormatEtc, AdviseFlags, Connection);
      end;
      if Succeeded(Result) and (DrawAspect = DVASPECT_ICON) then begin
        TempMetaPict := 0;
        if IconMetaPict = 0 then begin
          if Succeeded(OleObject.GetUserClassID(ClassID)) then begin
            TempMetaPict := OleGetIconOfClass(ClassID, nil, True);
            IconMetaPict := TempMetaPict;
          end;
        end;
        try
          FormatEtc.cfFormat := CF_METAFILEPICT;
          FormatEtc.ptd := nil;
          FormatEtc.dwAspect := DVASPECT_ICON;
          FormatEtc.lIndex := -1;
          FormatEtc.tymed := TYMED_MFPICT;
          Medium.tymed := TYMED_MFPICT;
          Medium.hMetaFilePict := IconMetaPict;
          Medium.unkForRelease := nil;
          Result := OleCache.SetData(FormatEtc, Medium, False);
        finally
          DestroyMetaPict(TempMetaPict);
        end;
      end;
      if Succeeded(Result) and (DrawAspect <> OldAspect) then begin
        { remove any existing caches that are set up for the old display aspect }
        OleCache.EnumCache(EnumStatData);
        if EnumStatData <> nil then
        try
          while EnumStatData.Next(1, StatData, nil) = 0 do
            if StatData.formatetc.dwAspect = OldAspect then
              OleCache.Uncache(StatData.dwConnection);
        finally
          ReleaseObject(EnumStatData);
        end;
      end;
    finally
      ReleaseObject(OleCache);
    end;
    if Succeeded(Result) and (DrawAspect <> DVASPECT_ICON) then
      OleObject.Update;
  end;
end;

function GetIconMetaPict(OleObject: IOleObject; DrawAspect: Longint): HGlobal;
var
  DataObject: IDataObject;
  FormatEtc: TFormatEtc;
  Medium: TStgMedium;
  ClassID: TCLSID;
begin
  Result := 0;
  if DrawAspect = DVASPECT_ICON then begin
{$IFDEF RX_D3}
    OleObject.QueryInterface(IDataObject, DataObject);
{$ELSE}
    OleObject.QueryInterface(IID_IDataObject, DataObject);
{$ENDIF}
    if DataObject <> nil then begin
      FormatEtc.cfFormat := CF_METAFILEPICT;
      FormatEtc.ptd := nil;
      FormatEtc.dwAspect := DVASPECT_ICON;
      FormatEtc.lIndex := -1;
      FormatEtc.tymed := TYMED_MFPICT;
      if Succeeded(DataObject.GetData(FormatEtc, Medium)) then
        Result := Medium.hMetaFilePict;
      ReleaseObject(DataObject);
    end;
  end;
  if Result = 0 then begin
    OleCheck(OleObject.GetUserClassID(ClassID));
    Result := OleGetIconOfClass(ClassID, nil, True);
  end;
end;

{ Return the first piece of a moniker }

function OleStdGetFirstMoniker(Moniker: IMoniker): IMoniker;
var
  Mksys: Longint;
  EnumMoniker: IEnumMoniker;
begin
  Result := nil;
  if Moniker <> nil then begin
    if (Moniker.IsSystemMoniker(Mksys) = 0) and
      (Mksys = MKSYS_GENERICCOMPOSITE) then
    begin
      if Moniker.Enum(True, EnumMoniker) <> 0 then Exit;
      EnumMoniker.Next(1, Result, nil);
      ReleaseObject(EnumMoniker);
    end
    else begin
{$IFNDEF RX_D3}
      Moniker.AddRef;
{$ENDIF}
      Result := Moniker;
    end;
  end;
end;

{ Return length of file moniker piece of the given moniker }

function OleStdGetLenFilePrefixOfMoniker(Moniker: IMoniker): Integer;
var
  MkFirst: IMoniker;
  BindCtx: IBindCtx;
  Mksys: Longint;
  P: PWideChar;
begin
  Result := 0;
  if Moniker <> nil then begin
    MkFirst := OleStdGetFirstMoniker(Moniker);
    if MkFirst <> nil then begin
      if (MkFirst.IsSystemMoniker(Mksys) = 0) and
        (Mksys = MKSYS_FILEMONIKER) then
      begin
        if CreateBindCtx(0, BindCtx) = 0 then begin
          if (MkFirst.GetDisplayName(BindCtx, nil, P) = 0) and (P <> nil) then
          begin
            Result := WStrLen(P);
            CoTaskMemFree(P);
          end;
          ReleaseObject(BindCtx);
        end;
      end;
      ReleaseObject(MkFirst);
    end;
  end;
end;

function CoAllocCStr(const S: string): PChar;
begin
  //Result := StrCopy(CoTaskMemAlloc(Length(S) + 1), PChar(S));
  Result := StrCopy(CoTaskMemAlloc(Length(S) * Sizeof(Char) + 1), PChar(S));    // [dpv]
end;

function WStrToString(P: PWideChar): string;
begin
  Result := '';
  if P <> nil then begin
    Result := WideCharToString(P);
    CoTaskMemFree(P);
  end;
end;

function GetFullNameStr(OleObject: IOleObject): string;
var
  P: PWideChar;
begin
  OleObject.GetUserType(USERCLASSTYPE_FULL, P);
  Result := WStrToString(P);
end;

function GetShortNameStr(OleObject: IOleObject): string;
var
  P: PWideChar;
begin
  OleObject.GetUserType(USERCLASSTYPE_SHORT, P);
  Result := WStrToString(P);
end;

function GetDisplayNameStr(OleLink: IOleLink): string;
var
  P: PWideChar;
begin
  OleLink.GetSourceDisplayName(P);
  Result := WStrToString(P);
end;

{$IFDEF RX_D3}
function GetVCLFrameForm(Form: TCustomForm): IVCLFrameForm;
begin
  if Form.OleFormObject = nil then TOleForm.Create(Form);
  Result := Form.OleFormObject as IVCLFrameForm;
end;

function IsFormMDIChild(Form: TCustomForm): Boolean;
begin
  Result := (Form is TForm) and (TForm(Form).FormStyle = fsMDIChild);
end;
{$ENDIF}

{ Clipboard formats }

var
  CFEmbeddedObject: Integer;
  CFLinkSource: Integer;
  CFRtf: Integer;
  CFRtfNoObjs: Integer;
  CFHtml: Integer;                                 // [dpv]

const
{$IFNDEF RX_D3}
  CF_RTFNOOBJS = 'Rich Text Format Without Objects';
{$ENDIF}
  CF_EMBEDDEDOBJECT = 'Embedded Object';
  CF_LINKSOURCE = 'Link Source';
  CF_HTML = 'HTML Format';                         // [dpv]

{************************************************************************}

{ OLE Extensions to the Rich Text Editor }
{ Converted from RICHOLE.H               }

{ Structure passed to GetObject and InsertObject }

type
  _ReObject = record
    cbStruct: DWORD;           { Size of structure                }
    cp: ULONG;                 { Character position of object     }
    clsid: TCLSID;             { Class ID of object               }
    poleobj: IOleObject;       { OLE object interface             }
    pstg: IStorage;            { Associated storage interface     }
    polesite: IOleClientSite;  { Associated client site interface }
    sizel: TSize;              { Size of object (may be 0,0)      }
    dvAspect: Longint;         { Display aspect to use            }
    dwFlags: DWORD;            { Object status flags              }
    dwUser: DWORD;             { Dword for user's use             }
  end;
  TReObject = _ReObject;

const

{ Flags to specify which interfaces should be returned in the structure above }

  REO_GETOBJ_NO_INTERFACES   =  $00000000;
  REO_GETOBJ_POLEOBJ         =  $00000001;
  REO_GETOBJ_PSTG            =  $00000002;
  REO_GETOBJ_POLESITE        =  $00000004;
  REO_GETOBJ_ALL_INTERFACES  =  $00000007;

{ Place object at selection }

  REO_CP_SELECTION    = ULONG(-1);

{ Use character position to specify object instead of index }

  REO_IOB_SELECTION   = ULONG(-1);
  REO_IOB_USE_CP      = ULONG(-2);

{ Object flags }

  REO_NULL            = $00000000;  { No flags                         }
  REO_READWRITEMASK   = $0000003F;  { Mask out RO bits                 }
  REO_DONTNEEDPALETTE = $00000020;  { Object doesn't need palette      }
  REO_BLANK           = $00000010;  { Object is blank                  }
  REO_DYNAMICSIZE     = $00000008;  { Object defines size always       }
  REO_INVERTEDSELECT  = $00000004;  { Object drawn all inverted if sel }
  REO_BELOWBASELINE   = $00000002;  { Object sits below the baseline   }
  REO_RESIZABLE       = $00000001;  { Object may be resized            }
  REO_LINK            = $80000000;  { Object is a link (RO)            }
  REO_STATIC          = $40000000;  { Object is static (RO)            }
  REO_SELECTED        = $08000000;  { Object selected (RO)             }
  REO_OPEN            = $04000000;  { Object open in its server (RO)   }
  REO_INPLACEACTIVE   = $02000000;  { Object in place active (RO)      }
  REO_HILITED         = $01000000;  { Object is to be hilited (RO)     }
  REO_LINKAVAILABLE   = $00800000;  { Link believed available (RO)     }
  REO_GETMETAFILE     = $00400000;  { Object requires metafile (RO)    }

{ Flags for IRichEditOle.GetClipboardData,   }
{ IRichEditOleCallback.GetClipboardData and  }
{ IRichEditOleCallback.QueryAcceptData       }

  RECO_PASTE          = $00000000;  { paste from clipboard  }
  RECO_DROP           = $00000001;  { drop                  }
  RECO_COPY           = $00000002;  { copy to the clipboard }
  RECO_CUT            = $00000003;  { cut to the clipboard  }
  RECO_DRAG           = $00000004;  { drag                  }

{ RichEdit GUIDs }

  IID_IRichEditOle: TGUID = (
    D1:$00020D00;D2:$0000;D3:$0000;D4:($C0,$00,$00,$00,$00,$00,$00,$46));
  IID_IRichEditOleCallback: TGUID = (
    D1:$00020D03;D2:$0000;D3:$0000;D4:($C0,$00,$00,$00,$00,$00,$00,$46));

type

{
 *  IRichEditOle
 *
 *  Purpose:
 *    Interface used by the client of RichEdit to perform OLE-related
 *    operations.
 *
 *    The methods herein may just want to be regular Windows messages.
}

{$IFDEF RX_D3}
  IRichEditOle = interface(IUnknown)
    ['{00020d00-0000-0000-c000-000000000046}']
    function GetClientSite(out clientSite: IOleClientSite): HResult; stdcall;
    function GetObjectCount: HResult; stdcall;
    function GetLinkCount: HResult; stdcall;
    function GetObject(iob: Longint; out reobject: TReObject;
      dwFlags: DWORD): HResult; stdcall;
    function InsertObject(var reobject: TReObject): HResult; stdcall;
    function ConvertObject(iob: Longint; rclsidNew: TIID;
      lpstrUserTypeNew: LPCSTR): HResult; stdcall;
    function ActivateAs(rclsid: TIID; rclsidAs: TIID): HResult; stdcall;
    function SetHostNames(lpstrContainerApp: LPCSTR;
      lpstrContainerObj: LPCSTR): HResult; stdcall;
    function SetLinkAvailable(iob: Longint; fAvailable: BOOL): HResult; stdcall;
    function SetDvaspect(iob: Longint; dvaspect: DWORD): HResult; stdcall;
    function HandsOffStorage(iob: Longint): HResult; stdcall;
    function SaveCompleted(iob: Longint; const stg: IStorage): HResult; stdcall;
    function InPlaceDeactivate: HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
    function GetClipboardData(var chrg: TCharRange; reco: DWORD;
      out dataobj: IDataObject): HResult; stdcall;
    function ImportDataObject(dataobj: IDataObject; cf: TClipFormat;
      hMetaPict: HGLOBAL): HResult; stdcall;
  end;
{$ELSE}
  IRichEditOle = class(IUnknown)
    function GetClientSite(var clientSite: IOleClientSite): HResult; virtual; stdcall; abstract;
    function GetObjectCount: HResult; virtual; stdcall; abstract;
    function GetLinkCount: HResult; virtual; stdcall; abstract;
    function GetObject(iob: Longint; var reobject: TReObject;
      dwFlags: DWORD): HResult; virtual; stdcall; abstract;
    function InsertObject(var reobject: TReObject): HResult; virtual; stdcall; abstract;
    function ConvertObject(iob: Longint; rclsidNew: TIID;
      lpstrUserTypeNew: LPCSTR): HResult; virtual; stdcall; abstract;
    function ActivateAs(rclsid: TIID; rclsidAs: TIID): HResult; virtual; stdcall; abstract;
    function SetHostNames(lpstrContainerApp: LPCSTR;
      lpstrContainerObj: LPCSTR): HResult; virtual; stdcall; abstract;
    function SetLinkAvailable(iob: Longint; fAvailable: BOOL): HResult; virtual; stdcall; abstract;
    function SetDvaspect(iob: Longint; dvaspect: DWORD): HResult; virtual; stdcall; abstract;
    function HandsOffStorage(iob: Longint): HResult; virtual; stdcall; abstract;
    function SaveCompleted(iob: Longint; const stg: IStorage): HResult; virtual; stdcall; abstract;
    function InPlaceDeactivate: HResult; virtual; stdcall; abstract;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; virtual; stdcall; abstract;
    function GetClipboardData(var chrg: TCharRange; reco: DWORD;
      var dataobj: IDataObject): HResult; virtual; stdcall; abstract;
    function ImportDataObject(dataobj: IDataObject; cf: TClipFormat;
      hMetaPict: HGLOBAL): HResult; virtual; stdcall; abstract;
  end;
{$ENDIF}

{
 *  IRichEditOleCallback
 *
 *  Purpose:
 *    Interface used by the RichEdit to get OLE-related stuff from the
 *    application using RichEdit.
}

{$IFDEF RX_D3}
  IRichEditOleCallback = interface(IUnknown)
    ['{00020d03-0000-0000-c000-000000000046}']
    function GetNewStorage(out stg: IStorage): HResult; stdcall;
    function GetInPlaceContext(out Frame: IOleInPlaceFrame;
      out Doc: IOleInPlaceUIWindow;
      lpFrameInfo: POleInPlaceFrameInfo): HResult; stdcall;
    function ShowContainerUI(fShow: BOOL): HResult; stdcall;
    function QueryInsertObject(const clsid: TCLSID; const stg: IStorage;
      cp: Longint): HResult; stdcall;
    function DeleteObject(const oleobj: IOleObject): HResult; stdcall;
    function QueryAcceptData(const dataobj: IDataObject;
      var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
      hMetaPict: HGLOBAL): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
    function GetClipboardData(const chrg: TCharRange; reco: DWORD;
      out dataobj: IDataObject): HResult; stdcall;
    function GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
      var dwEffect: DWORD): HResult; stdcall;
    function GetContextMenu(seltype: Word; const oleobj: IOleObject;
      const chrg: TCharRange; out menu: HMENU): HResult; stdcall;
  end;
{$ELSE}
  IRichEditOleCallback = class(IUnknown)
    function GetNewStorage(var stg: IStorage): HResult; virtual; stdcall; abstract;
    function GetInPlaceContext(var Frame: IOleInPlaceFrame;
      var Doc: IOleInPlaceUIWindow;
      lpFrameInfo: POleInPlaceFrameInfo): HResult; virtual; stdcall; abstract;
    function ShowContainerUI(fShow: BOOL): HResult; virtual; stdcall; abstract;
    function QueryInsertObject(const clsid: TCLSID; const stg: IStorage;
      cp: Longint): HResult; virtual; stdcall; abstract;
    function DeleteObject(const oleobj: IOleObject): HResult; virtual; stdcall; abstract;
    function QueryAcceptData(const dataobj: IDataObject;
      var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
      hMetaPict: HGLOBAL): HResult; virtual; stdcall; abstract;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; virtual; stdcall; abstract;
    function GetClipboardData(const chrg: TCharRange; reco: DWORD;
      var dataobj: IDataObject): HResult; virtual; stdcall; abstract;
    function GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
      var dwEffect: DWORD): HResult; virtual; stdcall; abstract;
    function GetContextMenu(seltype: Word; const oleobj: IOleObject;
      const chrg: TCharRange; var menu: HMENU): HResult; virtual; stdcall; abstract;
  end;
{$ENDIF}

{************************************************************************}

{ TRichEditOleCallback }

type
{$IFDEF RX_D3}
  TRichEditOleCallback = class(TObject, IUnknown, IRichEditOleCallback)
  private
    FDocForm: IVCLFrameForm;
    FFrameForm: IVCLFrameForm;
    FAccelTable: HAccel;
    FAccelCount: Integer;
{$IFDEF RX_D4}
    FAutoScroll: Boolean;
{$ENDIF}
    procedure CreateAccelTable;
    procedure DestroyAccelTable;
    procedure AssignFrame;
{$ELSE}
  TRichEditOleCallback = class(IRichEditOleCallback)
{$ENDIF}
  private
    FRefCount: Longint;
    FRichEdit: TRxCustomRichEdit;
  public
    constructor Create(RichEdit: TRxCustomRichEdit);
    destructor Destroy; override;
{$IFDEF RX_D3}
    function QueryInterface(const iid: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Longint; stdcall;
    function _Release: Longint; stdcall;
    function GetNewStorage(out stg: IStorage): HResult; stdcall;
    function GetInPlaceContext(out Frame: IOleInPlaceFrame;
      out Doc: IOleInPlaceUIWindow;
      lpFrameInfo: POleInPlaceFrameInfo): HResult; stdcall;
    function GetClipboardData(const chrg: TCharRange; reco: DWORD;
      out dataobj: IDataObject): HResult; stdcall;
    function GetContextMenu(seltype: Word; const oleobj: IOleObject;
      const chrg: TCharRange; out menu: HMENU): HResult; stdcall;
{$ELSE}
    function QueryInterface(const iid: TIID; var Obj): HResult; override;
    function AddRef: Longint; override;
    function Release: Longint; override;
    function GetNewStorage(var stg: IStorage): HResult; override;
    function GetInPlaceContext(var Frame: IOleInPlaceFrame;
      var Doc: IOleInPlaceUIWindow;
      lpFrameInfo: POleInPlaceFrameInfo): HResult; override;
    function GetClipboardData(const chrg: TCharRange; reco: DWORD;
      var dataobj: IDataObject): HResult; override;
    function GetContextMenu(seltype: Word; const oleobj: IOleObject;
      const chrg: TCharRange; var menu: HMENU): HResult; override;
{$ENDIF}
    function ShowContainerUI(fShow: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function QueryInsertObject(const clsid: TCLSID; const stg: IStorage;
      cp: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function DeleteObject(const oleobj: IOleObject): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function QueryAcceptData(const dataobj: IDataObject; var cfFormat: TClipFormat;
      reco: DWORD; fReally: BOOL; hMetaPict: HGLOBAL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
      var dwEffect: DWORD): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
  end;

constructor TRichEditOleCallback.Create(RichEdit: TRxCustomRichEdit);
begin
  inherited Create;
  FRichEdit := RichEdit;
end;

destructor TRichEditOleCallback.Destroy;
begin
{$IFDEF RX_D3}
  DestroyAccelTable;
  FFrameForm := nil;
  FDocForm := nil;
{$ENDIF}
  inherited Destroy;
end;

{$IFDEF RX_D3}

function TRichEditOleCallback.QueryInterface(const iid: TGUID; out Obj): HResult;
begin
  if GetInterface(iid, Obj) then Result := S_OK
  else Result := E_NOINTERFACE;
end;

function TRichEditOleCallback._AddRef: Longint;
begin
  Inc(FRefCount);
  Result := FRefCount;
end;

function TRichEditOleCallback._Release: Longint;
begin
  Dec(FRefCount);
  Result := FRefCount;
end;

procedure TRichEditOleCallback.CreateAccelTable;
var
  Menu: TMainMenu;
begin
  if (FAccelTable = 0) and Assigned(FFrameForm) then begin
    Menu := FFrameForm.Form.Menu;
    if Menu <> nil then
      Menu.GetOle2AcceleratorTable(FAccelTable, FAccelCount, [0, 2, 4]);
  end;
end;

procedure TRichEditOleCallback.DestroyAccelTable;
begin
  if FAccelTable <> 0 then begin
    DestroyAcceleratorTable(FAccelTable);
    FAccelTable := 0;
    FAccelCount := 0;
  end;
end;

procedure TRichEditOleCallback.AssignFrame;
begin
  if (GetParentForm(FRichEdit) <> nil) and not Assigned(FFrameForm) and
    FRichEdit.AllowInPlace then
  begin
    FDocForm := GetVCLFrameForm(ValidParentForm(FRichEdit));
    FFrameForm := FDocForm;
    if IsFormMDIChild(FDocForm.Form) then
      FFrameForm := GetVCLFrameForm(Application.MainForm);
  end;
end;

{$ELSE}

function TRichEditOleCallback.QueryInterface(const iid: TIID; var Obj): HResult;
begin
  if IsEqualIID(iid, IID_IUnknown) or
    IsEqualIID(iid, IID_IRichEditOleCallback) then
  begin
    Pointer(Obj) := Self;
    AddRef;
    Result := S_OK;
  end else begin
    Pointer(Obj) := nil;
    Result := E_NOINTERFACE;
  end;
end;

function TRichEditOleCallback.AddRef: Longint;
begin
  Inc(FRefCount);
  Result := FRefCount;
end;

function TRichEditOleCallback.Release: Longint;
begin
  Dec(FRefCount);
  Result := FRefCount;
end;

{$ENDIF RX_D3}

function TRichEditOleCallback.GetNewStorage(
  {$IFDEF RX_D3} out {$ELSE} var {$ENDIF} stg: IStorage): HResult;
begin
  try
    CreateStorage(stg);
    Result := S_OK;
  except
    Result:= E_OUTOFMEMORY;
  end;
end;

function TRichEditOleCallback.GetInPlaceContext(
  {$IFDEF RX_D3} out {$ELSE} var {$ENDIF} Frame: IOleInPlaceFrame;
  {$IFDEF RX_D3} out {$ELSE} var {$ENDIF} Doc: IOleInPlaceUIWindow;
  lpFrameInfo: POleInPlaceFrameInfo): HResult;
begin
{$IFDEF RX_D3}
  AssignFrame;
  if Assigned(FFrameForm) and FRichEdit.AllowInPlace then begin
    Frame := FFrameForm;
    Doc := FDocForm;
    CreateAccelTable;
    with lpFrameInfo^ do begin
      fMDIApp := False;
      FFrameForm.GetWindow(hWndFrame);
      hAccel := FAccelTable;
      cAccelEntries := FAccelCount;
    end;
    Result := S_OK;
  end
  else Result := E_NOTIMPL;
{$ELSE}
  Result := E_NOTIMPL;
{$ENDIF}
end;

function TRichEditOleCallback.QueryInsertObject(const clsid: TCLSID; const stg: IStorage;
  cp: Longint): HResult;
begin
  Result := NOERROR;
end;

function TRichEditOleCallback.DeleteObject(const oleobj: IOleObject): HResult;
begin
  if Assigned(oleobj) then oleobj.Close(OLECLOSE_NOSAVE);
  Result := NOERROR;
end;


(*
  It works, but we don't need it for now

 // Publications by Michael Van Canneyt
 // https://www.freepascal.org/~michael/articles/#dragdrop3

type
  TFormatDescription = Record
      MediaType : Integer;
      ClipBoardFormat : Integer;
      FormatName : String;
    end;
  TFormatDescriptionArray = Array of TFormatDescription;


var
  FAvailableFormats: TFormatDescriptionArray;
  ClipNames: array[CF_TEXT..CF_MAX-1] of string =
     ('CF_TEXT', 'CF_BITMAP', 'CF_METAFILEPICT', 'CF_SYLK', 'CF_DIF', 'CF_TIFF',
     'CF_OEMTEXT', 'CF_DIB', 'CF_PALETTE', 'CF_PENDATA', 'CF_RIFF', 'CF_WAVE',
     'CF_UNICODETEXT', 'CF_ENHMETAFILE', 'CF_HDROP', 'CF_LOCALE'{$IF CompilerVersion >= 23.0}, 'CF_DIBV5'{$ifend});


function GetFormats(const dataObj: IDataObject): Integer;
Var
  N : Array[0..255] of Char;
  F,M : Array[0..255] of Integer;
  MediaOK : Boolean;
  Enum : IEnumFORMATETC;
  Elt : TFormatEtc;
  I,E : longint;
  S : String;
  //Files: Boolean;
begin
  Result:=0;
  SetLength(FAvailableFormats,0);

  if DataObj.EnumFormatEtc(DATADIR_GET,Enum)<>S_OK then
     exit;
  MediaOK:=False;
  Repeat
    I:=0;
    if Enum.Next(1,elt,@I)=S_OK then begin
      if (Elt.tymed=TYMED_HGLOBAL)
         or (elt.tymed=TYMED_ISTREAM) then begin
        F[Result]:=elt.cfFormat;
        M[Result]:=elt.tymed;
        // if F[Result] = CF_HDROP then Files:= True;
        Inc(Result);
        MediaOK:= True;
      end;
    end;
  Until I<>1;
  Enum:= Nil; // Release instance

  if Result>0 then begin
    SetLength(FAvailableFormats,Result);
    For I:=0 to Result-1 do begin
      if F[I]<=CF_MAX then
        S:= ClipNames[F[I]]
      else begin
        FillChar(N[0],SizeOf(N),#0);
        If GetClipboardFormatName(F[I],@N,255)= 0 then
          S:= 'Predefined format '+IntToStr(F[i])
        else
          S:= N;
      end;
      FAvailableFormats[I].ClipBoardFormat:= F[i];
      FAvailableFormats[I].MediaType:= M[i];
      FAvailableFormats[I].FormatName:= S;
    end;
  end;
end;

*)


// https://stackoverflow.com/questions/21245887/retrieving-filename-from-idataobject-in-delphi

function ContainFormat(ADataObject: IDataObject; AFormat: TClipFormat;
  ATymed: Longint; AAspect: LongInt = DVASPECT_CONTENT; AIndex: LongInt = -1): Boolean;
var Format: TFormatEtc;
begin
  ZeroMemory(@Format, SizeOf(Format));
  Format.cfFormat := AFormat;
  Format.dwAspect := AAspect;
  Format.lindex := AIndex;
  Format.tymed := ATymed;
  Result := ADataObject.QueryGetData(Format) = S_OK;
end;


function TRichEditOleCallback.QueryAcceptData(const dataobj: IDataObject;
  var cfFormat: TClipFormat; reco: DWORD; fReally: BOOL;
  hMetaPict: HGLOBAL): HResult;
begin
  // See clarification of the treatment given to this method in the comment *3      [dpv]

  //Result := S_OK;
  //var Count: Integer:= GetFormats(DataObj);

  if ContainFormat(dataobj, CF_HDROP, TYMED_HGLOBAL) then
     Result := S_FALSE

  else begin                                                               // [dpv] See comment *4
    if (not fReally) then begin
       var DragObject: TDragObject;
       if assigned( FRichEdit.OnStartDrag ) then
          FRichEdit.OnStartDrag(FRichEdit, DragObject);
    end
    else begin
       if assigned( FRichEdit.OnEndDrag ) then
          FRichEdit.OnEndDrag(FRichEdit, nil, 0,0);
    end;

    Result := S_OK;
  end;

end;

function TRichEditOleCallback.ContextSensitiveHelp(fEnterMode: BOOL): HResult;
begin
  Result := NOERROR;
end;

function TRichEditOleCallback.GetClipboardData(const chrg: TCharRange; reco: DWORD;
  {$IFDEF RX_D3} out {$ELSE} var {$ENDIF} dataobj: IDataObject): HResult;
begin
  Result := E_NOTIMPL;
end;

function TRichEditOleCallback.GetDragDropEffect(fDrag: BOOL; grfKeyState: DWORD;
  var dwEffect: DWORD): HResult;
begin
  Result := E_NOTIMPL;
end;

function TRichEditOleCallback.GetContextMenu(seltype: Word;
  const oleobj: IOleObject; const chrg: TCharRange;
  {$IFDEF RX_D3} out {$ELSE} var {$ENDIF} menu: HMENU): HResult;
begin
  Result := E_NOTIMPL;
end;

function TRichEditOleCallback.ShowContainerUI(fShow: BOOL): HResult;
begin
{$IFDEF RX_D3}
  if not fShow then AssignFrame;
  if Assigned(FFrameForm) then begin
    if fShow then begin
      FFrameForm.SetMenu(0, 0, 0);
      FFrameForm.ClearBorderSpace;
      FRichEdit.SetUIActive(False);
      DestroyAccelTable;
{$IFDEF RX_D4}
      TForm(FFrameForm.Form).AutoScroll := FAutoScroll;
{$ENDIF}
      FFrameForm := nil;
      FDocForm := nil;
    end
    else begin
{$IFDEF RX_D4}
      FAutoScroll := TForm(FFrameForm.Form).AutoScroll;
      TForm(FFrameForm.Form).AutoScroll := False;
{$ENDIF}
      FRichEdit.SetUIActive(True);
    end;
    Result := S_OK;
  end
  else Result := E_NOTIMPL;
{$ELSE}
  Result := E_NOTIMPL;
{$ENDIF}
end;

{ TOleUIObjInfo - helper interface for Object Properties dialog }

type
{$IFDEF RX_D3}
  TOleUIObjInfo = class(TInterfacedObject, IOleUIObjInfo)
{$ELSE}
  TOleUIObjInfo = class(IOleUIObjInfo)
{$ENDIF}
  private
    FRichEdit: TRxCustomRichEdit;
    FReObject: TReObject;
  public
    constructor Create(RichEdit: TRxCustomRichEdit; ReObject: TReObject);
{$IFNDEF RX_D3}
    function QueryInterface(const iid: TIID; var obj): HResult; override;
    function AddRef: Longint; override;
    function Release: Longint; override;
{$ENDIF}
    function GetObjectInfo(dwObject: Longint;
      var dwObjSize: Longint; var lpszLabel: PChar;
      var lpszType: PChar; var lpszShortType: PChar;
      var lpszLocation: PChar): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetConvertInfo(dwObject: Longint; var ClassID: TCLSID;
      var wFormat: Word; var ConvertDefaultClassID: TCLSID;
      var lpClsidExclude: PCLSID; var cClsidExclude: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function ConvertObject(dwObject: Longint;
      const clsidNew: TCLSID): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetViewInfo(dwObject: Longint; var hMetaPict: HGlobal;
      var dvAspect: Longint; var nCurrentScale: Integer): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function SetViewInfo(dwObject: Longint; hMetaPict: HGlobal;
      dvAspect: Longint; nCurrentScale: Integer;
      bRelativeToOrig: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
  end;

constructor TOleUIObjInfo.Create(RichEdit: TRxCustomRichEdit;
  ReObject: TReObject);
begin
  inherited Create;
  FRichEdit := RichEdit;
  FReObject := ReObject;
end;

{$IFNDEF RX_D3}

function TOleUIObjInfo.QueryInterface(const iid: TIID; var obj): HResult;
begin
  Pointer(obj) := nil;
  Result := E_NOINTERFACE;
end;

function TOleUIObjInfo.AddRef: Longint;
begin
  Result := 0;
end;

function TOleUIObjInfo.Release: Longint;
begin
  Result := 0;
end;

{$ENDIF RX_D3}

function TOleUIObjInfo.GetObjectInfo(dwObject: Longint;
  var dwObjSize: Longint; var lpszLabel: PChar;
  var lpszType: PChar; var lpszShortType: PChar;
  var lpszLocation: PChar): HResult;
begin
  if @dwObjSize <> nil then
    dwObjSize := -1 { Unknown size };
  if @lpszLabel <> nil then
    lpszLabel := CoAllocCStr(GetFullNameStr(FReObject.poleobj));
  if @lpszType <> nil then
    lpszType := CoAllocCStr(GetFullNameStr(FReObject.poleobj));
  if @lpszShortType <> nil then
    lpszShortType := CoAllocCStr(GetShortNameStr(FReObject.poleobj));
  if (@lpszLocation <> nil) then begin
    if Trim(FRichEdit.Title) <> '' then
      lpszLocation := CoAllocCStr(Format('%s - %s',
        [FRichEdit.Title, Application.Title]))
    else
      lpszLocation := CoAllocCStr(Application.Title);
  end;
  Result := S_OK;
end;

function TOleUIObjInfo.GetConvertInfo(dwObject: Longint; var ClassID: TCLSID;
  var wFormat: Word; var ConvertDefaultClassID: TCLSID;
  var lpClsidExclude: PCLSID; var cClsidExclude: Longint): HResult;
begin
  FReObject.poleobj.GetUserClassID(ClassID);
  Result := S_OK;
end;

function TOleUIObjInfo.ConvertObject(dwObject: Longint;
  const clsidNew: TCLSID): HResult;
begin
  Result := E_NOTIMPL;
end;

function TOleUIObjInfo.GetViewInfo(dwObject: Longint; var hMetaPict: HGlobal;
  var dvAspect: Longint; var nCurrentScale: Integer): HResult;
begin
  if @hMetaPict <> nil then
    hMetaPict := GetIconMetaPict(FReObject.poleobj, FReObject.dvAspect);
  if @dvAspect <> nil then dvAspect := FReObject.dvAspect;
  if @nCurrentScale <> nil then nCurrentScale := 0;
  Result := S_OK;
end;

function TOleUIObjInfo.SetViewInfo(dwObject: Longint; hMetaPict: HGlobal;
  dvAspect: Longint; nCurrentScale: Integer;
  bRelativeToOrig: BOOL): HResult;
var
  Iconic: Boolean;
begin
  if Assigned(FRichEdit.FRichEditOle) then begin
    case dvAspect of
      DVASPECT_CONTENT:
        Iconic := False;
      DVASPECT_ICON:
        Iconic := True;
      else
        Iconic := FReObject.dvAspect = DVASPECT_ICON;
    end;
    IRichEditOle(FRichEdit.FRichEditOle).InPlaceDeactivate;
    Result := OleSetDrawAspect(FReObject.poleobj, Iconic, hMetaPict,
      FReObject.dvAspect);
    if Succeeded(Result) then
      IRichEditOle(FRichEdit.FRichEditOle).SetDvaspect(
        Longint(REO_IOB_SELECTION), FReObject.dvAspect);
  end
  else Result := E_NOTIMPL;
end;

{ TOleUILinkInfo - helper interface for Object Properties dialog }

type
{$IFDEF RX_D3}
  TOleUILinkInfo = class(TInterfacedObject, IOleUILinkInfo)
{$ELSE}
  TOleUILinkInfo = class(IOleUILinkInfo)
{$ENDIF}
  private
    FReObject: TReObject;
    FRichEdit: TRxCustomRichEdit;
    FOleLink: IOleLink;
  public
    constructor Create(RichEdit: TRxCustomRichEdit; ReObject: TReObject);
{$IFNDEF RX_D3}
    destructor Destroy; override;
    function QueryInterface(const iid: TIID; var obj): HResult; override;
    function AddRef: Longint; override;
    function Release: Longint; override;
{$ENDIF}
    function GetNextLink(dwLink: Longint): Longint;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function SetLinkUpdateOptions(dwLink: Longint;
      dwUpdateOpt: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetLinkUpdateOptions(dwLink: Longint;
      var dwUpdateOpt: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function SetLinkSource(dwLink: Longint; pszDisplayName: PChar;
      lenFileName: Longint; var chEaten: Longint;
      fValidateSource: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetLinkSource(dwLink: Longint; var pszDisplayName: PChar;
      var lenFileName: Longint; var pszFullLinkType: PChar;
      var pszShortLinkType: PChar; var fSourceAvailable: BOOL;
      var fIsSelected: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function OpenLinkSource(dwLink: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function UpdateLink(dwLink: Longint; fErrorMessage: BOOL;
      fErrorAction: BOOL): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function CancelLink(dwLink: Longint): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
    function GetLastUpdate(dwLink: Longint;
      var LastUpdate: TFileTime): HResult;
      {$IFDEF RX_D3} stdcall {$ELSE} override {$ENDIF};
  end;

{$IFDEF RX_D3}
procedure LinkError(const Ident: string);
begin
  Application.MessageBox(PChar(Ident), PChar(SLinkProperties),
    MB_OK or MB_ICONSTOP);
end;
{$ELSE}
procedure LinkError(Ident: string{Integer});
begin
  Application.MessageBox(PChar({LoadStr(}Ident{)}),
    PChar({LoadStr(}SLinkProperties{)}), MB_OK or MB_ICONSTOP);
end;
{$ENDIF}

constructor TOleUILinkInfo.Create(RichEdit: TRxCustomRichEdit;
  ReObject: TReObject);
begin
  inherited Create;
  FReObject := ReObject;
  FRichEdit := RichEdit;
{$IFDEF RX_D3}
  OleCheck(FReObject.poleobj.QueryInterface(IOleLink, FOleLink));
{$ELSE}
  OleCheck(FReObject.poleobj.QueryInterface(IID_IOleLink, FOleLink));
{$ENDIF}
end;

{$IFNDEF RX_D3}

destructor TOleUILinkInfo.Destroy;
begin
  ReleaseObject(FOleLink);
  inherited Destroy;
end;

function TOleUILinkInfo.QueryInterface(const iid: TIID; var obj): HResult;
begin
  Pointer(obj) := nil;
  Result := E_NOINTERFACE;
end;

function TOleUILinkInfo.AddRef: Longint;
begin
  Result := 0;
end;

function TOleUILinkInfo.Release: Longint;
begin
  Result := 0;
end;

{$ENDIF}

function TOleUILinkInfo.GetNextLink(dwLink: Longint): Longint;
begin
  if dwLink = 0 then Result := Longint(FRichEdit)
  else Result := 0;
end;

function TOleUILinkInfo.SetLinkUpdateOptions(dwLink: Longint;
  dwUpdateOpt: Longint): HResult;
begin
  Result := FOleLink.SetUpdateOptions(dwUpdateOpt);
  if Succeeded(Result) then FRichEdit.Modified := True;
end;

function TOleUILinkInfo.GetLinkUpdateOptions(dwLink: Longint;
  var dwUpdateOpt: Longint): HResult;
begin
  Result := FOleLink.GetUpdateOptions(dwUpdateOpt);
end;

function TOleUILinkInfo.SetLinkSource(dwLink: Longint; pszDisplayName: PChar;
  lenFileName: Longint; var chEaten: Longint;
  fValidateSource: BOOL): HResult;
var
  DisplayName: string;
  Buffer: array[0..255] of WideChar;
begin
  Result := E_FAIL;
  if fValidateSource then begin
    DisplayName := pszDisplayName;
    if Succeeded(FOleLink.SetSourceDisplayName(StringToWideChar(DisplayName,
      Buffer, SizeOf(Buffer) div 2))) then
    begin
      chEaten := Length(DisplayName);
      try
        OleCheck(FReObject.poleobj.Update);
      except
        Application.HandleException(FRichEdit);
      end;
      Result := S_OK;
    end;
  end
  else LinkError(SInvalidLinkSource);
end;

function TOleUILinkInfo.GetLinkSource(dwLink: Longint; var pszDisplayName: PChar;
  var lenFileName: Longint; var pszFullLinkType: PChar;
  var pszShortLinkType: PChar; var fSourceAvailable: BOOL;
  var fIsSelected: BOOL): HResult;
var
  Moniker: IMoniker;
begin
  if @pszDisplayName <> nil then
    pszDisplayName := CoAllocCStr(GetDisplayNameStr(FOleLink));
  if @lenFileName <> nil then begin
    lenFileName := 0;
    FOleLink.GetSourceMoniker(Moniker);
    if Moniker <> nil then begin
      lenFileName := OleStdGetLenFilePrefixOfMoniker(Moniker);
      ReleaseObject(Moniker);
    end;
  end;
  if @pszFullLinkType <> nil then
    pszFullLinkType := CoAllocCStr(GetFullNameStr(FReObject.poleobj));
  if @pszShortLinkType <> nil then
    pszShortLinkType := CoAllocCStr(GetShortNameStr(FReObject.poleobj));
  Result := S_OK;
end;

function TOleUILinkInfo.OpenLinkSource(dwLink: Longint): HResult;
begin
  try
    OleCheck(FReObject.poleobj.DoVerb(OLEIVERB_SHOW, nil, FReObject.polesite,
      0, FRichEdit.Handle, FRichEdit.ClientRect));
  except
    Application.HandleException(FRichEdit);
  end;
  Result := S_OK;
end;

function TOleUILinkInfo.UpdateLink(dwLink: Longint; fErrorMessage: BOOL;
  fErrorAction: BOOL): HResult;
begin
  try
    OleCheck(FReObject.poleobj.Update);
  except
    Application.HandleException(FRichEdit);
  end;
  Result := S_OK;
end;

function TOleUILinkInfo.CancelLink(dwLink: Longint): HResult;
begin
  LinkError(SCannotBreakLink);
  Result := E_NOTIMPL;
end;

function TOleUILinkInfo.GetLastUpdate(dwLink: Longint;
  var LastUpdate: TFileTime): HResult;
begin
  Result := S_OK;
end;

{ Get RichEdit OLE interface }

function GetRichEditOle(Wnd: HWnd; var RichEditOle): Boolean;
begin
  Result := SendMessage(Wnd, EM_GETOLEINTERFACE, 0, LPARAM(@RichEditOle)) <> 0;
end;

{ TRichEditStrings }

const
  ReadError  = $0001;
  WriteError = $0002;
  NoError    = $0000;

type
  TRichEditStrings = class(TStrings)
  private
    RichEdit: TRxCustomRichEdit;
    FFormat: TRichStreamFormat;
    FMode: TRichStreamModes;
    FConverter: TConversion;
    procedure EnableChange(const Value: Boolean);
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    procedure Put(Index: Integer; const S: string); override;
    procedure SetUpdateState(Updating: Boolean); override;
    procedure SetTextStr(const Value: string); override;
  public
    destructor Destroy; override;
    procedure Clear; override;
    procedure AddStrings(Strings: TStrings); override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
{$IFDEF RX_D12}
    procedure LoadFromFile(const FileName: string); override;
{$ENDIF}
    procedure LoadFromFile(const FileName: string{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF}); override;
    procedure LoadFromStream(Stream: TStream{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF}); override;
    procedure SaveToFile(const FileName: string{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF}); override;
    procedure SaveToStream(Stream: TStream{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF});override;
    property Format: TRichStreamFormat read FFormat write FFormat;
    property Mode: TRichStreamModes read FMode write FMode;
  end;

destructor TRichEditStrings.Destroy;
begin
  FConverter.Free;
  inherited Destroy;
end;

procedure TRichEditStrings.AddStrings(Strings: TStrings);
var
  SelChange: TNotifyEvent;
begin
  SelChange := RichEdit.OnSelectionChange;
  RichEdit.OnSelectionChange := nil;
  try
    inherited AddStrings(Strings);
  finally
    RichEdit.OnSelectionChange := SelChange;
  end;
end;

function TRichEditStrings.GetCount: Integer;
begin
  with RichEdit do begin
    Result := SendMessage(Handle, EM_GETLINECOUNT, 0, 0);
    if GetLineLength(GetLineIndex(Result - 1)) = 0 then Dec(Result);
  end;
end;

{$IFDEF UNICODE}
function TRichEditStrings.Get(Index: Integer): string;
var
  Text: array of Char;
  L: Integer;
  W: Word;
begin
  SetLength(Text, SizeOf(Char) * 4096);
  L := SendMessage(RichEdit.Handle, EM_LINELENGTH, WPARAM(Index), 0);
  if L > Length(Text) then SetLength(Text, SizeOf(Char) * L);
  W := Length(Text);
  Text[0] := Char(W);
  L := SendMessage(RichEdit.Handle, EM_GETLINE, WPARAM(Index), LPARAM(@Text[0]));
  if ((L - 2) >= 0) and (Text[L - 2] = #13) and (Text[L - 1] = #10) then Dec(L, 2)
  else if (RichEditVersion >= 2) and ((L - 1) >= 0) and (Text[L - 1] = #13) then Dec(L);
  SetString(Result, PChar(@Text[0]), L);
end;
{$ELSE}
function TRichEditStrings.Get(Index: Integer): string;
var
  Text: array[0..4095] of Char;
  L: Integer;
begin
  if SendMessage(RichEdit.Handle, EM_LINELENGTH, WPARAM(Index), 0) > SizeOf(Text) then Exit;
  Word((@Text)^) := SizeOf(Text);
  L := SendMessage(RichEdit.Handle, EM_GETLINE, WPARAM(Index), LPARAM(@Text));
  if (Text[L - 2] = #13) and (Text[L - 1] = #10) then Dec(L, 2)
  else if (RichEditVersion >= 2) and (Text[L - 1] = #13) then Dec(L);
  SetString(Result, Text, L);
end;
{$ENDIF}

procedure TRichEditStrings.Put(Index: Integer; const S: string);
var
  Selection: TCharRange;
begin
  if Index >= 0 then
  begin
    Selection.cpMin := RichEdit.GetLineIndex(Index);
    if Selection.cpMin <> -1 then begin
      Selection.cpMax := Selection.cpMin +
        RichEdit.GetLineLength(Selection.cpMin);
      SendMessage(RichEdit.Handle, EM_EXSETSEL, 0, LPARAM(@Selection));
      RichEdit.FLinesUpdating := True;
      try
        SendMessage(RichEdit.Handle, EM_REPLACESEL, 0, LPARAM(PChar(S)));
      finally
        RichEdit.FLinesUpdating := False;
      end;
    end;
  end;
end;

procedure TRichEditStrings.Insert(Index: Integer; const S: string);
var
  L: Integer;
  Selection: TCharRange;
  Fmt: PChar;
  Str: string;
begin
  if Index >= 0 then begin
    Selection.cpMin := RichEdit.GetLineIndex(Index);
    if Selection.cpMin >= 0 then begin
      if RichEditVersion = 1 then Fmt := '%s'#13#10
      else Fmt := '%s'#13;
    end
    else begin
      Selection.cpMin := RichEdit.GetLineIndex(Index - 1);
      if Selection.cpMin < 0 then Exit;
      L := RichEdit.GetLineLength(Selection.cpMin);
      if L = 0 then Exit;
      Inc(Selection.cpMin, L);
      if RichEditVersion = 1 then Fmt := #13#10'%s'
      else Fmt := #13'%s';
    end;
    Selection.cpMax := Selection.cpMin;
    SendMessage(RichEdit.Handle, EM_EXSETSEL, 0, LPARAM(@Selection));
    Str := SysUtils.Format(Fmt, [S]);
    RichEdit.FLinesUpdating := True;
    try
      SendMessage(RichEdit.Handle, EM_REPLACESEL, 0, LPARAM(PChar(Str)));
    finally
      RichEdit.FLinesUpdating := False;
    end;
    if RichEditVersion = 1 then
      if RichEdit.SelStart <> (Selection.cpMax + Length(Str)) then
        raise EOutOfResources.Create(ResStr(sRichEditInsertError));
  end;
end;

procedure TRichEditStrings.Delete(Index: Integer);
const
  Empty: PChar = '';
var
  Selection: TCharRange;
begin
  if Index < 0 then Exit;
  Selection.cpMin := RichEdit.GetLineIndex(Index);
  if Selection.cpMin <> -1 then begin
    Selection.cpMax := RichEdit.GetLineIndex(Index + 1);
    if Selection.cpMax = -1 then
      Selection.cpMax := Selection.cpMin +
        RichEdit.GetLineLength(Selection.cpMin);
    SendMessage(RichEdit.Handle, EM_EXSETSEL, 0, LPARAM(@Selection));
    RichEdit.FLinesUpdating := True;
    try
      SendMessage(RichEdit.Handle, EM_REPLACESEL, 0, LPARAM(Empty));
    finally
      RichEdit.FLinesUpdating := False;
    end;
  end;
end;

procedure TRichEditStrings.Clear;
begin
  RichEdit.Clear;
end;

procedure TRichEditStrings.SetUpdateState(Updating: Boolean);
begin
  if RichEdit.Showing then
    SendMessage(RichEdit.Handle, WM_SETREDRAW, Ord(not Updating), 0);
  if not Updating then begin
    RichEdit.Refresh;
    RichEdit.Perform(CM_TEXTCHANGED, 0, 0);
  end;
end;

procedure TRichEditStrings.EnableChange(const Value: Boolean);
var
  EventMask: Longint;
begin
  with RichEdit do begin
    EventMask := SendMessage(Handle, EM_GETEVENTMASK, 0, 0);
    if Value then
      EventMask := EventMask or ENM_CHANGE
    else
      EventMask := EventMask and not ENM_CHANGE;
    SendMessage(Handle, EM_SETEVENTMASK, 0, LPARAM(EventMask));
  end;
end;

procedure TRichEditStrings.SetTextStr(const Value: string);
begin
  EnableChange(False);
  try
    inherited SetTextStr(Value);
  finally
    EnableChange(True);
  end;
end;

{$IFDEF RX_D12}
function AdjustLineBreaks(Dest: PByte; Source: TBytes; Start, Len: Integer): Integer;
var
  P: PByte;
  I: Integer;
begin
  I := Start; // Position in Source
  P := Dest;
  while I < (Len - 1) do
  begin
    if (Source[I] = 10) and (Source[I + 1] = 0) then
    begin
      // Convert #10 to #13#10
      P^ := 13;
      Inc(P);
      P^ := 0;
      Inc(P);
      P^ := 10;
      Inc(P);
      P^ := 0;
      Inc(P);
    end
    else
    begin
      P^ := Source[I];
      Inc(P);
      P^ := Source[I + 1];
      Inc(P);
      if (Source[I] = 13) and (Source[I + 1] = 0) then
      begin
        // Convert #13 to #13#10
        P^ := 10;
        Inc(P);
        P^ := 0;
        Inc(P);
        // Skip #10 if preceeded by #13
        if (Source[I + 2] = 10) and (Source[I + 3] = 0) then
          Inc(I, 2);
      end;
    end;
    Inc(I, 2);
  end;
  if I = Len - 1 then
  begin
    P^ := Source[I];
    Inc(P);
  end;
  Result := Integer(P) - Integer(Dest);
end;
{$ELSE}
function AdjustLineBreaks(Dest, Source: PChar): Integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     EDI,EAX
        MOV     ESI,EDX
        MOV     EDX,EAX
        CLD
@@1:    LODSB
@@2:    OR      AL,AL
        JE      @@4
        CMP     AL,0AH
        JE      @@3
        STOSB
        CMP     AL,0DH
        JNE     @@1
        MOV     AL,0AH
        STOSB
        LODSB
        CMP     AL,0AH
        JE      @@1
        JMP     @@2
@@3:    MOV     EAX,0A0DH
        STOSW
        JMP     @@1
@@4:    STOSB
        LEA     EAX,[EDI-1]
        SUB     EAX,EDX
        POP     EDI
        POP     ESI
end;
{$ENDIF}

(*
// [dpv] See comment *5
function AdjustLineBreaksOLD(Dest, Source: PByte): Integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     EDI,EAX
        MOV     ESI,EDX
        MOV     EDX,EAX
        CLD
@@1:    LODSB
@@2:    OR      AL,AL
        JE      @@4
        CMP     AL,0AH
        JE      @@3
        STOSB
        CMP     AL,0DH
        JNE     @@1
        MOV     AL,0AH
        STOSB
        LODSB
        CMP     AL,0AH
        JE      @@1
        JMP     @@2
@@3:    MOV     EAX,0A0DH
        STOSW
        JMP     @@1
@@4:    STOSB
        LEA     EAX,[EDI-1]
        SUB     EAX,EDX
        POP     EDI
        POP     ESI
end;
*)


{$IFDEF RX_D12}
{$IFDEF RX_D19}
function StreamSave(dwCookie: DWORD_PTR; pbBuff: PByte;
    cb: Longint; var pcb: Longint): Longint; stdcall;
{$ELSE}
function StreamSave(dwCookie: Longint; pbBuff: PByte;
  cb: Longint; var pcb: Longint): Longint; stdcall;
{$ENDIF}
var
  StreamInfo: TRichEditStreamInfo;
  Buffer: TBytes;
begin
  Result := NoError;
  StreamInfo := PRichEditStreamInfo(dwCookie)^;
  try
    pcb := 0;
    if StreamInfo.Converter <> nil then
    begin
      SetLength(Buffer, cb);
      Move(pbBuff^, Buffer[0], cb);

      // Convert from Unicode to Encoding if PlainText is set
      if StreamInfo.PlainText then
      begin
        if StreamInfo.Encoding = nil then
          Buffer := TEncoding.Convert(TEncoding.Unicode, TEncoding.Default, Buffer)
        else
        begin
          if not TEncoding.Unicode.Equals(StreamInfo.Encoding) then
            Buffer := TEncoding.Convert(TEncoding.Unicode, StreamInfo.Encoding, Buffer);
        end;
      end;

      pcb := StreamInfo.Converter.ConvertWriteStream(StreamInfo.Stream, Buffer, Length(Buffer));
      // Length(Buffer) may be different from 'cb' if we converted the char set
      if (pcb <> cb) and (pcb = Length(Buffer)) then
        pcb := cb; // Fake the number of bytes written
    end;
  except
    Result := WriteError;
  end;
end;
{$ELSE}
function StreamSave(dwCookie: Longint; pbBuff: PByte;
  cb: Longint; var pcb: Longint): Longint; stdcall;
var
  StreamInfo: PRichEditStreamInfo;
begin
  Result := NoError;
  StreamInfo := PRichEditStreamInfo(Pointer(dwCookie));
  try
    pcb := 0;
    if StreamInfo^.Converter <> nil then
      pcb := StreamInfo^.Converter.ConvertWriteStream(StreamInfo^.Stream, PChar(pbBuff), cb);
  except
    Result := WriteError;
  end;
end;
{$ENDIF}

{$IFDEF RX_D12}
{$IFDEF RX_D19}
function StreamLoad(dwCookie: DWORD_PTR; pbBuff: PByte;
    cb: Longint; var pcb: Longint): Longint; stdcall;
{$ELSE}
function StreamLoad(dwCookie: Longint; pbBuff: PByte;
  cb: Longint; var pcb: Longint): Longint; stdcall;
{$ENDIF}
var
  Buffer, Preamble: TBytes;
  StreamInfo: TRichEditStreamInfo;
  StartIndex: Integer;
 //pbBuff2: TBytes;                                              // [dpv] See comment *5
begin
  Result := NoError;
  StreamInfo := PRichEditStreamInfo(dwCookie)^;
  SetLength(Buffer, cb + 1);
  // SetLength(pbBuff2, cb + 1);                                 // [dpv] See comment *5
  cb := cb div 2;
  if (cb mod 2) > 0 then
    cb := cb -1 ;
  StartIndex := 0;
  pcb := 0;
  try
    if StreamInfo.Converter <> nil then
      pcb := StreamInfo.Converter.ConvertReadStream(StreamInfo.Stream, Buffer, cb);
    if pcb > 0 then
    begin
      Buffer[pcb] := 0;
      if Buffer[pcb - 1] = 13 then begin
        Buffer[pcb - 1] := 0;
        Dec(pcb);                        // [dpv]  See comment *5, below
      end;

      // Convert from desired Encoding to Unicode
      if StreamInfo.PlainText then
      begin
        if StreamInfo.Encoding = nil then
        begin
          Buffer := TEncoding.Convert(TEncoding.Default, TEncoding.Unicode, Buffer, 0, pcb);
          pcb := Length(Buffer);
        end
        else
        begin
          if not TEncoding.Unicode.Equals(StreamInfo.Encoding) then
          begin
            Buffer := TEncoding.Convert(StreamInfo.Encoding, TEncoding.Unicode, Buffer, 0, pcb);
            pcb := Length(Buffer);
          end;
          // If Unicode preamble is present, set StartIndex to skip over it
          Preamble := TEncoding.Unicode.GetPreamble;
          if (pcb >= 2) and (Buffer[0] = Preamble[0]) and (Buffer[1] = Preamble[1]) then
            StartIndex := 2;
        end;
      end;
      pcb := AdjustLineBreaks(pbBuff, Buffer, StartIndex, pcb);

    (*
      { *5  Tests to identify and resolve the problem described here:
               https://github.com/dpradov/keynote-nf/issues/623#issuecomment-1853094597

       It was causing seemingly random errors that could truncate the contents of the affected nodes/notes
       And all because of the insertion of zeros where line breaks should have been added. It happened sporadically,
       usually only in notes with a lot of text.

       With the following lines I confirm the problem, once I detected that the error did not occur if instead of using
       the current AdjustLineBreaks method I used the old one.
       I verify that without the Dec(pcb) instruction the new method works incorrectly, injecting 00 0A at some points
       instead of 0D 0A. However, the previous method was not affected: the result obtained with and without the instruction
       Dec(pcb) is exactly the same in this case.
       I verify that the previous StreamLoad code (which relies on the old AdjustLineBreaks method and did not take into account
       Enconding), did not include the Dec(pcb) instruction. But I also verify that the code included here is taken
       from the Delphi file Vcl.ComCtrls. And the instruction Dec(pcb) does appear in it
      }
      var pcb1, pcb2: integer;
      pcb2 :=  AdjustLineBreaks(PByte(pbBuff2), Buffer, StartIndex, pcb);   // new method
      pcb1 :=  AdjustLineBreaksOLD(pbBuff, PByte(Buffer));                  // old method (with PByte instead PChar)
      list.Add(format('%d, %d', [pcb1, pcb2]));
      st1.Write(pbBuff[0],  pcb1);
      st2.Write(pbBuff2[0], pcb2);
      pcb:= pcb1;
    *)

    end;
  except
    Result := ReadError;
  end;
end;
{$ELSE}
function StreamLoad(dwCookie: Longint; pbBuff: PByte;
  cb: Longint; var pcb: Longint): Longint; stdcall;
var
  Buffer, pBuff: PChar;
  StreamInfo: PRichEditStreamInfo;
begin
  Result := NoError;
  StreamInfo := PRichEditStreamInfo(Pointer(dwCookie));
  Buffer := StrAlloc(cb + 1);
  try
    cb := cb div 2;
    pcb := 0;
    pBuff := Buffer + cb;
    try
      if StreamInfo^.Converter <> nil then
        pcb := StreamInfo^.Converter.ConvertReadStream(StreamInfo^.Stream, pBuff, cb);
      if pcb > 0 then
      begin
        pBuff[pcb] := #0;
        if pBuff[pcb - 1] = #13 then pBuff[pcb - 1] := #0;
        pcb := AdjustLineBreaks(Buffer, pBuff);
        Move(Buffer^, pbBuff^, pcb);
      end;
    except
      Result := ReadError;
    end;
  finally
    StrDispose(Buffer);
  end;
end;
{$ENDIF}

{$IFDEF RX_D12}
function ContainsPreamble(Stream: TStream; Signature: TBytes): Boolean;
var
  Buffer: TBytes;
  I, LBufLen, LSignatureLen, LPosition: Integer;
begin
  Result := True;
  LSignatureLen := Length(Signature);
  LPosition := Stream.Position;
  try
    SetLength(Buffer, LSignatureLen);
    LBufLen := Stream.Read(Buffer[0], LSignatureLen);
  finally
    Stream.Position := LPosition;
  end;

  if LBufLen = LSignatureLen then
  begin
    for I := 1 to LSignatureLen do
      if Buffer[I - 1] <> Signature [I - 1] then
      begin
        Result := False;
        Break;
      end;
  end
  else
    Result := False;
end;
{$ENDIF}

procedure TRichEditStrings.LoadFromStream(Stream: TStream{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF});
var
  EditStream: TEditStream;
  Position: Longint;
  TextType: Longint;
  StreamInfo: TRichEditStreamInfo;
  Converter: TConversion;
{$IFDEF RX_D12}
  PlainText: Boolean;
{$ENDIF}
begin
{$IFDEF RX_D12}
  if Encoding = nil then
  begin
    // Find the appropraite encoding
    if ContainsPreamble(Stream, TEncoding.Unicode.GetPreamble) then
      Encoding := TEncoding.Unicode
    else
      if ContainsPreamble(Stream, TEncoding.BigEndianUnicode.GetPreamble) then
        Encoding := TEncoding.BigEndianUnicode
      else
        if ContainsPreamble(Stream, TEncoding.UTF8.GetPreamble) then
          Encoding := TEncoding.UTF8
        else
          Encoding := TEncoding.Default;
  end;
{$ENDIF}
  StreamInfo.Stream := Stream;
  if FConverter <> nil then
    Converter := FConverter
  else
    Converter := RichEdit.DefaultConverter.Create;
  StreamInfo.Converter := Converter;
{$IFDEF RX_D12}
  PlainText:= (FFormat = sfPlainText) or
                        ((FFormat = sfDefault) and (RichEdit.PlainText = True));
  StreamInfo.PlainText:= PlainText;
  StreamInfo.Encoding := Encoding;
{$ENDIF}
  try
    with EditStream do
    begin
{$IFDEF RX_D12}
      dwCookie := DWORD_PTR(@StreamInfo);
      pfnCallBack := StreamLoad;
{$ELSE}
      dwCookie := {$IFDEF WIN64}IntPtr{$ELSE}LongInt{$ENDIF}(Pointer(@StreamInfo));
      pfnCallBack := @StreamLoad;
{$ENDIF}
      dwError := 0;
    end;
    Position := Stream.Position;
    case FFormat of
      sfDefault:
        if RichEdit.PlainText then
          TextType := SF_TEXT
        else
          TextType := SF_RTF;
      sfRichText: TextType := SF_RTF;
      else {sfPlainText}
        TextType := SF_TEXT;
    end;
    if TextType = SF_RTF then
    begin
      if smPlainRtf in Mode then
        TextType := TextType or SFF_PLAINRTF;
    end
    else
    if TextType = SF_TEXT then
    begin
{$IFNDEF RX_D12}
      if (smUnicode in Mode) and (RichEditVersion > 1) then
{$ENDIF}
        TextType := TextType or SF_UNICODE;
    end;
    if smSelection in Mode then
      TextType := TextType or SFF_SELECTION;

    {$IFDEF KNT_DEBUG} Log.Add(string.format('RichEdit_LoadFromStream.  TextType: %s Encoding_CodePage: %d', [TextType.ToString, Encoding.CodePage]),  4 );  {$ENDIF}

{                  // [dpv]   See comment *5
    list.Clear;
    st1.Clear;
    st2.Clear;
}

    SendMessage(RichEdit.Handle, EM_STREAMIN, TextType, LPARAM(@EditStream));


//                                                                            [dpv] *1
//    if (EditStream.dwError <> 0) then
//    begin
//      Stream.Position := Position;
//      if (TextType and SF_RTF = SF_RTF) then
//        TextType := SF_TEXT{$IFNDEF RX_D12} or SF_UNICODE{$ENDIF}
//      else
//        TextType := SF_RTF;
//{$IFDEF RX_D12}
//      StreamInfo.PlainText := not PlainText;
//{$ENDIF}
//      SendMessage(RichEdit.Handle, EM_STREAMIN, TextType, LPARAM(@EditStream));
//      if EditStream.dwError <> 0 then
//        raise EOutOfResources.Create(ResStr(sRichEditLoadFail));
//    end;

  {                                                                                                                      [dpv]
    *1
        When using an older version of RxRichEd (with some modifications from KeyNote project) in Delphi 2006
        we only set FEditor.StreamFormat:= sfPlainText. We didn't use FEditor.Mode:= smUnicode previous to LoadFromStream.
        FEditor.Mode:= smUnicode were used, when necesary, before SaveToStream and with a custom StreamSaveW that included:

          SetString(cad, PChar(pbBuff), cb);
          cad:= WideStringToUTF8(PWideChar(cad));
          len:= length(cad);
          pcb := StreamInfo^.Converter.ConvertWriteStream(StreamInfo^.Stream, PAnsiChar(cad), len);

       In SaveToStream we made a modification:
        ...
        if smSelection in Mode then TextType := TextType or SFF_SELECTION;
        if (TextType and SF_TEXT <> 0) and (TextType and SF_UNICODE <> 0) and (Stream.Size = 0) and (RichEdit.TextLength > 0) then
           Stream.Write(UTF8_BOM[1], length(UTF8_BOM));
        SendMessage(RichEdit.Handle, EM_STREAMOUT, TextType, LPARAM(@EditStream));

      This way the editor were saved in UTF8 format, with BOM
      Current TRichEditStrings.SaveToStream works ok with TEncoding and it is not necessary to use something like that
      to save the editor on a stream in UTF8 format.

      But there are some texts, codified in UTF8, that can include some incorrect character conversions, that with the old method
      worked ok and only ignored the incorrect symbols, and now raises exception.
      ( See https://github.com/dpradov/keynote-nf/issues/610 )


      So, if the normal conversion made with TEncoding in current StreamLoad produces an error, we will retry with no TEncoding
      conversion and setting only SF_TEST and not SF_UNICODE. The stream is supposed to be in UTF8 format, with BOM. RichEdit will
      manage it correctly.
  }


   {                                                    // [dpv]   See comment *5
     var Str: String;
     var Str1, Str2: AnsiString;
     str:= list.Text;
     SetString(str1, PAnsiChar(st1.Memory), st1.Size);
     SetString(str2, PAnsiChar(st2.Memory), st2.Size);
     IOUtils.TFile.WriteAllText('E:\diferencias.txt', str);
     IOUtils.TFile.WriteAllText('E:\salida1.txt', str1);
     IOUtils.TFile.WriteAllText('E:\salida2.txt', str2);
    }

    if (EditStream.dwError <> 0) then                     // [dpv] *1
    begin
     {$IFDEF KNT_DEBUG} Log.Add(string.format('RichEdit_LoadFromStream.  Error: %d', [EditStream.dwError]),  4 );  {$ENDIF}
      if PlainText then begin
         Stream.Position := Position;
         TextType := SF_TEXT;                            // No SF_UNICODE
         StreamInfo.Encoding:= nil;
         StreamInfo.PlainText:= false;                   // => No TEncoding conversion in StreamLoad
         {$IFDEF KNT_DEBUG} Log.Add('RichEdit_LoadFromStream.  PlainText -> Retrying as SF_TEXT, no encoding',  4 );  {$ENDIF}
         SendMessage(RichEdit.Handle, EM_STREAMIN, TextType, LPARAM(@EditStream));
      end;
      if EditStream.dwError <> 0 then
        raise EOutOfResources.Create(ResStr(sRichEditLoadFail));
    end;
    RichEdit.SetSelection(0, 0, True);
  finally
    if FConverter = nil then Converter.Free;
  end;
end;

procedure TRichEditStrings.SaveToStream(Stream: TStream{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF});
var
  EditStream: TEditStream;
  TextType: Longint;
  StreamInfo: TRichEditStreamInfo;
  Converter: TConversion;
{$IFDEF RX_D12}
  Preamble: TBytes;
{$ENDIF}
begin
  if FConverter <> nil then
    Converter := FConverter
  else
    Converter := RichEdit.DefaultConverter.Create;
  StreamInfo.Stream := Stream;
  StreamInfo.Converter := Converter;
{$IFDEF RX_D12}
  StreamInfo.PlainText := (FFormat = sfPlainText) or
                          ((FFormat = sfDefault) and (RichEdit.PlainText = True));
  StreamInfo.Encoding := Encoding;
{$ENDIF}
  try
    with EditStream do
    begin
{$IFDEF RX_D12}
      dwCookie := DWORD_PTR(@StreamInfo);
      pfnCallBack := StreamSave;
{$ELSE}
      dwCookie := {$IFDEF WIN64}IntPtr{$ELSE}LongInt{$ENDIF}(Pointer(@StreamInfo));
      pfnCallBack := @StreamSave;
{$ENDIF}
      dwError := 0;
    end;
    case FFormat of
      sfDefault:
        if RichEdit.PlainText then
          TextType := SF_TEXT
        else
          TextType := SF_RTF;
      sfRichText: TextType := SF_RTF;
    else {sfPlainText}
      TextType := SF_TEXT;
    end;

    if TextType = SF_RTF then
    begin
      if smNoObjects in Mode then TextType := SF_RTFNOOBJS;
      if smPlainRtf in Mode then TextType := TextType or SFF_PLAINRTF;
    end
    else if TextType = SF_TEXT then
    begin
{$IFDEF RX_D12}
        TextType := TextType or SF_UNICODE;
        if Encoding <> nil then
        begin
          Preamble := Encoding.GetPreamble;
          //if (Length(Preamble) > 0) and  then                                                // [dpv]
          if (Length(Preamble) > 0) and (Stream.Size = 0) and (RichEdit.TextLength > 0) then   // [dpv]
            Stream.WriteBuffer(Preamble[0], Length(Preamble));
        end;
{$ELSE}
      if (smUnicode in Mode) and (RichEditVersion > 1) then begin
        TextType := TextType or SF_UNICODE;
        if (Stream.Size = 0) and (RichEdit.TextLength > 0) then                                 // [dpv]
           Stream.Write(UTF8_BOM[1], length(UTF8_BOM));                                         // [dpv]
      end;
{$ENDIF}
    end;
    if smSelection in Mode then
      TextType := TextType or SFF_SELECTION;
    SendMessage(RichEdit.Handle, EM_STREAMOUT, TextType, LPARAM(@EditStream));
    if EditStream.dwError <> 0 then
      raise EOutOfResources.Create(ResStr(sRichEditSaveFail));
  finally
    if FConverter = nil then Converter.Free;
  end;
end;

{$IFDEF RX_D12}
procedure TRichEditStrings.LoadFromFile(const FileName: string);
begin
  LoadFromFile(FileName, nil);
end;
{$ENDIF}

procedure TRichEditStrings.LoadFromFile(const FileName: string{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF});
var
  Ext: string;
  Convert: PRichConversionFormat;
  SaveFormat: TRichStreamFormat;
begin
{$IFNDEF VER90}
  Ext := {$IFDEF RX_D12}WideLowerCase{$ELSE}AnsiLowerCaseFileName{$ENDIF}(ExtractFileExt(Filename));
{$ELSE}
  Ext := LowerCase(ExtractFileExt(Filename));
{$ENDIF}
  System.Delete(Ext, 1, 1);
  Convert := ConversionFormatList;
  while Convert <> nil do
    with Convert^ do
      if Extension <> Ext then Convert := Next
      else Break;
  if (FConverter = nil) and (Convert <> nil) then
    FConverter := Convert^.ConversionClass.Create;
  try
    SaveFormat := Format;
    try
      if Convert <> nil then begin
        if Convert^.PlainText then FFormat := sfPlainText
        else FFormat := sfRichText;
      end;
      inherited LoadFromFile(FileName{$IFDEF RX_D12}, Encoding{$ENDIF});
    finally
      FFormat := SaveFormat;
    end;
  except
    FConverter.Free;
    FConverter := nil;
    raise;
  end;
end;

procedure TRichEditStrings.SaveToFile(const FileName: string{$IFDEF RX_D12}; Encoding: TEncoding{$ENDIF});
var
  Ext: string;
  Convert: PRichConversionFormat;
  SaveFormat: TRichStreamFormat;
begin
{$IFNDEF VER90}
  Ext := {$IFDEF RX_D12}WideLowerCase{$ELSE}AnsiLowerCaseFileName{$ENDIF}(ExtractFileExt(Filename));
{$ELSE}
  Ext := LowerCase(ExtractFileExt(Filename));
{$ENDIF}
  System.Delete(Ext, 1, 1);
  Convert := ConversionFormatList;
  while Convert <> nil do
    with Convert^ do
      if Extension <> Ext then Convert := Next
      else Break;
  if (FConverter = nil) and (Convert <> nil) then
    FConverter := Convert^.ConversionClass.Create;
  try
    SaveFormat := Format;
    try
      if Convert <> nil then begin
        if Convert^.PlainText then FFormat := sfPlainText
        else FFormat := sfRichText;
      end;
      inherited SaveToFile(FileName{$IFDEF RX_D12}, Encoding{$ENDIF});
    finally
      FFormat := SaveFormat;
    end;
  except
    FConverter.Free;
    FConverter := nil;
    raise;
  end;
end;

{ TOEMConversion }

function TOEMConversion.ConvertReadStream(Stream: TStream;
  Buffer: {$IFDEF RX_D12}TConversionBuffer{$ELSE}PChar{$ENDIF}; BufSize: Integer): Integer;
var
  Mem: TMemoryStream;
begin
  Mem := TMemoryStream.Create;
  try
    Mem.SetSize(BufSize);
    Result := inherited ConvertReadStream(Stream,
      {$IFDEF RX_D12}TConversionBuffer{$ELSE}PChar{$ENDIF}(Mem.Memory), BufSize);
    OemToCharBuff(PAnsiChar(Mem.Memory), {$IFDEF RX_D12}PChar{$ENDIF}(Buffer), Result);
  finally
    Mem.Free;
  end;
end;

function TOEMConversion.ConvertWriteStream(Stream: TStream;
  Buffer: {$IFDEF RX_D12}TConversionBuffer{$ELSE}PChar{$ENDIF}; BufSize: Integer): Integer;
var
  Mem: TMemoryStream;
begin
  Mem := TMemoryStream.Create;
  try
    Mem.SetSize(BufSize);
    CharToOemBuff({$IFDEF RX_D12}PChar{$ENDIF}(Buffer), PAnsiChar(Mem.Memory), BufSize);
    Result := inherited ConvertWriteStream(Stream,
      {$IFDEF RX_D12}TConversionBuffer{$ELSE}PChar{$ENDIF}(Mem.Memory), BufSize);
  finally
    Mem.Free;
  end;
end;

{ TRxCustomRichEdit }

constructor TRxCustomRichEdit.Create(AOwner: TComponent);
var
  DC: HDC;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FSelAttributes := TRxTextAttributes.Create(Self, atSelected);
  FDefAttributes := TRxTextAttributes.Create(Self, atDefaultText);
  FWordAttributes := TRxTextAttributes.Create(Self, atWord);
  FParagraph := TRxParaAttributes.Create(Self);
  FRichEditStrings := TRichEditStrings.Create;
  TRichEditStrings(FRichEditStrings).RichEdit := Self;
  TabStop := True;
  Width := 185;
  Height := 89;
{$IFDEF RX_ENHPRINT}
  pagerect:=rect(180,180,1308,1924);
{$ENDIF RX_ENHPRINT}
  AutoSize := False;
{$IFDEF RX_D4}
  DoubleBuffered := False;
{$ENDIF}
  FAllowObjects := True;
{$IFDEF RX_D3}
  FAllowInPlace := True;
{$ENDIF}
{$IFDEF RX_ENHPRINT}
  PrnPreviews:=TList.create;
{$ENDIF RX_ENHPRINT}
  FAutoVerbMenu := True;
  FHideSelection := True;
  FHideScrollBars := True;
  ScrollBars := ssBoth;
  FSelectionBar := True;
  FLangOptions := [rlAutoFont];
  DC := GetDC(0);
  FScreenLogPixels := GetDeviceCaps(DC, LOGPIXELSY);
  ReleaseDC(0, DC);
  DefaultConverter := TConversion;
  FOldParaAlignment := TParaAlignment(Alignment);
  FUndoLimit := 100;
  FAutoURLDetect := True;
  FWordSelection := True;
  with FClickRange do begin
    cpMin := -1;
    cpMax := -1;
  end;
  FCallback := TRichEditOleCallback.Create(Self);
{$IFDEF RX_D4}
  Perform(CM_PARENTBIDIMODECHANGED, 0, 0);
{$ENDIF}
  FUpdating:= 0;                               // [dpv]
  FOldEventMask:= 0;                           // [dpv]
end;

destructor TRxCustomRichEdit.Destroy;
begin
{$IFDEF RX_ENHPRINT}
  PrnPreviews.Clear;
  PrnPreviews.Free;
{$ENDIF RX_ENHPRINT}
  FLastFind := nil;
  FSelAttributes.Free;
  FDefAttributes.Free;
  FWordAttributes.Free;
  FParagraph.Free;
  FRichEditStrings.Free;
  FMemStream.Free;
  FPopupVerbMenu.Free;
  FFindDialog.Free;
  FReplaceDialog.Free;
  inherited Destroy;
  { be sure that callback object is destroyed after inherited Destroy }
  TRichEditOleCallback(FCallback).Free;
end;

procedure TRxCustomRichEdit.Clear;
begin
  CloseObjects;
  inherited Clear;
  Modified := False;
end;

procedure TRxCustomRichEdit.CreateParams(var Params: TCreateParams);
const
  HideScrollBars: array[Boolean] of DWORD = (ES_DISABLENOSCROLL, 0);
  HideSelections: array[Boolean] of DWORD = (ES_NOHIDESEL, 0);
  WordWraps: array[Boolean] of DWORD = (0, ES_AUTOHSCROLL);
  SelectionBars: array[Boolean] of DWORD = (0, ES_SELECTIONBAR);
begin
  inherited CreateParams(Params);

{$IFDEF RX_SELECTDLL}                                             // [dpv]
  if RichEditVersion = 1 then
     CreateSubClass(Params, RICHEDIT_CLASS10A)
  else if RichEditVersion = 5 then                                // Office 2003
     CreateSubClass(Params, RICHEDIT_CLASSW)
  else if (RichEditVersion = 6) or (RichEditVersion >= 8) then    // Office 2007, Office 2010, Office 2013 ..
     CreateSubClass(Params, RICHEDIT_CLASS60W)
  else if RichEditVersion >= 4 then
     CreateSubClass(Params, RICHEDIT_CLASS50W)
  else
     CreateSubClass(Params, RICHEDIT_CLASS);
   
{$ELSE}
  case RichEditVersion of
    1: CreateSubClass(Params, RICHEDIT_CLASS10A);
    2..3: CreateSubClass(Params, RICHEDIT_CLASS);
    else
      CreateSubClass(Params, MSFTEDIT_CLASS);
  end;
{$ENDIF}

 
  with Params do begin
    Style := (Style and not (WS_HSCROLL or WS_VSCROLL)) or ES_SAVESEL or
      (WS_CLIPSIBLINGS or WS_CLIPCHILDREN);
    { NOTE: WS_CLIPCHILDREN and WS_CLIPSIBLINGS are essential otherwise }
    { once the object is inserted you see some painting problems.       }
    Style := Style and not (WS_HSCROLL or WS_VSCROLL);
    if ScrollBars in [ssVertical, ssBoth] then
      Style := Style or WS_VSCROLL;
    if (ScrollBars in [ssHorizontal, ssBoth]) and not WordWrap then
      Style := Style or WS_HSCROLL;
    Style := Style or HideScrollBars[FHideScrollBars] or
      SelectionBars[FSelectionBar] or HideSelections[FHideSelection] and
      not WordWraps[WordWrap];
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TRxCustomRichEdit.CreateWnd;
var
  StreamFmt: TRichStreamFormat;
  Mode: TRichStreamModes;
  DesignMode: Boolean;
  Mask: Longint;
begin
  StreamFmt := TRichEditStrings(Lines).Format;
  Mode := TRichEditStrings(Lines).Mode;
  inherited CreateWnd;
{$IFNDEF VER90}
  if (SysLocale.FarEast) and not (SysLocale.PriLangID = LANG_JAPANESE) then
    Font.Charset := GetDefFontCharSet;
{$ENDIF}
  Mask := ENM_CHANGE or ENM_SELCHANGE or ENM_REQUESTRESIZE or ENM_PROTECTED;         // If we wanted to be able to use CN_DROPFILES => "or ENM_DROPFILES"
  if RichEditVersion >= 2 then Mask := Mask or ENM_LINK;
  SendMessage(Handle, EM_SETEVENTMASK, 0, LPARAM(Mask));
  SendMessage(Handle, EM_SETBKGNDCOLOR, 0, ColorToRGB(Color));

  DragAcceptFiles( handle, true );                                                   // [dpv] See comment *3 

{$IFDEF RX_D3}
  DoSetMaxLength(MaxLength);
{$ENDIF}
  SetWordSelection(FWordSelection);
  if RichEditVersion >= 2 then begin
    SendMessage(Handle, EM_AUTOURLDETECT, WPARAM(FAutoURLDetect), 0);
    FUndoLimit := SendMessage(Handle, EM_SETUNDOLIMIT, WPARAM(FUndoLimit), 0);
    UpdateTextModes(PlainText);
    SetLangOptions(FLangOptions);
  end;
  //if FAllowObjects then begin                                                     // [dpv] See comment *3
  if FAllowObjects or (assigned(FOnFileDropped)) then begin
    SendMessage(Handle, EM_SETOLECALLBACK, 0,
      LPARAM(TRichEditOleCallback(FCallback) as IRichEditOleCallback));
    GetRichEditOle(Handle, FRichEditOle);
    UpdateHostNames;
  end;
  if FMemStream <> nil then begin
    FMemStream.ReadBuffer(DesignMode, SizeOf(DesignMode));
    if DesignMode then begin
      TRichEditStrings(Lines).Format := sfPlainText;
      TRichEditStrings(Lines).Mode := [];
    end;
    try
      Lines.LoadFromStream(FMemStream);
      FMemStream.Free;
      FMemStream := nil;
    finally
      TRichEditStrings(Lines).Format := StreamFmt;
      TRichEditStrings(Lines).Mode := Mode;
    end;
  end;
  if RichEditVersion < 2 then
    SendMessage(Handle, WM_SETFONT, 0, 0);
  Modified := FModified;
end;

procedure TRxCustomRichEdit.DestroyWnd;
var
  StreamFmt: TRichStreamFormat;
  Mode: TRichStreamModes;
  DesignMode: Boolean;
begin
  FModified := Modified;
  FMemStream := TMemoryStream.Create;
  StreamFmt := TRichEditStrings(Lines).Format;
  Mode := TRichEditStrings(Lines).Mode;
  DesignMode := (csDesigning in ComponentState);
  FMemStream.WriteBuffer(DesignMode, SizeOf(DesignMode));
  if DesignMode then begin
    TRichEditStrings(Lines).Format := sfPlainText;
    TRichEditStrings(Lines).Mode := [];
  end;
  try
    Lines.SaveToStream(FMemStream);
    FMemStream.Position := 0;
  finally
    TRichEditStrings(Lines).Format := StreamFmt;
    TRichEditStrings(Lines).Mode := Mode;
  end;
  DragAcceptFiles( handle, false);                                 // [dpv]
  inherited DestroyWnd;
end;

procedure TRxCustomRichEdit.SetAllowObjects(Value: Boolean);
begin
  if FAllowObjects <> Value then begin
    FAllowObjects := Value;
    RecreateWnd;
  end;
end;

procedure TRxCustomRichEdit.SetOnFileDropped(Value: TRichEditFileDroppedEvent);                       // [dpv]
var
  OldFOnFileDropped: TRichEditFileDroppedEvent;
begin
  // See coment *3
  // https://stackoverflow.com/questions/1026513/comparing-a-pointer-to-functions-value-in-delphi

  OldFOnFileDropped:= FOnFileDropped;
  FOnFileDropped := Value;  
    
  if (assigned(OldFOnFileDropped) <> assigned(FOnFileDropped)) and (@FOnFileDropped <> @OldFOnFileDropped) then begin

    if (not FAllowObjects) and (assigned(FOnFileDropped)) then
       RecreateWnd;
  end;

end;


{$IFDEF RX_D12}
procedure TRxCustomRichEdit.UpdateHostNames;
var
  AppName: string;
  AppName_: PAnsiChar;
begin
  if HandleAllocated and Assigned(FRichEditOle) then begin
    AppName := Application.Title;
    if Trim(AppName) = '' then
      AppName := ExtractFileName(Application.ExeName);
      AppName_:= @AppName[1];
    if Trim(Title) = '' then
      IRichEditOle(FRichEditOle).SetHostNames(AppName_, AppName_)
    else
      IRichEditOle(FRichEditOle).SetHostNames(AppName_, PAnsiChar(AnsiString(Title)));
  end;
end;
{$ELSE}
procedure TRxCustomRichEdit.UpdateHostNames;
var
  AppName: string;
begin
  if HandleAllocated and Assigned(FRichEditOle) then begin
    AppName := Application.Title;
    if Trim(AppName) = '' then
      AppName := ExtractFileName(Application.ExeName);
    if Trim(Title) = '' then
      IRichEditOle(FRichEditOle).SetHostNames(PChar(AppName), PChar(AppName))
    else
      IRichEditOle(FRichEditOle).SetHostNames(PChar(AppName), PChar(Title));
  end;
end;
{$ENDIF}

procedure TRxCustomRichEdit.SetTitle(const Value: string);
begin
  if FTitle <> Value then begin
    FTitle := Value;
    UpdateHostNames;
  end;
end;

function TRxCustomRichEdit.GetPopupMenu: TPopupMenu;
var
  EnumOleVerb: IEnumOleVerb;
  OleVerb: TOleVerb;
  Item: TMenuItem;
  ReObject: TReObject;
begin
  FPopupVerbMenu.Free;
  FPopupVerbMenu := nil;
  Result := inherited GetPopupMenu;
  if FAutoVerbMenu and (SelectionType = [stObject]) and
    Assigned(FRichEditOle) then
  begin
    FillChar(ReObject, SizeOf(ReObject), 0);
    ReObject.cbStruct := SizeOf(ReObject);
    if Succeeded(IRichEditOle(FRichEditOle).GetObject(
      Longint(REO_IOB_SELECTION), ReObject, REO_GETOBJ_POLEOBJ)) then
    try
      if Assigned(ReObject.poleobj) and
        (ReObject.dwFlags and REO_INPLACEACTIVE = 0) then
      begin
        FPopupVerbMenu := TPopupMenu.Create(Self);
        if ReObject.poleobj.EnumVerbs(EnumOleVerb) = 0 then
        try
          while (EnumOleVerb.Next(1, OleVerb, nil) = 0) and
            (OleVerb.lVerb >= 0) and
            (OleVerb.grfAttribs and OLEVERBATTRIB_ONCONTAINERMENU <> 0) do
          begin
            Item := TMenuItem.Create(FPopupVerbMenu);
            Item.Caption := WideCharToString(OleVerb.lpszVerbName);
            Item.Tag := OleVerb.lVerb;
            Item.Default := (OleVerb.lVerb = OLEIVERB_PRIMARY);
            Item.OnClick := PopupVerbClick;
            FPopupVerbMenu.Items.Add(Item);
          end;
        finally
          ReleaseObject(EnumOleVerb);
        end;
        if (Result <> nil) and (Result.Items.Count > 0) then begin
          Item := TMenuItem.Create(FPopupVerbMenu);
          Item.Caption := '-';
          Result.Items.Add(Item);
          Item := TMenuItem.Create(FPopupVerbMenu);
          Item.Caption := Format(ResStr(SPropDlgCaption),
            [GetFullNameStr(ReObject.poleobj)]);
          Item.OnClick := ObjectPropsClick;
          Result.Items.Add(Item);
          if FPopupVerbMenu.Items.Count > 0 then begin
            FPopupVerbMenu.Items.Caption := GetFullNameStr(ReObject.poleobj);
            Result.Items.Add(FPopupVerbMenu.Items);
          end;
        end
        else if FPopupVerbMenu.Items.Count > 0 then begin
          Item := TMenuItem.Create(FPopupVerbMenu);
          Item.Caption := Format(ResStr(SPropDlgCaption),
            [GetFullNameStr(ReObject.poleobj)]);
          Item.OnClick := ObjectPropsClick;
          FPopupVerbMenu.Items.Insert(0, Item);
          Result := FPopupVerbMenu;
        end;
      end;
    finally
      ReleaseObject(ReObject.poleobj);
    end;
  end;
end;

procedure TRxCustomRichEdit.PopupVerbClick(Sender: TObject);
var
  ReObject: TReObject;
begin
  if Assigned(FRichEditOle) then begin
    FillChar(ReObject, SizeOf(ReObject), 0);
    ReObject.cbStruct := SizeOf(ReObject);
    if Succeeded(IRichEditOle(FRichEditOle).GetObject(
      Longint(REO_IOB_SELECTION), ReObject, REO_GETOBJ_POLEOBJ or
      REO_GETOBJ_POLESITE)) then
    try
      if ReObject.dwFlags and REO_INPLACEACTIVE = 0 then
        OleCheck(ReObject.poleobj.DoVerb((Sender as TMenuItem).Tag, nil,
          ReObject.polesite, 0, Handle, ClientRect));
    finally
      ReleaseObject(ReObject.polesite);
      ReleaseObject(ReObject.poleobj);
    end;
  end;
end;

procedure TRxCustomRichEdit.ObjectPropsClick(Sender: TObject);
begin
  ObjectPropertiesDialog;
end;

procedure TRxCustomRichEdit.WMSetFont(var Message: TWMSetFont);
begin
  FDefAttributes.Assign(Font);
end;

procedure TRxCustomRichEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FDefAttributes.Assign(Font);
end;

procedure TRxCustomRichEdit.CreateWindowHandle(const Params: TCreateParams);
var
  Bounds: TRect;
begin
  Bounds := BoundsRect;
  inherited CreateWindowHandle(Params);
  if HandleAllocated then BoundsRect := Bounds;
end;

{$IFDEF RX_D3}
procedure TRxCustomRichEdit.DoSetMaxLength(Value: Integer);
begin
  { The rich edit control's default maximum amount of text is 32K }
  { Let's set it at 16M by default }
  if Value = 0 then Value := $FFFFFF;
  SendMessage(Handle, EM_EXLIMITTEXT, 0, LPARAM(Value));
end;
{$ENDIF}

function TRxCustomRichEdit.GetCaretPos: TPoint;
var
  CharRange: TCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL, 0, LPARAM(@CharRange));
  Result.X := CharRange.cpMax;
  Result.Y := LineFromChar(Result.X);
  Dec(Result.X, GetLineIndex(-1));
end;

{$IFDEF RX_D3}
function TRxCustomRichEdit.GetSelLength: Integer;
begin
  with GetSelection do
    Result := cpMax - cpMin;
end;

function TRxCustomRichEdit.GetSelStart: Integer;
begin
  Result := GetSelection.cpMin;
end;

function TRxCustomRichEdit.GetSelText: string;
begin
  with GetSelection do
    Result := GetTextRange(cpMin, cpMax);
end;

function TRxCustomRichEdit.GetSelVisibleText: string;
var
  GetTextEx: TGetTextEx;
  longSel: integer;
begin
   with GetSelection do
      longSel:= cpMax-cpMin+1;

   SetLength(Result, longSel);

   with GetTextEx do begin
      cb:= longSel * 2 + 4;     // size in bytes
      flags:= GT_SELECTION or GT_NOHIDDENTEXT;
      codepage:= 1200;
      lpDefaultChar:= nil;
      lpUsedDefChar:= nil;
   end;

   longSel:= SendMessage(Handle, EM_GETTEXTEX, WPARAM(@GetTextEx), LPARAM(Result));
   SetLength(Result, longSel);
end;


function TRxCustomRichEdit.GetVisibleText: string;
var
  GetTextEx: TGetTextEx;
  len: integer;
begin
   len:= GetTextLen;
   SetLength(Result, len);

   with GetTextEx do begin
      cb:= len * 2 + 4;     // size in bytes
      flags:= GT_NOHIDDENTEXT;
      codepage:= 1200;
      lpDefaultChar:= nil;
      lpUsedDefChar:= nil;
   end;

   len:= SendMessage(Handle, EM_GETTEXTEX, WPARAM(@GetTextEx), LPARAM(Result));
   SetLength(Result, len);
end;

{ [dpv]
 Uses EM_GETTEXTEX message

 GT_RAWTEXT: Text is retrieved exactly as it appears in memory. This includes special structure characters for table row and cell delimiters
             (see Remarks for EM_INSERTTABLE) as well as math object delimiters (start delimiter U+FDD0, argument delimiter U+FDEE, and end
             delimiter U+FDDF) and object markers (U+FFFC). This maintains character-position alignment between the retrieved text and the text in memory.
  => Position identified looking for a pattern text in a string returned by this function can be used to move caret to that position.

 Also applies other options in GT_DEFAULT: carriage returns (U+000D) are not translated into CRLF (U+000D U+000A)
}
function TRxCustomRichEdit.TextPlain (Selection: boolean= False): string;
var
  GetTextEx: TGetTextEx;
  len: integer;
begin
   len:= GetTextLen;
   SetLength(Result, len);

   with GetTextEx do begin
      cb:= len * 2 + 4;           // size in bytes
      flags:= GT_RAWTEXT; // GT_DEFAULT;
      if Selection then
         flags:= flags or GT_SELECTION;
      codepage:= 1200;
      lpDefaultChar:= nil;
      lpUsedDefChar:= nil;
   end;

   len:= SendMessage(Handle, EM_GETTEXTEX, WPARAM(@GetTextEx), LPARAM(Result));
   SetLength(Result, len);
end;


{$IFDEF RX_ENH}

{ EM_SETTEXTEX (https://learn.microsoft.com/en-us/windows/win32/controls/em-settextex):
  <<Combines the functionality of the WM_SETTEXT and EM_REPLACESEL messages, and adds the ability to set text using a code page and to use either rich text or plain text.
   Parameters
     wParam
        Pointer to a SETTEXTEX structure that specifies flags and an optional code page to use in translating to Unicode.
     lParam
        Pointer to the null-terminated text to insert. This text is an ANSI string, unless the code page is 1200 (Unicode).
		If lParam starts with a valid RTF ASCII sequence for example, "{\rtf" or "{urtf" the text is read in using the RTF reader.
    >>
  Requirement: Rich Edit 3.0 }

procedure TRxCustomRichEdit.PutRtfText (const sRTF: string; const DoInsert: boolean;
                                        const SelectionOnly: boolean = true; const KeepSelected: boolean = false);
var
  aSTE: TSetTextEx;
  s: AnsiString;
  paramRTF: LPARAM;
begin
  if sRTF = '' then exit;

  if not DoInsert then begin          // If we're appending, we need to set our selection at the end of the control
     SelStart := -1;
     selLength := 0;
  end;

  try
    if RichEditVersion < 3 then begin
       {$IFDEF KNT_DEBUG} Log.Add('PutRtfText [string] / RichEdtVer < 3', 4 );  {$ENDIF}
       if (not SelectionOnly) then
	      Lines.Clear;
       RtfSelText:= sRTF;
       exit;
    end
    else begin
       {$IFDEF KNT_DEBUG} Log.Add('PutRtfText [string] / RichEdtVer >= 3', 4 );  {$ENDIF}
       if SelectionOnly then
          aSTE.flags:= ST_SELECTION;
       aSTE.flags:= aSTE.flags or ST_KEEPUNDO;

       if RichEditVersion <= 4 then begin          // See https://github.com/dpradov/keynote-nf/issues/602#issuecomment-1688868732  (problem with old RichEdit versions -- W7 ...)
          if CanSaveAsANSI(sRTF) then begin
             s:= sRTF;
             //aSTE.codepage:= StringCodePage(s);   // CP_ACP
             aSTE.codepage:= CP_ACP;          // CP_ACP= ANSI codepage => use the currently set default Windows ANSI codepage.
          end
          else begin
             aSTE.codepage:= CP_UTF8;
             s:= UTF8Encode(sRTF);
          end;
          paramRTF:= LPARAM(PAnsiChar(s));
       end
       else begin
          aSTE.codepage:= 1200;   // 1200 (Unicode)
          paramRTF:= LPARAM(PChar(sRTF));
       end;

       SendMessage(Handle, EM_SETTEXTEX, WPARAM(@aSTE), paramRTF);           // EM_SETTEXTEX
    end;

    if not KeepSelected then
       SelStart := SelStart + SelLength;

  finally
  end;
end;


procedure TRxCustomRichEdit.PutRtfText (const sRTF: RawByteString; const DoInsert: boolean;
                                        const SelectionOnly: boolean = true; const KeepSelected: boolean = false);
var
  aSTE: TSetTextEx;
begin

  if sRTF = '' then exit;

  if not DoInsert then begin            // If we're appending, we need to set our selection at the end of the control
     SelStart := -1;
     selLength := 0;
  end;

  try
    if RichEditVersion < 3 then begin
       {$IFDEF KNT_DEBUG} Log.Add('PutRtfText [RawByteString] / RichEdtVer < 3', 4 );  {$ENDIF}
       if (not SelectionOnly) then
	      Lines.Clear;
       RtfSelText:= sRTF;
       exit;
    end
    else begin
       aSTE.flags:= 0;
       if SelectionOnly then
          aSTE.flags:= ST_SELECTION;
       aSTE.flags:= aSTE.flags or ST_KEEPUNDO;
       aSTE.codepage:= CP_ACP;          // CP_ACP= ANSI codepage => use the currently set default Windows ANSI codepage.
       //aSTE.codepage:= StringCodePage(sRTF);
       {$IFDEF KNT_DEBUG} Log.Add('PutRtfText [RawByteString] / RichEdtVer >= 3   Codepage:' + aSTE.Codepage.ToString, 4 );  {$ENDIF}
       SendMessage(Handle, EM_SETTEXTEX, WPARAM(@aSTE), LPARAM(PAnsiChar(sRTF)));
    end;

    if not KeepSelected then
       SelStart := SelStart + SelLength;

  finally
  end;
end;

{$ENDIF}

{$ENDIF RX_D3}

procedure TRxCustomRichEdit.SetMargins(Left, Right: integer);                       // [dpv]
var
  w: WPARAM;
  l: LPARAM;
begin
   if (Left <= 0) or (Right <= 0) then
       w:= EC_USEFONTINFO
   else begin
       w:= EC_LEFTMARGIN or EC_RIGHTMARGIN;
       l:= MAKELPARAM(Left, Right);            // To query -> LoWord() HiWord()
   end;

   SendMessage(Handle, EM_SETMARGINS, w, l);
end;


function TRxCustomRichEdit.GetSelTextBuf(Buffer: PChar; BufSize: Integer): Integer;
var
  S: string;
begin
  S := SelText;
  Result := Length(S);
  if BufSize < Length(S) then Result := BufSize;
  StrPLCopy(Buffer, S, Result);
end;

{$IFDEF RX_D4}
procedure TRxCustomRichEdit.CMBiDiModeChanged(var Message: TMessage);
var
  AParagraph: TParaFormat2;
begin
  HandleNeeded; { we REALLY need the handle for BiDi }
  inherited;
  Paragraph.GetAttributes(AParagraph);
  AParagraph.dwMask := PFM_ALIGNMENT;
  AParagraph.wAlignment := Ord(Alignment) + 1;
  Paragraph.SetAttributes(AParagraph);
end;
{$ENDIF}

procedure TRxCustomRichEdit.SetHideScrollBars(Value: Boolean);
begin
  if HideScrollBars <> Value then begin
    FHideScrollBars := Value;
    RecreateWnd;
  end;
end;

procedure TRxCustomRichEdit.ScrollLinesBy(inc: integer);
begin
  SendMessage(Handle, EM_LINESCROLL, 0, inc);
end;

procedure TRxCustomRichEdit.SetScrollPosInEditor(Point: TPoint);
begin
  SendMessage(Handle, EM_SETSCROLLPOS, 0, LPARAM(@Point));
end;

function TRxCustomRichEdit.GetScrollPosInEditor: TPoint;
begin
  SendMessage(Handle, EM_GETSCROLLPOS, 0, LPARAM(@Result));
end;


procedure TRxCustomRichEdit.SetSelectionBar(Value: Boolean);
begin
  if FSelectionBar <> Value then begin
    FSelectionBar := Value;
    RecreateWnd;
  end;
end;

procedure TRxCustomRichEdit.SetHideSelection(Value: Boolean);
begin
  if HideSelection <> Value then begin
    FHideSelection := Value;
    SendMessage(Handle, EM_HIDESELECTION, Ord(HideSelection), LPARAM(True));
  end;
end;

function TRxCustomRichEdit.GetAutoURLDetect: Boolean;
begin
  Result := FAutoURLDetect;
  if HandleAllocated and not (csDesigning in ComponentState) then begin
    if RichEditVersion >= 2 then
      Result := Boolean(SendMessage(Handle, EM_GETAUTOURLDETECT, 0, 0));
  end;
end;

procedure TRxCustomRichEdit.SetAutoURLDetect(Value: Boolean);
begin
  if Value <> FAutoURLDetect then begin
    FAutoURLDetect := Value;
    if HandleAllocated and (RichEditVersion >= 2) then
      SendMessage(Handle, EM_AUTOURLDETECT, WPARAM(FAutoURLDetect), 0);
  end;
end;

function TRxCustomRichEdit.GetWordSelection: Boolean;
begin
  Result := FWordSelection;
  if HandleAllocated then
    Result := (SendMessage(Handle, EM_GETOPTIONS, 0, 0) and
      ECO_AUTOWORDSELECTION) <> 0;
end;

procedure TRxCustomRichEdit.SetWordSelection(Value: Boolean);
var
  Options: LPARAM;
begin
  FWordSelection := Value;
  if HandleAllocated then begin
    Options := SendMessage(Handle, EM_GETOPTIONS, 0, 0);
    if Value then Options := Options or ECO_AUTOWORDSELECTION
    else Options := Options and not ECO_AUTOWORDSELECTION;
    SendMessage(Handle, EM_SETOPTIONS, ECOOP_SET, Options);
  end;
end;

const
  RichLangOptions: array[TRichLangOption] of DWORD = (IMF_AUTOKEYBOARD,
    IMF_AUTOFONT, IMF_IMECANCELCOMPLETE, IMF_IMEALWAYSSENDNOTIFY);

function TRxCustomRichEdit.GetLangOptions: TRichLangOptions;
var
  Flags: Longint;
  I: TRichLangOption;
begin
  Result := FLangOptions;
  if HandleAllocated and not (csDesigning in ComponentState) and
    (RichEditVersion >= 2) then
  begin
    Result := [];
    Flags := SendMessage(Handle, EM_GETLANGOPTIONS, 0, 0);
    for I := Low(TRichLangOption) to High(TRichLangOption) do
      if Flags and RichLangOptions[I] <> 0 then Include(Result, I);
  end;
end;

procedure TRxCustomRichEdit.SetLangOptions(Value: TRichLangOptions);
var
  Flags: DWORD;
  I: TRichLangOption;
begin
  FLangOptions := Value;
  if HandleAllocated and (RichEditVersion >= 2) then begin
    Flags := 0;
    for I := Low(TRichLangOption) to High(TRichLangOption) do
      if I in Value then Flags := Flags or RichLangOptions[I];
    SendMessage(Handle, EM_SETLANGOPTIONS, 0, LPARAM(Flags));
  end;
end;

procedure TRxCustomRichEdit.SetSelAttributes(Value: TRxTextAttributes);
begin
  FSelAttributes.Assign(Value);
end;

function TRxCustomRichEdit.GetCanRedo: Boolean;
begin
  Result := False;
  if HandleAllocated and (RichEditVersion >= 2) then
    Result := SendMessage(Handle, EM_CANREDO, 0, 0) <> 0;
end;

function TRxCustomRichEdit.GetCanPaste: Boolean;
begin
  Result := False;
  if HandleAllocated then
    Result := SendMessage(Handle, EM_CANPASTE, 0, 0) <> 0;
end;

{$IFNDEF RX_V110}
function TRxCustomRichEdit.GetCanUndo: Boolean;
begin
  Result := False;
  if HandleAllocated then
    Result := SendMessage(Handle, EM_CANUNDO, 0, 0) <> 0;
end;
{$ENDIF}

function TRxCustomRichEdit.GetRedoName: TUndoName;
begin
  Result := unUnknown;
  if (RichEditVersion >= 2) and HandleAllocated then
    Result := TUndoName(SendMessage(Handle, EM_GETREDONAME, 0, 0));
end;

function TRxCustomRichEdit.GetUndoName: TUndoName;
begin
  Result := unUnknown;
  if (RichEditVersion >= 2) and HandleAllocated then
    Result := TUndoName(SendMessage(Handle, EM_GETUNDONAME, 0, 0));
end;


procedure TRxCustomRichEdit.SuspendUndo;
var
  docTOM: ITextDocument;
begin
  if Assigned(FRichEditOle) then begin
    OleCheck(FRichEditOle.QueryInterface(ITextDocument, docTOM));
    docTOM.Undo(tomSuspend);
  end;
end;

procedure TRxCustomRichEdit.ResumeUndo;
var
  docTOM: ITextDocument;
begin
  if Assigned(FRichEditOle) then begin
    OleCheck(FRichEditOle.QueryInterface(ITextDocument, docTOM));
    docTOM.Undo(tomResume);
  end;
end;


function TRxCustomRichEdit.GetSelectionType: TRichSelectionType;
const
  SelTypes: array[TRichSelection] of Integer = (
    SEL_TEXT, SEL_OBJECT, SEL_MULTICHAR, SEL_MULTIOBJECT);
var
  Selection: Integer;
  I: TRichSelection;
begin
  Result := [];
  if HandleAllocated then begin
    Selection := SendMessage(Handle, EM_SELECTIONTYPE, 0, 0);
    for I := Low(TRichSelection) to High(TRichSelection) do
      if SelTypes[I] and Selection <> 0 then Include(Result, I);
  end;
end;

function TRxCustomRichEdit.GetSelection: TCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL, 0, LPARAM(@Result));
end;

procedure TRxCustomRichEdit.SetSelection(StartPos, EndPos: Longint;
  ScrollCaret: Boolean);
var
  CharRange: TCharRange;
begin
  with CharRange do begin
    cpMin := StartPos;
    cpMax := EndPos;
  end;
  SendMessage(Handle, EM_EXSETSEL, 0, LPARAM(@CharRange));
  if ScrollCaret then SendMessage(Handle, EM_SCROLLCARET, 0, 0);
end;

{$IFDEF RX_D3}
procedure TRxCustomRichEdit.SetSelLength(Value: Integer);
begin
  with GetSelection do SetSelection(cpMin, cpMin + Value, True);
end;

procedure TRxCustomRichEdit.SetSelStart(Value: Integer);
begin
  SetSelection(Value, Value, False);
end;
{$ENDIF RX_D3}

function TRxCustomRichEdit.GetCharPos(CharIndex: Integer): TPoint;
var
  Res: Longint;
begin
  FillChar(Result, SizeOf(Result), 0);
  if HandleAllocated then begin
    if RichEditVersion = 2 then begin
      Res := SendMessage(Handle, Messages.EM_POSFROMCHAR, WPARAM(CharIndex), 0);
      Result.X := LoWord(Res);
      Result.Y := HiWord(Res);
    end
    else { RichEdit 1.0 and 3.0 }
      SendMessage(Handle, Messages.EM_POSFROMCHAR, WPARAM(@Result), LPARAM(CharIndex));
  end;
end;

function TRxCustomRichEdit.GetCharFromPos(Point: TPoint): integer;                       // [dpv]
begin
  if HandleAllocated then begin
      Result:= SendMessage(Handle, Messages.EM_CHARFROMPOS, WPARAM(nil), LPARAM(@Point));
  end;
end;


function TRxCustomRichEdit.GetTextRange(StartPos, EndPos: Longint): string;
var
  TextRange: TTextRange;
begin
  SetLength(Result, EndPos - StartPos + 1);
  TextRange.chrg.cpMin := StartPos;
  TextRange.chrg.cpMax := EndPos;
  TextRange.lpstrText := PChar(Result);
  SetLength(Result, SendMessage(Handle, EM_GETTEXTRANGE, 0, LPARAM(@TextRange)));
end;

function TRxCustomRichEdit.WordAtCursor: string;
var
  Range: TCharRange;
begin
  Result := '';
  if HandleAllocated then begin
    Range.cpMax := SelStart;
    if Range.cpMax = 0 then Range.cpMin := 0
    else if SendMessage(Handle, EM_FINDWORDBREAK, WB_ISDELIMITER, LPARAM(Range.cpMax)) <> 0 then
      Range.cpMin := SendMessage(Handle, EM_FINDWORDBREAK, WB_MOVEWORDLEFT, LPARAM(Range.cpMax))
    else
      Range.cpMin := SendMessage(Handle, EM_FINDWORDBREAK, WB_LEFT, LPARAM(Range.cpMax));
    while SendMessage(Handle, EM_FINDWORDBREAK, WB_ISDELIMITER, LPARAM(Range.cpMin)) <> 0 do
      Inc(Range.cpMin);
    Range.cpMax := SendMessage(Handle, EM_FINDWORDBREAK, WB_RIGHTBREAK, LPARAM(Range.cpMax));
    Result := Trim(GetTextRange(Range.cpMin, Range.cpMax));
  end;
end;

function TRxCustomRichEdit.LineFromChar(CharIndex: Integer): Integer;
begin
  Result := SendMessage(Handle, EM_EXLINEFROMCHAR, 0, LPARAM(CharIndex));
end;

function TRxCustomRichEdit.GetLineIndex(LineNo: Integer): Integer;
begin
  Result := SendMessage(Handle, EM_LINEINDEX, WPARAM(LineNo), 0);
end;

function TRxCustomRichEdit.GetLineLength(CharIndex: Integer): Integer;
begin
  Result := SendMessage(Handle, EM_LINELENGTH, WPARAM(CharIndex), 0);
end;

function TRxCustomRichEdit.GetFirstVisibleLine: Integer;
begin
  Result := SendMessage(Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
end;

procedure TRxCustomRichEdit.SetUndoLimit(Value: Integer);
begin
  if (Value <> FUndoLimit) then begin
    FUndoLimit := Value;
    if (RichEditVersion >= 2) and HandleAllocated then
      FUndoLimit := SendMessage(Handle, EM_SETUNDOLIMIT, WPARAM(Value), 0);
  end;
end;

procedure TRxCustomRichEdit.SetDefAttributes(Value: TRxTextAttributes);
begin
  FDefAttributes.Assign(Value);
end;

procedure TRxCustomRichEdit.SetWordAttributes(Value: TRxTextAttributes);
begin
  FWordAttributes.Assign(Value);
end;

function TRxCustomRichEdit.GetStreamFormat: TRichStreamFormat;
begin
  Result := TRichEditStrings(Lines).Format;
end;

function TRxCustomRichEdit.GetStreamMode: TRichStreamModes;
begin
  Result := TRichEditStrings(Lines).Mode;
end;

procedure TRxCustomRichEdit.SetStreamFormat(Value: TRichStreamFormat);
begin
  TRichEditStrings(Lines).Format := Value;
end;

procedure TRxCustomRichEdit.SetStreamMode(Value: TRichStreamModes);
begin
  TRichEditStrings(Lines).Mode := Value;
end;

procedure TRxCustomRichEdit.SetPlainText(Value: Boolean);
var
  MemStream: TStream;
  StreamFmt: TRichStreamFormat;
  Mode: TRichStreamModes;
begin
  if PlainText <> Value then begin
    if HandleAllocated and (RichEditVersion >= 2) then begin
      MemStream := TMemoryStream.Create;
      try
        StreamFmt := TRichEditStrings(Lines).Format;
        Mode := TRichEditStrings(Lines).Mode;
        try
          if (csDesigning in ComponentState) or Value then
            TRichEditStrings(Lines).Format := sfPlainText
          else TRichEditStrings(Lines).Format := sfRichText;
          TRichEditStrings(Lines).Mode := [];
          Lines.SaveToStream(MemStream);
          MemStream.Position := 0;
          TRichEditStrings(Lines).EnableChange(False);
          try
            SendMessage(Handle, WM_SETTEXT, 0, 0);
            UpdateTextModes(Value);
            FPlainText := Value;
          finally
            TRichEditStrings(Lines).EnableChange(True);
          end;
          Lines.LoadFromStream(MemStream);
        finally
          TRichEditStrings(Lines).Format := StreamFmt;
          TRichEditStrings(Lines).Mode := Mode;
        end;
      finally
        MemStream.Free;
      end;
    end;
    FPlainText := Value;
  end;
end;

procedure TRxCustomRichEdit.UpdateTextModes(Plain: Boolean);
const
  TextModes: array[Boolean] of DWORD = (TM_RICHTEXT, TM_PLAINTEXT);
  UndoModes: array[Boolean] of DWORD = (TM_SINGLELEVELUNDO, TM_MULTILEVELUNDO);
begin
  if (RichEditVersion >= 2) and HandleAllocated then begin
    SendMessage(Handle, EM_SETTEXTMODE, WPARAM(TextModes[Plain] or
      UndoModes[FUndoLimit > 1]), 0);
  end;
end;

procedure TRxCustomRichEdit.CMColorChanged(var Message: TMessage);
begin
  inherited;
  SendMessage(Handle, EM_SETBKGNDCOLOR, 0, ColorToRGB(Color))
end;

procedure TRxCustomRichEdit.EMReplaceSel(var Message: TMessage);
var
  CharRange: TCharRange;
begin
  Perform(EM_EXGETSEL, 0, LPARAM(@CharRange));
  with CharRange do
    cpMax := cpMin + Integer(StrLen(PChar(Message.lParam)));
  if (FUndoLimit > 1) and (RichEditVersion >= 2) and not FLinesUpdating then
    Message.wParam := 1; { allow Undo }
  inherited;
  if not FLinesUpdating then begin
    Perform(EM_EXSETSEL, 0, LPARAM(@CharRange));
    Perform(EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TRxCustomRichEdit.SetRichEditStrings(Value: TStrings);
begin
  FRichEditStrings.Assign(Value);
end;

procedure TRxCustomRichEdit.CloseObjects;
var
  I: Integer;
  ReObject: TReObject;
begin
  if Assigned(FRichEditOle) then begin
    FillChar(ReObject, SizeOf(ReObject), 0);
    ReObject.cbStruct := SizeOf(ReObject);
    with IRichEditOle(FRichEditOle) do begin
      for I := GetObjectCount - 1 downto 0 do
        if Succeeded(GetObject(I, ReObject, REO_GETOBJ_POLEOBJ)) then begin
          if ReObject.dwFlags and REO_INPLACEACTIVE <> 0 then
            IRichEditOle(FRichEditOle).InPlaceDeactivate;
          ReObject.poleobj.Close(OLECLOSE_NOSAVE);
          ReleaseObject(ReObject.poleobj);
        end;
    end;
  end;
end;


//function TRxCustomRichEdit.PasteSpecialDialog: Boolean;
function TRxCustomRichEdit.PasteSpecialDialog (PasteImg: boolean= true): integer;               // [dpv]

  procedure SetPasteEntry(var Entry: TOleUIPasteEntry; Format: TClipFormat;
    tymed: DWORD; const FormatName, ResultText: string; Flags: DWORD);
  begin
    with Entry do begin
      fmtetc.cfFormat := Format;
      fmtetc.dwAspect := DVASPECT_CONTENT;
      fmtetc.lIndex := -1;
      fmtetc.tymed := tymed;
      if FormatName <> '' then lpstrFormatName := PChar(FormatName)
      else lpstrFormatName := '%s';
      if ResultText <> '' then lpstrResultText := PChar(ResultText)
      else lpstrResultText := '%s';
      dwFlags := Flags;
    end;
  end;

  function GetAsHTML: UTf8String;              // [dpv]
  var
     Data: THandle;
  begin
      try
        Clipboard.Open;
        try
           Data := GetClipboardData(CFHtml);
           if Data <> 0 then begin
              Result := PUTf8Char(GlobalLock(Data));
              GlobalUnLock(Data)
           end
           else
              Result:= '';
        finally
          Clipboard.Close;
        end;
      except
      end;
  end;


const
   PasteFormatCount = 7;                                     // [dpv] (6 -> 7)
var
  Data: TOleUIPasteSpecial;
  PasteFormats: array[0..PasteFormatCount - 1] of TOleUIPasteEntry;
  Format: Integer;
  FormatSelected: integer;                                    // [dpv]
  OleClientSite: IOleClientSite;
  Storage: IStorage;
  OleObject: IOleObject;
  ReObject: TReObject;
  Selection: TCharRange;
  HTMLText: UTF8string;                                       // [dpv]
begin
  FormatSelected := -1;
  if not CanPaste or not Assigned(FRichEditOle) then Exit;
  FillChar(Data, SizeOf(Data), 0);
  FillChar(PasteFormats, SizeOf(PasteFormats), 0);
  with Data do begin
    cbStruct := SizeOf(Data);
    hWndOwner := Handle;
    arrPasteEntries := @PasteFormats;
    cPasteEntries := PasteFormatCount;
    arrLinkTypes := @CFLinkSource;
    cLinkTypes := 1;
    dwFlags := PSF_SELECTPASTE;
  end;
  SetPasteEntry(PasteFormats[0], CFEmbeddedObject, TYMED_ISTORAGE, '', '',
    OLEUIPASTE_PASTE or OLEUIPASTE_ENABLEICON);
  SetPasteEntry(PasteFormats[1], CFLinkSource, TYMED_ISTREAM, '', '',
    OLEUIPASTE_LINKTYPE1 or OLEUIPASTE_ENABLEICON);
  SetPasteEntry(PasteFormats[2], CFRtf, TYMED_ISTORAGE,
    CF_RTF, CF_RTF, OLEUIPASTE_PASTE);
  SetPasteEntry(PasteFormats[3], CFRtfNoObjs, TYMED_ISTORAGE,
    CF_RTFNOOBJS, CF_RTFNOOBJS, OLEUIPASTE_PASTE);
  SetPasteEntry(PasteFormats[4], CF_TEXT, TYMED_HGLOBAL,
    'Unformatted text', 'text without any formatting', OLEUIPASTE_PASTE);
  SetPasteEntry(PasteFormats[5], CF_BITMAP, TYMED_GDI,
    'Windows Bitmap', 'bitmap image', OLEUIPASTE_PASTE);
  SetPasteEntry(PasteFormats[6], CFHtml, TYMED_ISTORAGE,       // [dpv]
    CF_HTML, 'HTML Source', OLEUIPASTE_PASTE);

  try
    if OleUIPasteSpecial(Data) = OLEUI_OK then begin
      FormatSelected := Data.nSelectedIndex;
      if FormatSelected in [0, 1] then begin
        { CFEmbeddedObject, CFLinkSource }
        FillChar(ReObject, SizeOf(TReObject), 0);
        IRichEditOle(FRichEditOle).GetClientSite(OleClientSite);
        Storage := nil;
        try
          CreateStorage(Storage);
          case Data.nSelectedIndex of
            0: OleCheck(OleCreateFromData(Data.lpSrcDataObj,
               {$IFDEF RX_D3} IOleObject {$ELSE} IID_IOleObject {$ENDIF},
               OLERENDER_DRAW, nil, OleClientSite, Storage, OleObject));
            1: OleCheck(OleCreateLinkFromData(Data.lpSrcDataObj,
               {$IFDEF RX_D3} IOleObject {$ELSE} IID_IOleObject {$ENDIF},
               OLERENDER_DRAW, nil, OleClientSite, Storage, OleObject));
          end;
          try
            with ReObject do begin
              cbStruct := SizeOf(TReObject);
              cp := REO_CP_SELECTION;
              poleobj := OleObject;
              OleObject.GetUserClassID(clsid);
              pstg := Storage;
              polesite := OleClientSite;
              dvAspect := DVASPECT_CONTENT;
              dwFlags := REO_RESIZABLE;
              OleCheck(OleSetDrawAspect(OleObject,
                Data.dwFlags and PSF_CHECKDISPLAYASICON <> 0,
                Data.hMetaPict, dvAspect));
            end;
            SendMessage(Handle, EM_EXGETSEL, 0, LPARAM(@Selection));
            Selection.cpMax := Selection.cpMin + 1;
            OleCheck(IRichEditOle(FRichEditOle).InsertObject(ReObject));
            SendMessage(Handle, EM_EXSETSEL, 0, LPARAM(@Selection));
            IRichEditOle(FRichEditOle).SetDvaspect(
              Longint(REO_IOB_SELECTION), ReObject.dvAspect);
          finally
            ReleaseObject(OleObject);
          end;
        finally
          ReleaseObject(OleClientSite);
          ReleaseObject(Storage);
        end;
      end
      else if FormatSelected = 6 then begin                            // [dpv]
         HTMLText:= GetAsHTML;
         SelText:= HTMLText;
         SelStart := SelStart + Length(HTMLText);
         SelLength:= 0;
      end
      else begin
        if PasteImg or (FormatSelected <> 5)  then begin               // [dpv]
          Format := PasteFormats[FormatSelected].fmtetc.cfFormat;
          OleCheck(IRichEditOle(FRichEditOle).ImportDataObject(
            Data.lpSrcDataObj, Format, Data.hMetaPict));
        end;
      end;
      SendMessage(Handle, EM_SCROLLCARET, 0, 0);
    end;
  finally
    DestroyMetaPict(Data.hMetaPict);
    ReleaseObject(Data.lpSrcDataObj);
    Result:= FormatSelected;
  end;
end;


{ Paste via IRichEditOLE indicating the clipboard format to use
   (if cfFormat=0 => use the best available format)

  IRichEditOle::ImportDataObject(lpdataobj, cf, hMetaPict):  Imports a clipboard object into a
   rich edit control, replacing the current selection.
    cf: Type: CLIPFORMAT
    Clipboard format to use. A value of zero will use the best available format.

  From version 10.0.15063.0 of MSFTEDIT.DLL (Windows 10 version 1703) it doesn't work
  when pasting images. It seems to be necessary to explicitily indicate the format  CF_BITMAP  }
 
function TRxCustomRichEdit.PasteIRichEditOLE(cfFormat: TClipFormat): Boolean;
var
  lpSrcDataObj: IDataObject;
begin
  Result:= False;
  if not CanPaste or not Assigned(FRichEditOle) then Exit;

  try
    if cfFormat = 0 then begin
      if Clipboard.HasFormat(CF_BITMAP) then
         cfFormat:= CF_BITMAP;
    end;

    if OleGetClipboard(lpSrcDataObj) = S_OK then begin
       OleCheck(IRichEditOle(FRichEditOle).ImportDataObject(
               lpSrcDataObj, cfFormat, 0));
       SendMessage(Handle, EM_SCROLLCARET, 0, 0);
       Result:= True;
       end;

  finally
     ReleaseObject(lpSrcDataObj);
  end;
end;

function TRxCustomRichEdit.InsertObjectDialog: Boolean;
var
  Data: TOleUIInsertObject;
  //NameBuffer: array[0..255] of Char;     // [dpv]
  Name: string;                            // [dpv]
  OleClientSite: IOleClientSite;
  Storage: IStorage;
  OleObject: IOleObject;
  ReObject: TReObject;
  IsNewObject: Boolean;
  Selection: TCharRange;
begin
  FillChar(Data, SizeOf(Data), 0);
  //FillChar(NameBuffer, SizeOf(NameBuffer), 0);   // [dpv]
  SetString(Name, nil, 256);                       // [dpv]  
  FillChar(ReObject, SizeOf(TReObject), 0);
  if Assigned(FRichEditOle) then begin
    IRichEditOle(FRichEditOle).GetClientSite(OleClientSite);
    Storage := nil;
    try
      CreateStorage(Storage);
      with Data do begin
        cbStruct := SizeOf(Data);
        dwFlags := IOF_SELECTCREATENEW or IOF_VERIFYSERVERSEXIST or
          IOF_CREATENEWOBJECT or IOF_CREATEFILEOBJECT or IOF_CREATELINKOBJECT;
        hWndOwner := Handle;
        //lpszFile := NameBuffer;         // [dpv]   (--> Error: Result= 125: OLEUI_IOERR_CCHFILEINVALID )
        //cchFile := SizeOf(NameBuffer);  // [dpv]
        lpszFile := PChar(Name);          // [dpv]
        cchFile := Length(Name);          // [dpv]
        iid := {$IFDEF RX_D3} IOleObject {$ELSE} IID_IOleObject {$ENDIF};
        oleRender := OLERENDER_DRAW;
        lpIOleClientSite := OleClientSite;
        lpIStorage := Storage;
        ppvObj := @OleObject;
      end;
      try
        Result := OleUIInsertObject(Data) = OLEUI_OK;
        if Result then
        try
          IsNewObject := Data.dwFlags and IOF_SELECTCREATENEW = IOF_SELECTCREATENEW;
          with ReObject do begin
            cbStruct := SizeOf(TReObject);
            cp := REO_CP_SELECTION;
            clsid := Data.clsid;
            poleobj := OleObject;
            pstg := Storage;
            polesite := OleClientSite;
            dvAspect := DVASPECT_CONTENT;
            dwFlags := REO_RESIZABLE;
            if IsNewObject then dwFlags := dwFlags or REO_BLANK;
            OleCheck(OleSetDrawAspect(OleObject,
              Data.dwFlags and IOF_CHECKDISPLAYASICON <> 0,
              Data.hMetaPict, dvAspect));
          end;
          SendMessage(Handle, EM_EXGETSEL, 0, LPARAM(@Selection));
          Selection.cpMax := Selection.cpMin + 1;
          OleCheck(IRichEditOle(FRichEditOle).InsertObject(ReObject));
          SendMessage(Handle, EM_EXSETSEL, 0, LPARAM(@Selection));
          SendMessage(Handle, EM_SCROLLCARET, 0, 0);
          IRichEditOle(FRichEditOle).SetDvaspect(
            Longint(REO_IOB_SELECTION), ReObject.dvAspect);
          if IsNewObject then OleObject.DoVerb(OLEIVERB_SHOW, nil,
            OleClientSite, 0, Handle, ClientRect);
        finally
          ReleaseObject(OleObject);
        end;
      finally
        DestroyMetaPict(Data.hMetaPict);
      end;
    finally
      ReleaseObject(OleClientSite);
      ReleaseObject(Storage);
    end;
  end
  else Result := False;
end;

function TRxCustomRichEdit.ObjectPropertiesDialog: Boolean;
var
  ObjectProps: TOleUIObjectProps;
  PropSheet: TPropSheetHeader;
  GeneralProps: TOleUIGnrlProps;
  ViewProps: TOleUIViewProps;
  LinkProps: TOleUILinkProps;
  DialogCaption: string;
  ReObject: TReObject;
begin
  Result := False;
  if not Assigned(FRichEditOle) or (SelectionType <> [stObject]) then Exit;
  FillChar(ObjectProps, SizeOf(ObjectProps), 0);
  FillChar(PropSheet, SizeOf(PropSheet), 0);
  FillChar(GeneralProps, SizeOf(GeneralProps), 0);
  FillChar(ViewProps, SizeOf(ViewProps), 0);
  FillChar(LinkProps, SizeOf(LinkProps), 0);
  FillChar(ReObject, SizeOf(ReObject), 0);
  ReObject.cbStruct := SizeOf(ReObject);
  if Succeeded(IRichEditOle(FRichEditOle).GetObject(Longint(REO_IOB_SELECTION),
    ReObject, REO_GETOBJ_POLEOBJ or REO_GETOBJ_POLESITE)) then
  try
    if ReObject.dwFlags and REO_INPLACEACTIVE = 0 then begin
      ObjectProps.cbStruct := SizeOf(ObjectProps);
      ObjectProps.dwFlags := OPF_DISABLECONVERT;
      ObjectProps.lpPS := @PropSheet;
      ObjectProps.lpObjInfo := TOleUIObjInfo.Create(Self, ReObject);
      if (ReObject.dwFlags and REO_LINK) <> 0 then begin
        ObjectProps.dwFlags := ObjectProps.dwFlags or OPF_OBJECTISLINK;
        ObjectProps.lpLinkInfo := TOleUILinkInfo.Create(Self, ReObject);
      end;
      ObjectProps.lpGP := @GeneralProps;
      ObjectProps.lpVP := @ViewProps;
      ObjectProps.lpLP := @LinkProps;
      PropSheet.dwSize := SizeOf(PropSheet);
      PropSheet.hWndParent := Handle;
{$IFDEF RX_D3}
      PropSheet.hInstance := MainInstance;
{$ELSE}
      PropSheet.hInstance := HInstance;
{$ENDIF}
      DialogCaption := Format(ResStr(SPropDlgCaption),
        [GetFullNameStr(ReObject.poleobj)]);
      PropSheet.pszCaption := PChar(DialogCaption);
      GeneralProps.cbStruct := SizeOf(GeneralProps);
      ViewProps.cbStruct := SizeOf(ViewProps);
      ViewProps.dwFlags := VPF_DISABLESCALE;
      LinkProps.cbStruct := SizeOf(LinkProps);
      LinkProps.dwFlags := ELF_DISABLECANCELLINK;
      Result := OleUIObjectProperties(ObjectProps) = OLEUI_OK;
    end;
  finally
{$IFNDEF RX_D3}
    ObjectProps.lpLinkInfo.Free;
    ObjectProps.lpObjInfo.Free;
    ReleaseObject(ReObject.polesite);
    ReleaseObject(ReObject.poleobj);
{$ENDIF}
  end;
end;


function TRxCustomRichEdit.TextLength: integer;             // [dpv] Extracted from .Print and .CreatePrnPrew
var
  TextLenEx: TGetTextLengthEx;
begin
    if RichEditVersion >= 2 then begin
      with TextLenEx do begin
        flags := GTL_DEFAULT;
        codepage := CP_ACP;
      end;
      Result := Perform(EM_GETTEXTLENGTHEX, WParam(@TextLenEx), 0);
    end
    else
      Result := GetTextLen;
end;

procedure TRxCustomRichEdit.PrintPageNumberAndHeader(Canvas: TCanvas;
                                                    PageWidth, PageHeight: integer; PageRect: TRect;
                                                    PageNum: Integer; ShowNumPage: boolean;
                                                    Header: String = '');
var
  Sz: TSize;
  S: string;
  Top: Integer;
begin
    if not ShowNumPage and (Header = '') then exit;

    Canvas.Font.Name := 'Tahoma';
    Canvas.Font.Size := 12;
    Canvas.Font.Color:= clBlack;

    S:= 'Tahoma';
    if header <> '' then
       S:= header;
    Sz:= Canvas.TextExtent(S);

    if ShowNumPage then begin
       Top:= PageHeight - ((PageHeight - (PageRect.Bottom - (Sz.Height-5)) ) div 2);
       Canvas.TextOut(
          PageWidth div 2,
          Top,
          PageNum.ToString
        );
    end;

    if Header <> '' then begin
       Top:= (PageRect.Top - (Sz.Height-5)) div 2;
       if Top < 0 then
          Top:= PageRect.Top;

       Canvas.TextOut(
          PageWidth - (PageWidth - PageRect.Right) - Sz.Width - 5,
          Top,
          Header
        );
    end;
end;



// [dpv]: ShowNumPage, OwnPrintJob, FirstPageMarginTop (pixels), Result(LastPagePrintedHeight) (pixels), Header
function TRxCustomRichEdit.Print(const Caption: string;
                                 ShowNumPage: boolean= true; StartNumPage: boolean= true;
                                 OwnPrintJob: boolean= true; FirstPageMarginTop: integer = -1;
                                 const Header: string = ''): integer;
var
  Range: TFormatRange;
  LastChar, MaxLen, LogX, LogY, OldMap: Integer;
  SaveRect: TRect;
  PWidth, PHeight: Integer;
  //TextLenEx: TGetTextLengthEx;                                  // dpv

  function PixelsToTwips(Pixels, DPI: Integer): Integer;
  begin
    Result := MulDiv(Pixels, 1440, DPI);
  end;

  procedure AddPageNumberAndHeader;
  begin
    PrintPageNumberAndHeader(Printer.Canvas, Printer.PageWidth, Printer.PageHeight, PageRect, PageNum, ShowNumPage, Header);
    inc(PageNum);
  end;

begin
{$IFDEF RX_ENHPRINT}
  percentdone:=0;
{$ENDIF RX_ENHPRINT}
  FillChar(Range, SizeOf(TFormatRange), 0);
  with Printer, Range do begin
    Title := Caption;
    if OwnPrintJob then
       BeginDoc;
    hdc := Handle;
    hdcTarget := hdc;
    LogX := GetDeviceCaps(Handle, LOGPIXELSX);
    LogY := GetDeviceCaps(Handle, LOGPIXELSY);

    PWidth:=  PixelsToTwips(PageWidth, LogX);
    PHeight:= PixelsToTwips(PageHeight, LogY);

    if IsRectEmpty(PageRect) then begin
      rc.right := PWidth;
      rc.bottom := PHeight;
    end
    else begin
      rc.left :=   PixelsToTwips(PageRect.Left, LogX);
      rc.top :=    PixelsToTwips(PageRect.Top, LogY);
      rc.right :=  PixelsToTwips(PageRect.Right, LogX);
      rc.bottom := PixelsToTwips(PageRect.Bottom, LogY);
    end;
    rcPage := Rect(0, 0, PWidth, PHeight);
    SaveRect := rc;
    LastChar := 0;
  	MaxLen:= TextLength;                                           // [dpv]
    if StartNumPage then
       PageNum:= 1;
  {                                                                // [dpv]
    if RichEditVersion >= 2 then begin
      with TextLenEx do begin
        flags := GTL_DEFAULT;
        codepage := CP_ACP;
      end;
      MaxLen := Perform(EM_GETTEXTLENGTHEX, WParam(@TextLenEx), 0);
    end
    else MaxLen := GetTextLen;
	}
    chrg.cpMax := -1;
    { ensure printer DC is in text map mode }
    OldMap := SetMapMode(hdc, MM_TEXT);
    SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);    { flush buffer }
    try
      if FirstPageMarginTop >= 0 then
         rc.Top:= PixelsToTwips(FirstPageMarginTop, LogY)
      else
         AddPageNumberAndHeader;

      repeat
        chrg.cpMin := LastChar;
        LastChar := SendMessage(Self.Handle, EM_FORMATRANGE, 1, LPARAM(@Range));
        if (LastChar < MaxLen) and (LastChar <> -1) then begin
           NewPage;
           AddPageNumberAndHeader;
        end
        else
           Result:= MulDiv(Range.rc.Bottom, LogY, 1440);    // [dpv] Current printed height  (Twips -> Pixels)

        rc:= SaveRect;

      {$IFDEF RX_ENHPRINT}
        percentdone:=round(100*(LastChar/MaxLen));
      {$ENDIF RX_ENHPRINT}
      until (LastChar >= MaxLen) or (LastChar = -1);
      if OwnPrintJob then
         EndDoc;
    finally
      SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);  { flush buffer }
      SetMapMode(hdc, OldMap);       { restore previous map mode }
    end;
  end;
end;

(*  [dpv]
{$IFDEF RX_ENHPRINT}
procedure TRxCustomRichEdit.CreatePrnPrew(const Caption: string);
var
  Range: TFormatRange;
  LastChar, MaxLen, LogX, LogY, OldMap: Integer;
  SaveRect: TRect;
  //TextLenEx: TGetTextLengthEx;                                   // [dpv]
  MetaCanvas:TmetafileCanvas;
begin
//  if prnpreview<>nil then prnpreview.free;
  PrnPreviews.clear;
  prnpreview:=tmetafile.create;
  prnpreview.width:=pagerect.right-pagerect.left;
  prnpreview.height:=pagerect.bottom-pagerect.top;
  MetaCanvas:=TmetafileCanvas.create(prnpreview,0);
  percentdone:=0;
  FillChar(Range, SizeOf(TFormatRange), 0);
  with Printer, Range do begin
    Title := Caption;
    hdcTarget := hdc;
    hdc := metacanvas.Handle;
    LogX := GetDeviceCaps(Handle, LOGPIXELSX);
    LogY := GetDeviceCaps(Handle, LOGPIXELSY);
    if IsRectEmpty(PageRect) then begin
      rc.right := PageWidth * 1440 div LogX;
      rc.bottom := PageHeight * 1440 div LogY;
    end
    else begin
      rc.left := PageRect.Left * 1440 div LogX;
      rc.top := PageRect.Top * 1440 div LogY;
      rc.right := PageRect.Right * 1440 div LogX;
      rc.bottom := PageRect.Bottom * 1440 div LogY;
    end;
    rcPage := rc;
    SaveRect := rc;
    LastChar := 0;
	MaxLen:= TextLength;                                             // [dpv]
	{                                                                // [dpv]
    if RichEditVersion >= 2 then begin
      with TextLenEx do begin
        flags := GTL_DEFAULT;
        codepage := CP_ACP;
      end;
      MaxLen := Perform(EM_GETTEXTLENGTHEX, WParam(@TextLenEx), 0);
    end
    else MaxLen := GetTextLen;
	}
    chrg.cpMax := -1;
    { ensure printer DC is in text map mode }
    OldMap := SetMapMode(hdc, MM_TEXT);
    SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);    { flush buffer }
    try
      while (LastChar < MaxLen) and (LastChar <> -1) do
      begin
        rc := SaveRect;
        chrg.cpMin := LastChar;
        LastChar := SendMessage(Self.Handle, EM_FORMATRANGE, 1, LPARAM(@Range));
        if (LastChar < MaxLen) and (LastChar <> -1) then
        begin
          MetaCanvas.Free;
          PrnPreviews.Add(prnpreview);
          prnpreview := tmetafile.Create;
          prnpreview.Width := PageRect.Right-PageRect.Left;
          prnpreview.Height := pagerect.Bottom-PageRect.Top;
          MetaCanvas:=TmetafileCanvas.Create(prnpreview,0);
          MetaCanvas.Brush.Color:=clWindow;
          hdc := MetaCanvas.Handle;
        end;
        PercentDone:=round(100*(LastChar/MaxLen));
      end;
      MetaCanvas.Free;
      PrnPreviews.Add(prnpreview);
    finally
      SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);  { flush buffer }
      SetMapMode(hdc, OldMap);       { restore previous map mode }
    end;
  end;
end;
{$ENDIF RX_ENHPRINT}
*)


{ *1
Difference between hdc and hdcTarget
- hdc (Current Rendering Device Handle):
  This is the device context (HDC) where the text is currently being drawn.
  In the case of preview, this should be the context of the canvas you are drawing on (e.g. the TMetafileCanvas.Handle
   or the context of a TCanvas).
- hdcTarget (Format Target Device Handle):
  This is the context of the final target device, i.e. the place for which you are formatting the text.
  When you preview for a printer, hdcTarget should be the printer's HDC (Printer.Handle in Delphi).
  Windows uses hdcTarget to calculate precise metrics such as:
   Text size and kerning.
   Line spacing.
   Font scaling based on the capabilities of the output device (in this case, the printer).
   This ensures that the text is formatted taking into account the printer's characteristics, but drawn in the hdc
   corresponding to the preview.

 https://learn.microsoft.com/en-us/windows/win32/api/richedit/ns-richedit-formatrange
 https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-getdevicecaps
}

{$IFDEF RX_ENHPRINT}                                                                // [dpv]
function TRxCustomRichEdit.CreatePrnPrew(const Caption: string;
                                         ShowNumPage: boolean= true;
                                         FirstPageMarginTop: integer = -1;
                                         ScreenDPI: Integer= 96;
                                         const Header: string = ''): Integer;
var
  Range: TFormatRange;
  LastChar, MaxLen, DPI, OldMap: Integer;
  SaveRect, FullPageRect: TRect;
  MetaCanvas: TMetafileCanvas;
  PWidth, PHeight: Integer;
  hdcMetacanvas: HDC;

  function GetNewPageHDC (First: boolean): HDC;
  begin
    prnpreview:= TMetaFile.create;
    prnpreview.width  := PWidth;
    prnpreview.height := PHeight;
    MetaCanvas:=TmetafileCanvas.create(prnpreview,0);
    MetaCanvas.Brush.Color:= clWindow;
    MetaCanvas.FillRect(FullPageRect);

    if ShowNumPage or (Header <> '') then
       PrintPageNumberAndHeader(MetaCanvas, PWidth, PHeight, PageRect, PrnPreviews.Count + 1, ShowNumPage, Header);

    if First and (FirstPageMarginTop <> -1) and (PrnPreviews.Count > 0) then begin
       MetaCanvas.Draw(0, 0, PrnPreviews[PrnPreviews.Count-1]);
       PrnPreviews.Remove(PrnPreviews[PrnPreviews.Count-1]);
    end;
    Result:= MetaCanvas.Handle;
  end;

begin
  // PrnPreviews.clear;

  percentdone:=0;
  FillChar(Range, SizeOf(TFormatRange), 0);
  with Printer, Range do begin
    Title := Caption;

    DPI := ScreenDPI;
    PWidth  := MulDiv(PageWidth,  DPI, GetDeviceCaps(Handle, LOGPIXELSX));
    PHeight := MulDiv(PageHeight, DPI, GetDeviceCaps(Handle, LOGPIXELSY));

    FullPageRect.Top:= 0;
    FullPageRect.Left:= 0;
    FullPageRect.Right := PWidth;
    FullPageRect.Bottom:= PHeight;

    if IsRectEmpty(PageRect) then begin
      rc.right  := PageWidth  * 1440 div DPI;
      rc.bottom := PageHeight * 1440 div DPI;
    end
    else begin
      rc.left   := PageRect.Left   * 1440 div DPI;
      rc.top    := PageRect.Top    * 1440 div DPI;
      rc.right  := PageRect.Right  * 1440 div DPI;
      rc.bottom := PageRect.Bottom * 1440 div DPI;
    end;
    rcPage := FullPageRect;
    SaveRect := rc;
    hdcTarget := Printer.Handle;        //*1
    hdc:= GetNewPageHDC(true);
    LastChar := 0;
  	MaxLen:= TextLength;
    chrg.cpMax := -1;

    // ensure printer DC is in text map mode
    OldMap := SetMapMode(hdc, MM_TEXT);
    SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);    // flush buffer
    try
      if FirstPageMarginTop >= 0 then
         rc.Top:= FirstPageMarginTop * 1440 div DPI;

      while (LastChar < MaxLen) and (LastChar <> -1) do begin
        chrg.cpMin := LastChar;
        LastChar := SendMessage(Self.Handle, EM_FORMATRANGE, 1, LPARAM(@Range));
        if (LastChar < MaxLen) and (LastChar <> -1) then begin
          MetaCanvas.Free;
          PrnPreviews.Add(prnpreview);
          hdc:= GetNewPageHDC(false);
        end
        else
           Result:= MulDiv(Range.rc.Bottom, DPI, 1440);    // [dpv] Current printed height  (Twips -> Pixels)
        PercentDone:=round(100*(LastChar/MaxLen));
        rc := SaveRect;
      end;
      MetaCanvas.Free;
      PrnPreviews.Add(prnpreview);
    finally
      SendMessage(Self.Handle, EM_FORMATRANGE, 0, 0);  // flush buffer
      SetMapMode(hdc, OldMap);                         // restore previous map mode
    end;
  end;
end;
{$ENDIF RX_ENHPRINT}



var
  Painting: Boolean = False;

procedure TRxCustomRichEdit.WMPaint(var Message: TWMPaint);
var
  R, R1: TRect;
{$IFDEF RX_ENHPRINT}
  I:integer;
  lf,rg:tpoint;
  a:array[0..1] of tpoint;
  min,max:integer;
  //pen:hpen;
  logx:Integer;
  //pagepos:integer;
{$ENDIF RX_ENHPRINT}
begin
  if RichEditVersion >= 2 then
    inherited
  else begin
    if GetUpdateRect(Handle, R, True) then
    begin
      with ClientRect do R1 := Rect(Right - 3, Top, Right, Bottom);
      if IntersectRect(R, R, R1) then InvalidateRect(Handle, @R1, True);
    end;
    if Painting then
      Invalidate
    else begin
      Painting := True;
      try
        inherited;
      finally
        Painting := False;
      end;
    end;
  end;
{$IFDEF RX_ENHPRINT}
  if fDrawEndPage then
  begin
    LogX := GetDeviceCaps(printer.Handle, LOGPIXELSX);
    //logx*screen.pixelsperinch
    lf.x:=ClientRect.Left;
    rg.x:=ClientRect.Right;
    getScrollRange(handle,SB_Vert,min,max);
    for i:=1 to Round((max-min)*2 / (PageRect.Bottom/logx*Screen.PixelsPerInch-PageRect.Top/logx*Screen.PixelsPerInch)) do
    begin
      lf.y:=Round(i*(PageRect.Bottom/logx*Screen.PixelsPerInch-PageRect.Top/logx*Screen.PixelsPerInch)-(GetScrollPos(handle,SB_Vert)));
      rg.y:=lf.y;
      a[0]:=lf;a[1]:=rg;
      if PolyLine(getWindowDC(handle),a,2) then
        {pagepos:=lf.y}; {save Y for future use}
    end;
  end;
{$ENDIF RX_ENHPRINT}
end;

procedure TRxCustomRichEdit.WMDestroy(var Msg: TWMDestroy);
begin
  CloseObjects;
  ReleaseObject(FRichEditOle);
  inherited;
end;

procedure TRxCustomRichEdit.WMMouseMove(var Message: TMessage);
begin
  inherited;
end;

procedure TRxCustomRichEdit.WMSetCursor(var Message: TWMSetCursor);
begin
  inherited;
end;

{$IFDEF RX_D5}
procedure TRxCustomRichEdit.WMRButtonUp(var Message: TMessage);
begin
  { RichEd20 does not pass the WM_RBUTTONUP message to defwndproc, }
  { so we get no WM_CONTEXTMENU message. Simulate message here.    }
  //if Win32MajorVersion < 5 then //bug on W2K, no popup invoked
    Perform(WM_CONTEXTMENU, Handle, LParam(Cardinal(PointToSmallPoint(
      ClientToScreen(SmallPointToPoint(TWMMouse(Message).Pos))))));
  inherited;
end;
{$ENDIF}

{$IFDEF RX_ENH}
function  TRxCustomRichEdit.GetRtfSelText: String;
var
  SS: TStringStream;
  bsmSelection: Boolean;
Begin
  bsmSelection:=smSelection in StreamMode;
  StreamMode:=StreamMode+[smSelection];
  SS:=TStringStream.Create('');
  try
    Lines.SaveToStream(SS);
    Result:=SS.DataString;
  finally
    SS.FREE;
    if NOT bsmSelection then
      StreamMode:=StreamMode-[smSelection];
  end;
End;//GetRtfSelText

procedure TRxCustomRichEdit.SetRtfSelText(const sRtf: String);
var
  SS: TStringStream;
  bsmSelection: Boolean;
Begin
  bsmSelection:=smSelection in StreamMode;
  StreamMode:=StreamMode+[smSelection];
  SS:=TStringStream.Create(sRtf);
  try
    Lines.LoadFromStream(SS);
  finally
    SS.FREE;
    if NOT bsmSelection then
      StreamMode:=StreamMode-[smSelection];
  end;
End;//SetRtfSelText


function  TRxCustomRichEdit.GetRtfText: AnsiString;
var
  StreamModeBak: TRichStreamModes;
  MS: TMemoryStream;

Begin
  StreamModeBak:= StreamMode;
  StreamMode:=StreamMode - [smSelection];

  MS:=TMemoryStream.Create;
  try
    Lines.SaveToStream(MS);
    SetString(Result, PAnsiChar(MS.Memory), MS.Size);

  finally
    MS.Free;
    StreamMode:= StreamModeBak;
  end;
End;


procedure TRxCustomRichEdit.SetRtfText(const sRtf: AnsiString);
var
  MS: TMemoryStream;
  StreamModeBak: TRichStreamModes;
Begin
  StreamModeBak:= StreamMode;
  StreamMode:= StreamMode - [smSelection];

  MS:=TMemoryStream.Create;
  try
    MS.Write(sRtf[1], ByteLength(sRtf));
    MS.Position:= 0;
    Lines.LoadFromStream(MS);
  finally
    MS.FREE;
    StreamMode:= StreamModeBak;
  end;	 
End;


procedure TRxCustomRichEdit.AddText(const Str: String);
Begin
  SelText:= Str;
  SelStart:= SelStart + Length(Str);
End;

{$ENDIF}

procedure TRxCustomRichEdit.CNNotify(var Message: TWMNotify);
var
  AMsg: TMessage;
begin
  with Message do
    case NMHdr^.code of
      EN_SELCHANGE: SelectionChange;
      EN_REQUESTRESIZE: RequestSize(PReqSize(NMHdr)^.rc);
      EN_SAVECLIPBOARD:
        with PENSaveClipboard(NMHdr)^ do
          if not SaveClipboard(cObjectCount, cch) then Result := 1;
      EN_PROTECTED:
        with PENProtected(NMHdr)^ do begin
          AMsg.Msg := Msg;
          AMsg.WParam := WParam;
          AMsg.LParam := LParam;
          AMsg.Result := 0;
          if not ProtectChange(AMsg, chrg.cpMin, chrg.cpMax) then
            Result := 1;
        end;
      EN_LINK:
        with PENLink(NMHdr)^ do begin
          case Msg of
            WM_RBUTTONDOWN:
              begin
                FClickRange := chrg;
                FClickBtn := mbRight;
                SelStart:= chrg.cpMin;
              end;
            WM_RBUTTONUP:
              begin
                if (FClickBtn = mbRight) and (FClickRange.cpMin = chrg.cpMin) and
                  (FClickRange.cpMax = chrg.cpMax) then
                  URLClick(GetTextRange(chrg.cpMin, chrg.cpMax), mbRight);
                with FClickRange do begin
                  cpMin := -1;
                  cpMax := -1;
                end;
              end;
            WM_LBUTTONDOWN:
              begin
                FClickRange := chrg;
                FClickBtn := mbLeft;
              end;
            WM_LBUTTONUP:
              begin
                if (FClickBtn = mbLeft) and (FClickRange.cpMin = chrg.cpMin) and
                  (FClickRange.cpMax = chrg.cpMax) then
                  URLClick(GetTextRange(chrg.cpMin, chrg.cpMax), mbLeft);
                with FClickRange do begin
                  cpMin := -1;
                  cpMax := -1;
                end;
              end;
            WM_SETCURSOR:
              begin
                FClickRange := chrg;
                URLMouseMove(WParam);
              end;
          end;
        end;
      EN_STOPNOUNDO:
        begin
          { cannot allocate enough memory to maintain the undo state }
        end;
      { See comment *3
      EN_DROPFILES:
        begin
          FileDropped (ENDDROPFILES(NMHdr)^);
        end;
       }
    end;
end;

function TRxCustomRichEdit.SaveClipboard(NumObj, NumChars: Integer): Boolean;
begin
  Result := True;
  if Assigned(OnSaveClipboard) then
    OnSaveClipboard(Self, NumObj, NumChars, Result);
end;

function TRxCustomRichEdit.ProtectChange(const Message: TMessage; StartPos,
  EndPos: Integer): Boolean;
begin
  Result := False;
  if Assigned(OnProtectChangeEx) then
    OnProtectChangeEx(Self, Message, StartPos, EndPos, Result)
  else if Assigned(OnProtectChange) then
    OnProtectChange(Self, StartPos, EndPos, Result);
end;

procedure TRxCustomRichEdit.SelectionChange;
begin
  if Assigned(OnSelectionChange) then OnSelectionChange(Self);
end;

procedure TRxCustomRichEdit.RequestSize(const Rect: TRect);
begin
  if Assigned(OnResizeRequest) then OnResizeRequest(Self, Rect);
end;

procedure TRxCustomRichEdit.URLClick(const URLText: string; Button: TMouseButton);
begin
  if Assigned(OnURLClick) then OnURLClick(Self, URLText, Button);
end;

procedure TRxCustomRichEdit.URLMouseMove(WParam: WPARAM);           // [dpv]
begin
  if Assigned(OnURLMouseMove) then OnURLMouseMove(Self, WParam);
end;


{
procedure TRxCustomRichEdit.FileDropped(EndDropFiles: TEndDropFiles);     //  [dpv]  See comment *3
var
  FileList: TStringList;
begin
  SelText:= '';
  if not assigned( OnFileDropped ) then exit;

  FileList := GetDropFiles(EndDropFiles.hDrop);
  try
    OnFileDropped( self, FileList );

  finally
    FileList.Free;
  end;

end;
}

procedure TRxCustomRichEdit.WMDropFiles(var Msg: TWMDropFiles);            //  [dpv]  See comment *3
var
  FileList : TStringList;
begin
  if not assigned( OnFileDropped ) then exit;

  FileList := GetDropFiles(Msg.Drop);
  try
    OnFileDropped( self, FileList );

  finally
    FileList.Free;
  end;

  // If wanted the EN_DROPFILES notification to be received we should let the default handler run (but this is not the case)
  //inherited;
end; // WMDropFiles




function TRxCustomRichEdit.FindText(const SearchStr: string;
  StartPos, Length: Integer; Options: TRichSearchTypes): Integer;
var
  Find: TFindTextEx;
  Flags: Integer;
begin
{                                                                           // [dpv]
  with Find.chrg do begin
     cpMin := StartPos;
     cpMax := cpMin + Abs(Length);
   end;
}

{ https://learn.microsoft.com/en-us/windows/win32/controls/em-findtextex        [dpv]
  The cpMin member of FINDTEXTEX.chrg always specifies the starting-point of
  the search, and cpMax specifies the end point. When searching backward,
  cpMin must be equal to or greater than cpMax. When searching forward, a
  value of -1 in cpMax extends the search range to the end of the text.  }

  if Length <= 0 then Length:= -1;                                            // [dpv]

  with Find.chrg do begin                                                     // [dpv]
    cpMin := StartPos;
    if stBackward in Options then begin
       cpMax:= 0;
       if Length > 0 then  cpMax := cpMin - Length
    end
    else begin
       cpMax:= -1;
       if Length > 0 then  cpMax := cpMin + Length;
    end;
  end;

  if RichEditVersion >= 2 then begin
    if not (stBackward in Options) then Flags := FT_DOWN
    else Flags := 0;
  end
  else begin
    Options := Options - [stBackward];
    Flags := 0;
  end;
  if stWholeWord in Options then Flags := Flags or {$IFNDEF RX_D12}FT_WHOLEWORD{$ELSE}Winapi.CommDlg.FR_WHOLEWORD{$ENDIF};
  if stMatchCase in Options then Flags := Flags or {$IFNDEF RX_D12}FT_MATCHCASE{$ELSE}Winapi.CommDlg.FR_MATCHCASE{$ENDIF};

{$IFDEF RX_D12}                                                                 // [dpv]
  Find.lpstrText := PChar(SearchStr);
{$ELSE}
  Find.lpstrText := PAnsiChar(SearchStr);
{$ENDIF}

  Result := SendMessage(Handle, EM_FINDTEXTEX, Flags, LPARAM(@Find));       // [dpv] -> EM_FINDTEXTEX or EM_FINDTEXTEXW
  if (Result >= 0) and (stSetSelection in Options) then begin
    SendMessage(Handle, EM_EXSETSEL, 0, LPARAM(@Find.chrgText));
    SendMessage(Handle, EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TRxCustomRichEdit.ClearUndo;
begin
  SendMessage(Handle, EM_EMPTYUNDOBUFFER, 0, 0);
end;

procedure TRxCustomRichEdit.Redo;
begin
  SendMessage(Handle, EM_REDO, 0, 0);
end;

{$IFNDEF RX_V110}
procedure TRxCustomRichEdit.Undo;
begin
  SendMessage(Handle, WM_UNDO, 0, 0);
end;
{$ENDIF}

procedure TRxCustomRichEdit.StopGroupTyping;
begin
  if (RichEditVersion >= 2) and HandleAllocated then
    SendMessage(Handle, EM_STOPGROUPTYPING, 0, 0);
end;

{ Maintains performance while updating.
 It is recommended to call this method before doing any major updates that we don't wish the user to
 see. Remember to call EndUpdate when you are finished with the update. Nested calls are supported.
 Calling this method will prevent redrawing. It will also setup the event mask of the underlying richedit
 control so that no events are sent. }
 
procedure TRxCustomRichEdit.BeginUpdate;
begin
    FUpdating:= FUpdating + 1;                                         // Deal with nested calls
    if FUpdating <= 1 then begin
        FOldEventMask := SendMessage(Handle, EM_SETEVENTMASK, 0, 0);   // Prevent the control from raising any events
        SendMessage(Handle, WM_SETREDRAW, 0, 0);                       // Prevent the control from redrawing itself
    End;
end;


{ Resumes drawing and event handling.
  This method should be called every time a call is made made to BeginUpdate. It resets the event mask to it's
  original value and enables redrawing of the control.}

procedure TRxCustomRichEdit.EndUpdate (InvalidateAndRefresh: boolean= true);
begin
    FUpdating:= FUpdating -1;                                        // Deal with nested calls
    if FUpdating <= 0 then begin
        SendMessage(Handle, WM_SETREDRAW, 1, 0);                     // Allow the control to redraw itself
        SendMessage(Handle, EM_SETEVENTMASK, 0, FOldEventMask);      // Allow the control to raise event messages
        if InvalidateAndRefresh then begin
           Invalidate;
           Refresh;
        end;
    end;
end;


procedure TRxCustomRichEdit.RemoveMargins;                          // [dpv]
var
   Rect: TRect;
begin
   SendMessage(Handle, EM_GETRECT, 0, LPARAM(@Rect));
   Rect.Left:= 0;
   Rect.Top:= 0;
   Rect.Right:= 0;
   Rect.Bottom:= 0;
   SendMessage(Handle, EM_SETRECT, 0, LPARAM(@Rect));
end;


{$IFDEF RX_D3}
procedure TRxCustomRichEdit.SetUIActive(Active: Boolean);
var
  Form: TCustomForm;
begin
  try
    Form := GetParentForm(Self);
    if Form <> nil then
      if Active then begin
        if (Form.ActiveOleControl <> nil) and
          (Form.ActiveOleControl <> Self) then
          Form.ActiveOleControl.Perform(CM_UIDEACTIVATE, 0, 0);
        Form.ActiveOleControl := Self;
        if AllowInPlace and CanFocus then SetFocus;
      end
      else begin
        if Form.ActiveOleControl = Self then Form.ActiveOleControl := nil;
        if (Form.ActiveControl = Self) and AllowInPlace then begin
          Windows.SetFocus(Handle);
          SelectionChange;
        end;
      end;
  except
    Application.HandleException(Self);
  end;
end;

procedure TRxCustomRichEdit.CMDocWindowActivate(var Message: TMessage);
begin
  if Assigned(FCallback) then
    with TRichEditOleCallback(FCallback) do
      if Assigned(FDocForm) and IsFormMDIChild(FDocForm.Form) then begin
        if Message.WParam = 0 then begin
          FFrameForm.SetMenu(0, 0, 0);
          FFrameForm.ClearBorderSpace;
        end;
      end;
end;

procedure TRxCustomRichEdit.CMUIDeactivate(var Message: TMessage);
begin
  if (GetParentForm(Self) <> nil) and Assigned(FRichEditOle) and
    (GetParentForm(Self).ActiveOleControl = Self) then
    {IRichEditOle(FRichEditOle).InPlaceDeactivate};
end;
{$ENDIF RX_D3}

{ Find & Replace Dialogs }

procedure TRxCustomRichEdit.SetupFindDialog(Dialog: TFindDialog;
  const SearchStr, ReplaceStr: string);
begin
  with Dialog do begin
    if SearchStr <> '' then FindText := SearchStr;
    if RichEditVersion = 1 then
      Options := Options + [frHideUpDown, frDown];
    OnFind := FindDialogFind;
{$IFDEF RX_D3}
    OnClose := FindDialogClose;
{$ENDIF}
  end;
  if Dialog is TReplaceDialog then
    with TReplaceDialog(Dialog) do begin
      if ReplaceStr <> '' then ReplaceText := ReplaceStr;
      OnReplace := ReplaceDialogReplace;
    end;
end;

function TRxCustomRichEdit.FindDialog(const SearchStr: string): TFindDialog;
begin
  if FFindDialog = nil then begin
    FFindDialog := TFindDialog.Create(Self);
    if FReplaceDialog <> nil then
      FFindDialog.FindText := FReplaceDialog.FindText;
  end;
  Result := FFindDialog;
  SetupFindDialog(FFindDialog, SearchStr, '');
  FFindDialog.Execute;
end;

function TRxCustomRichEdit.ReplaceDialog(const SearchStr,
  ReplaceStr: string): TReplaceDialog;
begin
  if FReplaceDialog = nil then begin
    FReplaceDialog := TReplaceDialog.Create(Self);
    if FFindDialog <> nil then
      FReplaceDialog.FindText := FFindDialog.FindText;
  end;
  Result := FReplaceDialog;
  SetupFindDialog(FReplaceDialog, SearchStr, ReplaceStr);
  FReplaceDialog.Execute;
end;

function TRxCustomRichEdit.GetCanFindNext: Boolean;
begin
  Result := HandleAllocated and (FLastFind <> nil) and
    (FLastFind.FindText <> '');
end;

function TRxCustomRichEdit.FindNext: Boolean;
begin
  if CanFindNext then Result := FindEditText(FLastFind, False, True)
  else Result := False;
end;

procedure TRxCustomRichEdit.AdjustFindDialogPosition(Dialog: TFindDialog);
var
  TextRect, R: TRect;
begin
  if Dialog.Handle = 0 then Exit;
  with TextRect do begin
    TopLeft := ClientToScreen(GetCharPos(SelStart));
    BottomRight := ClientToScreen(GetCharPos(SelStart + SelLength));
    Inc(Bottom, 20);
  end;
  with Dialog do begin
    GetWindowRect(Handle, R);
    if PtInRect(R, TextRect.TopLeft) or PtInRect(R, TextRect.BottomRight) then
    begin
      if TextRect.Top > R.Bottom - R.Top + 20 then
        OffsetRect(R, 0, TextRect.Top - R.Bottom - 20)
      else begin
        if TextRect.Top + R.Bottom - R.Top < GetSystemMetrics(SM_CYSCREEN) then
          OffsetRect(R, 0, 40 + TextRect.Top - R.Top);
      end;
      Position := R.TopLeft;
    end;
  end;
end;

function TRxCustomRichEdit.FindEditText(Dialog: TFindDialog; AdjustPos, Events: Boolean): Boolean;
var
  Length, StartPos: Integer;
  SrchOptions: TRichSearchTypes;
begin
  with TFindDialog(Dialog) do begin
    SrchOptions := [stSetSelection];
    if frDown in Options then begin
      StartPos := Max(SelStart, SelStart + SelLength);
      Length := System.Length(Text) - StartPos + 1;
    end
    else begin
      SrchOptions := SrchOptions + [stBackward];
      StartPos := Min(SelStart, SelStart + SelLength);
      Length := StartPos + 1;
    end;
    if frMatchCase in Options then
      SrchOptions := SrchOptions + [stMatchCase];
    if frWholeWord in Options then
      SrchOptions := SrchOptions + [stWholeWord];
    Result := Self.FindText(FindText, StartPos, Length, SrchOptions) >= 0;
    if FindText <> '' then FLastFind := Dialog;
    if Result then begin
      if AdjustPos then AdjustFindDialogPosition(Dialog);
    end
    else if Events then TextNotFound(Dialog);
  end;
end;

procedure TRxCustomRichEdit.TextNotFound(Dialog: TFindDialog);
begin
  with Dialog do
    if Assigned(FOnTextNotFound) then FOnTextNotFound(Self, FindText);
end;

procedure TRxCustomRichEdit.FindDialogFind(Sender: TObject);
begin
  FindEditText(TFindDialog(Sender), True, True);
end;

procedure TRxCustomRichEdit.ReplaceDialogReplace(Sender: TObject);
var
  Cnt: Integer;
  SaveSelChange: TNotifyEvent;
begin
  with TReplaceDialog(Sender) do begin
    if (frReplaceAll in Options) then begin
      Cnt := 0;
      SaveSelChange := FOnSelChange;
      TRichEditStrings(Lines).EnableChange(False);
      try
        FOnSelChange := nil;
        while FindEditText(TFindDialog(Sender), False, False) do begin
          SelText := ReplaceText;
          Inc(Cnt);
        end;
        if Cnt = 0 then TextNotFound(TFindDialog(Sender))
        else AdjustFindDialogPosition(TFindDialog(Sender));
      finally
        TRichEditStrings(Lines).EnableChange(True);
        FOnSelChange := SaveSelChange;
        if Cnt > 0 then begin
          Change;
          SelectionChange;
        end;
      end;
    end
    else if (frReplace in Options) then begin
      if FindEditText(TFindDialog(Sender), True, True) then
        SelText := ReplaceText;
    end;
  end;
end;

{$IFDEF RX_D3}
procedure TRxCustomRichEdit.FindDialogClose(Sender: TObject);
begin
  CloseFindDialog(Sender as TFindDialog);
end;

procedure TRxCustomRichEdit.CloseFindDialog(Dialog: TFindDialog);
begin
  if Assigned(FOnCloseFindDialog) then FOnCloseFindDialog(Self, Dialog);
end;
{$ENDIF RX_D3}

{ Conversion formats }

procedure AppendConversionFormat(const Ext: string; Plain: Boolean;
  AClass: TConversionClass);
var
  NewRec: PRichConversionFormat;
begin
  New(NewRec);
  with NewRec^ do begin
{$IFNDEF VER90}
    Extension := {$IFDEF RX_D15}AnsiLowerCase{$ELSE}AnsiLowerCaseFileName{$ENDIF}(Ext);
{$ELSE}
    Extension := LowerCase(Ext);
{$ENDIF}
    PlainText := Plain;
    ConversionClass := AClass;
    Next := ConversionFormatList;
  end;
  ConversionFormatList := NewRec;
end;

class procedure TRxCustomRichEdit.RegisterConversionFormat(const AExtension: string;
  APlainText: Boolean; AConversionClass: TConversionClass);
begin
  AppendConversionFormat(AExtension, APlainText, AConversionClass);
end;

{ Initialization part }

var
  OldError: Longint;
  FLibHandle: THandle;
  Ver: TOsVersionInfo;


{$IFDEF RX_SELECTDLL}                                                   // [dpv]

procedure GetDLLProductVersion (out sModulePath: string;
                                out DLLProductVersion: Single;
                                out RichEditVersion: TRichEditVersion);
var
  ModuleHandle: HMODULE;
  ModulePath : array[0..MAX_PATH] of char;
  dummy : DWORD;
  size : integer;
  buffer : PChar;
  vsInfo : PVSFixedFileInfo;
  vsInfoSize : UINT;
  FileVersionMinor, FileVersionMajor : integer;
  nameDLL: string;
begin
  ModuleHandle := FLibHandle;

  if ( GetModuleFileName( ModuleHandle, ModulePath, MAX_PATH ) = 0 ) then exit; // function failed

  size := GetFileVersionInfosize( ModulePath, dummy );
  if ( size = 0 ) then exit; // function failed

  GetMem( buffer, size );
  try
    if ( not GetFileVersionInfo( ModulePath, 0, size, buffer )) then exit;

    if ( not VerQueryValue(buffer, '\', pointer( vsInfo ), vsInfoSize )) then exit;

    FileVersionMinor := loword( vsInfo^.dwFileVersionMS );
    FileVersionMajor := hiword( vsInfo^.dwFileVersionMS );

    sModulePath:= ModulePath;
    nameDLL := UpperCase(ExtractFileName(sModulePath));

    DLLProductVersion:= 1.0;

    if nameDLL = 'RICHED32.DLL' then
          DLLProductVersion:= 1.0

    else if nameDLL = 'RICHED20.DLL' then
           case FileVersionMinor of
              30,31,40,50:   DLLProductVersion:= FileVersionMinor/10;   // 3.0  3.1  4.0  5.0
              0:
                  case FileVersionMajor of
                      5:     DLLProductVersion:= 2.0;
                      12,14: DLLProductVersion:= 6.0;    // 12:Office2007  14:Office2010
                      15:    DLLProductVersion:= 8.0;    // 15:Office2013
                      else
                         if FileVersionMajor > 15 then
                            DLLProductVersion:= 8.0
                         else
                            DLLProductVersion:= 3.0;     // conservative
                  end;
           end

    else if nameDLL = 'MSFTEDIT.DLL' then begin
           if (FileVersionMajor = 5) and (FileVersionMinor = 41) then
               DLLProductVersion:= 4.1
           else if (FileVersionMajor = 6) and (FileVersionMinor = 2) then
               DLLProductVersion:= 7.5   // Windows 8
           else if (FileVersionMajor = 10) and (FileVersionMinor = 0) then
               DLLProductVersion:= 7.5   // Windows 10
           else
               if FileVersionMajor > 10 then
                  DLLProductVersion:= 7.5
               else
                  DLLProductVersion:= 4.1;    // conservative
    end;
    
    RichEditVersion := Trunc(DLLProductVersion);

  finally
    FreeMem( buffer, size );
  end;

{
    See also: 	
        https://learn.microsoft.com/en-us/archive/blogs/murrays/richedit-9-additions
        https://learn.microsoft.com/es-es/archive/blogs/murrays/richedit-8-feature-additions
        https://learn.microsoft.com/es-es/archive/blogs/murrays/richedit-versions-update-to-7-0
        https://learn.microsoft.com/es-es/archive/blogs/murrays/richedit-versions


    C:\Windows\System32\RICHED20.DLL
    Rich Text Edit Control, v2.0
    Microsoft RichEdit Control, version 2.0
    5.0.150.0

    C:\Windows\System32\RICHED20.DLL
    Rich Text Edit Control, v3.1
    File version: 5.31.23.1231
    Product version: 3.1
          RichEdit 3: 5.30
          RichEdit 4: 5.40

    XP / Windows 7:
    C:\Windows\System32\MSFTEDIT.DLL
    Rich Text Edit Control, v4.1
    Product version: 4.1
    File version:  5.41.15.1515

    OFFICE 2003  (11)
    C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE11\RICHED20.DLL
    Rich Text Edit Control, v5.0
    Product version: 5.0
    File version: 5.50.99.2070

    OFFICE 2007  (12)
    C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE12\RICHED20.DLL
    RichEdit Version 6.0
    Product/file version: 12.0.6606.1000
    Product name: 2007 Microsoft Office system
    (Needs msptls.dll)

    Windows 8
    C:\Windows\System32\MSFTEDIT.DLL
    Control de edición de texto enriquecido, v7.5
    Product/file version: 6.2.9200.16657

    OFFICE 2010  (14)  (released with W8)
    RichEdit Version 6.0
    C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE14\RICHED20.DLL
    14.0.7155.5000
    (Needs msptls.dll)

    OFFICE 2013  (15)
    RichEdit Version 8.0
    C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE15\RICHED20.DLL
    15.0.4599.1000
    (Needs msptls.dll)

    Windows 10
    C:\Windows\System32\MSFTEDIT.DLL
    Control de edición de texto enriquecido, v7.5
    Product/file version:    10.0.10586.17
}
end; // GetDLLProductVersion


function LoadRichEditDLL(const RichEditLibraryPath: string = ''): TRichEditVersion;      // [dpv]
var
  VersionDLL: Single;
  VersionRichEdit: TRichEditVersion;
  sModulePath: string;

begin
  {$IFDEF KNT_DEBUG} Log.Add(string.format('LoadRichEditDLL - BEGIN.  RichEditLibraryPath: %s', [RichEditLibraryPath]),  4 );  {$ENDIF}

  FLibHandle := 0;
  RichEditVersion := 1;
  OldError := SetErrorMode(SEM_NOOPENFILEERRORBOX);
  try

    if RichEditLibraryPath <> '' then begin
       FLibHandle := LoadLibrary(PChar(RichEditLibraryPath));
       if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR)  then
           FLibHandle := 0;
       if FLibHandle <> 0 then
           RichEditVersion := 3;   // assumption (at least that version)
    end;

   {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - Custom RichEditLibraryPath. OK?: %s', [BoolToStr(FLibHandle > 0)]),  4 ); {$ENDIF}

{$IFNDEF RICHEDIT_VER_10}
    if FLibHandle = 0 then begin
       FLibHandle := LoadLibrary(RichEdit41ModuleName);
       if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR)  then
           FLibHandle := 0;
       if FLibHandle <> 0 then
           RichEditVersion := 4;
    end;

   {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - %s. OK?: %s', [RichEdit41ModuleName, BoolToStr(FLibHandle > 0)]),  4 ); {$ENDIF}

    if FLibHandle = 0 then begin
        FLibHandle := LoadLibrary(RichEdit20ModuleName);
        if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR) then
            FLibHandle := 0;
        if FLibHandle <> 0 then begin
          RichEditVersion := 2;
          Ver.dwOSVersionInfoSize := SizeOf(Ver);
          GetVersionEx(Ver);
          with Ver do begin
             if (dwPlatformId = VER_PLATFORM_WIN32_NT) and
              (dwMajorVersion >= 5) then
              RichEditVersion := 3;
          end;
        end;
        {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - %s. OK?: %s', [RichEdit20ModuleName, BoolToStr(FLibHandle > 0)]),  4 ); {$ENDIF}
    end;
{$ENDIF}
    if FLibHandle = 0 then begin
      FLibHandle := LoadLibrary(RichEdit10ModuleName);
      if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR) then FLibHandle := 0;

      {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - %s. OK?: %s', [RichEdit10ModuleName, BoolToStr(FLibHandle > 0)]),  4 ); {$ENDIF}
    end;


    if FLibHandle <> 0 then begin
       GetDLLProductVersion(sModulePath, VersionDLL, VersionRichEdit);
       if VersionRichEdit > RichEditVersion then
          RichEditVersion:= VersionRichEdit;

       {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - DLL Loaded: %s  VerDLL:%f  VerRichEd: %d', [sModulePath, VersionDLL, VersionRichEdit]),  4 ); {$ENDIF}
    end;

  finally
    SetErrorMode(OldError);
    Result := RichEditVersion;
   {$IFDEF KNT_DEBUG}Log.Add(string.format('LoadRichEditDLL - Result (RichEditVersion): %d', [RichEditVersion]),  4 ); {$ENDIF}
  end;

end; // LoadRichEditDLL



{$ELSE}                              // Not defined RX_SELECTDLL :

procedure LoadRichEditDLL;
begin

  try
{$IFNDEF RICHEDIT_VER_10}
    FLibHandle := LoadLibrary(RichEdit41ModuleName); //last version
    if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR) then
      FLibHandle := LoadLibrary(RichEdit20ModuleName) //most common version
    else
      RichEditVersion := 4;
    if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR) then FLibHandle := 0;
{$ELSE}
    FLibHandle := 0;
{$ENDIF}
    if FLibHandle = 0 then
    begin
      FLibHandle := LoadLibrary(RichEdit10ModuleName);
      if (FLibHandle > 0) and (FLibHandle < HINSTANCE_ERROR) then FLibHandle := 0;
    end
    else
      if RichEditVersion <> 4 then
      begin
        RichEditVersion := 2;
        Ver.dwOSVersionInfoSize := SizeOf(Ver);
        GetVersionEx(Ver);
        with Ver do
        begin
          if (dwPlatformId = VER_PLATFORM_WIN32_NT) and (dwMajorVersion >= 5) then
            RichEditVersion := 3;
        end;
      end;
  finally
    SetErrorMode(OldError);
  end;

end; // LoadRichEditDLL


{$ENDIF}

initialization

{$IFDEF RX_SELECTDLL}
  // LoadRichEditDLL([RichEditLibraryPath]) will be called from outside of this unit, at the beginning of the application
  
{$ELSE}
  RichEditVersion := 1;
  OldError := SetErrorMode(SEM_NOOPENFILEERRORBOX);

  LoadRichEditDLL();
{$ENDIF}

  CFEmbeddedObject := RegisterClipboardFormat(CF_EMBEDDEDOBJECT);
  CFLinkSource := RegisterClipboardFormat(CF_LINKSOURCE);
  CFRtf := RegisterClipboardFormat(CF_RTF);
  CFRtfNoObjs := RegisterClipboardFormat(CF_RTFNOOBJS);
  CFHtml := RegisterClipboardFormat(CF_HTML);                  // [dpv]

{                                                              // [dpv]   See comment *5
  list:= TStringList.Create;
  st1:= TMemoryStream.Create;
  st2:= TMemoryStream.Create;
}

finalization
  if FLibHandle <> 0 then FreeLibrary(FLibHandle);
end.