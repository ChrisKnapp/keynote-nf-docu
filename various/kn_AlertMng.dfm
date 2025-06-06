object Form_Alarm: TForm_Alarm
  Left = 330
  Top = 208
  HelpContext = 76
  Margins.Left = 0
  ClientHeight = 540
  ClientWidth = 954
  Color = clBtnFace
  Constraints.MinHeight = 527
  Constraints.MinWidth = 628
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  ShowHint = True
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnHelp = FormHelp
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  OnShow = FormShow
  DesignSize = (
    954
    540)
  TextHeight = 13
  object lblFilter: TLabel
    Left = 601
    Top = 8
    Width = 67
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    AutoSize = False
    Caption = 'Filter:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitLeft = 635
  end
  object Button_ClearFilter: TToolbarButton97
    Left = 850
    Top = 6
    Width = 17
    Height = 21
    Hint = 'Clear Filter'
    Anchors = [akTop, akRight]
    Caption = 'X'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ImageIndex = 0
    ParentFont = False
    OnClick = Button_ClearFilterClick
    ExplicitLeft = 884
  end
  object TntLabel2: TLabel
    Left = 10
    Top = 9
    Width = 93
    Height = 13
    AutoSize = False
    Caption = 'Show mode:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Button_Sound: TToolbarButton97
    Left = 906
    Top = 4
    Width = 25
    Height = 24
    Hint = 'Enable or disable sound when alarm goes off'
    AllowAllUp = True
    Anchors = [akTop, akRight]
    GroupIndex = 1
    Flat = False
    ImageIndex = 50
    Images = Form_Main.IMG_Toolbar
    OnClick = Button_SoundClick
    ExplicitLeft = 940
  end
  object TB_ClipCap: TToolbarButton97
    Left = 880
    Top = 4
    Width = 25
    Height = 24
    Hint = 'Copy selected alarms to the clipboard'
    Anchors = [akTop, akRight]
    Flat = False
    ImageIndex = 18
    Images = Form_Main.IMG_Toolbar
    OnClick = TB_ClipCapClick
    ExplicitLeft = 914
  end
  object Panel: TPanel
    Left = 1
    Top = 134
    Width = 933
    Height = 405
    Anchors = [akLeft, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 133
    ExplicitWidth = 929
    DesignSize = (
      933
      405)
    object lblCalNotSup: TLabel
      Left = 744
      Top = 254
      Width = 173
      Height = 14
      Anchors = [akRight, akBottom]
      Caption = 'System Calendar not supported'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Visible = False
      ExplicitLeft = 763
    end
    object PanelAlarm: TPanel
      Left = 6
      Top = 39
      Width = 725
      Height = 359
      Anchors = [akLeft, akRight, akBottom]
      Constraints.MinWidth = 585
      TabOrder = 2
      ExplicitWidth = 721
      DesignSize = (
        725
        359)
      object lblExpiration: TLabel
        Left = 12
        Top = 150
        Width = 141
        Height = 13
        Caption = 'Event or Expiration Time:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblExpirationStatus: TLabel
        Left = 124
        Top = 194
        Width = 201
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblReminder: TLabel
        Left = 336
        Top = 151
        Width = 87
        Height = 13
        Caption = 'Next Reminder:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblReminderStatus: TLabel
        Left = 348
        Top = 194
        Width = 119
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Today_8AM: TToolbarButton97
        Left = 41
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '8 AM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object LblToday: TLabel
        Left = 71
        Top = 306
        Width = 122
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Today at:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Today_12AM: TToolbarButton97
        Left = 81
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '12 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_3PM: TToolbarButton97
        Left = 121
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '3 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_6PM: TToolbarButton97
        Left = 162
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '6 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_8PM: TToolbarButton97
        Left = 203
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '8 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object LblTomorrow: TLabel
        Left = 257
        Top = 306
        Width = 200
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = 'Tomorrow at:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Tomorrow_8AM: TToolbarButton97
        Left = 256
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '8 AM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Tomorrow_12AM: TToolbarButton97
        Left = 297
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '12 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Tomorrow_3PM: TToolbarButton97
        Left = 338
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '3 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Tomorrow_6PM: TToolbarButton97
        Left = 379
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '6 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Tomorrow_8PM: TToolbarButton97
        Left = 421
        Top = 327
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '8 PM'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_5min: TToolbarButton97
        Left = 42
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '5 min'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_10min: TToolbarButton97
        Left = 95
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '10 min'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_15min: TToolbarButton97
        Left = 148
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '15 min'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_30min: TToolbarButton97
        Left = 202
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '30 min'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_1h: TToolbarButton97
        Left = 255
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '1 h'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_2h: TToolbarButton97
        Left = 309
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '2 h'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_3h: TToolbarButton97
        Left = 364
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '3 h'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object Today_5h: TToolbarButton97
        Left = 419
        Top = 276
        Width = 38
        Height = 21
        AllowAllUp = True
        GroupIndex = 1
        Caption = '5 h'
        ImageIndex = 37
        OldDisabledStyle = True
        RepeatInterval = 101
        ShowBorderWhenInactive = True
        OnClick = Today_5minClick
        OnDblClick = Today_5minDblClick
      end
      object TntLabel3: TLabel
        Left = 12
        Top = 219
        Width = 114
        Height = 13
        Caption = 'Proposed Reminder:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = cl3DDkShadow
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblProposedReminder: TLabel
        Left = 138
        Top = 219
        Width = 249
        Height = 13
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object CB_ExpirationTime: TComboBox
        Left = 263
        Top = 170
        Width = 62
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        TabStop = False
        OnCloseUp = CB_ExpirationTimeCloseUp
        OnDropDown = CB_ExpirationTimeDropDown
        OnSelect = CB_ExpirationTimeSelect
      end
      object cExpirationTime: TEdit
        Left = 266
        Top = 172
        Width = 40
        Height = 16
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnExit = cExpirationTimeExit
      end
      object CB_ExpirationDate: TDateTimePicker
        Left = 41
        Top = 170
        Width = 218
        Height = 21
        Checked = False
        DateFormat = dfLong
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Visible = False
        OnChange = CB_ExpirationDateChange
      end
      object chk_Expiration: TCheckBox
        Left = 20
        Top = 171
        Width = 17
        Height = 17
        TabOrder = 3
        OnClick = chk_ExpirationClick
      end
      object cReminder: TEdit
        Left = 343
        Top = 172
        Width = 115
        Height = 19
        TabStop = False
        Ctl3D = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentCtl3D = False
        ParentFont = False
        ReadOnly = True
        TabOrder = 4
        Text = 'cReminder'
      end
      object CB_ProposedIntervalReminder: TComboBox
        Left = 41
        Top = 243
        Width = 95
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        TabStop = False
        OnChange = CB_ProposedIntervalReminderChange
        OnExit = CB_ProposedIntervalReminderExit
      end
      object rb_Before: TRadioButton
        Left = 156
        Top = 242
        Width = 100
        Height = 26
        Caption = 'Before event'
        TabOrder = 6
        OnClick = rb_FromNowClick
      end
      object rb_FromNow: TRadioButton
        Left = 263
        Top = 242
        Width = 116
        Height = 26
        Caption = 'From now'
        TabOrder = 7
        OnClick = rb_FromNowClick
      end
      object Button_Apply: TButton
        Left = 626
        Top = 172
        Width = 84
        Height = 25
        Anchors = [akTop, akRight]
        Caption = '&Apply'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
        OnClick = Button_ApplyClick
        ExplicitLeft = 622
      end
      object chk_ApplyOnExitChange: TCheckBox
        Left = 633
        Top = 202
        Width = 85
        Height = 27
        Hint = 
          'Automatically apply pending changes on exit (ex. pressing ESC) a' +
          'nd on selection change'#13#10#13#10'Note: Double Click on Reminder buttons' +
          ', also apply changes'
        Anchors = [akTop, akRight]
        Caption = 'Apply Auto'
        Checked = True
        State = cbChecked
        TabOrder = 9
        WordWrap = True
        OnClick = chk_ApplyOnExitChangeClick
        ExplicitLeft = 629
      end
      object txtSubject: TMemo
        Left = 9
        Top = 40
        Width = 701
        Height = 87
        TabStop = False
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 10
        WantTabs = True
        OnChange = txtSubjectChange
        ExplicitWidth = 697
      end
      object cIdentifier: TEdit
        Left = 10
        Top = 12
        Width = 698
        Height = 22
        TabStop = False
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clBtnFace
        Ctl3D = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentCtl3D = False
        ParentFont = False
        ReadOnly = True
        TabOrder = 11
        Text = 'NODO'
        ExplicitWidth = 694
      end
      object PanelFormat: TPanel
        Left = 604
        Top = 128
        Width = 119
        Height = 23
        Anchors = [akTop, akRight]
        BevelOuter = bvNone
        TabOrder = 12
        ExplicitLeft = 600
        object TB_Bold: TToolbarButton97
          Left = 0
          Top = 0
          Width = 24
          Height = 22
          AllowAllUp = True
          GroupIndex = 5
          ImageIndex = 0
          Images = Form_Main.IMG_Format
          RepeatInterval = 101
          OnClick = TB_BoldClick
        end
        object TB_Color: TColorBtn
          Left = 34
          Top = 0
          Width = 34
          Height = 22
          Hint = 'Click to change text color'
          ActiveColor = clBlack
          TargetColor = clBlack
          Flat = True
          DropDownFlat = True
          AutomaticColor = clWindowText
          IsAutomatic = True
          OnClick = TB_ColorClick
          AutoBtnCaption = 'Default color'
          OtherBtnCaption = '&Other colors...'
          RegKey = 'General Frenetics\KeyNote\ColorBtn1'
          DDArrowWidth = 12
        end
        object TB_Hilite: TColorBtn
          Left = 74
          Top = 0
          Width = 34
          Height = 22
          Hint = 'Click to add or remove highlight'
          ActiveColor = clInfoBk
          TargetColor = clBlack
          Flat = True
          DropDownFlat = True
          AutomaticColor = clWindow
          IsAutomatic = True
          OnClick = TB_HiliteClick
          GlyphType = gtBackground
          AutoBtnCaption = 'No Highlight'
          OtherBtnCaption = '&Other colors...'
          RegKey = 'General Frenetics\KeyNote\ColorBtn2'
          DDArrowWidth = 12
        end
      end
      object btnExpandWindow: TButton
        Left = 677
        Top = 330
        Width = 33
        Height = 22
        Hint = 
          'Change width, to include or not full grid size and calendar filt' +
          'er'
        Anchors = [akTop, akRight]
        Caption = '<<'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 13
        OnClick = btnExpandWindowClick
        ExplicitLeft = 673
      end
    end
    object PanelCalendar: TPanel
      Left = 736
      Top = 44
      Width = 195
      Height = 204
      Anchors = [akRight, akBottom]
      BevelEdges = [beRight]
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 732
      object cCalendar: TMonthCalendar
        Left = 0
        Top = 37
        Width = 191
        Height = 160
        MultiSelect = True
        Date = 45623.000000000000000000
        EndDate = 45623.904912233800000000
        TabOrder = 0
        Visible = False
        OnClick = cCalendarClick
        OnExit = cCalendarExit
        OnGetMonthInfo = cCalendarGetMonthInfo
      end
      object CB_FilterDates: TComboBox
        Left = 1
        Top = 5
        Width = 188
        Height = 21
        Style = csDropDownList
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnChange = CB_FilterDatesChange
      end
    end
    object pnlButtons: TPanel
      Left = 2
      Top = -1
      Width = 933
      Height = 37
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 929
      DesignSize = (
        933
        37)
      object Button_Remove: TButton
        Left = 753
        Top = 2
        Width = 84
        Height = 25
        Hint = 'Remove selected alarms (only if discarded)'
        Anchors = [akTop, akRight]
        Caption = '&Remove'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnClick = Button_RemoveClick
        ExplicitLeft = 749
      end
      object Button_Restore: TButton
        Left = 846
        Top = 2
        Width = 84
        Height = 25
        Hint = 'Restore the discarded alarms'
        Anchors = [akTop, akRight]
        Caption = 'Res&tore'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnClick = Button_RestoreClick
        ExplicitLeft = 842
      end
      object Button_Show: TButton
        Left = 5
        Top = 2
        Width = 84
        Height = 25
        Hint = 'Show location of alarm'
        Caption = '&Show'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = Button_ShowClick
      end
      object Button_New: TButton
        Left = 192
        Top = 2
        Width = 84
        Height = 25
        Hint = 
          'Create new alarm (in the same node/folder that the item selected' +
          ' or in the active folder, if no one is selected)'
        Caption = '&New'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = Button_NewClick
      end
      object Button_Discard: TButton
        Left = 98
        Top = 2
        Width = 84
        Height = 25
        Hint = 'Discard selected alarms  (remove on empty alarms)'
        Caption = '&Discard'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = Button_DiscardClick
      end
      object Button_SelectAll: TButton
        Left = 294
        Top = 2
        Width = 84
        Height = 25
        Caption = '&Select All'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = Button_SelectAllClick
      end
      object btnShowHideDetails: TButton
        Left = 384
        Top = 2
        Width = 21
        Height = 25
        Hint = 'Hide or show details of selected alarm(s)'
        Caption = #218
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Symbol'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 6
        OnClick = btnShowHideDetailsClick
      end
    end
  end
  object Grid: TListView
    Left = 8
    Top = 31
    Width = 926
    Height = 98
    Align = alCustom
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Subject'
        Width = 273
      end
      item
        Caption = 'Reminder Date'
        Width = 86
      end
      item
        Caption = 'Time'
        Width = 49
      end
      item
        Caption = 'Expirat./Start  Date'
        Width = 108
      end
      item
        Caption = 'Time'
      end
      item
        Caption = 'Folder'
        Width = 103
      end
      item
        Caption = 'Note'
        Width = 203
      end
      item
        Caption = 'Disc.'
        Width = 35
      end>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    GridLines = True
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    TabOrder = 2
    ViewStyle = vsReport
    OnAdvancedCustomDrawItem = GridAdvancedCustomDrawItem
    OnAdvancedCustomDrawSubItem = GridAdvancedCustomDrawSubItem
    OnColumnClick = GridColumnClick
    OnDblClick = GridDblClick
    OnEnter = GridEnter
    OnSelectItem = GridSelectItem
    ExplicitWidth = 922
    ExplicitHeight = 97
  end
  object cFilter: TEdit
    Left = 674
    Top = 5
    Width = 174
    Height = 21
    Anchors = [akTop, akRight]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnChange = cFilterChange
    OnExit = cFilterExit
    ExplicitLeft = 670
  end
  object CB_ShowMode: TComboBox
    Left = 103
    Top = 6
    Width = 146
    Height = 21
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnChange = CB_ShowModeChange
  end
end
