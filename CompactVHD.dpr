program CompactVHD;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  JwaWinType, JwaWinbase, JwaWinCon, JwaWinError, JwaWinNt,
  VirtDisk;

const
  Cursor: array[0..7] of Char = ('\','|','/','-','\','|','/','-');
// [......................................................................]
//
var
  Path: String;
  hConsole: THandle;
  MaxX: Integer;
  MaxY: Integer;
  CCI: TConsoleCursorInfo;
  Coord: TCoord;
  Progress: VIRTUAL_DISK_PROGRESS;

procedure Init;
begin
  // Get console output handle
  hConsole := GetStdHandle(STD_OUTPUT_HANDLE);
  // Get max window size
  Coord := GetLargestConsoleWindowSize(hConsole);
  MaxX := Coord.X;
  MaxY := Coord.Y;
end;

function GetXY: TCoord;
var
  csbi: CONSOLE_SCREEN_BUFFER_INFO;
begin
  GetConsoleScreenBufferInfo(hConsole, csbi);
  Result := csbi.dwCursorPosition;
end;

procedure GotoXY(X, Y : Word);
begin
  Coord.X := X; Coord.Y := Y;
  SetConsoleCursorPosition(hConsole, Coord);
end;

procedure ShowCursor(const Show : Boolean);
begin
 CCI.bVisible := Show;
 SetConsoleCursorInfo(hConsole, CCI);
end;

procedure TestCursor;
var
  i: Integer;
begin
  Init;
  ShowCursor(False);
  i := 0;
  Coord := GetXY;

  while True do
  begin
    SetConsoleCursorPosition(hConsole, Coord);
    Write(Cursor[i]);

    Inc(i);
    if i > High(Cursor) then
      i := Low(Cursor);
    Sleep(200);
  end;
end;

 //Format file byte size
 function FormatByteSize(const bytes: Longint): string;
 const
   B = 1; //byte
   KB = 1024 * B; //kilobyte
   MB = 1024 * KB; //megabyte
   GB = 1024 * MB; //gigabyte
 begin
   if bytes > GB then
     result := FormatFloat('#.## GB', bytes / GB)
   else
     if bytes > MB then
       result := FormatFloat('#.## MB', bytes / MB)
     else
       if bytes > KB then
         result := FormatFloat('#.## KB', bytes / KB)
       else
         result := FormatFloat('#.## bytes', bytes) ;
 end;

function fsize(const Filename: String): Int64;
var
  hFile: THandle;
  FileSize: LARGE_INTEGER;
  dwRes: DWORD;
begin
  hFile := CreateFile(PChar(Path), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
  if hFile = 0 then
  begin
    dwRes := GetLastError;
    WriteLn(Format('Error 0x%.8x (%s) while opening VHD %s', [dwRes,
      SysErrorMessage(dwRes), Path]));
    Exit(0);
  end;

  try
    if GetFileSizeEx(hFile, FileSize) then
    begin
      Result := FileSize.QuadPart;
    end
    else begin
      dwRes := GetLastError;
      WriteLn(Format('Error 0x%.8x (%s) while opening VHD %s', [dwRes,
        SysErrorMessage(dwRes), Path]));
      Exit(0);
    end;
  finally
    CloseHandle(hFile);
  end;
end;

procedure OutputVhdInfo(const Path: String; const SizeOnly: Boolean=False);
var
  hVirtDisk: THandle;
  dwSize: DWORD;
  dwRes: DWORD;
  vdi: GET_VIRTUAL_DISK_INFO;
  vst: VIRTUAL_STORAGE_TYPE;
begin
  vst.DeviceID := VIRTUAL_STORAGE_TYPE_DEVICE_VHD;
  vst.VendorId := VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT;

  dwRes := OpenVirtualDisk(vst, PChar(Path), VIRTUAL_DISK_ACCESS_GET_INFO,
    OPEN_VIRTUAL_DISK_FLAG_NONE, nil, hVirtDisk);
  if dwRes <> ERROR_SUCCESS then
    Exit;
  try
    dwSize := Sizeof(vdi);

    if not SizeOnly then
    begin
      vdi.Version := GET_VIRTUAL_DISK_INFO_PROVIDER_SUBTYPE;
      dwRes := GetVirtualDiskInformation(hVirtDisk, dwSize, vdi, nil);
      if dwRes = ERROR_SUCCESS then
      begin
        Write('VHD Type: ');
        case vdi.ProviderSubType of
          2: WriteLn('Fixed');
          3: WriteLn('Dynamically Expandible (sparse)');
          4: WriteLn('Differencing');
        end;
      end;
    end;

    vdi.Version := GET_VIRTUAL_DISK_INFO_SIZE;
    dwRes := GetVirtualDiskInformation(hVirtDisk, dwSize, vdi, nil);
    if dwRes = ERROR_SUCCESS then
    begin
      if not SizeOnly then
      begin
        WriteLn(Format('BlockSize: %d, SectorSize: %d', [vdi.Size.BlockSize, vdi.Size.SectorSize]));
      end;
      WriteLn(Format('PhysicalSize: %d VirtualSize: %d', [vdi.Size.PhysicalSize, vdi.Size.VirtualSize]));
    end;
  finally
    CloseHandle(hVirtDisk);
  end;
end;

function CompactVhdFile(const FileSystemAware: Boolean): Boolean;
var
  hVirtDisk: THandle;
  Flags: DWORD;
  dwRes: DWORD;
  Overlapped: TOverlapped;
  vst: VIRTUAL_STORAGE_TYPE;
  bPending: Boolean;
  i: Integer;
begin
  Result := False;

  Flags := VIRTUAL_DISK_ACCESS_METAOPS;
  Write('Compaction method: ');
  if FileSystemAware then
  begin
    Flags := Flags or  VIRTUAL_DISK_ACCESS_ATTACH_RO;
    WriteLn('file-system-aware');
  end
  else begin
    WriteLn('file-system-agnostic');
  end;

  vst.DeviceID := VIRTUAL_STORAGE_TYPE_DEVICE_VHD;
  vst.VendorId := VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT;

  dwRes := OpenVirtualDisk(vst, PChar(Path), Flags, OPEN_VIRTUAL_DISK_FLAG_NONE,
    nil, hVirtDisk);
  if dwRes <> ERROR_SUCCESS then
    Exit;

  try
    Write('Compacting: ');
    Coord := GetXY;
    ZeroMemory(@Overlapped, SizeOf(Overlapped));
    Overlapped.hEvent := CreateEvent(nil, True, False, nil);

    dwRes :=  CompactVirtualDisk(hVirtDisk, COMPACT_VIRTUAL_DISK_FLAG_NONE, nil,
      @Overlapped);
    if (dwRes <> ERROR_SUCCESS) and (dwRes <> ERROR_IO_PENDING) then
    begin
      WriteLn(sLineBreak + Format('Error 0x%.8x (%s) while compacting VHD %s', [dwRes,
        SysErrorMessage(dwRes), Path]));
      Exit;
    end;

    bPending := True;
    i := 0;

    while bPending do
    begin
      dwRes := GetVirtualDiskOperationProgress(hVirtDisk, @Overlapped, Progress);
      if (dwRes = ERROR_SUCCESS) and (Progress.OperationStatus = ERROR_IO_PENDING) then
      begin
        SetConsoleCursorPosition(hConsole, Coord);
        Write(Cursor[i]);

        Inc(i);
        if i > High(Cursor) then
          i := Low(Cursor);

        bPending := WaitForSingleObject(Overlapped.hEvent, 100) = WAIT_TIMEOUT;
      end;
    end;

    SetConsoleCursorPosition(hConsole, Coord);
    WriteLn('Finished.');
    Result := True; //Progress.OperationStatus = ERROR_SUCCESS;

  finally
    CloseHandle(hVirtDisk);
    CloseHandle(Overlapped.hEvent);
  end;



end;

begin
  Init;

  WriteLn('CompactVHD 1.0 (c) 2012 Remko Weijnen');
  WriteLn('');

  Path := ParamStr(1);
  if not FileExists(Path) then
  begin
    WriteLn(Format('VHD %s not found', [Path]));
    Exit;
  end;

  WriteLn(Format('Target VHD: %s', [Path]));
//  WriteLn(Format('Current Size for VHD: %s', [FormatByteSize(fsize(Path))]));
  WriteLn('');
  OutputVhdInfo(Path);
  WriteLn('');

  CompactVHDFile(True);
  OutputVhdInfo(Path, True);
  WriteLn('');
  CompactVHDFile(False);
  OutputVhdInfo(Path, True);
  WriteLn('');
end.



