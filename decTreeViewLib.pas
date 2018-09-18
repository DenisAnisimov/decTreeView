unit decTreeViewLib;

{ $DEFINE NATIVE_BORDERS}

{$if CompilerVersion > 15}
  {$DEFINE SUPPORTS_INLINE}
{$ifend}

{$if CompilerVersion >= 23}
  {$DEFINE SUPPORTS_UNICODE_STRING}
{$ifend}

{$if CompilerVersion >= 24}
  {$DEFINE SUPPORTS_ATOMICINCREMENT}
{$ifend}

(*

Not supported yet:

Messages:
  CCM_DPISCALE
  CCM_GETUNICODEFORMAT
  CCM_GETVERSION
  CCM_SETUNICODEFORMAT
  CCM_SETVERSION
  CCM_SETWINDOWTHEME

  TVM_CREATEDRAGIMAGE
  TVM_EDITLABEL
  TVM_ENDEDITLABELNOW
  TVM_GETEDITCONTROL
  TVM_GETISEARCHSTRING
  TVM_GETITEMHEIGHT
  TVM_GETITEMPARTRECT
  TVM_GETSCROLLTIME
  TVM_GETTOOLTIPS
  TVM_GETUNICODEFORMAT
  TVM_GETVISIBLECOUNT
  TVM_MAPACCIDTOHTREEITEM
  TVM_MAPHTREEITEMTOACCID
  TVM_SETAUTOSCROLLINFO
  TVM_SETHOT
  TVM_SETITEMHEIGHT
  TVM_SETSCROLLTIME
  TVM_SETTOOLTIPS
  TVM_SETUNICODEFORMAT
  TVM_SHOWINFOTIP
  TVM_SORTCHILDREN
  TVM_SORTCHILDRENCB

Notification:

  NM_CLICK
  NM_DBLCLK
  NM_RCLICK
  NM_RDBLCLK
  TVN_ASYNCDRAW
  TVN_BEGINDRAG
  TVN_BEGINLABELEDIT
  TVN_BEGINRDRAG
  TVN_ENDLABELEDIT
  TVN_GETINFOTIP
  TVN_ITEMCHANGED
  TVN_ITEMCHANGING
  TVN_KEYDOWN
  TVN_SINGLEEXPAND

Styles:
  TVS_CHECKBOXES
  TVS_DISABLEDRAGDROP
  TVS_EDITLABELS
  TVS_FULLROWSELECT
  TVS_HASLINES
  TVS_INFOTIP
  TVS_NOHSCROLL
  TVS_NONEVENHEIGHT
  TVS_NOSCROLL
  TVS_NOTOOLTIPS
  TVS_RTLREADING
  TVS_SINGLEEXPAND
  TVS_TRACKSELECT

ExtStyles:
  TVS_EX_AUTOHSCROLL
  TVS_EX_DIMMEDCHECKBOXES
  TVS_EX_DOUBLEBUFFER
  TVS_EX_DRAWIMAGEASYNC
  TVS_EX_EXCLUSIONCHECKBOXES
  TVS_EX_FADEINOUTEXPANDOS
  TVS_EX_MULTISELECT
  TVS_EX_NOINDENTSTATE
  TVS_EX_NOSINGLECOLLAPSE
  TVS_EX_PARTIALCHECKBOXES
  TVS_EX_RICHTOOLTIP

*)

interface

uses
  Windows, CommCtrl;

{$IFNDEF SUPPORTS_UNICODE_STRING}
type
  UnicodeString = WideString;
{$endif}

const
  TreeViewClassName: PChar = 'decTreeView';

procedure InitTreeViewLib;

const
  TVS_EX_AUTOCENTER = $80000000;

const
  TVM_SETBORDER = TV_FIRST + 35;
  TVSBF_XBORDER = $00000001;
  TVSBF_YBORDER = $00000002;

  TVM_GETBORDER = TV_FIRST + 100; // Non standard

  TVM_SETSPACE = TV_FIRST + 101; // Non standard
  TVM_GETSPACE = TV_FIRST + 102; // Non standard

function TreeView_SetBorder(AWnd: HWND; AFlags, AXBorder, AYBorder: UINT): Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetXBorder(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetYBorder(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

function TreeView_SetSpace(AWnd: HWND; AFlags, AXSpace, AYSpace: UINT): Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetXSpace(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetYSpace(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

implementation

uses
  Messages {$IFDEF DEBUG}, SysUtils{$ENDIF} {$IFDEF USE_LOGS}, decTreeViewLibLogs{$ENDIF};

function TreeView_SetBorder(AWnd: HWND; AFlags, AXBorder, AYBorder: UINT): Integer;
begin
  Result := SendMessage(AWnd, TVM_SETBORDER, AFlags, MakeLParam(AXBorder, AYBorder));
end;

function TreeView_GetXBorder(AWnd: HWND): UINT;
begin
  Result := SendMessage(AWnd, TVM_GETBORDER, TVSBF_XBORDER, 0);
end;

function TreeView_GetYBorder(AWnd: HWND): UINT;
begin
  Result := SendMessage(AWnd, TVM_GETBORDER, TVSBF_YBORDER, 0);
end;

function TreeView_SetSpace(AWnd: HWND; AFlags, AXSpace, AYSpace: UINT): Integer;
begin
  Result := SendMessage(AWnd, TVM_SETSPACE, AFlags, MakeLParam(AXSpace, AYSpace));
end;

function TreeView_GetXSpace(AWnd: HWND): UINT;
begin
  Result := SendMessage(AWnd, TVM_GETSPACE, TVSBF_XBORDER, 0);
end;

function TreeView_GetYSpace(AWnd: HWND): UINT;
begin
  Result := SendMessage(AWnd, TVM_GETSPACE, TVSBF_YBORDER, 0);
end;

const
  WM_DPICHANGED              = $02E0;
  WM_DPICHANGED_BEFOREPARENT = $02E2;
  WM_DPICHANGED_AFTERPARENT  = $02E3;
  WM_GETDPISCALEDSIZE        = $02E4;


  TVM_SETHOT = TV_FIRST + 58;
{#define TreeView_SetHot(hwnd, hitem) \
    SNDMSG((hwnd), TVM_SETHOT, 0, (LPARAM)(hitem))}

  TVSI_NOSINGLEEXPAND = $8000;

function Min(A, B: Integer): Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  if A < B then Result := A
           else Result := B;
end;

function Max(A, B: Integer): Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  if A > B then Result := A
           else Result := B;
end;

const
  VSCLASS_TREEVIEWSTYLE   = 'TREEVIEWSTYLE';
  VSCLASS_TREEVIEW        = 'TREEVIEW';

  TVP_TREEITEM           = 1;
  TVP_GLYPH              = 2;
  TVP_BRANCH             = 3;
  TVP_HOTGLYPH           = 4;

  TREIS_NORMAL           = 1;
  TREIS_HOT              = 2;
  TREIS_SELECTED         = 3;
  TREIS_DISABLED         = 4;
  TREIS_SELECTEDNOTFOCUS = 5;
  TREIS_HOTSELECTED      = 6;

  GLPS_CLOSED            = 1;
  GLPS_OPENED            = 2;

  HGLPS_CLOSED           = 1;
  HGLPS_OPENED           = 2;


var
  LibsCS: TRTLCriticalSection;
  LibsInited: Boolean;
  UXThemeLib: HMODULE;
  User32Lib: HMODULE;

type
  HTHEME = THandle;

  THEMESIZE = UINT;
const
  TS_MIN = 0;
  TS_TRUE = 1;
  TS_DRAW = 2;

  {THEMESIZE = (
    TS_MIN,             // minimum size
    TS_TRUE,            // size without stretching
    TS_DRAW             // size that theme mgr will use to draw part
  );
  TThemeSize = THEMESIZE;}

const
  OTD_FORCE_RECT_SIZING = $00000001;          // make all parts size to rect
  OTD_NONCLIENT         = $00000002;          // set if hTheme to be used for nonclient area
  OTD_VALIDBITS         = OTD_FORCE_RECT_SIZING or OTD_NONCLIENT;

type
  TCloseThemeData = function(ATheme: HTHEME): HRESULT; stdcall;
  TDrawThemeBackground = function(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; const ABoundingRect: TRect; AClipRect: PRect): HRESULT; stdcall;
  TGetThemeBackgroundContentRect = function(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; const ABoundingRect: TRect; AContentRect: PRECT): HRESULT; stdcall;
  TGetThemeColor = function(ATheme: HTHEME; APartId, AStateId, APropId: Integer; var AColor: COLORREF): HRESULT; stdcall;
  TGetThemePartSize = function(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; ARect: PRECT; ASize: THEMESIZE; var psz: TSize): HRESULT; stdcall;
  TIsAppThemed = function: BOOL; stdcall;
  TIsThemeActive = function: BOOL; stdcall;
  TIsThemePartDefined = function(ATheme: HTHEME; APartId, AStateId: Integer): BOOL; stdcall;
  TOpenThemeData = function(AWnd: HWND; AClassList: LPCWSTR): HTHEME; stdcall;
  TOpenThemeDataEx = function(AWnd: HWND; AClassList: PWideChar; AFlags: DWORD): HTHEME; stdcall;
  TOpenThemeDataForDpi = function(AWnd: HWND; AClassList: PWideChar; ADPI: UINT): HTHEME; stdcall;

  TGetDpiForWindow = function(AWnd: HWND): UINT; stdcall;
  TGetDpiForSystem = function: UINT; stdcall;
  TSystemParametersInfoForDpi = function(AAction: UINT; AParam: UINT; AOut: Pointer; AWinIni, ADpi: UINT): BOOL; stdcall;
  TGetSystemMetricsForDpi = function(AIndex: Integer; ADpi: UINT): Integer; stdcall;

var
  _CloseThemeData: TCloseThemeData;
  _DrawThemeBackground: TDrawThemeBackground;
  _GetThemeBackgroundContentRect: TGetThemeBackgroundContentRect;
  _GetThemeColor: TGetThemeColor;
  _GetThemePartSize: TGetThemePartSize;
  _IsAppThemed: TIsAppThemed;
  _IsThemeActive: TIsThemeActive;
  _IsThemePartDefined: TIsThemePartDefined;
  _OpenThemeData: TOpenThemeData;
  _OpenThemeDataForDpi: TOpenThemeDataForDpi;
  _OpenThemeDataEx: TOpenThemeDataEx;

  _GetDpiForWindow: TGetDpiForWindow;
  _GetDpiForSystem: TGetDpiForSystem;
  _SystemParametersInfoForDpi: TSystemParametersInfoForDpi;
  _GetSystemMetricsForDpi: TGetSystemMetricsForDpi;

procedure InitLibs;
begin
  EnterCriticalSection(LibsCS);
  if not LibsInited then
    begin
      LibsInited := True;

      UXThemeLib := LoadLibrary('uxtheme.dll');
      if UXThemeLib <> 0 then
        begin
          _CloseThemeData := GetProcAddress(UXThemeLib, 'CloseThemeData');
          _DrawThemeBackground := GetProcAddress(UXThemeLib, 'DrawThemeBackground');
          _GetThemeBackgroundContentRect := GetProcAddress(UXThemeLib, 'GetThemeBackgroundContentRect');
          _GetThemeColor := GetProcAddress(UXThemeLib, 'GetThemeColor');
          _GetThemePartSize := GetProcAddress(UXThemeLib, 'GetThemePartSize');
          _IsAppThemed := GetProcAddress(UXThemeLib, 'IsAppThemed');
          _IsThemeActive := GetProcAddress(UXThemeLib, 'IsThemeActive');
          _IsThemePartDefined := GetProcAddress(UXThemeLib, 'IsThemePartDefined');
          _OpenThemeData := GetProcAddress(UXThemeLib, 'OpenThemeData');
          _OpenThemeDataForDpi := GetProcAddress(UXThemeLib, 'OpenThemeDataForDpi');
          _OpenThemeDataEx := GetProcAddress(UXThemeLib, 'OpenThemeDataEx');
        end;

      User32Lib := LoadLibrary('User32.dll');
      if User32Lib <> 0 then
        begin
          @_GetDpiForWindow := GetProcAddress(User32Lib, 'GetDpiForWindow');
          @_GetDpiForSystem := GetProcAddress(User32Lib, 'GetDpiForSystem');
          @_SystemParametersInfoForDpi := GetProcAddress(User32Lib, 'SystemParametersInfoForDpi');
          @_GetSystemMetricsForDpi := GetProcAddress(User32Lib, 'GetSystemMetricsForDpi');
        end;
    end;
  LeaveCriticalSection(LibsCS);
end;

procedure DoneLibs;
begin
  if UXThemeLib <> 0 then
    FreeLibrary(UXThemeLib);
  if User32Lib <> 0 then
    FreeLibrary(User32Lib);
end;

function CloseThemeData(ATheme: HTHEME): HRESULT;
begin
  if Assigned(_CloseThemeData) then
    Result := _CloseThemeData(ATheme)
  else
    Result := E_NOTIMPL;
end;

function DrawThemeBackground(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; const ARect: TRect; AClipRect: PRect): HRESULT;
begin
  if Assigned(_DrawThemeBackground) then
    Result := _DrawThemeBackground(ATheme, ADC, APartId, AStateId, ARect, AClipRect)
  else
    Result := E_NOTIMPL;
end;

function GetThemeBackgroundContentRect(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; const ABoundingRect: TRect; AContentRect: PRECT): HRESULT;
begin
  if Assigned(_GetThemeBackgroundContentRect) then
    Result := _GetThemeBackgroundContentRect(ATheme, ADC, APartId, AStateId, ABoundingRect, AContentRect)
  else
    Result := E_NOTIMPL;
end;

function GetThemeColor(ATheme: HTHEME; APartId, AStateId, APropId: Integer; var AColor: COLORREF): HRESULT;
begin
  if Assigned(_GetThemeColor) then
    Result := _GetThemeColor(ATheme, APartId, AStateId, APropId, AColor)
  else
    Result := E_NOTIMPL;
end;

function GetThemePartSize(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; ARect: PRECT; ASize: THEMESIZE; var psz: TSize): HRESULT;
begin
  if Assigned(_GetThemePartSize) then
    Result := _GetThemePartSize(ATheme, ADC, APartId, AStateId, ARect, ASize, psz)
  else
    Result := E_NOTIMPL;
end;

function IsAppThemed: Boolean;
begin
  if Assigned(_IsAppThemed) then
    Result := _IsAppThemed
  else
    Result := False;
end;

function IsThemeActive: Boolean;
begin
  if Assigned(_IsThemeActive) then
    Result := _IsThemeActive
  else
    Result := False;
end;

function IsThemePartDefined(ATheme: HTHEME; APartId, AStateId: Integer): Boolean;
begin
  if Assigned(_IsThemePartDefined) then
    Result := _IsThemePartDefined(ATheme, APartId, AStateId)
  else
    Result := False;
end;

function OpenThemeData(AWnd: HWND; AClassList: LPCWSTR): HTHEME;
begin
  if Assigned(_OpenThemeData) then
    Result := _OpenThemeData(AWnd, AClassList)
  else
    Result := 0;
end;

function OpenThemeDataForDpi(AWnd: HWND; AClassList: LPCWSTR; ADpi: UINT; ACallDefaultIfFail: Boolean = True): HTHEME;
begin
  if Assigned(_OpenThemeDataForDpi) then
    Result := _OpenThemeDataForDpi(AWnd, AClassList, ADpi)
  else
    if ACallDefaultIfFail then
      Result := OpenThemeData(AWnd, AClassList)
    else
      Result := 0;
end;

function OpenThemeDataEx(AWnd: HWND; AClassList: PWideChar; AFlags: DWORD): HTHEME;
begin
  if Assigned(_OpenThemeDataEx) then
    Result := _OpenThemeDataEx(AWnd, AClassList, AFlags)
  else
    Result := OpenThemeData(AWnd, AClassList);
end;

function UseThemes: Boolean;
begin
  if (UXThemeLib <> 0) then
    Result := IsAppThemed and IsThemeActive
  else
    Result := False;
end;

function GetDpiForWindow(AWnd: HWND): UINT;
var
  DC: HDC;
begin
  if Assigned(@_GetDpiForWindow) then
    Result := _GetDpiForWindow(AWnd)
  else
    begin
      DC := GetDC(AWnd);
      if DC <> 0 then
        begin
          Result := GetDeviceCaps(DC, LOGPIXELSY);
          ReleaseDC(AWnd, DC);
        end
      else
        Result := 96;
    end;
end;

function GetDpiForSystem: UINT;
var
  DC: HDC;
begin
  if Assigned(@_GetDpiForSystem) then
    Result := _GetDpiForSystem
  else
    begin
      DC := GetDC(0);
      if DC <> 0 then
        begin
          Result := GetDeviceCaps(DC, LOGPIXELSY);
          ReleaseDC(0, DC);
        end
      else
        Result := 96;
    end;
end;

function SystemParametersInfoForDpi(AAction: UINT; AParam: UINT; AOut: Pointer; AWinIni, ADpi: UINT; ACallDefaultIfFail: Boolean = True): Boolean;
begin
  if Assigned(@_SystemParametersInfoForDpi) then
    begin
      Result := _SystemParametersInfoForDpi(AAction, AParam, AOut, AWinIni, ADpi);
      if Result then Exit;
    end;
  if ACallDefaultIfFail then
    Result := SystemParametersInfoW(AAction, AParam, AOut, AWinIni)
  else
    Result := False;
end;

function GetSystemMetricsForDpi_(AIndex: Integer; ADpi: UINT; ACallDefaultIfFail: Boolean = True): Integer;
begin
  if Assigned(@_GetSystemMetricsForDpi) then
    begin
      Result := _GetSystemMetricsForDpi(AIndex, ADpi);
      if Result <> 0 then Exit;
    end;
  if ACallDefaultIfFail then
    Result := GetSystemMetrics(AIndex)
  else
    Result := 0;
end;

const
  I_CHILDRENAUTO = -2;

  TVE_ACTIONMASK = $0003; // TVE_COLLAPSE | TVE_EXPAND | TVE_TOGGLE

function IsFlagPtr(APtr: Pointer): BOOL;
begin
  Result := (APtr = nil) or (LPSTR(APtr) = LPSTR_TEXTCALLBACKA);
end;

function ProduceWFromA(AStr: PAnsiChar): UnicodeString;
var
  StrLen: Integer;
begin
  Result := '';
  if not IsFlagPtr(AStr) then
    begin
      StrLen := MultiByteToWideChar(CP_ACP, 0, AStr, -1, nil, 0);
      if StrLen = 0 then Exit;
      SetLength(Result, StrLen);
      if MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, AStr, -1, PWideChar(Result), StrLen) = 0 then
        Result := ''
    end;
end;

function ProduceAFromW(AStr: PWideChar): AnsiString;
var
  StrLen: Integer;
begin
  Result := '';
  if not IsFlagPtr(AStr) then
    begin
      StrLen := WideCharToMultiByte(CP_ACP, 0, AStr, -1, nil, 0, nil, nil);
      if StrLen = 0 then Exit;
      SetLength(Result, StrLen - 1);
      if WideCharToMultiByte(CP_ACP, 0, AStr, -1, PAnsiChar(Result), StrLen, nil, nil) = 0 then
        Result := '';
    end;
end;

type
  TTreeView = class;

  TTreeViewItems = class;

  TTreeViewItem = class(TObject)
  public
    constructor Create(ATreeView: TTreeView; AParentItems: TTreeViewItems; ALevel: Integer);
    destructor Destroy; override;
  private
    FNeedUpdateSize: Boolean;
    function IsVisible: Boolean;
    procedure Invalidate; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
    procedure NeedUpdateSize; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
    procedure NeedUpdateSizeWithChilds;
    procedure AssignW(AItem: PTVItemExW);
    procedure AssignA(AItem: PTVItemExA);
    procedure AssignToW(AItem: PTVItemExW);
    procedure AssignToA(AItem: PTVItemExA);
    function IsChild(AItem: TTreeViewItem): Boolean;
    function HitTest(const APoint: TPoint): UINT;
    function Expand(ACode, AAction: UINT; ANotify: Boolean): Boolean;
    procedure FullExpand(ACode, AAction: UINT; ANotify: Boolean);
    function ExpandParents(AAction: UINT): Boolean;
    procedure UpdateSize(ADC: HDC);
    procedure PaintConnector(ADC: HDC; AIndex: Integer; ADest: TTreeViewItem);
    procedure PaintConnectors(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
    procedure PaintBackground(ADC: HDC; const ARect: TRect; out AFontColor: TColorRef);
    procedure PaintStateIcon(ADC: HDC; const ARect: TRect);
    procedure PaintIcon(ADC: HDC; const ARect: TRect);
    procedure PaintText(ADC: HDC; var ARect: TRect; AFontColor: TColorRef);
    procedure PaintButton(ADC: HDC; const ARect: TRect);
    procedure Paint(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AXOffset, AYOffset: Integer; AEraseBackground: Boolean);
  private
    FTreeView: TTreeView;
    FParentItems: TTreeViewItems;
    FLevel: Integer;
    FIndex: Integer;

    FState: UINT;
    FStateEx: UINT;
    FTextCallback: Boolean;
    FText: UnicodeString;
    FImageIndex: Integer;
    FSelectedImageIndex: Integer;
    FExpandedImageIndex: Integer;
    FChildren: Integer;
    FParam: LPARAM;
    FIntegral: Integer;

    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FTextWidth: Integer;
    FTextHeight: Integer;

    FItems: TTreeViewItems;

    function HasStateIcon: Boolean;
    function HasIcon: Boolean;
    function HasButton: Boolean;

    function GetText: UnicodeString;
    function GetBold: Boolean;
    function GetEnabled: Boolean;
    function GetExpanded: Boolean;
    function GetSelected: Boolean;
    function GetHasChildren: Boolean;
    function GetHasChildrenWithoutCallback: Integer;
    function GetImageIndex: Integer;
    function GetSelectedImageIndex: Integer;
    function GetExpandedImageIndex: Integer;

    function GetRight: Integer;
    function GetBottom: Integer;
    function GetBoundsRect: TRect;
    function GetBoundsRectEx: TRect;
    function GetStateIconRect: TRect;
    function GetIconRect: TRect;
    function GetTextRect: TRect;
    function GetButtonRect: TRect;

    function GetItems: TTreeViewItems;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TTreeViewItem;
  private
    property TreeView: TTreeView read FTreeView;
    property ParentItems: TTreeViewItems read FParentItems;
    property Level: Integer read FLevel;
    property Index_: Integer read FIndex write FIndex;

    property State: UINT read FState;
    property StateEx: UINT read FStateEx;
    property Text: UnicodeString read GetText;
    property Bold: Boolean read GetBold;
    property Enabled: Boolean read GetEnabled;
    property Expanded: Boolean read GetExpanded;
    property Selected: Boolean read GetSelected;
    property HasChildren: Boolean read GetHasChildren;
    property ImageIndex: Integer read GetImageIndex;
    property SelectedImageIndex: Integer read GetSelectedImageIndex;
    property ExpandedImageIndex: Integer read GetExpandedImageIndex;

    property Left: Integer read FLeft write FLeft;
    property Top: Integer read FTop write FTop;
    property Right: Integer read GetRight;
    property Bottom: Integer read GetBottom;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property BoundsRect: TRect read GetBoundsRect;
    property BoundsRectEx: TRect read GetBoundsRectEx;
    property StateIconRect: TRect read GetStateIconRect;
    property IconRect: TRect read GetIconRect;
    property TextRect: TRect read GetTextRect;
    property ButtonRect: TRect read GetButtonRect;

    property Items_: TTreeViewItems read GetItems;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TTreeViewItem read GetItem;
  end;
  PTreeViewItem = ^TTreeViewItem;

  TTreeViewItems = class(TObject)
  public
    constructor Create(ATreeView: TTreeView; AOwner: TTreeViewItem; ALevel: Integer);
    destructor Destroy; override;
  private
    function InsertItemW(AInsertAfter: TTreeViewItem; AItem: PTVItemExW): TTreeViewItem;
    function InsertItemA(AInsertAfter: TTreeViewItem; AItem: PTVItemExA): TTreeViewItem;
    function GetNextItem(AItem: TTreeViewItem; ADirection: DWORD): TTreeViewItem;
    procedure DeleteItem(AItem: TTreeViewItem);
    procedure DeleteAll;
    function ItemAtPos(const APoint: TPoint): TTreeViewItem;
  private
    FTreeView: TTreeView;
    FParent: TTreeViewItem;
    FLevel: Integer;
  private
    Count: Integer;
    Items: array of TTreeViewItem;
    property TreeView: TTreeView read FTreeView;
    property Parent: TTreeViewItem read FParent;
    property Level: Integer read FLevel;
  end;

  TTreeView = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
  private
    {$IFDEF NATIVE_BORDERS}
    procedure CaclClientRect(ARect, AClientRect: PRect);
    procedure PaintClientRect(ARgn: HRGN);
    {$ENDIF}
  private
    // Scroll routines
    FUpdateScrollBars: Boolean;
    FOptimalWidth: Integer;
    FOptimalHeight: Integer;
    function IsScrollBarVisible(ABar: DWORD): Boolean;
    function IsHorzScrollBarVisible: Boolean;
    function IsVertScrollBarVisible: Boolean;
    procedure UpdateScrollBars;
    procedure ScrollMessage(AReason: WPARAM; ABar: DWORD);
    procedure CalcBaseOffsets(var AXOffset, AYOffset: Integer);
    procedure OffsetMousePoint(var APoint: TPoint);
    procedure OffsetItemRect(var ARect: TRect);
  private
    // Paint routines
    FSavePoint: TPoint;
    FPaintRequest: UINT;
    function SendDrawNotify(ADC: HDC; AStage: UINT; var ANMTVCustomDraw: TNMTVCustomDraw): UINT;
    procedure PaintRootConnector(ADC: HDC; ASource, ADest: TTreeViewItem);
    procedure PaintRootConnectors(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
    procedure PaintInsertMask(ADC: HDC; AUpdateRgn: HRGN);
    procedure PaintTo(ADC: HDC; var AUpdateRgn, ABackgroupRgn: HRGN);
    procedure Paint;
    procedure PaintClient(ADC: HDC);
    procedure Invalidate;
    procedure InvalidateItem(AItem: TTreeViewItem);
    procedure InvalidateInsertMask;
  private
    // Item routines
    FInsertMaskItem: TTreeViewItem;
    FInsertMaskItemAfter: Boolean;
    FSelectedItem: TTreeViewItem;
    FMouseOverItem: TTreeViewItem;
    FExpandItem: TTreeViewItem;
    ExpandItemRect: TRect;
    FScrollItem: TTreeViewItem;
    procedure HitTest(TVHitTestInfo: PTVHitTestInfo);
    procedure MakeVisible(AItem: TTreeViewItem);
    function SelectItem(AItem: TTreeViewItem; ANotify: Boolean; AAction: UINT): Boolean;
    procedure UpdateSelected(AAction: UINT);
    procedure SetInsertMaskItemAfter(AInsertMaskItem: TTreeViewItem; AAfter: Boolean);
    procedure SetInsertMaskItem(AInsertMaskItem: TTreeViewItem);
    function GetInsertMaskRect: TRect;
    property InsertMaskItem: TTreeViewItem read FInsertMaskItem write SetInsertMaskItem;
    property InsertMaskItemAfter: Boolean read FInsertMaskItemAfter;
    property InsertMaskRect: TRect read GetInsertMaskRect;
    property SelectedItem: TTreeViewItem read FSelectedItem;
    property MouseOverItem: TTreeViewItem read FMouseOverItem write FMouseOverItem;
    property ExpandItem: TTreeViewItem read FExpandItem write FExpandItem;
    property ScrollItem: TTreeViewItem read FScrollItem write FScrollItem;
  private
    // Control routines
    FMoveMode: Boolean;
    FMoveMouseStartPos: TPoint;
    FMoveScrollStartPos: TPoint;
    procedure KeyDown(AKeyCode: DWORD; AFlags: DWORD);
    procedure LButtonDown(APoint: TPoint);
    procedure LButtonUp(APoint: TPoint);
    procedure MButtonDown(APoint: TPoint);
    procedure RButtonDown(APoint: TPoint);
    procedure MouseMove(APoint: TPoint);
  private
    // Callback routines
    function SendNotify(AParentWnd, AWnd: HWND; ACode: Integer; ANMHdr: PNMHdr): LRESULT; overload;
    function SendNotify(ACode: Integer; ANMHdr: PNMHdr): LRESULT; overload;
    function SendItemExpand(ACode: Integer; AItem: TTreeViewItem; AAction: UINT): Boolean;
    function SendSelectChange(ACode: Integer; AOldItem, ANewItem: TTreeViewItem; AAction: UINT): Boolean;
  private
    // Main routines
    FTempTextBuffer: Pointer;
    FNeedUpdateItemPositions: Boolean;
    FUpdateCount: Integer;
    FLockUpdate: Boolean;
    FProcessedItems: array of TTreeViewItem;
    FArrowCursor: HCURSOR;
    FHandCursor: HCURSOR;
    FMoveCursor: HCURSOR;
    procedure DoUpdate;
    procedure Update;
    procedure FullUpdate;
    procedure SetLockUpdate(ALockUpdate: Boolean);
    function WndProc(AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT;
  private
    FParentHandle: HWND;
    FHandle: HWND;
    FUnicode: Boolean;
    FDestroying: Boolean;
  private
    FFocused: Boolean;
    FStyle: UINT;
    FStyle2: UINT;
    FStyleEx: UINT;
    FAutoCenter: Boolean;
    FAlwaysShowSelection: Boolean;
    FHasButtons: Boolean;
    FLinesAsRoot: Boolean;
    FDpi: UINT;
    FTheme: HTHEME;
    FDpiTheme: Boolean;
    FCXVScroll: Integer;
    FCYHScroll: Integer;
    FThemeButtonSize: TSize;
    FButtonSize: TSize;
    FFont: HFONT;
    FSysFont: Boolean;
    FBoldFont: HFONT;
    FSysColor: Boolean;
    FColor: TColorRef;
    FSysTextColor: Boolean;
    FTextColor: TColorRef;
    FSysLineColor: Boolean;
    FLineColor: TColorRef;
    FSysInsertMaskColor: Boolean;
    FInsertMaskColor: TColorRef;
    FImageList: HIMAGELIST;
    FImageListIconSize: TSize;
    FStateImageList: HIMAGELIST;
    FStateImageListIconSize: TSize;
    FHorzBorder: Integer;
    FVertBorder: Integer;
    FHorzSpace: Integer;
    FVertSpace: Integer;
    FItems: TTreeViewItems;
    FTotalCount: Integer;
    procedure SetFocused(AFocused: Boolean);
    procedure InitStyles(AStyles: UINT);
    procedure InitStyles2(AStyles2: UINT);
    procedure InitStylesEx(AStylesEx: UINT);
    procedure SetStyle(AStyle: UINT);
    procedure SetStyle2(AMask, AStyle2: UINT);
    procedure SetStyleEx(AStyleEx: UINT);
    procedure SetDpi(ADpi: UINT);
    procedure CloseTheme;
    procedure OpenTheme;
    function GetThemed: Boolean;
    procedure DeleteFont;
    procedure UpdateScrollBarSize;
    procedure UpdateButtonSize;
    function GetButtonSize: TSize;
    procedure SetFont(AFont: HFONT);
    function GetBoldFont: HFONT;
    procedure UpdateColors;
    procedure SetColor(AColor: TColorRef);
    procedure SetTextColor(ATextColor: TColorRef);
    procedure SetLineColor(ALineColor: TColorRef);
    procedure SetInsertMaskColor(AInsertMaskColor: TColorRef);
    procedure SetImageList(AImageList: HIMAGELIST);
    procedure SetStateImageList(AStateImageList: HIMAGELIST);
    procedure SetBorders(AHorzBorder, AVertBorder: Integer);
    procedure SetHorzBorder(AHorzBorder: Integer);
    procedure SetVertBorder(AVertBorder: Integer);
    procedure SetSpaces(AHorzSpace, AVertSpace: Integer);
    procedure SetHorzSpace(AHorzSpace: Integer);
    procedure SetVertSpace(AVertSpace: Integer);
    function GetItems: TTreeViewItems;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TTreeViewItem;
    property Focused: Boolean read FFocused write SetFocused;
    property AutoCenter: Boolean read FAutoCenter;
    property AlwaysShowSelection: Boolean read FAlwaysShowSelection;
    property HasButtons: Boolean read FHasButtons;
    property LinesAsRoot: Boolean read FLinesAsRoot;
    property Dpi: UINT read FDpi write SetDpi;
    property Themed: Boolean read GetThemed;
    property Theme: HTHEME read FTheme;
    property ButtonSize: TSize read GetButtonSize;
    property Font: HFONT read FFont write SetFont;
    property BoldFont: HFONT read GetBoldFont;
    property Color: TColorRef read FColor write SetColor;
    property TextColor: TColorRef read FTextColor write SetTextColor;
    property LineColor: TColorRef read FLineColor write SetLineColor;
    property InsertMaskColor: TColorRef read FInsertMaskColor write SetInsertMaskColor;
    property ImageList: HIMAGELIST read FImageList write SetImageList;
    property ImageListIconSize: TSize read FImageListIconSize;
    property StateImageList: HIMAGELIST read FStateImageList write SetStateImageList;
    property StateImageListIconSize: TSize read FStateImageListIconSize;
    property HorzBorder: Integer read FHorzBorder write SetHorzBorder;
    property VertBorder: Integer read FVertBorder write SetVertBorder;
    property HorzSpace: Integer read FHorzSpace write SetHorzSpace;
    property VertSpace: Integer read FVertSpace write SetVertSpace;
    property Items_: TTreeViewItems read GetItems;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TTreeViewItem read GetItem;
  end;

//**************************************************************************************************
// TTreeViewItem
//**************************************************************************************************

constructor TTreeViewItem.Create(ATreeView: TTreeView; AParentItems: TTreeViewItems; ALevel: Integer);
begin
  inherited Create;
  FTreeView := ATreeView;
  FParentItems := AParentItems;
  FLevel := ALevel;
  FNeedUpdateSize := True;
  FChildren := I_CHILDRENAUTO;
  FImageIndex := I_IMAGECALLBACK;
  FSelectedImageIndex := I_IMAGECALLBACK;
  FExpandedImageIndex := I_IMAGECALLBACK;
end;

destructor TTreeViewItem.Destroy;
begin
  if Assigned(FItems) then
    FItems.Free;
  inherited Destroy;
end;

function TTreeViewItem.IsVisible: Boolean;
begin
  if not Assigned(ParentItems.Parent) then
    Result := True
  else
    Result := ParentItems.Parent.IsVisible and ParentItems.Parent.Expanded;
end;

procedure TTreeViewItem.Invalidate;
begin
  TreeView.InvalidateItem(Self);
end;

procedure TTreeViewItem.NeedUpdateSize;
begin
  FNeedUpdateSize := True;
end;

procedure TTreeViewItem.NeedUpdateSizeWithChilds;
var
  ItemIndex: Integer;
begin
  FNeedUpdateSize := True;
  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].NeedUpdateSizeWithChilds;
end;

procedure TTreeViewItem.AssignA(AItem: PTVItemExA);
var
  SaveText: PAnsiChar;
  SaveLen: Integer;
  NewText: UnicodeString;
begin
  if (AItem.mask and TVIF_TEXT = 0) or IsFlagPtr(AItem.pszText) then
    AssignW(PTVItemExW(AItem))
  else
    begin
      SaveText := AItem.pszText;
      SaveLen := AItem.cchTextMax;
      NewText := ProduceWFromA(AItem.pszText);
      AItem.pszText := PAnsiChar(PWideChar(NewText));
      AssignW(PTVItemExW(AItem));
      AItem.pszText := SaveText;
      AItem.cchTextMax := SaveLen;
    end;
end;

procedure TTreeViewItem.AssignW(AItem: PTVItemExW);
var
  NeedUpdate: Boolean;
  NeedInvalidate: Boolean;
  PrevHasChildren: Integer;
  PrevBold: Boolean;
  PrevEnabled: Boolean;
  PrevExpanded: Boolean;
  PrevSelected: Boolean;
  PrevOverlayIndex: Integer;
  PrevStateIconIndex: Integer;
  NewOverlayIndex: Integer;
  NewStateIconIndex: Integer;
begin
  NeedUpdate := False;
  NeedInvalidate := False;

  if AItem.mask and TVIF_TEXT <> 0 then
    begin
      if IsFlagPtr(AItem.pszText) then
        begin
          FTextCallback := True;
          FText := '';
        end
      else
        begin
          FTextCallback := False;
          FText := AItem.pszText;
        end;
      NeedUpdate := True;
    end;

  if AItem.mask and TVIF_IMAGE <> 0 then
    begin
      if (FImageIndex <> AItem.iImage) or (AItem.iImage = I_IMAGECALLBACK) then
        NeedInvalidate := True;
      FImageIndex := AItem.iImage;
    end;

  if AItem.mask and TVIF_SELECTEDIMAGE <> 0 then
    begin
      if (FSelectedImageIndex <> AItem.iSelectedImage) or (AItem.iSelectedImage = I_IMAGECALLBACK) then
        NeedInvalidate := True;
      FSelectedImageIndex := AItem.iSelectedImage;
    end;

  if AItem.mask and TVIF_EXPANDEDIMAGE <> 0 then
    begin
      if (FExpandedImageIndex <> AItem.iExpandedImage) or (AItem.iExpandedImage = I_IMAGECALLBACK) then
        NeedInvalidate := True;
      FExpandedImageIndex := AItem.iExpandedImage;
    end;

  if AItem.mask and TVIF_PARAM <> 0 then
    FParam := AItem.lParam;
  if AItem.mask and TVIF_INTEGRAL <> 0 then
    FIntegral := AItem.iIntegral;

  if AItem.mask and TVIF_CHILDREN <> 0 then
    begin
      PrevHasChildren := GetHasChildrenWithoutCallback;
      FChildren := AItem.cChildren;
      if GetHasChildrenWithoutCallback <> PrevHasChildren then
        NeedUpdate := True;
    end;

  PrevBold := Bold;
  PrevExpanded := Expanded;
  PrevSelected := Selected;
  PrevOverlayIndex := FState and TVIS_OVERLAYMASK;
  PrevStateIconIndex := FState and TVIS_STATEIMAGEMASK;

  if (AItem.cChildren = I_CHILDRENCALLBACK) and (Count = 0) then
    FState := FState and not (TVIS_EXPANDEDONCE or TVIS_EXPANDED);

  NewOverlayIndex := FState and TVIS_OVERLAYMASK;
  if NewOverlayIndex <> PrevOverlayIndex then
    if (NewOverlayIndex = 0) or (PrevOverlayIndex = 0) then
      NeedUpdate := True
    else
      NeedInvalidate := True;

  NewStateIconIndex := FState and TVIS_STATEIMAGEMASK;
  if NewStateIconIndex <> PrevStateIconIndex then
    if (NewStateIconIndex = 0) or (PrevStateIconIndex = 0) then
      NeedUpdate := True
    else
      NeedInvalidate := True;

  PrevEnabled := Enabled;
  if AItem.mask and TVIF_STATEEX <> 0 then
    FStateEx := AItem.uStateEx;
  if Enabled <> PrevEnabled then
    NeedInvalidate := True;

  if AItem.mask and TVIF_STATE <> 0 then
    begin
      FState := (FState and not AItem.stateMask) or (AItem.state and AItem.stateMask);

      if Selected <> PrevSelected then
        if Selected then
          begin
            if not FTreeView.SelectItem(Self, False, TVC_UNKNOWN) then
              FState := FState and not TVIS_SELECTED;
          end
        else
          begin
            if not FTreeView.SelectItem(nil, False, TVC_UNKNOWN) then
              FState := FState or TVIS_SELECTED;
          end;

      if Expanded <> PrevExpanded then
        if Expanded then
          begin
            if not Expand(TVE_EXPAND, TVC_UNKNOWN, False) then
              FState := FState and not TVIS_EXPANDED;
          end
        else
          begin
            if not Expand(TVE_COLLAPSE, TVC_UNKNOWN, False) then
              FState := FState or TVIS_EXPANDED;
          end;

      if Bold <> PrevBold then
        NeedUpdate := True;
      if Expanded <> PrevExpanded then
        NeedUpdate := True;
      if Selected <> PrevSelected then
        NeedInvalidate := True;
    end;

  if NeedUpdate then
    begin
      NeedUpdateSize;
      TreeView.Update;
    end
  else
    if NeedInvalidate then
      Invalidate;
end;

procedure TTreeViewItem.AssignToW(AItem: PTVItemExW);
var
  S: UnicodeString;
begin
  if (AItem.mask and TVIF_TEXT <> 0) and Assigned(AItem.pszText) and (AItem.cchTextMax > 0) then
    begin
      if AItem.cchTextMax = 1 then
        AItem.pszText^ := #0
      else
        begin
          S := Text;
          if Length(S) >= AItem.cchTextMax then
            SetLength(S, AItem.cchTextMax - 1);
          if S = '' then
            AItem.pszText^ := #0
          else
            CopyMemory(AItem.pszText, PWideChar(S), (Length(S) + 1) * SizeOf(WideChar));
        end;
    end;
  if AItem.mask and TVIF_IMAGE <> 0 then
    AItem.iImage := ImageIndex;
  if AItem.mask and TVIF_PARAM <> 0 then
    AItem.lParam := FParam;
  if AItem.mask and TVIF_STATE <> 0 then
    AItem.state := FState;
  if AItem.mask and TVIF_SELECTEDIMAGE <> 0 then
    AItem.iSelectedImage := SelectedImageIndex;
  if AItem.mask and TVIF_CHILDREN <> 0 then
    AItem.cChildren := FChildren;
  if AItem.mask and TVIF_INTEGRAL <> 0 then
    AItem.iIntegral := FIntegral;
  if AItem.mask and TVIF_STATEEX <> 0 then
    AItem.uStateEx := FStateEx;
  if AItem.mask and TVIF_EXPANDEDIMAGE <> 0 then
    AItem.iExpandedImage := ExpandedImageIndex;
end;

procedure TTreeViewItem.AssignToA(AItem: PTVItemExA);
var
  SaveText: PAnsiChar;
  SaveLen: Integer;
  NewText: UnicodeString;
  S: AnsiString;
begin
  if (AItem.mask and TVIF_TEXT = 0) or not Assigned(AItem.pszText) or (AItem.cchTextMax = 0) then
    AssignToW(PTVItemExW(AItem))
  else
    begin
      SaveText := AItem.pszText;
      SaveLen := AItem.cchTextMax;
      SetLength(NewText, AItem.cchTextMax);
      NewText[1] := #0;
      AItem.pszText := PAnsiChar(PWideChar(NewText));
      AssignToW(PTVItemExW(AItem));
      AItem.pszText := SaveText;
      AItem.cchTextMax := SaveLen;
      S := ProduceAFromW(PWideChar(NewText));

      if AItem.cchTextMax = 1 then
        AItem.pszText^ := #0
      else
        begin
          if Length(S) >= AItem.cchTextMax then
            SetLength(S, AItem.cchTextMax - 1);
          if S = '' then
            AItem.pszText^ := #0
          else
            CopyMemory(AItem.pszText, PAnsiChar(S), (Length(S) + 1) * SizeOf(AnsiChar));
        end;
    end;

  {if (AItem.mask and TVIF_TEXT <> 0) and Assigned(AItem.pszText) and (AItem.cchTextMax > 0) then
    begin
      if AItem.cchTextMax = 1 then
        AItem.pszText^ := #0
      else
        begin
          S := AnsiString(Text);
          if Length(S) >= AItem.cchTextMax then
            SetLength(S, AItem.cchTextMax - 1);
          if S = '' then
            AItem.pszText^ := #0
          else
            CopyMemory(AItem.pszText, PAnsiChar(S), (Length(S) + 1) * SizeOf(AnsiChar));
        end;
    end;
  DoAssignTo(PTVItemExW(AItem));}
end;


function TTreeViewItem.IsChild(AItem: TTreeViewItem): Boolean;
begin
  Result := False;
  while Assigned(AItem) do
    if AItem.ParentItems.Parent = Self then
      begin
        Result := True;
        Exit;
      end
    else
      AItem := AItem.ParentItems.Parent;
end;

function TTreeViewItem.HitTest(const APoint: TPoint): UINT;
begin
  if HasStateIcon and PtInRect(StateIconRect, APoint) then
    Result := TVHT_ONITEMSTATEICON
  else
  if HasIcon and PtInRect(IconRect, APoint) then
    Result := TVHT_ONITEMICON
  else
  if HasButton and PtInRect(ButtonRect, APoint) then
    Result := TVHT_ONITEMBUTTON
  else
    Result := TVHT_ONITEMLABEL;
end;

function TTreeViewItem.Expand(ACode, AAction: UINT; ANotify: Boolean): Boolean;
var
  RealCode: UINT;
begin
  Result := False;
  RealCode := ACode and TVE_ACTIONMASK;
  if (RealCode = 0) or not HasChildren then Exit;

  if RealCode = TVE_TOGGLE then
    begin
      if Expanded then ACode := TVE_COLLAPSE
                  else ACode := TVE_EXPAND;
      RealCode := ACode;
    end;

  case RealCode of
    TVE_COLLAPSE:
      if not Expanded then
        begin
          Result := True;
          Exit;
        end;
    TVE_EXPAND:
      if Expanded then
        begin
          Result := True;
          Exit;
        end;
  end;

  if (RealCode = TVE_EXPAND) and (FState and TVIS_EXPANDEDONCE = 0) then
    ANotify := True;

  if ANotify and TreeView.SendItemExpand(TVN_ITEMEXPANDING, Self, ACode) then Exit;

  if Count = 0 then Exit;

	if RealCode = TVE_EXPAND then FState := FState or TVIS_EXPANDED
                           else FState := FState and not TVIS_EXPANDED;

  if ANotify then
    TreeView.SendItemExpand(TVN_ITEMEXPANDED, Self, ACode);

  FState := FState or TVIS_EXPANDEDONCE;

  if (RealCode or TVE_COLLAPSERESET) = (TVE_COLLAPSE or TVE_COLLAPSERESET) then
    begin
      FState := FState and not TVIS_EXPANDEDONCE;
      {if Count > 0 then
        Items_.DeleteAll;}
    end;

  if not Expanded and IsChild(TreeView.SelectedItem) then
    begin
      if not TreeView.SelectItem(Self, True, AAction) then
        begin
          TreeView.SelectedItem.FState := TreeView.SelectedItem.FState and not TVIS_SELECTED;
          TreeView.FSelectedItem := nil;
        end;
    end;

  if not Assigned(TreeView.ExpandItem) then
    begin
      TreeView.ExpandItem := Self;
      TreeView.ExpandItemRect := BoundsRect;
    end;
  TreeView.Update;

  Result := True;
end;

procedure TTreeViewItem.FullExpand(ACode, AAction: UINT; ANotify: Boolean);
var
  ItemIndex: Integer;
begin
  Expand(ACode, AAction, ANotify);
  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].FullExpand(ACode, AAction, ANotify);
end;

function TTreeViewItem.ExpandParents(AAction: UINT): Boolean;
begin
  Result := True;
  if Assigned(FParentItems.FParent) then
    begin
      Result := FParentItems.FParent.ExpandParents(AAction);
      if Result then
        Result := FParentItems.FParent.Expand(TVE_EXPAND, AAction, True);
    end;
end;

procedure TTreeViewItem.UpdateSize(ADC: HDC);
var
  S: UnicodeString;
  R: TRect;
  SaveFont: HFONT;
  ItemIndex: Integer;
  ButtonSize: TSize;
begin
  if FNeedUpdateSize then
    begin
      FWidth := 0;
      FHeight := 0;

      S := Text;
      R.Left := 0;
      R.Top := 0;
      R.Right := 0;
      R.Bottom := 0;

      if Bold then SaveFont := SelectObject(ADC, TreeView.BoldFont)
              else SaveFont := SelectObject(ADC, TreeView.Font);
      DrawTextExW(ADC, PWideChar(S), Length(S), R, DT_CALCRECT or DT_LEFT or DT_NOPREFIX, nil);
      SelectObject(ADC, SaveFont);
      FTextWidth := R.Right - R.Left;
      FTextHeight := R.Bottom - R.Top;

      Inc(FWidth, FTextWidth);
      Inc(FHeight, FTextHeight);

      if HasStateIcon then
        begin
          Inc(FWidth, TreeView.StateImageListIconSize.cx + FTreeView.HorzBorder);
          FHeight := Max(FHeight, TreeView.StateImageListIconSize.cy);
        end;

      if HasIcon then
        begin
          Inc(FWidth, TreeView.ImageListIconSize.cx + FTreeView.HorzBorder);
          FHeight := Max(FHeight, TreeView.ImageListIconSize.cy);
        end;

      if HasButton then
        begin
          ButtonSize := TreeView.ButtonSize;
          Inc(FWidth, FTreeView.HorzBorder + ButtonSize.cx);
          FHeight := Max(FHeight, ButtonSize.cy);
        end;

      Inc(FWidth, FTreeView.HorzBorder * 2 + 2);
      Inc(FHeight, FTreeView.VertBorder * 2 + 2);

      FNeedUpdateSize := False;
    end;

  if Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].UpdateSize(ADC);
end;

procedure TTreeViewItem.PaintConnector(ADC: HDC; AIndex: Integer; ADest: TTreeViewItem);
var
  Points: packed array[0..3] of TPoint;
  Pen: HPEN;
  SavePen: HPEN;
begin
  Points[0].X := Right;
  Points[0].Y := Top + Round((Height / (Count + 1)) * (AIndex + 1));
  Points[1].X := Points[0].X + TreeView.HorzSpace div 2;
  Points[1].Y := Points[0].Y;
  Points[3].X := ADest.Left;
  Points[3].Y := ADest.Top + Round(ADest.Height / 2);
  Points[2].X := Points[3].X - TreeView.HorzSpace div 2;
  Points[2].Y := Points[3].Y;

  Pen := CreatePen(PS_SOLID, 1, TreeView.LineColor);
  SavePen := SelectObject(ADC, Pen);
  PolyBezier(ADC, Points, 4);
  SelectObject(ADC, SavePen);
  DeleteObject(Pen);
end;

procedure FillRectWithColor(ADC: HDC; const ARect: TRect; AColor: TColorRef);
var
  Brush: HBRUSH;
begin
  Brush := CreateSolidBrush(AColor);
  FillRect(ADC, ARect, Brush);
  DeleteObject(Brush);
end;

procedure FillRgnWithColor(ADC: HDC; ARgn: HRGN; AColor: TColorRef);
var
  Brush: HBRUSH;
begin
  Brush := CreateSolidBrush(AColor);
  FillRgn(ADC, ARgn, Brush);
  DeleteObject(Brush);
end;

procedure FrameRectWithColor(ADC: HDC; const ARect: TRect; AColor: TColorRef);
var
  Brush: HBRUSH;
begin
  Brush := CreateSolidBrush(AColor);
  FrameRect(ADC, ARect, Brush);
  DeleteObject(Brush);
end;

procedure TTreeViewItem.PaintConnectors(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
var
  ConnectorRect: TRect;
  ItemIndex: Integer;
  Item: TTreeViewItem;
  TempRgn: HRGN;
begin
  if Expanded and (Count > 0) then
    begin
      ConnectorRect.Left := Right;
      ConnectorRect.Right := ConnectorRect.Left + TreeView.HorzSpace;
      ConnectorRect.Top := Top;
      ConnectorRect.Bottom := Bottom;

      for ItemIndex := 0 to Count - 1 do
        begin
          Item := Items[ItemIndex];
          ConnectorRect.Top := Min(ConnectorRect.Top, Item.Top);
          ConnectorRect.Bottom := Max(ConnectorRect.Bottom, Item.Bottom);
        end;

      if RectInRegion(AUpdateRgn, ConnectorRect) then
        begin
          if AEraseBackground then
            begin
              FillRectWithColor(ADC, ConnectorRect, TreeView.Color);
              TempRgn := CreateRectRgnIndirect(ConnectorRect);
              CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
              DeleteObject(TempRgn);
            end;

          for ItemIndex := 0 to Count - 1 do
            begin
              Item := Items[ItemIndex];
              ConnectorRect.Top := Min(Top, Item.Top);
              ConnectorRect.Bottom := Max(Bottom, Item.Bottom);
              if RectInRegion(AUpdateRgn, ConnectorRect) then
                PaintConnector(ADC, ItemIndex, Item);
            end;
        end;
    end;
end;

procedure TTreeViewItem.PaintBackground(ADC: HDC; const ARect: TRect; out AFontColor: TColorRef);
var
  StateID: Integer;
  BackgroudColor: TColorRef;
begin
  AFontColor := TreeView.TextColor;
  if TreeView.Themed then
    begin
      FillRectWithColor(ADC, ARect, TreeView.Color);

      StateID := TREIS_NORMAL;
      if not Enabled then
        begin
          StateID := TREIS_DISABLED;
          GetThemeColor(TreeView.Theme, TVP_TREEITEM, TREIS_DISABLED, 3803 {TMT_TEXTCOLOR}, AFontColor);
        end
      else
        if Selected then
          if TreeView.Focused then
            StateID := TREIS_SELECTED
          else
            if TreeView.AlwaysShowSelection then
              begin
                StateID := TREIS_SELECTED;
                if IsThemePartDefined(TreeView.Theme, TVP_TREEITEM, TREIS_SELECTEDNOTFOCUS) then
                  StateID := TREIS_SELECTEDNOTFOCUS;
              end;
      if StateID <> TREIS_NORMAL then
        DrawThemeBackground(TreeView.Theme, ADC, TVP_TREEITEM, StateID, ARect, nil);
    end
  else
    begin
      BackgroudColor := TreeView.Color;
      if not Enabled then
        AFontColor := GetSysColor(COLOR_GRAYTEXT)
      else
        if Selected then
          begin
            if TreeView.Focused then
              begin
                BackgroudColor := GetSysColor(COLOR_HIGHLIGHT);
                AFontColor := GetSysColor(COLOR_HIGHLIGHTTEXT);
              end
            else
              if TreeView.AlwaysShowSelection then
                BackgroudColor := GetSysColor(COLOR_BTNFACE);
          end;
      FillRectWithColor(ADC, ARect, BackgroudColor);
    end;
end;

procedure TTreeViewItem.PaintStateIcon(ADC: HDC; const ARect: TRect);
var
  IconIndex: Integer;
begin
  IconIndex := (FState and TVIS_STATEIMAGEMASK) shr 12;
  ImageList_Draw(TreeView.StateImageList, IconIndex, ADC, ARect.Left, ARect.Top, ILD_NORMAL);
end;

procedure TTreeViewItem.PaintIcon(ADC: HDC; const ARect: TRect);
var
  IconIndex: Integer;
begin
  if Selected then
    IconIndex := SelectedImageIndex
  else
    if Expanded then
      IconIndex := ExpandedImageIndex
    else
      IconIndex := ImageIndex;
  if IconIndex <> I_IMAGECALLBACK then
    ImageList_DrawEx(TreeView.ImageList, IconIndex, ADC, ARect.Left, ARect.Top, 0, 0, CLR_DEFAULT, CLR_DEFAULT, ILD_NORMAL or (FState and TVIS_OVERLAYMASK));
end;

procedure TTreeViewItem.PaintText(ADC: HDC; var ARect: TRect; AFontColor: TColorRef);
var
  S: UnicodeString;
  SaveFont: HFONT;
begin
  S := Text;
  if S <> '' then
    begin
      if Bold then SaveFont := SelectObject(ADC, TreeView.BoldFont)
              else SaveFont := SelectObject(ADC, TreeView.Font);
      SetBkMode(ADC, TRANSPARENT);
      SetTextColor(ADC, AFontColor);
      DrawTextExW(ADC, PWideChar(S), Length(S), ARect, DT_CENTER or DT_NOPREFIX, nil);
      SelectObject(ADC, SaveFont);
    end;
end;

procedure TTreeViewItem.PaintButton(ADC: HDC; const ARect: TRect);
var
  StateID: Integer;
  Pen: HPEN;
  SavePen: HPEN;
  X, Y: Integer;
begin
  if HasButton then
    if TreeView.Themed then
      begin
        if Expanded then StateID := GLPS_OPENED
                    else StateID := GLPS_CLOSED;
        DrawThemeBackground(TreeView.Theme, ADC, TVP_GLYPH, StateID, ARect, nil);
      end
    else
      begin
        FillRectWithColor(ADC, ARect, TreeView.Color);
        FrameRectWithColor(ADC, ARect, GetSysColor(COLOR_GRAYTEXT));
        Pen := CreatePen(PS_SOLID, 1, TreeView.TextColor);
        SavePen := SelectObject(ADC, Pen);
        Y := ARect.Top + (ARect.Bottom - ARect.Top) div 2;
        MoveToEx(ADC, ARect.Left + 2, Y, nil);
        LineTo(ADC, ARect.Right - 2, Y);
        if not Expanded then
          begin
            X := ARect.Left + (ARect.Right - ARect.Left) div 2;
            MoveToEx(ADC, X, ARect.Top + 2, nil);
            LineTo(ADC, X, ARect.Bottom - 2);
          end;
        SelectObject(ADC, SavePen);
        DeleteObject(Pen);
      end;
end;

procedure TTreeViewItem.Paint(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AXOffset, AYOffset: Integer; AEraseBackground: Boolean);
var
  TempRgn: HRGN;
  ItemRect: TRect;
  NMTVCustomDraw: TNMTVCustomDraw;
  PaintRequest: UINT;
  ItemIndex: Integer;
  FontColor: TColorRef;
  R: TRect;
begin
  PaintConnectors(ADC, AUpdateRgn, ABackgroupRgn, AEraseBackground);

  ItemRect := BoundsRect;
  if RectInRegion(AUpdateRgn, ItemRect) then
    begin
      PaintBackground(ADC, ItemRect, FontColor);

      NMTVCustomDraw.clrText := FontColor;
      NMTVCustomDraw.clrTextBk := CLR_NONE;

      if FTreeView.FPaintRequest and CDRF_NOTIFYSUBITEMDRAW <> 0 then
        begin
          ZeroMemory(@NMTVCustomDraw, SizeOf(NMTVCustomDraw));
          NMTVCustomDraw.nmcd.rc := BoundsRect;
          OffsetRect(NMTVCustomDraw.nmcd.rc, -AXOffset, -AYOffset);
          NMTVCustomDraw.nmcd.dwItemSpec := DWORD_PTR(Self);
          if Selected then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_SELECTED;
          if not Enabled then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_DISABLED;
          if FTreeView.Focused then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_FOCUS;
          NMTVCustomDraw.nmcd.lItemlParam := FParam;
          NMTVCustomDraw.iLevel := Level;
          PaintRequest := FTreeView.SendDrawNotify(ADC, CDDS_ITEMPREPAINT, NMTVCustomDraw);
        end
      else
        PaintRequest := CDRF_DODEFAULT;

      if PaintRequest and CDRF_SKIPDEFAULT = 0 then
        begin
          if NMTVCustomDraw.clrTextBk <> CLR_NONE then
            FillRectWithColor(ADC, ItemRect, NMTVCustomDraw.clrTextBk);
          FrameRectWithColor(ADC, ItemRect, TreeView.LineColor);

          if (PaintRequest and TVCDRF_NOIMAGES = 0) and HasStateIcon then
            begin
              R := StateIconRect;
              if RectInRegion(AUpdateRgn, R) then
                PaintStateIcon(ADC, R);
            end;

          if (PaintRequest and TVCDRF_NOIMAGES = 0) and HasIcon then
            begin
              R := IconRect;
              if RectInRegion(AUpdateRgn, R) then
                PaintIcon(ADC, R);
            end;

          R := TextRect;
          if RectInRegion(AUpdateRgn, R) then
            PaintText(ADC, R, NMTVCustomDraw.clrText);

          if HasButton then
            begin
              R := ButtonRect;
              if RectInRegion(AUpdateRgn, R) then
                PaintButton(ADC, R);
            end;

          {$IFDEF DEBUG}
          {if HasStateIcon then
            FrameRectWithColor(ADC, StateIconRect, $00FF00);
          if HasIcon then
            FrameRectWithColor(ADC, IconRect, $00FF00);
          FrameRectWithColor(ADC, GetTextRect, $00FF00);
          if HasButton then
            FrameRectWithColor(ADC, ButtonRect, $00FF00);{}
          {$ENDIF}
        end;

      if PaintRequest and CDRF_NOTIFYPOSTPAINT <> 0 then
        FTreeView.SendDrawNotify(ADC, CDDS_ITEMPOSTPAINT, NMTVCustomDraw);

      if AEraseBackground then
        begin
          TempRgn := CreateRectRgnIndirect(ItemRect);
          CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
          DeleteObject(TempRgn);
        end;
    end;

  if Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].Paint(ADC, AUpdateRgn, ABackgroupRgn, AXOffset, AYOffset, AEraseBackground);
end;

function TTreeViewItem.HasStateIcon: Boolean;
begin
  Result := (TreeView.StateImageList <> 0) and (FState and TVIS_STATEIMAGEMASK <> 0);
end;

function TTreeViewItem.HasIcon: Boolean;
begin
  Result := TreeView.ImageList <> 0;
end;

function TTreeViewItem.HasButton: Boolean;
begin
  Result := TreeView.HasButtons and HasChildren;
end;

function TTreeViewItem.GetText: UnicodeString;
var
  TVDispInfoW: TTVDispInfoW;
begin
  if FTextCallback then
    begin
      if not Assigned(TreeView.FTempTextBuffer) then
        GetMem(TreeView.FTempTextBuffer, 32768 * SizeOf(WideChar));
      TVDispInfoW.item.mask := TVIF_HANDLE or TVIF_PARAM or TVIF_TEXT;
      TVDispInfoW.item.hItem := HTreeItem(Self);
      TVDispInfoW.item.lParam := FParam;
      TVDispInfoW.item.pszText := TreeView.FTempTextBuffer;
      TVDispInfoW.item.pszText^ := #0;
      TVDispInfoW.item.cchTextMax := 32768;
      TreeView.SendNotify(TVN_GETDISPINFOW, @TVDispInfoW);
      Result := PWideChar(TreeView.FTempTextBuffer);
    end
  else
    Result := FText;
end;

function TTreeViewItem.GetBold: Boolean;
begin
  Result := FState and TVIS_BOLD <> 0;
end;

function TTreeViewItem.GetEnabled: Boolean;
begin
  Result := StateEx and TVIS_EX_DISABLED = 0;
end;

function TTreeViewItem.GetExpanded: Boolean;
begin
  Result := FState and TVIS_EXPANDED <> 0;
end;

function TTreeViewItem.GetSelected: Boolean;
begin
  Result := FState and TVIS_SELECTED <> 0;
end;

function TTreeViewItem.GetHasChildren: Boolean;
var
  TVDispInfoW: TTVDispInfoW;
begin
  if Count > 0 then
    Result := True
  else
    case FChildren of
      I_CHILDRENAUTO: Result := {Count > 0}False;
      I_CHILDRENCALLBACK:
        begin
          TVDispInfoW.item.mask := TVIF_HANDLE or TVIF_PARAM or TVIF_CHILDREN;
          TVDispInfoW.item.hItem := HTreeItem(Self);
          TVDispInfoW.item.lParam := FParam;
          TVDispInfoW.item.cChildren := 0;
          TreeView.SendNotify(TVN_GETDISPINFOW, @TVDispInfoW);
          case TVDispInfoW.item.cChildren of
            0: Result := False;
            I_CHILDRENAUTO: Result := Count > 0;
          else
            Result := True;
          end;
        end;
      0: Result := False;
    else
      Result := True;
    end;
end;

function TTreeViewItem.GetHasChildrenWithoutCallback: Integer;
begin
  if Count > 0 then
    Result := 1
  else
    case FChildren of
      I_CHILDRENAUTO: Result := {Count > 0}0;
      I_CHILDRENCALLBACK: Result := -1;
      0: Result := 0;
    else
      Result := 1;
    end;
end;

function TTreeViewItem.GetImageIndex: Integer;
var
  TVDispInfoW: TTVDispInfoW;
begin
  if FImageIndex = I_IMAGECALLBACK then
    begin
      TVDispInfoW.item.mask := TVIF_HANDLE or TVIF_PARAM or TVIF_IMAGE;
      TVDispInfoW.item.hItem := HTreeItem(Self);
      TVDispInfoW.item.lParam := FParam;
      TVDispInfoW.item.iImage := I_IMAGECALLBACK;
      TreeView.SendNotify(TVN_GETDISPINFOW, @TVDispInfoW);
      Result := TVDispInfoW.item.iImage;
    end
  else
    Result := FImageIndex;
end;

function TTreeViewItem.GetSelectedImageIndex: Integer;
var
  TVDispInfoW: TTVDispInfoW;
begin
  if FSelectedImageIndex = I_IMAGECALLBACK then
    begin
      TVDispInfoW.item.mask := TVIF_HANDLE or TVIF_PARAM or TVIF_SELECTEDIMAGE;
      TVDispInfoW.item.hItem := HTreeItem(Self);
      TVDispInfoW.item.lParam := FParam;
      TVDispInfoW.item.iSelectedImage := I_IMAGECALLBACK;
      TreeView.SendNotify(TVN_GETDISPINFOW, @TVDispInfoW);
      Result := TVDispInfoW.item.iSelectedImage;
      if Result = I_IMAGECALLBACK then
        if Expanded then Result := ExpandedImageIndex
                    else Result := ImageIndex;
    end
  else
    Result := FSelectedImageIndex;
end;

type
  TTVDispInfoExW = record
    hdr: TNMHDR;
    item: TTVItemExW;
  end;

function TTreeViewItem.GetExpandedImageIndex: Integer;
var
  TVDispInfoW: TTVDispInfoExW;
begin
  if FExpandedImageIndex = I_IMAGECALLBACK then
    begin
      TVDispInfoW.item.mask := TVIF_HANDLE or TVIF_PARAM or TVIF_EXPANDEDIMAGE;
      TVDispInfoW.item.hItem := HTreeItem(Self);
      TVDispInfoW.item.lParam := FParam;
      TVDispInfoW.item.iExpandedImage := I_IMAGECALLBACK;
      TreeView.SendNotify(TVN_GETDISPINFOW, @TVDispInfoW);
      Result := TVDispInfoW.item.iExpandedImage;
      if Result = I_IMAGECALLBACK then
        Result := ImageIndex;
    end
  else
    Result := FExpandedImageIndex;
end;

function TTreeViewItem.GetRight: Integer;
begin
  Result := FLeft + FWidth;
end;

function TTreeViewItem.GetBottom: Integer;
begin
  Result := FTop + FHeight;
end;

function TTreeViewItem.GetBoundsRect: TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Width := Width;
  Result.Height := Height;
end;

function TTreeViewItem.GetBoundsRectEx: TRect;
begin
  Result := BoundsRect;
  Inc(Result.Right, TreeView.HorzSpace);
  Inc(Result.Bottom, TreeView.VertSpace);
end;

function TTreeViewItem.GetStateIconRect: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := TreeView.StateImageListIconSize.cx;
  Result.Bottom := TreeView.StateImageListIconSize.cy;
  OffsetRect(Result, Left + FTreeView.HorzBorder + 1, Top + (FHeight - Result.Bottom) div 2);
end;

function TTreeViewItem.GetIconRect: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := TreeView.ImageListIconSize.cx;
  Result.Bottom := TreeView.ImageListIconSize.cy;
  OffsetRect(Result, Left + FTreeView.HorzBorder + 1, Top + (FHeight - Result.Bottom) div 2);
  if HasStateIcon then
    OffsetRect(Result, TreeView.StateImageListIconSize.cx + FTreeView.HorzBorder, 0);
end;

function TTreeViewItem.GetTextRect: TRect;
begin
  Result.Left := Left + FTreeView.HorzBorder + 1;
  Result.Top := Top + (Height - FTextHeight) div 2;
  Result.Right := Result.Left + FTextWidth;
  Result.Bottom := Result.Top + FTextHeight;
  if HasStateIcon then
    OffsetRect(Result, TreeView.StateImageListIconSize.cx + FTreeView.HorzBorder, 0);
  if HasIcon then
    OffsetRect(Result, TreeView.ImageListIconSize.cx + FTreeView.HorzBorder, 0);
end;

function TTreeViewItem.GetButtonRect: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  with TreeView.ButtonSize do
    begin
      Result.Right := cx;
      Result.Bottom := cy;
    end;
  OffsetRect(Result, Right - Result.Right - FTreeView.HorzBorder, Top + (Bottom - Top - Result.Bottom) div 2);
end;

function TTreeViewItem.GetItems: TTreeViewItems;
begin
  if not Assigned(FItems) then
    FItems := TTreeViewItems.Create(TreeView, Self, FLevel + 1);
  Result := FItems;
end;

function TTreeViewItem.GetCount: Integer;
begin
  if Assigned(FItems) then Result := FItems.Count
                      else Result := 0;
end;

function TTreeViewItem.GetItem(AIndex: Integer): TTreeViewItem;
begin
  Result := FItems.Items[AIndex];
end;

//**************************************************************************************************
// TTreeViewItems
//**************************************************************************************************

constructor TTreeViewItems.Create(ATreeView: TTreeView; AOwner: TTreeViewItem; ALevel: Integer);
begin
  inherited Create;
  FTreeView := ATreeView;
  FParent := AOwner;
  FLevel := ALevel;
end;

destructor TTreeViewItems.Destroy;
begin
  DeleteAll;
  SetLength(Items, 0);
  inherited Destroy;
end;

function TTreeViewItems.InsertItemW(AInsertAfter: TTreeViewItem; AItem: PTVItemExW): TTreeViewItem;
var
  Pos: Integer;
  PosFound: Boolean;
  ItemIndex: Integer;
  Delta: Integer;
  CopyCount: Integer;
  Source, Dest: Pointer;
  ItemSize: Integer;
begin
  Result := nil;
  Pos := 0; // Make compiler happy
  case THandle(AInsertAfter) of
    THandle(TVI_FIRST):
      Pos := 0;
    THandle(TVI_LAST):
      Pos := Count;
    THandle(TVI_SORT):
      Pos := Count;
    THandle(TVI_ROOT):
      Exit;
  else
    PosFound := False;
    for ItemIndex := 0 to Count - 1 do
      if Items[ItemIndex] = AInsertAfter then
        begin
          Pos := ItemIndex;
          PosFound := True;
          Break;
        end;
    if not PosFound then
      Exit;
  end;

  if Count = Length(Items) then
    begin
      if Length(Items) > 64 then
        Delta := Length(Items) div 4
      else
        if Length(Items) > 8 then
          Delta := 16
        else
          Delta := 4;
      SetLength(Items, Count + Delta);
    end;

  CopyCount := Count - Pos;
  if CopyCount > 0 then
    begin
      Source := @Items[Pos];
      Dest := @Items[Pos + 1];
      ItemSize := THandle(Dest) - THandle(Source);
      CopyMemory(Dest, Source, CopyCount * ItemSize);
    end;

  Inc(Count);
  Result := TTreeViewItem.Create(TreeView, Self, Level);
  Items[Pos] := Result;
  for ItemIndex := Pos to Count - 1 do
    Items[ItemIndex].Index_ := ItemIndex;
  Inc(TreeView.FTotalCount);

  if Assigned(Parent) and (Count = 1) and TreeView.HasButtons then
    Parent.NeedUpdateSize;

  if AItem.mask and TVIF_TEXT <> 0 then
    begin
      if IsFlagPtr(AItem.pszText) then
    	  Result.FTextCallback := True
    	else
        Result.FText := AItem.pszText;
    end;

  if AItem.mask and TVIF_IMAGE <> 0 then
    Result.FImageIndex := AItem.iImage;
  if AItem.mask and TVIF_SELECTEDIMAGE <> 0 then
    Result.FSelectedImageIndex := AItem.iSelectedImage;
  if AItem.mask and TVIF_EXPANDEDIMAGE <> 0 then
    Result.FExpandedImageIndex := AItem.iExpandedImage;
  if AItem.mask and TVIF_PARAM <> 0 then
    Result.FParam := AItem.lParam;
  if AItem.mask and TVIF_STATE <> 0 then
    Result.FState := AItem.state and AItem.stateMask;
  if AItem.mask and TVIF_STATEEX <> 0 then
    Result.FStateEx := AItem.uStateEx;
  if AItem.mask and TVIF_INTEGRAL <> 0 then
    Result.FIntegral := AItem.iIntegral;
  if AItem.mask and TVIF_CHILDREN <> 0 then
    Result.FChildren := AItem.cChildren;

  TreeView.Update;
end;

function TTreeViewItems.InsertItemA(AInsertAfter: TTreeViewItem; AItem: PTVItemExA): TTreeViewItem;
var
  SaveText: PAnsiChar;
  SaveLen: Integer;
  NewText: UnicodeString;
begin
  if (AItem.mask and TVIF_TEXT = 0) or IsFlagPtr(AItem.pszText) then
    Result := InsertItemW(AInsertAfter, PTVItemExW(AItem))
  else
    begin
      SaveText := AItem.pszText;
      SaveLen := AItem.cchTextMax;
      NewText := ProduceWFromA(AItem.pszText);
      AItem.pszText := PAnsiChar(PWideChar(NewText));
      Result := InsertItemW(AInsertAfter, PTVItemExW(AItem));
      AItem.pszText := SaveText;
      AItem.cchTextMax := SaveLen;
    end;
end;

function TTreeViewItems.GetNextItem(AItem: TTreeViewItem; ADirection: DWORD): TTreeViewItem;
begin
  Result := nil;
  case ADirection of
    //TVGN_ROOT: Processed in TreeView
    TVGN_NEXT:
      if AItem.Index_ < Count - 1 then
        Result := Items[AItem.Index_ + 1];
    TVGN_PREVIOUS:
      if AItem.Index_ > 0 then
        Result := Items[AItem.Index_ - 1];
    TVGN_PARENT:
      Result := Parent;
    TVGN_CHILD:
      if AItem.Count > 0 then
        Result := AItem.Items[0];
    //TVGN_FIRSTVISIBLE:
    //TVGN_NEXTVISIBLE:
    //TVGN_PREVIOUSVISIBLE:
    //TVGN_DROPHILITE:
    //TVGN_CARET: Processed in TreeView
    //TVGN_LASTVISIBLE:
    //TVGN_NEXTSELECTED:
  else
    Result := nil;
  end;
end;

procedure TTreeViewItems.DeleteItem(AItem: TTreeViewItem);
var
  ItemIndex: Integer;
  NMTreeView: TNMTreeView;
  Position: Integer;
  CopyCount: Integer;
  Source, Dest: Pointer;
  ItemSize: Integer;
  NewSelectItem: TTreeViewItem;
begin
  for ItemIndex := AItem.Count - 1 downto 0 do
    AItem.Items_.DeleteItem(AItem.Items[ItemIndex]);

  NMTreeView.itemOld.mask := TVIF_HANDLE or TVIF_PARAM;
  NMTreeView.itemOld.hItem := HTreeItem(AItem);
  NMTreeView.itemOld.lParam := AItem.FParam;
  TreeView.SendNotify(TVN_DELETEITEMW, @NMTreeView);

  if TreeView.SelectedItem = AItem then
    begin
      if AItem.Index_ < Count - 1 then
        NewSelectItem := Items[AItem.Index_ + 1]
      else
        if AItem.Index_ > 0 then
          NewSelectItem := Items[AItem.Index_ - 1]
        else
          NewSelectItem := Parent;
      TreeView.SelectItem(NewSelectItem, True, 0);
    end;

  if TreeView.SelectedItem = AItem then TreeView.FSelectedItem := nil;
  if TreeView.MouseOverItem = AItem then TreeView.MouseOverItem := nil;
  if TreeView.ExpandItem = AItem then TreeView.ExpandItem := nil;
  if TreeView.ScrollItem = AItem then TreeView.ScrollItem := nil;
  if TreeView.InsertMaskItem = AItem then TreeView.InsertMaskItem := nil;

  Position := AItem.Index_;
  CopyCount := Count - Position - 1;
  if CopyCount > 0 then
    begin
      Source := @Items[Position + 1];
      Dest := @Items[Position];
      ItemSize := THandle(Source) - THandle(Dest);
      CopyMemory(Dest, Source, CopyCount * ItemSize);
    end;
  Dec(Count);
  for ItemIndex := Position to Count - 1 do
    Items[ItemIndex].Index_ := ItemIndex;
  Dec(TreeView.FTotalCount);

  AItem.Free;
  if Assigned(Parent) and (Count = 0) and TreeView.HasButtons then
    Parent.NeedUpdateSize;
  TreeView.Update;
end;

procedure TTreeViewItems.DeleteAll;
var
  ItemIndex: Integer;
begin
  for ItemIndex := Count - 1 downto 0 do
    DeleteItem(Items[ItemIndex]);
end;

function TTreeViewItems.ItemAtPos(const APoint: TPoint): TTreeViewItem;
var
  ItemIndex: Integer;
begin
  for ItemIndex := 0 to Count - 1 do
    begin
      Result := Items[ItemIndex];
      if PtInRect(Result.BoundsRect, APoint) then Exit;
      if Result.Expanded and (Result.Count > 0) then
        begin
          Result := Result.Items_.ItemAtPos(APoint);
          if Assigned(Result) then Exit;
        end;
    end;
  Result := nil;
end;

//**************************************************************************************************
// TTreeView
//**************************************************************************************************

const
  IDT_SCROLLWAIT = 43;

constructor TTreeView.Create;
begin
  inherited Create;
  FSysColor := True;
  FSysTextColor := True;
  FSysLineColor := True;
  FSysInsertMaskColor := True;
  UpdateColors;
  FVertBorder := 3;
  FHorzBorder := 3;
  FVertSpace := 10;
  FHorzSpace := 30;
  InitStyles2(TVS_EX_AUTOCENTER);
end;

destructor TTreeView.Destroy;
begin
  FDestroying := True;
  if Assigned(FItems) then
    FItems.Free;
  if Assigned(FTempTextBuffer) then
    FreeMem(FTempTextBuffer);
  inherited Destroy;
end;

{$IFDEF NATIVE_BORDERS}
procedure TTreeView.CaclClientRect(ARect, AClientRect: PRect);
begin
  GetThemeBackgroundContentRect(Theme, 0, TVP_TREEITEM, TREIS_NORMAL, ARect^, AClientRect);
  if IsHorzScrollBarVisible then
    Dec(AClientRect.Bottom, GetSystemMetricsForDpi_(SM_CYHSCROLL, Dpi, True));
  if IsVertScrollBarVisible then
    Dec(AClientRect.Right, GetSystemMetricsForDpi_(SM_CYHSCROLL, Dpi, True));
end;

procedure TTreeView.PaintClientRect(ARgn: HRGN);
var
  RC,
  R2,
  RW : TRect;
  ContentRect: TRect;
  DC : HDC;
begin
  DC := GetDCEx(FHandle, ARgn, DCX_WINDOW or DCX_INTERSECTRGN);
  if DC = 0 then
    DC := GetWindowDC(FHandle);
  Windows.GetClientRect(FHandle, RC);
  GetWindowRect(FHandle, RW);
  MapWindowPoints(0, FHandle, RW, 2);
  OffsetRect(RC, -RW.Left, -RW.Top);
  ExcludeClipRect(DC, RC.Left, RC.Top, RC.Right, RC.Bottom);
  OffsetRect(RW, -RW.Left, -RW.Top);
  R2 := RW;

  {if IsThemeBackgroundPartiallyTransparent(TabTheme, DC, TABP_PANE, 0) then
  begin
      DrawParentThemeBackground(Handle, DC, RW);
  end;}

  GetThemeBackgroundContentRect(Theme, DC, TVP_TREEITEM, TREIS_NORMAL, RW, @ContentRect);
  ExcludeClipRect(DC, ContentRect.Left, ContentRect.Top, ContentRect.Right, ContentRect.Bottom);
  DrawThemeBackground(Theme, DC, TVP_TREEITEM, TREIS_NORMAL, RW, nil);
  ReleaseDC(FHandle, DC);
end;
{$ENDIF}

function TTreeView.IsScrollBarVisible(ABar: DWORD): Boolean;
var
  ScrollBarInfo: TScrollBarInfo;
begin
  ScrollBarInfo.cbSize := SizeOf(ScrollBarInfo);
  Result := GetScrollBarInfo(FHandle, ABar, ScrollBarInfo);
  if Result then
    Result := ScrollBarInfo.rgstate[0] and STATE_SYSTEM_INVISIBLE = 0;
end;

function TTreeView.IsHorzScrollBarVisible: Boolean;
begin
  Result := IsScrollBarVisible(OBJID_HSCROLL);
end;

function TTreeView.IsVertScrollBarVisible: Boolean;
begin
  Result := IsScrollBarVisible(OBJID_VSCROLL);
end;

procedure TTreeView.UpdateScrollBars;
var
  ClientRect: TRect;
  ClientWidth, ClientHeight: integer;
  ScrollInfo: TScrollInfo;
  XPos, YPos: Double;
  NeedVertScrollBar, NeedHorzScrollBar: Boolean;
begin
  if FDestroying then Exit;
  if FUpdateScrollBars then Exit;

  FUpdateScrollBars := True;
  try
    if Assigned(ExpandItem) then
      OffsetItemRect(ExpandItemRect);

    GetClientRect(FHandle, ClientRect);
    ClientWidth := ClientRect.Right - ClientRect.Left;
    ClientHeight := ClientRect.Bottom - ClientRect.Top;

    XPos := 0;
    YPos := 0;

    if IsVertScrollBarVisible then
      begin
        Inc(ClientWidth, FCXVScroll);
        ScrollInfo.cbSize := SizeOf(ScrollInfo);
        ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
        GetScrollInfo(FHandle, SB_VERT, ScrollInfo);
        with ScrollInfo do
          if nMax > nMin then
            YPos := (nPos + nPage / 2) / (nMax - nMin);
      end;
    if IsHorzScrollBarVisible then
      begin
        Inc(ClientHeight, FCYHScroll);
        ScrollInfo.cbSize := SizeOf(ScrollInfo);
        ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
        GetScrollInfo(FHandle, SB_HORZ, ScrollInfo);
        with ScrollInfo do
          if nMax > nMin then
            XPos := (nPos + nPage / 2) / (nMax - nMin);
      end;

    if ClientWidth = 0 then exit;
    if ClientHeight = 0 then exit;

    NeedVertScrollBar := FOptimalHeight > ClientHeight;
    if NeedVertScrollBar then
      Dec(ClientWidth, FCXVScroll);
    NeedHorzScrollBar := FOptimalWidth > ClientWidth;
    if NeedHorzScrollBar then
      Dec(ClientHeight, FCYHScroll);
    if not NeedVertScrollBar then
      begin
        NeedVertScrollBar := FOptimalHeight > ClientHeight;
        if NeedVertScrollBar then
          Dec(ClientWidth, FCXVScroll);
      end;

    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
    ScrollInfo.nMin := 0;

    if NeedVertScrollBar then
      begin
        ScrollInfo.nMax := FOptimalHeight;
        ScrollInfo.nPage := ClientHeight;
        if Assigned(ExpandItem) then
          begin
            ScrollInfo.nPos := ExpandItem.Top - ExpandItemRect.Top;
            ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
            ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          end
        else
          ScrollInfo.nPos := Round(YPos * ScrollInfo.nMax - Integer(ScrollInfo.nPage) / 2);
      end
    else
      ScrollInfo.nMax := 0;
    SetScrollInfo(FHandle, SB_VERT, ScrollInfo, True);

    if NeedHorzScrollBar then
      begin
        ScrollInfo.nMax := FOptimalWidth;
        ScrollInfo.nPage := ClientWidth;
        if Assigned(ExpandItem) then
          begin
            ScrollInfo.nPos := ExpandItem.Left - ExpandItemRect.Left;
            ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
            ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          end
        else
          ScrollInfo.nPos := Round(XPos * ScrollInfo.nMax - Integer(ScrollInfo.nPage) / 2);
      end
    else
      ScrollInfo.nMax := 0;
    SetScrollInfo(FHandle, SB_HORZ, ScrollInfo, True);
    ExpandItem := nil;
  finally
    FUpdateScrollBars := False;
  end;
end;

procedure TTreeView.ScrollMessage(AReason: WPARAM; ABar: DWORD);
const
  LineSize = 10;
var
  ScrollInfo: TScrollInfo;
  NewPos: Integer;
  X, Y: Integer;
begin
  if FDestroying then Exit;

  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
  if not GetScrollInfo(FHandle, ABar, ScrollInfo) then Exit;

  NewPos := ScrollInfo.nPos;
  case LoWord(AReason) of
    TB_LINEUP:
      Dec(NewPos, LineSize);
    TB_LINEDOWN:
      Inc(NewPos, LineSize);
    TB_PAGEUP:
      Dec(NewPos, ScrollInfo.nPage);
    TB_PAGEDOWN:
      Inc(NewPos, ScrollInfo.nPage);
    TB_THUMBPOSITION,
    TB_THUMBTRACK:
      NewPos := HiWord(AReason);
    TB_TOP:
      NewPos := 0;
    TB_BOTTOM:
      NewPos := ScrollInfo.nMax - Integer(ScrollInfo.nPage);
  else
    Exit;
    //TB_ENDTRACK             = 8;
  end;

  NewPos := Max(NewPos, 0);
  NewPos := Min(NewPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
  if NewPos <> ScrollInfo.nPos then
    begin
      SetScrollPos(FHandle, ABar, NewPos, True);
      if ABar = SB_HORZ then
        begin
          X := ScrollInfo.nPos - NewPos;
          Y := 0;
        end
      else
        begin
          X := 0;
          Y := ScrollInfo.nPos - NewPos;
        end;
      ScrollWindowEx(FHandle, X, Y, nil, nil, 0, nil, SW_INVALIDATE);
    end;
end;

procedure TTreeView.CalcBaseOffsets(var AXOffset, AYOffset: Integer);
var
  ClientRect: TRect;
begin
  GetClientRect(FHandle, ClientRect);

  if IsHorzScrollBarVisible then
    AXOffset := -GetScrollPos(FHandle, SB_HORZ)
  else
    if AutoCenter then
      AXOffset := (ClientRect.Right - ClientRect.Left - FOptimalWidth) div 2
    else
      AXOffset := 0;

  if IsVertScrollBarVisible then
    AYOffset := -GetScrollPos(FHandle, SB_VERT)
  else
    if AutoCenter then
      AYOffset := (ClientRect.Bottom - ClientRect.Top - FOptimalHeight) div 2
    else
      AYOffset := 0;
end;

procedure TTreeView.OffsetMousePoint(var APoint: TPoint);
var
  XOffset, YOffset: Integer;
begin
  CalcBaseOffsets(XOffset, YOffset);
  Dec(APoint.X, XOffset);
  Dec(APoint.Y, YOffset);
end;

procedure TTreeView.OffsetItemRect(var ARect: TRect);
var
  XOffset, YOffset: Integer;
begin
  CalcBaseOffsets(XOffset, YOffset);
  OffsetRect(ARect, XOffset, YOffset);
end;

function TTreeView.SendDrawNotify(ADC: HDC; AStage: UINT; var ANMTVCustomDraw: TNMTVCustomDraw): UINT;
var
  Point: TPoint;
begin
  SetWindowOrgEx(ADC, FSavePoint.X, FSavePoint.Y, @Point);
  ANMTVCustomDraw.nmcd.dwDrawStage := AStage;
  ANMTVCustomDraw.nmcd.hdc := ADC;
  Result := SendNotify(NM_CUSTOMDRAW, @ANMTVCustomDraw);
  SetWindowOrgEx(ADC, Point.X, Point.Y, nil);
end;

procedure TTreeView.PaintRootConnector(ADC: HDC; ASource, ADest: TTreeViewItem);
var
  Points: packed array[0..3] of TPoint;
  Pen: HPEN;
  SavePen: HPEN;
begin
  Points[0].X := HorzSpace div 2;
  Points[0].Y := ASource.Top + ASource.Height div 2;
  Points[1].X := Points[0].X - HorzSpace div 2;
  Points[1].Y := Points[0].Y;
  Points[3].X := ADest.Left;
  Points[3].Y := ADest.Top + ADest.Height div 2;
  Points[2].X := Points[3].X - HorzSpace div 2;
  Points[2].Y := Points[3].Y;

  Pen := CreatePen(PS_SOLID, 1, LineColor);
  SavePen := SelectObject(ADC, Pen);
  PolyBezier(ADC, Points, 4);
  SelectObject(ADC, SavePen);
  DeleteObject(Pen);
end;

procedure TTreeView.PaintRootConnectors(ADC: HDC; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
var
  ConnectorRect: TRect;
  TempRgn: HRGN;
  ItemIndex: Integer;
begin
  if not LinesAsRoot or (Count = 0) then Exit;

  ConnectorRect.Left := 0;
  ConnectorRect.Top := Items[0].Top;
  ConnectorRect.Right := HorzSpace div 2;
  ConnectorRect.Bottom := Items[Count - 1].Bottom;
  if RectInRegion(AUpdateRgn, ConnectorRect) then
    begin
      if AEraseBackground then
        begin
          FillRectWithColor(ADC, ConnectorRect, Color);
          TempRgn := CreateRectRgnIndirect(ConnectorRect);
          CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
          DeleteObject(TempRgn);
        end;

      for ItemIndex := 0 to Count - 2 do
        begin
          ConnectorRect.Top := Items[ItemIndex].Top;
          ConnectorRect.Bottom := Items[ItemIndex + 1].Bottom;
          if RectInRegion(AUpdateRgn, ConnectorRect) then
            PaintRootConnector(ADC, Items[ItemIndex], Items[ItemIndex + 1]);
        end;
    end;
end;

procedure TTreeView.PaintInsertMask(ADC: HDC; AUpdateRgn: HRGN);
var
  R: TRect;
  Pen: HPEN;
  SavePen: HPEN;
  Index: Integer;
begin
  R := InsertMaskRect;
  Pen := CreatePen(PS_SOLID, 1, InsertMaskColor);
  SavePen := SelectObject(ADC, Pen);

  MoveToEx(ADC, R.Left, R.Top, nil);
  LineTo(ADC, R.Left, R.Bottom);
  MoveToEx(ADC, R.Left + 1, R.Top + 1, nil);
  LineTo(ADC, R.Left + 1, R.Bottom - 1);

  MoveToEx(ADC, R.Right - 1, R.Top, nil);
  LineTo(ADC, R.Right - 1, R.Bottom);
  MoveToEx(ADC, R.Right - 2, R.Top + 1, nil);
  LineTo(ADC, R.Right - 2, R.Bottom - 1);

  for Index := R.Top + 2 to R.Bottom - 3 do
    begin
      MoveToEx(ADC, R.Left + 2, Index, nil);
      LineTo(ADC, R.Right - 2, Index);
    end;

  SelectObject(ADC, SavePen);
end;

procedure TTreeView.PaintTo(ADC: HDC; var AUpdateRgn, ABackgroupRgn: HRGN);
var
  R: TRect;
  XOffset, YOffset: Integer;
  NMCustomDraw: TNMTVCustomDraw;
  ItemIndex: Integer;
begin
  //if FLockUpdate then Exit;
  SetWindowOrgEx(ADC, 0, 0, @FSavePoint);
  SetWindowOrgEx(ADC, FSavePoint.X, FSavePoint.Y, nil);
  CalcBaseOffsets(XOffset, YOffset);

  ZeroMemory(@NMCustomDraw, SizeOf(NMCustomDraw));
  FPaintRequest := SendDrawNotify(ADC, CDDS_PREPAINT, NMCustomDraw);
  if FPaintRequest and CDRF_SKIPDEFAULT = 0 then
    begin
      if FPaintRequest and CDRF_NOTIFYPOSTERASE <> 0 then
        begin
          DeleteObject(AUpdateRgn);
          DeleteObject(ABackgroupRgn);
          GetClientRect(FHandle, R);
          AUpdateRgn := CreateRectRgnIndirect(R);
          ABackgroupRgn := CreateRectRgnIndirect(R);
          FillRgnWithColor(ADC, ABackgroupRgn, Color);
          SendDrawNotify(ADC, CDDS_POSTERASE, NMCustomDraw);
        end;

      if FPaintRequest and CDRF_DOERASE = 0 then
        begin
          SetWindowOrgEx(ADC, FSavePoint.X - XOffset, FSavePoint.Y - YOffset, nil);
          OffsetRgn(AUpdateRgn, -XOffset, -YOffset);
          OffsetRgn(ABackgroupRgn, -XOffset, -YOffset);

          PaintRootConnectors(ADC, AUpdateRgn, ABackgroupRgn, FPaintRequest and CDRF_NOTIFYPOSTERASE = 0);
          for ItemIndex := 0 to Count - 1 do
            Items[ItemIndex].Paint(ADC, AUpdateRgn, ABackgroupRgn, XOffset, YOffset, FPaintRequest and CDRF_NOTIFYPOSTERASE = 0);

          SetWindowOrgEx(ADC, FSavePoint.X, FSavePoint.Y, nil);
          OffsetRgn(AUpdateRgn, XOffset, YOffset);
          OffsetRgn(ABackgroupRgn, XOffset, YOffset);
        end;

      if FPaintRequest and CDRF_NOTIFYPOSTERASE = 0 then
        FillRgnWithColor(ADC, ABackgroupRgn, Color);

      if FPaintRequest and CDRF_NOTIFYPOSTPAINT <> 0 then
        SendDrawNotify(ADC, CDDS_POSTPAINT, NMCustomDraw);
    end;

  if Assigned(InsertMaskItem) then
    begin
      SetWindowOrgEx(ADC, FSavePoint.X - XOffset, FSavePoint.Y - YOffset, nil);
      OffsetRgn(AUpdateRgn, -XOffset, -YOffset);
      PaintInsertMask(ADC, AUpdateRgn);
      SetWindowOrgEx(ADC, FSavePoint.X, FSavePoint.Y, nil);
      OffsetRgn(AUpdateRgn, XOffset, YOffset);
    end;
end;

procedure TTreeView.Paint;
var
  UpdateRgn: HRGN;
  BackgroupRgn: HRGN;
  DC: HDC;
  PaintStruct: TPaintStruct;
begin
  UpdateRgn := CreateRectRgn(0, 0, 0, 0);
  try
    if GetUpdateRgn(FHandle, UpdateRgn, False) <> NULLREGION then
      begin
        BackgroupRgn := CreateRectRgn(0, 0, 0, 0);
        CombineRgn(BackgroupRgn, UpdateRgn, 0, RGN_COPY);
        try
          DC := BeginPaint(FHandle, PaintStruct);
          if DC = 0 then Exit;
          try
            PaintTo(DC, UpdateRgn, BackgroupRgn);
          finally
            EndPaint(FHandle, PaintStruct);
          end;
        finally
          DeleteObject(BackgroupRgn);
        end;
      end;
  finally
    DeleteObject(UpdateRgn);
  end;
end;

procedure TTreeView.PaintClient(ADC: HDC);
var
  UpdateRect: TRect;
  UpdateRgn: HRGN;
  BackgroupRgn: HRGN;
begin
  GetClientRect(FHandle, UpdateRect);
  UpdateRgn := CreateRectRgnIndirect(UpdateRect);
  BackgroupRgn := CreateRectRgnIndirect(UpdateRect);
  try
    PaintTo(ADC, UpdateRgn, BackgroupRgn);
  finally
    DeleteObject(UpdateRgn);
    DeleteObject(BackgroupRgn);
  end;
end;

procedure TTreeView.Invalidate;
begin
  if FDestroying then Exit;
  InvalidateRect(FHandle, nil, False);
end;

procedure TTreeView.InvalidateItem(AItem: TTreeViewItem);
var
  ItemRect: TRect;
begin
  if FDestroying then Exit;
  if not AItem.IsVisible then Exit;
  ItemRect := AItem.BoundsRect;
  OffsetItemRect(ItemRect);
  InvalidateRect(FHandle, ItemRect, False);
end;

procedure TTreeView.InvalidateInsertMask;
var
  ItemRect: TRect;
begin
  if FDestroying then Exit;
  if Assigned(InsertMaskItem) then
    begin
      ItemRect := InsertMaskRect;
      OffsetItemRect(ItemRect);
      InvalidateRect(FHandle, ItemRect, False);
    end;
end;

procedure TTreeView.HitTest(TVHitTestInfo: PTVHitTestInfo);
var
  ClientRect: TRect;
  Item: TTreeViewItem;
  P: TPoint;
begin
  GetClientRect(FHandle, ClientRect);
  TVHitTestInfo.flags := 0;
  TVHitTestInfo.hItem := nil;
  if TVHitTestInfo.pt.X < ClientRect.Left then
    TVHitTestInfo.flags := TVHitTestInfo.flags or TVHT_TOLEFT
  else
    if TVHitTestInfo.pt.X >= ClientRect.Right then
      TVHitTestInfo.flags := TVHitTestInfo.flags or TVHT_TORIGHT;
  if TVHitTestInfo.pt.Y < ClientRect.Top then
    TVHitTestInfo.flags := TVHitTestInfo.flags or TVHT_ABOVE
  else
    if TVHitTestInfo.pt.Y >= ClientRect.Bottom then
      TVHitTestInfo.flags := TVHitTestInfo.flags or TVHT_BELOW;
  if TVHitTestInfo.flags <> 0 then Exit;
  P := TVHitTestInfo.pt;
  OffsetMousePoint(P);
  Item := FItems.ItemAtPos(P);
  if not Assigned(Item) then
    TVHitTestInfo.flags := TVHT_NOWHERE
  else
    begin
      TVHitTestInfo.hItem := HTreeItem(Item);
      TVHitTestInfo.flags := Item.HitTest(P);
    end;
end;

procedure TTreeView.MakeVisible(AItem: TTreeViewItem);
var
  ItemRect: TRect;
  ClientRect: TRect;
  XOffset, YOffset: Integer;
  XPos, YPos: Integer;
begin
  if not AItem.ExpandParents(TVC_UNKNOWN) then Exit;

  ItemRect := AItem.BoundsRect;
  CalcBaseOffsets(XOffset, YOffset);
  OffsetRect(ItemRect, XOffset, YOffset);
  GetClientRect(FHandle, ClientRect);
  XOffset := 0;
  YOffset := 0;
  if ItemRect.Right > ClientRect.Right then
    Inc(XOffset, ItemRect.Right - ClientRect.Right);
  if ItemRect.Bottom > ClientRect.Bottom then
    Inc(YOffset, ItemRect.Bottom - ClientRect.Bottom);
  OffsetRect(ItemRect, -XOffset, -YOffset);

  if ItemRect.Left < ClientRect.Left then
    Inc(XOffset, ItemRect.Left - ClientRect.Left);
  if ItemRect.Top < ClientRect.Top then
    Inc(YOffset, ItemRect.Top - ClientRect.Top);

  if (XOffset <> 0) or (YOffset <> 0) then
    begin
      if XOffset <> 0 then
        begin
          XPos := GetScrollPos(FHandle, SB_HORZ);
          Inc(XPos, XOffset);
          SetScrollPos(FHandle, SB_HORZ, XPos, True);
        end;
      if YOffset <> 0 then
        begin
          YPos := GetScrollPos(FHandle, SB_VERT);
          Inc(YPos, YOffset);
          SetScrollPos(FHandle, SB_VERT, YPos, True);
        end;
      ScrollWindowEx(FHandle, -XOffset, -YOffset, nil, nil, 0, nil, SW_INVALIDATE);
    end;
end;

function TTreeView.SelectItem(AItem: TTreeViewItem; ANotify: Boolean; AAction: UINT): Boolean;
var
  OldSelected: TTreeViewItem;
begin
  if FSelectedItem = AItem then
    begin
      Result := True;
      Exit;
    end;

  Result := False;
  if Assigned(AItem) and not AItem.ExpandParents(AAction) then Exit;

  if ANotify and SendSelectChange(TVN_SELCHANGINGW, FSelectedItem, AItem, AAction) then Exit;

  if Assigned(FSelectedItem) then
    begin
      FSelectedItem.FState := FSelectedItem.FState and not TVIS_SELECTED;
      InvalidateItem(FSelectedItem);
    end;

  OldSelected := FSelectedItem;
  FSelectedItem := AItem;

  if Assigned(AItem) then
    begin
      AItem.FState := AItem.FState or TVIS_SELECTED;
      {if AAction = TVC_BYMOUSE then
        begin
          ScrollItem := AItem;
          SetTimer(FHandle, IDT_SCROLLWAIT, GetDoubleClickTime, nil);
        end
      else}
        MakeVisible(AItem);
      InvalidateItem(AItem);
    end;

  if ANotify then
    SendSelectChange(TVN_SELCHANGED, OldSelected, AItem, AAction);

  Result := True;
end;

procedure TTreeView.UpdateSelected(AAction: UINT);
begin
  if not Assigned(SelectedItem) then
    if Assigned(FItems) and (FItems.Count > 0) then
      SelectItem(FItems.Items[0], True, AAction);
end;

procedure TTreeView.SetInsertMaskItemAfter(AInsertMaskItem: TTreeViewItem; AAfter: Boolean);
begin
  if (FInsertMaskItem = AInsertMaskItem) and (FInsertMaskItemAfter = AAfter) then Exit;
  InvalidateInsertMask;
  FInsertMaskItem := AInsertMaskItem;
  FInsertMaskItemAfter := AAfter;
  InvalidateInsertMask;
end;

procedure TTreeView.SetInsertMaskItem(AInsertMaskItem: TTreeViewItem);
begin
  SetInsertMaskItemAfter(AInsertMaskItem, InsertMaskItemAfter);
end;

function TTreeView.GetInsertMaskRect: TRect;
const
  Offset = 2;
  Height = 6;
begin
  if Assigned(InsertMaskItem) then
    begin
      Result := InsertMaskItem.BoundsRect;
      if InsertMaskItemAfter then
        Result.Top := Result.Bottom + Offset - Height
      else
        Result.Top := Result.Top - Offset;
      Result.Bottom := Result.Top + Height;
    end
  else
    begin
      Result.Left := 0;
      Result.Top := 0;
      Result.Right := 0;
      Result.Bottom := 0;
    end;
end;

procedure TTreeView.KeyDown(AKeyCode: DWORD; AFlags: DWORD);
var
  TVKeyDown: TTVKeyDown;
begin
  TVKeyDown.wVKey := AKeyCode;
  TVKeyDown.flags := 0;
  SendNotify(TVN_KEYDOWN, @TVKeyDown);

  if GetKeyState(VK_CONTROL) < 0 then
    begin
      case AKeyCode of
        VK_UP:
          ScrollMessage(SB_LINEUP, SB_VERT);
        VK_DOWN:
          ScrollMessage(SB_LINEDOWN, SB_VERT);
        VK_PRIOR:
          ScrollMessage(SB_PAGEUP, SB_VERT);
        VK_NEXT:
          ScrollMessage(SB_PAGEDOWN, SB_VERT);
        VK_HOME:
          ScrollMessage(SB_TOP, SB_VERT);
        VK_END:
          ScrollMessage(SB_BOTTOM, SB_VERT);
        VK_LEFT:
          ScrollMessage(SB_LINEUP, SB_HORZ);
        VK_RIGHT:
          ScrollMessage(SB_LINEDOWN, SB_HORZ);
      end
    end
  else
    begin
      if Count > 0 then
        begin
          case AKeyCode of
            VK_UP,
            VK_DOWN,
            VK_LEFT,
            VK_RIGHT,
            VK_PRIOR,
            VK_NEXT:
              if not Assigned(SelectedItem) then
                begin
                  UpdateSelected(TVC_BYKEYBOARD);
                  Exit;
                end;
          end;

          case AKeyCode of
            VK_UP, VK_PRIOR:
              begin
                if SelectedItem.Index_ > 0 then
                  SelectItem(SelectedItem.ParentItems.Items[SelectedItem.Index_ - 1], True, TVC_BYKEYBOARD)
                else
                  if Assigned(SelectedItem.ParentItems.Parent) then
                    SelectItem(SelectedItem.ParentItems.Parent, True, TVC_BYKEYBOARD)
              end;
            VK_DOWN, VK_NEXT:
              begin
                if SelectedItem.Index_ < SelectedItem.ParentItems.Count - 1 then
                  SelectItem(SelectedItem.ParentItems.Items[SelectedItem.Index_ + 1], True, TVC_BYKEYBOARD)
                else
                  if Assigned(SelectedItem.ParentItems.Parent) then
                    SelectItem(SelectedItem.ParentItems.Parent, True, TVC_BYKEYBOARD)
              end;
            VK_LEFT, VK_BACK:
              begin
                if Assigned(SelectedItem.ParentItems.Parent) then
                  SelectItem(SelectedItem.ParentItems.Parent, True, TVC_BYKEYBOARD)
              end;
            VK_RIGHT:
              begin
                if not SelectedItem.Expanded then
                  SelectedItem.Expand(TVE_EXPAND, TVC_BYKEYBOARD, True)
                else
                  if SelectedItem.Count > 0 then
                    SelectItem(SelectedItem.Items[0], True, TVC_BYKEYBOARD)
              end;
            VK_SUBTRACT:
              if Assigned(SelectedItem) and SelectedItem.Expanded then
                SelectedItem.Expand(TVE_COLLAPSE, TVC_BYKEYBOARD, True);
            VK_ADD:
              if Assigned(SelectedItem) and not SelectedItem.Expanded then
                SelectedItem.Expand(TVE_EXPAND, TVC_BYKEYBOARD, True);
            VK_MULTIPLY:
              if Assigned(SelectedItem) then
                SelectedItem.FullExpand(TVE_EXPAND, TVC_BYKEYBOARD, True);
            VK_HOME:
              SelectItem(Items[0], True, TVC_BYKEYBOARD);
            VK_END:
              SelectItem(Items[Count - 1], True, TVC_BYKEYBOARD);
          end;
        end;

      case AKeyCode of
        VK_RETURN:
          SendNotify(NM_RETURN, nil);
      end;
    end;
end;

procedure TTreeView.LButtonDown(APoint: TPoint);
var
  Item: TTreeViewItem;
  ItemPoint: TPoint;
begin
  SetFocus(FHandle);
  if Count = 0 then Exit;
  ItemPoint := APoint;
  OffsetMousePoint(ItemPoint);
  Item := FItems.ItemAtPos(ItemPoint);
  if Assigned(Item) then
    case Item.HitTest(ItemPoint) of
      TVHT_ONITEMBUTTON:
        Item.Expand(TVE_TOGGLE, TVC_BYMOUSE, True);
    else
      SelectItem(Item, True, TVC_BYMOUSE);
    end
  else
    if IsHorzScrollBarVisible or IsVertScrollBarVisible then
      begin
        FMoveMode := True;
        FMoveMouseStartPos := APoint;
        FMoveScrollStartPos.X := GetScrollPos(FHandle, SB_HORZ);
        FMoveScrollStartPos.Y := GetScrollPos(FHandle, SB_VERT);
        SetCapture(FHandle);
        if FMoveCursor = 0 then
          FMoveCursor := LoadCursor(0, IDC_SIZEALL);
        SetCursor(FMoveCursor);
      end;
end;

procedure TTreeView.LButtonUp(APoint: TPoint);
begin
  ReleaseCapture;
  FMoveMode := False;
end;

procedure TTreeView.MButtonDown(APoint: TPoint);
begin
  SetFocus(FHandle);
end;

procedure TTreeView.RButtonDown(APoint: TPoint);
begin
  SetFocus(FHandle);
end;

procedure TTreeView.MouseMove(APoint: TPoint);
var
  XOffset, YOffset: Integer;
  ScrollInfo: TScrollInfo;
begin
  if FMoveMode then
    begin
      XOffset := 0;
      YOffset := 0;

      if IsHorzScrollBarVisible then
        begin
          ScrollInfo.cbSize := SizeOf(ScrollInfo);
          ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
          GetScrollInfo(FHandle, SB_HORZ, ScrollInfo);
          XOffset := ScrollInfo.nPos;
          ScrollInfo.nPos := FMoveScrollStartPos.X + (FMoveMouseStartPos.X - APoint.X);
          ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
          ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          XOffset := ScrollInfo.nPos - XOffset;
          if XOffset <> 0 then
            SetScrollPos(FHandle, SB_HORZ, ScrollInfo.nPos, True);
        end;

      if IsVertScrollBarVisible then
        begin
          ScrollInfo.cbSize := SizeOf(ScrollInfo);
          ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
          GetScrollInfo(FHandle, SB_VERT, ScrollInfo);
          YOffset := ScrollInfo.nPos;
          ScrollInfo.nPos := FMoveScrollStartPos.Y + (FMoveMouseStartPos.Y - APoint.Y);
          ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
          ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          YOffset := ScrollInfo.nPos - YOffset;
          if YOffset <> 0 then
            SetScrollPos(FHandle, SB_VERT, ScrollInfo.nPos, True);
        end;

      if (XOffset <> 0) or (YOffset <> 0) then
        ScrollWindowEx(FHandle, -XOffset, -YOffset, nil, nil, 0, nil, SW_INVALIDATE);
    end;
end;

function TTreeView.SendNotify(AParentWnd, AWnd: HWND; ACode: Integer; ANMHdr: PNMHdr): LRESULT;
var
  NMHdr: TNMHdr;
  ID: Integer;
  Save1: PWideChar;
  Save2: Pointer;
  NewText1: AnsiString;
  NewText2: AnsiString;
  NMGetInfoTip: PNMTVGetInfoTipW;

  procedure ProcessTreeView(AOld, ANew: Boolean);
  var
    Item: PTVItemW;
  begin
    Item := @(PNMTreeViewW(ANMHdr)).itemOld;
    Save2 := Item.pszText;
    if AOld then
      begin
        if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) then
          begin
            NewText2 := ProduceAFromW(Item.pszText);
            Item.pszText := PWideChar(PAnsiChar(NewText2));
          end;
      end;
    Item := @PNMTreeViewW(ANMHdr).itemNew;
    Save1 := Item.pszText;
    if ANew then
      begin
        if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) then
          begin
            NewText1 := ProduceAFromW(Item.pszText);
            Item.pszText := PWideChar(PAnsiChar(NewText1));
          end;
      end;
  end;

  procedure RestoreTreeView;
  var
    Item: PTVItemW;
  begin
    Item := @(PNMTreeViewW(ANMHdr)).itemOld;
    Item.pszText := Save2;
    Item := @(PNMTreeViewW(ANMHdr)).itemNew;
    Item.pszText := Save1;
  end;

  procedure ProcessDispInfo;
  var
    Item: PTVItemW;
  begin
    Item := @PTVDispInfoW(ANMHdr).item;
    Save1 := Item.pszText;
    if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) then
      begin
        Save1 := Item.pszText;
        NewText1 := ProduceAFromW(Item.pszText);
        Item.pszText := PWideChar(PAnsiChar(NewText1));
      end;
  end;

  procedure RestoreDispInfo;
  var
    Item: PTVItemW;
  begin
    Item := @PTVDispInfoW(ANMHdr).item;
    Item.pszText := Save1;
  end;

var
  Item: PTVItemW;
begin
  if AParentWnd = 0 then
    begin
      Result := 0;
      Exit;
    end;

    //
    // If pci->hwnd is -1, then a WM_NOTIFY is being forwared
    // from one control to a parent.  EG:  Tooltips sent
    // a WM_NOTIFY to toolbar, and toolbar is forwarding it
    // to the real parent window.
    //

  if AWnd <> Windows.HWND(-1) then
    begin
      if AWnd <> 0 then ID := GetDlgCtrlID(AWnd)
                   else ID := 0;

      if not Assigned(ANMHdr) then
         ANMHdr := @NMHdr;

      ANMHdr.hwndFrom := AWnd;
      ANMHdr.idFrom := ID;
      ANMHdr.code := ACode;
    end
  else
    begin
      ID := ANMHdr.idFrom;
      ACode := ANMHdr.code;
    end;

  if not FUnicode then
    begin
      Save1 := nil;
      Save2 := nil;
      case ACode of
        TVN_SELCHANGINGW:
          begin
            ANMHdr.code := TVN_SELCHANGINGA;
            ProcessTreeView(True, True);
          end;
        TVN_SELCHANGEDW:
          begin
            ANMHdr.code := TVN_SELCHANGEDA;
            ProcessTreeView(True, True);
          end;
        TVN_DELETEITEMW:
          begin
            ANMHdr.code := TVN_DELETEITEMA;
            ProcessTreeView(True, False);
          end;
        TVN_ITEMEXPANDINGW:
          begin
            ANMHdr.code := TVN_ITEMEXPANDINGA;
            ProcessTreeView(True, True);
          end;
        TVN_ITEMEXPANDEDW:
          begin
            ANMHdr.code := TVN_ITEMEXPANDEDA;
            ProcessTreeView(True, True);
          end;
        TVN_BEGINDRAGW:
          begin
            ANMHdr.code := TVN_BEGINDRAGA;
            ProcessTreeView(False, True);
          end;
        TVN_BEGINRDRAGW:
          begin
            ANMHdr.code := TVN_BEGINRDRAGA;
            ProcessTreeView(False, True);
          end;
        {TVN_SINGLEEXPAND:
          begin
            pnmhdr.code := TVN_SINGLEEXPAND;
            ProcessTreeView(False, True);
          end;}
        TVN_SETDISPINFOW:
          begin
            ANMHdr.code := TVN_SETDISPINFOA;
            ProcessDispInfo;
          end;
        TVN_BEGINLABELEDITW:
          begin
            ANMHdr.code := TVN_BEGINLABELEDITA;
            ProcessDispInfo;
          end;
        TVN_ENDLABELEDITW:
          begin
            ANMHdr.code := TVN_ENDLABELEDITA;
            ProcessDispInfo;
          end;
        TVN_GETDISPINFOW:
          begin
            ANMHdr.code := TVN_GETDISPINFOA;
            Item := @PTVDispInfoW(ANMHdr).item;
            Save1 := Item.pszText;
            if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) and (Item.cchTextMax > 0)  then
              begin
                SetLength(NewText1, Item.cchTextMax);
                NewText1[1] := #0;
                Item.pszText := PWideChar(PAnsiChar(NewText1));
              end;
          end;
        TVN_GETINFOTIPW:
          begin
            ANMHdr.code := TVN_GETINFOTIPA;
            NMGetInfoTip := PNMTVGetInfoTipW(ANMHdr);
            Save1 := NMGetInfoTip.pszText;
            if NMGetInfoTip.cchTextMax > 0 then
              begin
                NewText1 := ProduceAFromW(NMGetInfoTip.pszText);
                NewText2 := NewText1;
                NMGetInfoTip.pszText := PWideChar(PAnsiChar(NewText1));
              end;
          end;
      end;

      Result := SendMessage(AParentWnd, WM_NOTIFY, ID, LPARAM(ANMHdr));

      case ANMHdr.code of
        TVN_SELCHANGINGA,
        TVN_SELCHANGEDA,
        TVN_DELETEITEMA,
        TVN_ITEMEXPANDINGA,
        TVN_ITEMEXPANDEDA,
        TVN_BEGINDRAGA,
        TVN_BEGINRDRAGA:
          RestoreTreeView;
        TVN_SETDISPINFOA,
        TVN_BEGINLABELEDITA,
        TVN_ENDLABELEDITA:
          RestoreDispInfo;
        TVN_GETDISPINFOA:
          begin
            Item := @PTVDispInfoW(ANMHdr).item;
            Item.pszText := Save1;
            if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) and (Item.cchTextMax > 0)  then
              begin
                //ConvertAToWN(pci->uiCodePage, pvThunk1, dwThunkSize, (LPSTR)pitem->pszText, -1);
              end;
          end;
        TVN_GETINFOTIPA:
          begin
            NMGetInfoTip := PNMTVGetInfoTipW(ANMHdr);
            Save1 := NMGetInfoTip.pszText;
            if NMGetInfoTip.cchTextMax > 0 then
              begin
                //Convert
              end;
          end;
      end
    end
  else
    Result := SendMessage(AParentWnd, WM_NOTIFY, ID, LPARAM(ANMHdr));
end;

function TTreeView.SendNotify(ACode: Integer; ANMHdr: PNMHdr): LRESULT;
begin
  Result := SendNotify(FParentHandle, FHandle, ACode, ANMHdr);
end;

function TTreeView.SendItemExpand(ACode: Integer; AItem: TTreeViewItem; AAction: UINT): Boolean;
var
  NMTreeView: TNMTreeViewW;
begin
  NMTreeView.action := AAction and TVE_ACTIONMASK;

  NMTreeView.itemNew.mask := TVIF_HANDLE or TVIF_STATE or TVIF_PARAM or TVIF_IMAGE or TVIF_SELECTEDIMAGE;
  NMTreeView.itemNew.hItem := HTreeItem(AItem);
  NMTreeView.itemNew.state := AItem.FState;
  NMTreeView.itemNew.lParam := AItem.FParam;
  NMTreeView.itemNew.iImage := AItem.ImageIndex;
  NMTreeView.itemNew.iSelectedImage := AItem.SelectedImageIndex;
  case AItem.FChildren of
    I_CHILDRENCALLBACK,
    1:
      begin
        NMTreeView.itemNew.cChildren := 1;
        NMTreeView.itemNew.mask := NMTreeView.itemNew.mask or TVIF_CHILDREN;
      end;
    0:
      begin
        NMTreeView.itemNew.cChildren := 0;
        NMTreeView.itemNew.mask := NMTreeView.itemNew.mask or TVIF_CHILDREN;
      end
  end;

  NMTreeView.itemOld.mask := 0;

  Result := SendNotify(ACode, @NMTreeView) <> 0;
end;

function TTreeView.SendSelectChange(ACode: Integer; AOldItem, ANewItem: TTreeViewItem; AAction: UINT): Boolean;
var
  NMTreeView: TNMTreeViewW;
begin
  NMTreeView.action := AAction and TVE_ACTIONMASK;

  NMTreeView.itemNew.hItem := HTreeItem(ANewItem);
  if Assigned(ANewItem) then
    begin
      NMTreeView.itemNew.state := ANewItem.FState;
      NMTreeView.itemNew.lParam := ANewItem.FParam;
    end
  else
    begin
      NMTreeView.itemNew.state := 0;
      NMTreeView.itemNew.lParam := 0;
    end;
  NMTreeView.itemNew.mask := TVIF_HANDLE or TVIF_STATE or TVIF_PARAM;

  NMTreeView.itemOld.hItem := HTreeItem(AOldItem);
  if Assigned(AOldItem) then
    begin
      NMTreeView.itemOld.state := AOldItem.FState;
      NMTreeView.itemOld.lParam := AOldItem.FParam;
    end
  else
    begin
      NMTreeView.itemOld.state := 0;
      NMTreeView.itemOld.lParam := 0;
    end;
  NMTreeView.itemOld.mask := TVIF_HANDLE or TVIF_STATE or TVIF_PARAM;

  Result := SendNotify(ACode, @NMTreeView) <> 0;
end;

procedure MoveDownChilds(AParent: TTreeViewItem; ADelta: Integer);
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  for ItemIndex := 0 to AParent.Count - 1 do
    begin
      Item := AParent.Items[ItemIndex];
      Inc(Item.FTop, ADelta);
      MoveDownChilds(Item, ADelta);
    end;
end;

function FindNewTop(const AItemRect: TRect; APrevItemsRgn: HRGN): Integer;
var
  Delta: Integer;
  TempRegion: HRGN;
  ItemRegion: HRGN;
  CombineResult: Integer;
begin
  Delta := 0;
  Result := AItemRect.Top;
  TempRegion := CreateRectRgn(0, 0, 0, 0);
  ItemRegion := CreateRectRgnIndirect(AItemRect);

  // É¹æª ð±¨î´¾ ð¯§é·¨, ä¥¥ ì¦¬æ®² î£ ð¦°æ²¥ë¡¥ó²½ í‡í°°æ¥»å´¹é­¨
  while True do
    begin

      CombineResult := CombineRgn(TempRegion, ItemRegion, APrevItemsRgn, RGN_AND);
      if CombineResult = NULLREGION then Break;
      if Delta = 0 then Delta := 1
                   else Delta := Delta * 2;
      OffsetRgn(ItemRegion, 0, Delta);
      Result := Result + Delta;
    end;
  // É¹æª ó¯¸­í²²í±¯ï¨¨í½§í¼¬ ä¥¥ ì¦¬æ®² î£ ð¦°æ²¥ë¡¥ó²½ í‡í°°æ¥»å´¹é­¨
  while Delta > 0 do
    begin
      OffsetRgn(ItemRegion, 0, -Delta);
      Result := Result - Delta;
      CombineResult := CombineRgn(TempRegion, ItemRegion, APrevItemsRgn, RGN_AND);
      if CombineResult <> NULLREGION then
        begin
          OffsetRgn(ItemRegion, 0, Delta);
          Result := Result + Delta;
        end;
      Delta := Delta div 2;
    end;

  DeleteObject(TempRegion);
  DeleteObject(ItemRegion);
end;

{$IFDEF DEBUG}
procedure FindNewTopTest;
var
  Top: Integer;
  Top2: Integer;
  PrevItemsRgn: HRGN;
  R: TRect;
begin
  R.Left := 0;
  R.Top := 0;
  R.Right := 10;
  R.Bottom := 1;
  for Top := 1 to 256 do
    begin
      PrevItemsRgn := CreateRectRgn(0, 0, 10, Top);
      Top2 := FindNewTop(R, PrevItemsRgn);
      if Top2 <> Top then
        MessageBox(0, PChar('FindNewTopTest fails'), 'FindNewTopTest', MB_ICONERROR);
      DeleteObject(PrevItemsRgn);
    end;
end;
{$ENDIF}

procedure TTreeView.DoUpdate;
var
  {$IFDEF DEBUG}
  SaveXOffset: Integer;
  SaveYOffset: Integer;
  {$ENDIF}
  DC: HDC;
  ProcessedCount: Integer;
  Region: HRGN;

  procedure RebuildRegion;
  var
    ItemIndex: Integer;
    TempRegion: HRGN;
    R: TRect;
  begin
    DeleteObject(Region);
    Region := CreateRectRgn(0, 0, 0, 0);
    for ItemIndex := 0 to ProcessedCount - 1 do
      begin
        R := FProcessedItems[ItemIndex].BoundsRectEx;
        R.Top := 0;
        TempRegion := CreateRectRgnIndirect(R);
        CombineRgn(Region, Region, TempRegion, RGN_OR);
        DeleteObject(TempRegion);
      end;

    {$IFDEF DEBUG}
    OffsetRgn(Region, SaveXOffset, SaveYOffset);
    //FillRgnWithColor(DC, Region, $FF0000);
    OffsetRgn(Region, -SaveXOffset, -SaveYOffset);
    {$ENDIF}
  end;

  procedure Iterate(AItem: TTreeViewItem; AX, AY: Integer);
  var
    {$IFDEF DEBUG}
    R: TRect;
    {$ENDIF}
    ItemIndex: Integer;
    Item: TTreeViewItem;
    MinY, MaxY: Integer;
    Y: Integer;
    FirstItem: TTreeViewItem;
    LastItem: TTreeViewItem;
    StartTop: Integer;
  begin
    {$IFDEF DEBUG}
    R := AItem.BoundsRect;
    OffsetRect(R, SaveXOffset, SaveYOffset);
    //FillRectWithColor(DC, R, $00FF00);;
    {$ENDIF}

    AItem.Left := AX;
    Inc(AX, AItem.Width + HorzSpace);
    Y := 0;
    FirstItem := nil;
    LastItem := nil;
    if AItem.Expanded then
      for ItemIndex := 0 to AItem.Count - 1 do
        begin
          Item := AItem.Items[ItemIndex];
          Iterate(Item, AX, Y);
          Y := Item.Bottom + VertSpace;
          if not Assigned(FirstItem) then
            FirstItem := Item;
          LastItem := Item;
        end;

    if Assigned(FirstItem) then
      begin
        MinY := FirstItem.Top;
        MaxY := LastItem.Top + LastItem.Height;
        Y := MinY + (MaxY - MinY) div 2 - AItem.Height div 2;
        if Y < AY then
          begin
            MoveDownChilds(AItem, AY - Y);
            RebuildRegion;
            Y := AY;
          end;
        AItem.Top := Y;
      end
    else
      AItem.Top := AY;

    StartTop := AItem.Top;
    AItem.Top := FindNewTop(AItem.BoundsRectEx, Region);
    MoveDownChilds(AItem, AItem.Top - StartTop);

    FProcessedItems[ProcessedCount] := AItem;
    Inc(ProcessedCount);
    RebuildRegion;
  end;

  procedure UpdateOptimalSize(AItem: TTreeViewItem; var AOptimalWidth, AOptimalHeight: Integer);
  var
    ItemIndex: Integer;
  begin
    AOptimalWidth := Max(AOptimalWidth, AItem.Right);
    AOptimalHeight := Max(AOptimalHeight, AItem.Bottom);
    if AItem.Expanded then
      for ItemIndex := 0 to AItem.Count - 1 do
        UpdateOptimalSize(AItem.Items[ItemIndex], AOptimalWidth, AOptimalHeight);
  end;

var
  XOffset: Integer;
  YOffset: Integer;
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  if FLockUpdate or (FUpdateCount > 0) or not FNeedUpdateItemPositions or FDestroying then Exit;
  FNeedUpdateItemPositions := False;

  {$IFDEF DEBUG}
  CalcBaseOffsets(SaveXOffset, SaveYOffset);
  {$ENDIF}
  FOptimalWidth := 0;
  FOptimalHeight := 0;
  if Count > 0 then
    begin
      DC := GetDC(FHandle);
      if DC <> 0 then
        try
          for ItemIndex := 0 to Count - 1 do
            Items[ItemIndex].UpdateSize(DC);

          if (Count = 1) or not LinesAsRoot then XOffset := 0
                                            else XOffset := HorzSpace div 2;
          YOffset := 0;

          if Length(FProcessedItems) < FTotalCount then
            SetLength(FProcessedItems, FTotalCount);
          ProcessedCount := 0;
          Region := CreateRectRgn(0, 0, 0, 0);
          try
            for ItemIndex := 0 to Count - 1 do
              begin
                Item := Items[ItemIndex];
                Iterate(Item, XOffset, YOffset);
                YOffset := Item.Top + Item.Height;
              end;
          finally
            if Region <> 0 then
              DeleteObject(Region);
          end;

          for ItemIndex := 0 to Count - 1 do
            UpdateOptimalSize(Items[ItemIndex], FOptimalWidth, FOptimalHeight);
        finally
          ReleaseDC(FHandle, DC);
        end;
    end;

  UpdateScrollBars;
  Invalidate;
end;

procedure TTreeView.Update;
begin
  FNeedUpdateItemPositions := True;
  DoUpdate;
end;

procedure TTreeView.FullUpdate;
var
  ItemIndex: Integer;
begin
  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].NeedUpdateSizeWithChilds;
  FNeedUpdateItemPositions := True;
  DoUpdate;
end;

procedure TTreeView.SetLockUpdate(ALockUpdate: Boolean);
begin
  FLockUpdate := ALockUpdate;
  DoUpdate;
end;

function CreateSysFont(ADPI: HWND): HFONT;
var
  Metrics: TNonClientMetricsW;
  SystemDPI: UINT;
begin
  Metrics.cbSize := SizeOf(Metrics);
  if SystemParametersInfoForDpi(SPI_GETNONCLIENTMETRICS, Metrics.cbSize, @Metrics, 0, ADPI, False) then
    Result := CreateFontIndirectW(Metrics.lfMessageFont)
  else
    if SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, Metrics.cbSize, @Metrics, 0) then
      begin
        SystemDPI := GetDpiForSystem;
        if ADPI <> SystemDPI then
          begin
            Metrics.lfMessageFont.lfHeight := MulDiv(Metrics.lfMessageFont.lfHeight, ADPI, SystemDPI);
            Metrics.lfMessageFont.lfWidth := 0;
          end;
        Result := CreateFontIndirectW(Metrics.lfMessageFont);
      end
    else
      Result := 0;
end;

function LParamToPoint(ALParam: LPARAM): TPoint; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  Result.X := LoWord(ALParam);
  Result.Y := HiWord(ALParam);
end;

function TTreeView.WndProc(AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT;

  function GetClientCursorPos: TPoint;
  begin
    GetCursorPos(Result);
    ScreenToClient(FHandle, Result);
  end;

var
  {$IFDEF NATIVE_BORDERS}
  R: TRect;
  {$ENDIF}
  CreateStruct: PCreateStruct;
  ItemExW: PTVItemExW;
  TreeItem: TTreeViewItem;
  TreeItemP: PTreeViewItem;
  TreeItems: TTreeViewItems;
  InsertStructW: PTVInsertStructW;
  Rect: PRect;
  VertValue, HorzValue: Integer;
  TVHitTestInfo: PTVHitTestInfo;
  NMMouse: TNMMouse;
  CursorPos: TPoint;
  Wheel: SHORT;
  Reason: Integer;
begin
  Inc(FUpdateCount);
  try
    Result := 0;
    case AMsg of
      WM_NCCREATE:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          CreateStruct := PCreateStruct(ALParam);
          FParentHandle := CreateStruct.hwndParent;
          InitStyles(CreateStruct.style);
          InitStylesEx(CreateStruct.dwExStyle);
          FUnicode := SendMessage(FParentHandle, WM_NOTIFYFORMAT, FHandle, NF_QUERY) = NFR_UNICODE;
          FSysFont := True;
          Dpi := GetDpiForWindow(FHandle);
        end;
      WM_DESTROY:
        begin
          FDestroying := True;
          if Assigned(FItems) then
            FItems.DeleteAll;
          CloseTheme;
          DeleteFont;
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
        end;
      WM_NOTIFYFORMAT:
        begin
          if ALParam = NF_QUERY then
            Result := NFR_UNICODE
          else
            if ALParam = NF_REQUERY  then
              begin
                Result := SendMessage(FParentHandle, WM_NOTIFYFORMAT, FHandle, NF_QUERY);
                FUnicode := Result = NFR_UNICODE;
              end;
        end;
      {$IFDEF NATIVE_BORDERS}
      WM_NCCALCSIZE:
        begin
          R := PRect(ALParam)^;
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if Themed then
            CaclClientRect(@R, PRect(ALParam));
        end;
      WM_NCPAINT:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if Themed then
            PaintClientRect(AWParam);
        end;
      {$ENDIF}

      WM_HSCROLL:
        ScrollMessage(AWParam, SB_HORZ);
      WM_VSCROLL:
        ScrollMessage(AWParam, SB_VERT);

      WM_STYLECHANGED:
        if ALParam <> 0 then
          case Integer(AWParam) of
            GWL_STYLE: SetStyle(PStyleStruct(ALParam).styleNew);
            GWL_EXSTYLE: SetStyleEx(PStyleStruct(ALParam).styleNew);
          end;
      WM_ENABLE:
        if AWParam <> 0 then FStyle := FStyle and not WS_DISABLED
                        else FStyle := FStyle or WS_DISABLED;
      TVM_SETEXTENDEDSTYLE:
        SetStyle2(AWParam, ALParam);
      TVM_GETEXTENDEDSTYLE:
        Result := FStyle2;
      WM_THEMECHANGED:
        OpenTheme;
      WM_DPICHANGED_BEFOREPARENT:
        Dpi := GetDpiForWindow(FHandle);
      WM_WININICHANGE:
        begin
          UpdateScrollBarSize;
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
        end;
      WM_SETFONT:
        Font := AWParam;
      WM_GETFONT:
        if FSysFont then Result := 0
                    else Result := Font;
      TVM_SETBKCOLOR:
        begin
          if FSysColor then Result := -1
                       else Result := Color;
          Color := ALParam;
        end;
      TVM_GETBKCOLOR:
        if FSysColor then Result := -1
                     else Result := Color;
      TVM_SETTEXTCOLOR:
        begin
          if FSysTextColor then Result := -1
                           else Result := TextColor;
          TextColor := ALParam;
        end;
      TVM_GETTEXTCOLOR:
        if FSysTextColor then Result := -1
                         else Result := TextColor;
      TVM_SETLINECOLOR:
        begin
          if FSysLineColor then Result := LRESULT(CLR_DEFAULT)
                           else Result := LineColor;
          LineColor := ALParam;
        end;
      TVM_GETLINECOLOR:
        if FSysLineColor then Result := LRESULT(CLR_DEFAULT)
                         else Result := LineColor;
      TVM_SETINSERTMARKCOLOR:
        begin
          Result := InsertMaskColor;
          InsertMaskColor := ALParam;
        end;
      TVM_GETINSERTMARKCOLOR:
        Result := InsertMaskColor;
      TVM_SETIMAGELIST:
        case AWParam of
          TVSIL_NORMAL:
            begin
              Result := ImageList;
              ImageList := ALParam;
            end;
          TVSIL_STATE:
            begin
              Result := StateImageList;
              StateImageList := ALParam;
            end;
        end;
      TVM_GETIMAGELIST:
        case AWParam of
          TVSIL_NORMAL:
            Result := ImageList;
          TVSIL_STATE:
            Result := StateImageList;
        end;
      TVM_SETBORDER:
        begin
          Result := MakeLParam(HorzBorder, VertBorder);
          if AWParam and TVSBF_XBORDER <> 0 then HorzValue := LoWord(ALParam)
                                            else HorzValue := HorzBorder;
          if AWParam and TVSBF_YBORDER <> 0 then VertValue := HiWord(ALParam)
                                            else VertValue := VertBorder;
          SetBorders(HorzValue, VertValue);
        end;
      TVM_GETBORDER:
        case AWParam of
          TVSBF_XBORDER: Result := HorzBorder;
          TVSBF_YBORDER: Result := VertBorder;
        end;
      TVM_SETSPACE:
        begin
          Result := MakeLParam(HorzSpace, VertSpace);
          if AWParam and TVSBF_XBORDER <> 0 then HorzValue := LoWord(ALParam)
                                            else HorzValue := HorzSpace;
          if AWParam and TVSBF_YBORDER <> 0 then VertValue := HiWord(ALParam)
                                            else VertValue := VertSpace;
          SetSpaces(HorzValue, VertValue);
        end;
      TVM_GETSPACE:
        case AWParam of
          TVSBF_XBORDER: Result := HorzSpace;
          TVSBF_YBORDER: Result := VertSpace;
        end;
      TVM_SETINDENT:
        begin
          Result := HorzSpace;
          HorzSpace := AWParam;
        end;
      TVM_GETINDENT:
        Result := HorzSpace;

      WM_SETREDRAW:
        SetLockUpdate(AWParam = 0);
      WM_ERASEBKGND:
        Result := 1;
      WM_PAINT:
        Paint;
      WM_PRINTCLIENT:
        PaintClient(AWParam);
      WM_SIZE:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          UpdateScrollBars;
        end;

      WM_SETFOCUS:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          Focused := True;
          SendNotify(NM_SETFOCUS, nil);
        end;
      WM_KILLFOCUS:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          Focused := False;
          SendNotify(NM_KILLFOCUS, nil);
        end;
      WM_SETCURSOR:
        begin
          ZeroMemory(@NMMouse, SizeOf(NMMouse));
          CursorPos := GetClientCursorPos;
          NMMouse.pt := CursorPos;
          NMMouse.dwHitInfo := ALParam;
          if Assigned(FItems) then
            begin
              OffsetMousePoint(CursorPos);
              TreeItem := FItems.ItemAtPos(CursorPos);
              if Assigned(TreeItem) then
                begin
                  NMMouse.dwItemSpec := DWORD_PTR(TreeItem);
                  NMMouse.dwItemData := TreeItem.FParam;
                end;
            end;
          if SendNotify(NM_SETCURSOR, @NMMouse) = 0 then
            if (NMMouse.dwItemSpec = 0) or True then
              begin
                if FArrowCursor = 0 then
                  FArrowCursor := LoadCursor(0, IDC_ARROW);
                SetCursor(FArrowCursor);
              end
            else
              begin
                if FHandCursor = 0 then
                  FHandCursor := LoadCursor(0, IDC_HAND);
                SetCursor(FHandCursor);
              end;
        end;

      WM_GETDLGCODE:
        Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
      WM_KEYDOWN,
      WM_SYSKEYDOWN:
        KeyDown(AWParam, ALParam);

      WM_LBUTTONDOWN:
        LButtonDown(GetClientCursorPos);
      WM_LBUTTONUP:
        LButtonUp(GetClientCursorPos);
      WM_MBUTTONDOWN:
        MButtonDown(GetClientCursorPos);
      WM_RBUTTONDOWN:
        RButtonDown(GetClientCursorPos);
      WM_MOUSEMOVE:
        MouseMove(GetClientCursorPos);
      WM_MOUSEWHEEL:
        begin
          Wheel := HiWord(AWParam);
          if Wheel > 0 then Reason := TB_LINEUP
                       else Reason := TB_LINEDOWN;
          if IsVertScrollBarVisible then
            ScrollMessage(Reason, SB_VERT)
          else
            ScrollMessage(Reason, SB_HORZ);
        end;
      WM_CAPTURECHANGED:
        FMoveMode := False;
      WM_TIMER:
        begin
          case AWPARAM of
            IDT_SCROLLWAIT:
              begin
                KillTimer(FHandle, IDT_SCROLLWAIT);
                if Assigned(ScrollItem) then
                  begin
                    MakeVisible(ScrollItem);
                    ScrollItem := nil;
                  end;
              end;
          end;
        end;

      TVM_INSERTITEMA,
      TVM_INSERTITEMW:
        begin
          InsertStructW := PTVInsertStructW(ALParam);
          if not Assigned(InsertStructW) then Exit;
          if (InsertStructW.hParent = TVI_ROOT) or (InsertStructW.hParent = nil) then
            TreeItems := Items_
          else
            TreeItems := TTreeViewItem(InsertStructW.hParent).Items_;
          TreeItem := TTreeViewItem(InsertStructW.hInsertAfter);
          if AMsg = TVM_INSERTITEMA then
            Result := LRESULT(TreeItems.InsertItemA(TreeItem, @InsertStructW.itemex))
          else
            Result := LRESULT(TreeItems.InsertItemW(TreeItem, @InsertStructW.itemex));
        end;
      TVM_SETITEMA,
      TVM_SETITEMW:
        begin
          ItemExW := PTVItemExW(ALParam);
          if not Assigned(ItemExW) then Exit;
          TreeItem := TTreeViewItem(ItemExW.hItem);
          if not Assigned(TreeItem) then Exit;
          if AMsg = TVM_SETITEMA then TreeItem.AssignA(PTVItemExA(ItemExW))
                                 else TreeItem.AssignW(ItemExW);
          Result := 1;
        end;
      TVM_GETITEMA,
      TVM_GETITEMW:
        begin
          ItemExW := PTVItemExW(ALParam);
          if not Assigned(ItemExW) then Exit;
          TreeItem := TTreeViewItem(ItemExW.hItem);
          if not Assigned(TreeItem) then Exit;
          if AMsg = TVM_GETITEMA then TreeItem.AssignToA(PTVItemExA(ItemExW))
                                 else TreeItem.AssignToW(ItemExW);
          Result := 1;
        end;
      TVM_GETITEMSTATE:
        begin
          TreeItem := TTreeViewItem(AWParam);
          if not Assigned(TreeItem) then Exit;
          Result := TreeItem.State and ALParam;
        end;
      TVM_GETNEXTITEM:
        case AWParam of
          TVGN_ROOT:
            if Count > 0 then
              Result := LRESULT(Items[0]);
          TVGN_CARET:
            Result := LRESULT(SelectedItem);
        else
          TreeItem := TTreeViewItem(ALParam);
          if not Assigned(TreeItem) then Exit;
          Result := LRESULT(TreeItem.ParentItems.GetNextItem(TreeItem, AWParam));
        end;
      TVM_DELETEITEM:
        if (ALPARAM = LPARAM(TVI_ROOT)) or (ALPARAM = 0) then
          begin
            FSelectedItem := nil;
            FMouseOverItem := nil;
            FExpandItem := nil;
            FScrollItem := nil;
            FInsertMaskItem := nil;
            if Assigned(FItems) then
              FItems.DeleteAll;
            Result := 1;
          end
        else
          begin
            TreeItem := TTreeViewItem(ALParam);
            TreeItem.ParentItems.DeleteItem(TreeItem);
            Result := 1;
          end;
      TVM_SELECTITEM:
        begin
          TreeItem := TTreeViewItem(ALParam);
          case AWParam and $FF of
            TVGN_CARET:
              if SelectItem(TreeItem, True, TVC_UNKNOWN) then
                Result := 1;
          end;
        end;
      TVM_EXPAND:
        begin
          TreeItem := TTreeViewItem(ALParam);
          if not Assigned(TreeItem) then Exit;
          if TreeItem.Expand(AWParam, TVC_UNKNOWN, False) then
            Result := 1;
        end;
      TVM_ENSUREVISIBLE:
        begin
          TreeItem := TTreeViewItem(ALParam);
          if not Assigned(TreeItem) then Exit;
          MakeVisible(TreeItem);
          Result := 1;
        end;
      TVM_GETITEMRECT:
        begin
          TreeItemP := PTreeViewItem(ALParam);
          if not Assigned(TreeItemP) then Exit;
          TreeItem := TreeItemP^;
          if not Assigned(TreeItem) or not TreeItem.IsVisible then Exit;
          Rect := PRect(ALParam);
          if AWParam = 0 then Rect^ := TreeItem.BoundsRect
                         else Rect^ := TreeItem.TextRect;
          OffsetItemRect(Rect^);
          Result := 1;
        end;
      TVM_GETCOUNT:
        Result := FTotalCount;
      TVM_GETSELECTEDCOUNT:
        if Assigned(SelectedItem) then Result := 1;
      TVM_HITTEST:
        begin
          TVHitTestInfo := PTVHitTestInfo(ALParam);
          if Assigned(TVHitTestInfo) then
            begin
              HitTest(TVHitTestInfo);
              Result := LRESULT(TVHitTestInfo.hItem);
            end;
        end;
      TVM_SETINSERTMARK:
        begin
          SetInsertMaskItemAfter(TTreeViewItem(ALParam), AWParam <> 0);
          Result := 1;
        end
    else
      Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
    end;
  finally
    Dec(FUpdateCount);
    DoUpdate;
  end;
end;

procedure TTreeView.SetFocused(AFocused: Boolean);
begin
  if FFocused = AFocused then exit;
  FFocused := AFocused;
  if FFocused then
    UpdateSelected(TVC_BYMOUSE);
  if Assigned(SelectedItem) then
    InvalidateItem(SelectedItem);
end;

procedure TTreeView.InitStyles(AStyles: UINT);
begin
  FStyle := AStyles;
  FAlwaysShowSelection := AStyles and TVS_SHOWSELALWAYS <> 0;
  FHasButtons := AStyles and TVS_HASBUTTONS <> 0;
  FLinesAsRoot := AStyles and TVS_LINESATROOT <> 0;
end;

procedure TTreeView.InitStyles2(AStyles2: UINT);
begin
  FStyle2 := AStyles2;
  FAutoCenter := AStyles2 and TVS_EX_AUTOCENTER <> 0;
end;

procedure TTreeView.InitStylesEx(AStylesEx: UINT);
begin
  FStyleEx := AStylesEx;
end;

procedure TTreeView.SetStyle(AStyle: UINT);
var
  NeedUpdate: Boolean;
  NeedFullUpdate: Boolean;
  NeedInvalidate: Boolean;
  PrevAlwaysShowSelection: Boolean;
  PrevHasButtons: Boolean;
  PrevLinesAsRoot: Boolean;
begin
  NeedUpdate := False;
  NeedFullUpdate := False;
  NeedInvalidate := False;

  PrevAlwaysShowSelection := AlwaysShowSelection;
  PrevHasButtons := HasButtons;
  PrevLinesAsRoot := LinesAsRoot;

  InitStyles(AStyle);

  if AlwaysShowSelection <> PrevAlwaysShowSelection then
    if not Focused and Assigned(SelectedItem) then
      NeedInvalidate := True;
  if HasButtons <> PrevHasButtons then
    NeedFullUpdate := True;
  if LinesAsRoot <> PrevLinesAsRoot then
    NeedFullUpdate := True;

  if NeedFullUpdate then
    FullUpdate
  else
    if NeedUpdate then
      Update;
  if NeedInvalidate then
    Invalidate;
end;

procedure TTreeView.SetStyle2(AMask, AStyle2: UINT);
var
  NeedUpdate: Boolean;
  NeedFullUpdate: Boolean;
  NeedInvalidate: Boolean;
  PrevAutoCenter: Boolean;
begin
  NeedUpdate := False;
  NeedFullUpdate := False;
  NeedInvalidate := False;

  PrevAutoCenter := AutoCenter;

  AStyle2 := (FStyle2 and not AMask) or (AStyle2 and AMask);
  InitStyles2(AStyle2);

  if AutoCenter <> PrevAutoCenter then
    NeedInvalidate := True;

  if NeedFullUpdate then
    FullUpdate
  else
    if NeedUpdate then
      Update;
  if NeedInvalidate then
    Invalidate;
end;

procedure TTreeView.SetStyleEx(AStyleEx: UINT);
var
  NeedUpdate: Boolean;
  NeedFullUpdate: Boolean;
  NeedInvalidate: Boolean;
begin
  NeedUpdate := False;
  NeedFullUpdate := False;
  NeedInvalidate := False;

  InitStylesEx(AStyleEx);

  if NeedFullUpdate then
    FullUpdate
  else
    if NeedUpdate then
      Update;
  if NeedInvalidate then
    Invalidate;
end;

procedure TTreeView.SetDpi(ADpi: UINT);
begin
  if FDpi = ADpi then Exit;
  FDpi := ADpi;
  if FSysFont then
    begin
      DeleteFont;
      FFont := CreateSysFont(FDpi);
    end;
  OpenTheme;
  UpdateButtonSize;
  UpdateScrollBarSize;
end;

procedure TTreeView.CloseTheme;
begin
  if FTheme <> 0 then
    begin
      CloseThemeData(FTheme);
      FTheme := 0;
    end;
end;

procedure TTreeView.OpenTheme;
begin
  CloseTheme;
  if UseThemes then
    begin
      FTheme := {0;//} OpenThemeDataForDpi(FHandle, VSCLASS_TREEVIEW, Dpi, False);
      FDpiTheme := FTheme <> 0;
      if not FDpiTheme then
        begin
          if Dpi = GetDpiForSystem then
            begin
              FTheme := OpenThemeData(FHandle, VSCLASS_TREEVIEW);
              FDpiTheme := True;
            end
          else
            FTheme := OpenThemeDataEx(FHandle, VSCLASS_TREEVIEW, OTD_FORCE_RECT_SIZING);
        end;
      if FTheme <> 0 then
        if not Succeeded(GetThemePartSize(FTheme, 0, TVP_GLYPH, GLPS_CLOSED, nil, TS_TRUE, FThemeButtonSize)) then
          begin
            FThemeButtonSize.cx := 15 * Dpi div 96;
            FThemeButtonSize.cy := FThemeButtonSize.cx;
          end;
    end;
  FullUpdate;
end;

function TTreeView.GetThemed: Boolean;
begin
  Result := Theme <> 0;
end;

procedure TTreeView.DeleteFont;
begin
  if FFont <> 0 then
    begin
      DeleteObject(FFont);
      FFont := 0;
    end;
  if FBoldFont <> 0 then
    begin
      DeleteObject(FBoldFont);
      FBoldFont := 0;
    end;
end;

procedure TTreeView.UpdateScrollBarSize;
begin
  FCXVScroll := GetSystemMetricsForDpi_(SM_CXVSCROLL, Dpi);
  FCYHScroll := GetSystemMetricsForDpi_(SM_CYHSCROLL, Dpi);
end;

procedure TTreeView.UpdateButtonSize;
var
  DC: HDC;
  SaveFont: HFONT;
  R: TRect;
begin
  FButtonSize.cx := 9;
  DC := GetDC(FHandle);
  if DC <> 0 then
    try
      SaveFont := SelectObject(DC, Font);
      R.Left := 0; R.Top := 0; R.Right := 0; R.Bottom := 0;
      DrawTextEx(DC, '+', 1, R, DT_CALCRECT or DT_LEFT or DT_NOPREFIX, nil);
      FButtonSize.cx := ((R.Right) div 2) * 2 + 1;
      SelectObject(DC, SaveFont);
    finally
      ReleaseDC(FHandle, DC);
    end;
  FButtonSize.cy := FButtonSize.cx;
end;

function TTreeView.GetButtonSize: TSize;
begin
  if Themed then Result := FThemeButtonSize
            else Result := FButtonSize;
end;

procedure TTreeView.SetFont(AFont: HFONT);
var
  NewFont: HFONT;
  LogFont: TLogFontW;
begin
  if (AFont = 0) and FSysFont then Exit;
  if AFont = 0 then
    begin
      DeleteFont;
      FFont := CreateSysFont(Dpi);
      FSysFont := True;
    end
  else
    begin
      if GetObject(AFont, SizeOf(LogFont), @LogFont) = 0 then Exit;
      NewFont := CreateFontIndirectW(LogFont);
      if NewFont = 0 then Exit;
      DeleteFont;
      FFont := NewFont;
      FSysFont := False;
    end;
  UpdateButtonSize;
  FullUpdate;
end;

function TTreeView.GetBoldFont: HFONT;
var
  LogFont: TLogFontW;
begin
  if FBoldFont = 0 then
    if GetObject(FFont, SizeOf(LogFont), @LogFont) <> 0 then
      begin
        LogFont.lfWeight := FW_BOLD;
        FBoldFont := CreateFontIndirectW(LogFont);
      end;
  Result := FBoldFont;
end;

procedure TTreeView.UpdateColors;
begin
  if FSysColor then
    FColor := GetSysColor(COLOR_WINDOW);
  if FSysTextColor then
    FTextColor := GetSysColor(COLOR_WINDOWTEXT);
  if FSysLineColor then
    FLineColor := GetSysColor(COLOR_WINDOWTEXT);
  if FSysInsertMaskColor then
    FInsertMaskColor := GetSysColor(COLOR_WINDOWTEXT);
end;

procedure TTreeView.SetColor(AColor: TColorRef);
var
  PrevColor: TColorRef;
begin
  PrevColor := FColor;
  if AColor = TColorRef(-1) then
    begin
      FSysColor := True;
      FColor := GetSysColor(COLOR_WINDOW);
    end
  else
    begin
      FSysColor := False;
      FColor := AColor;
    end;
  if FColor = PrevColor then Exit;
  Invalidate;
end;

procedure TTreeView.SetTextColor(ATextColor: TColorRef);
var
  PrevTextColor: TColorRef;
begin
  PrevTextColor := FTextColor;
  if ATextColor = TColorRef(-1) then
    begin
      FSysTextColor := True;
      FTextColor := GetSysColor(COLOR_WINDOWTEXT);
    end
  else
    begin
      FSysTextColor := False;
      FTextColor := ATextColor;
    end;
  if FTextColor = PrevTextColor then Exit;
  Invalidate;
end;

procedure TTreeView.SetLineColor(ALineColor: TColorRef);
var
  PrevLineColor: TColorRef;
begin
  PrevLineColor := FLineColor;
  if ALineColor = CLR_DEFAULT then
    begin
      FSysLineColor := True;
      FLineColor := GetSysColor(COLOR_WINDOWTEXT);
    end
  else
    begin
      FSysLineColor := False;
      FLineColor := ALineColor;
    end;
  if FLineColor = PrevLineColor then Exit;
  Invalidate;
end;

procedure TTreeView.SetInsertMaskColor(AInsertMaskColor: TColorRef);
begin
  FSysInsertMaskColor := False;
  if FInsertMaskColor = AInsertMaskColor then Exit;
  FInsertMaskColor := AInsertMaskColor;
  InvalidateInsertMask;
end;

procedure TTreeView.SetImageList(AImageList: HIMAGELIST);
begin
  if FImageList = AImageList then Exit;
  FImageList := AImageList;
  if FImageList <> 0 then
    ImageList_GetIconSize(FImageList, FImageListIconSize.cx, FImageListIconSize.cy);
  FullUpdate;
end;

procedure TTreeView.SetStateImageList(AStateImageList: HIMAGELIST);
begin
  if FStateImageList = AStateImageList then Exit;
  FStateImageList := AStateImageList;
  if FStateImageList <> 0 then
    ImageList_GetIconSize(FStateImageList, FStateImageListIconSize.cx, FStateImageListIconSize.cy);
  FullUpdate;
end;

procedure TTreeView.SetBorders(AHorzBorder, AVertBorder: Integer);
begin
  if (FHorzBorder = AHorzBorder) and (FVertBorder = AVertBorder) then Exit;
  FHorzBorder := AHorzBorder;
  FVertBorder := AVertBorder;
  FullUpdate;
end;

procedure TTreeView.SetHorzBorder(AHorzBorder: Integer);
begin
  if FHorzBorder = AHorzBorder then Exit;
  FHorzBorder := AHorzBorder;
  FullUpdate;
end;

procedure TTreeView.SetVertBorder(AVertBorder: Integer);
begin
  if FVertBorder = AVertBorder then Exit;
  FVertBorder := AVertBorder;
  FullUpdate;
end;

procedure TTreeView.SetSpaces(AHorzSpace, AVertSpace: Integer);
begin
  if (FHorzSpace = AHorzSpace) and (FVertSpace = AVertSpace) then Exit;
  FHorzSpace := AHorzSpace;
  FVertSpace := AVertSpace;
  FullUpdate;
end;

procedure TTreeView.SetHorzSpace(AHorzSpace: Integer);
begin
  if FHorzSpace = AHorzSpace then Exit;
  FHorzSpace := AHorzSpace;
  FullUpdate;
end;

procedure TTreeView.SetVertSpace(AVertSpace: Integer);
begin
  if FVertSpace = AVertSpace then Exit;
  FVertSpace := AVertSpace;
  FullUpdate;
end;

function TTreeView.GetItems: TTreeViewItems;
begin
  if not Assigned(FItems) then
    FItems := TTreeViewItems.Create(Self, nil, 0);
  Result := FItems;
end;

function TTreeView.GetCount: Integer;
begin
  if Assigned(FItems) then Result := FItems.Count
                      else Result := 0;
end;

function TTreeView.GetItem(AIndex: Integer): TTreeViewItem;
begin
  Result := FItems.Items[AIndex];
end;

//**************************************************************************************************

function TreeViewWndProc(AWindow: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall;
var
  TreeView: TTreeView;
begin
  {$IFDEF USE_LOGS}
  LogEnterTreeViewWndProc(AWindow, AMsg, AWParam, ALParam);
  {$ENDIF}
  Result := 0;
  try
    case AMsg of
      WM_NCCREATE:
        begin
          InitLibs;
          TreeView := TTreeView.Create;
          TreeView.FHandle := AWindow;
          SetWindowLongPtr(AWindow, 0, LONG_PTR(TreeView));
          Result := TreeView.WndProc(AMsg, AWParam, ALParam);
        end;
      WM_NCDESTROY:
        begin
          TreeView := TTreeView(GetWindowLongPtr(AWindow, 0));
          Result := TreeView.WndProc(AMsg, AWParam, ALParam);
          TreeView.Free;
        end;
    else
      TreeView := TTreeView(GetWindowLongPtr(AWindow, 0));
      Result := TreeView.WndProc(AMsg, AWParam, ALParam);
    end;
  except
    {$IFDEF USE_LOGS}
    on E: Exception do
     LogTreeViewWndProcException(E);
    {$ENDIF}
  end;
  {$IFDEF USE_LOGS}
  LogExitTreeViewWndProc(AWindow, AMsg, AWParam, ALParam, Result);
  {$ENDIF}
end;

var
  InitCount: Integer;

procedure InitTreeViewLib;
var
  R: Cardinal;
  WndClass: TWndClass;
begin
  R:= {$IFDEF SUPPORTS_ATOMICINCREMENT}AtomicIncrement{$ELSE}InterlockedIncrement{$ENDIF}(InitCount);
  if R = 1 then
    begin
      ZeroMemory(@WndClass, SizeOf(WndClass));
      WndClass.style := CS_VREDRAW or CS_HREDRAW or CS_DBLCLKS;
      WndClass.lpfnWndProc := @TreeViewWndProc;
      WndClass.cbWndExtra := SizeOf(TTreeView);
      WndClass.hInstance := HInstance;
      WndClass.lpszClassName := TreeViewClassName;
      {$IFDEF DEBUG}
      if RegisterClass(WndClass) = 0 then
        RaiseLastOSError;
      {$ELSE}
      RegisterClass(WndClass);
      {$ENDIF}
    end;
  if R > 3 then
    {$IFDEF SUPPORTS_ATOMICINCREMENT}AtomicDecrement{$ELSE}InterlockedDecrement{$ENDIF}(InitCount);
end;

procedure DoneTreeViewLib;
begin
  if InitCount > 0 then
    UnregisterClass(TreeViewClassName, HInstance)
end;

initialization
  if ModuleIsLib then
    IsMultiThread := True;
  InitializeCriticalSection(LibsCS);
  {$IFDEF DEBUG}
  FindNewTopTest;
  {$ENDIF}

finalization
  DoneTreeViewLib;
  DoneLibs;
  DeleteCriticalSection(LibsCS);

end.

