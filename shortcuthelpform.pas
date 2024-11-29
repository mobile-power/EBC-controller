unit shortcuthelpform;
(*
 Show shortcuts as defined in various controls
 ad@ardiehl.de 28.10.2023 *)
{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, IpHtml,
  menus,lclproc,ExtCtrls,StdCtrls,ComCtrls;

type

  { TfrmShortcuts }

  TfrmShortcuts = class(TForm)
    IpHtmlPanel1: TIpHtmlPanel;
    procedure FormCreate(Sender: TObject);
    procedure setHelpText(Sender: TObject);
  private

  public

  end;

var
  frmShortcuts: TfrmShortcuts;

implementation

uses main;

Resourcestring
  csk_connect  = 'Connect';
  csk_Tabs     = 'Tabs';
  csk_Data     = 'Data';
  csk_Steps    = 'Steps / Program';
  csk_Settings = 'Settings';
  csk_Values   = 'Values';
  csk_Run      = 'Run';
  csk_Title    = 'Shortcut keys';


{$R *.lfm}

{ TfrmShortcuts }

const lineBreak = char(10);
procedure TfrmShortcuts.SetHelpText(Sender: TObject);
var
  h: string;
  inTab : boolean;
  //f : text;

  procedure endTab;
  begin
    if inTab then
    begin
      inTab := false;
      h := h + '</table>'+lineBreak;
    end;
  end;

  procedure beginTab;
  begin
    if not inTab then
    begin
      inTab := true;
      h := h + '<table>'+lineBreak;
    end;
  end;

  procedure addHead(s: string);
  begin
    endTab;
    h := h + '<h3>'+s+'</h3>'+lineBreak;
  end;

  procedure addKey(key,func: string);
  begin
    beginTab;
    h := h + '<tr><td>'+key+'</td><td>'+func+'</td></tr>'+lineBreak;
  end;

  procedure addKeyC2(Caption,Hint: string; shortCut: tShortCut);
  var
    short,txt,cap : string;
    ch : char;
    p : integer;
  begin
    short := '';
    txt := Hint;
    ch := #0;
    if ShortCut > 0 then
      short := ShortCutToText(ShortCut);

    cap := Caption;
    p := pos('&',cap);
    if (p > 0) then
    begin
      ch := cap[p+1];
      system.delete(cap,p,1);
    end;

    if length(txt) < 1 then
      txt := cap;

    if length(short) < 1 then
      if ch <> #0 then
        short := 'Alt-'+upcase(ch);

    if length(short)>0 then
      addKey(short,txt);
  end;

  procedure addKeyC(c : TComponent);
  begin
    if c is TTabSheet then
      with TTabSheet(c) do
        addKey('',Hint)
    else if c is TMenuItem then
      with TMenuItem(c) do
        addKeyC2(Caption,Hint,ShortCut)
    else if c is TButton then
      with TButton(c) do
        addKeyC2(Caption,Hint,0)
    else if c is TCustomLabeledEdit then
      with TCustomLabeledEdit(c) do
        addKeyC2(EditLabel.Caption,EditLabel.Hint,0)
    else if c is TControl then
      with TControl(c) do
        addKeyC2(Caption,Hint,0)
  end;

begin
  h := '<html><head><title>'+csk_Title+'</title></head><body>'+lineBreak;
  inTab := false;
  addHead(csk_connect);
  AddKeyC(frmMain.mm_Connect);
  AddKeyC(frmMain.mm_Disconnect);

  addHead(csk_Tabs);
  addKeyC(frmMain.tsCharge);
  addKeyC(frmMain.tsDischarge);
  addKeyC(frmMain.tsProgram);
  addKeyC(frmMain.tsConsole);

  addHead(csk_Data);
  addKeyC(frmMain.mm_savePng);
  addKeyC(frmMain.mm_saveCsv);
  addKeyC(frmMain.mm_setCsvLogFile);
  addKeyC(frmMain.mm_AutoLog);

  addHead(csk_Steps);
  addKeyC(frmMain.mm_stepLoad);
  addKeyC(frmMain.mm_stepEdit);
  addKeyC(frmMain.mm_skipStep);

  addHead(csk_Settings);
  addKeyC(frmMain.mm_Settings);
  addKeyC(frmMain.mm_taskBarName);
  addKeyC(frmMain.mm_LogFileDir);

  addHead(csk_Values);
  addKeyC(frmMain.edtCells);
  addKeyC(frmMain.edtChargeV);
  addKeyC(frmMain.edtCutA);
  addKeyC(frmMain.edtCutM);
  addKeyC(frmMain.edtCutTime);
  addKeyC(frmMain.edtCutEnergyDischarge);
  addKeyC(frmMain.edtCutCap);

  addHead(csk_Run);
  addKeyC(frmMain.btnStart);
  addKeyC(frmMain.btnStop);
  addKeyC(frmMain.btnCont);
  addKeyC(frmMain.btnAdjust);
  addKeyC(frmMain.tbxMonitor);

  endTab;
  h := h + '</body>';

  IpHtmlPanel1.SetHtmlFromStr(h);
end;

procedure TfrmShortcuts.FormCreate(Sender: TObject);
begin
   SetHelpText(Sender);
end;




end.

