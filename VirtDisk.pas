unit VirtDisk;

interface

uses
  JwaWinType, JwaWinBase;
{$MINENUMSIZE 4}

type
  _VIRTUAL_STORAGE_TYPE = record
    DeviceID: ULONG;
    VendorId: GUID;
  end;
  VIRTUAL_STORAGE_TYPE = _VIRTUAL_STORAGE_TYPE;
  PVIRTUAL_STORAGE_TYPE = ^VIRTUAL_STORAGE_TYPE;
  TVirtualStorageType = VIRTUAL_STORAGE_TYPE;

  _VIRTUAL_DISK_ACCESS_MASK = Integer;
  VIRTUAL_DISK_ACCESS_MASK = _VIRTUAL_DISK_ACCESS_MASK;

const
  VIRTUAL_DISK_ACCESS_NONE        = $00000000;
  VIRTUAL_DISK_ACCESS_ATTACH_RO   = $00010000;
  VIRTUAL_DISK_ACCESS_ATTACH_RW   = $00020000;
  VIRTUAL_DISK_ACCESS_DETACH      = $00040000;
  VIRTUAL_DISK_ACCESS_GET_INFO    = $00080000;
  VIRTUAL_DISK_ACCESS_CREATE      = $00100000;
  VIRTUAL_DISK_ACCESS_METAOPS     = $00200000;
  VIRTUAL_DISK_ACCESS_READ        = $000d0000;
  VIRTUAL_DISK_ACCESS_ALL         = $003f0000;
  VIRTUAL_DISK_ACCESS_WRITABLE    = $00320000;

type
  _OPEN_VIRTUAL_DISK_FLAG = Integer;
  OPEN_VIRTUAL_DISK_FLAG = _OPEN_VIRTUAL_DISK_FLAG;

const
  OPEN_VIRTUAL_DISK_FLAG_NONE                = $00000000;
  OPEN_VIRTUAL_DISK_FLAG_NO_PARENTS          = $00000001;
  OPEN_VIRTUAL_DISK_FLAG_BLANK_FILE          = $00000002;
  OPEN_VIRTUAL_DISK_FLAG_BOOT_DRIVE          = $00000004;
  OPEN_VIRTUAL_DISK_FLAG_CACHED_IO           = $00000008;
  OPEN_VIRTUAL_DISK_FLAG_CUSTOM_DIFF_CHAIN   = $00000010;

type
  _OPEN_VIRTUAL_DISK_PARAMETERS = record
  case Byte of
    0: (
      Version1: record
        RWDepth: ULONG
      end;
    );
    1: (
      Version2: record
        GetInfoOnly: BOOL;
        ReadOnly: BOOL;
        ResiliencyGuid: GUID
      end;
    );
  end;
  OPEN_VIRTUAL_DISK_PARAMETERS = _OPEN_VIRTUAL_DISK_PARAMETERS;
  POPEN_VIRTUAL_DISK_PARAMETERS = ^OPEN_VIRTUAL_DISK_PARAMETERS;

  _COMPACT_VIRTUAL_DISK_FLAG = (
    COMPACT_VIRTUAL_DISK_FLAG_NONE = $00000000
  );
  COMPACT_VIRTUAL_DISK_FLAG = _COMPACT_VIRTUAL_DISK_FLAG;
  PCOMPACT_VIRTUAL_DISK_FLAG = ^COMPACT_VIRTUAL_DISK_FLAG;

  _COMPACT_VIRTUAL_DISK_PARAMETERS = record
  case Byte of
    0: (
      Version1: record
        Reserved: ULONG
      end;
    );
  end;
  COMPACT_VIRTUAL_DISK_PARAMETERS = _COMPACT_VIRTUAL_DISK_PARAMETERS;
  PCOMPACT_VIRTUAL_DISK_PARAMETERS = ^COMPACT_VIRTUAL_DISK_PARAMETERS;

  _GET_VIRTUAL_DISK_INFO_VERSION = (
    GET_VIRTUAL_DISK_INFO_UNSPECIFIED       = 0,
    GET_VIRTUAL_DISK_INFO_SIZE              = 1,
    GET_VIRTUAL_DISK_INFO_IDENTIFIER        = 2,
    GET_VIRTUAL_DISK_INFO_PARENT_LOCATION   = 3,
    GET_VIRTUAL_DISK_INFO_PARENT_IDENTIFIER = 4,
    GET_VIRTUAL_DISK_INFO_PARENT_TIMESTAMP  = 5,
    GET_VIRTUAL_DISK_INFO_VIRTUAL_STORAGE_TYPE  = 6,
    GET_VIRTUAL_DISK_INFO_PROVIDER_SUBTYPE  = 7
  );
  GET_VIRTUAL_DISK_INFO_VERSION = _GET_VIRTUAL_DISK_INFO_VERSION;

  GET_VIRTUAL_DISK_INFO = record
    Version: GET_VIRTUAL_DISK_INFO_VERSION;
    case Byte of
      0: (Size: record
            VirtualSize: ULONGLONG;
            PhysicalSize: ULONGLONG;
            BlockSize: ULONG;
            SectorSize: ULONG;
          end);
      1: (Identifier: GUID);
      2: (ParentLocation: record
            ParentResolved: BOOL;
            ParentLocationBuffer:array[0..ANYSIZE_ARRAY-1] of WCHAR;
          end);
      3: (ParentIdentifier: GUID);
      4: (ParentTimeStamp: ULONG);
      5: (VirtualStorageType: VIRTUAL_STORAGE_TYPE);
      6: (ProviderSubType: ULONG);
  end;
  PGET_VIRTUAL_DISK_INFO = ^GET_VIRTUAL_DISK_INFO;

  _VIRTUAL_DISK_PROGRESS = record
    OperationStatus: DWORD;
    CurrentValue: ULONGLONG;
    CompletionValue: ULONGLONG;
  end;
  VIRTUAL_DISK_PROGRESS = _VIRTUAL_DISK_PROGRESS;
  PVIRTUAL_DISK_PROGRESS = ^VIRTUAL_DISK_PROGRESS;

const
  VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT: GUID = (D1:$ec984aec; D2:$a0f9; D3:$47e9; D4:($90, $1f, $71, $41, $5a, $66, $34, $5b));

  VIRTUAL_STORAGE_TYPE_DEVICE_UNKNOWN    = 0;
  VIRTUAL_STORAGE_TYPE_DEVICE_ISO        = 1;
  VIRTUAL_STORAGE_TYPE_DEVICE_VHD        = 2;

function CompactVirtualDisk(VirtualDiskHandle: Handle;
  Flags: COMPACT_VIRTUAL_DISK_FLAG; Parameters: PCOMPACT_VIRTUAL_DISK_PARAMETERS;
  Overlapped: LPOVERLAPPED): DWORD; stdcall external 'VirtDisk.dll';

function GetVirtualDiskInformation(VirtualDiskHandle: THandle;
  var VirtualDiskInfoSize: ULONG; var VirtualDiskInfo: GET_VIRTUAL_DISK_INFO;
  SizeUsed: PULONG): DWORD; stdcall external 'VirtDisk.dll';

function GetVirtualDiskOperationProgress(VirtualDiskHandle: THandle;
  Overlapped: LPOVERLAPPED; var Progress: VIRTUAL_DISK_PROGRESS): DWORD; stdcall;
  external 'VirtDisk.dll';

function OpenVirtualDisk(const VirtualStorageType: VIRTUAL_STORAGE_TYPE;
  Path: PChar; VirtualDiskAccessMask: VIRTUAL_DISK_ACCESS_MASK;
  Flags: OPEN_VIRTUAL_DISK_FLAG; Parameters: POPEN_VIRTUAL_DISK_PARAMETERS;
  var Handle: THandle): DWORD; stdcall; external 'VirtDisk.dll';

implementation

end.
