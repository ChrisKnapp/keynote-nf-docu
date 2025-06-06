object Form_NewKntFolder: TForm_NewKntFolder
  Left = 382
  Top = 333
  HelpContext = 13
  ActiveControl = Combo_TabName
  BorderStyle = bsDialog
  Caption = 'New folder'
  ClientHeight = 153
  ClientWidth = 326
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  ShowHint = True
  OnActivate = FormActivate
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnHelp = FormHelp
  OnKeyDown = FormKeyDown
  TextHeight = 13
  object Label1: TLabel
    Left = 6
    Top = 26
    Width = 49
    Height = 13
    Alignment = taRightJustify
    AutoSize = False
    Caption = '&Name:'
    FocusControl = Combo_TabName
  end
  object Label2: TLabel
    Left = 6
    Top = 56
    Width = 49
    Height = 13
    Alignment = taRightJustify
    AutoSize = False
    Caption = '&Icon:'
  end
  object Button_OK: TButton
    Left = 15
    Top = 111
    Width = 75
    Height = 25
    Hint = 'Accept settings'
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    OnClick = Button_OKClick
  end
  object Button_Cancel: TButton
    Left = 95
    Top = 111
    Width = 75
    Height = 25
    Hint = 'Close dialog box'
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
    OnClick = Button_CancelClick
  end
  object Combo_TabName: TComboBox
    Left = 60
    Top = 21
    Width = 237
    Height = 21
    Hint = 'Enter folder name'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnChange = Combo_TabNameChange
    OnKeyPress = Combo_TabNameKeyPress
  end
  object Button_Properties: TButton
    Left = 216
    Top = 111
    Width = 84
    Height = 25
    Hint = 'Edit properties of the new folder'
    Caption = '&Properties'
    TabOrder = 4
    OnClick = Button_PropertiesClick
  end
  object Combo_Icons: TGFXComboBox
    Left = 60
    Top = 54
    Width = 80
    Height = 22
    Hint = 'Select icon for folder'
    Extended = False
    TabOrder = 1
  end
end
