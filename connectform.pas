unit connectform;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, lazserial, lcltype ,LCLTranslator
  {$ifdef windows}
  ,windows,registry
  {$endif}
  ;

type

  { TfrmConnect }

  TfrmConnect = class(TForm)
    CancelButton: TButton;
    OkButton: TButton;
    edtDevice: TComboBox;
    DeviceLabel: TLabel;
    Panel1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    procedure EnumDevices;
  public

  end;

var
  frmConnect: TfrmConnect;

implementation

uses main;

{$R *.lfm}

{ TfrmConnect }

procedure TfrmConnect.EnumDevices;
{$ifdef Windows}
var i : integer;
    hkCurrent: HKEY = 0;
    dwMaxValueNameLen : dword;
    enumContinue: boolean = true;
    index : dword = 0;
    nameBuf : pchar = NIL;
    dwValueNameSize : dword = 0;
    device : string;
    res : dword;
    valueSize : longint = 0;

    reg : TRegistry;
    valueNames : TUnicodeStringArray;
    valueName,value : UnicodeString;
    Info:    TRegKeyInfo;
begin
  edtDevice.items.Clear;
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if not reg.openKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then exit;
    reg.GetKeyInfo(Info);

    valueNames := reg.GetValueNames;
    if valueNames <> NIL then
      for valueName in valueNames do
      begin
        value := reg.ReadString(valueName);
        edtDevice.items.add(value);
      end;
  finally
    reg.free;
  end;

end;
{$else}
const DevicePath = '/dev';
var  s: TSearchRec;
begin
  if FindFirst(DevicePath + PathDelim + 'ttyUSB*', faAnyFile, S) = 0 then
  repeat
    edtDevice.Items.Add(DevicePath + PathDelim + S.Name);
  until FindNext(S) <> 0;
  FindClose(S);
end;
{$endif}

procedure TfrmConnect.FormCreate(Sender: TObject);
begin
  enumDevices;
end;

procedure TfrmConnect.OkButtonClick(Sender: TObject);
var ser : TLazSerial;
    ok : boolean;
begin
  // check if port is valid
  if length(edtDevice.text)<1 then
  begin
    modalResult := mrCancel;
    exit;
  end;
  ok := false;
  try
    ser := TLazSerial.Create (self);
    ser.BaudRate:=br__9600;
    ser.Device:=edtDevice.text;
    try
      ser.Open;
      ser.Close;
      ok := true;
    except
      on e:exception do
        Application.MessageBox(pchar(e.Message),pchar(cError),MB_ICONSTOP);
    end;
  finally
    ser.free;
  end;
  if ok then modalResult := mrOk;
end;

{
const
  cDevicePath = '/dev';
var
  S: TSearchRec;
begin
  if FindFirst(FormatPath(cDevicePath + PathDelim + 'tty*'), faAnyFile, S) = 0 then
  begin
    repeat
      if (Pos('ttyS', S.Name) > 0) or (Pos('ttyUSB', S.Name) > 0 ) then
        edtDevice.Items.Add(S.Name);
    until FindNext(S) <> 0;
  end;
  FindClose(S);
end;
}

end.

