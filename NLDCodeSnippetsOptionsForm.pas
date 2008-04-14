unit NLDCodeSnippetsOptionsForm;

interface

uses
  Windows, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls, Classes, Graphics;

type
  TOptionsForm = class(TForm)
    PageControl1: TPageControl;
    TabSheetOptions: TTabSheet;
    TabSheetAbout: TTabSheet;
    Copyright: TLabel;
    CloseButton: TButton;
    Image1: TImage;
    Label1: TLabel;
    HotKeyCopy: THotKey;
    Label2: TLabel;
    HotKeyPaste: THotKey;
    Label3: TLabel;
    EditFolder: TEdit;
    Label4: TLabel;
    NLDelphi: TLabel;
    procedure CopyrightClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure NLDelphiClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionsForm: TOptionsForm;

implementation

{$R *.dfm}

uses
  ShellApi;

procedure TOptionsForm.CopyrightClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'mailto:mhemmes@bergler.nl?subject=CodeSnippets', '', '', SW_SHOW);
end;

procedure TOptionsForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then ModalResult := mrCancel;
end;

procedure TOptionsForm.NLDelphiClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://www.nldelphi.com/', '', '', SW_SHOW);
end;

end.

