unit NLDCodeSnippetsForm;

interface

uses
  Classes, Controls, Forms, StdCtrls, ExtCtrls, Buttons;

type
  TSnippetsForm = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    MemoCodeSnippet: TMemo;
    ListBoxCodeSnippets: TListBox;
    ButtonPaste: TBitBtn;
    TimerSelection: TTimer;
    procedure TimerSelectionTimer(Sender: TObject);
    procedure ListBoxCodeSnippetsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure ListBoxCodeSnippetsDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FCodeSnippetLibrary: TStringList;
    FCodeLoaded: Integer;
    FPath: string;
    function GetSelectedText: string;
    procedure LoadCodeSnippet(Index: Integer);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetCodeSnippetLibrary(const APath: string);
    procedure AddSnippet(const AName, AFileName: string);

    property SelectedText: string read GetSelectedText;
  end;

var
  SnippetsForm: TSnippetsForm;

implementation

{$R *.dfm}

uses
  SysUtils;

{ TSnippetsForm }

constructor TSnippetsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCodeSnippetLibrary := TStringList.Create;
  FCodeLoaded := -1;
end;

destructor TSnippetsForm.Destroy;
begin
  FreeAndNil(FCodeSnippetLibrary);
  inherited Destroy;
end;

procedure TSnippetsForm.GetCodeSnippetLibrary(const APath: string);
var
  SearchRec: TSearchRec;
  FileStream: TFileStream;
  Buffer: string;
  I: Integer;
begin
  FPath := IncludeTrailingPathDelimiter(APath);
  FCodeSnippetLibrary.Clear;
  ListBoxCodeSnippets.Items.BeginUpdate;
  try
    ListBoxCodeSnippets.Items.Clear;
    if FindFirst(FPath+'code????.txt', faArchive, SearchRec) = 0 then
    begin
      repeat
        FileStream := TFileStream.Create(FPath+SearchRec.Name, fmOpenRead or fmShareDenyWrite);
        try
          SetLength(Buffer, 255);
          SetLength(Buffer, FileStream.Read(Buffer[1], 255));
          I := Pos(#13, Buffer);
          if I < 1 then I := Pos(#10, Buffer);
          Buffer := Copy(Buffer, 1, I-1);
          if Copy(Buffer,1,1) = '[' then Delete(Buffer,1,1);
          if Copy(Buffer,Length(Buffer),1) = ']' then Delete(Buffer,Length(Buffer),1);
        finally
          FileStream.Free;
        end;
        FCodeSnippetLibrary.Add(Buffer+'='+SearchRec.Name);
        ListBoxCodeSnippets.Items.AddObject(Buffer,TObject(FCodeSnippetLibrary.Count-1));
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  finally
    ListBoxCodeSnippets.Items.EndUpdate;
  end;
end;

function TSnippetsForm.GetSelectedText: string;
begin
  if ListBoxCodeSnippets.ItemIndex >= 0 then
  begin
    if FCodeLoaded <> Integer(ListBoxCodeSnippets.Items.Objects[ListBoxCodeSnippets.ItemIndex]) then
      LoadCodeSnippet(Integer(ListBoxCodeSnippets.Items.Objects[ListBoxCodeSnippets.ItemIndex]));
    Result := MemoCodeSnippet.Lines.Text;
  end;
end;

procedure TSnippetsForm.TimerSelectionTimer(Sender: TObject);
begin
  TimerSelection.Enabled := False;
  LoadCodeSnippet(Integer(ListBoxCodeSnippets.Items.Objects[ListBoxCodeSnippets.ItemIndex]));
end;

procedure TSnippetsForm.ListBoxCodeSnippetsClick(Sender: TObject);
begin
  TimerSelection.Enabled := False;
  TimerSelection.Enabled := True;
end;

procedure TSnippetsForm.LoadCodeSnippet(Index: Integer);
var
  FileName: string;
begin
  FileName := FPath + FCodeSnippetLibrary.Values[FCodeSnippetLibrary.Names[Index]];
  MemoCodeSnippet.Lines.LoadFromFile(FileName);
  MemoCodeSnippet.Lines.Delete(0);
  FCodeLoaded := Index;
end;

procedure TSnippetsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TimerSelection.Enabled := False;
end;

procedure TSnippetsForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then ModalResult := mrCancel;
end;

procedure TSnippetsForm.ListBoxCodeSnippetsDblClick(Sender: TObject);
begin
  TimerSelection.Enabled := False;
  LoadCodeSnippet(Integer(ListBoxCodeSnippets.Items.Objects[ListBoxCodeSnippets.ItemIndex]));
  ModalResult := mrOk;
end;

procedure TSnippetsForm.AddSnippet(const AName, AFileName: string);
begin
  FCodeSnippetLibrary.Add(AName+'='+AFileName);
  ListBoxCodeSnippets.Items.AddObject(AName, TObject(FCodeSnippetLibrary.Count-1));
end;

procedure TSnippetsForm.FormShow(Sender: TObject);
begin
  ActiveControl := ListBoxCodeSnippets;
end;

end.
