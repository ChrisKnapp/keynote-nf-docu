unit kn_AlertMng;

(****** LICENSE INFORMATION **************************************************

 - This Source Code Form is subject to the terms of the Mozilla Public
 - License, v. 2.0. If a copy of the MPL was not distributed with this
 - file, You can obtain one at http://mozilla.org/MPL/2.0/.

------------------------------------------------------------------------------
 (c) 2007-2015 Daniel Prado Velasco <dprado.keynote@gmail.com> (Spain)

  Fore more information, please see 'README.md' and 'doc/README_SourceCode.txt'
  in https://github.com/dpradov/keynote-nf

 *****************************************************************************)


interface

uses
   Winapi.Windows,
   Winapi.Messages,
   Winapi.MMSystem,
   Winapi.CommCtrl,
   System.SysUtils,
   System.Classes,
   System.DateUtils,
   System.AnsiStrings,
   Vcl.Graphics,
   Vcl.Controls,
   Vcl.Forms,
   Vcl.Dialogs,
   Vcl.StdCtrls,
   Vcl.ComCtrls,
   Vcl.ExtCtrls,
   Vcl.Clipbrd,

   VirtualTrees,
   TB97Ctls,
   ColorPicker,

   gf_streams,
   gf_misc,
   kn_KntFolder,
   knt.model.note,
   kn_LocationObj
   ;


type
  TShowMode = (TShowReminders, TShowSet, TShowAll, TShowOverdue, TShowPending, TShowDiscarded, TShowNew, TShowAllWithDiscarded);
  TFilterDate = (TSelectAllDates, TSelectDays, TSelectWeek, TSelectMonth);
  TSortedColumn = (TColumnExpiration, TColumnNodeName, TColumnNoteName, TColumnAlarmNote, TColumnReminder, TColumnDiscarded);
  TDaysArray = array of LongWord;

  TAlarmStatus = (TAlarmUnsaved, TAlarmNormal, TAlarmDiscarded, TAlarmPendingKnown, TAlarmPendingUnknown);

  TAlarm = class
  private
    function GetOverdue: boolean;
    function GetPending: boolean;
    function GetEmpty: boolean;

  public
    AlarmReminder: TDateTime;     // Reminder instant
    ExpirationDate: TDateTime;    // Expiration/start instant
    AlarmNote: string;
    NNode: TNoteNode;
    Folder: TKntFolder;
    Bold: boolean;
    FontColor: TColor;
    BackColor: TColor;

    Status: TAlarmStatus;

    property Empty: boolean read GetEmpty;
    property Pending: boolean read GetPending;
    property Overdue: boolean read GetOverdue;    // Alarm whose event is overdue

    constructor Create;
  end;

  TAlarmList = TSimpleObjList<TAlarm>;
  PAlarm = ^TAlarm;


  //---------------------------------------------------------------------

  TAlarmMng = class
  private
    FAlarmList: TAlarmList;

    FDiscardedAlarmList: TAlarmList;          // Alarms discarded. Can be removed or restored
    FSelectedAlarmList: TAlarmList;           // Selection of alarms to show (from reminders triggered, or alarms related to node or folder, if editing or adding)
    FUnfilteredAlarmList: TAlarmList;

    FAuxiliarAlarmList: TAlarmList;           // For loading process. Saves temporarily processed alarms


    Timer: TTimer;
    FTicks: integer;

    FCanceledAt: TDateTime;

    FNumberPending, FNumberOverdue: Integer;

    procedure ShowFormAlarm (modeEdit: TShowMode);

    procedure CommunicateAlarm (alarm: TAlarm);
    procedure UpdateAlarmsState;
    procedure FlashAlarmState();
    procedure TimerTimer(Sender: TObject);
    procedure MoveAlarmsInList( List: TAlarmList; FolderFrom: TKntFolder; NNodeFrom : TNoteNode; FolderTo: TKntFolder; NNodeTo: TNoteNode );

  protected

  public
    procedure EditAlarms (NNode: TNoteNode; Folder: TKntFolder; forceAdd: boolean= false);
    function GetAlarmModeHint: string;
    procedure CheckAlarms;

    property AlarmList: TAlarmList read FAlarmList;
    property DiscardedAlarmList: TAlarmList read FDiscardedAlarmList;
    property SelectedAlarmList: TAlarmList read FSelectedAlarmList;
    property UnfilteredAlarmList: TAlarmList read FUnfilteredAlarmList write FUnfilteredAlarmList;

    function HasAlarms( folder: TKntFolder; NNode: TNoteNode; considerDiscarded: boolean ): boolean;
    function GetAlarms( folder: TKntFolder; NNode: TNoteNode; considerDiscarded: boolean ): TAlarmList;

    property NumberPendingAlarms: integer read FNumberPending;
    property NumberOverdueAlarms: integer read FNumberOverdue;

    function GetNextPendingAlarmForCommunicate: TAlarm;

    procedure AddAlarm( alarm : TAlarm );
    procedure MoveAlarms( FolderFrom: TKntFolder; NNodeFrom : TNoteNode; FolderTo: TKntFolder; NNodeTo: TNoteNode );
    procedure RemoveAlarmsOfNNode( NNode : TNoteNode; UpdateUI: boolean );
    procedure RemoveAlarmsOfFolder( folder : TKntFolder; UpdateUI: boolean );
    procedure RemoveAlarm( alarm : TAlarm; UpdateUI: boolean );
    procedure DiscardAlarm( alarm : TAlarm; MaintainInUnfilteredList: boolean );
    procedure RestoreAlarm( alarm : TAlarm; MaintainInUnfilteredList: boolean  );
    procedure ModifyAlarm( alarm: TAlarm );

    procedure UpdateFormMain (alarm: TAlarm);
    procedure ShowAlarms (const showOnlyPendings: boolean);
    procedure StopFlashMode;
    procedure CancelReminders(value: Boolean);

    procedure Clear;
    constructor Create;
    destructor Destroy; override;

    // Save / Load alarms
    procedure SaveAlarms(var tf : TTextFile; NNode: TNoteNode = nil; Folder: TKntFolder = nil);
    procedure ProcessAlarm (s: AnsiString; NNode: TNoteNode = nil; Folder: TKntFolder = nil);
    procedure AddProcessedAlarms ();
    procedure AddProcessedAlarmsOfFolder (Folder: TKntFolder; NewFolder: TKntFolder);
    procedure AddProcessedAlarmsOfNote (NNode: TNoteNode; Folder: TKntFolder;  NewFolder: TKntFolder; NewNNode: TNoteNode);
    procedure ClearAuxiliarProcessedAlarms();

  end;


  //---------------------------------------------------------------------

  TForm_Alarm = class(TForm)
    Panel: TPanel;

    Grid: TListView;
    Button_Sound: TToolbarButton97;

    PanelCalendar: TPanel;
    cCalendar: TMonthCalendar;

    CB_FilterDates: TComboBox;
    cFilter: TEdit;
    lblFilter: TLabel;
    Button_ClearFilter: TToolbarButton97;

    TntLabel2: TLabel;
    CB_ShowMode: TComboBox;
    TB_ClipCap: TToolbarButton97;
    pnlButtons: TPanel;
    Button_Remove: TButton;
    Button_Restore: TButton;
    Button_Show: TButton;
    Button_New: TButton;
    Button_Discard: TButton;
    Button_SelectAll: TButton;
    PanelAlarm: TPanel;
    lblExpiration: TLabel;
    lblExpirationStatus: TLabel;
    lblReminder: TLabel;
    lblReminderStatus: TLabel;
    Today_8AM: TToolbarButton97;
    LblToday: TLabel;
    Today_12AM: TToolbarButton97;
    Today_3PM: TToolbarButton97;
    Today_6PM: TToolbarButton97;
    Today_8PM: TToolbarButton97;
    LblTomorrow: TLabel;
    Tomorrow_8AM: TToolbarButton97;
    Tomorrow_12AM: TToolbarButton97;
    Tomorrow_3PM: TToolbarButton97;
    Tomorrow_6PM: TToolbarButton97;
    Tomorrow_8PM: TToolbarButton97;
    Today_5min: TToolbarButton97;
    Today_10min: TToolbarButton97;
    Today_15min: TToolbarButton97;
    Today_30min: TToolbarButton97;
    Today_1h: TToolbarButton97;
    Today_2h: TToolbarButton97;
    Today_3h: TToolbarButton97;
    Today_5h: TToolbarButton97;
    TntLabel3: TLabel;
    lblProposedReminder: TLabel;
    CB_ExpirationTime: TComboBox;
    cExpirationTime: TEdit;
    CB_ExpirationDate: TDateTimePicker;
    chk_Expiration: TCheckBox;
    cReminder: TEdit;
    CB_ProposedIntervalReminder: TComboBox;
    rb_Before: TRadioButton;
    rb_FromNow: TRadioButton;
    Button_Apply: TButton;
    chk_ApplyOnExitChange: TCheckBox;
    txtSubject: TMemo;
    cIdentifier: TEdit;
    PanelFormat: TPanel;
    TB_Bold: TToolbarButton97;
    TB_Color: TColorBtn;
    TB_Hilite: TColorBtn;
    btnExpandWindow: TButton;
    btnShowHideDetails: TButton;
    lblCalNotSup: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure EnsureCalendarSupported;
    procedure EnsureCalendarSize;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure Today_5minClick(Sender: TObject);
    procedure Today_5minDblClick(Sender: TObject);

    procedure Button_NewClick(Sender: TObject);
    procedure Button_SelectAllClick(Sender: TObject);
    procedure Button_RemoveClick(Sender: TObject);
    procedure Button_ApplyClick(Sender: TObject);
    procedure Button_SoundClick(Sender: TObject);
    procedure Button_ShowClick(Sender: TObject);
    procedure Button_DiscardClick(Sender: TObject);
    procedure Button_RestoreClick(Sender: TObject);

    procedure CB_ShowModeChange(Sender: TObject);

    procedure TB_ClipCapClick(Sender: TObject);
    procedure TB_HiliteClick(Sender: TObject);
    procedure TB_ColorClick(Sender: TObject);
    procedure TB_BoldClick(Sender: TObject);
    procedure txtSubjectChange(Sender: TObject);

    procedure Button_ClearFilterClick(Sender: TObject);
    procedure cFilterChange(Sender: TObject);
    procedure cFilterExit(Sender: TObject);

    procedure CB_FilterDatesChange(Sender: TObject);
    procedure cCalendarClick(Sender: TObject);
    procedure cCalendarExit(Sender: TObject);
    procedure cCalendarGetMonthInfo(Sender: TObject; Month: Cardinal; var MonthBoldInfo: Cardinal);

    procedure GridEnter(Sender: TObject);
    procedure GridColumnClick(Sender: TObject; Column: TListColumn);
    procedure GridDblClick(Sender: TObject);
    procedure GridSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure GridAdvancedCustomDrawSubItem(Sender: TCustomListView;
                Item: TListItem; SubItem: Integer; State: TCustomDrawState;
                Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure GridAdvancedCustomDrawItem(Sender: TCustomListView;
                Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
                var DefaultDraw: Boolean);

    procedure chk_ExpirationClick(Sender: TObject);
    procedure CB_ExpirationDateChange(Sender: TObject);
    procedure CB_ExpirationTimeCloseUp(Sender: TObject);
    procedure CB_ExpirationTimeSelect(Sender: TObject);
    procedure CB_ExpirationTimeDropDown(Sender: TObject);
    procedure rb_FromNowClick(Sender: TObject);

    procedure cExpirationTimeExit(Sender: TObject);

    procedure CB_ProposedIntervalReminderChange(Sender: TObject);
    procedure CB_ProposedIntervalReminderExit(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnExpandWindowClick(Sender: TObject);
    procedure chk_ApplyOnExitChangeClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnShowHideDetailsClick(Sender: TObject);
    function FormHelp(Command: Word; Data: NativeInt;
      var CallHelp: Boolean): Boolean;

  private
    { Private declarations }
    FModeEdit: TShowMode;
    FFilteredAlarmList: TAlarmList;
    FOptionSelected: TObject;
    FNumberAlarms: integer;

    FNewExpirationDate: TDateTime;
    FReminder: TDateTime;
    FProposedReminder: TDateTime;
    FExpirationDateModified: Boolean;
    FSubjectModified: Boolean;
    FBoldModified: Boolean;
    FFontColorModified, FBackColorModified: Boolean;
    FIntervalDirectlyChanged: Boolean;

    FCalendarMonthChanged: Boolean;
    FInitializingControls: Integer;

    FApplyOnExitChangeBAK: Boolean;

    procedure CreateParams(var Params: TCreateParams); override;

    procedure EnableControls (Value: Boolean);

    function ConfirmApplyPendingChanges(OfferCancel: boolean=false): boolean;
    procedure ResetModifiedState;

    procedure CleanProposedReminderPanel();
    procedure UpdateProposedReminderDate (KeepInterval: boolean = false);
    procedure SetProposedReminderDate(ReferenceDate: TDateTime; IntervalStr: string; BeforeReference: Boolean; KeepInterval: boolean = false);
    procedure ShowReminderDate(Instant: TDateTime);
    procedure ShowReminderStatus(Instant: TDateTime);
    procedure ShowProposedReminderDate(ReminderDate: TDateTime; IntervalStr: string; ReferenceDate: TDateTime; KeepInterval: Boolean = false);
    procedure ReleaseTimeButtons();
    procedure DisableTimeButtonsInThePast ();
    procedure PressEquivalentTimeButton(ReminderDate: TDateTime; ReferenceDate: TDateTime);

    procedure SetModeEdit (Value: TShowMode);
    procedure UpdateCaption;
    procedure UpdateAlarmOnGrid(alarm: TAlarm; item: TListItem);

    procedure ShowExpirationDate(Instant: TDateTime);
    procedure ShowExpirationStatus(Instant: TDateTime);
    function  GetSelectedExpirationDate: TDateTime;
    procedure SetNewExpirationDate(Instant: TDateTime);

    function  AlarmSelected: TAlarm;
    procedure TrySelectItem(i: integer);
    procedure HideAlarm(ls: TListItem);

    procedure ShowCommonProperties();
    procedure ShowDetails(Show: boolean);

    procedure CopyAlarmList();
    function UnfilteredAlarmList: TAlarmList;

    function CreateLocation(alarm: TAlarm): TLocation;

  public
    property ModeEdit: TShowMode read FModeEdit write SetModeEdit;
    property NewExpirationDate: TDateTime read FNewExpirationDate write SetNewExpirationDate;
    function ChangesToApply: Boolean;

    procedure FilterAlarmList;
  end;


  function FormatAlarmInstant (instant: TDateTime): string;

var
  Form_Alarm: TForm_Alarm;
  SortedColumn: TSortedColumn;
  AscOrder: integer;  // 1: ASC  -1: DESC

implementation
uses
  gf_strings,
  gf_miscvcl,
  kn_Global,
  kn_const,
  kn_Info,
  kn_ClipUtils,
  kn_RTFUtils,
  kn_LinksMng,
  kn_VCLControlsMng,
  kn_Main,
  knt.App,
  knt.RS
  ;


{$R *.DFM}

  //const COLUMN_AlarmNote = 0;         // item
  const COLUMN_ReminderDate = 0;        // subitems
  const COLUMN_ReminderTime = 1;
  const COLUMN_ExpirationDate = 2;
  const COLUMN_ExpirationTime = 3;
  const COLUMN_NoteName = 4;
  const COLUMN_NodeName = 5;
  const COLUMN_Discarded = 6;


  const WAIT_TIME_ON_ESCAPE = 5;
  const IMG_INDEX_NO_OVERDUE_NOR_PENDING = 51;
  const IMG_INDEX_OVERDUE_OR_PENDING = 52;

  const FORM_WIDTH = 966;



// From TTntMonthCalendar.ForceGetMonthInfo()
procedure ForceGetMonthInfo (calendar: TMonthCalendar);
var
  Hdr: TNMDayState;
  Days: array of TMonthDayState;
  Range: array[1..2] of TSystemTime;
  Handle: HWND;
begin
  Handle:= calendar.Handle;

  // populate Days array
  Hdr.nmhdr.hwndFrom := Handle;
  Hdr.nmhdr.idFrom := 0;
  Hdr.nmhdr.code := MCN_GETDAYSTATE;
  Hdr.cDayState := MonthCal_GetMonthRange(Handle, GMR_DAYSTATE, @Range[1]);
  Hdr.stStart := Range[1];
  SetLength(Days, Hdr.cDayState);
  Hdr.prgDayState := @Days[0];
  SendMessage(Handle, CN_NOTIFY, WPARAM(Handle), LPARAM(@Hdr));
  // update day state
  SendMessage(Handle, MCM_SETDAYSTATE, Hdr.cDayState, LPARAM(Hdr.prgDayState))
end;

//From ComControl98 (TreeNT)
function MonthCal_GetMonthRange(hmc: HWND; gmr: DWORD; rgst: PSystemTime): DWORD;
begin
  Result := SendMessage(hmc, MCM_GETMONTHRANGE, gmr, LPARAM(rgst));
end;




//==========================================================================================
//                                         TAlarm
//==========================================================================================

constructor TAlarm.Create;
begin
   inherited Create;
   Status := TAlarmNormal;
   AlarmReminder:= 0;
   ExpirationDate:= 0;
   AlarmNote:= '';
   NNode:= nil;
   folder:= nil;
   Bold:= False;
   FontColor:= clWindowText;
   BackColor:= clWindow;
end;

function TAlarm.GetOverdue: boolean;
begin
   Result:= (ExpirationDate <>0) and ( now() >= ExpirationDate);
end;

function TAlarm.GetPending: boolean;
begin
   Result:= (Status = TAlarmPendingKnown) or (Status = TAlarmPendingUnknown);
end;

function TAlarm.GetEmpty: boolean;
begin
   Result:= (Trim(AlarmNote)='') and (ExpirationDate = 0);
end;


//==========================================================================================
//                                   TAlarmMng
//==========================================================================================

//----------------------------------
//          Creation / Destruction
//----------------------------------

constructor TAlarmMng.Create;
begin
   inherited Create;
   //FEnabled:= false;
   FAlarmList:= TAlarmList.Create;
   FAlarmList.Capacity:= 10;
   FSelectedAlarmList:= TAlarmList.Create;
   FDiscardedAlarmList:= TAlarmList.Create;
   FUnfilteredAlarmList:= nil;

   FAuxiliarAlarmList:= TAlarmList.Create;

   Timer:= TTimer.Create(nil);
   Timer.Interval:= 350;
   Timer.Enabled := false;
   Timer.OnTimer:= TimerTimer;
   FCanceledAt:= 0;

   FNumberPending:= 0;
   FNumberOverdue:= 0;

   UpdateAlarmsState;
end;

destructor TAlarmMng.Destroy;
begin
   if assigned (FAlarmList) then
      FAlarmList.Free;
   if assigned (FSelectedAlarmList) then
      FSelectedAlarmList.Free;
   if assigned (FDiscardedAlarmList) then
      FDiscardedAlarmList.Free;

   if assigned (FAuxiliarAlarmList) then
      FAuxiliarAlarmList.Free;

   if assigned (Timer) then
      Timer.Free;
   inherited Destroy;
end;

procedure TAlarmMng.Clear;
begin
   if assigned (FAlarmList) then
      FAlarmList.Clear;
   if assigned (FSelectedAlarmList) then
      FSelectedAlarmList.Clear;
   if assigned(FDiscardedAlarmList) then
      FDiscardedAlarmList.Clear;

   FCanceledAt:= 0;
   UpdateAlarmsState;
end;


//----------------------------------
//       Node / Folder Information
//----------------------------------

// Only one of the first two parameters (folder, node) is needed, the other can be set to nil
function TAlarmMng.HasAlarms( folder: TKntFolder; NNode: TNoteNode; considerDiscarded: boolean ): boolean;

    function HasAlarmsInList (list: TAlarmList): boolean;
    var
       i: integer;
       alarm: TAlarm;
    begin
       Result:= false;
       i:= 0;
       while I <= list.Count - 1 do begin
           alarm:= list[i];
           if assigned(NNode) then begin
                if NNode = alarm.NNode then begin
                   Result:= true;
                   break;
                end;
           end
           else if (alarm.NNode = nil) and (folder = alarm.folder) then begin
                   Result:= true;
                   break;
                end;
           I:= I + 1;
       end;
    end;

begin
   Result:= HasAlarmsInList(FAlarmList);
   if (not Result) and considerDiscarded then
       Result:= HasAlarmsInList(FDiscardedAlarmList);
end;


// Only one of the first two parameters (folder, node) is needed, the other can be set to nil
function TAlarmMng.GetAlarms( folder: TKntFolder; NNode: TNoteNode; considerDiscarded: boolean ): TAlarmList;

    procedure AddAlarmsFromList (list: TAlarmList);
    var
       i: Integer;
       alarm: TAlarm;
    begin
       i:= 0;
       while i <= list.Count - 1 do begin
          alarm:= list[i];
          if assigned(NNode) then begin
             if NNode = alarm.NNode then
                Result.Add(alarm)
          end
             else if (alarm.NNode = nil) and (folder = alarm.folder) then
                Result.Add(alarm);

          i:= i + 1;
       end;
    end;

begin
   Result:= TAlarmList.Create;

   AddAlarmsFromList (FAlarmList);
   if considerDiscarded then
      AddAlarmsFromList (FDiscardedAlarmList);
end;


//----------------------------------
//       Auxiliar methods
//----------------------------------

function FormatDate (instant: TDateTime): string;
begin
    if instant = 0 then
       Result:= ''
    else
        if IsToday(instant) then
           Result:= GetRS(sAlrt20)
        else if IsToday(IncDay(instant,-1)) then
           Result:= GetRS(sAlrt21)
        else
           Result:= FormatDateTime( 'dd/MMM/yyyy', instant );
end;

function FormatAlarmInstant (instant: TDateTime): string;
begin
    if instant = 0 then
       Result:= ''
    else
        if IsToday(instant) then
           Result:= GetRS(sAlrt20) + ' ' + FormatDateTime( 'HH:mm', instant )
        else if IsToday(IncDay(instant,-1)) then
           Result:= GetRS(sAlrt21) + ' ' + FormatDateTime( 'HH:mm', instant )
        else
           Result:= FormatDateTime( 'dd MMM yyyy - HH:mm', instant );
end;

function compareAlarms_Reminder (Alarm1, Alarm2: TAlarm): integer;
begin
   if Alarm1.AlarmReminder = Alarm2.AlarmReminder  then
      Result:= 0
   else if Alarm1.AlarmReminder > Alarm2.AlarmReminder then
      Result:= 1
   else
      Result:= -1;
end;

function compareAlarms_selectedColumn(PAlarm1, PAlarm2: Pointer): Integer;
var
   nodeName1, nodeName2: string;
   discarded1, discarded2: Boolean;
   Alarm1, Alarm2: TAlarm;
begin
    Alarm1:= TAlarm(PAlarm1);
    Alarm2:= TAlarm(PAlarm2);
    case SortedColumn of
        TColumnExpiration:
               if Alarm1.ExpirationDate = Alarm2.ExpirationDate  then
                  Result:= compareAlarms_Reminder (Alarm1, Alarm2)
               else if Alarm1.ExpirationDate > Alarm2.ExpirationDate then
                  Result:= 1
               else
                  Result:= -1;

        TColumnNoteName, TColumnNodeName:
               begin
                   if assigned (Alarm1.NNode) then nodeName1:= Alarm1.NNode.GetNodeName(Alarm1.folder) else nodeName1:= '';
                   if assigned (Alarm2.NNode) then nodeName2:= Alarm2.NNode.GetNodeName(Alarm2.folder) else nodeName2:= '';
                   nodeName1:= Alarm1.folder.Name + nodeName1;
                   nodeName2:= Alarm2.folder.Name + nodeName2;

                   if nodeName1  = nodeName2 then
                      Result:= compareAlarms_Reminder (Alarm1, Alarm2)
                   else if nodeName1 > nodeName2 then
                      Result:= 1
                   else
                      Result:= -1;
               end;

        TColumnAlarmNote:
               if Alarm1.AlarmNote  = Alarm2.AlarmNote then
                  Result:= compareAlarms_Reminder (Alarm1, Alarm2)
               else if Alarm1.AlarmNote > Alarm2.AlarmNote then
                  Result:= 1
               else
                  Result:= -1;

        TColumnReminder:
               if Alarm1.AlarmReminder  = Alarm2.AlarmReminder then
                  Result:= 0
               else if Alarm1.AlarmReminder > Alarm2.AlarmReminder then
                  Result:= 1
               else
                  Result:= -1;

        TColumnDiscarded:
             begin
               discarded1:= (Alarm1.Status = TAlarmDiscarded);
               discarded2:= (Alarm2.Status = TAlarmDiscarded);
               if discarded1 = discarded2 then
                  Result:= 0
               else if discarded1 then
                  Result:= 1
               else
                  Result:= -1;
             end;
    end;
    Result:= Result * AscOrder;

end;


//----------------------------------
//       Alarms Check
//----------------------------------


procedure TAlarmMng.CheckAlarms;
var
  ShowRemindersInModalWindow: boolean;
  TriggeredAlarmList: TAlarmList;
  alarm: TAlarm;

  procedure FillTriggeredAlarmList;
  var
    I: Integer;
    alarm: TAlarm;
    limit: TDateTime;
  begin
     limit:= 0;

     if FCanceledAt <> 0 then
        limit:= incMinute(FCanceledAt, WAIT_TIME_ON_ESCAPE);

     I:= 0;
     while I <= FAlarmList.Count - 1 do begin
        alarm:= FAlarmList[I];
        if ( (now >= alarm.AlarmReminder) and ((FCanceledAt = 0) or (now > limit) or (alarm.AlarmReminder > FCanceledAt)) ) or
           (alarm.Overdue and (alarm.ExpirationDate > FCanceledAt) and (DateTimeDiff(now, alarm.ExpirationDate)<5*60))
        then begin
            TriggeredAlarmList.Add(alarm);
            if not alarm.Pending then begin
               if not ShowRemindersInModalWindow then
                  alarm.Status:= TAlarmPendingUnknown
               else
                  alarm.Status:= TAlarmPendingKnown;
            end;
        end;
        
        I:= I + 1;
      end;
  end;

  procedure PlaySound;
  var
     soundfn: string;
  begin
     soundfn := extractfilepath( application.exename ) + 'alert.wav';
     if ( KeyOptions.PlaySoundOnAlarm and fileexists( soundfn )) then
         sndplaysound( PChar( soundfn ), SND_FILENAME or SND_ASYNC or SND_NOWAIT );
  end;

begin
   TriggeredAlarmList:= TAlarmList.Create;
   ShowRemindersInModalWindow:= not (KeyOptions.DisableAlarmPopup or (assigned(Form_Alarm) and Form_Alarm.Visible ));

   try
     FillTriggeredAlarmList;

     if TriggeredAlarmList.Count > 0 then begin

         if ShowRemindersInModalWindow then begin
             PlaySound;

             if IsIconic( Application.Handle ) then begin  // with MainFormOnTaskbar := True => Application.Handle -> Form_Main.Handle
                Application_Restore;
                Application_BringToFront;
             end;

             FSelectedAlarmList.Assign(TriggeredAlarmList);
             ShowFormAlarm (TShowReminders);
         end
         else begin    // ShowRemindersInModalWindow = False
            alarm:= GetNextPendingAlarmForCommunicate;
            if assigned(alarm) then begin      // there has been new triggerd alarms
               PlaySound;
               CommunicateAlarm(alarm);
               alarm.Status := TAlarmPendingKnown;
               Timer.Enabled := True;   // Each new triggered alarm will be notified for a few seconds, and will active flash mode of TB_AlarmMode
               FTicks:= 0;
               UpdateAlarmsState;
            end;
         end;

     end;

   finally
     TriggeredAlarmList.Clear;
   end;

end;


procedure TAlarmMng.UpdateAlarmsState;
var
  I: Integer;
  alarm: TAlarm;
begin
   I:= 0;
   FNumberOverdue:= 0;
   FNumberPending:= 0;

   while I <= FAlarmList.Count - 1 do begin
      alarm:= FAlarmList[i];
      if alarm.Overdue then
         FNumberOverdue:= FNumberOverdue + 1;

      if alarm.Pending then
         if (alarm.AlarmReminder = 0) or (now() < alarm.AlarmReminder) then
             alarm.Status := TAlarmNormal
         else
             FNumberPending:= FNumberPending + 1;
      I:= I + 1;
   end;


   Form_Main.TB_AlarmMode.Hint:= GetAlarmModeHint;

   if (FNumberPending = 0) and (FNumberOverdue = 0) then begin
      Form_Main.TB_AlarmMode.ImageIndex:= IMG_INDEX_NO_OVERDUE_NOR_PENDING;
      SelectStatusbarGlyph( ActiveFile<>nil );      // Reset icon on status bar
   end
   else
      if Form_Main.TB_AlarmMode.ImageIndex = IMG_INDEX_NO_OVERDUE_NOR_PENDING then begin
        // Each triggered alarm (there may be more than one) will be notified for a second and image of button TB_AlarmMode will alternate
        Timer.Enabled := True;
        FTicks:= 0;
        Form_Main.TB_AlarmMode.ImageIndex:= IMG_INDEX_OVERDUE_OR_PENDING;
     end;
end;


//----------------------------------
//       Alarm List Management
//----------------------------------


procedure TAlarmMng.AddAlarm( alarm : TAlarm );
begin
    if not assigned(alarm) then exit;

    if alarm.Status = TAlarmDiscarded then
       FDiscardedAlarmList.Add(alarm)
    else
       FAlarmList.Add(alarm);
    UpdateFormMain (alarm);
end;

procedure TAlarmMng.MoveAlarms( FolderFrom: TKntFolder; NNodeFrom : TNoteNode; FolderTo: TKntFolder; NNodeTo: TNoteNode );
begin
    MoveAlarmsInList(FAlarmList, FolderFrom, NNodeFrom,  FolderTo, NNodeTo);
    if assigned(FUnfilteredAlarmList) then
       MoveAlarmsInList(FUnfilteredAlarmList, FolderFrom, NNodeFrom,  FolderTo, NNodeTo);

    MoveAlarmsInList(FDiscardedAlarmList, FolderFrom, NNodeFrom,  FolderTo, NNodeTo);
    MoveAlarmsInList(FSelectedAlarmList, FolderFrom, NNodeFrom,  FolderTo, NNodeTo);
    // TODO: Refrescar el nodo actual
end;

procedure TAlarmMng.MoveAlarmsInList( List: TAlarmList; FolderFrom: TKntFolder; NNodeFrom : TNoteNode; FolderTo: TKntFolder; NNodeTo: TNoteNode );
var
  I: Integer;
  alarm: TAlarm;
begin
   I:= 0;
   while I <= List.Count - 1 do begin
      alarm:= List[i];
      if (alarm.folder = FolderFrom) and assigned(alarm.NNode) and (alarm.NNode.GID = NNodeFrom.GID) then begin
         alarm.folder:= FolderTo;
         alarm.NNode:= NNodeTo;
      end;
      I:= I + 1;
   end;
end;

procedure TAlarmMng.RemoveAlarmsOfNNode( NNode : TNoteNode; UpdateUI: boolean );
var
  I: Integer;
  alarm: TAlarm;
begin
   I:= 0;
   while I <= FAlarmList.Count - 1 do begin
      alarm:= FAlarmList[i];
      if NNode = alarm.NNode then
         RemoveAlarm(alarm, false);
      I:= I + 1;
   end;

   if UpdateUI then begin
      UpdateAlarmsState;
      UpdateFormMain(alarm);
   end;

end;

procedure TAlarmMng.RemoveAlarmsOfFolder( folder : TKntFolder; UpdateUI: boolean );
var
  I: Integer;
  alarm: TAlarm;
begin
   I:= 0;
   while I <= FAlarmList.Count - 1 do begin
      alarm:= FAlarmList[i];
      if (alarm.NNode = nil) and (folder = alarm.folder) then
         RemoveAlarm(FAlarmList[i], false);
      I:= I + 1;
   end;

   if UpdateUI then begin
      UpdateAlarmsState;
      UpdateFormMain(alarm);
   end;

end;


procedure TAlarmMng.ModifyAlarm( alarm: TAlarm );
begin
    UpdateAlarmsState;
    UpdateFormMain(alarm);
end;

procedure TAlarmMng.DiscardAlarm( alarm : TAlarm; MaintainInUnfilteredList: boolean );
begin
    alarm.Status:= TAlarmDiscarded;
    FDiscardedAlarmList.Add(alarm);
    FAlarmList.Remove(alarm);
    FSelectedAlarmList.Remove(alarm);
    if not MaintainInUnfilteredList and assigned(FUnfilteredAlarmList) then
       FUnfilteredAlarmList.Remove(alarm);

    UpdateAlarmsState;
    UpdateFormMain(alarm);
end;

procedure TAlarmMng.RemoveAlarm( alarm : TAlarm; UpdateUI: boolean);
begin
    FAlarmList.Remove(alarm);
    FDiscardedAlarmList.Remove(alarm);
    FSelectedAlarmList.Remove(alarm);
    if assigned(FUnfilteredAlarmList) then
       FUnfilteredAlarmList.Remove(alarm);

    if UpdateUI then begin
       UpdateAlarmsState;
       UpdateFormMain(alarm);
    end;
end;

procedure TAlarmMng.RestoreAlarm( alarm : TAlarm; MaintainInUnfilteredList: boolean  );
begin
    alarm.Status:= TAlarmNormal;
    FDiscardedAlarmList.Remove(alarm);
    FAlarmList.Add(alarm);
    FSelectedAlarmList.Remove(alarm);
    if not MaintainInUnfilteredList and assigned(FUnfilteredAlarmList) then
       FUnfilteredAlarmList.Remove(alarm);

    UpdateAlarmsState;
    UpdateFormMain(alarm);
end;


procedure TAlarmMng.CancelReminders (value: boolean);
begin
   if Value then
      FCanceledAt:= now
   else
      FCanceledAt:= 0;
end;


procedure TAlarmMng.EditAlarms (NNode: TNoteNode; Folder: TKntFolder; forceAdd: boolean= false);
var
   alarm: TAlarm;
begin
      FSelectedAlarmList.Clear;
      FSelectedAlarmList:= GetAlarms(Folder, NNode, false);
      if forceAdd or (FSelectedAlarmList.Count = 0) then begin
         alarm:= TAlarm.Create;
         alarm.NNode:= NNode;
         alarm.folder:= Folder;
         alarm.Status:= TAlarmUnsaved;
         FSelectedAlarmList.Add(alarm);
      end;

      ShowFormAlarm (TShowSet);
end;


procedure TAlarmMng.ShowAlarms (const showOnlyPendings: boolean);
var
   modeEdit: TShowMode;
begin
      if showOnlyPendings and (NumberPendingAlarms > 0) then
         modeEdit:= TShowPending
      else
         modeEdit:= TShowAll;

      ShowFormAlarm (modeEdit);
end;

procedure TAlarmMng.ShowFormAlarm (modeEdit: TShowMode);
begin
  if ( Form_Alarm = nil ) then
  begin
    Form_Alarm := TForm_Alarm.Create( Form_Main );
  end;

  try
    App.SetTopMost(Form_Alarm.Handle, True);

    Form_Alarm.ShowDetails (modeEdit <> TShowAll);
    Form_Alarm.modeEdit:= modeEdit;

    Form_Alarm.EnableControls(false);
    Form_Alarm.cFilter.Text:= '';
    if (modeEdit = TShowReminders) then begin
       Form_Alarm.CB_FilterDates.ItemIndex:= 0;
       Form_Alarm.Width:= Form_Alarm.Constraints.MinWidth;
    end
    else
       Form_Alarm.Width:= FORM_WIDTH + 5;
       
    Form_Alarm.FilterAlarmList;

    UpdateAlarmsState;
    if not Form_Alarm.Visible then
       Form_Alarm.Show
    else
       Form_Alarm.FormShow(nil);

    if modeEdit = TShowAll then
       Form_Alarm.Grid.Selected:= nil;

  except
    on E : Exception do
    begin
      App.ErrorPopup( E.Message);
    end;
  end;

end;



//-----------------------------------------------------
//      Inform Alarms State / Reminders triggered / Overdue events
//-----------------------------------------------------

procedure TAlarmMng.UpdateFormMain ( alarm: TAlarm );
begin
   if alarm.folder <> ActiveFolder then exit;
   Form_Main.UpdateAlarmStatus;
end;


procedure TAlarmMng.FlashAlarmState();
var
  Glyph : TPicture;
  Index: integer;
begin
   if (FNumberPending = 0) and (FNumberOverdue = 0) then
      Index:= IMG_INDEX_NO_OVERDUE_NOR_PENDING
   else begin
       Index:= Form_Main.TB_AlarmMode.ImageIndex;
       if Index = IMG_INDEX_OVERDUE_OR_PENDING then
          Index:= IMG_INDEX_NO_OVERDUE_NOR_PENDING
       else
          Index:= IMG_INDEX_OVERDUE_OR_PENDING;
   end;
  Form_Main.TB_AlarmMode.ImageIndex:= Index;

  Glyph := TPicture.Create;
  try
    Form_Main.IMG_Toolbar.GetBitmap(Index, Glyph.Bitmap);
    SetStatusbarGlyph(Glyph);
  finally
    Glyph.Free;
  end;
end;

procedure TAlarmMng.StopFlashMode;
begin
  if assigned( ActiveFile ) then begin
     UpdateAlarmsState;
     Timer.Enabled := false;
     SelectStatusbarGlyph( true );      // Reset icon on status bar
  end;
end;


procedure TAlarmMng.CommunicateAlarm (alarm : TAlarm);
var
   cad: string;
   idAlarm: string;
begin
   if alarm.AlarmNote <> '' then
      cad:= Format(' [%s]', [ StringReplace(alarm.AlarmNote, _CRLF, ' // ', [rfReplaceAll]) ])
   else
      cad:= '';

   if assigned(alarm.NNode) then
      idAlarm:= alarm.NNode.GetNodeName(alarm.folder)
   else
      idAlarm:= alarm.folder.Name;
   App.ShowInfoInStatusBar(Format(GetRS(sAlrt08), [FormatAlarmInstant(alarm.ExpirationDate), idAlarm + cad]));
end;

procedure TAlarmMng.TimerTimer(Sender: TObject);
var
  alarm: TAlarm;
begin
   FlashAlarmState();
   FTicks:= FTicks + 1;
   if FTicks > 14 then begin   // Aprox. 5 seconds
     alarm:= GetNextPendingAlarmForCommunicate;
     if assigned(alarm) then
        CommunicateAlarm(alarm);

     if (FNumberPending = 0) and (FNumberOverdue = 0) then
        StopFlashMode;
   end;
end;


function TAlarmMng.GetAlarmModeHint: string;
var
  soundState, popupState: string;
begin
   if KeyOptions.PlaySoundOnAlarm then
      soundState:= GetRS(sAlrt09)
   else
      soundState:= GetRS(sAlrt10);

   if KeyOptions.DisableAlarmPopup then
      popupState:= GetRS(sAlrt13)
   else
      popupState:= GetRS(sAlrt12);

   Result:= Format(GetRS(sAlrt11), [NumberPendingAlarms, NumberOverdueAlarms, popupState, soundState]);
end;


function TAlarmMng.GetNextPendingAlarmForCommunicate: TAlarm;
var
  I: Integer;
  alarm: TAlarm;
begin
   I:= 0;
   while I <= FAlarmList.Count - 1 do begin
      alarm:= FAlarmList[i];
      if alarm.Status = TAlarmPendingUnknown then begin
         Result:= alarm;
         exit;
      end;
      I:= I + 1;
   end;

   Result:= nil;
end;



// Save / Load alarms

(*
Format of the serialized alarm:  NA=[D]Reminder[/Expiration][*Format][|subject]
Ej: NA=D10-06-2010 08:00:00/10-06-2010 07:55:00*B100/1200|Comment to the alarm

[] => optional
D: Discarded
Expiration or Reminder: DD-MM-YYYY HH:MM:SS
Format: BoldFormatFontColor/BackColor
BoldFormat: B or N   (Bold or Normal)
FontColor - BackColor: number (TColor)
subject: unicode text

*)


procedure TAlarmMng.SaveAlarms(var tf : TTextFile; NNode: TNoteNode = nil; Folder: TKntFolder = nil);
var
   I: integer;
   Alarms: TAlarmList;
   s: string;
   alarm: TAlarm;
   BoldStr: char;
begin
  try
     if assigned(NNode) then
        Alarms:= GetAlarms(nil, NNode, true)
     else
        Alarms:= GetAlarms(Folder, nil, true);

     I:= 0;
     while I <= Alarms.Count - 1 do begin
        alarm:= Alarms[i];
        s:= '';
        if alarm.ExpirationDate <> 0 then
           s:= '/' + FormatDateTime(_COMPACT_DATETIME_TOFILE, alarm.ExpirationDate );

        if alarm.Bold or (alarm.FontColor <> clWindowText) or (alarm.BackColor <> clWindow) then begin
           if alarm.Bold then BoldStr:= 'B' else BoldStr:= 'N';
           s:= s + '*' + BoldStr + IntToStr(alarm.FontColor) + '/' + IntToStr(alarm.BackColor);
           end;

        if alarm.AlarmNote <> '' then
           s:= s + '|' + StringReplace(alarm.AlarmNote, #13#10, '��', [rfReplaceAll]);
        s:= FormatDateTime(_COMPACT_DATETIME_TOFILE, alarm.AlarmReminder ) + s;
        if alarm.Status = TAlarmDiscarded then
           s:= 'D' + s;
        tf.WriteLine( _NodeAlarm + '=' + s, True );

        I:= I + 1;
     end;

  except
  end;
end;


procedure TAlarmMng.ProcessAlarm (s: AnsiString; NNode: TNoteNode = nil; Folder: TKntFolder = nil);
var
    alarm: TAlarm;
    p, p2: integer;
    format: AnsiString;
begin
   try

      alarm:= TAlarm.Create;

      p := Pos( '|', s );
      if ( p > 0 ) then begin
          alarm.AlarmNote:= StringReplace(TryUTF8ToUnicodeString(copy(s, p+1, length(s))), '��', #13#10, [rfReplaceAll]);
          delete( s, p, length(s));
      end;

      p := Pos( '*', s );
      if ( p > 0 ) then begin
          format:= copy(s, p+1, length(s));
          if format[1] = 'B' then
             alarm.Bold:= true;
          p2 := Pos( '/', format );
          alarm.FontColor := StrToInt(copy(format, 2, p2-2));
          alarm.BackColor := StrToInt(copy(format, p2+1, length(format)));
          delete( s, p, length(s));
      end;

      p := Pos( '/', s );
      if ( p > 0 ) then begin
          if ActiveFile.Version.Major < '3' then
             alarm.ExpirationDate:= StrToDateTime(copy(s, p+1, length(s)), LongDateToFileSettings)
          else
             alarm.ExpirationDate:= StrToDate_Compact( copy(s, p+1, length(s)) );
          delete( s, p, length(s));
      end;
      if s[1] = 'D' then begin
         alarm.Status := TAlarmDiscarded;
         s:= Copy(s,2,MaxInt)
      end;
      if ActiveFile.Version.Major < '3' then
         alarm.AlarmReminder:= StrToDateTime(s, LongDateToFileSettings)
      else
         alarm.AlarmReminder:= StrToDate_Compact(s);

      if p <= 0  then
         alarm.ExpirationDate:= 0;

      alarm.NNode:= NNode;
      alarm.Folder:= Folder;

      FAuxiliarAlarmList.Add(alarm);

   except
   end;
end;


procedure TAlarmMng.AddProcessedAlarms ();
var
  I: Integer;
begin
   if not assigned(FAuxiliarAlarmList) then exit;
   I:= 0;
   while I <= FAuxiliarAlarmList.Count - 1 do begin
      AlarmMng.AddAlarm(FAuxiliarAlarmList[i]);
      I:= I + 1;
   end;

   FAuxiliarAlarmList.Clear;
end;

procedure TAlarmMng.AddProcessedAlarmsOfFolder (Folder: TKntFolder; NewFolder: TKntFolder);
var
  I: Integer;
  alarm: TAlarm;
begin
   if not assigned(FAuxiliarAlarmList) then exit;

   I:= 0;
   while I <= FAuxiliarAlarmList.Count - 1 do begin
      alarm:= FAuxiliarAlarmList[i];
      if (alarm.Folder = Folder) and (alarm.NNode= nil) then begin
         alarm.Folder := NewFolder;
         AlarmMng.AddAlarm(alarm);
      end;
      I:= I + 1;
   end;
end;

procedure TAlarmMng.AddProcessedAlarmsOfNote (NNode: TNoteNode; Folder: TKntFolder;  NewFolder: TKntFolder; NewNNode: TNoteNode);
var
  I: Integer;
  alarm: TAlarm;
begin
   if not assigned(FAuxiliarAlarmList) then exit;

   I:= 0;
   while I <= FAuxiliarAlarmList.Count - 1 do begin
      alarm:= FAuxiliarAlarmList[i];
      if (alarm.Folder = Folder) and (alarm.NNode = NNode) then begin
         alarm.Folder := NewFolder;
         alarm.NNode := NewNNode;
         AlarmMng.AddAlarm(alarm);
      end;
      I:= I + 1;
   end;
end;

procedure TAlarmMng.ClearAuxiliarProcessedAlarms();
begin
   if assigned(FAuxiliarAlarmList) then
      FAuxiliarAlarmList.Clear;
end;



//==========================================================================================
//                                   TForm_Alarm
//==========================================================================================

//----------------------------------
//          Creation / Close
//----------------------------------

procedure TForm_Alarm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := _MainFormHandle;
end; // CreateParams


procedure TForm_Alarm.FormCreate(Sender: TObject);
var
   i: integer;
begin
  FFilteredAlarmList:= TAlarmList.Create;
  FCalendarMonthChanged:= false;
  FInitializingControls:= 0;
  FIntervalDirectlyChanged:= False;
  FApplyOnExitChangeBAK:= True;

  with CB_ProposedIntervalReminder.Items do begin
      Add('0 ' + GetRS(STR_minutes));
      Add('5 ' + GetRS(STR_minutes));
      Add('10 ' + GetRS(STR_minutes));
      Add('15 ' + GetRS(STR_minutes));
      Add('30 ' + GetRS(STR_minutes));

      Add('1 ' + GetRS(STR_hour));
      for i := 2 to 10 do
          Add(intTostr(i) + ' ' + GetRS(STR_hours));
      Add('0.5 ' + GetRS(STR_days));
      Add('18 ' + GetRS(STR_hours));
      Add('1 ' + GetRS(STR_day));
      for i := 2 to 4 do
          Add(intTostr(i) + ' ' + GetRS(STR_days));
      Add('1 ' + GetRS(STR_week));
      Add('2 ' + GetRS(STR_weeks));
  end;
  CB_ProposedIntervalReminder.ItemIndex := 0;

  with CB_ExpirationTime.Items do begin
      for i := 0 to 23 do begin
          Add(Format('%.2d:00', [i]));
          Add(Format('%.2d:30', [i]));
      end;
  end;
  CB_ExpirationTime.Text := '';

  with CB_ShowMode.Items do begin
      Add(GetRS(sAlrt22));
      Add(GetRS(sAlrt24));
      Add(GetRS(sAlrt23));
      Add(GetRS(sAlrt25));
      Add(GetRS(sAlrt26));
  end;
  CB_ShowMode.ItemIndex:= -1;

  with CB_FilterDates.Items do begin
      Add(GetRS(sAlrt31));
      Add(GetRS(sAlrt32));
      Add(GetRS(sAlrt33));
      Add(GetRS(sAlrt34));
  end;
  CB_FilterDates.ItemIndex:= 0;

  cCalendar.Date:= now;
  cCalendar.EndDate:= now;
end;


function TForm_Alarm.FormHelp(Command: Word; Data: NativeInt;
  var CallHelp: Boolean): Boolean;
begin
   CallHelp:= False;
   ActiveKeyNoteHelp_FormHelp(Command, Data);
end;

procedure TForm_Alarm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   CanClose:= ConfirmApplyPendingChanges(true);
end;


procedure TForm_Alarm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if (modeEdit = TShowReminders) or (modeEdit = TShowAll) or (modeEdit = TShowPending) or (modeEdit = TShowAllWithDiscarded) then
        AlarmMng.CancelReminders(true);

   AlarmMng.StopFlashMode;
   FFilteredAlarmList.Clear;
end;


//----------------------------------
//          Show / Resize
//----------------------------------


procedure TForm_Alarm.EnsureCalendarSupported;
begin
  if CB_ExpirationDate.Visible then exit;

  if not CheckCalendarInTDateTimePicker(Form_Main) then begin
     if not PrepareTDateTimePicker(CB_ExpirationDate) then
        lblCalNotSup.Visible:= True;
     try
        cCalendar.MinDate:= EncodeDate(2000, 1, 1);
        cCalendar.MaxDate:= EncodeDate(2075, 12, 31);
        cCalendar.Date:= Today();
        cCalendar.Visible := True;
     except
     end;
  end
  else begin
     try
       CB_ExpirationDate.Visible := true;
       cCalendar.Visible := true;
     except
       lblCalNotSup.Visible:= True;
     end;
  end;
end;

procedure TForm_Alarm.EnsureCalendarSize;
var
  Dif: integer;
  MinRect: TRect;

begin
  SendMessage(cCalendar.Handle, MCM_GETMINREQRECT, 0, LPARAM(@MinRect));  // Minimum size required
  cCalendar.Width:= MinRect.Right - MinRect.Left;
  cCalendar.Height := MinRect.Bottom - MinRect.Top;

  if cCalendar.Width > PanelCalendar.Width then begin
     Dif:= cCalendar.Width - PanelCalendar.Width;
     PanelAlarm.Width := PanelAlarm.Width - Dif;
     PanelCalendar.Left:= PanelCalendar.Left - Dif;
     PanelCalendar.Width:= cCalendar.Width;
  end;
end;

procedure TForm_Alarm.FormShow(Sender: TObject);
var
  alarm, alarm_selected: TAlarm;
  I, iNewAlarm, iAlarmSelected: Integer;
  nodeNote: PVirtualNode;
  myNote: TNote;

  procedure AddAlarm (Alarm: TAlarm);
  var
     item : TListItem;
  begin
      item := Grid.Items.Add;
      UpdateAlarmOnGrid(alarm, item);
  end;

begin
   App.ApplyBiDiModeOnForm(Self);
   EnsureCalendarSupported;
   EnsureCalendarSize;

   ResetModifiedState();
   AlarmMng.CancelReminders(false);
   Button_Sound.Down:= KeyOptions.PlaySoundOnAlarm;
   if (FFilteredAlarmList.Count = 0) then begin
       Grid.Items.Clear;
       cIdentifier.Text := Format( GetRS(sAlrt01), [0] );
       EnableControls (false);
   end
   else begin
      alarm_selected:= AlarmSelected;
      Grid.Items.BeginUpdate;
      Grid.Items.Clear;

      FFilteredAlarmList.Sort(compareAlarms_selectedColumn);
      iNewAlarm:= -1;
      for I := 0 to FNumberAlarms - 1 do
      begin
        alarm:= TAlarm (FFilteredAlarmList[I]);
        AddAlarm (alarm);
        if alarm.AlarmReminder = 0 then
           iNewAlarm:= i;
      end;
      Grid.Items.EndUpdate;

      Grid.SetFocus;
      if Grid.ItemFocused = nil then
         Grid.ItemFocused:= Grid.Items[0];

      // select new alarm, if exists, or the alarm previously selected, if any
      if iNewAlarm >= 0 then
         Grid.Selected := Grid.Items[iNewAlarm]
      else begin
         i:= FFilteredAlarmList.IndexOf(alarm_selected);
         TrySelectItem(i);
      end;

      if (modeEdit = TShowSet) or (modeEdit = TShowNew) then begin
         txtSubject.Enabled:= true;
         txtSubject.SetFocus;
      end;
   end;

   ForceGetMonthInfo(ccalendar);
   FCalendarMonthChanged:= False;
end;


procedure TForm_Alarm.UpdateCaption;
var
  str: string;
  n: integer;
begin
    case FModeEdit of
        TShowReminders:         str:= GetRS(sAlrt03);
        TShowSet, TShowNew:     str:= GetRS(sAlrt02);
        TShowAll:               str:= GetRS(sAlrt04);
        TShowOverdue:           str:= GetRS(sAlrt05);
        TShowPending:           str:= GetRS(sAlrt06);
        TShowDiscarded:         str:= GetRS(sAlrt07);
        TShowAllWithDiscarded:  str:= GetRS(sAlrt04);
    end;
    if (cFilter.Text <> '') or (CB_FilterDates.ItemIndex <> 0) then
       str:= str + GetRS(sAlrt35);

    Caption:= Format(str, [FNumberAlarms]);
end;


//----------------------------------
//          Keyboard
//----------------------------------

procedure TForm_Alarm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_ESCAPE then begin
     if (modeEdit = TShowReminders) or (modeEdit = TShowAll) or (modeEdit = TShowPending) or (modeEdit = TShowAllWithDiscarded) then
        AlarmMng.CancelReminders(true);
     Close;
     end
  else
      if (key = 13) and (cFilter.Focused ) then begin
         ConfirmApplyPendingChanges();
         FilterAlarmList();
         FormShow(nil);
         cFilter.SetFocus;
      end;

end;


procedure TForm_Alarm.FormResize(Sender: TObject);
begin
   PanelCalendar.Visible := not (PanelAlarm.Width <=  PanelAlarm.Constraints.MinWidth);
   if Width < FORM_WIDTH then
      btnExpandWindow.Caption:= '>>'
   else
      btnExpandWindow.Caption:= '<<'

end;

procedure TForm_Alarm.btnExpandWindowClick(Sender: TObject);
begin
   if btnExpandWindow.Caption = '>>' then
      Width:= FORM_WIDTH + 5
   else
      Width:= Constraints.MinWidth;
end;


procedure TForm_Alarm.ShowDetails (Show: boolean);
begin
  if btnShowHideDetails.Caption = Char(218) then begin
     if Show then exit;
     btnShowHideDetails.Caption:= Char(217);
  end
  else begin
     if not Show then exit;
     btnShowHideDetails.Caption:= Char(218);
  end;

  PanelCalendar.Visible := Show and (PanelAlarm.Width >  PanelAlarm.Constraints.MinWidth);

  if not Show then begin
     pnlButtons.Top:= Panel.Height - pnlButtons.Height;
     Grid.Height:= Grid.Height + PanelAlarm.Height +5;
     PanelAlarm.BevelOuter:= bvNone;
  end
  else begin
     PanelAlarm.BevelOuter:= bvRaised;
     pnlButtons.Top:= -1;
     Grid.Height:= Grid.Height - PanelAlarm.Height -5;
  end;

end;


procedure TForm_Alarm.btnShowHideDetailsClick(Sender: TObject);
var
   DetailsShown: boolean;
begin
  if btnShowHideDetails.Caption = Char(218) then begin
     DetailsShown:= true;
  end
  else
     DetailsShown:= false;

  ShowDetails (not DetailsShown);
end;

//----------------------------------
//           Edition. General
//----------------------------------

procedure TForm_Alarm.CB_ShowModeChange(Sender: TObject);
var
  EnableRemoveButtons: boolean;
begin
    ConfirmApplyPendingChanges();

    EnableRemoveButtons:= false;

    case CB_ShowMode.ItemIndex of
        0: modeEdit:= TShowAll;
        1: modeEdit:= TShowPending;
        2: modeEdit:= TShowOverdue;
        3: modeEdit:= TShowDiscarded;
        4: modeEdit:= TShowAllWithDiscarded;
    end;

    FilterAlarmList();
    FormShow(nil);
end;


procedure TForm_Alarm.EnableControls (Value: Boolean);
var
   AllSelectedAlarmsAreDiscarded: boolean;
   AllSelectedAlarmsAreNotDiscarded: boolean;
   i: integer;
   alarm: TAlarm;
   ls: TListItem;
begin
   FInitializingControls:= FInitializingControls + 1;

   Today_5min.Enabled:= Value;
   Today_10min.Enabled:= Value;
   Today_15min.Enabled:= Value;
   Today_30min.Enabled:= Value;
   Today_1h.Enabled:= Value;
   Today_2h.Enabled:= Value;
   Today_3h.Enabled:= Value;
   Today_5h.Enabled:= Value;
   Today_8AM.Enabled:= Value;
   LblToday.Enabled:= Value;
   Today_12AM.Enabled:= Value;
   Today_3PM.Enabled:= Value;
   Today_6PM.Enabled:= Value;
   Today_8PM.Enabled:= Value;
   LblTomorrow.Enabled:= Value;
   Tomorrow_8AM.Enabled:= Value;
   Tomorrow_12AM.Enabled:= Value;
   Tomorrow_3PM.Enabled:= Value;
   Tomorrow_6PM.Enabled:= Value;
   Tomorrow_8PM.Enabled:= Value;

   PanelFormat.Enabled:= Value;

   alarm:= AlarmSelected;
   chk_Expiration.Enabled:= Value;
   if not Value or (Grid.SelCount > 1) or (alarm.ExpirationDate = 0) then
      chk_Expiration.Checked:= false
   else
      chk_Expiration.Checked:= true;

   CB_ExpirationDate.Enabled:= chk_Expiration.Checked;
   cExpirationTime.Enabled:=   chk_Expiration.Checked;
   CB_ExpirationTime.Enabled:= chk_Expiration.Checked;

   lblExpirationStatus.Visible := (Grid.SelCount = 1);
   lblReminderStatus.Visible   := (Grid.SelCount = 1);

   rb_FromNow.Enabled:= Value;
   rb_Before.Enabled:= Value and chk_Expiration.Checked;
   if not rb_Before.Enabled then
      rb_FromNow.Checked:= True;

   CB_ProposedIntervalReminder.Enabled:= Value;
   Button_Apply.Enabled:= Value;
   Button_Show.Enabled:= Value;
   txtSubject.Enabled:= Value;
   TB_Bold.Enabled:= Value;
   TB_Color.Enabled:= Value;
   TB_Hilite.Enabled:= Value;


    AllSelectedAlarmsAreDiscarded:= true;
    AllSelectedAlarmsAreNotDiscarded:= true;

    ls := Grid.Selected;
    while Assigned(ls) and (AllSelectedAlarmsAreDiscarded or AllSelectedAlarmsAreNotDiscarded) do
    begin
       alarm:= TAlarm(ls.Data);
       if alarm.Status= TAlarmDiscarded then
          AllSelectedAlarmsAreNotDiscarded:= false
       else
          AllSelectedAlarmsAreDiscarded:= false;
       ls := Grid.GetNextItem(ls, sdAll, [isSelected]);
    end;


   Button_Remove.Enabled:=     Value and AllSelectedAlarmsAreDiscarded;
   Button_Restore.Enabled:=    Value and AllSelectedAlarmsAreDiscarded;

   Button_Discard.Enabled:=    Value and AllSelectedAlarmsAreNotDiscarded;

   if (not Value) or AllSelectedAlarmsAreDiscarded then
      lblExpiration.Font.Color:= clBlack;

   if Value then
      DisableTimeButtonsInThePast
   else begin
      ReleaseTimeButtons;
      CB_ExpirationDate.DateTime:= now;
      cExpirationTime.Text := '';
      CB_ProposedIntervalReminder.Text := '';
      txtSubject.Text := '';
      cReminder.Text:= '';
      cReminder.Font.Color:= clBlack;
      TB_Bold.Down:= false;
      TB_Color.ActiveColor:= clWindowText;
      TB_Hilite.ActiveColor:= clWindow;
   end;

   FInitializingControls:= FInitializingControls - 1;
end;


procedure TForm_Alarm.SetModeEdit (Value: TShowMode);
var
  str: string;
  i: integer;
begin
    FModeEdit:= Value;

    if modeEdit <> TShowNew then begin
        i:= -1;
        case FModeEdit of
          TShowReminders: str:= '';
          TShowSet:       str:= '';
          TShowAll:       begin
                          str:= GetRS(sAlrt29);
                          i:= 0;
                          end;
          TShowPending:   begin
                          str:= GetRS(sAlrt27);
                          i:= 1;
                          end;
          TShowOverdue:   begin
                          str:= GetRS(sAlrt28);
                          i:= 2;
                          end;
          TShowDiscarded: begin
                          str:= '';
                          i:= 3;
                          end;
          TShowAllWithDiscarded:
                          begin
                          str:= GetRS(sAlrt30);
                          i:= 4;
                          end;

        end;
        CB_ShowMode.Hint:= str;
        CB_ShowMode.ItemIndex:= i;
    end;

    if assigned (AlarmMng.UnfilteredAlarmList) then begin
       AlarmMng.UnfilteredAlarmList.Free;
       AlarmMng.UnfilteredAlarmList:= nil;
    end;

    UpdateCaption;
end;

function TForm_Alarm.ChangesToApply: Boolean;
begin
     Result:= FExpirationDateModified or (FProposedReminder >= 0)
              or FSubjectModified or FBoldModified or FFontColorModified or FBackColorModified;
end;

procedure TForm_Alarm.ResetModifiedState;
begin
    FExpirationDateModified:= False;
    FSubjectModified:= False;
    FProposedReminder:= -1;
    FBoldModified:= False;
    FFontColorModified:= False;
    FBackColorModified:= False;
end;

// Return True if no cancel
function TForm_Alarm.ConfirmApplyPendingChanges(OfferCancel: boolean=false): boolean;
var
  ask: boolean;
  Buttons: TMsgDlgButtons;
  msgResult: integer;
begin
    ask:= not chk_ApplyOnExitChange.Checked;
    Result:= true;

    if ChangesToApply then begin
       buttons:= [mbYes,mbNo];
       if OfferCancel then
          buttons:= [mbYes,mbNo,mbCancel];

       msgResult:= mrYes;
       if (ask) then
          MsgResult:= App.DoMessageBox( GetRS(sAlrt19), mtConfirmation, Buttons, def1, 0, Handle );

       if MsgResult <> mrCancel then begin
         if MsgResult = mrYes then
            Button_ApplyClick(nil);
         ResetModifiedState;
       end
       else
          Result:= false;
    end;

       // Como consecuencia de DoMessageBox (no ocurre con MessageBox) al retornar de esa ventana modal parece como si no
       // estuviera el foco en el grid, pues la selecci�n se destaca en gris, no en azul. Sin embargo s� lo tiene realmente
       // Prefiero dejar de momento esto as� para que se pueda ver bien el mensaje, pues MessageBox no admite Unicode.
       // Al menos no con esta versi�n de Delphi (2006). Cuando pase a otra m�s avanzada (en breve) no habr� problema.
end;


procedure TForm_Alarm.ShowCommonProperties();
var
  Subject: string;
  Bold: boolean; 
  FontColor: TColor;
  backColor: TColor;
  Alarm: TAlarm;
  ls: TListItem;
begin
  Subject:= '';
  bold:= false;
  fontColor:= clWindowText;
  backColor:= clWindow;

  ls := Grid.Selected;
  if assigned(ls) then begin
     Subject:= TAlarm(ls.Data).AlarmNote;
     bold:= TAlarm(ls.Data).Bold;
     fontColor:= TAlarm(ls.Data).FontColor;
     backColor:= TAlarm(ls.Data).BackColor;
  end;

  while Assigned(ls) do
  begin
     alarm:= TAlarm(ls.Data);
     if alarm.AlarmNote <> Subject then
        Subject:= '';
     if alarm.Bold <> bold then
        bold:= false;
     if alarm.FontColor <> fontColor then
        fontColor:= clWindowText;
     if alarm.BackColor <> backColor then
        backColor:= clWindow;

     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);
  end;

  txtSubject.Text:= Subject;
  TB_Bold.Down:= bold;
  TB_Color.ActiveColor:= FontColor;
  TB_Hilite.ActiveColor:= BackColor;
end;


//-------------------------------------------
//     Unfiltered / Filtered    Alarm List
//-------------------------------------------

function TForm_Alarm.UnfilteredAlarmList: TAlarmList;
var
   I: Integer;
   alarm: TAlarm;
begin
   if not assigned(AlarmMng.UnfilteredAlarmList) then
   begin
       AlarmMng.UnfilteredAlarmList:= TAlarmList.Create;
       if modeEdit <> TShowAllWithDiscarded then
       begin
           case modeEdit of
                TShowAll:       AlarmMng.UnfilteredAlarmList.Assign(AlarmMng.AlarmList);
                TShowDiscarded: AlarmMng.UnfilteredAlarmList.Assign(AlarmMng.DiscardedAlarmList);
                TShowPending:
                     for I := 0 to AlarmMng.AlarmList.Count - 1 do begin
                        alarm:= AlarmMng.AlarmList[I];
                        if alarm.Pending then
                           AlarmMng.UnfilteredAlarmList.Add(alarm);
                     end;

                TShowOverdue:
                     for I := 0 to AlarmMng.AlarmList.Count - 1 do begin
                        alarm:= AlarmMng.AlarmList[I];
                        if alarm.Overdue then
                           AlarmMng.UnfilteredAlarmList.Add(alarm);
                     end;

                else
                    AlarmMng.UnfilteredAlarmList.Assign(AlarmMng.SelectedAlarmList);
           end;
       end
       else
       begin
           AlarmMng.UnfilteredAlarmList.Assign(AlarmMng.AlarmList);
           for I := 0 to AlarmMng.DiscardedAlarmList.Count - 1 do
              AlarmMng.UnfilteredAlarmList.Add( TAlarm (AlarmMng.DiscardedAlarmList[I]) );
       end;
   end;

   Result:= AlarmMng.UnfilteredAlarmList;
end;

procedure TForm_Alarm.FilterAlarmList();
var
   i: integer;
   alarm: TAlarm;
   myExpDate: TDateTime;
   text: string;
   Date, EndDate: TDateTime;
   FAuxAlarmList: TAlarmList;
begin
   text:= ansilowercase(cFilter.Text);
   Date:= cCalendar.Date;
   EndDate:= cCalendar.EndDate;

   cFilter.Tag := 0;

   FAuxAlarmList:= UnfilteredAlarmList;
   FFilteredAlarmList.Clear;

   if (text <> '') or (CB_FilterDates.ItemIndex <> 0) then begin   // 0 -> All Dates
       for I := 0 to FAuxAlarmList.Count - 1 do
       begin
          alarm:= TAlarm (FAuxAlarmList[I]);

          if (modeEdit in [TShowSet, TShowNew]) and (alarm.AlarmReminder = 0) then
              FFilteredAlarmList.Add(alarm)
          else
              if (text = '') or
                 (pos(text, ansilowercase(alarm.AlarmNote)) > 0) or
                 (assigned(alarm.NNode) and (pos(text, ansilowercase(alarm.NNode.GetNodeName(alarm.folder))) > 0) ) or
                 (pos(text, ansilowercase(alarm.folder.Name)) > 0) then begin

                 myExpDate:= RecodeTime(alarm.ExpirationDate, 0,0,0,0);
                 if (CB_FilterDates.ItemIndex = 0) or (myExpDate >= Date ) and (myExpDate <= EndDate ) then
                     FFilteredAlarmList.Add(alarm);
              end;

       end;

   end
   else
       FFilteredAlarmList.Assign(FAuxAlarmList);

   FNumberAlarms:= FFilteredAlarmList.Count;
   UpdateCaption;
end;



//----------------------------------
//          Action Buttons
//----------------------------------

procedure TForm_Alarm.Button_NewClick(Sender: TObject);
var
   alarm: TAlarm;
   ls: TListItem;
   folder: TKntFolder;
   NNode: TNoteNode;
   i: integer;
begin
    if ChangesToApply then begin
       ConfirmApplyPendingChanges();
       FilterAlarmList();
       FormShow(nil);
    end;

    ls := Grid.Selected;
    if assigned(ls) then begin
       folder:= TAlarm(ls.Data).folder;
       NNode:= TAlarm(ls.Data).NNode;
    end
    else begin
       folder:= ActiveFolder;
       NNode:= nil;
    end;

    alarm:= TAlarm.Create;
    alarm.NNode:= NNode;
    alarm.folder:= folder;
    alarm.Status:= TAlarmUnsaved;

    if modeEdit <> TShowNew then
       AlarmMng.SelectedAlarmList.Assign(Self.UnfilteredAlarmList);  // Make a copy over SelectedAlarmList
    AlarmMng.SelectedAlarmList.Add(alarm);

    // A change in modeEdit will trigger a change in CB_ShowMode, except with TShowNew:
    // CB_ShowMode will keep its value to resalt that the alarms visible comes from that selection, but we need to know
    // that actually we are creating a new alarm to show this alarm although it may not satisfy the filter criterium
    modeEdit:= TShowNew;

    FilterAlarmList;
    FormShow(nil);
end;

procedure TForm_Alarm.Button_ShowClick(Sender: TObject);
begin
     GridDblClick(nil);
end;

procedure TForm_Alarm.Button_ApplyClick(Sender: TObject);
var
  alarm: TAlarm;
  ls: TListItem;
  ls2: TListItem;
  i: integer;
  
    procedure ApplyChangesOnAlarm(ls: TListItem; alarm: TAlarm);
    begin
        if FExpirationDateModified then
           alarm.ExpirationDate:= NewExpirationDate;

        if FProposedReminder > 0 then
           alarm.AlarmReminder:= FProposedReminder;

        if FSubjectModified then
           alarm.AlarmNote := txtSubject.Text;

        if FBoldModified then
           alarm.Bold:= TB_Bold.Down;

        if FFontColorModified then
           alarm.FontColor:= TB_Color.ActiveColor;

        if FBackColorModified then
           alarm.BackColor:= TB_Hilite.ActiveColor;


        if Alarm.Status= TAlarmUnsaved then begin
           alarm.Status:= TAlarmNormal;
           AlarmMng.AddAlarm(alarm);
           end
        else
           AlarmMng.ModifyAlarm(alarm);
            
        UpdateAlarmOnGrid(alarm, ls);
    end;

begin
    if not ChangesToApply then exit;

    if (FProposedReminder >= 0) and (FProposedReminder < Now) then begin
       CB_ProposedIntervalReminder.SetFocus;
       App.ErrorPopup( GetRS(sAlrt14));
       exit;
    end;

    for i:= Grid.Items.Count -1 downto 0 do begin
        ls:= Grid.Items[i];
        alarm:= TAlarm(ls.Data);
        if ls.Selected then
           ApplyChangesOnAlarm(ls, alarm);
           
        if alarm.Empty then begin
           AlarmMng.RemoveAlarm (alarm, true);
           HideAlarm(ls);
        end
    end;

    App.FileSetModified;

    if ( (FProposedReminder > now) and ((modeEdit = TShowReminders) or (modeEdit = TShowPending)) ) or
       ( FExpirationDateModified and (FNewExpirationDate > now) and (modeEdit = TShowOverdue) )
    then begin
        ls2 := Grid.Selected;
        while Assigned(ls2) do begin
           alarm:= TAlarm(ls2.Data);
           Self.UnfilteredAlarmList.Remove(alarm);
           ls2 := Grid.GetNextItem(ls2, sdAll, [isSelected]);
        end;

      if (modeEdit = TShowReminders) and (Self.UnfilteredAlarmList.Count = 0) then begin
         ResetModifiedState;
         Close;
      end;
    end;

  ResetModifiedState;           // => ChangesToApply -> False

  FilterAlarmList;
  FormShow(nil);
end;

procedure TForm_Alarm.Button_DiscardClick(Sender: TObject);
var
  alarm: TAlarm;
  ls, lsWork: TListItem;
  i: integer;
begin
  if Grid.SelCount > 1 then
     if ( App.DoMessageBox( Format( GetRS(sAlrt15), [Grid.SelCount] ), mtWarning, [mbYes,mbNo], def1, 0, Handle ) <> mrYes ) then exit;

  i:= -1;
  ls := Grid.Selected;
  while Assigned(ls) do begin
     lsWork:= ls;
     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);

     alarm:= TAlarm(lsWork.Data);     
     i:= Grid.Items.IndexOf(lsWork);
     if alarm.Empty then begin
        AlarmMng.RemoveAlarm (alarm, true);
        HideAlarm(lsWork);
     end
     else begin
        App.FileSetModified;
        AlarmMng.DiscardAlarm (alarm, (modeEdit = TShowAllWithDiscarded));
        if modeEdit <> TShowAllWithDiscarded then
           HideAlarm(lsWork);
     end;
  end;

  if (modeEdit = TShowReminders) and (Grid.Items.Count = 0) then
     Close

  else begin
     ForceGetMonthInfo(ccalendar);
     FCalendarMonthChanged:= False;

     Grid.SetFocus;
     if modeEdit <> TShowAllWithDiscarded then
        TrySelectItem(i)
     else begin
        FilterAlarmList;
        FormShow(nil);
     end;
  end;

end;


procedure TForm_Alarm.Button_RestoreClick(Sender: TObject);
var
  alarm: TAlarm;
  ls, lsWork: TListItem;
  i: integer;
begin
   if Grid.SelCount > 1 then
      if ( App.DoMessageBox( Format( GetRS(sAlrt17), [Grid.SelCount] ), mtWarning, [mbYes,mbNo], def1, 0, Handle ) <> mrYes ) then exit;

  i:= -1;
  ls := Grid.Selected;
  while Assigned(ls) do
  begin
     lsWork:= ls;
     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);

     alarm:= TAlarm(lsWork.Data);
     if alarm.Status = TAlarmDiscarded then begin
        App.FileSetModified;
        i:= Grid.Items.IndexOf(lsWork);
        AlarmMng.RestoreAlarm (alarm, (modeEdit = TShowAllWithDiscarded));
        if modeEdit <> TShowAllWithDiscarded then
           HideAlarm(lsWork);
     end;
  end;

  ForceGetMonthInfo(ccalendar);
  FCalendarMonthChanged:= False;
  Grid.SetFocus;
  if modeEdit <> TShowAllWithDiscarded then
     TrySelectItem(i)
  else begin
     FilterAlarmList;
     FormShow(nil);
  end;
end;

procedure TForm_Alarm.Button_RemoveClick(Sender: TObject);
var
  alarm: TAlarm;
  ls, lsWork: TListItem;
  i: integer;
  strConfirm: string;
begin
  if Grid.SelCount > 1 then
     strConfirm := GetRS(sAlrt16)
  else
     strConfirm := GetRS(sAlrt18);

  if ( App.DoMessageBox( Format( strConfirm, [Grid.SelCount] ), mtWarning, [mbYes,mbNo], def1, 0, Handle ) <> mrYes ) then exit;

  i:= -1;
  ls := Grid.Selected;
  while Assigned(ls) do begin
     lsWork:= ls;
     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);

     alarm:= TAlarm(lsWork.Data);
     if alarm.Status = TAlarmDiscarded then begin
        App.FileSetModified;
        i:= Grid.Items.IndexOf(lsWork);
        AlarmMng.RemoveAlarm (alarm, true);
        HideAlarm(lsWork);
     end;
  end;

  ForceGetMonthInfo(ccalendar);
  FCalendarMonthChanged:= False;
  Grid.SetFocus;
  TrySelectItem(i);
end;


procedure TForm_Alarm.Button_SelectAllClick(Sender: TObject);
begin
    Grid.SelectAll;
end;

procedure TForm_Alarm.Button_SoundClick(Sender: TObject);
begin
    KeyOptions.PlaySoundOnAlarm:= Button_Sound.Down;
end;


//----------------------------------
//          Alarm Subject
//----------------------------------

procedure TForm_Alarm.txtSubjectChange(Sender: TObject);
begin
   if FInitializingControls > 0 then exit;
   FSubjectModified:= True;
end;


//----------------------------------
//          Expiration/Event Date
//----------------------------------

procedure TForm_Alarm.chk_ApplyOnExitChangeClick(Sender: TObject);
begin
   if FInitializingControls = 0 then
      FApplyOnExitChangeBAK:= chk_ApplyOnExitChange.Checked;
end;

procedure TForm_Alarm.chk_ExpirationClick(Sender: TObject);
var
   enabled: boolean;
begin
   if FInitializingControls > 0 then exit;

   FInitializingControls:= FInitializingControls + 1;
   enabled:= chk_Expiration.checked;

   CB_ExpirationDate.Enabled:= enabled;
   CB_ExpirationTime.Enabled:= enabled;
   cExpirationTime.Enabled:= enabled;
   rb_Before.Enabled:= enabled;

   if enabled then begin
      rb_Before.Checked:= enabled;
      NewExpirationDate:= Now;
   end
   else begin
      rb_FromNow.Checked:= true;
      NewExpirationDate:= 0;
   end;

   FInitializingControls:= FInitializingControls - 1;
end;

procedure TForm_Alarm.CB_ExpirationDateChange(Sender: TObject);
begin
    NewExpirationDate:= GetSelectedExpirationDate;
end;

procedure TForm_Alarm.cExpirationTimeExit(Sender: TObject);
begin
   cExpirationTime.Text:= TimeRevised(cExpirationTime.Text);
   NewExpirationDate:= GetSelectedExpirationDate;
end;

procedure TForm_Alarm.CB_ExpirationTimeDropDown(Sender: TObject);
var
   t: TDateTime;
   selectedIndex, i: integer;
   strTime: string;
begin
    strTime:= TimeRevised(cExpirationTime.Text);
    cExpirationTime.Text:= strTime;
    try
       t:= StrToTime(strTime);
    except
       t:= StrToTime('00:00');
    end;

    selectedIndex:= 0;
    for i:= CB_ExpirationTime.Items.Count-1 downto 0 do
         if t >= StrToTime(CB_ExpirationTime.Items[i]) then begin
            selectedIndex:= i;
            break;
         end;
    CB_ExpirationTime.ItemIndex:= selectedIndex;
end;

procedure TForm_Alarm.CB_ExpirationTimeCloseUp(Sender: TObject);
begin
    if CB_ExpirationTime.Focused  then
       cExpirationTime.SetFocus;
    cExpirationTime.SelStart:= length(cExpirationTime.Text);
    cExpirationTime.SelLength:= 0;
end;

procedure TForm_Alarm.CB_ExpirationTimeSelect(Sender: TObject);
begin
    cExpirationTime.Text := CB_ExpirationTime.Text;
    cExpirationTime.SelStart:= length(cExpirationTime.Text);
    cExpirationTime.SelLength:= 0;
end;



function TForm_Alarm.GetSelectedExpirationDate: TDateTime;
var
   myTime: TDateTime;
begin
   try
      myTime:= StrToTime(cExpirationTime.Text);
      Result:= RecodeTime(CB_ExpirationDate.DateTime, HourOf(myTime), MinuteOf(myTime), 0, 0);
   except
      Result:= 0;
   end;
end;

procedure TForm_Alarm.SetNewExpirationDate(Instant: TDateTime);
var
   myTime: TDateTime;
begin
    FNewExpirationDate:= Instant;
    FExpirationDateModified:= True;
    ShowExpirationDate(Instant);
    ShowReminderStatus(FReminder);
    UpdateProposedReminderDate;
end;

procedure TForm_Alarm.ShowExpirationDate(Instant: TDateTime);
begin
   if Instant = 0 then begin
      CB_ExpirationDate.DateTime := Now;
      cExpirationTime.Text := '';
   end
   else begin
      CB_ExpirationDate.DateTime := Instant;
      cExpirationTime.Text := FormatDateTime('hh:nn', Instant);
   end;
   ShowExpirationStatus(Instant);
end;

procedure TForm_Alarm.ShowExpirationStatus(Instant: TDateTime);
var
   IntervalStr, FormatStr: string;
begin
     if Instant <= 0 then
       lblExpirationStatus.Caption:= ''

     else begin
         IntervalStr:= GetTimeIntervalStr(Instant, Now);
         if Instant < now then begin
            FormatStr:= GetRS(sAlrt36);
            lblExpirationStatus.Font.Color:= clRed;
            end
         else begin
            FormatStr:= GetRS(sAlrt37);
            lblExpirationStatus.Font.Color:= clGray;
         end;

         lblExpirationStatus.Caption:= Format(FormatStr, [IntervalStr]);
     end;
end;



//----------------------------------
//     Reminder Instant
//----------------------------------

procedure TForm_Alarm.ShowReminderDate(Instant: TDateTime);
var
   str: string;
begin
     str:= ' ';
     if Instant <> 0 then
          str:= FormatAlarmInstant(Instant);

    cReminder.Text := str;
    ShowReminderStatus(Instant);
end;

procedure TForm_Alarm.ShowReminderStatus(Instant: TDateTime);
var
   showAsBefore: Boolean;
   IntervalStr: string;
begin
     if Instant <= 0 then
       lblReminderStatus.Caption:= ''

     else begin

         if Instant < now then begin
            IntervalStr:= GetTimeIntervalStr(Instant, Now);
            lblReminderStatus.Caption:= Format(GetRS(sAlrt36), [IntervalStr]);
            lblReminderStatus.Font.Color:= clRed;
            end
         else begin
            if (NewExpirationDate = 0) or (Instant > NewExpirationDate) or (Abs(Instant - now) <= Abs(Instant - NewExpirationDate)) then begin
                IntervalStr:= GetTimeIntervalStr(Instant, Now);
                lblReminderStatus.Caption:= Format(GetRS(sAlrt37), [IntervalStr]);
            end
            else begin
                IntervalStr:= GetTimeIntervalStr(Instant, NewExpirationDate);
                lblReminderStatus.Caption:= Format(GetRS(sAlrt38), [IntervalStr]);
            end;
            if (NewExpirationDate <> 0) and (NewExpirationDate > Now) and (Instant > NewExpirationDate) then
               lblReminderStatus.Font.Color:= clRed
            else
               lblReminderStatus.Font.Color:= clGray;
         end;
     end;
end;


procedure TForm_Alarm.CleanProposedReminderPanel();
begin
    lblProposedReminder.Caption:= '';
    CB_ProposedIntervalReminder.Text:= '';
    ReleaseTimeButtons;
    if not chk_Expiration.Checked then
        rb_FromNow.Checked:= true;

    FProposedReminder:= -1;
end;

procedure TForm_Alarm.UpdateProposedReminderDate (KeepInterval: boolean = false);
var
   ReferenceDate: TDateTime;
begin
   if CB_ProposedIntervalReminder.Text = '' then exit;

   if rb_FromNow.Checked then
      ReferenceDate:= Now
   else
      ReferenceDate:= NewExpirationDate;

   SetProposedReminderDate(ReferenceDate, CB_ProposedIntervalReminder.Text, (rb_FromNow.Checked = False), KeepInterval);
end;

procedure TForm_Alarm.SetProposedReminderDate(ReferenceDate: TDateTime; IntervalStr: string; BeforeReference: Boolean; KeepInterval: boolean= false);
begin
    if IntervalStr <> '' then begin
        try
            FProposedReminder:= IncStrInterval(ReferenceDate, IntervalStr, not BeforeReference);
            if not KeepInterval then
               IntervalStr:= GetTimeIntervalStr(ReferenceDate, FProposedReminder);  // To clean, interpret the value.  Example: "2m" --> "2 minutes"
        except
            FProposedReminder:= 0;
        end;

        ShowProposedReminderDate(FProposedReminder, IntervalStr, ReferenceDate, KeepInterval);
    end
    else
        CleanProposedReminderPanel;
end;


procedure TForm_Alarm.ShowProposedReminderDate(ReminderDate: TDateTime; IntervalStr: string; ReferenceDate: TDateTime; KeepInterval: Boolean = false);
begin
     FInitializingControls:= FInitializingControls + 1;

     if ReminderDate = 0 then begin
        lblProposedReminder.Caption:= '';
        ReleaseTimeButtons;
        end
     else begin
        lblProposedReminder.Caption:= FormatAlarmInstant(ReminderDate);
        if ReminderDate < now then
           lblProposedReminder.Font.Color:= clRed
        else
           lblProposedReminder.Font.Color:= clBlue;

        CB_ProposedIntervalReminder.Text:= IntervalStr;
        PressEquivalentTimeButton(ReminderDate, ReferenceDate);
     end;

   FInitializingControls:= FInitializingControls - 1;
end;


procedure TForm_Alarm.CB_ProposedIntervalReminderChange(Sender: TObject);
begin
     if FInitializingControls > 0 then exit;

     UpdateProposedReminderDate(true);
     FIntervalDirectlyChanged:= true;
end;


procedure TForm_Alarm.CB_ProposedIntervalReminderExit(Sender: TObject);
var
   Reminder: TDateTime;
begin
    if FIntervalDirectlyChanged then begin
       UpdateProposedReminderDate;
       FIntervalDirectlyChanged:= False;
    end;
end;

procedure TForm_Alarm.rb_FromNowClick(Sender: TObject);
begin
    if FInitializingControls > 0 then exit;
    UpdateProposedReminderDate
end;


procedure TForm_Alarm.ReleaseTimeButtons();
begin
   if FOptionSelected <> nil then begin
      TToolbarButton97(FOptionSelected).Down:= false;
      FOptionSelected:= nil;
   end;
end;

// Disable time buttons that imply a notify in the past
procedure TForm_Alarm.DisableTimeButtonsInThePast ();

   procedure DisableButton(button: TObject);
   begin
      TToolbarButton97(button).Enabled:= false;
      if button = FOptionSelected then begin
         TToolbarButton97(FOptionSelected).Down:= false;
         FOptionSelected:= nil;
      end;
   end;

begin

   if incHour(Today(), 8) <= now then
      DisableButton(Today_8AM);
   if incHour(Today(), 12) <= now then
      DisableButton(Today_12AM);
   if incHour(Today(), 15) <= now then
      DisableButton(Today_3PM);
   if incHour(Today(), 18) <= now then
      DisableButton(Today_6PM);
   if incHour(Today(), 20) <= now then
      DisableButton(Today_8PM);     
end;


procedure TForm_Alarm.PressEquivalentTimeButton(ReminderDate: TDateTime; ReferenceDate: TDateTime);
var
  difFromNow: int64;
begin
   ReleaseTimeButtons;

   difFromNow:= DateTimeDiff(ReferenceDate, ReminderDate);

   if      (difFromNow >= 4*60) and (difFromNow <= 6*60) then FOptionSelected:= Today_5min
   else if (difFromNow >= 9*60) and (difFromNow <= 11*60) then FOptionSelected:= Today_10min
   else if (difFromNow >= 13.5*60) and (difFromNow <= 16.5*60)then FOptionSelected:= Today_15min
   else if (difFromNow >= 25.5*60) and (difFromNow <= 33.5*60) then FOptionSelected:= Today_30min
   else if (difFromNow >= 54.5*60) and (difFromNow <= 65.5*60) then FOptionSelected:= Today_1h
   else if (difFromNow >= 114.5*60) and (difFromNow <= 126.5*60) then FOptionSelected:= Today_2h
   else if (difFromNow >= 169.5*60) and (difFromNow <= 190.5*60) then FOptionSelected:= Today_3h
   else if (difFromNow >= 284.5*60) and (difFromNow <= 315.5*60) then FOptionSelected:= Today_5h
   else if DateTimeDiff(incHour(Today(), 8), ReminderDate) < 60*15 then FOptionSelected:= Today_8AM
   else if DateTimeDiff(incHour(Today(), 12), ReminderDate) < 60*15 then FOptionSelected:= Today_12AM
   else if DateTimeDiff(incHour(Today(), 15), ReminderDate) < 60*15 then FOptionSelected:= Today_3PM
   else if DateTimeDiff(incHour(Today(), 18), ReminderDate) < 60*15 then FOptionSelected:= Today_6PM
   else if DateTimeDiff(incHour(Today(), 20), ReminderDate) < 60*15 then FOptionSelected:= Today_8PM
   else if DateTimeDiff(incHour(Tomorrow(), 8), ReminderDate) < 60*20 then FOptionSelected:= Tomorrow_8AM
   else if DateTimeDiff(incHour(Tomorrow(), 12), ReminderDate) < 60*20 then FOptionSelected:= Tomorrow_12AM
   else if DateTimeDiff(incHour(Tomorrow(), 15), ReminderDate) < 60*20 then FOptionSelected:= Tomorrow_3PM
   else if DateTimeDiff(incHour(Tomorrow(), 18), ReminderDate) < 60*20 then FOptionSelected:= Tomorrow_6PM
   else if DateTimeDiff(incHour(Tomorrow(), 20), ReminderDate) < 60*20 then FOptionSelected:= Tomorrow_8PM;

   if FOptionSelected <> nil then begin
      TToolbarButton97(FOptionSelected).Down:= true;
   end;
end;


procedure TForm_Alarm.Today_5minClick(Sender: TObject);
var
   minInc: integer;
   Alarm: TDateTime;
   myNote: TNote;
   setFromNow: boolean;
   IntervalStr: string;
begin
    if Sender = nil then exit;

    if not TToolbarButton97(Sender).Down then begin
       TToolbarButton97(Sender).Down:= true;
       exit;
    end;

    setFromNow:= false;
    minInc:= 0;
    Alarm := 0;
    FOptionSelected:= Sender;

    if Today_5min.Down then
       minInc:= 5
    else if Today_10min.Down then
       minInc:= 10
    else if Today_15min.Down then
       minInc:= 15
    else if Today_30min.Down then
       minInc:= 30
    else if Today_1h.Down then
       minInc:= 60
    else if Today_2h.Down then
       minInc:= 120
    else if Today_3h.Down then
       minInc:= 180
    else if Today_5h.Down then
       minInc:= 300;


    if minInc <> 0 then
       Alarm:= incMinute(now(), minInc)

    else begin
        setFromNow:= true;

        if Today_8AM.Down then
           Alarm:= incHour(Today(), 8)
        else if Today_12AM.Down then
           Alarm:= incHour(Today(), 12)
        else if Today_3PM.Down then
           Alarm:= incHour(Today(), 15)
        else if Today_6PM.Down then
           Alarm:= incHour(Today(), 18)
        else if Today_8PM.Down then
           Alarm:= incHour(Today(), 20)
        else if Tomorrow_8AM.Down then
           Alarm:= incHour(Tomorrow(), 8)
        else if Tomorrow_12AM.Down then
           Alarm:= incHour(Tomorrow(), 12)
        else if Tomorrow_3PM.Down then
           Alarm:= incHour(Tomorrow(), 15)
        else if Tomorrow_6PM.Down then
           Alarm:= incHour(Tomorrow(), 18)
        else if Tomorrow_8PM.Down then
           Alarm:= incHour(Tomorrow(), 20);

    end;

    IntervalStr:= GetTimeIntervalStr(Now, Alarm);
    CB_ProposedIntervalReminder.Text:= IntervalStr;
    if SetFromNow and (not rb_FromNow.Checked) then begin
       FInitializingControls:= FInitializingControls + 1;
       rb_FromNow.Checked := true;
       FInitializingControls:= FInitializingControls - 1;
    end;

    if rb_FromNow.Checked then begin
        FProposedReminder:= Alarm;
        ShowProposedReminderDate(Alarm, IntervalStr, Now)
        end
    else
        SetProposedReminderDate(NewExpirationDate, IntervalStr, True);

    CB_ProposedIntervalReminder.SetFocus;
    FIntervalDirectlyChanged:= False;
end;

procedure TForm_Alarm.Today_5minDblClick(Sender: TObject);
begin
    Today_5minClick(Sender);
    Button_ApplyClick(nil);
end;

//--------------------------------------------------
//       Alarm Style: Bold, Font color, Back color
//--------------------------------------------------

procedure TForm_Alarm.TB_BoldClick(Sender: TObject);
begin
   FBoldModified:= True;
   txtSubject.SetFocus;
end;

procedure TForm_Alarm.TB_ColorClick(Sender: TObject);
begin
   FFontColorModified:= True;
   txtSubject.SetFocus;
end;

procedure TForm_Alarm.TB_HiliteClick(Sender: TObject);
begin
   FBackColorModified:= True;
   txtSubject.SetFocus;
end;



//----------------------------------
//          Text Filter
//----------------------------------

procedure TForm_Alarm.cFilterChange(Sender: TObject);
begin
    cFilter.Tag := 1;
end;

procedure TForm_Alarm.cFilterExit(Sender: TObject);
begin
    if cFilter.Tag = 1 then begin
       ConfirmApplyPendingChanges();
       FilterAlarmList();
       FormShow(nil);
    end;
end;

procedure TForm_Alarm.Button_ClearFilterClick(Sender: TObject);
begin
    if cFilter.Text <> '' then begin
       cFilter.Text:= '';

      FilterAlarmList();
      FormShow(nil);
    end;
end;


//----------------------------------
//          Calendar
//----------------------------------

procedure TForm_Alarm.CB_FilterDatesChange(Sender: TObject);
begin
   ConfirmApplyPendingChanges();

   if CB_FilterDates.ItemIndex = 0 then begin
      cCalendar.EndDate:= cCalendar.Date;
      FilterAlarmList();
      FormShow(nil);
   end
   else
      cCalendarClick(nil);

   FCalendarMonthChanged:= false;
end;


procedure TForm_Alarm.cCalendarClick(Sender: TObject);
var
   year, month, day : Word;
   beginDate, endDate: TDateTime;
   dayOfWeek: Word;
begin
   ConfirmApplyPendingChanges();

   beginDate:= cCalendar.Date;
   endDate:= cCalendar.EndDate;

   DecodeDate(beginDate, year, month, day);
   case CB_FilterDates.ItemIndex of
        0: endDate:= beginDate;         // AllDates
        2: begin        // Week
           dayOfWeek:= DayOfTheWeek(beginDate);
           endDate:= incDay(beginDate, 7 -dayOfWeek);
           beginDate:= incDay(beginDate, -dayOfWeek+1);
           end;
        3: begin        // Month
           beginDate:= EncodeDate(year, month, 1);
           endDate:= EncodeDate(year, month, DaysInAMonth(year, month));
           end;
   end;

   cCalendar.EndDate:= cCalendar.Date;
   cCalendar.Date:= beginDate;
   cCalendar.EndDate:= endDate;

   if CB_FilterDates.ItemIndex <> 0 then begin
      FilterAlarmList();
      FormShow(nil);
   end
   else if not FCalendarMonthChanged then begin
      CB_FilterDates.ItemIndex:= 1;
      CB_FilterDatesChange(nil);
   end;
   FCalendarMonthChanged:= false;
end;

procedure TForm_Alarm.cCalendarExit(Sender: TObject);
begin
   FCalendarMonthChanged:= false;
end;

procedure TForm_Alarm.cCalendarGetMonthInfo(Sender: TObject; Month: Cardinal;
  var MonthBoldInfo: Cardinal);
var
   days: array of LongWord;
   i, x, day: integer;
   allDays: array[0..31] of boolean;
   alarm: TAlarm;
   dateCalendar: string;
   myList: TAlarmList;
begin
  FCalendarMonthChanged:= true;

  myList:= Self.UnfilteredAlarmList;

  for i:= 0 to 31 do
      allDays[i]:= false;

   dateCalendar:=  IntToStr(Month) + FormatDateTime('yyyy', cCalendar.Date );
   for I := 0 to myList.Count - 1 do
   begin
      alarm:= TAlarm (myList[I]);
      if FormatDateTime('Myyyy', alarm.ExpirationDate ) = dateCalendar then begin
         day:= StrToInt(FormatDateTime( 'd', alarm.ExpirationDate ));
         allDays[day]:= true;
      end;
   end;

   SetLength(days, 31);
   x:= 0;
   for i:= 0 to 31 do
      if allDays[i] then begin
         days[x]:= i;
         x:= x + 1;
      end;      

   if x > 0 then begin
     SetLength(days, x);
     cCalendar.BoldDays(days, MonthBoldInfo);
   end;
end;



//----------------------------------
//            Grid
//----------------------------------

procedure TForm_Alarm.GridEnter(Sender: TObject);
begin
   ConfirmApplyPendingChanges();
end;

function TForm_Alarm.AlarmSelected: TAlarm;
begin
   Result:= nil;
   if assigned(Grid.Selected) then
      Result:= TAlarm(Grid.Selected.Data);
end;

procedure TForm_Alarm.GridSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
   alarm: TAlarm;
   Subject: string;
begin
  FInitializingControls:= FInitializingControls + 1;
  try
 
    ResetModifiedState;
    CleanProposedReminderPanel;

    alarm:= AlarmSelected;
    if not assigned(alarm) then begin
       cIdentifier.Text := Format( GetRS(sAlrt01), [0] );
       EnableControls (false);
       if not Selected then
          modeEdit:= TShowAll;
       chk_ApplyOnExitChange.Checked:= FApplyOnExitChangeBAK;
       chk_ApplyOnExitChange.Enabled:= true;
    end
    else begin
         EnableControls (true);
         
         if Grid.SelCount > 1 then begin                   // Several alarms selected
             cIdentifier.Text:= Format( GetRS(sAlrt01), [Grid.SelCount] );
             ShowCommonProperties();
             FReminder:= 0;
             ShowReminderDate(0);
             FApplyOnExitChangeBAK:= chk_ApplyOnExitChange.Checked;
             chk_ApplyOnExitChange.Checked:= false;
             chk_ApplyOnExitChange.Enabled:= false;
         end
         else begin
             chk_ApplyOnExitChange.Checked:= FApplyOnExitChangeBAK;
             chk_ApplyOnExitChange.Enabled:= true;

             if assigned(alarm.NNode) then
                cIdentifier.Text := alarm.Folder.Name + ' / ' + alarm.NNode.GetNodeName(alarm.folder)
             else
                cIdentifier.Text := alarm.Folder.Name;

             ShowExpirationDate(alarm.ExpirationDate);
             FNewExpirationDate:= alarm.ExpirationDate;
             FReminder:= alarm.AlarmReminder;
             ShowReminderDate(alarm.AlarmReminder);

             if alarm.Status <> TAlarmUnsaved then begin             // Existent ALARM
                txtSubject.Text:= alarm.AlarmNote;
                TB_Bold.Down:= alarm.Bold;
                TB_Color.ActiveColor:= alarm.FontColor;
                TB_Hilite.ActiveColor:= alarm.BackColor;
             end
             else begin                                              // NEW ALARM
                txtSubject.Text:= '';
                TB_Bold.Down:= false;
                TB_Color.ActiveColor:= clWindowText;
                TB_Hilite.ActiveColor:= clWindow;
                SetProposedReminderDate(Now, '5 ' + GetRS(STR_minutes), false);
             end;
         end;

    end;
    
  finally
    FInitializingControls:= FInitializingControls - 1;
  end;
    
end;

procedure TForm_Alarm.TrySelectItem(i: integer);
var
  n: integer;
begin
     // Select next alarm, if exists. Otherwise select the previous one
     n:= Grid.Items.Count;
     if i < 0 then begin
        if n >= 1 then
           Grid.Selected:= Grid.Items[0]
        end
     else if i <= n-1 then
        Grid.Selected := Grid.Items[i]
     else if n > 0 then
        Grid.Selected := Grid.Items[n-1];
end;


procedure TForm_Alarm.HideAlarm (ls: TListItem);
var
   i: integer;
begin
   i:= Grid.Items.IndexOf(ls);
   Grid.Items.Delete(i);

   FNumberAlarms:= FNumberAlarms -1;
   UpdateCaption;
end;


procedure TForm_Alarm.GridDblClick(Sender: TObject);
var
  Location: TLocation;
begin
    Location:= CreateLocation(AlarmSelected);
    if assigned(Location) then
       JumpToLocation (Location);
end;

procedure TForm_Alarm.GridColumnClick(Sender: TObject; Column: TListColumn);
var
  index: integer;
  oldSortedColumn: TSortedColumn;
begin
    index:= Column.Index;

    oldSortedColumn:= SortedColumn;
    if (index = 0)  then
       SortedColumn := TColumnAlarmNote
    else if (index <= 2) then
       SortedColumn := TColumnReminder
    else if (index <= 4) then
       SortedColumn := TColumnExpiration
    else if (index = 5)  then
       SortedColumn := TColumnNoteName
    else if (index = 6)  then
       SortedColumn := TColumnNodeName
    else if (index = 7) then
       SortedColumn := TColumnDiscarded;

    if oldSortedColumn = SortedColumn then
       AscOrder:= AscOrder * -1;

    FormShow(nil);
end;


procedure TForm_Alarm.UpdateAlarmOnGrid(alarm: TAlarm; item: TListItem);
  var
     NodeName, FolderName: string;
     Discarded: string;
  begin
      if assigned(alarm.NNode) then
         NodeName:= alarm.NNode.GetNodeName(alarm.folder)
      else
         NodeName:= '';
      FolderName:= alarm.Folder.Name;
      Discarded:= '';
      if alarm.Status = TAlarmDiscarded then Discarded := 'D';

      item.Data:= Alarm;
      item.subitems.Clear;
      item.caption := StringReplace(alarm.AlarmNote, _CRLF, '��', [rfReplaceAll]);
      item.subitems.Add( FormatDate(alarm.AlarmReminder) );
      item.subitems.Add( FormatDateTime('hh:nn', alarm.AlarmReminder) );
      item.subitems.Add( FormatDate(alarm.ExpirationDate));
      if alarm.ExpirationDate <> 0 then
          item.subitems.Add( FormatDateTime('hh:nn', alarm.ExpirationDate) )
      else
          item.subitems.Add( '');
      item.subitems.Add( FolderName );
      item.subitems.Add( NodeName);
      item.subitems.Add( Discarded);
end;


procedure TForm_Alarm.GridAdvancedCustomDrawItem(
   Sender: TCustomListView;
   Item: TListItem;
   State: TCustomDrawState;
   Stage: TCustomDrawStage;
   var DefaultDraw: Boolean) ;
begin
    Sender.Canvas.Brush.Color:= TAlarm(item.Data).BackColor;
    Sender.Canvas.Font.Color := TAlarm(item.Data).FontColor;
    if TAlarm(item.Data).Bold then
       Sender.Canvas.Font.Style:= [fsBold];   
end;

procedure TForm_Alarm.GridAdvancedCustomDrawSubItem(
  Sender: TCustomListView; Item: TListItem; SubItem: Integer;
  State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
    Sender.Canvas.Brush.Color:= TAlarm(item.Data).BackColor;
    Sender.Canvas.Font.Color := TAlarm(item.Data).FontColor;
    if (TAlarm(item.Data).Bold) and (subitem>=3) and (subitem <=4)  then
        Sender.Canvas.Font.Style:= [fsBold]
    else
        Sender.Canvas.Font.Style:= [];
       
    if TAlarm(item.Data).AlarmReminder = 0 then
       Sender.Canvas.Font.Style:= [fsItalic, fsBold];
end;



//----------------------------------
//     Copy to the CLIPBOARD
//----------------------------------

procedure TForm_Alarm.TB_ClipCapClick(Sender: TObject);
begin
    CopyAlarmList();
end;

function TForm_Alarm.CreateLocation(alarm: TAlarm): TLocation;
var
  folder: TKntFolder;
begin
    Result:= nil;

    if assigned(alarm) then begin
      folder:= alarm.folder;

      Result := TLocation.Create;
      Result.FileName := ActiveFile.FileName;
      Result.FolderID := alarm.folder.ID;
      Result.CaretPos := 0;
      Result.SelLength := 0;
      if assigned(alarm.NNode) then
         Result.NNodeGID := alarm.NNode.GID
      else
         Result.NNodeGID := 0;
    end;
end;


procedure TForm_Alarm.CopyAlarmList();
var
  alarm: TAlarm;
  ls: TListItem;
  i, pos: integer;
  ColorsTbl: array of TColor;
  iColorsTbl: integer;
  rtf, rtfColorsTbl: string;

  function GetPositionInRTFTable(Color: TColor): integer;
  var
      i: integer;
  begin
      Result:= -1;  // By default, the color is not available

      for I := 0 to length(ColorsTbl) - 1 do
           if ColorsTbl[i] = Color then
           begin
              Result:= i;
              exit;
           end
  end;

  procedure ProcessColor(Color: TColor; IgnoreIfEqual: TColor);
  begin
     if (Color <> IgnoreIfEqual) then
     begin
         pos:= GetPositionInRTFTable(Color);
         if pos < 0  then
         begin
            if iColorsTbl = length(ColorsTbl) then begin
               SetLength(ColorsTbl, iColorsTbl + 10);
               end;
            ColorsTbl[iColorsTbl]:= Color;
            iColorsTbl:= iColorsTbl + 1;
            rtfColorsTbl:= rtfColorsTbl + GetRTFColor(Color);
         end;
     end;
  end;

  //  References: Table definitions in RTF: http://www.biblioscape.com/rtf15_spec.htm#Heading40
  function GenerateHeader(): string;
    begin
        Result:= '\trowd\trgaph30 \cellx500\cellx1500\cellx3500\cellx4900\cellx5600\cellx9100\cellx10600\cellx11250\cellx11800 \pard\b\cf0\intbl ' +
             'Lnk \cell ' +
             'Folder \cell ' +
             'Note \cell ' +
             'Expiration \cell ' +
             'Time \cell ' +
             '\qc\ Subject \cell ' +
             'Reminder \cell ' +
             'Time \cell ' +
             'Disc. \cell ' +
             '\row\b0' +#13#10;
  end;

  function GenerateAlarmRow(alarm: TAlarm): string;
    var
       NodeName, KntFolderName: string;
       Discarded: string;
       colorFont, bgColor: string;
       pos: integer;
       hyperlink: string;
       location: TLocation;
    const
       CELL = '\cell ';
    begin
        if assigned(alarm.NNode) then
           NodeName:= alarm.NNode.GetNodeName(alarm.folder)
        else
           NodeName:= '';
        KntFolderName:= alarm.Folder.Name;
        Discarded:= '';
        if alarm.Status = TAlarmDiscarded then Discarded := 'D';

        location:= CreateLocation(alarm);
        hyperlink:= '';
        if assigned(location) then begin
            hyperlink:= Format('{\field{\*\fldinst{HYPERLINK "%s"}}{\fldrslt{\cf1\ul lnk}}}\cf0\ulnone',
                                 [URLToRTF(BuildKntURL(location), false )])
        end;

        //colorFont:= ColorToString(alarm.BackColor);
        colorFont:= '\cf0';
        pos:= GetPositionInRTFTable(alarm.FontColor);
        if pos > 0 then
            colorFont:= '\cf' + IntToStr(pos);

        bgColor:= '';
        pos:= GetPositionInRTFTable(alarm.BackColor);
        if pos > 0 then
           bgColor:= '\clcbpat' + IntToStr(pos);

        Result:= Format('\trowd\trgaph30 %s\cellx500%s\cellx1500%s\cellx3500%s\cellx4900%s\cellx5600%s\cellx9100%s\cellx10600%s\cellx11250\cellx11800' +
                        '\pard\intbl%s ',
                       [bgColor,bgColor,bgColor,bgColor,bgColor,bgColor,bgColor,bgColor,bgColor,  colorFont ]);

        Result:= Result + hyperlink + CELL;                                       // Hyperlink
        Result:= Result + TextToUseInRTF(KntFolderName) + CELL;                   // FolderName
        Result:= Result + TextToUseInRTF(NodeName) + CELL;                        // NodeName

        if alarm.Bold then
           Result:= Result + '\b ';

        Result:= Result + FormatDate(alarm.ExpirationDate) + CELL;                // ExpirationDate
        if alarm.ExpirationDate <> 0 then
           Result:= Result + FormatDateTime('hh:nn', alarm.ExpirationDate) + CELL // ExpirationTime
        else
           Result:= Result + CELL;

        Result:= Result + TextToUseInRTF(alarm.AlarmNote) + CELL;                 // AlarmNote

        if alarm.Bold then
           Result:= Result + '\b0 ';

        Result:= Result + FormatDateTime('dd/MMM/yyyy', alarm.AlarmReminder) + CELL;  // ReminderDate
        Result:= Result + FormatDateTime('hh:nn', alarm.AlarmReminder) + CELL;        // ReminderTime
        Result:= Result + Discarded + CELL;                                           // Discarded
        Result:= Result + '\row' + _CRLF;
  end;


begin
  rtf:= '';

  // Prepare table of colors
  rtfColorsTbl:= '{\colortbl ;\red0\green0\blue255;';
  SetLength(ColorsTbl, 10);
  ColorsTbl[0]:= -1;
  ColorsTbl[1]:= RGB(0,0,255);
  iColorsTbl:= 2;

  ls := Grid.Selected;
  while Assigned(ls) do
  begin
     alarm:= TAlarm(ls.Data);
     ProcessColor(alarm.FontColor, clWindowText);
     ProcessColor(alarm.BackColor, clWindow);
     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);
  end;

  // Include RTF representation of selected alarms
  ls := Grid.Selected;
  while Assigned(ls) do begin
     alarm:= TAlarm(ls.Data);
     rtf:= rtf + GenerateAlarmRow(alarm);
     ls := Grid.GetNextItem(ls, sdAll, [isSelected]);
  end;

  if rtf <> '' then begin
     rtf:= Format('{\rtf1\ansi\pard\fs18 %s} %s%s}', [rtfColorsTbl, generateHeader(), rtf]);
     Clipboard.AsRTF:= rtf;
  end;

end;



initialization
  AscOrder:= 1;
  SortedColumn := TColumnExpiration;
end.