object SnippetsForm: TSnippetsForm
  Left = 225
  Top = 170
  Width = 504
  Height = 329
  ActiveControl = ListBoxCodeSnippets
  Caption = 'CodeSnippets'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 185
    Top = 0
    Width = 3
    Height = 302
    Cursor = crHSplit
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 302
    Align = alLeft
    TabOrder = 0
    DesignSize = (
      185
      302)
    object ListBoxCodeSnippets: TListBox
      Left = 8
      Top = 8
      Width = 169
      Height = 261
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 13
      Sorted = True
      TabOrder = 0
      OnClick = ListBoxCodeSnippetsClick
      OnDblClick = ListBoxCodeSnippetsDblClick
    end
    object ButtonPaste: TBitBtn
      Left = 8
      Top = 272
      Width = 75
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = '&Paste'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
  object MemoCodeSnippet: TMemo
    Left = 188
    Top = 0
    Width = 308
    Height = 302
    Align = alClient
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object TimerSelection: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerSelectionTimer
    Left = 136
    Top = 16
  end
end
