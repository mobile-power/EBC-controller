unit aboutForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IpFileBroker, IpHtml, SynHighlighterHTML, lclintf, LazVersion;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Button1: TButton;
    IpHtmlPanel1: TIpHtmlPanel;
    TopPannel: TPanel;
    BottomPannel: TPanel;
    procedure LoadResourceStrings;
    procedure FormCreate(Sender: TObject);
    procedure IpHtmlPanel1HotClick(Sender: TObject);
    procedure IpHtmlPanel1HotURL(Sender: TObject; const URL: String);
  private
     currURL : string;
  public

  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.lfm}

Resourcestring
  cWhatAmI  = 'A GUI Software for Linux (and Windows) to control ZTE Tech EBC series battery testers and electronic loads intailly written by %s';
  cEnhanced = 'This version %s supports the A20 as well as the A40.';
  cEnhancedVersion = 'enhanced version';
  cVersion         = 'Version';
  cCompileDate     = 'Compiled';
  cFPCVersion      = 'FPC Version';
  cLazarusVersion  = 'Lazarus Version';


{ TfrmAbout }

procedure TfrmAbout.LoadResourceStrings;
var VersionInfo : array[0..3] of string;
    maxLen,i,j,k : integer;
begin
  maxLen := 0;
  VersionInfo[0] := cVersion;
  VersionInfo[1] := cCompileDate;
  VersionInfo[2] := cFPCVersion;
  VersionInfo[3] := cLazarusVersion;
  for i := low(VersionInfo) to high(VersionInfo) do
    if Length(VersionInfo[i]) > maxLen then maxLen := Length(VersionInfo[i]);
  inc(maxLen);
  for i := low(VersionInfo) to high(VersionInfo) do
  begin
    j := maxLen - Length(VersionInfo[i]);
    for k := 1 to j do
      VersionInfo[i] := VersionInfo[i] + '&nbsp;';
  end;

  IpHtmlPanel1.SetHtmlFromStr(Format(
  '<html><head>'+
     '<title>'+Caption+'</title>'+
     '</head><body>'+
     '<h1>EBC-Controller</h1>'+
     '<p>'+Format(cWhatAmI,['<a href="https://github.com/JOGAsoft/EBC-controller">JOGAsoft</a>'])+'</p>'+
     '<p>'+Format(cEnhanced,['<a href="https://github.com/ardiehl/EBC-controller">'+cEnhancedVersion+'</a>'])+'</p>'+
     '<tt>'+VersionInfo[0]+': '+cVersion+'</tt><br>'+
     '<tt>'+VersionInfo[1]+': ' + {$I %DATE%} + ' ' + {$I %TIME%} + '</tt><br>' +
     '<tt>'+VersionInfo[2]+': '+  {$I %FPCVERSION%} + '</tt><br>'+
     '<tt>'+VersionInfo[3]+': %s</tt>' +
     '</body></html>',[laz_version]));
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  LoadResourceStrings;
end;

procedure TfrmAbout.IpHtmlPanel1HotClick(Sender: TObject);
begin
  openUrl(currURL);
end;

procedure TfrmAbout.IpHtmlPanel1HotURL(Sender: TObject; const URL: String);
begin
  currURL:=URL;
end;


end.

