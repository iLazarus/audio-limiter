unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Math,
  LCLIntf, LCLType, StdCtrls, LazUTF8, Menus, Windows, ComObj, ActiveX;

const
  WM_NCLBUTTONDOWN = $00A1;
  CB_SETDROPPEDWIDTH = $0160;
  
  // Core Audio API GUIDs
  CLSID_MMDeviceEnumerator: TGUID = '{BCDE0395-E52F-467C-8E3D-C4579291692E}';
  IID_IMMDeviceEnumerator: TGUID = '{A95664D2-9614-4F35-A746-DE8DB63617E6}';
  IID_IAudioMeterInformation: TGUID = '{C02216F6-8C67-4B5B-9D00-D008E73E0064}';
  IID_IAudioClient: TGUID = '{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}';
  IID_IAudioCaptureClient: TGUID = '{C8ADBD64-E71E-48a0-A4DE-185C395CD317}';
  IID_IAudioRenderClient: TGUID = '{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}';

type
  EDataFlow = (
    eRender = 0,
    eCapture = 1,
    eAll = 2
  );

  ERole = (
    eConsole = 0,
    eMultimedia = 1,
    eCommunications = 2
  );

  // Forward declarations
  IMMDevice = interface;
  IMMDeviceCollection = interface;
  IPropertyStore = interface;
  IMMNotificationClient = interface;

  PROPERTYKEY = record
    fmtid: TGUID;
    pid: DWORD;
  end;

  IMMDeviceEnumerator = interface(IUnknown)
    ['{A95664D2-9614-4F35-A746-DE8DB63617E6}']
    function EnumAudioEndpoints(dataFlow: EDataFlow; dwStateMask: DWORD; out ppDevices: IMMDeviceCollection): HRESULT; stdcall;
    function GetDefaultAudioEndpoint(dataFlow: EDataFlow; role: ERole; out ppEndpoint: IMMDevice): HRESULT; stdcall;
    function GetDevice(pwstrId: LPCWSTR; out ppDevice: IMMDevice): HRESULT; stdcall;
    function RegisterEndpointNotificationCallback(pClient: IUnknown): HRESULT; stdcall;
    function UnregisterEndpointNotificationCallback(pClient: IUnknown): HRESULT; stdcall;
  end;

  IMMDeviceCollection = interface(IUnknown)
    ['{0BD7A1BE-7A1A-44DB-8397-CC5392387B5E}']
    function GetCount(out pcDevices: UINT): HRESULT; stdcall;
    function Item(nDevice: UINT; out ppDevice: IMMDevice): HRESULT; stdcall;
  end;

  IMMDevice = interface(IUnknown)
    ['{D666063F-1587-4E43-81F1-B948E807363F}']
    function Activate(const iid: TGUID; dwClsCtx: DWORD; pActivationParams: Pointer; out ppInterface): HRESULT; stdcall;
    function OpenPropertyStore(stgmAccess: DWORD; out ppProperties: IPropertyStore): HRESULT; stdcall;
    function GetId(out ppstrId: LPWSTR): HRESULT; stdcall;
    function GetState(out pdwState: DWORD): HRESULT; stdcall;
  end;

  IAudioMeterInformation = interface(IUnknown)
    ['{C02216F6-8C67-4B5B-9D00-D008E73E0064}']
    function GetPeakValue(out pfPeak: Single): HRESULT; stdcall;
    function GetMeteringChannelCount(out pnChannelCount: UINT): HRESULT; stdcall;
    function GetChannelsPeakValues(u32ChannelCount: UINT; afPeakValues: PSingle): HRESULT; stdcall;
    function QueryHardwareSupport(out pdwHardwareSupportMask: DWORD): HRESULT; stdcall;
  end;

  IPropertyStore = interface(IUnknown)
    ['{886d8eeb-8cf2-4446-8d02-cdba1dbdcf99}']
    function GetCount(out cProps: DWORD): HRESULT; stdcall;
    function GetAt(iProp: DWORD; out pkey: PROPERTYKEY): HRESULT; stdcall;
    function GetValue(const key: PROPERTYKEY; out pv: PROPVARIANT): HRESULT; stdcall;
    function SetValue(const key: PROPERTYKEY; const propvar: PROPVARIANT): HRESULT; stdcall;
    function Commit: HRESULT; stdcall;
  end;

  WAVEFORMATEX = record
    wFormatTag: Word;
    nChannels: Word;
    nSamplesPerSec: DWORD;
    nAvgBytesPerSec: DWORD;
    nBlockAlign: Word;
    wBitsPerSample: Word;
    cbSize: Word;
  end;
  PWAVEFORMATEX = ^WAVEFORMATEX;

  IAudioClient = interface(IUnknown)
    ['{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}']
    function Initialize(ShareMode: DWORD; StreamFlags: DWORD; hnsBufferDuration: Int64;
      hnsPeriodicity: Int64; pFormat: PWAVEFORMATEX; AudioSessionGuid: PGUID): HRESULT; stdcall;
    function GetBufferSize(out pNumBufferFrames: UINT32): HRESULT; stdcall;
    function GetStreamLatency(out phnsLatency: Int64): HRESULT; stdcall;
    function GetCurrentPadding(out pNumPaddingFrames: UINT32): HRESULT; stdcall;
    function IsFormatSupported(ShareMode: DWORD; pFormat: PWAVEFORMATEX;
      out ppClosestMatch: PWAVEFORMATEX): HRESULT; stdcall;
    function GetMixFormat(out ppDeviceFormat: PWAVEFORMATEX): HRESULT; stdcall;
    function GetDevicePeriod(out phnsDefaultDevicePeriod: Int64;
      out phnsMinimumDevicePeriod: Int64): HRESULT; stdcall;
    function Start: HRESULT; stdcall;
    function Stop: HRESULT; stdcall;
    function Reset: HRESULT; stdcall;
    function SetEventHandle(eventHandle: THandle): HRESULT; stdcall;
    function GetService(const riid: TGUID; out ppv): HRESULT; stdcall;
  end;

  IAudioCaptureClient = interface(IUnknown)
    ['{C8ADBD64-E71E-48a0-A4DE-185C395CD317}']
    function GetBuffer(out ppData: PByte; out pNumFramesToRead: UINT32;
      out pdwFlags: DWORD; out pu64DevicePosition: UINT64;
      out pu64QPCPosition: UINT64): HRESULT; stdcall;
    function ReleaseBuffer(NumFramesRead: UINT32): HRESULT; stdcall;
    function GetNextPacketSize(out pNumFramesInNextPacket: UINT32): HRESULT; stdcall;
  end;

  IAudioRenderClient = interface(IUnknown)
    ['{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}']
    function GetBuffer(NumFramesRequested: UINT32; out ppData: PByte): HRESULT; stdcall;
    function ReleaseBuffer(NumFramesWritten: UINT32; dwFlags: DWORD): HRESULT; stdcall;
  end;

  IMMNotificationClient = interface(IUnknown)
    ['{7991EEC9-7E89-4D85-8390-6C703CEC60C0}']
    function OnDeviceStateChanged(pwstrDeviceId: LPCWSTR; dwNewState: DWORD): HRESULT; stdcall;
    function OnDeviceAdded(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnDeviceRemoved(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnDefaultDeviceChanged(flow: EDataFlow; role: ERole; pwstrDefaultDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnPropertyValueChanged(pwstrDeviceId: LPCWSTR; const key: PROPERTYKEY): HRESULT; stdcall;
  end;

const
  DEVICE_STATE_ACTIVE = $00000001;
  STGM_READ = $00000000;
  
  // AudioClient Constants
  AUDCLNT_SHAREMODE_SHARED = 0;
  AUDCLNT_SHAREMODE_EXCLUSIVE = 1;
  AUDCLNT_STREAMFLAGS_EVENTCALLBACK = $00040000;
  AUDCLNT_STREAMFLAGS_LOOPBACK = $00020000;
  
  // PKEY_Device_FriendlyName
  PKEY_Device_FriendlyName: PROPERTYKEY = (
    fmtid: '{A45C254E-DF1C-4EFD-8020-67D146A850E0}';
    pid: 14
  );

// PropVariant helper functions
procedure PropVariantInit(pv: PPropVariant); inline;
function PropVariantClear(pv: PPropVariant): HRESULT; stdcall; external 'ole32.dll' name 'PropVariantClear';

type
  // 音频压缩器/限制器类
  TAudioCompressor = class
  private
    FSampleRate: Single;
    FThreshold: Single;
    FPeakAt: Single;      // 峰值检测 attack tau
    FPeakRt: Single;      // 峰值检测 release tau
    FPeakAverage: Single;
    FGainAt: Single;      // 增益 attack tau
    FGainRt: Single;      // 增益 release tau
    FGainAverage: Single;
    // 前瞻缓冲区
    FLookaheadBuffer: array of Single;
    FLookaheadSize: Integer;
    FLookaheadPos: Integer;
    function CalcTau(timeMs: Single): Single;
    function Limiter(input: Single): Single;
    function ArAvg(avg, at, rt, input: Single): Single;
  public
    constructor Create(sampleRate: Single; threshold: Single; attackMs: Single = 5.0; releaseMs: Single = 100.0);
    destructor Destroy; override;
    function Compress(input: Single): Single;
    property Threshold: Single read FThreshold write FThreshold;
  end;

  TMainForm = class;

  TAudioNotificationClient = class(TInterfacedObject, IMMNotificationClient)
  private
    FOwner: TMainForm;
  public
    constructor Create(AOwner: TMainForm);
    function OnDeviceStateChanged(pwstrDeviceId: LPCWSTR; dwNewState: DWORD): HRESULT; stdcall;
    function OnDeviceAdded(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnDeviceRemoved(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnDefaultDeviceChanged(flow: EDataFlow; role: ERole; pwstrDefaultDeviceId: LPCWSTR): HRESULT; stdcall;
    function OnPropertyValueChanged(pwstrDeviceId: LPCWSTR; const key: PROPERTYKEY): HRESULT; stdcall;
  end;

  { TMainForm }

  TMainForm = class(TForm)
    RecorderComboBox: TComboBox;
    SoundComboBox: TComboBox;
    MainPaintBox: TPaintBox;
    HeaderStaticText: TStaticText;
    LineShape: TShape;
    AudioSampleTimer: TTimer;
    TrayIcon1: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    MenuItemExit: TMenuItem;
    procedure AudioSampleTimerTimer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure RecorderComboBoxChange(Sender: TObject);
    procedure SoundComboBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HeaderStaticTextDblClick(Sender: TObject);
    procedure HeaderStaticTextMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MainPaintBoxMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure MainPaintBoxPaint(Sender: TObject);
  private
    FMinDB: Single;
    FCurrentDeviceIndex: Integer;
    FCurrentCaptureIndex: Integer;
    FLeftVolumeDB: Single;
    FRightVolumeDB: Single;
    FDeviceEnumerator: IMMDeviceEnumerator;
    FRenderDeviceCollection: IMMDeviceCollection;
    FCaptureDeviceCollection: IMMDeviceCollection;
    FCurrentDevice: IMMDevice;
    FAudioMeter: IAudioMeterInformation;
    FNotificationClient: IMMNotificationClient;
    FUpdatingCombos: Boolean;
    // 阈值线相关
    FThresholdDB: Single;       // 阈值dB值 (负数，如 -12)
    // 音频流处理相关
    FLimiterRunning: Boolean;
    FCaptureDevice: IMMDevice;
    FRenderDevice: IMMDevice;
    FCaptureClient: IAudioClient;
    FRenderClient: IAudioClient;
    FCaptureService: IAudioCaptureClient;
    FRenderService: IAudioRenderClient;
    FCompressorL: TAudioCompressor;
    FCompressorR: TAudioCompressor;
    FCaptureFormat: PWAVEFORMATEX;
    FRenderFormat: PWAVEFORMATEX;
    FStreamTimer: TTimer;
    FCaptureChannels: Word;
    FRenderBufferSize: UINT32;
    FMinimizedToTray: Boolean;
    procedure EnumerateDevices;
    procedure InitAudio(DeviceIndex: Integer);
    procedure FreeAudio;
    procedure UpdateVolume;
    procedure HandleDefaultDeviceChanged;
    procedure DefaultDeviceChangedAsync(Data: PtrInt);
    procedure PopulateDeviceCombo(dataFlow: EDataFlow; combo: TComboBox;
      var targetCollection: IMMDeviceCollection; out selectedIndex: Integer);
    // 音频流处理
    procedure StartLimiter;
    procedure StopLimiter;
    procedure StreamTimerTick(Sender: TObject);
    procedure ProcessAudioData;
    procedure MinimizeToTray;
    procedure RestoreFromTray;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ Helper functions }

procedure PropVariantInit(pv: PPropVariant); inline;
begin
  FillChar(pv^, SizeOf(TPropVariant), 0);
end;

{ TAudioCompressor }

constructor TAudioCompressor.Create(sampleRate: Single; threshold: Single; attackMs: Single; releaseMs: Single);
var
  i: Integer;
begin
  inherited Create;
  FSampleRate := sampleRate;
  FThreshold := threshold;
  // 更快的峰值检测，但不要太快以避免爆破声
  FPeakAt := CalcTau(0.1);       // 0.1ms attack
  FPeakRt := CalcTau(50.0);      // 50ms release
  FPeakAverage := 0.0;
  FGainAt := CalcTau(attackMs);  // 增益 attack
  FGainRt := CalcTau(releaseMs); // 增益 release
  FGainAverage := 1.0;
  
  // 初始化前瞻缓冲区 (2ms)
  FLookaheadSize := Round(sampleRate * 0.002);
  if FLookaheadSize < 1 then FLookaheadSize := 1;
  SetLength(FLookaheadBuffer, FLookaheadSize);
  for i := 0 to FLookaheadSize - 1 do
    FLookaheadBuffer[i] := 0.0;
  FLookaheadPos := 0;
end;

destructor TAudioCompressor.Destroy;
begin
  SetLength(FLookaheadBuffer, 0);
  inherited Destroy;
end;

function TAudioCompressor.CalcTau(timeMs: Single): Single;
begin
  // 计算时间常数 tau
  Result := 1.0 - Exp(-2200.0 / (timeMs * FSampleRate));
end;

function TAudioCompressor.Limiter(input: Single): Single;
var
  db, gain: Single;
begin
  // 将输入转换为 dB 并计算增益衰减
  if Abs(input) < 0.0000001 then
    db := -140.0
  else
    db := 20.0 * Log10(Abs(input));
  
  gain := FThreshold - db;
  if gain > 0 then
    gain := 0;
  
  Result := Power(10.0, 0.05 * gain);
end;

function TAudioCompressor.ArAvg(avg, at, rt, input: Single): Single;
var
  tau: Single;
begin
  // Attack/Release 平均滤波
  if input > avg then
    tau := at
  else
    tau := rt;
  
  Result := (1.0 - tau) * avg + tau * input;
end;

function TAudioCompressor.Compress(input: Single): Single;
var
  gain: Single;
  delayedSample: Single;
begin
  // 峰值检测 - 先检测当前输入
  FPeakAverage := ArAvg(FPeakAverage, FPeakAt, FPeakRt, Abs(input));
  
  // 计算限制器增益
  gain := Limiter(FPeakAverage);
  
  // 增益平滑 - 使用更平滑的过渡
  FGainAverage := ArAvg(FGainAverage, FGainAt, FGainRt, gain);
  
  // 从前瞻缓冲区取出延迟的样本
  delayedSample := FLookaheadBuffer[FLookaheadPos];
  
  // 将当前样本存入前瞻缓冲区
  FLookaheadBuffer[FLookaheadPos] := input;
  FLookaheadPos := (FLookaheadPos + 1) mod FLookaheadSize;
  
  // 应用增益到延迟的样本
  Result := FGainAverage * delayedSample;
end;

{ TAudioNotificationClient }

constructor TAudioNotificationClient.Create(AOwner: TMainForm);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TAudioNotificationClient.OnDeviceStateChanged(pwstrDeviceId: LPCWSTR;
  dwNewState: DWORD): HRESULT; stdcall;
begin
  Result := S_OK;
end;

function TAudioNotificationClient.OnDeviceAdded(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
begin
  Result := S_OK;
end;

function TAudioNotificationClient.OnDeviceRemoved(pwstrDeviceId: LPCWSTR): HRESULT; stdcall;
begin
  Result := S_OK;
end;

function TAudioNotificationClient.OnDefaultDeviceChanged(flow: EDataFlow; role: ERole;
  pwstrDefaultDeviceId: LPCWSTR): HRESULT; stdcall;
begin
  // 不处理系统默认设备改变，保持用户选择
  Result := S_OK;
end;

function TAudioNotificationClient.OnPropertyValueChanged(pwstrDeviceId: LPCWSTR;
  const key: PROPERTYKEY): HRESULT; stdcall;
begin
  Result := S_OK;
end;

{ TMainForm }

// private procedure

procedure TMainForm.EnumerateDevices;
var
  hr: HRESULT;
  renderIndex, captureIndex: Integer;
begin
  renderIndex := -1;
  captureIndex := -1;
  FCurrentDeviceIndex := -1;
  FCurrentCaptureIndex := -1;
  
  // 创建设备枚举器
  if FDeviceEnumerator = nil then
  begin
    hr := CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_ALL, 
                          IID_IMMDeviceEnumerator, FDeviceEnumerator);
    if Failed(hr) then
    begin
      ShowMessage('无法创建设备枚举器');
      Exit;
    end;
  end;

  if (FNotificationClient = nil) and (FDeviceEnumerator <> nil) then
  begin
    FNotificationClient := TAudioNotificationClient.Create(Self);
    FDeviceEnumerator.RegisterEndpointNotificationCallback(FNotificationClient);
  end;

  FUpdatingCombos := True;
  try
    PopulateDeviceCombo(eRender, SoundComboBox, FRenderDeviceCollection, renderIndex);
    PopulateDeviceCombo(eCapture, RecorderComboBox, FCaptureDeviceCollection, captureIndex);
  finally
    FUpdatingCombos := False;
  end;

  FCurrentDeviceIndex := renderIndex;
  FCurrentCaptureIndex := captureIndex;
end;

procedure TMainForm.InitAudio(DeviceIndex: Integer);
var
  hr: HRESULT;
  device: IMMDevice;
  audioClient: IAudioClient;
  waveFormat: PWAVEFORMATEX;
  bitsPerSample: Integer;
  // sampleRate: DWORD;
  channelCount: Word;
begin
  FreeAudio;
  
  if FRenderDeviceCollection = nil then Exit;
  
  hr := FRenderDeviceCollection.Item(DeviceIndex, device);
  if Failed(hr) or (device = nil) then
  begin
    ShowMessage('无法获取设备');
    Exit;
  end;
  
  FCurrentDevice := device;
  
  // 获取音频位宽并计算dB下限
  FMinDB := -60.0; // 默认值
  hr := device.Activate(IID_IAudioClient, CLSCTX_ALL, nil, audioClient);
  if Succeeded(hr) and (audioClient <> nil) then
  begin
    hr := audioClient.GetMixFormat(waveFormat);
    if Succeeded(hr) and (waveFormat <> nil) then
    begin
      // sampleRate := waveFormat^.nSamplesPerSec;
      channelCount := waveFormat^.nChannels;
      bitsPerSample := waveFormat^.wBitsPerSample; // wBitsPerSample is already per-sample
      CoTaskMemFree(waveFormat);

      // 根据位宽设置动态范围：6.0 dB * 位数
      if bitsPerSample > 0 then
        FMinDB := -(bitsPerSample  * 6.0)
      else
        FMinDB := -96.0; // 16-bit 默认
    end;
    audioClient := nil;
  end;
  
  // 激活音频计量接口
  hr := device.Activate(IID_IAudioMeterInformation, CLSCTX_ALL, nil, FAudioMeter);
  if Failed(hr) then
  begin
    ShowMessage('无法激活音频计量接口');
    Exit;
  end;
  
  FCurrentDeviceIndex := DeviceIndex;
end;

procedure TMainForm.FreeAudio;
begin
  FAudioMeter := nil;
  FCurrentDevice := nil;
end;

procedure TMainForm.UpdateVolume;
var
  // hr: HRESULT;
  peak: Single;
  channelPeaks: array[0..1] of Single;
  leftPeak, rightPeak: Single;
  function PeakToDB(const value: Single): Single;
  begin
    if value < 0.0001 then
      Exit(FMinDB);
    Result := 20 * Log10(value);
    if Result < FMinDB then
      Result := FMinDB;
  end;
begin
  FillChar(channelPeaks, SizeOf(channelPeaks), 0);
  if FAudioMeter = nil then
  begin
    FLeftVolumeDB := FMinDB;
    FRightVolumeDB := FMinDB;
    Exit;
  end;
  
  // 获取各声道峰值；若失败则退回整体峰值
  if Succeeded(FAudioMeter.GetChannelsPeakValues(2, @channelPeaks[0])) then
  begin
    leftPeak := channelPeaks[0];
    rightPeak := channelPeaks[1];
  end
  else if Succeeded(FAudioMeter.GetPeakValue(peak)) then
  begin
    leftPeak := peak;
    rightPeak := peak;
  end
  else
  begin
    leftPeak := 0.0;
    rightPeak := 0.0;
  end;
  
  // 处理左右声道 - 直接使用原始峰值，无平滑
  FLeftVolumeDB := PeakToDB(leftPeak);
  FRightVolumeDB := PeakToDB(rightPeak);
  // FLeftVolumeDB := -99;
  // FRightVolumeDB := -99;
end;

procedure TMainForm.HandleDefaultDeviceChanged;
begin
  Application.QueueAsyncCall(@DefaultDeviceChangedAsync, 0);
end;

procedure TMainForm.DefaultDeviceChangedAsync(Data: PtrInt);
begin
  EnumerateDevices;
  if FCurrentDeviceIndex >= 0 then
    InitAudio(FCurrentDeviceIndex);
end;

procedure TMainForm.PopulateDeviceCombo(dataFlow: EDataFlow; combo: TComboBox;
  var targetCollection: IMMDeviceCollection; out selectedIndex: Integer);
var
  hr: HRESULT;
  count: UINT;
  i: UINT;
  device: IMMDevice;
  deviceState: DWORD;
  propStore: IPropertyStore;
  pv: PROPVARIANT;
  deviceName: string;
  addedIndex: Integer;
  defaultComboIndex: Integer;
  defaultDevice: IMMDevice;
  defaultDeviceId: LPWSTR;
  defaultDeviceIdStr: string;
  deviceId: LPWSTR;
  deviceIdStr: string;
begin
  selectedIndex := -1;
  combo.Items.Clear;
  combo.ItemIndex := -1;
  defaultComboIndex := -1;
  device := nil;
  propStore := nil;

  if FDeviceEnumerator = nil then Exit;

  targetCollection := nil;
  hr := FDeviceEnumerator.EnumAudioEndpoints(dataFlow, DEVICE_STATE_ACTIVE, targetCollection);
  if Failed(hr) or (targetCollection = nil) then Exit;

  hr := targetCollection.GetCount(count);
  if Failed(hr) or (count = 0) then Exit;

  defaultDeviceIdStr := '';
  defaultDevice := nil;
  if Succeeded(FDeviceEnumerator.GetDefaultAudioEndpoint(dataFlow, eConsole, defaultDevice)) and (defaultDevice <> nil) then
  begin
    if Succeeded(defaultDevice.GetId(defaultDeviceId)) then
    begin
      defaultDeviceIdStr := UTF8Encode(UnicodeString(defaultDeviceId));
      CoTaskMemFree(defaultDeviceId);
    end;
    defaultDevice := nil;
  end;

  for i := 0 to count - 1 do
  begin
    hr := targetCollection.Item(i, device);
    if Succeeded(hr) and (device <> nil) then
    begin
      hr := device.GetState(deviceState);
      if Succeeded(hr) and (deviceState = DEVICE_STATE_ACTIVE) then
      begin
        deviceName := Format('设备 %d', [i]);
        propStore := nil;
        hr := device.OpenPropertyStore(STGM_READ, propStore);
        if Succeeded(hr) and (propStore <> nil) then
        begin
          PropVariantInit(@pv);
          hr := propStore.GetValue(PKEY_Device_FriendlyName, pv);
          if Succeeded(hr) and (pv.vt = VT_LPWSTR) then
            deviceName := UTF8Encode(UnicodeString(pv.pwszVal));
          PropVariantClear(@pv);
          propStore := nil;
        end;

        addedIndex := combo.Items.AddObject(deviceName, TObject(PtrInt(i)));

        if (defaultDeviceIdStr <> '') and Succeeded(device.GetId(deviceId)) then
        begin
          deviceIdStr := UTF8Encode(UnicodeString(deviceId));
          CoTaskMemFree(deviceId);
          if SameText(deviceIdStr, defaultDeviceIdStr) then
            defaultComboIndex := addedIndex;
        end;
      end;
      device := nil;
    end;
  end;

  if combo.Items.Count > 0 then
  begin
    if defaultComboIndex >= 0 then
      combo.ItemIndex := defaultComboIndex
    else
      combo.ItemIndex := 0;

    selectedIndex := PtrInt(combo.Items.Objects[combo.ItemIndex]);
    SendMessage(combo.Handle, CB_SETDROPPEDWIDTH, 320, 0);
  end;
end;
// private procedure

procedure TMainForm.HeaderStaticTextMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  end;
end;

procedure TMainForm.HeaderStaticTextDblClick(Sender: TObject);
begin
  MinimizeToTray;
end;

procedure TMainForm.MinimizeToTray;
begin
  if FMinimizedToTray then Exit;
  FMinimizedToTray := True;
  AudioSampleTimer.Enabled := False; // 停止渲染定时器
  ShowInTaskBar := stNever;
  TrayIcon1.Visible := True;
  Hide;
end;

procedure TMainForm.RestoreFromTray;
begin
  if not FMinimizedToTray then Exit;
  FMinimizedToTray := False;
  TrayIcon1.Visible := False;
  ShowInTaskBar := stAlways;
  Show;
  Application.BringToFront;
  SetForegroundWindow(Handle);
  AudioSampleTimer.Enabled := True;
  MainPaintBox.Invalidate;
end;

procedure TMainForm.MainPaintBoxPaint(Sender: TObject);
var
  paintCanvas: TCanvas;
  paintRect: TRect;
  channelGap, topMargin, bottomMargin: Integer;
  barWidth: Integer;
  leftRect, rightRect: TRect;
  displayText: string;
  thresholdRatio: Single;
  thresholdY: Integer;
  thresholdText: string;
  textW, textH: Integer;

  function RectWidth(const R: TRect): Integer; inline;
  begin
    Result := R.Right - R.Left;
  end;

  function RectHeight(const R: TRect): Integer; inline;
  begin
    Result := R.Bottom - R.Top;
  end;

  function NormalizeLevel(const levelDB: Single): Single;
  begin
    if FMinDB >= 0 then Exit(0);
    if levelDB <= FMinDB then
      Exit(0);
    Result := (levelDB - FMinDB) / (-FMinDB);
    if Result > 1 then
      Result := 1
    else if Result < 0 then
      Result := 0;
  end;

  procedure DrawChannelBar(const rect: TRect; const levelDB: Single);
  const
    SegmentHeight = 4;
    ColorHeight = 3;
  var
    ratio: Single;
    fillHeight: Integer;
    drawnHeight: Integer;
    segmentBottom: Integer;
    segmentTop: Integer;
    colorTop: Integer;
    colorFraction: Single;
    barColor: TColor;
  begin
    paintCanvas.Brush.Color := clBlack;
    paintCanvas.FillRect(rect);

    paintCanvas.Brush.Style := bsClear;
    paintCanvas.Pen.Color := clGray;
    paintCanvas.Rectangle(rect);
    paintCanvas.Brush.Style := bsSolid;

    ratio := NormalizeLevel(levelDB);
    fillHeight := Round(ratio * (rect.Bottom - rect.Top));
    drawnHeight := 0;
    segmentBottom := rect.Bottom;

    while (drawnHeight < fillHeight) and (segmentBottom > rect.Top) do
    begin
      segmentTop := segmentBottom - SegmentHeight;
      if segmentTop < rect.Top then
        segmentTop := rect.Top;

      colorTop := segmentBottom - ColorHeight;
      if colorTop < segmentTop then
        colorTop := segmentTop;

      if segmentBottom - colorTop > 0 then
      begin
        colorFraction := (rect.Bottom - colorTop) / RectHeight(rect);
        if colorFraction > 0.9 then
          barColor := clRed
        else if colorFraction > 0.6 then
          barColor := clYellow
        else
          barColor := clLime;

        paintCanvas.Brush.Color := barColor;
        paintCanvas.FillRect(rect.Left + 1, colorTop, rect.Right - 1, segmentBottom);
      end;

      drawnHeight := drawnHeight + SegmentHeight;
      segmentBottom := segmentBottom - SegmentHeight;
    end;
  end;


begin
  if FMinimizedToTray then Exit; // 不渲染托盘状态

  paintCanvas := MainPaintBox.Canvas;
  paintRect := MainPaintBox.ClientRect;

  paintCanvas.Brush.Color := clBlack;
  paintCanvas.FillRect(paintRect);

  paintCanvas.Font.Color := clWhite;
  paintCanvas.Font.Size := 8;
  displayText := Format('%.0f   %.0f', [FLeftVolumeDB, FRightVolumeDB]);
  paintCanvas.TextOut(paintRect.Left + (RectWidth(paintRect) - paintCanvas.TextWidth(displayText)) div 2, paintRect.Top + 4, displayText);

  topMargin := paintCanvas.TextHeight(displayText) + 8;
  bottomMargin := 2;
  channelGap := 2;
  barWidth := (RectWidth(paintRect) - (channelGap * 3)) div 2;
  if barWidth < 10 then barWidth := 10;

  leftRect.Left := paintRect.Left + channelGap;
  leftRect.Top := paintRect.Top + topMargin;
  leftRect.Right := paintRect.Left + channelGap + barWidth;
  leftRect.Bottom := paintRect.Bottom - bottomMargin;
  
  rightRect.Left := paintRect.Right - channelGap - barWidth;
  rightRect.Top := paintRect.Top + topMargin;
  rightRect.Right := paintRect.Right - channelGap;
  rightRect.Bottom := paintRect.Bottom - bottomMargin;

  DrawChannelBar(leftRect, FLeftVolumeDB);
  DrawChannelBar(rightRect, FRightVolumeDB);

  // 绘制可拖动的阈值横线
  if FMinDB < 0 then
  begin
    // 计算阈值线的Y坐标 (0dB在顶部，FMinDB在底部)
    thresholdRatio := (FThresholdDB - FMinDB) / (0 - FMinDB);
    if thresholdRatio < 0 then thresholdRatio := 0;
    if thresholdRatio > 1 then thresholdRatio := 1;
    thresholdY := leftRect.Bottom - Round(thresholdRatio * RectHeight(leftRect));

    // 绘制横跨两个柱状图的横线
    paintCanvas.Pen.Color := clAqua;
    paintCanvas.Pen.Width := 2;
    paintCanvas.MoveTo(leftRect.Left, thresholdY);
    paintCanvas.LineTo(rightRect.Right, thresholdY);
    paintCanvas.Pen.Width := 1;

    // 在中间显示dB值
    thresholdText := Format('[%.0f]', [FThresholdDB]);
    textW := paintCanvas.TextWidth(thresholdText);
    textH := paintCanvas.TextHeight(thresholdText);
    paintCanvas.Brush.Color := clBlack;
    paintCanvas.Font.Color := clAqua;
    paintCanvas.TextOut((leftRect.Right + rightRect.Left - textW) div 2, thresholdY - textH div 2, thresholdText);
  end;
end;

procedure TMainForm.AudioSampleTimerTimer(Sender: TObject);
begin
  UpdateVolume;
  MainPaintBox.Invalidate; // 触发重绘
end;

procedure TMainForm.TrayIcon1DblClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TMainForm.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.MainPaintBoxMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  delta: Single;
begin
  if FMinDB >= 0 then Exit;

  // 滚轮向上增加(趋向0dB)，向下减少(趋向FMinDB)
  if WheelDelta > 0 then
    delta := 1.0
  else
    delta := -1.0;

  FThresholdDB := FThresholdDB + delta;
  
  // 限制范围
  if FThresholdDB > 0 then FThresholdDB := 0;
  if FThresholdDB < FMinDB then FThresholdDB := FMinDB;

  // 始终保持处理启用，不再根据阈值自动停止
  if not FLimiterRunning then
    StartLimiter;

  MainPaintBox.Invalidate;
  Handled := True;
end;

procedure TMainForm.RecorderComboBoxChange(Sender: TObject);
var
  selectedIndex: Integer;
  wasRunning: Boolean;
begin
  if FUpdatingCombos then Exit;
  if RecorderComboBox.ItemIndex < 0 then Exit;
  if RecorderComboBox.ItemIndex >= RecorderComboBox.Items.Count then Exit;

  selectedIndex := PtrInt(RecorderComboBox.Items.Objects[RecorderComboBox.ItemIndex]);
  if selectedIndex < 0 then Exit;
  if selectedIndex = FCurrentCaptureIndex then Exit;
  
  // 记住限制器是否在运行
  wasRunning := FLimiterRunning;
  
  // 先停止
  if wasRunning then
    StopLimiter;
  
  FCurrentCaptureIndex := selectedIndex;
  
  // 切换后立即尝试启动处理
  StartLimiter;
end;

procedure TMainForm.SoundComboBoxChange(Sender: TObject);
var
  selectedIndex: Integer;
  wasRunning: Boolean;
begin
  if FUpdatingCombos then Exit;
  if SoundComboBox.ItemIndex < 0 then Exit;
  if SoundComboBox.ItemIndex >= SoundComboBox.Items.Count then Exit;

  selectedIndex := PtrInt(SoundComboBox.Items.Objects[SoundComboBox.ItemIndex]);
  if selectedIndex < 0 then Exit;
  if selectedIndex = FCurrentDeviceIndex then Exit;

  // 记住限制器是否在运行
  wasRunning := FLimiterRunning;
  
  // 先停止
  if wasRunning then
    StopLimiter;
  
  // 更新音频计量设备
  InitAudio(selectedIndex);
  
  // 切换后立即尝试启动处理
  StartLimiter;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // 无边框
  BorderStyle := bsNone;
  // 居中
  Position := poScreenCenter;
  // 黑底
  Color := clBlack;
  // 置顶
  FormStyle := fsStayOnTop;
  
  // 初始化COM
  CoInitialize(nil);
  
  FCurrentDeviceIndex := -1;
  FCurrentCaptureIndex := -1;
  FThresholdDB := -20.0;  // 默认阈值 -20 dB
  FLimiterRunning := False;
  FCaptureChannels := 0;
  FRenderBufferSize := 0;
  FMinimizedToTray := False;
  
  // 创建流处理定时器
  FStreamTimer := TTimer.Create(Self);
  FStreamTimer.Enabled := False;
  FStreamTimer.Interval := 5;  // 5ms 处理间隔
  FStreamTimer.OnTimer := @StreamTimerTick;

  // 托盘图标配置
  TrayIcon1.Visible := False;
  TrayIcon1.Hint := 'AudioMeter';
  if Application.Icon.Handle <> 0 then
    TrayIcon1.Icon.Assign(Application.Icon);

  // 托盘右键菜单
  MenuItemExit := TMenuItem.Create(Self);
  MenuItemExit.Caption := '退出';
  MenuItemExit.OnClick := @MenuItemExitClick;

  TrayPopupMenu := TPopupMenu.Create(Self);
  TrayPopupMenu.Items.Add(MenuItemExit);
  TrayIcon1.PopupMenu := TrayPopupMenu;
  
  // 枚举设备并填充下拉列表
  EnumerateDevices;
  
  // 初始化选中的设备
  if FCurrentDeviceIndex >= 0 then
    InitAudio(FCurrentDeviceIndex);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  StopLimiter;
  FreeAudio;
  if (FDeviceEnumerator <> nil) and (FNotificationClient <> nil) then
    FDeviceEnumerator.UnregisterEndpointNotificationCallback(FNotificationClient);
  FNotificationClient := nil;
  FRenderDeviceCollection := nil;
  FCaptureDeviceCollection := nil;
  FDeviceEnumerator := nil;
  FStreamTimer.Free;
  TrayIcon1.Visible := False;
  TrayIcon1.PopupMenu := nil;
  CoUninitialize;
end;

procedure TMainForm.StartLimiter;
var
  hr: HRESULT;
  bufferDuration: Int64;
  sampleRate: Single;
  
  procedure Cleanup;
  begin
    if FCompressorL <> nil then begin FCompressorL.Free; FCompressorL := nil; end;
    if FCompressorR <> nil then begin FCompressorR.Free; FCompressorR := nil; end;
    FCaptureService := nil;
    FRenderService := nil;
    if FCaptureFormat <> nil then begin CoTaskMemFree(FCaptureFormat); FCaptureFormat := nil; end;
    if FRenderFormat <> nil then begin CoTaskMemFree(FRenderFormat); FRenderFormat := nil; end;
    FCaptureClient := nil;
    FRenderClient := nil;
    FCaptureDevice := nil;
    FRenderDevice := nil;
    FCaptureChannels := 0;
    FRenderBufferSize := 0;
  end;
  
begin
  if FLimiterRunning then Exit;
  
  // 检查设备索引
  if (FCurrentCaptureIndex < 0) or (FCurrentDeviceIndex < 0) then Exit;
  
  // 获取捕获设备
  if FCaptureDeviceCollection = nil then Exit;
  hr := FCaptureDeviceCollection.Item(FCurrentCaptureIndex, FCaptureDevice);
  if Failed(hr) or (FCaptureDevice = nil) then Exit;
  
  // 获取渲染设备
  if FRenderDeviceCollection = nil then begin Cleanup; Exit; end;
  hr := FRenderDeviceCollection.Item(FCurrentDeviceIndex, FRenderDevice);
  if Failed(hr) or (FRenderDevice = nil) then begin Cleanup; Exit; end;
  
  // 激活捕获音频客户端
  hr := FCaptureDevice.Activate(IID_IAudioClient, CLSCTX_ALL, nil, FCaptureClient);
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 激活渲染音频客户端
  hr := FRenderDevice.Activate(IID_IAudioClient, CLSCTX_ALL, nil, FRenderClient);
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 获取捕获格式
  hr := FCaptureClient.GetMixFormat(FCaptureFormat);
  if Failed(hr) then begin Cleanup; Exit; end;
  FCaptureChannels := FCaptureFormat^.nChannels;
  
  // 获取渲染格式
  hr := FRenderClient.GetMixFormat(FRenderFormat);
  if Failed(hr) then begin Cleanup; Exit; end;
  FRenderBufferSize := 0;
  
  // 100ms 缓冲区
  bufferDuration := 1000000;  // 100ms in 100-nanosecond units
  
  // 初始化捕获客户端
  hr := FCaptureClient.Initialize(AUDCLNT_SHAREMODE_SHARED, 0, bufferDuration, 0, FCaptureFormat, nil);
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 初始化渲染客户端
  hr := FRenderClient.Initialize(AUDCLNT_SHAREMODE_SHARED, 0, bufferDuration, 0, FRenderFormat, nil);
  if Failed(hr) then begin Cleanup; Exit; end;

  // 缓存渲染缓冲区大小，避免循环中重复获取
  if Failed(FRenderClient.GetBufferSize(FRenderBufferSize)) then
  begin
    Cleanup;
    Exit;
  end;
  
  // 获取捕获服务
  hr := FCaptureClient.GetService(IID_IAudioCaptureClient, FCaptureService);
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 获取渲染服务
  hr := FRenderClient.GetService(IID_IAudioRenderClient, FRenderService);
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 创建压缩器
  sampleRate := FCaptureFormat^.nSamplesPerSec;
  FCompressorL := TAudioCompressor.Create(sampleRate, FThresholdDB);
  FCompressorR := TAudioCompressor.Create(sampleRate, FThresholdDB);
  
  // 启动捕获
  hr := FCaptureClient.Start;
  if Failed(hr) then begin Cleanup; Exit; end;
  
  // 启动渲染
  hr := FRenderClient.Start;
  if Failed(hr) then
  begin
    FCaptureClient.Stop;
    Cleanup;
    Exit;
  end;
  
  FLimiterRunning := True;
  FStreamTimer.Enabled := True;
end;

procedure TMainForm.StopLimiter;
begin
  if not FLimiterRunning then Exit;
  
  FStreamTimer.Enabled := False;
  FLimiterRunning := False;
  
  // 停止流
  if FCaptureClient <> nil then
    FCaptureClient.Stop;
  if FRenderClient <> nil then
    FRenderClient.Stop;
  
  // 释放压缩器
  if FCompressorL <> nil then
  begin
    FCompressorL.Free;
    FCompressorL := nil;
  end;
  if FCompressorR <> nil then
  begin
    FCompressorR.Free;
    FCompressorR := nil;
  end;
  
  // 释放服务
  FCaptureService := nil;
  FRenderService := nil;
  
  // 释放格式
  if FCaptureFormat <> nil then
  begin
    CoTaskMemFree(FCaptureFormat);
    FCaptureFormat := nil;
  end;
  if FRenderFormat <> nil then
  begin
    CoTaskMemFree(FRenderFormat);
    FRenderFormat := nil;
  end;
  
  // 释放客户端
  FCaptureClient := nil;
  FRenderClient := nil;
  
  // 释放设备
  FCaptureDevice := nil;
  FRenderDevice := nil;

  // 重置缓存字段
  FCaptureChannels := 0;
  FRenderBufferSize := 0;
end;

procedure TMainForm.StreamTimerTick(Sender: TObject);
begin
  if FLimiterRunning then
  begin
    // 更新压缩器阈值
    if FCompressorL <> nil then
      FCompressorL.Threshold := FThresholdDB;
    if FCompressorR <> nil then
      FCompressorR.Threshold := FThresholdDB;
    
    ProcessAudioData;
  end;
end;

procedure TMainForm.ProcessAudioData;
var
  hr: HRESULT;
  captureData: PByte;
  renderData: PByte;
  numFramesToRead: UINT32;
  flags: DWORD;
  devicePos, qpcPos: UINT64;
  packetSize: UINT32;
  padding: UINT32;
  renderBufferSize: UINT32;
  channels: Word;
  numFramesAvailable: UINT32;
  captureFloats: PSingle;
  renderFloats: PSingle;
  i: Integer;
  leftSample, rightSample: Single;
begin
  if (FCaptureService = nil) or (FRenderService = nil) then Exit;
  if (FCaptureClient = nil) or (FRenderClient = nil) then Exit;

  // 使用缓存的声道数和缓冲区大小，避免重复查询
  channels := FCaptureChannels;
  if channels = 0 then Exit;
  renderBufferSize := FRenderBufferSize;
  if renderBufferSize = 0 then Exit;
  
  // 处理所有可用的捕获数据包
  hr := FCaptureService.GetNextPacketSize(packetSize);
  while Succeeded(hr) and (packetSize > 0) do
  begin
    // 获取捕获缓冲区
    hr := FCaptureService.GetBuffer(captureData, numFramesToRead, flags, devicePos, qpcPos);
    if Failed(hr) then Break;
    
    if numFramesToRead > 0 then
    begin
      // 获取渲染缓冲区的可用空间
      hr := FRenderClient.GetCurrentPadding(padding);
      if Succeeded(hr) then
      begin
        numFramesAvailable := renderBufferSize - padding;
        if numFramesAvailable > numFramesToRead then
          numFramesAvailable := numFramesToRead;
        
        if numFramesAvailable > 0 then
        begin
          // 获取渲染缓冲区
          hr := FRenderService.GetBuffer(numFramesAvailable, renderData);
          if Succeeded(hr) then
          begin
            captureFloats := PSingle(captureData);
            renderFloats := PSingle(renderData);
            
            // 处理每个帧
            for i := 0 to numFramesAvailable - 1 do
            begin
              if channels >= 2 then
              begin
                // 立体声
                leftSample := captureFloats[i * channels];
                rightSample := captureFloats[i * channels + 1];
                
                // 应用压缩
                if FCompressorL <> nil then
                  leftSample := FCompressorL.Compress(leftSample);
                if FCompressorR <> nil then
                  rightSample := FCompressorR.Compress(rightSample);
                
                renderFloats[i * channels] := leftSample;
                renderFloats[i * channels + 1] := rightSample;
              end
              else
              begin
                // 单声道
                leftSample := captureFloats[i];
                if FCompressorL <> nil then
                  leftSample := FCompressorL.Compress(leftSample);
                renderFloats[i] := leftSample;
              end;
            end;
            
            FRenderService.ReleaseBuffer(numFramesAvailable, 0);
          end;
        end;
      end;
    end;
    
    // 释放捕获缓冲区
    FCaptureService.ReleaseBuffer(numFramesToRead);
    
    // 获取下一个数据包大小
    hr := FCaptureService.GetNextPacketSize(packetSize);
  end;
end;

end.