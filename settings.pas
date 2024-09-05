unit settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  EditBtn, JLabeledIntegerEdit;

// never ever change order as it is saved in config file

const
  cAutoLoad = 0;
  cRememberSaveDir = 1;
  cRememberAutoLog = 2;
  cRememberStepDir = 3;
  cForceMon = 4;
  cLogRecData = 5;
  cIgnoreCRC = 6;
  cTaskbarCsvPrefix = 7;

type

  { TfrmSettings }

  TfrmSettings = class(TForm)
    CancelButton: TButton;
    OkButton: TButton;
    cgSettings: TCheckGroup;
    edtProgFile: TFileNameEdit;
    grpParam: TGroupBox;
    edtIntTime: TJLabeledIntegerEdit;
    rgStart: TRadioGroup;
    procedure OkButtonClick(Sender: TObject);
    procedure cgSettingsClick(Sender: TObject);
    procedure cgSettingsItemClick(Sender: TObject; Index: integer);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LoadRecourcestrings;
  private

  public

  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.lfm}

Resourcestring
  cstAutoLoad = '&Autoload program file';
  cstRememberSaveDir = '&Remember save directory';
  cstRememberAutoLog = 'Remember &CSV file for automatic logging';
  cstRememberStepDir = 'Remember s&tep file directory';
  cstForceMon = '&Force monitor mode after cycle end';
  cstLogRecData = '&Log received data to console';
  cstIgnoreCRC = '&Ignore CRC';
  cstTaskbarCsvPrefix = 'use taskbar name as csv file name &prefix';

  cstLoadLastSettings = 'Load last settings';
  cstUseDefaultSettings = 'Use default settings';
  cstUseSelection2 = 'Use selection 2';
  cstUseSelection3 = 'Use selection 3';


{ TfrmSettings }

procedure TfrmSettings.LoadRecourcestrings;
begin
  cgSettings.Items.Clear;
  cgSettings.Items.Add(cstAutoLoad);
  cgSettings.Items.Add(cstRememberSaveDir);
  cgSettings.Items.Add(cstRememberAutoLog);
  cgSettings.Items.Add(cstRememberStepDir);
  cgSettings.Items.Add(cstForceMon);
  cgSettings.Items.Add(cstLogRecData);
  cgSettings.Items.Add(cstIgnoreCRC);
  cgSettings.Items.Add(cstTaskbarCsvPrefix);

  rgStart.Items.Clear;
  rgStart.Items.Add(cstLoadLastSettings);
  rgStart.Items.Add(cstUseDefaultSettings);
  rgStart.Items.Add(cstUseSelection2);
  rgStart.Items.Add(cstUseSelection3);
end;

procedure TfrmSettings.cgSettingsClick(Sender: TObject);
begin
  edtProgFile.Enabled := cgSettings.Checked[cAutoLoad];
end;

procedure TfrmSettings.OkButtonClick(Sender: TObject);
begin
  if edtIntTime.Value < 2 then edtIntTime.Value := 2;
end;

procedure TfrmSettings.cgSettingsItemClick(Sender: TObject; Index: integer);
begin
  cgSettingsClick(Sender);
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  //cgSettings.CheckEnabled[cCaptureSettings] := False;
  LoadRecourcestrings;
end;

procedure TfrmSettings.FormShow(Sender: TObject);
begin
  cgSettingsClick(Sender);
end;

end.

