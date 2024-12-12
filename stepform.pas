unit StepForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  SynEdit, SynHighlighterAny, lineparser, LCLType, ExtCtrls, ActnList, ComCtrls, SynEditTypes,
  stepadd_loop;

const
  cNaN = 10E999;
  cCmdCCCV = 'C_CCCV';
  c_fixedBase =  9000;
  c_wait      = c_fixedBase;
  c_loop      = c_fixedBase+1;
  c_end       = c_fixedBase+2;
  c_stop      = c_fixedBase+3;
  c_FixedCmds : array of string =
           ('wait', 'loop', 'end', 'stop');
//  cSettingsFile = 'Settings.conf';

type
  TRunMode = (rmNone, rmMonitor, rmCharging, rmDischarging, rmDischargingCR, rmWait, rmLoop, rmEnd);

{
  TBreakPtr = ^TBreak;
  TBreak = record
    Time: TDateTime;
    Duration: TDateTime;
    Current: Extended;
    Voltage: Extended;
    Capacity: Extended;
    Energy: Extended;
    Next: TBreakPtr;
  end;

  TProgram = record
    Token: Integer;
    Cells: Integer;
    Current: Extended;
    Voltage: Extended;
    BreakPtr: TBreakPtr;
  end;}

  TSteps = record
    Mode: TRunMode;
//    ModeText: string;
    Command: string;
    Cells: Integer;
    TestVal: Extended;
    CutVolt: Extended;
    CutAmp: Extended;
    CutTime: Integer;
    CutAmpTime: Integer;  // Cut N minutes after current < CutAmp
    CutCap: Extended;
    CutEnergyDischarge: Extended;
    Loop: Integer;
    LoopCounter: Integer;
    CapI: Boolean;        // Loop as long as capacity increases
    EneI: Boolean;        // Loop as long as energy increases
    CV: Extended;         // Constant voltage for c_CCCV mode
    PacketIndex : integer;
  end;

  { TfrmStep }

  TfrmStep = class(TForm)
    edtDevice: TComboBox;
    edtDeviceLabel: TLabel;
    lblXY: TLabel;
    OkButton: TButton;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    N3: TMenuItem;
    N2: TMenuItem;
    MenuItem11: TMenuItem;
    mniNew: TMenuItem;
    mniOpen: TMenuItem;
    mniSave: TMenuItem;
    mniSaveAs: TMenuItem;
    mniExit: TMenuItem;
    mniAdd: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    N1: TMenuItem;
    memStep: TSynEdit;
    odOpen: TOpenDialog;
    DevicePanel: TPanel;
    StatusPanel: TPanel;
    sdSave: TSaveDialog;
    SynStepHighlighter: TSynAnySyn;
    procedure lblXYClick(Sender: TObject);
    procedure memStepStatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure setDevice(deviceName : string);
    procedure edtDeviceChange(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure memStepChange(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure mniNewClick(Sender: TObject);
    procedure mniOpenClick(Sender: TObject);
    procedure mniSaveClick(Sender: TObject);
    procedure mniSaveAsClick(Sender: TObject);
    procedure mni_AddLoopClick(Sender: TObject);
    procedure mni_AddWaitClick(Sender: TObject);
  private
    fModel : integer;
    FCompiled: Boolean;
    FInitialDirIsSet: Boolean;
    fCurrFileName : string;
  public
    function Compile(Model: integer; showAbort : boolean) : integer;
    property Compiled: Boolean read FCompiled;
    property fileName: string read fCurrFileName;
    procedure SetInitialDir(ADir: string);
    function loadFile(afileName : string) : boolean;
    procedure LoadResourceStrings;
  end;

var
  FSteps: array of TSteps;
  frmStep: TfrmStep;

Resourcestring
  cCommandExpected             = 'Command expected';
  cUnexpectedParamCharge       = 'unexpected parameter for charge';
  cChargeVoltageNotSpecified   = 'Charge voltage not specified in script nor in conf file (volt=)';
  cCutoffCurrNotSpecified      = 'Cutoff current not specified (cuta=)';
  cChargeCurrNotSpecified      = 'Charge current not specified (curr=)';
  cUnexpectedParDischarge      = 'unexpected parameter for discharge (%s)';
  cUnexpectedParDischargeCP    = 'unexpected parameter for discharge current power (%s)';
  cUnexpectedParDischargeCR    = 'unexpected parameter for discharge current resistance(%s)';
  cLoopValueAlreadySpecified   = 'Loop value already specified';
  cUnexpectedParLoop           = 'unexpected parameter for loop';
  cUnexpectedCommand           = 'unexpected command';
  cErrorInScriptFile           = 'Error in script file';
  cLineColMessage              = '(Line %d, Column %d): %s';
  cDescNote                    = 'Note: A20 and A40 requires charging voltage (chargers have no presets like A5 and A10), may be set via ini file e.g. for LiPo';
  cMinutes                     = 'minutes';
  cUnsaved                     = 'Unsaved';
  cCapcity                     = 'capacity';
  cEnergy                      = 'energy';
  cCurrent                     = 'current';
  cAddWait                     = 'Add wait';
  cWaitTime                    = 'Wait time in seconds:';
  cInvalidInteger              = 'Invalid integer number: %s';
  cExamples                    = 'Examples:';

implementation

{$R *.lfm}

uses main;

function TestStr(AStr: string; ATest: string): Boolean;
begin
  Result := (Pos(ATest, AStr) = 1);
end;

function MyVal(AStr: string): Extended;
var
  I: Integer;
  s: string;
begin
  Result := 0;
  s := '';
  for I := 1 to Length(AStr) do
  begin
    if AStr[I] in ['0'..'9', '.'] then
    begin
      s := s + AStr[I];
    end;
  end;
  if Length(s) > 0 then
  begin
    Result := StrToFloat(s);
  end;
end;

function GetParam(AStr: string; AParam: Integer): string;
var
  I, S: Integer;
  sl: string;
begin
  S := 1;
  Result := '';
  sl := AStr + ' ';
  for I := 1 to Length(sl) do
  begin
    if sl[I] in [' '] then
    begin
      Dec(AParam);
      if AParam = 0 then
      begin
        Result := Copy(sl, S, I - S);
        Break;
      end;
      S := I + 1;
    end;
  end;
end;

{
Charge:    c_[NiMH|NiCd|LiPo|LiFe|Ac|PB|CCCV] Cells=n Curr=I Volt=U [CutA=I|Cap=C|Energy=W|Time=t|CutAt=t]
Discharge: d_[CC|CP|CR] [Curr=I|Power=P|Res=R] CutV=U [Cap=C|Energy=W|Time=t]
Wait:      Wait t (minutes)
Loop:      Loop [CapI|EneI] n - run steps n more times. CapI/EneI - run as long dis. capacity increases
Cutoffs:   [c/d] CutA=current(A) CutC=capacity(Ah) Energy=energy(Wh) Time=(minutes) CutAt=(minutes)
Examples:  c_NiMH Cells=4 Curr=0.75 CutA=0.2 Time=180
           d_CR Res=10 CutV=2.8 Energy=6 Time=360
           end
}
const p_base      = 10000;

type
  p_Ids  = (id_p_value = TK_VALUE, id_p_volt = p_base,id_p_cells, id_p_curr, id_p_cuta, id_p_cap, id_p_energy, id_p_time, id_p_cutat, id_p_power, id_p_res, id_p_cutv, id_p_capi, id_p_enei, id_p_LAST);
const
  p_Names : array of string =
           ('volt', 'cells', 'curr', 'cuta', 'cap', 'energy', 'time', 'cutat', 'power', 'res', 'cutv', 'capi', 'enei');
  p_ValuesRequired : array of boolean =
           (true  , true   , true  , true  , true , true    , true  , true   , true   , true , true  , false , false);

function TfrmStep.Compile(model : integer; showAbort : boolean) : integer;
var
  pa : TLineParser;
  i,tk,n,pm : integer;
  duplicateValue : boolean;
  Buttons: TMsgDlgButtons;
begin
  result := mrCancel;
  SetLength(FSteps, memStep.Lines.Count);
  for I := 0 to Length(FSteps) - 1 do
  begin
    FSteps[I].Command := 'END';
    FSteps[I].Mode := rmEND;
    FSteps[I].PacketIndex := -1;
  end;

  // init parser
  pa := TLineParser.create;
  n := 0;

  // add fixed commands like wait or loop
  n := c_fixedBase;
  for i := low(c_FixedCmds) to High(c_FixedCmds) do
  begin
    pa.addCommand(c_FixedCmds[i],n);
    inc(n);
  end;

  // add commands from conf file
  for I := Low(frmMain.FPackets) to High(frmMain.FPackets) - 1 do
      if frmMain.PacketSupportedByCharger(model,i) then
        with frmMain.FPackets[i] do
          pa.addCommand(Command,i);

  // add parameters
  n := 0;
  for i:= integer(id_p_volt) to integer(id_p_last)-1 do
  begin
    pa.addParam(p_names[n],i,p_valuesRequired[n]);
    inc(n);
  end;

  pa.addParamAlias('volt','voltage');  // alias, was different in example step files

  // parse
  try
    try
      N := 0;
      for I := 0 to memStep.Lines.Count - 1 do
      begin
        pa.beginLine(i+1,memStep.Lines.Strings[I]);
        tk := pa.expectCommandOrEOL;
        if tk>=0 then
        begin
          FSteps[N].Mode := rmCharging;
          FSteps[N].Cells := 1;
          FSteps[N].TestVal := 0.1;
          FSteps[N].CutAmp := 0;
          FSteps[N].CutTime := 0;
          FSteps[N].CutVolt := 0;
          FSteps[N].CutCap := 0;
          FSteps[N].CutEnergyDischarge := 0;
          FSteps[N].CapI := False;
          FSteps[N].EneI := False;
          FSteps[N].LoopCounter := 0;
          FSteps[N].Command:= upperCase(pa.getTokenText);
          FSteps[N].CV := 0;

          if tk >= 0 then
          begin
            FSteps[N].PacketIndex := Tk;
            if tk < c_fixedBase then  // command from conf file
            begin
              If tk > high(frmMain.FPackets) then pa.raiseException (cCommandExpected);
              case frmMain.FPackets[tk].Method of
                mNone      : pa.raiseException (cCommandExpected);
                mCharge    : begin
                  pm := pa.expectParamOrEOL;
                  while(pm>=0) do
                  begin
                    case p_Ids(pm) of
                      id_p_cap    : FSteps[N].cutCap := pa.tkValue;
                      id_p_energy : FSteps[N].CutEnergyDischarge := pa.tkValue;
                      id_p_time   : FSteps[N].CutTime := trunc(pa.tkValue);
                      id_p_cells  : FSteps[N].Cells := trunc(pa.tkValue);
                      id_p_curr   : FSteps[N].TestVal := pa.tkValue;
                      id_p_cutat  : FSteps[N].CutAmpTime := trunc(pa.tkValue);
                      id_p_cuta   : FSteps[N].CutAmp := pa.tkValue;
                      id_p_volt   : FSteps[N].CV := pa.tkValue;
                    otherwise pa.raiseException (cUnexpectedParamCharge);
                    end;
                    pm := pa.expectParamOrEOL;
                  end;
                  if FSteps[N].Cells < 1 then FSteps[N].Cells := 1;
                  inc(n);
                end;
                mChargeCV: begin
                  FSteps[N].CV := frmMain.FPackets[tk].VoltInfo;
                  pm := pa.expectParamOrEOL;
                  while(pm>=0) do
                  begin
                    FSteps[N].CV := frmMain.FPackets[tk].VoltInfo;
                    case p_Ids(pm) of
                      id_p_cap    : FSteps[N].cutCap := pa.tkValue;
                      id_p_energy : FSteps[N].CutEnergyDischarge := pa.tkValue;
                      id_p_time   : FSteps[N].CutTime := trunc(pa.tkValue);
                      id_p_cells  : FSteps[N].Cells := trunc(pa.tkValue);
                      id_p_curr   : FSteps[N].TestVal := pa.tkValue;
                      id_p_cutat  : FSteps[N].CutAmpTime := trunc(pa.tkValue);
                      id_p_cuta   : FSteps[N].CutAmp := pa.tkValue;
                      id_p_volt   : FSteps[N].CV := pa.tkValue;
                    otherwise pa.raiseException (cUnexpectedParamCharge);
                    end;
                    pm := pa.expectParamOrEOL;
                  end;
                  if FSteps[N].CV < 0.01 then
                    pa.raiseException (cChargeVoltageNotSpecified);
                  if FSteps[N].CutAmp < 0.01 then
                    pa.raiseException (cCutoffCurrNotSpecified);
                  if FSteps[N].TestVal < 0.01 then
                    pa.raiseException (cChargeCurrNotSpecified);
                  inc(n);
                end;
                mDischarge: begin
                  FSteps[N].Mode := rmDischarging;
                  pm := pa.expectParamOrEOL;
                  while(pm>=0) do
                  begin
                    case p_Ids(pm) of
                      id_p_cap    : FSteps[N].cutCap := pa.tkValue;
                      id_p_energy : FSteps[N].CutEnergyDischarge := pa.tkValue;
                      id_p_time   : FSteps[N].CutTime := trunc(pa.tkValue);
                      id_p_cutv   : FSteps[N].CutVolt := pa.tkValue;
                      id_p_curr	: FSteps[N].TestVal := pa.tkValue;
                    otherwise pa.raiseException (format(cUnexpectedParDischarge,[pa.getTokenText]));
                    end;
                    pm := pa.expectParamOrEOL;
                  end;
                  inc(n);
                end;
                mDischargeCP: begin
                  FSteps[N].Mode := rmDischarging;
                  pm := pa.expectParamOrEOL;
                  while(pm>=0) do
                  begin
                    case p_Ids(pm) of
                      id_p_cap    : FSteps[N].cutCap := pa.tkValue;
                      id_p_energy : FSteps[N].CutEnergyDischarge := pa.tkValue;
                      id_p_time   : FSteps[N].CutTime := trunc(pa.tkValue);
                      id_p_cutv   : FSteps[N].CutVolt := pa.tkValue;
                      id_p_power  : FSteps[N].TestVal := pa.tkValue;
                    otherwise pa.raiseException (format(cUnexpectedParDischargeCP,[pa.getTokenText]));
                    end;
                    pm := pa.expectParamOrEOL;
                  end;
                  inc(n);
                end;
                mDischargeCR: begin
                  FSteps[N].Mode := rmDischargingCR;
                  pm := pa.expectParamOrEOL;
                  while(pm>=0) do
                  begin
                    case p_Ids(pm) of
                      id_p_cap    : FSteps[N].cutCap := pa.tkValue;
                      id_p_energy : FSteps[N].CutEnergyDischarge := pa.tkValue;
                      id_p_time   : FSteps[N].CutTime := trunc(pa.tkValue);
                      id_p_cutv   : FSteps[N].CutVolt := pa.tkValue;
                      id_p_res    : FSteps[N].TestVal := pa.tkValue;
                    otherwise pa.raiseException (format(cUnexpectedParDischargeCR,[pa.getTokenText]));
                    end;
                    pm := pa.expectParamOrEOL;
                  end;
                  inc(n);
                end;
              end;
            end else
            case tk of
              c_wait : begin
                FSteps[N].Mode := rmWait;
                pa.expectValue;
                FSteps[N].CutTime := trunc(pa.tkValue);
                inc(n)
              end;
              c_loop : begin
                duplicateValue := false;
                FSteps[N].Mode := rmLoop;
                FSteps[N].CapI := false;
                FSteps[N].EneI := false;
                FSteps[N].Loop := 0;
                pm := pa.expectParamOrValueOrEOL;

                while(pm>=0) or (pm = TK_VALUE) do
                begin
                  case p_Ids(pm) of
                    id_p_capi   : FSteps[N].capi := true;
                    id_p_enei   : FSteps[N].enei := true;
                    id_p_value  : begin
                                    if duplicateValue then pa.raiseException(cLoopValueAlreadySpecified);
                                    FSteps[N].Loop := trunc(pa.tkValue);
                                    duplicateValue := true;
                                  end;
                    otherwise pa.raiseException (cUnexpectedParLoop);
                  end;
                  pm := pa.expectParamOrValueOrEOL;
                end;
                if FSteps[N].Loop = 0 then FSteps[N].Loop := 999999;
                inc(n);
              end;
              c_end,
              c_stop : begin
                FSteps[N].Mode := rmEnd;
                inc(n);
              end;
            end;
          end else
            if tk <> TK_EOL then
              pa.raiseException (cUnexpectedCommand);
         end;
      end;
      FCompiled := True;
      Result := mrOk;

    except
      on e:TLineParserException do
      begin
        if showAbort then Buttons := [mbOk, mbAbort] else Buttons := [mbOk];
        Result := MessageDlg (cErrorInScriptFile, format(cLineColMessage,[e.LineNo, e.LinePos,e.Message]), mtError, Buttons,0);
        memStep.CaretX:=e.LinePos;
        memStep.CaretY:=e.LineNo;
      end;
    end;

  finally
    pa.free;
  end;
end;


procedure TfrmStep.SetInitialDir(ADir: string);
begin
  if not FInitialDirIsSet then
  begin
    sdSave.InitialDir := ADir;
    odOpen.InitialDir := ADir;
    FInitialDirIsSet := True;
  end;
end;

procedure TfrmStep.FormCreate(Sender: TObject);
begin
  FCompiled := False;
  FInitialDirIsSet := False;
  {$ifdef windows}
  Memo1.Font.Name := 'Courier New'; //'DejaVu Sans Mono';
  memStep.Font.Name := 'Courier New';
  {$endif}
end;

procedure TfrmStep.OkButtonClick(Sender: TObject);
var
  res : Integer;
begin
  // AD: compile and return to editor on error if not in view mode
  if frmStep.memStep.Enabled then
  begin
    res := compile(fModel,true);
    if (res = mrAbort) then modalResult := mrAbort
    else if FCompiled then modalResult := mrOK
    else ActiveControl := memStep;
  end else
    modalResult := mrOK;
end;

procedure TfrmStep.setDevice(deviceName : string);
begin
  edtDevice.Text := deviceName;
  edtDeviceChange(self);
end;

procedure TfrmStep.memStepStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  lblXY.Caption := format('%d: %d',[MemStep.CaretX,MemStep.CaretY]);
end;

procedure TfrmStep.lblXYClick(Sender: TObject);
begin

end;

procedure TfrmStep.edtDeviceChange(Sender: TObject);
var
  i : integer;
  c,d : TStringList;
  HelpText : String;
  mNew : TMenuItem;
  s : string;
begin
  memStep.ReadOnly:=true;
  memStep.HighLighter := NIL;
  c := TStringList.Create;
  d := TStringList.Create;  // for help text discharge
  try
    SynStepHighlighter.KeyWords.Clear;
    SynStepHighlighter.KeyWords.Add('WAIT');
    SynStepHighlighter.KeyWords.Add('LOOP');
    SynStepHighlighter.KeyWords.Add('END');
    Memo1.Clear;
    if (length(edtDevice.Text)<1) then exit;
    fModel := frmMain.GetModelIndex(edtDevice.Text);
    for I := Low(frmMain.FPackets) to High(frmMain.FPackets) - 1 do
      if frmMain.PacketSupportedByCharger(fModel,i) then
        with frmMain.FPackets[i] do
        begin
          case Method of
            mCharge, mChargeCV: begin
              c.add (copy(command,3,255));
              SynStepHighlighter.KeyWords.Add(Command);
            end;
            mDischarge : begin
              d.add (copy(command,3,255));
              SynStepHighlighter.KeyWords.Add(Command);
            end;
            mNone,mDischargeCP, mDischargeCR: ;  // to avoid warnings
          end;
        end;
    memStep.ReadOnly:=false;
    memStep.HighLighter := SynStepHighlighter;
    memStep.invalidate;

    {Charge:    c_[NiMH|NiCd|LiPo|LiFe|PB|CCCV] Cells=n Curr=I [CutA=I|Cap=C|Energy=W|Time=t|CutAt=t] [Volt=u]
Discharge: d_[CC|CP|CR] [Curr=I|Power=P|Res=R] CutV=U [Cap=C|Energy=W|Time=t]
Wait:      Wait t (minutes)
Loop:      Loop [CapI|EneI] n - run steps n more times. CapI/EneI - run as long dis. capacity increases
Cutoffs:   [c/d] CutA=current(A) CutC=capacity(Ah) Energy=energy(Wh) Time=(minutes) CutAt=(minutes)
Examples:  c_NiMH Cells=4 Curr=0.75 CutA=0.2 Time=180
           d_CR Res=10 CutV=2.8 Energy=6 Time=360
Note: A20 and A40 requires charging voltage (chargers have no presets like A5 and A10), may be set via ini file e.g. for LiPo
}
     Memo1.Lines.Clear;
     if c.Count > 0 then
     begin
       HelpText := '';
       AppendStr(HelpText,'Charge:    c_[');
       for i := 0 to c.Count-1 do
       begin
         if i > 0 then AppendStr(HelpText,'|');
         AppendStr(HelpText,c[i]);
       end;
        AppendStr(HelpText,'] Cells=n Curr=I [CutA=I|Cap=C|Energy=W|Time=t|CutAt=t]|[Volt=u]');
        Memo1.Lines.Add (HelpText);
     end;

     if d.Count > 0 then
     begin
       HelpText := '';
       AppendStr(HelpText,'Discharge: d_[');
       for i := 0 to d.Count-1 do
       begin
         if i > 0 then AppendStr(HelpText,'|');
         AppendStr(HelpText,d[i]);
       end;
        AppendStr(HelpText,'] [Curr=I|Power=P|Res=R] CutV=U [Cap=C|Energy=W|Time=t]');
        Memo1.Lines.Add (HelpText);
     end;

     s := cExamples;
     while(length(s)) < 11 do s := s + ' ';
     Memo1.Lines.Add('Wait:      Wait t ('+cMinutes+')');
     Memo1.Lines.Add('Loop:      Loop [CapI|EneI] n - run steps n more times. CapI/EneI - run as long dis. capacity increases');
     Memo1.Lines.Add('Cutoffs:   [c/d] CutA='+cCurrent+'(A) CutC='+cCapcity+'(Ah) Energy='+cEnergy+'(Wh) Time=('+cMinutes+') CutAt=('+cMinutes+')');
     Memo1.Lines.Add(s+'c_'+c[0]+' Cells=4 Curr=0.75 CutA=0.2 Time=180');
     Memo1.Lines.Add('           d_CR Res=10 CutV=2.8 Energy=6 Time=360');
     Memo1.Lines.Add(cDescNote);

     // clear add menu
     while mniAdd.Count > 0 do
       mniAdd.delete(0);
     // create add menu entries for charge
     for i := 0 to c.Count-1 do
     begin
       mNew := TMenuItem.Create(Self);
       mNew.Caption := 'c_'+c[i];
       mniAdd.Add(mNew);
     end;
     mNew := TMenuItem.Create(Self); mNew.Caption := '-'; mniAdd.Add(mNew);
     for i := 0 to d.Count-1 do
     begin
       mNew := TMenuItem.Create(Self);
       mNew.Caption := 'd_'+d[i];
       mniAdd.Add(mNew);
     end;
     mNew := TMenuItem.Create(Self); mNew.Caption := '-'; mniAdd.Add(mNew);

     mNew := TMenuItem.Create(Self); mNew.Caption := '&Wait'; mNew.OnClick := @mni_AddWaitClick; mniAdd.Add(mNew);
     mNew := TMenuItem.Create(Self); mNew.Caption := '&Loop'; mNew.OnClick := @mni_AddLoopClick; mniAdd.Add(mNew);

  finally
    c.free; d.free;
  end;

end;


procedure TfrmStep.LoadResourceStrings;
begin
  edtDeviceChange(self);
end;

procedure TfrmStep.memStepChange(Sender: TObject);
begin
  FCompiled := False;
end;

procedure TfrmStep.mniExitClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmStep.mniNewClick(Sender: TObject);
begin
  memStep.Lines.Clear;
  frmStep.Caption := 'Unsaved';
end;

procedure TfrmStep.mniOpenClick(Sender: TObject);
begin
  if odOpen.Execute then loadFile(odOpen.FileName);
end;

procedure TfrmStep.mniSaveClick(Sender: TObject);
begin
  if sdSave.FileName > '' then
  begin
    memStep.Lines.SaveToFile(sdSave.FileName);
    frmStep.Caption := sdSave.FileName;
  end else
  begin
    mniSaveAsClick(Sender);
  end;
end;

procedure TfrmStep.mniSaveAsClick(Sender: TObject);
begin
  if sdSave.Execute then
  begin
    memStep.Lines.SaveToFile(sdSave.FileName);
    frmStep.Caption := sdSave.FileName;
  end;
end;

function TfrmStep.loadFile(aFileName : string) : boolean;
begin
  result := true;
  if length(aFileName) < 1 then exit(false);
  try
     memStep.Lines.LoadFromFile(aFileName);
  except
    result := false;
  end;
  if result then
  begin
    fcurrFileName := aFileName;
    frmStep.Caption := aFileName;
    sdSave.FileName := aFileName;
    odOpen.FileName := aFileName;
    fcurrFileName := aFileName;
    Compile(fModel,true);
  end else
  begin
    fcurrFileName := '';
    frmStep.Caption := cUnsaved;
    sdSave.FileName := '';
  end;
end;

procedure TfrmStep.mni_AddLoopClick(Sender: TObject);
var f : TfrmStepAdd_Loop;
    s : string;
begin
  f := NIL;
  try
    f := TfrmStepAdd_Loop.Create(application);
    if f.ShowModal = mrOk then
      if f.edtLoopCount.Value > 0 then
      begin
        s := 'loop ';
        if f.chkCapIEneI.Checked then s := s + 'enei ';
        s := s + IntToStr(f.edtLoopCount.Value);
        memStep.Lines.Add(s);
      end;
  finally
    f.free;
  end;
end;

procedure TfrmStep.mni_AddWaitClick(Sender: TObject);
var s : string;
    i : integer;
begin
  s := '1';
  if InputQuery(cAddWait, cWaitTime, s) then
  begin
    try
      i := StrToInt(s);
      if i > 0 then
        memStep.Lines.Add('wait '+s);
    except
      on e:exception do
        Application.MessageBox(pchar(format(cInvalidInteger,[s])),pchar(cError),MB_ICONSTOP);
    end;
  end;
end;

end.

