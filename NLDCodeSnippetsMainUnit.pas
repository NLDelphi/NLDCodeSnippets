unit NLDCodeSnippetsMainUnit;

interface

uses
  Classes, ToolsAPI, Menus,
  NLDCodeSnippetsForm;

type
  TMDHCodeSnippetsWizard = class(TNotifierObject, IOTAWizard)
  private
    FToolsMenu: TMenuItem;
    FCodeSnippetsMenuItem: TMenuItem;
    FCodeSnippetFolder: string;
    FCopySnippetShortcut: TShortCut;
    FPasteSnippetShortcut: TShortCut;
    FKeyboardBinding: Integer;
    FSnippetsForm: TSnippetsForm;
    procedure ReadSettings;
    procedure WriteSettings;
    procedure CopyCode(EditBuffer: IOTAEditBuffer);
    procedure CopySelectedCode(Sender: TObject);
    procedure PasteCode(EditBuffer: IOTAEditBuffer);
    procedure PasteCodeSnippet(Sender: TObject);
    procedure ShowOptionsForm(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    // IOTAWizard interface methods (required for all wizards/experts)
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
  end;

  TMDHKeyboardBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    FOwner: TMDHCodeSnippetsWizard;
    FCopySnippetShortcut: TShortCut;
    FPasteSnippetShortcut: TShortCut;
    procedure CopySnippet(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
    procedure PasteSnippet(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
  public
    constructor Create(AOwner: TMDHCodeSnippetsWizard);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);

    property CopySnippetShortcut: TShortCut read FCopySnippetShortcut write FCopySnippetShortcut;
    property PasteSnippetShortcut: TShortCut read FPasteSnippetShortcut write FPasteSnippetShortcut;
  end;

procedure Register;

implementation

uses
  Windows, Controls, Dialogs, SysUtils, Registry,
  NLDCodeSnippetsOptionsForm;

procedure Register;
begin
  RegisterPackageWizard(TMDHCodeSnippetsWizard.Create);
end;

constructor TMDHCodeSnippetsWizard.Create;
var
  vMainMenu: TMainMenu;
  vIndex: Integer;
  vNewMenu: TMenuItem;
  vKeyboardBinding: TMDHKeyboardBinding;
begin
  inherited Create;

  // For creating files with random numbers
  Randomize;

  ReadSettings;

  // find Delphi's main menu
  vMainMenu := (BorlandIDEServices as INTAServices).MainMenu;
  // find Tools
  for vIndex := 0 to vMainMenu.Items.Count - 1 do begin
    if AnsiSameCaption(vMainMenu.Items[vIndex].Caption, 'Tools') then begin
      FToolsMenu := vMainMenu.Items[vIndex];
      System.Break;
    end;
  end;

  FCodeSnippetsMenuItem := TMenuItem.Create(FToolsMenu);
  FCodeSnippetsMenuItem.Caption := '&CodeSnippets';

  vNewMenu := TMenuItem.Create(FCodeSnippetsMenuItem);
  vNewMenu.Caption := '&Copy selected code to snippets library';
  vNewMenu.OnClick := CopySelectedCode;
  FCodeSnippetsMenuItem.Add(vNewMenu);

  vNewMenu := TMenuItem.Create(FCodeSnippetsMenuItem);
  vNewMenu.Caption := '&Paste code snippet at cursor';
  vNewMenu.OnClick := PasteCodeSnippet;
  FCodeSnippetsMenuItem.Add(vNewMenu);

  vNewMenu := TMenuItem.Create(FCodeSnippetsMenuItem);
  vNewMenu.Caption := '-';
  FCodeSnippetsMenuItem.Add(vNewMenu);

  vNewMenu := TMenuItem.Create(FCodeSnippetsMenuItem);
  vNewMenu.Caption := 'Options';
  vNewMenu.OnClick := ShowOptionsForm;
  FCodeSnippetsMenuItem.Add(vNewMenu);

  // find first separator
  for vIndex := 0 to FToolsMenu.Count - 1 do begin
    if FToolsMenu.Items[vIndex].IsLine then begin
      FToolsMenu.Insert(vIndex, FCodeSnippetsMenuItem);
      System.Break;
    end;
  end;

  vKeyboardBinding := TMDHKeyboardBinding.Create(Self);
  vKeyboardBinding.CopySnippetShortcut := FCopySnippetShortcut;
  vKeyboardBinding.PasteSnippetShortcut := FPasteSnippetShortcut;
  FKeyboardBinding := (BorlandIDEServices as IOTAKeyboardServices).AddKeyboardBinding(vKeyboardBinding);

  FSnippetsForm := TSnippetsForm.Create(nil);
  FSnippetsForm.GetCodeSnippetLibrary(FCodeSnippetFolder);
end;

destructor TMDHCodeSnippetsWizard.Destroy;
var
  vIndex: Integer;
begin
  FSnippetsForm.Hide;
  FreeAndNil(FSnippetsForm);
  (BorlandIDEServices as IOTAKeyboardServices).RemoveKeyboardBinding(FKeyboardBinding);
  vIndex := 0;
  while vIndex < FToolsMenu.Count do begin
    if AnsiSameCaption(FToolsMenu.Items[vIndex].Caption, 'CodeSnippets') then
      FToolsMenu.Remove(FToolsMenu.Items[vIndex])
    else
      Inc(vIndex);
  end;
  FCodeSnippetsMenuItem.Free;
  inherited Destroy;
end;

procedure TMDHCodeSnippetsWizard.Execute;
begin
  MessageDlg('CodeSnippets', mtInformation, [mbOk], 0);
end;

function TMDHCodeSnippetsWizard.GetIDString: string;
begin
  Result := 'MDH.CodeSnippets';
end;

function TMDHCodeSnippetsWizard.GetName: string;
begin
  Result := 'CodeSnippets';
end;

function TMDHCodeSnippetsWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TMDHCodeSnippetsWizard.ShowOptionsForm(Sender: TObject);
var
  vKeyboardBinding: TMDHKeyboardBinding;
begin
  OptionsForm := TOptionsForm.Create(nil);
  try
    OptionsForm.HotKeyCopy.HotKey := FCopySnippetShortcut;
    OptionsForm.HotKeyPaste.HotKey := FPasteSnippetShortcut;
    OptionsForm.EditFolder.Text := FCodeSnippetFolder;
    if OptionsForm.ShowModal = mrOk then begin
      FCopySnippetShortcut := OptionsForm.HotKeyCopy.HotKey;
      FPasteSnippetShortcut := OptionsForm.HotKeyPaste.HotKey;
      FCodeSnippetFolder := OptionsForm.EditFolder.Text;
      WriteSettings;
      (BorlandIDEServices as IOTAKeyboardServices).RemoveKeyboardBinding(FKeyboardBinding);
      vKeyboardBinding := TMDHKeyboardBinding.Create(Self);
      vKeyboardBinding.CopySnippetShortcut := FCopySnippetShortcut;
      vKeyboardBinding.PasteSnippetShortcut := FPasteSnippetShortcut;
      FKeyboardBinding := (BorlandIDEServices as IOTAKeyboardServices).AddKeyboardBinding(vKeyboardBinding);
    end;
  finally
    FreeAndNil(OptionsForm);
  end;
end;

procedure TMDHCodeSnippetsWizard.ReadSettings;
var
  vRegRoot: string;
  vReg: TRegIniFile;
begin
  vRegRoot := (BorlandIDEServices as IOTAServices).GetBaseRegistryKey;
  vReg := TRegIniFile.Create(KEY_READ);
  try
    vReg.RootKey := HKEY_CURRENT_USER;
    if vReg.OpenKey(vRegRoot, False) then begin
      try
        FCopySnippetShortcut := TextToShortCut(vReg.ReadString('MDHCodeSnippets', 'CopyShortcut', 'Ctrl+Shift+C'));
      except
        FCopySnippetShortcut := TextToShortCut('Ctrl+Shift+C');
      end;
      try
        FPasteSnippetShortcut := TextToShortCut(vReg.ReadString('MDHCodeSnippets', 'PasteShortcut', 'Ctrl+Shift+V'));
      except
        FPasteSnippetShortcut := TextToShortCut('Ctrl+Shift+V');
      end;
      FCodeSnippetFolder := vReg.ReadString('MDHCodeSnippets', 'Folder', '');
    end;
  finally
    vReg.Free;
  end;
end;

procedure TMDHCodeSnippetsWizard.WriteSettings;
var
  vRegRoot: string;
  vReg: TRegIniFile;
begin
  vRegRoot := (BorlandIDEServices as IOTAServices).GetBaseRegistryKey;
  vReg := TRegIniFile.Create(KEY_WRITE);
  try
    vReg.RootKey := HKEY_CURRENT_USER;
    if vReg.OpenKey(vRegRoot, False) then begin
      vReg.WriteString('MDHCodeSnippets', 'CopyShortcut', ShortCutToText(FCopySnippetShortcut));
      vReg.WriteString('MDHCodeSnippets', 'PasteShortcut', ShortCutToText(FPasteSnippetShortcut));
      vReg.WriteString('MDHCodeSnippets', 'Folder', FCodeSnippetFolder);
    end;
  finally
    vReg.Free;
  end;
end;

procedure TMDHCodeSnippetsWizard.CopyCode(EditBuffer: IOTAEditBuffer);
var
  vText: string;
  vCodeSnippetName: string;
  vSnippetFile: TFileStream;
  vFileName: string;
  vHeader: string;
begin
  try
    // Exit if nothing is selected
    if not EditBuffer.EditBlock.IsValid then Exit;

    // Check if the code snippet folder still exists
    if FCodeSnippetFolder = '' then
    begin
      MessageDlg('Please set the folder for code snippets in the CodeSnippets Options form.', mtError, [mbOk], 0);
      Exit;
    end;
    if not DirectoryExists(FCodeSnippetFolder) then
    begin
      MessageDlg('The folder for code snippets doesn''t exists.', mtError, [mbOk], 0);
      Exit;
    end;

    // Get the selected text
    vText := EditBuffer.EditBlock.Text;

    // Ask the name for this code snippet
    vCodeSnippetName := '';
    if InputQuery('CodeSnippets', 'Name for this code snippet:', vCodeSnippetName) then
    begin
      vHeader := '['+vCodeSnippetName+']'#13#10;
      repeat
        vFileName := IncludeTrailingPathDelimiter(FCodeSnippetFolder)+'code'+Format('%.4d', [Random(10000)])+'.txt';
      until not FileExists(vFileName);
      vSnippetFile := TFileStream.Create(vFileName, fmCreate or fmShareExclusive);
      try
        vSnippetFile.WriteBuffer(vHeader[1], Length(vHeader));
        vSnippetFile.WriteBuffer(vText[1], Length(vText));
      finally
        vSnippetFile.Free;
      end;
    end;

    FSnippetsForm.AddSnippet(vCodeSnippetName, ExtractFileName(vFileName));
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOk], 0);
  end;
end;

procedure TMDHCodeSnippetsWizard.CopySelectedCode(Sender: TObject);
var
  vEditorServices: IOTAEditorServices;
  vEditView: IOTAEditView;
begin
  try
    vEditorServices := BorlandIDEServices as IOTAEditorServices;
    // Get the top-most view where the user is working.
    vEditView := vEditorServices.TopView;
    // Exit if no edit window exists
    if vEditView = nil then Exit;
    // Exit if nothing is selected
    if not vEditView.Block.IsValid then Exit;
    // Copy the selected text to a snippet file
    CopyCode(vEditView.Buffer);
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOk], 0);
  end;
end;

procedure TMDHCodeSnippetsWizard.PasteCode(EditBuffer: IOTAEditBuffer);
var
  vWriter: IOTAEditWriter;
  CursorPos, TopPos: TOTAEditPos;
  BlockStart, BlockAfter: TOTACharPos;
  StartPos, EndPos: Integer;
  vText: string;
  vSourceEditor: IOTASourceEditor;
begin
  if FSnippetsForm.ShowModal = mrOk then
  begin
    vText := FSnippetsForm.SelectedText;
    // Get the start and end position of the selected text ...
    if EditBuffer.EditBlock.IsValid then begin
      BlockStart := EditBuffer.BlockStart;
      BlockAfter := EditBuffer.BlockAfter;
      StartPos := EditBuffer.TopView.CharPosToPos(BlockStart);
      EndPos   := EditBuffer.TopView.CharPosToPos(BlockAfter);
    end
    // ... or get the current cursor position if nothing was selected.
    else begin
      CursorPos := EditBuffer.TopView.CursorPos;
      EditBuffer.TopView.ConvertPos(True, CursorPos, BlockStart);
      BlockAfter := BlockStart;
      StartPos := EditBuffer.TopView.CharPosToPos(BlockStart);
      EndPos := StartPos;
    end;

    // Replace the selection with the code snippet.
    vWriter := EditBuffer.CreateUndoableWriter;
    vWriter.CopyTo(StartPos);
    vWriter.DeleteTo(EndPos);
    vWriter.Insert(PChar(vText));
    BlockAfter := vWriter.CurrentPos;
    vWriter := nil;

    // Set the cursor to the start of the code snippet.
    EditBuffer.TopView.ConvertPos(False, CursorPos, BlockStart);
    EditBuffer.TopView.CursorPos := CursorPos;

    // Make sure the top of the code snippet is visible.
    // Scroll the edit window if ncessary.
    if (BlockStart.Line < EditBuffer.TopView.TopPos.Line) or
       (BlockAfter.Line >= EditBuffer.TopView.TopPos.Line + EditBuffer.TopView.ViewSize.CY) then
    begin
      EditBuffer.TopView.ConvertPos(False, TopPos, BlockStart);
      EditBuffer.TopView.TopPos := TopPos;
    end;

    // Select the newly inserted code snippet.
    vSourceEditor := EditBuffer as IOTASourceEditor;
    vSourceEditor.BlockVisible := False;
    vSourceEditor.BlockType    := btNonInclusive;
    vSourceEditor.BlockStart   := BlockStart;
    vSourceEditor.BlockAfter   := BlockAfter;
    vSourceEditor.BlockVisible := True;

    // Repaint and focus the code editor
    EditBuffer.TopView.Paint;
    EditBuffer.TopView.GetEditWindow.Form.SetFocus;
  end;
end;

procedure TMDHCodeSnippetsWizard.PasteCodeSnippet(Sender: TObject);
var
  vEditorServices: IOTAEditorServices;
  vEditView: IOTAEditView;
begin
  try
    vEditorServices := BorlandIDEServices as IOTAEditorServices;
    // Get the top-most view where the user is working.
    vEditView := vEditorServices.TopView;
    // Exit if no edit window exists
    if vEditView = nil then Exit;
    // Exit if the source is readonly
    if vEditView.Buffer.IsReadOnly then begin
      MessageDlg('The source file is read-only', mtError, [mbOk], 0);
      Exit;
    end;
    // Insert code snippet at current cursor position
    PasteCode(vEditView.Buffer);
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOk], 0);
  end;
end;

{ TMDHKeyboardBinding }

constructor TMDHKeyboardBinding.Create(AOwner: TMDHCodeSnippetsWizard);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TMDHKeyboardBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TMDHKeyboardBinding.GetDisplayName: string;
begin
  Result := 'CodeSnippet';
end;

function TMDHKeyboardBinding.GetName: string;
begin
  Result := 'MDHCodeSnippet';
end;

procedure TMDHKeyboardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([FCopySnippetShortcut], CopySnippet, nil);
  BindingServices.AddKeyBinding([FPasteSnippetShortcut], PasteSnippet, nil);
end;

procedure TMDHKeyboardBinding.CopySnippet(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  BindingResult := krHandled;
  FOwner.CopyCode(Context.EditBuffer);
end;

procedure TMDHKeyboardBinding.PasteSnippet(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  BindingResult := krHandled;
  FOwner.PasteCode(Context.EditBuffer);
end;

end.

