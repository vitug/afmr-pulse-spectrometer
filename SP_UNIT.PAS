{************************************************************}
{                                                            }
{                 Module sp_unit                             }
{       Copyright (c) 2000-2016                              }
{               RSMUV                                        }
{                                                            }
{  Developer: Vasiliy Tugarinov                              }
{  Modification:  december 2016                              }
{                                                            }
{************************************************************}
//Antiferromagnetic resonance spectrometer controller
Unit sp_unit;

Interface
//{$DEFINE debug}

uses
  Basic, Charger, tempr_s, Spectrm, V_meter, Adc_Base, CommonTypes,
  FileParams, FileRelis, Lcard,
  SysUtils, Dialogs, Windows, Classes;

const
  FileNameLength = 4;

type
  // ����� ��� ����� �������� �������, ����� ����� ������ ��������� ���������� ���������� ����� �������
  TChargerThread = class(TThread)
  private
    FCharger: TCharger;
  public
    constructor Create(Charger: TCharger);
    procedure Execute; override;
  end;

  PTSpectrometer = ^TSpectrometer;    //��������� ������� �������, ��������� � ������� ��������
  TSpectrometer = class
  private
    FFileParam: TFileParam;           // ������ �� ini ���� � �����������
    FAdcSpectrMeassure: TAdcSpectr;   // ��� ��������� (������ + ����)
    FAdcLevelSignal: TAdcLevelSignal; // ��� ������ �������
    FZeroLevel: integer;              // ������� ���� �����
    FCharger: TCharger;               // �����-������
    FChargerThread: TChargerThread;   // ����� ��� �������
    FSb: TSpectrumBase;               // ���� ��������
    FPulseGenerator: TPulseGenerator; // ��������� ��������
    FTempSensor: TemperatureSensor;   // ������ �����������
    FVoltmeter: TVoltmeter;           // ���������
    FFileCounter: word;               // ������� ������ ��������
    FDescription: TSpectrDescription; //�������� �������
    FisBusy: Boolean;                 // ������
    FFiles: TFiles;                   // ������ � �������
    FSaveDebugADCData: boolean;       // ���� ������ ���������� ������ � ��� (���� � ������)
    FFullyCharge: boolean;            // ���� ��������� ������� ������� � ������ ��� ������������� ����������
    FAutoGaugeScale: byte;            // ������ � "%" ����� �������, �� �������� ������� (��� ������� ���������� ��� �������� ������� ������� ����������)
  protected
    procedure SaveCurrentData(FrontBack_: TFrontBack);        // ������ ������
    procedure SaveCurrentPulse;                               // ������ ��������
    procedure SaveCurrentSignal;                              // ������ �������
  public
    constructor Create(Param: TFileParam);  // ����������� ������
    constructor CreateWithoutCamacAndLcard;
    function GetTemperature: real;    // ���������� �����������
    function GetChargeVoltage: real;  // ���������� ���������� ������
    function GetThermopareVoltage: double; //���������� ���������� �� ��������� � ���
    function GetMaxField(volt: Real): real; // ���������� ���� ���� �� ������
    function Debug: boolean;          // ��������� ����� (�������, ���������)
    function UnderThreshold: boolean; // ��������� ����������� ���� ���. ������
    function ReadyADC: Boolean;       // ��������� ���������� ��� � ������
    function NextSpectrum: Boolean;   // ����. ������ �� ����
    function PrevSpectrum: Boolean;   // ����. ������ �� ����
    procedure StartRecord;            //������ �������
    procedure Charge;                 // �����
    procedure UnCharge;               // ������
    procedure AutoCharge;             // ����� ������� ���������� ���� � ������ �������(��� ����������)
    function ReadAdcData(FileName: string): TADC_DATA;    // ������ ������ ��� �� ����� ��� �������
    procedure CreateModules;          // �������� ������� ����� � ������
    procedure InitE2010Only;          // ������������� ������ ����� �2010 � ������ ���� �� ������
    procedure SetTempZeroCompensation(ZeroCorrection:double);

    property SB: TSpectrumBase read FSb write FSb;   // ���� ��������
    property AdcSpectr: TAdcSpectr read FAdcSpectrMeassure write FAdcSpectrMeassure; // ��� spectra
    property AdcLevel: TAdcLevelSignal read FAdcLevelSignal write FAdcLevelSignal;   //��� ������ �������
    property PulseGenerator: TPulseGenerator read FPulseGenerator write FPulseGenerator;
    property isBusy: Boolean read FisBusy write FisBusy;                        // ������
    property TempSensor: TemperatureSensor read FTempSensor write FTempSensor; // �����������
    property IniFileParam: TFileParam read FFileParam;                      // ��� ���� � �����������
    property Files: TFiles read FFiles;                                     // ���������� ����������
    property ZeroLevel: integer read FZeroLevel write FZeroLevel;           // ������� ���� ���
    property SaveDebugADCData: Boolean read FSaveDebugADCData write FSaveDebugADCData; //������ �����. ������
    property FullyCharge: boolean read FFullyCharge;
    property Description: TSpectrDescription read FDescription write FDescription;
    property AutoGaugeScale: byte read FAutoGaugeScale write FAutoGaugeScale;
    property ZeroCompensationTempSensor:double write SetTempZeroCompensation;

  end;

  // ����� ��� ����������, � ��� ���������� ���� ��������� ����������, ����� �� �������� ���������� ���������
  TChargerStartThread = class(TThread)
  private
    FCharger: TCharger;
    FSpectrometer: TSpectrometer;
  public
    constructor Create(Charger: TCharger; Spectrometer: TSpectrometer);
    procedure Execute; override;
  end;

implementation

uses ConvUtils;

//==================================================

constructor TSpectrometer.Create(Param: TFileParam);
var
  LastChanges: TLastChangesExperiment;
begin
  //������� ���. ��� ����������
  FFullyCharge := false;

  FFiles := TFiles.CreateDirectory;             // �������������� ������� ������
  FFileParam := Param;                 // ������ ����� ����������
  FPulseGenerator := TPulseGenerator.Create; // ��������� ��������
  CreateModules;                       // ������� ������� ��������� � ��.

  // ������ �� ��� ����� ��������� � ���������� ���
  FAdcSpectrMeassure.ChannelField := FFileParam.GetParamChField;
  FAdcSpectrMeassure.ChannelSignal := FFileParam.GetParamChSignal;
  FAdcSpectrMeassure.Frequency := FFileParam.GetAdcRate;
  FAdcSpectrMeassure.Duration := FFileParam.GetDurationSpectr;

  FAdcLevelSignal.ChannelLevel := FFileParam.GetParamChLevel;
  FAdcLevelSignal.Frequency := FFileParam.GetRateAdcLevel;
  FAdcLevelSignal.Duration := FFileParam.GetDurationLevel;

  // ��������� � PulseGenerator ��������� ��������� ���� � ������������� ����. � �������� ����. ������ �� �����
  FPulseGenerator.RiseUpCoefSet := FFileParam.GetRiseUpCoefSet;
  FPulseGenerator.DownCoefSet := FFileParam.GetDownCoefSet;
  FPulseGenerator.BeginParamCircuit := FFileParam.GetParamCircuit;
  FPulseGenerator.MaxErrorFit := FFileParam.GetMaxErrorFit;

  // ������ � ������������� ���� ������ ���������� ������ � ���
  FSaveDebugADCData := FFileParam.GetFlagSaveDebugADCData;
  //����� �������� �������, ���� ��� ��� �� ��������
  if FSaveDebugADCData then
    FFiles.CreateSubDirDebug;

  //�������� �������� ������������
  //�������� ��������� �������������� �������� �� �����
  LastChanges := FFileParam.GetLastChangesExperiment;
  with FDescription do
  begin
    Crystal := LastChanges.Crystal;
    Generator := LastChanges.Generator;
    Section := LastChanges.Section;
    Thermopair := LastChanges.Thermopair;
    Orientation := LastChanges.Orientation;
    Comment := LastChanges.Comment;
  end;

  //������ �������� ����� ���������� ��� �������������� �� �����
  FAutoGaugeScale := FFileParam.GetAutoScalePercent;

  FZeroLevel := 0;                    // ������� ���� �����
  FFileCounter := 0;
  FisBusy := false;

  // ���������� ����� ��� ��������� ������
  if ReadyADC then
    FAdcLevelSignal.Prepare;

  FTempSensor.Unorm:=FFileParam.GetLastThermoCoupleRealControlPointU;
  FTempSensor.ControlPoint:=FFileParam.GetLastThermoCoupleControlPointU;

end;

//--------------------------------------------------

constructor TSpectrometer.CreateWithoutCamacAndLcard;
begin
//  New(FSB);
  FSB := TSpectrumBase.Init;
end;

//--------------------------------------------------

procedure TSpectrometer.StartRecord;
var
  SpectrFront: TSpectrum;
  SpectrBack:  TSpectrum;
  TempSignal: TADC_DATA;
{$if Defined(debug)}
  Field, Signal: TADC_DATA;
{$ifend}
begin
  FisBusy := true;
  FFullyCharge := false; //������� ���� ������� ����������

  //������� ������ � �������� �������
  FDescription.Temperature := GetTemperature;
  FDescription.ChargeVoltage := GetChargeVoltage;
  FDescription.ThermopairVoltage := GetThermopareVoltage;

{$if Defined(debug)}
  // ��������� �����, ����� ������ ��� �� ������
  Field := ReadAdcData('First_00000001.dat');
  Signal := ReadAdcData('Second_00000001.dat');
{$else}
  if not FAdcSpectrMeassure.Ready then
    exit;

  //����� ��� ������� (��������� ���� ����� ������, ����� ��� ����� ��������������������� ����� ������)
  FChargerThread := nil;
  FChargerThread := TChargerThread.Create(FCharger);
  FChargerThread.Resume;

  //���������� ����� ����� �������
  FAdcSpectrMeassure.Prepare;

  // ����� ���
  FAdcSpectrMeassure.Start;
{$ifend}

{$if Defined(debug)}
  //������������ ������� ����
  FPulseGenerator.Fit(Field, FDescription.ChargeVoltage);
  //������������ ������
  //TempSignal := FPulseGenerator.RecalcSignal(Signal);
  TempSignal := FPulseGenerator.RecalcSignalFull(Signal);
{$else}
  //������������ ������� ����
  FPulseGenerator.Fit(FAdcSpectrMeassure.GetDataOfChannel(FAdcSpectrMeassure.ChannelField.Number), FDescription.ChargeVoltage);
  //������������ ������
  //TempSignal := FPulseGenerator.RecalcSignal(FAdcSpectrMeassure.GetDataOfChannel(FAdcSpectrMeassure.ChannelSignal.Number));
  TempSignal := FPulseGenerator.RecalcSignalFull(FAdcSpectrMeassure.GetDataOfChannel(FAdcSpectrMeassure.ChannelSignal.Number));
{$ifend}
  // �������� ����� ��������
  FDescription.FrontBack := fbFront; //��������� ���� ����� �����
  SpectrFront := TSpectrum.InitEstimateFieldFit(TempSignal, FPulseGenerator, FDescription);

  // ������ ����� ��������
  FDescription.FrontBack := fbBack; //��������� ���� ����� �����
  SpectrBack := TSpectrum.InitEstimateFieldFit(TempSignal, FPulseGenerator, FDescription);

  //�������������� ��� ��� ��������� ������ �������
  if FAdcLevelSignal.Ready then
    FAdcLevelSignal.Prepare;

  //����������� ������� ������
  inc(FFileCounter);

  //��������� � ���� ������ ����� � ���������� ���
  SpectrBack.FileNumber := FFileCounter;
  FSb.Add(SpectrBack);
  SaveCurrentData(fbBack);

  //��������� � ���� �������� ����� � ���������� ���
  SpectrFront.FileNumber := FFileCounter;
  FSb.Add(SpectrFront);
  SaveCurrentData(fbFront);

  //������ ���������� ������ � ���
  if FSaveDebugADCData then
  begin
    SaveCurrentPulse;
    SaveCurrentSignal;
  end;

  FisBusy := false;
end;

//--------------------------------------------------

function TSpectrometer.GetTemperature:real;
var
  T: double;
begin
{$if Defined(debug)}
  T := 273;
{$else}
  T := TempSensor.GetTemp;
{$ifend}
  Result := T;
end;

//--------------------------------------------------

function TSpectrometer.GetChargeVoltage:real;
var
 Volt: real;
begin
  FVoltmeter.Measure;
{$if Defined(debug)}
  Volt := 220;
{$else}
  Volt := FVoltMeter.U;
{$ifend}
  Result := Volt;
end;

//--------------------------------------------------

function TSpectrometer.GetThermopareVoltage: double;
var
  Volt: double;
begin
{$if Defined(debug)}
  Volt := 0;
{$else}
  Volt := TempSensor.U * 1E6;
{$ifend}
  Result := Volt;
end;

//--------------------------------------------------

function TSpectrometer.GetMaxField(volt: Real): real;
begin
  if Volt > 0 then
    Result := FPulseGenerator.GetField(6E-3 ,volt)
  else
    Result := 0;
end;

//--------------------------------------------------

procedure TSpectrometer.SaveCurrentData(FrontBack_: TFrontBack);
var
  FileNameWhithZero: String;
  TempPath: String;
begin
  TempPath := '';
  FileNameWhithZero := FFiles.MakeFileNameWithZeros(FFileCounter);

  if FrontBack_ = fbBack then
    TempPath := FFiles.SpectrsRoot + 'Back\'
  else
    TempPath := FFiles.SpectrsRoot + 'Front\';

  if not DirectoryExists(TempPath) then
    ForceDirectories(TempPath);

  FSb.SaveData(TempPath + FileNameWhithZero + '.dat');
end;

//--------------------------------------------------

procedure TSpectrometer.SaveCurrentPulse;
var
  FileNameWhithZero: String;
  TempPath: String;
begin
  TempPath := '';
//  FSb.GetCurrent.FileNumber := FFileCounter;
  FileNameWhithZero := FFiles.MakeFileNameWithZeros(FFileCounter);

  TempPath := FFiles.DebugTimeStampDir + 'Pulse\';

  if not DirectoryExists(TempPath) then
    ForceDirectories(TempPath);

  FSb.SavePulse(TempPath + FileNameWhithZero + '.dat');
end;

//--------------------------------------------------

procedure TSpectrometer.SaveCurrentSignal;
var
  FileNameWhithZero: String;
  TempPath: String;
begin
  TempPath := '';
  FileNameWhithZero := FFiles.MakeFileNameWithZeros(FFileCounter);

  TempPath := FFiles.DebugTimeStampDir + 'Signal\';

  if not DirectoryExists(TempPath) then
    ForceDirectories(TempPath);

  FSb.SaveSignal(TempPath + FileNameWhithZero + '.dat');
end;

//--------------------------------------------------

procedure TSpectrometer.Charge;
begin
  FCharger.Charge;
end;

//--------------------------------------------------

procedure TSpectrometer.UnCharge;
begin
  FCharger.Uncharge;
end;

//--------------------------------------------------

function TSpectrometer.ReadAdcData(FileName: string): TADC_DATA;
var
  i, LinesFile: longint;
  F: Text;
  FileStr: String[100];
  DataStr: TFileADC_Data;
  AdcData: TADC_DATA;
begin
  AssignFile(F, FFiles.DebugRoot + 'ADC_Data\' + FileName);
{$I-}
  Reset(F);
{$I+}
  if IOResult <> 0 then
  begin
    MessageBox(HWND(nil), 'Error read data', 'Debug error', MB_OK + MB_ICONERROR);
    exit;
  end;

  //������ ���-�� ����� � ����� (������ ������)
  LinesFile := 0;
  while not SeekEof(F) do
  begin
    Readln(F);
    inc(LinesFile);
  end;

  //������ ���-�� ����� � �������� � ����� (�������� �����������)
  LinesFile := LinesFile - FileDebugComment;

  //-----------��������� ������---------------
  Reset(F);
  //���������� �����������
  for i := 0 to FileDebugComment - 1 do
  begin
    Readln(F);
  end;

  //������ �����
  SetLength(AdcData, LinesFile); //������������ ������ ��� ������ �� �����

  i := 0;
  while not SeekEof(F) do
  begin
    Readln(F, FileStr);
    DataStr := FFiles.GetWords(FileStr);
    inc(i);

    AdcData[i - 1].time := ConvertStringInFloat(DataStr[0]);
    AdcData[i - 1].quantization_step := StrToInt(DataStr[1]);
    AdcData[i - 1].voltage := ConvertStringInFloat(DataStr[2]);
  end;
  CloseFile(F);
  Result := AdcData;
end;

//--------------------------------------------------

procedure TSpectrometer.AutoCharge;
var
  ChargerStart: TChargerStartThread;
begin
  ChargerStart := TChargerStartThread.Create(FCharger, Self);
  ChargerStart.Resume;
end;

//--------------------------------------------------

function TSpectrometer.NextSpectrum: Boolean;
begin
  Result := True;
  if FSb <> nil then
    if not FSb.Up then
      Result := False;
end;

//--------------------------------------------------

function TSpectrometer.PrevSpectrum: Boolean;
begin
  Result := True;
  if (FSb <> nil) then
    if not FSb.Down then
      Result := False;
end;

//--------------------------------------------------

procedure TSpectrometer.CreateModules;
var
  E2010: TPlata;
begin
  E2010 := TPlata.PlataCreate;
  FAdcSpectrMeassure := TAdcSpectr.Create(E2010);          // ��� ��������� (������ + ����)
  FAdcLevelSignal := TAdcLevelSignal.Create(E2010);        // ��� ������ �������
  FCharger := TCharger.Init(E2010);                        // �����-������
  FSb := TSpectrumBase.Init;                        // ���� ��������
  FTempSensor := TemperatureSensor.Init;            // ������ �����������
  FVoltmeter := TVoltmeter.Init(E2010, LcardChannelAdcVoltage);                    // ���������
end;

//--------------------------------------------------

procedure TSpectrometer.InitE2010Only;
var
  E2010: TPlata;
begin
  if (FAdcSpectrMeassure <> nil) and (FAdcLevelSignal <> nil) then
  begin
    E2010 := TPlata.PlataCreate;
    FAdcSpectrMeassure.Create(E2010);          // ��� ��������� (������ + ����)
    FAdcLevelSignal.Create(E2010);             // ��� ������ �������
  end;
  if ReadyADC then
  begin
    FAdcLevelSignal.Prepare;
  end;
end;

//--------------------------------------------------

function TSpectrometer.Debug: boolean;
begin
{$if Defined(debug)}
  Result := True;
{$else}
  Result := False;
{$ifend}
end;

//--------------------------------------------------

function TSpectrometer.UnderThreshold: boolean;
begin
  Result := TempSensor.UnderThreshold;
end;

//--------------------------------------------------

function TSpectrometer.ReadyADC: Boolean;
begin
  Result := FAdcSpectrMeassure.Ready and FAdcLevelSignal.Ready;
end;

{ TChargerThread }

constructor TChargerThread.create(Charger: TCharger);
begin
  inherited Create(True);
  FCharger := Charger;
  Priority := tpHighest;
  FreeOnTerminate := true;
end;

//--------------------------------------------------

procedure TChargerThread.Execute;
begin
  inherited;
  sleep(1);
  FCharger.UnCharge;
end;

{ TChargerStartThread }

constructor TChargerStartThread.create(Charger: TCharger; Spectrometer: TSpectrometer);
begin
  inherited Create(True);
  FCharger := Charger;
  FSpectrometer := Spectrometer;
  Priority := tpHighest;
  FreeOnTerminate := true;
end;

//--------------------------------------------------

procedure TChargerStartThread.Execute;
var
  Unew, Unew1: real;
begin
  inherited;
  FSpectrometer.FFullyCharge := false;
  FCharger.Charge;
  Delay(1000);
  with FSpectrometer do
  begin
    repeat
      repeat
        Delay(500);
        Unew := GetChargeVoltage;
      until Unew < 1000;
      Delay(500);
      repeat
        Unew1 := GetChargeVoltage;
        Delay(500);
      until Unew1 < 1000;
    until abs(Unew - Unew1) < 1;
    Delay(500);
    FFullyCharge := True;
  end;
end;

//===================================================


procedure TSpectrometer.SetTempZeroCompensation(ZeroCorrection: double);
begin
  FTempSensor.ZeroCorrection:=ZeroCorrection;
end;

end.