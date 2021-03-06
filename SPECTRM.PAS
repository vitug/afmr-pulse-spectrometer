{************************************************************}
{                                                            }
{                 Module ���                                 }
{       Copyright (c) 2001  ��� ����                         }
{               �����/������                                 }
{                                                            }
{  �����������: �� ��                                        }
{  �������������: 05 ������� 2008                            }
{                                                            }
{************************************************************}
Unit spectrm;

Interface

uses
  Basic, Charger, tempr_s, Mathematic, CommonTypes, FileRelis,
  SysUtils, Dialogs, Windows;

type

    PTPulseGenerator = ^TPulseGenerator;
    TPulseGenerator = class
    private
      FBeginParamCircuit: TParameters; //��������� ��������� �������� (��������� ����)
      FParamCircuit: TParameters;      //����������� ��������� ���� / ��������
      FRiseUpCoefSet: TPulseEdgeCoefSet;// ������������ ��������� ������� ���� (�������� �����)
      FDownCoefSet: TPulseEdgeCoefSet;  // ������������ ��������� ������� ���� (������ �����)
      FField: TADC_DATA;               //������ ���� (������������)
      FTimeMidleRealField: double;     //����� �������� ��������� ��������(�������� ����), �� � ������������������ �������� 
      FTimeBeginRealField: double;     //����� ������ ��������� ��������(������� ����) ��� ��������� �������
      FTimeEndRealField: double;       //����� ����� ��������� ��������(������� ����)  ��� ��������� �������
      FError: double;                  //������ ������������������
      FMaxErrorFit: double;            //������ ������������������ ������������ (�������� �������, ��� ��������� � ���������)
      procedure FindMaxOfDiff(Signal: TADC_DATA);  //������� �������� �������� �� �������� �����������
      procedure FindMaxClassic(Signal: TADC_DATA); // ������� ����� ��������� �� �������� ����
      procedure FindMaxOfModel(Signal: TADC_DATA); // ����� ��������� ��������� ������ ��� ������ � ������� ������
      procedure SetRiseCoefSet(const Value: TPulseEdgeCoefSet);
      procedure SetDownCoefSet(const Value: TPulseEdgeCoefSet);
      procedure SetBeginParamCircuit(const Value: TParameters);
      function RecalcTime(AdcData, ResizeAdcData: TADC_DATA): TADC_DATA;   // ������������� ����� �� ������� ������ ��� �������� ������� � �������� � ���� 0..��������������
    public
      constructor Create; //�����������
      function GetField(Time: real;  ChargeVoltage: double; PulseEdge: TFrontBack = fbFront): real;  {���� �������� ���� � ������ ������� time � ���������� �����������}
      function Fit (Field: TADC_DATA; ChargeVoltage: double): integer;   {��������� �������� ����}
      procedure FindMax(Signal: TADC_DATA); // ����� ��������� ��������
      function GetFieldFit(Time: real;  ChargeVoltage: double; PrCirct: TParameters; PulseEdge: TFrontBack): real;  {���� �������� ���� (����� ��������) � ������ ������� time}
      function GetFitValue(Time: real; ChargeVoltage: double; PrCirct: TParameters): real;  {���� �������� ����� �������� � ������ ������� time}
      function RecalcSignal(Signal: TADC_DATA): TADC_DATA;
      function RecalcSignalFull(Signal: TADC_DATA): TADC_DATA; // �������� ������ �� ������ �������� � �� ����� ���������
      destructor Done;
      property RiseUpCoefSet: TPulseEdgeCoefSet read FRiseUpCoefSet write SetRiseCoefSet;
      property DownCoefSet: TPulseEdgeCoefSet read FDownCoefSet write SetDownCoefSet;
      property BeginParamCircuit: TParameters read FBeginParamCircuit write SetBeginParamCircuit;
      property ErrorFit: double read FError;
      property MaxErrorFit: double read FMaxErrorFit write FMaxErrorFit;
    end;

    PTSpectrum = ^TSpectrum;
    TSpectrum = class{�������� ������, �����������, ������� � ��.}
    private
      FSpectrDescription: TSpectrDescription; // �������������� ���������� ������������
      FSpectrData: TSpectrData;       // ������ �������
      FPulseData: TADC_DATA;          // ������ ���� (������������)
      FSignalData: TADC_DATA;         // ������ ������� (������������)
      FFileNumber: integer;             //����� ����� ��� ������� �������� ������
      FParamCircuit_Fit: TParameters;   // ��������� ���� ����� �������� (����� ��� ����������� ����.�������� � ������ ���������)
    protected
      procedure copy_linear (From, To_: TSpectrData);
      procedure copy_linearADCData(From, To_: TADC_DATA);
    public
      constructor InitEstimateFieldFit(Signal_: TADC_DATA; PulseGen_: TPulseGenerator;
        SpectrDescription_: TSpectrDescription);
      constructor InitCopyClass(From_: TSpectrum);
      destructor Done; virtual;
      property SpectrData: TSpectrData read FSpectrData;
      property PulseData: TADC_DATA read FPulseData;
      property SignalData: TADC_DATA read FSignalData;
      property SpectrDescription: TSpectrDescription read FSpectrDescription;
      property FileNumber: integer read FFileNumber write FFileNumber;
      property ParamCircuit_Fit: TParameters read FParamCircuit_Fit;
    end;

    PTDataQueue = ^TDataQueue;
    {�������� ������� ������� ���������� ������ � ��������� �� ���������� � ��������� �������}
    TDataQueue = class
    private
      FContent: TSpectrum;
      FPrev: TDataQueue;
      FNext: TDataQueue;
    public
      constructor Init(Content_: TSpectrum; Prev_, Next_: TDataQueue);
      destructor Done;
      property Content: TSpectrum read FContent write FContent;
    end;

    PTSpectrumBase = ^TSpectrumBase;
    TSpectrumBase = class
    private
       FData: TDataQueue;
       FOrigin: TDataQueue;
       FEndofBase: TDataQueue;
       FIterator: word;
       FIteratorEnd: word;

       procedure SaveHeading(var F: Text; Description: TSpectrDescription);    //���������� ��������� � ����
     public
       constructor Init;
       procedure Add(DataIn: TSpectrum);        //���������� �������� � �������
       procedure Delete;                        //�������� �������� �������
       procedure DeleteInBegin;
       function Up: boolean;                    //������� � ���������� ��������
       function Down: boolean;                  //������� � ����������� ��������
       procedure BeginBase;                     //������� � ������
       procedure EndBase;                       //������� � ����� �������
       procedure SaveData(NameofFile: String);  //������ ������� �� ����
       procedure SavePulse(NameofFile: String); //������ �������� ���� �� ����
       procedure SaveSignal(NameofFile: String);// ������ ������� �� ������� �� ����
       procedure Clear;                         //������� �������
       function GetCurrent: TSpectrum;
       property Data: TDataQueue read FData write FData;
    end;

implementation



//==================================================

constructor  TSpectrum.InitEstimateFieldFit(Signal_: TADC_DATA; PulseGen_: TPulseGenerator;
        SpectrDescription_: TSpectrDescription);
var
  i, j: longint;
  CalcField: Double;

begin
  inherited Create;
  FFileNumber := 0; // ����� ����� (����������� ��� ������ �� StartRecord)
  // �������� ���� (����� ��� ������������ ����������� � ��� ������ ��� � ���������� �����)
  FPulseData := PulseGen_.FField;
  // �������� ������ (����� ��� ������ ��� � ���������� �����)
  FSignalData := Signal_;
  // ��������� ���� ��� ������� �������� ��� ������� (����� ����� ��� ������������ �����������)
  FParamCircuit_Fit := PulseGen_.FParamCircuit;

  //������ �������� �������� (��� ���������� �� �������� � ������ �����)
  PulseGen_.FindMax(Signal_);
  
  //�������� �������
  FSpectrDescription := SpectrDescription_;
  //������ ������������� �� ����
  FSpectrDescription.ErrorFit := PulseGen_.FError;

{��������� ��������� �� �������� ��� ������ ����� �������� � ����������� �� FrontBack}

//------��������� �� ��������� ������-------
  j := 0;
  if FSpectrDescription.FrontBack = fbFront then
  begin
    for i := 0 to length(Signal_) - 1 do
    begin
      if Signal_[i].time <= PulseGen_.FTimeMidleRealField then
      begin
        SetLength(FSpectrData, length(FSpectrData) + 1);
        FSpectrData[j].x := PulseGen_.GetFieldFit(Signal_[i].time, FSpectrDescription.ChargeVoltage, FParamCircuit_Fit, fbFront);
        FSpectrData[j].y.Quant := Signal_[i].quantization_step;
        FSpectrData[j].y.Voltage := Signal_[i].voltage;
        inc(j);
      end;
    end; //end for
  end; // end if FrontBack

  //------��������� �� ������� ������-------
  if FSpectrDescription.FrontBack = fbBack then
  begin
    for i := 0 to length(Signal_) - 1 do
    begin
      if Signal_[i].time >= PulseGen_.FTimeMidleRealField then
      begin
        CalcField := PulseGen_.GetFieldFit(Signal_[i].time, FSpectrDescription.ChargeVoltage, FParamCircuit_Fit, fbBack);
        {��������� "����������������" ������ �� ���������,
        ������ ��������, ����� ���� ������ ������������� � ��������� ����}
        if CalcField < 0 then
          break;
        SetLength(FSpectrData, length(FSpectrData) + 1);
        FSpectrData[j].x := CalcField;
        FSpectrData[j].y.Quant := Signal_[i].quantization_step;
        FSpectrData[j].y.Voltage := Signal_[i].voltage;
        inc(j);
      end;
    end; //end for
  end; // end if FrontBack

  FFileNumber := 1;

end;

//--------------------------------------------------

constructor TSpectrum.InitCopyClass(From_: TSpectrum);
begin
  SetLength(FSpectrData, Length(From_.FSpectrData));
  copy_linear(From_.FSpectrData, FSpectrData);
  SetLength(FPulseData, Length(From_.FPulseData));
  copy_linearADCData(From_.FPulseData, FPulseData);
  SetLength(FSignalData, Length(From_.FSignalData));
  copy_linearADCData(From_.FSignalData, FSignalData);
  FSpectrDescription := From_.FSpectrDescription;
  FFileNumber := From_.FFileNumber;
  FParamCircuit_Fit := From_.FParamCircuit_Fit;
end;

//--------------------------------------------------

procedure TSpectrum.copy_linear(From, To_: TSpectrData);
var
  i: integer;
begin
  for i := low(From) to High(From) do
    To_[i] := From[i];
end;

//--------------------------------------------------

procedure TSpectrum.copy_linearADCData(From, To_: TADC_DATA);
var
  i: integer;
begin
  for i := low(From) to High(From) do
    To_[i] := From[i];

end;

//--------------------------------------------------

destructor TSpectrum.Done;
begin
//
end;

//===================================================

constructor TDataQueue.Init(Content_: TSpectrum; Prev_, Next_: TDataQueue);
begin
   if Content_ <> nil then
   begin
     FContent := TSpectrum.InitCopyClass(Content_);
     Content_.Done;
     FPrev := Prev_;
     FNext := Next_;
   end;       
end;

//--------------------------------------------------

destructor TDataQueue.Done;
begin
  FContent.Done;
end;

//===================================================

constructor TSpectrumBase.Init;
begin
  FData := nil;
  FOrigin := Data;
  FIterator := 0;
end;

//--------------------------------------------------

procedure TSpectrumBase.Add(DataIn: TSpectrum);
var
  DataTemp: TDataQueue;
begin
  if DataIn <> nil then
  begin
    EndBase;
    FIterator := FIterator + 1;
    DataTemp := FData;
    FData := TDataQueue.Init(DataIn, DataTemp, nil);
    if DataTemp = nil then
    begin
      FOrigin := Data;
      FData.FNext := nil;
      FData.FPrev := nil;
    end
    else
      FData.FPrev.FNext := FData;
     if Data.FNext <> nil then
     begin
       FData.FNext.FPrev := FData;
       FIteratorEnd := FIteratorEnd + 1;
     end
     else
     begin
       FEndofBase := FData;
       FIteratorEnd := FIterator;
     end;
  end;

end;

//--------------------------------------------------

procedure TSpectrumBase.Delete;
var
   TD: TDataQueue;
begin
    if FData <> nil then
    begin
      if FIterator > 1 then
        FIterator := FIterator - 1;
      TD := FData;
      if FData.FPrev <> nil then
      begin
        FData.FPrev.FNext := FData.FNext;
        FData := FData.FPrev;
      end
      else
      begin
        FData := FData.FNext;
        FOrigin := FData;
        if FData <> nil then
          FData.FPrev := nil;
      end;
      TD.Done;
    end;
end;

//--------------------------------------------------

function TSpectrumBase.Up: boolean;
begin
  Result := False;
  if (FData <> nil) and (FData <> nil) then
  begin
    if FData.FNext <> nil then
    begin
      FIterator := FIterator + 1;
      FData := FData.FNext;
      Result := True;
    end
    else
      Result := False;
    end;
end;

//--------------------------------------------------

function TSpectrumBase.Down: boolean;
begin
  Result := False;
  if (FData <> nil) and (FData <> nil) then
  begin
    if FData.FPrev <> nil then
    begin
      FIterator := FIterator - 1;
      FData := FData.FPrev;
      Result := True;
     end
     else
      Result := False;
    end;
end;

//--------------------------------------------------

procedure TSpectrumBase.BeginBase;
begin
  if FData <> nil then
  begin
    FData := FOrigin;
    FIterator := 1;
  end;
end;

//--------------------------------------------------

procedure TSpectrumBase.EndBase;
begin
  if FData <> nil then
  begin
    if FData.FNext <> nil then
    FData := FEndofBase;
    FIterator := FIteratorEnd;
  end;
end;

//--------------------------------------------------

procedure TSpectrumBase.SaveHeading(var F: Text; Description: TSpectrDescription);
var
  StrFrontBack: String;
begin
  Writeln(F, '___Summary_information___');
  Writeln(F, 'Object= ', Description.Crystal);
  Writeln(F, 'Generator= ', Description.Generator);
  Writeln(F, 'Section= ', Description.Section);
  Writeln(F, 'Thermopair= ', Description.Thermopair);
  Writeln(F, 'Orientation= ', Description.Orientation);
  Writeln(F, 'Remarks= ', Description.Comment);
  Writeln(F, 'ADC_Frequency= ', Description.ADCFrequency, 'KHz');
  Writeln(F, 'Amount(Field/Signal)= ', Description.ADCFieldDivSignal);
  Writeln(F, 'Charge_Voltage= ', FloatToStrF(Description.ChargeVoltage , ffFixed, 6, 3, FormatSettings ), 'V');
  Writeln(F, 'Frequency= ', FloatToStrF(Description.Frequency, ffFixed, 6, 3 , FormatSettings), 'GHz');
  Writeln(F, 'Temperature= ', FloatToStrF(Description.Temperature, ffFixed, 6, 3, FormatSettings), 'K');
  Writeln(F, 'Voltage_on_termopare= ', FloatToStrF(Description.ThermopairVoltage, ffFixed, 6, 3, FormatSettings), 'mkV');
  Writeln(F, 'Rotation_Angle= ', FloatToStrF(Description.Angle, ffFixed, 6, 3, FormatSettings), 'Degree');
  // ����� ����� �����
  case Description.FrontBack of
    fbFront:  StrFrontBack := 'Front';
    fbBack: StrFrontBack := 'Back';
    fbFull: StrFrontBack := 'Full';
  end;
  Writeln(F, 'Front_Back= ', StrFrontBack);
  Writeln(F, 'ErrorFit= ', FloatToStrF(Description.ErrorFit, ffGeneral, 3, 1, FormatSettings));
  Writeln(F, 'Amplifier_Scale= ', FloatToStrF(Description.AmplifierScale, ffFixed, 6, 3, FormatSettings));

  //16 ����� �����
  //���������� ��� 3 ������
  Writeln(F);Writeln(F);Writeln(F);
end;

//--------------------------------------------------

procedure TSpectrumBase.SaveData(NameofFile: String);
var
  F: Text;
  i: integer;
begin
  AssignFile(F, NameofFile);
  Rewrite(F);
  try
    if FData <> nil then
    begin
      if length(FData.FContent.FSpectrData ) > 1 then
      begin
        With FData.FContent do
        begin
          SaveHeading(F, FSpectrDescription);
          //����� �����
          for i := 0 to Length(FSpectrData) - 1 do
            Writeln(F, FloatToStrF(FSpectrData[i].x, ffFixed, 10, 6, FormatSettings), '  ', FloatToStrF(FSpectrData[i].y.Voltage, ffFixed, 9, 6, FormatSettings));
        end; //With FData.FContent
      end
      else
        Writeln(F, 'No Data');
    end //if Data<>nil
    else
      Writeln(F,'Error spectrBase. Data is nil');
  finally
    CloseFile(F);
  end;
end;

//--------------------------------------------------

procedure TSpectrumBase.SavePulse(NameofFile: String);
var
  F: Text;
  i: integer;
  SpDescript: TSpectrDescription;
begin
  AssignFile(F, NameofFile);
  Rewrite(F);
  try
    if FData <> nil then
    begin
      if length(FData.FContent.FPulseData) > 1 then
      begin
        with FData.FContent do
        begin
          SpDescript := FSpectrDescription;
          SpDescript.FrontBack := fbFull;
          SaveHeading(F, SpDescript);
          //����� �����
          for i := 0 to Length(FPulseData) - 1 do
            Writeln(F, FloatToStr(FPulseData[i].Time, FormatSettings), '  ', FloatToStr(FPulseData[i].Voltage, FormatSettings));
        end;
      end
      else
        Writeln(F, 'No Data');
    end     //if Data<>nil
    else
      Writeln(F,'Error spectrBase. Data is nil');
  finally
    CloseFile(F);
  end;
//
end;

//--------------------------------------------------

procedure TSpectrumBase.SaveSignal(NameofFile: String);
var
  F: Text;
  i: integer;
  SpDescript: TSpectrDescription;
begin
  AssignFile(F, NameofFile);
  Rewrite(F);
  try
    if FData <> nil then
    begin
      if length(FData.FContent.FSignalData) > 1 then
      begin
        with FData.FContent do
        begin
          SpDescript := FSpectrDescription;
          SpDescript.FrontBack := fbFull;
          SaveHeading(F, SpDescript);
          //����� �����
          for i := 0 to Length(FSignalData) - 1 do
            Writeln(F, FloatToStr(FSignalData[i].Time, FormatSettings), '  ', FloatToStr(FSignalData[i].Voltage, FormatSettings));
        end;
      end
      else
        Writeln(F, 'No Data');
    end     //if Data<>nil
    else
      Writeln(F,'Error spectrBase. Data is nil');
  finally
    CloseFile(F);
  end;
//
end;

//--------------------------------------------------

procedure TSpectrumBase.Clear;
begin
  if FData <> nil then
  begin
    EndBase;
    while FData.FPrev <> nil do
    begin
      Down;
      FData.FNext.Done;
    end;
    FData.Done;
    FData.FNext := nil;
    FData := nil;
    FIterator := 0;
 end;
end;

//--------------------------------------------------

procedure TSpectrumBase.DeleteInBegin;
var
  Td: TDataQueue;
begin
  if (FData <> nil)  and (FIterator > 1) then
  begin
    Td := FOrigin;
    FOrigin := FOrigin.FNext;
    FOrigin.FPrev := nil;
    Td.Done;
    Dec(FIterator);
  end;
end;

//--------------------------------------------------

function TSpectrumBase.GetCurrent: TSpectrum;
begin
  if (FData = nil) then
    Result := nil
  else
    Result := FData.FContent;
end;

//====================================================

constructor TPulseGenerator.Create;
begin
  inherited Create;
  FError := 0;
end;

//--------------------------------------------------

function TPulseGenerator.RecalcTime(AdcData, ResizeAdcData: TADC_DATA): TADC_DATA;
var
  i: longint;
begin
  for i := 0 to length(ResizeAdcData) - 1 do
  begin
    ResizeAdcData[i].time := ResizeAdcData[i].time - FTimeBeginRealField;
  end;
  Result := ResizeAdcData;
end;

//--------------------------------------------------

function TPulseGenerator.fit(Field: TADC_DATA; ChargeVoltage: double): integer;
var
  i, j: longint;
  ZeroShiftQuant: integer;
  Max, Min: SHORT;
  MaxIndex, MinIndex: longint;
  ZeroShiftVolt: double;
  TempArrayField: TADC_DATA;
  TempArrayFieldLeft, TempArrayFieldRight: TADC_DATA;
  s: String;
  tmpArrayX, tmpArrayY :TDataXY;
  TempParam: TParameters;
begin
  Result := -3;
  //������� ������� �������� �� ������ ������� �����
  {������ �������� ���� ���, ��� �����
  ��������� ��������� ������ PointForZero ����� (��� ������ ������� ��� � ����� ������� ��� �����).
  }
  ZeroShiftQuant := 0; //����� � ���������
  ZeroShiftVolt := 0;  //����� � �������
  for i := 0 to PointForZero - 1  do
  begin
    ZeroShiftVolt := ZeroShiftVolt + Field[i].voltage;
    ZeroShiftQuant := ZeroShiftQuant + Field[i].quantization_step;
  end;
  ZeroShiftVolt := ZeroShiftVolt / PointForZero;
  ZeroShiftQuant := Round(ZeroShiftQuant / PointForZero);

  //������� ������������ ����������� �������� � ������ �������� ����
  for i := 0 to length(Field) - 1 do
  begin
    Field[i].quantization_step :=  Field[i].quantization_step - ZeroShiftQuant;
    Field[i].voltage :=  Field[i].voltage - ZeroShiftVolt;
  end;

  //������ �������� ��������, ������ ������ � ������� ����, ��� ��� �����������
  //���� ����� �� �����
  Max := 0;
  for i := 0 to length(Field) - 1 do
  begin
    if Field[i].quantization_step > Max then
    begin
      Max := Field[i].quantization_step;
      MaxIndex := i;
    end;
  end;

  //������ ������� ��������, ������ ������ � ������� ����, ��� ��� ����������
  //���� ������ �� ��������� ������
  Min := 10000;
  for i := MaxIndex to length(Field) - 1  do
  begin
    if Field[i].quantization_step < Min then
    begin
      Min := Field[i].quantization_step;
      MinIndex := i;
    end;
  end;

  //�������� �������� ����� � ��������� ������
  //������ �� ��������� ����� �� ����
  j := 0;
  for i := MaxIndex downto 0 do
  begin
    if Field[i].quantization_step < 0 then
      break;
    SetLength(TempArrayFieldLeft, length(TempArrayFieldLeft) + 1);
    TempArrayFieldLeft[j] := Field[i];
    inc(j);
  end;

  //�������� ������ ����� � ��������� ������
  //������ �� ��������� ������ �� ��������
  j := 0;
  for i := MaxIndex to MinIndex do
  begin
    SetLength(TempArrayFieldRight, length(TempArrayFieldRight) + 1);
    TempArrayFieldRight[j] := Field[i];
    inc(j);
  end;

  //��������� �������� � ������ ������ � ������ �������
  //��������� ������ TempArrayField
  //�������� (�����)
  j := 0;
  for i := High(TempArrayFieldLeft) downto Low(TempArrayFieldLeft) do
  begin
    SetLength(TempArrayField, length(TempArrayField) + 1);
    TempArrayField[j] := TempArrayFieldLeft[i];
    inc(j);
  end;
  //������ (������)
  for i := Low(TempArrayFieldRight) to High(TempArrayFieldRight) do
  begin
    SetLength(TempArrayField, length(TempArrayField) + 1);
    TempArrayField[j] := TempArrayFieldRight[i];
    inc(j);
  end;

  //���� �� �������� �������, � �� ����� ����� ���������
  if Length(TempArrayField) >  100 then // 100 ��������, ���� ����� ������ ��������� ��� �� �������
  begin
    // ������� ����� ������ � ����� ��������
    FTimeBeginRealField := TempArrayField[0].time;
    FTimeEndRealField := TempArrayField[length(TempArrayField) - 1].time;

    {����� ����, ��� �������� ������� �� ����� ������ � ��� ����������
     ���������������� ����� � ��� 0..�������������,
     ����� �������� ��������� ��������}
    TempArrayField := RecalcTime(Field, TempArrayField);

    //�������� ������������ ������� � ������ ���������������
    SetLength(FField, length(TempArrayField));
    FField := TempArrayField;

    //������� ������ ������ ��� ��������
    SetLength(tmpArrayX, length(TempArrayField));
    SetLength(tmpArrayY, length(TempArrayField));
    for i := 0 to Length(TempArrayField) - 1 do
    begin
      tmpArrayX[i] := TempArrayField[i].time;
      tmpArrayY[i] := TempArrayField[i].voltage / ChargeVoltage;
    end;

    //������� ���������� ��������� ���������
    FParamCircuit := FBeginParamCircuit;

    //��������� ��������� ��� �������� � �������
    TempParam := FBeginParamCircuit;
    Result := fitNewton(@TempParam, tmpArrayX, tmpArrayY, Length(tmpArrayX));
    if Result = 0 then
    begin
      //��������� ������ ���������, ������� ��������� ���� ��� ��������
      FParamCircuit := TempParam;
    end;
  end; //if length(TempFieldArray) > 100

  //���������� ������ (������ - �����������)^2/���-�� �����
  FError := 0;
  if Length(TempArrayField) > 0 then
  begin
    for i := 0 to Length(TempArrayField) - 1 do
    begin
      FError := FError +
        SQR(func(@FParamCircuit, TempArrayField[i].time) * ChargeVoltage - TempArrayField[i].voltage);
    end;
    FError := FError / Length(TempArrayField);
  end;

  if Result < 0 then
  begin
    s := '�� ������� ��������� ��������' +
      #13 + '������� ����� ��������� � ���������� �����������' +
      #13 + '�������� �������� �� ���������.';
    MessageBox(HWND(nil), PChar(s), '��������', MB_OK+MB_ICONWARNING);
  end;
end;

//--------------------------------------------------

//���� �������� ���� �� �������� �����������
procedure TPulseGenerator.FindMaxOfDiff(Signal: TADC_DATA);
var
  Min: double;
  MaxTime: double;
  i: integer;
begin
  //������� ����� �������� �������� �.�. �������� ��������
  MaxTime :=  FField[length(FField) - 1].time;
  Min := 1000;
  for i := 0 to Length(Signal) - 1  do
  begin
    if Signal[i].time <= MaxTime then
    begin
      if ABS(diff(@FParamCircuit, Signal[i].time)) < Min then
      begin
        Min := ABS(diff(@FParamCircuit, Signal[i].time));
        FTimeMidleRealField := Signal[i].time;
      end;
    end; //if
  end;
end;

//--------------------------------------------------
//���� �������� ����
procedure TPulseGenerator.FindMaxClassic(Signal: TADC_DATA);
var
  Max: double;
  MaxTime: double;
  i: integer;
begin
  //������� ����� �������� �������� �.�. �������� ��������
  MaxTime :=  FField[length(FField) - 1].time;
  Max := 0;
  for i := 0 to Length(Signal) - 1  do
  begin
    if Signal[i].time <= MaxTime then
    begin
      if func(@FParamCircuit, Signal[i].time) > Max then
      begin
        Max := func(@FParamCircuit, Signal[i].time);
        FTimeMidleRealField := Signal[i].time;
      end;
    end; //if
  end;
end;

//--------------------------------------------------
//���� �������� ���� �� ����������� �������� �������� �� �������� � ������ ������
procedure TPulseGenerator.FindMaxOfModel(Signal: TADC_DATA);
var
  Min: double;
  MaxTime: double;
  i: integer;
  fieldFront:double;
  fieldBack:double;
begin
  //������� ����� �������� �������� �.�. �������� ��������
  Min := 10000;
  MaxTime :=  FField[length(FField) - 1].time;
  for i := 0 to Length(Signal) - 1  do
  begin
    if Signal[i].time <= MaxTime then
    begin
      fieldBack := GetFieldFit(Signal[i].time, 220, FParamCircuit, fbBack);
      fieldFront := GetFieldFit(Signal[i].time, 220, FParamCircuit, fbFront);
      if Abs(fieldFront - fieldBack) < Min then
      begin
        Min := Abs(fieldFront - fieldBack);
        FTimeMidleRealField := Signal[i].time;
      end;
    end; //if
  end;

end;

//--------------------------------------------------

procedure TPulseGenerator.FindMax(Signal: TADC_DATA);
begin
  //���� �����-�� ��� ������� ���� ������ ��������� FindMaxOfModel
  if (FRiseUpCoefSet.k1 <> FDownCoefSet.k1) or (FRiseUpCoefSet.k2 <> FDownCoefSet.k2) or
    (FRiseUpCoefSet.k3 <> FDownCoefSet.k3) then
      FindMaxOfModel(Signal)
  else
    FindMaxClassic(Signal);
end;

//--------------------------------------------------

function TPulseGenerator.GetFieldFit(Time: real;  ChargeVoltage: double; PrCirct: TParameters; PulseEdge: TFrontBack): real;
var
  f: Double;
  CoefSet: TPulseEdgeCoefSet;
begin
  f := func(@PrCirct, Time) * ChargeVoltage;

  if PulseEdge = fbFront then
    CoefSet := FRiseUpCoefSet
  else
    CoefSet := FDownCoefSet;

  if (Time >= PrCirct[prmT]) then
    Result := CoefSet.k1 * (f + CoefSet.k2 * diff(@PrCirct, Time) * ChargeVoltage) + CoefSet.k3
  else
    Result := 0;

end;

//--------------------------------------------------
//���������� �������� �������, ������� ��������� �������
function TPulseGenerator.GetFitValue(Time: real; ChargeVoltage: double; PrCirct: TParameters): real;
begin
  Result := func(@PrCirct , Time) * ChargeVoltage;
end;

//--------------------------------------------------
//������������ ��� ��������������� ������ ������������� ���������� ����, ����� ���� ����� �������.
function TPulseGenerator.GetField(Time: real;  ChargeVoltage: double; PulseEdge: TFrontBack = fbFront): real;
var
  f: Double;
  CoefSet: TPulseEdgeCoefSet;

begin
  f := func(@FBeginParamCircuit, Time) * ChargeVoltage;

  if PulseEdge = fbFront then
    CoefSet := FRiseUpCoefSet
  else
    CoefSet := FDownCoefSet;

  if (Time >= FBeginParamCircuit[prmT]) then
    Result := CoefSet.k1 * (f + CoefSet.k2 * diff(@FBeginParamCircuit, Time) * ChargeVoltage) + CoefSet.k3
  else
    Result := 0;

end;

//--------------------------------------------------
{������� "������� ����������" �� ����� ������� �� ������ ���.
� ��������� ������� ��������}
function TPulseGenerator.RecalcSignal(Signal: TADC_DATA): TADC_DATA;
var
  i, j: longint;
  TempArraySignal: TADC_DATA;

begin
  j := 0;
  for i := 0 to length(Signal) - 1 do
  begin
    if (Signal[i].time >= FTimeBeginRealField) and (Signal[i].time <= FTimeEndRealField) then
    begin
      inc(j);
      SetLength(TempArraySignal, j);
      TempArraySignal[j - 1] := Signal[i];
    end;
  end;

   {����� ����, ��� �������� ������ �� ����� ������ � ��� ����������
   ���������������� ����� � ��� 0..������������ c ������ ������� ������ ��������
   }
 Result := RecalcTime(Signal, TempArraySignal);
end;

//--------------------------------------------------
{������� "������� ����������" �� ����� ������� �� ������ ���.
� ��������� ��������������..legth(����� ��� ������� ����������)}
function TPulseGenerator.RecalcSignalFull(Signal: TADC_DATA): TADC_DATA;
var
  i, j: longint;
  TempArraySignal: TADC_DATA;

begin
  j := 0;
  for i := 0 to length(Signal) - 1 do
  begin
    if (Signal[i].time >= FTimeBeginRealField) then
    begin
      inc(j);
      SetLength(TempArraySignal, j);
      TempArraySignal[j - 1] := Signal[i];
    end;
  end;

  {����� ����, ��� �������� ������ �� ����� ������ � ��� ����������
   ���������������� ����� � ��� 0..������������ c ������ ������� ������ ��������
  }
 Result := RecalcTime(Signal, TempArraySignal);

end;

//--------------------------------------------------

Destructor TPulseGenerator.Done;
begin
//
end;

//--------------------------------------------------

procedure TPulseGenerator.SetRiseCoefSet(const Value: TPulseEdgeCoefSet);
begin
  FRiseUpCoefSet := Value;
end;

//--------------------------------------------------

procedure TPulseGenerator.SetDownCoefSet(const Value: TPulseEdgeCoefSet);
begin
  FDownCoefSet := Value;
end;

//--------------------------------------------------

procedure TPulseGenerator.SetBeginParamCircuit(const Value: TParameters);
begin
  FBeginParamCircuit := Value;
end;

//==================================================


end.
