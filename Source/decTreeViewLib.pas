unit decTreeViewLib;

{$DEFINE NATIVE_BORDERS}

(*

Not supported yet:

Messages:
  CCM_DPISCALE
  CCM_GETVERSION
  CCM_SETVERSION

  TVM_CREATEDRAGIMAGE
  TVM_EDITLABEL
  TVM_ENDEDITLABELNOW
  TVM_GETEDITCONTROL
  TVM_GETISEARCHSTRING
  TVM_GETITEMHEIGHT
  TVM_GETITEMPARTRECT
  TVM_GETSCROLLTIME
  TVM_GETTOOLTIPS
  TVM_GETVISIBLECOUNT
  TVM_MAPACCIDTOHTREEITEM
  TVM_MAPHTREEITEMTOACCID
  TVM_SETAUTOSCROLLINFO
  TVM_SETHOT
  TVM_SETITEMHEIGHT
  TVM_SETSCROLLTIME
  TVM_SETTOOLTIPS
  TVM_SHOWINFOTIP
  TVM_SORTCHILDREN
  TVM_SORTCHILDRENCB

Notification:

  TVN_ASYNCDRAW
  TVN_BEGINDRAG
  TVN_BEGINLABELEDIT
  TVN_BEGINRDRAG
  TVN_ENDLABELEDIT
  TVN_GETINFOTIP
  TVN_KEYDOWN
  TVN_SETDISPINFO

Styles:
  TVS_DISABLEDRAGDROP
  TVS_EDITLABELS
  TVS_FULLROWSELECT
  TVS_HASLINES
  TVS_INFOTIP
  TVS_NOHSCROLL
  TVS_NONEVENHEIGHT
  TVS_NOTOOLTIPS
  TVS_RTLREADING

ExtStyles:
  TVS_EX_AUTOHSCROLL
  TVS_EX_DRAWIMAGEASYNC
  TVS_EX_FADEINOUTEXPANDOS
  TVS_EX_MULTISELECT
  TVS_EX_NOINDENTSTATE
  TVS_EX_NOSINGLECOLLAPSE
  TVS_EX_RICHTOOLTIP

*)

interface

{$if CompilerVersion >= 25}
{$LEGACYIFEND ON}
{$ifend}

{$if CompilerVersion > 15}
  {$DEFINE SUPPORTS_INLINE}
{$ifend}

{$if CompilerVersion >= 23}
  {$DEFINE SUPPORTS_UNICODE_STRING}
{$ifend}

{$if CompilerVersion >= 24}
  {$DEFINE SUPPORTS_ATOMICINCREMENT}
{$ifend}

uses
  Windows, CommCtrl;

{$IFNDEF SUPPORTS_UNICODE_STRING}
type
  UnicodeString = WideString;
{$endif}

{$ALIGN ON}
{$MINENUMSIZE 4}

const
  TreeViewClassName: PChar = 'decTreeView';

function InitTreeViewLib: ATOM; stdcall;

const
  TVS_EX_AUTOCENTER = $80000000; // Non standard

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

const
  TVN_GETITEMSIZE = TVN_FIRST - 100; // Non standard

implementation

uses
  Messages {$IFDEF DEBUG}, SysUtils{$ENDIF} {$IFDEF USE_LOGS}, decShellLogs, decTreeViewLibLogs{$ENDIF},
  Types;

{$if CompilerVersion < 23}
{$I decTreeViewFix.inc}
{$ifend}

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

  //TVSI_NOSINGLEEXPAND = $8000;

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

var
  OSVersionInfo: TOSVersionInfo;

procedure InitOSVersion;
begin
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if not GetVersionEx(OSVersionInfo) then
    begin
      OSVersionInfo.dwMajorVersion := 5;
      OSVersionInfo.dwMinorVersion := 1;
    end;
end;

function IsVistaOrLater: Boolean; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  Result := OSVersionInfo.dwMajorVersion >= 6;
end;

const
  VSCLASS_TREEVIEWSTYLE  = 'TREEVIEWSTYLE';
  VSCLASS_TREEVIEW       = 'TREEVIEW';

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

  VSCLASS_BUTTONSTYLE    = 'BUTTONSTYLE';
  VSCLASS_BUTTON         = 'BUTTON';

  BP_CHECKBOX            = 3;

  CBS_UNCHECKEDNORMAL    = 1;
  CBS_UNCHECKEDHOT       = 2;
  CBS_UNCHECKEDPRESSED   = 3;
  CBS_UNCHECKEDDISABLED  = 4;
  CBS_CHECKEDNORMAL      = 5;
  CBS_CHECKEDHOT         = 6;
  CBS_CHECKEDPRESSED     = 7;
  CBS_CHECKEDDISABLED    = 8;
  CBS_MIXEDNORMAL        = 9;
  CBS_MIXEDHOT           = 10;
  CBS_MIXEDPRESSED       = 11;
  CBS_MIXEDDISABLED      = 12;
  CBS_IMPLICITNORMAL     = 13;
  CBS_IMPLICITHOT        = 14;
  CBS_IMPLICITPRESSED    = 15;
  CBS_IMPLICITDISABLED   = 16;
  CBS_EXCLUDEDNORMAL     = 17;
  CBS_EXCLUDEDHOT        = 18;
  CBS_EXCLUDEDPRESSED    = 19;
  CBS_EXCLUDEDDISABLED   = 20;

var
  LibsCS: TRTLCriticalSection;
  LibsInited: Boolean;
  UXThemeLib: HMODULE;
  DWMApiLib: HMODULE;
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
  TDrawThemeParentBackground = function(AWnd: HWND; ADC: HDC; ARect: PRECT): HRESULT; stdcall;
  TGetThemeBackgroundContentRect = function(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; const ABoundingRect: TRect; AContentRect: PRECT): HRESULT; stdcall;
  TGetThemeColor = function(ATheme: HTHEME; APartId, AStateId, APropId: Integer; var AColor: COLORREF): HRESULT; stdcall;
  TGetThemePartSize = function(ATheme: HTHEME; ADC: HDC; APartId, AStateId: Integer; ARect: PRECT; ASize: THEMESIZE; var psz: TSize): HRESULT; stdcall;
  TIsAppThemed = function: BOOL; stdcall;
  TIsThemeActive = function: BOOL; stdcall;
  TIsThemeBackgroundPartiallyTransparent = function(ATheme: HTHEME; APartId, AStateId: Integer): BOOL; stdcall;
  TIsThemePartDefined = function(ATheme: HTHEME; APartId, AStateId: Integer): BOOL; stdcall;
  TOpenThemeData = function(AWnd: HWND; AClassList: LPCWSTR): HTHEME; stdcall;
  TOpenThemeDataEx = function(AWnd: HWND; AClassList: PWideChar; AFlags: DWORD): HTHEME; stdcall;
  TOpenThemeDataForDpi = function(AWnd: HWND; AClassList: PWideChar; ADPI: UINT): HTHEME; stdcall;
  TSetWindowTheme = function(AWnd: HWND; ASubAppName, ASubIdList: PWideChar): HRESULT; stdcall;

  HPAINTBUFFER = THandle;

  TBPPaintParams = record
    cbSize: DWORD;
    dwFlags: DWORD;                      // BPPF_ flags
    prcExclude: PRect;
    pBlendFunction: PBLENDFUNCTION;
  end;
  PBPPaintParams = ^TBPPaintParams;

const
  // BP_BUFFERFORMAT
  BPBF_COMPATIBLEBITMAP = 0; // Compatible bitmap
  BPBF_DIB              = 1; // Device-independent bitmap
  BPBF_TOPDOWNDIB       = 2; // Top-down device-independent bitmap
  BPBF_TOPDOWNMONODIB   = 3; // Top-down monochrome device-independent bitmap
  BPBF_COMPOSITED       = BPBF_TOPDOWNDIB;

type
  TBufferedPaintInit = function: HRESULT; stdcall;
  TBufferedPaintUnInit = function: HRESULT; stdcall;
  TBeginBufferedPaint = function(ATargetDC: HDC; const ATargetRect: TRect; AFormat: DWORD; APaintParams: PBPPaintParams; var ADC: HDC): HPAINTBUFFER; stdcall;
  TBufferedPaintSetAlpha = function(ABufferedPaint: HPAINTBUFFER; ARect: PRect; AAlpha: Byte): HRESULT; stdcall;
  TEndBufferedPaint = function(ABufferedPaint: HPAINTBUFFER; AUpdateTarget: BOOL): HRESULT; stdcall;

const
  TMT_TRANSITIONDURATIONS = 6000;

type
  TGetThemeTransitionDuration = function(ATheme: HTHEME; APartId, AStateIdFrom, AStateIdTo, APropId: Integer; var ADuration: DWORD): HRESULT; stdcall;

const
  // BP_ANIMATIONSTYLE
  BPAS_NONE   = 0; // No animation
  BPAS_LINEAR = 1; // Linear fade animation
  BPAS_CUBIC  = 2; // Cubic fade animation
  BPAS_SINE   = 3; // Sinusoid fade animation

type
  TBPAnimationParams = record
    cbSize: DWORD;
    dwFlags: DWORD;              // BPAF_ flags
    style: Cardinal;
    dwDuration: DWORD;
  end;
  PBPAnimationParams = ^TBPAnimationParams;

  HANIMATIONBUFFER = THandle;     // handle to a buffered paint animation

  TBeginBufferedAnimation = function (AWnd: HWND; ATargetDC: HDC; var ATargetRect: TRect; AFormat: DWORD; APaintParams: PBPPaintParams;
    var AAnimationParams: TBPAnimationParams; var AFromDC: HDC; var AToDC: HDC): HANIMATIONBUFFER; stdcall;
  TBufferedPaintRenderAnimation = function (AWND: HWND; ATarget: HDC): BOOL; stdcall;
  TEndBufferedAnimation = function(AAnimation: HANIMATIONBUFFER; AUpdateTarget: BOOL): HRESULT; stdcall;
  TBufferedPaintStopAllAnimations = function(AWnd: HWND): HRESULT; stdcall;

  TDwmIsCompositionEnabled = function(var AEnabled: BOOL): HRESULT; stdcall;

  TGetDpiForWindow = function(AWnd: HWND): UINT; stdcall;
  TGetDpiForSystem = function: UINT; stdcall;
  TSystemParametersInfoForDpi = function(AAction: UINT; AParam: UINT; AOut: Pointer; AWinIni, ADpi: UINT): BOOL; stdcall;
  TGetSystemMetricsForDpi = function(AIndex: Integer; ADpi: UINT): Integer; stdcall;

var
  _CloseThemeData: TCloseThemeData;
  _DrawThemeBackground: TDrawThemeBackground;
  _DrawThemeParentBackground: TDrawThemeParentBackground;
  _GetThemeBackgroundContentRect: TGetThemeBackgroundContentRect;
  _GetThemeColor: TGetThemeColor;
  _GetThemePartSize: TGetThemePartSize;
  _IsAppThemed: TIsAppThemed;
  _IsThemeActive: TIsThemeActive;
  _IsThemeBackgroundPartiallyTransparent: TIsThemeBackgroundPartiallyTransparent;
  _IsThemePartDefined: TIsThemePartDefined;
  _OpenThemeData: TOpenThemeData;
  _OpenThemeDataEx: TOpenThemeDataEx;
  _OpenThemeDataForDpi: TOpenThemeDataForDpi;
  _SetWindowTheme: TSetWindowTheme;

  _BufferedPaintInit: TBufferedPaintInit;
  _BufferedPaintUnInit: TBufferedPaintUnInit;
  _BeginBufferedPaint: TBeginBufferedPaint;
  _BufferedPaintSetAlpha: TBufferedPaintSetAlpha;
  _EndBufferedPaint: TEndBufferedPaint;

  _GetThemeTransitionDuration: TGetThemeTransitionDuration;
  _BeginBufferedAnimation: TBeginBufferedAnimation;
  _BufferedPaintRenderAnimation: TBufferedPaintRenderAnimation;
  _EndBufferedAnimation: TEndBufferedAnimation;
  _BufferedPaintStopAllAnimations: TBufferedPaintStopAllAnimations;

  _DwmIsCompositionEnabled: TDwmIsCompositionEnabled;

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
          _DrawThemeParentBackground := GetProcAddress(UXThemeLib, 'DrawThemeParentBackground');
          _GetThemeBackgroundContentRect := GetProcAddress(UXThemeLib, 'GetThemeBackgroundContentRect');
          _GetThemeColor := GetProcAddress(UXThemeLib, 'GetThemeColor');
          _GetThemePartSize := GetProcAddress(UXThemeLib, 'GetThemePartSize');
          _IsAppThemed := GetProcAddress(UXThemeLib, 'IsAppThemed');
          _IsThemeActive := GetProcAddress(UXThemeLib, 'IsThemeActive');
          _IsThemeBackgroundPartiallyTransparent := GetProcAddress(UXThemeLib, 'IsThemeBackgroundPartiallyTransparent');
          _IsThemePartDefined := GetProcAddress(UXThemeLib, 'IsThemePartDefined');
          _OpenThemeData := GetProcAddress(UXThemeLib, 'OpenThemeData');
          _OpenThemeDataEx := GetProcAddress(UXThemeLib, 'OpenThemeDataEx');
          _OpenThemeDataForDpi := GetProcAddress(UXThemeLib, 'OpenThemeDataForDpi');
          _SetWindowTheme := GetProcAddress(UXThemeLib, 'SetWindowTheme');

          _BufferedPaintInit := GetProcAddress(UXThemeLib, 'BufferedPaintInit');
          _BufferedPaintUnInit := GetProcAddress(UXThemeLib, 'BufferedPaintUnInit');
          _BeginBufferedPaint := GetProcAddress(UXThemeLib, 'BeginBufferedPaint');
          _BufferedPaintSetAlpha := GetProcAddress(UXThemeLib, 'BufferedPaintSetAlpha');
          _EndBufferedPaint := GetProcAddress(UXThemeLib, 'EndBufferedPaint');

          _GetThemeTransitionDuration := GetProcAddress(UXThemeLib, 'GetThemeTransitionDuration');
          _BeginBufferedAnimation := GetProcAddress(UXThemeLib, 'BeginBufferedAnimation');
          _BufferedPaintRenderAnimation := GetProcAddress(UXThemeLib, 'BufferedPaintRenderAnimation');
          _EndBufferedAnimation := GetProcAddress(UXThemeLib, 'EndBufferedAnimation');
          _BufferedPaintStopAllAnimations := GetProcAddress(UXThemeLib, 'BufferedPaintStopAllAnimations');
        end;

      DWMApiLib := LoadLibrary('dwmapi.dll');
      if DWMApiLib <> 0 then
        begin
          _DwmIsCompositionEnabled := GetProcAddress(DWMApiLib, 'DwmIsCompositionEnabled');
        end;

      User32Lib := LoadLibrary('user32.dll');
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
  if DWMApiLib <> 0 then
    FreeLibrary(DWMApiLib);
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

function DrawThemeParentBackground(AWnd: HWND; ADC: HDC; ARect: PRECT): HRESULT;
begin
  if Assigned(_DrawThemeParentBackground) then
    Result := _DrawThemeParentBackground(AWnd, ADC, ARect)
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

function IsThemeBackgroundPartiallyTransparent(ATheme: HTHEME; APartId, AStateId: Integer): BOOL;
begin
  if Assigned(_IsThemeBackgroundPartiallyTransparent) then
    Result := _IsThemeBackgroundPartiallyTransparent(ATheme, APartId, AStateId)
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

function OpenThemeDataEx(AWnd: HWND; AClassList: PWideChar; AFlags: DWORD): HTHEME;
begin
  if Assigned(_OpenThemeDataEx) then
    Result := _OpenThemeDataEx(AWnd, AClassList, AFlags)
  else
    Result := OpenThemeData(AWnd, AClassList);
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

function SetWindowTheme(AWnd: HWND; ASubAppName, ASubIdList: PWideChar): HRESULT;
begin
  if Assigned(_SetWindowTheme) then
    Result := _SetWindowTheme(AWnd, ASubAppName, ASubIdList)
  else
    Result := E_NOTIMPL;
end;

function UseThemes: Boolean;
begin
  if (UXThemeLib <> 0) then
    Result := IsAppThemed and IsThemeActive
  else
    Result := False;
end;

function BufferedPaintInit: HRESULT;
begin
  if Assigned(_BufferedPaintInit) then
    Result := _BufferedPaintInit
  else
    Result := E_NOTIMPL;
end;

function BufferedPaintUnInit: HRESULT;
begin
  if Assigned(_BufferedPaintUnInit) then
    Result := _BufferedPaintUnInit
  else
    Result := E_NOTIMPL;
end;

function BeginBufferedPaint(ATargetDC: HDC; const ATargetRect: TRect; AFormat: DWORD; APaintParams: PBPPaintParams; var ADC: HDC): HPAINTBUFFER;
begin
  if Assigned(_BeginBufferedPaint) then
    Result := _BeginBufferedPaint(ATargetDC, ATargetRect, AFormat, APaintParams, ADC)
  else
    Result := 0;
end;

function BufferedPaintSetAlpha(ABufferedPaint: HPAINTBUFFER; ARect: PRect; AAlpha: Byte): HRESULT;
begin
  if Assigned(_BufferedPaintSetAlpha) then
    Result := _BufferedPaintSetAlpha(ABufferedPaint, ARect, AAlpha)
  else
    Result := E_NOTIMPL;
end;

function EndBufferedPaint(ABufferedPaint: HPAINTBUFFER; AUpdateTarget: BOOL): HRESULT;
begin
  if Assigned(_EndBufferedPaint) then
    Result := _EndBufferedPaint(ABufferedPaint, AUpdateTarget)
  else
    Result := E_NOTIMPL;
end;

function GetThemeTransitionDuration(ATheme: HTHEME; APartId, AStateIdFrom, AStateIdTo, APropId: Integer; var ADuration: DWORD): HRESULT;
begin
  if Assigned(_GetThemeTransitionDuration) then
    Result := _GetThemeTransitionDuration(ATheme, APartId, AStateIdFrom, AStateIdTo, APropId, ADuration)
  else
    Result := E_NOTIMPL;
end;

function BeginBufferedAnimation(AWnd: HWND; ATargetDC: HDC; var ATargetRect: TRect; AFormat: DWORD; APaintParams: PBPPaintParams;
  var AAnimationParams: TBPAnimationParams; var AFromDC: HDC; var AToDC: HDC): HANIMATIONBUFFER;
begin
  if Assigned(_BeginBufferedAnimation) then
    Result := _BeginBufferedAnimation(AWnd, ATargetDC, ATargetRect, AFormat, APaintParams, AAnimationParams, AFromDC, AToDC)
  else
    Result := 0;
end;

function BufferedPaintRenderAnimation(AWND: HWND; ATarget: HDC): BOOL;
begin
  if Assigned(_BufferedPaintRenderAnimation) then
    Result := _BufferedPaintRenderAnimation(AWnd, ATarget)
  else
    Result := False;
end;

function EndBufferedAnimation(AAnimation: HANIMATIONBUFFER; AUpdateTarget: BOOL): HRESULT;
begin
  if Assigned(_EndBufferedAnimation) then
    Result := _EndBufferedAnimation(AAnimation, AUpdateTarget)
  else
    Result := E_NOTIMPL;
end;

function BufferedPaintStopAllAnimations(AWnd: HWND): HRESULT;
begin
  if Assigned(_BufferedPaintStopAllAnimations) then
    Result := _BufferedPaintStopAllAnimations(AWnd)
  else
    Result := E_NOTIMPL;
end;


function DwmIsCompositionEnabled: BOOL;
begin
  if Assigned(_DwmIsCompositionEnabled) then
    begin
      if _DwmIsCompositionEnabled(Result) <> S_OK then
        Result := False
    end
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
  GdiPlusDll = 'gdiplus.dll';

function GdipCreateFromHDC(ADC: HDC; out AGraphics: HDC): UINT; stdcall; external GdiPlusDll;
function GdipDeleteGraphics(AGraphics: HDC): UINT; stdcall; external GdiPlusDll;

function GdipCreatePen1(AColor: UINT; AWidth: Single; AUnit: UINT; out APen: HPEN): UINT; stdcall; external GdiPlusDll;
function GdipDeletePen(APen: HPEN): UINT; stdcall; external GdiPlusDll;

const
  SmoothingModeDefault      = 0;
  SmoothingModeHighSpeed    = 1;
  SmoothingModeHighQuality  = 2;
  SmoothingModeNone         = 3;
  SmoothingModeAntiAlias    = 4;
  SmoothingModeAntiAlias8x4 = SmoothingModeAntiAlias;
  SmoothingModeAntiAlias8x8 = 5;

function GdipSetSmoothingMode(Graphics: HDC; SmoothingMode: UINT): UINT; stdcall; external GdiPlusDll;

function GdipDrawBeziersI(Graphics: HDC; Pen: HPEN; const Points: PPoint; Count: Integer): UINT; stdcall; external GdiPlusDll;

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

  TGdiCache = class(TObject)
  public
    constructor Create(ATreeView: TTreeView; ADC: HDC);
    destructor Destroy; override;
  private
    procedure DeleteGdiPlusDC;
  private
    FTreeView: TTreeView;
    FDC: HDC;

    FCheckBoxExcludePen: HPEN;
    FLinePen: HPEN;
    FTextColorPen: HPEN;

    FButtonFaceBrush: HBRUSH;
    FColorBrush: HBRUSH;
    FGrayTextBrush: HBRUSH;
    FHighlightBrush: HBRUSH;
    FLineBrush: HBRUSH;

    FGdiPlusDC: HDC;
    FGdiPlusDCInited: Boolean;
    FGdiPlusLineColorPen: HPEN;

    function GetCheckBoxExcludePen: HPEN;
    function GetLinePen: HPEN;
    function GetTextColorPen: HPEN;

    function GetButtonFaceBrush: HBRUSH;
    function GetColorBrush: HBRUSH;
    function GetGrayTextBrush: HBRUSH;
    function GetHighlightBrush: HBRUSH;
    function GetLineBrush: HBRUSH;

    function GetGdiPlusDC: HDC;
    function GetGdiPlusLineColorPen: HPEN;
  private
    property CheckBoxExcludePen: HPEN read GetCheckBoxExcludePen;
    property LinePen: HPEN read GetLinePen;
    property TextColorPen: HPEN read GetTextColorPen;

    property ButtonFaceBrush: HBRUSH read GetButtonFaceBrush;
    property ColorBrush: HBRUSH read GetColorBrush;
    property GrayTextBrush: HBRUSH read GetGrayTextBrush;
    property HighlightBrush: HBRUSH read GetHighlightBrush;
    property LineBrush: HBRUSH read GetLineBrush;

    property GdiPlusDC: HDC read GetGdiPlusDC;
    property GdiPlusLineColorPen: HPEN read GetGdiPlusLineColorPen;
  end;

  TKids = (kCompute, kForceYes, kForceNo, kCallback);


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
    procedure FullExpand(ACode, AAction: UINT; ANotify: Boolean);
    function ExpandParents(AAction: UINT): Boolean;
    procedure SavePositionForAnimation;
    procedure PreparePositionsForExpandAnimation(ADelta: Integer);
    procedure PreparePositionsForCollapseAnimation(ADelta: Integer);
    procedure UpdateSize(ADC: HDC);
    procedure InitCheckBoxState;
    procedure SelectNextCheckState;
    procedure PaintConnector(ADC: HDC; AGdiCache: TGdiCache; AIndex: Integer; ADest: TTreeViewItem);
    procedure PrePaintConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN);
    procedure PaintConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn: HRGN);
    procedure PaintBackground(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect; out AFontColor: TColorRef);
    procedure PaintStateIcon(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect);
    procedure PaintIcon(ADC: HDC; const ARect: TRect);
    procedure PaintText(ADC: HDC; var ARect: TRect; AFontColor: TColorRef);
    procedure PaintButton(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect);
    procedure Paint(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN; AXOffset, AYOffset: Integer; AEraseBackground: Boolean);
    procedure MouseMove(const APoint: TPoint);
    procedure MouseLeave;
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

    FKids: TKids;

    FMinTop: Integer;
    FPrevLeft: Integer;
    FPrevTop: Integer;
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FTextWidth: Integer;
    FTextHeight: Integer;

    FItems: TTreeViewItems;

    FHotButton: Boolean;
    FHotCheckBox: Boolean;
    FPressCheckBox: Boolean;

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
    function GetStateIndex: Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
    procedure SetStateIndex(AStateIndex: Integer); {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
    function GetImageIndex: Integer;
    function GetSelectedImageIndex: Integer;
    function GetExpandedImageIndex: Integer;

    property Kids: TKids read FKids;

    function GetLeft: Integer;
    function GetTop: Integer;
    function GetRight: Integer;
    function GetBottom: Integer;
    function GetBoundsRect: TRect;
    function GetStateIconRect: TRect;
    function GetIconRect: TRect;
    function GetTextRect: TRect;
    function GetButtonRect: TRect;

    function GetItems: TTreeViewItems;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TTreeViewItem; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

    procedure SetHotButton(AHotButton: Boolean);
    procedure SetHotCheckBox(AHotCheckBox: Boolean);
    procedure SetPressCheckBox(APressCheckBox: Boolean);
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
    property StateIndex: Integer read GetStateIndex write SetStateIndex;
    property ImageIndex: Integer read GetImageIndex;
    property SelectedImageIndex: Integer read GetSelectedImageIndex;
    property ExpandedImageIndex: Integer read GetExpandedImageIndex;

    property Left: Integer read GetLeft write FLeft;
    property Top: Integer read GetTop write FTop;
    property Right: Integer read GetRight;
    property Bottom: Integer read GetBottom;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property BoundsRect: TRect read GetBoundsRect;
    property StateIconRect: TRect read GetStateIconRect;
    property IconRect: TRect read GetIconRect;
    property TextRect: TRect read GetTextRect;
    property ButtonRect: TRect read GetButtonRect;

    property Items_: TTreeViewItems read GetItems;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TTreeViewItem read GetItem;

    property HotButton: Boolean read FHotButton write SetHotButton;
    property HotCheckBox: Boolean read FHotCheckBox write SetHotCheckBox;
    property PressCheckBox: Boolean read FPressCheckBox write SetPressCheckBox;
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

  TAnimationMode = (amNone, amExpand, amCollapse);
  TAdditionalCheckState = (csPartial, csDimmed, csExclusion);
  TAdditionalCheckStates = set of TAdditionalCheckState;

  TTreeView = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
  private
    // NC Paint
    function HasBorder: Boolean;
    {$IFDEF NATIVE_BORDERS}
    procedure CaclClientRect(ARect, AClientRect: PRect);
    {$ENDIF}
    function PaintBorders(AClipRgn: HRGN): LRESULT;
  private
    // Scroll routines
    FHorzScrollInfo: TScrollInfo;
    FVertScrollInfo: TScrollInfo;
    FUpdateScrollBars: Boolean;
    FPrevOptimalWidth: Integer;
    FPrevOptimalHeight: Integer;
    FOptimalWidth: Integer;
    FOptimalHeight: Integer;
    function GetScrollInfo(ABar: Integer; var AScrollInfo: TScrollInfo): Boolean;
    function SetScrollInfo(ABar: Integer; var AScrollInfo: TScrollInfo): Integer;
    function SetScrollPos(ABar, APos: Integer): Integer;
    function GetScrollPos(ABar: Integer): Integer;
    function PixelsPerLine: UINT;
    function IsRealScrollBarVisible(ABar: DWORD): Boolean;
    function IsRealHorzScrollBarVisible: Boolean;
    function IsRealVertScrollBarVisible: Boolean;
    function IsScrollBarVisible(ABar: DWORD): Boolean;
    function IsHorzScrollBarVisible: Boolean;
    function IsVertScrollBarVisible: Boolean;
    procedure UpdateScrollBarsEx(AClientWidth, AClientHeight: Integer);
    procedure UpdateScrollBars(AMouseMove: Boolean = True);
    procedure NoScrollBarChanged;
    procedure ScrollMessage(AReason: WPARAM; ABar: DWORD);
    procedure CalcBaseOffsets(var AXOffset, AYOffset: Integer);
    procedure OffsetMousePoint(var APoint: TPoint);
    procedure OffsetItemRect(var ARect: TRect);
  private
    // Paint routines
    FBufferedPaintInited: Boolean;
    FBufferedPaintInitResult: HRESULT;
    FHideFocus: Boolean;
    FSavePoint: TPoint;
    FPaintRequest: UINT;
    FPrevXOffset: Integer;
    FPrevYOffset: Integer;
    FResizeMode: Boolean;
    FAnimationMode: TAnimationMode;
    FAnimatioStepCount: Integer;
    FAnimatioStep: Integer;
    FAnimationExpandItem: TTreeViewItem;
    FAnimationCollapseItem: TTreeViewItem;
    function SendDrawNotify(ADC: HDC; AStage: UINT; var ANMTVCustomDraw: TNMTVCustomDraw): UINT;
    procedure PolyBezier(ADC: HDC; AGdiCache: TGdiCache; const APoints; ACount: DWORD);
    procedure PaintRootConnector(ADC: HDC; AGdiCache: TGdiCache; ASource, ADest: TTreeViewItem);
    procedure PrePaintRootConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN);
    procedure PaintRootConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
    procedure PaintInsertMask(ADC: HDC; AUpdateRgn: HRGN);
    procedure PaintTo(ADC: HDC; AGdiCache: TGdiCache; var AUpdateRgn, ABackgroupRgn: HRGN; ASmartEraseBackground: Boolean);
    procedure Paint;
    procedure PaintClient(ADC: HDC);
    procedure Invalidate;
    procedure InvalidateItem(AItem: TTreeViewItem);
    procedure InvalidateItemCheckBox(AItem: TTreeViewItem);
    procedure InvalidateItemButton(AItem: TTreeViewItem);
    procedure InvalidateInsertMask;
    function CalcAnimation(AStart, AFinish: Integer): Integer;
    procedure DoAnimation(AExpandItem, ACollapseItem, AMouseItem: TTreeViewItem; AMode: TAnimationMode);
    property AnimationMode: TAnimationMode read FAnimationMode;
    property AnimationExpandItem: TTreeViewItem read FAnimationExpandItem;
    property AnimationCollapseItem: TTreeViewItem read FAnimationCollapseItem;
  private
    // Item routines
    FInsertMaskItem: TTreeViewItem;
    FInsertMaskItemAfter: Boolean;
    FFocusedItem: TTreeViewItem;
    FFixedItem: TTreeViewItem;
    FixedItemRect: TRect;
    FScrollItem: TTreeViewItem;
    FHotItem: TTreeViewItem;
    FPressedItem: TTreeViewItem;
    FDropItem: TTreeViewItem;
    procedure HitTest(TVHitTestInfo: PTVHitTestInfo);
    procedure MakeVisible(AItem: TTreeViewItem);
    function ExpandItem(AItem: TTreeViewItem; ACode, AAction: UINT; ANotify: Boolean): Boolean;
    procedure SingleExpandItem(AItem, APrevFocused: TTreeViewItem; AAction: UINT; ANotify: Boolean; ADisableSingleCollapse: Boolean);
    function SelectItem(AItem: TTreeViewItem; ANotify: Boolean; AAction: UINT; ADisableSingleCollapse: Boolean): Boolean;
    procedure UpdateSelected(AAction: UINT);
    procedure SetInsertMaskItemAfter(AInsertMaskItem: TTreeViewItem; AAfter: Boolean);
    procedure SetInsertMaskItem(AInsertMaskItem: TTreeViewItem);
    function GetInsertMaskRect: TRect;
    procedure SetHotItem(AHotItem: TTreeViewItem);
    procedure SetPressedItem(APressedItem: TTreeViewItem);
    procedure SetDropItem(ADropItem: TTreeViewItem);
    property InsertMaskItem: TTreeViewItem read FInsertMaskItem write SetInsertMaskItem;
    property InsertMaskItemAfter: Boolean read FInsertMaskItemAfter;
    property InsertMaskRect: TRect read GetInsertMaskRect;
    property FocusedItem: TTreeViewItem read FFocusedItem;
    property FixedItem: TTreeViewItem read FFixedItem write FFixedItem;
    property ScrollItem: TTreeViewItem read FScrollItem write FScrollItem;
    property HotItem: TTreeViewItem read FHotItem write SetHotItem;
    property PressedItem: TTreeViewItem read FPressedItem write SetPressedItem;
    property DropItem: TTreeViewItem read FDropItem write SetDropItem;
  private
    // Control routines
    FMoveMode: Boolean;
    FMoveMouseStartPos: TPoint;
    FMoveScrollStartPos: TPoint;
    FTrackMouse: Boolean;
    FWheelAccumulator: array[Boolean] of Integer;
    FWheelActivity: array[Boolean] of Cardinal;
    function GetClientCursorPos: TPoint;
    procedure KeyDown(AKeyCode: DWORD; AFlags: DWORD);
    procedure LButtonDown(APoint: TPoint);
    procedure LButtonDblDown(APoint: TPoint);
    procedure LButtonUp(APoint: TPoint);
    procedure MButtonDown(APoint: TPoint);
    procedure MButtonDblDown(APoint: TPoint);
    procedure MButtonUp(APoint: TPoint);
    procedure RButtonDown(APoint: TPoint);
    procedure RButtonDblDown(APoint: TPoint);
    procedure RButtonUp(APoint: TPoint);
    procedure TrackMouse;
    procedure MouseMove(APoint: TPoint);
    procedure MouseHover(APoint: TPoint);
    procedure MouseLeave;
    procedure MouseWheel(ADelta: Integer; AVert: Boolean);
  private
    // Callback routines
    function SendNotify(AParentWnd, AWnd: HWND; ACode: Integer; ANMHdr: PNMHdr): LRESULT; overload;
    function SendNotify(ACode: Integer; ANMHdr: PNMHdr): LRESULT; overload;
    function SendTreeViewNotify(ACode: Integer; AOldItem, ANewItem: TTreeViewItem; AAction: UINT): UINT;
    function SendItemChangeNofify(ACode: Integer; AItem: TTreeViewItem; AOldState, ANewState: UINT): Boolean;
  private
    // Main routines
    FTempTextBuffer: Pointer;
    FNeedUpdateItemSize: Boolean;
    FNeedUpdateItemPositions: Boolean;
    FUpdateCount: Integer;
    FLockUpdate: Boolean;
    FArrowCursor: HCURSOR;
    FHandCursor: HCURSOR;
    FMoveCursor: HCURSOR;
    procedure DoUpdate2;
    procedure DoUpdate;
    procedure Update; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
    procedure FullUpdate; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
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
    FAlwaysShowSelection: Boolean;
    FAutoCenter: Boolean;
    FBorder: Boolean;
    FClientEdge: Boolean;
    FHasButtons: Boolean;
    FLinesAsRoot: Boolean;
    FNoScroll: Boolean;
    FSingleExpand: Boolean;
    FTrackSelect: Boolean;
    FCheckBoxes: Boolean;
    FCheckBoxStateCount: Integer;
    FCheckBoxStates: array[1..5] of Integer;
    FDpi: UINT;
    FTheme: HTHEME;
    FDpiTheme: Boolean;
    FCheckBoxTheme: HTHEME;
    FDpiCheckTheme: Boolean;
    FTreeItemThemeExist: Boolean;
    FButtonThemeExist: Boolean;
    FHotButtonThemeExist: Boolean;
    FCheckBoxThemeExist: Boolean;
    FCXVScroll: Integer;
    FCYHScroll: Integer;
    FThemeButtonSize: TSize;
    FButtonSize: TSize;
    FThemeCheckBoxSize: TSize;
    FCheckBoxSize: TSize;
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
    FIndent: Integer; // Dummy
    FItemHeight: Integer; // Dummy
    procedure SetFocused(AFocused: Boolean);
    procedure SetNoScroll(ANoScroll: Boolean);
    procedure UpdateCheckBoxes;
    procedure InitItemsCheckBoxStates;
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
    procedure UpdateCheckSize;
    function GetButtonSize: TSize;
    function GetCheckBoxSize: TSize;
    procedure SetFont(AFont: HFONT);
    function GetBoldFont: HFONT;
    procedure UpdateColors;
    procedure SetColor(AColor: TColorRef);
    procedure SetTextColor(ATextColor: TColorRef);
    procedure SetLineColor(ALineColor: TColorRef);
    procedure SetInsertMaskColor(AInsertMaskColor: TColorRef);
    procedure SetImageList(AImageList: HIMAGELIST);
    procedure SetStateImageList(AStateImageList: HIMAGELIST);
    function GetStateImageListIconSize: TSize;
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
    property AlwaysShowSelection: Boolean read FAlwaysShowSelection;
    property AutoCenter: Boolean read FAutoCenter;
    property Border: Boolean read FBorder;
    property ClientEdge: Boolean read FClientEdge;
    property HasButtons: Boolean read FHasButtons;
    property LinesAsRoot: Boolean read FLinesAsRoot;
    property NoScroll: Boolean read FNoScroll write SetNoScroll;
    property SingleExpand: Boolean read FSingleExpand;
    property TrackSelect: Boolean read FTrackSelect;
    property CheckBoxes: Boolean read FCheckBoxes;
    property Dpi: UINT read FDpi write SetDpi;
    property Themed: Boolean read GetThemed;
    property Theme: HTHEME read FTheme;
    property TreeItemThemeExist: Boolean read FTreeItemThemeExist;
    property ButtonThemeExist: Boolean read FButtonThemeExist;
    property HotButtonThemeExist: Boolean read FHotButtonThemeExist;
    property ButtonSize: TSize read GetButtonSize;
    property CheckBoxTheme: HTHEME read FCheckBoxTheme;
    property CheckBoxThemeExist: Boolean read FCheckBoxThemeExist;
    property CheckBoxSize: TSize read GetCheckBoxSize;
    property Font: HFONT read FFont write SetFont;
    property BoldFont: HFONT read GetBoldFont;
    property Color: TColorRef read FColor write SetColor;
    property TextColor: TColorRef read FTextColor write SetTextColor;
    property LineColor: TColorRef read FLineColor write SetLineColor;
    property InsertMaskColor: TColorRef read FInsertMaskColor write SetInsertMaskColor;
    property ImageList: HIMAGELIST read FImageList write SetImageList;
    property ImageListIconSize: TSize read FImageListIconSize;
    property StateImageList: HIMAGELIST read FStateImageList write SetStateImageList;
    property StateImageListIconSize: TSize read GetStateImageListIconSize;
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

constructor TGdiCache.Create(ATreeView: TTreeView; ADC: HDC);
begin
  inherited Create;
  FTreeView := ATreeView;
  FDC := ADC;
end;

destructor TGdiCache.Destroy;
begin
  if FCheckBoxExcludePen <> 0 then DeleteObject(FCheckBoxExcludePen);
  if FLinePen <> 0 then DeleteObject(FLinePen);
  if FTextColorPen <> 0 then DeleteObject(FTextColorPen);

  if FButtonFaceBrush <> 0 then DeleteObject(FButtonFaceBrush);
  if FColorBrush <> 0 then DeleteObject(FColorBrush);
  if FGrayTextBrush <> 0 then DeleteObject(FGrayTextBrush);
  if FHighlightBrush <> 0 then DeleteObject(FHighlightBrush);
  if FLineBrush <> 0 then DeleteObject(FLineBrush);

  if FGdiPlusLineColorPen <> 0 then GdipDeletePen(FGdiPlusLineColorPen);
  if FGdiPlusDC <> 0 then GdipDeleteGraphics(FGdiPlusDC);
  inherited Destroy;
end;

procedure TGdiCache.DeleteGdiPlusDC;
begin
  if FGdiPlusDC <> 0 then
    begin
      GdipDeleteGraphics(FGdiPlusDC);
      FGdiPlusDC := 0;
    end;
end;

function TGdiCache.GetCheckBoxExcludePen: HPEN;
begin
  if FCheckBoxExcludePen = 0 then
    FCheckBoxExcludePen := CreatePen(PS_SOLID, 1, $5D5D5D);
  Result := FCheckBoxExcludePen;
end;

function TGdiCache.GetLinePen: HPEN;
begin
  if FLinePen = 0 then
    FLinePen := CreatePen(PS_SOLID, 1, FTreeView.LineColor);
  Result := FLinePen;
end;

function TGdiCache.GetTextColorPen: HPEN;
begin
  if FTextColorPen = 0 then
    FTextColorPen := CreatePen(PS_SOLID, 1, FTreeView.TextColor);
  Result := FTextColorPen;
end;

function TGdiCache.GetButtonFaceBrush: HBRUSH;
begin
  if FButtonFaceBrush = 0 then
    FButtonFaceBrush := CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
  Result := FButtonFaceBrush;
end;

function TGdiCache.GetColorBrush: HBRUSH;
begin
  if FColorBrush = 0 then
    FColorBrush := CreateSolidBrush(FTreeView.Color);
  Result := FColorBrush;
end;

function TGdiCache.GetGrayTextBrush: HBRUSH;
begin
  if FGrayTextBrush = 0 then
    FGrayTextBrush := CreateSolidBrush(GetSysColor(COLOR_GRAYTEXT));
  Result := FGrayTextBrush;
end;

function TGdiCache.GetHighlightBrush: HBRUSH;
begin
  if FHighlightBrush = 0 then
    FHighlightBrush := CreateSolidBrush(GetSysColor(COLOR_HIGHLIGHT));
  Result := FHighlightBrush;
end;

function TGdiCache.GetLineBrush: HBRUSH;
begin
  if FLineBrush = 0 then
    FLineBrush := CreateSolidBrush(FTreeView.LineColor);
  Result := FLineBrush;
end;

function TGdiCache.GetGdiPlusDC: HDC;
begin
  if not FGdiPlusDCInited then
    begin
      FGdiPlusDCInited := True;
      if GdipCreateFromHDC(FDC, FGdiPlusDC) <> 0 then
        FGdiPlusDC := 0;
    end;
  Result := FGdiPlusDC;
end;

function TGdiCache.GetGdiPlusLineColorPen: HPEN;
begin
  if FGdiPlusLineColorPen = 0 then
    if GdipCreatePen1(FTreeView.LineColor or $FF000000, 1, 0, FGdiPlusLineColorPen) <> 0 then
      FGdiPlusLineColorPen := 0;
  Result := FGdiPlusLineColorPen;
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
  FImageIndex := 0;
  FSelectedImageIndex := 0;
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
  PrevState: UINT;
  NewState: UINT;
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
      case FChildren of
        I_CHILDRENAUTO:
          FKids := kCompute;
        I_CHILDRENCALLBACK:
          FKids := kCallback;
        0:
          FKids := kForceNo;
      else
        FKids := kForceYes;
      end;
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
      PrevState := FState;
      NewState := (FState and not AItem.stateMask) or (AItem.state and AItem.stateMask);
      if NewState <> PrevState then
        if not FTreeView.SendItemChangeNofify(TVN_ITEMCHANGINGW, Self, PrevState, NewState) then
          begin
            FState := NewState;

            if Expanded <> PrevExpanded then
              if Expanded then
                begin
                  if not TreeView.ExpandItem(Self, TVE_EXPAND, TVC_UNKNOWN, False) then
                    FState := FState and not TVIS_EXPANDED;
                end
              else
                begin
                  if not TreeView.ExpandItem(Self, TVE_COLLAPSE, TVC_UNKNOWN, False) then
                    FState := FState or TVIS_EXPANDED;
                end;

            if Bold <> PrevBold then
              NeedUpdate := True;
            if Expanded <> PrevExpanded then
              NeedUpdate := True;
            if Selected <> PrevSelected then
              NeedInvalidate := True;

            FTreeView.SendItemChangeNofify(TVN_ITEMCHANGEDW, Self, PrevState, NewState);
          end;
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
  //if AItem.mask and TVIF_PARAM <> 0 then // Always
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

procedure TTreeViewItem.FullExpand(ACode, AAction: UINT; ANotify: Boolean);
var
  ItemIndex: Integer;
begin
  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].FullExpand(ACode, AAction, ANotify);
  TreeView.ExpandItem(Self, ACode, AAction, ANotify);
end;

function TTreeViewItem.ExpandParents(AAction: UINT): Boolean;
begin
  Result := True;
  if Assigned(FParentItems.FParent) then
    begin
      Result := FParentItems.FParent.ExpandParents(AAction);
      if Result then
        Result := TreeView.ExpandItem(FParentItems.FParent, TVE_EXPAND, AAction, True);
    end;
end;

procedure TTreeViewItem.SavePositionForAnimation;
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  FPrevLeft := FLeft;
  FPrevTop := FTop;
  if Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].SavePositionForAnimation
  else
    if Self = TreeView.AnimationCollapseItem then
      for ItemIndex := 0 to Count - 1 do
        begin
          Item := Items[ItemIndex];
          Item.FPrevLeft := Item.FLeft;
          Item.FPrevTop := Item.FTop;
        end;
end;

procedure TTreeViewItem.PreparePositionsForExpandAnimation(ADelta: Integer);
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  for ItemIndex := 0 to Count - 1 do
    begin
      Item := Items[ItemIndex];
      Item.FPrevLeft := Item.FLeft;
      Item.FPrevTop := Item.FTop + ADelta;
    end;
end;

procedure TTreeViewItem.PreparePositionsForCollapseAnimation(ADelta: Integer);
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  for ItemIndex := 0 to Count - 1 do
    begin
      Item := Items[ItemIndex];
      Item.FLeft := Item.FPrevLeft;
      Item.FTop := Item.FPrevTop + ADelta;
    end;
end;

procedure TTreeViewItem.UpdateSize(ADC: HDC);
var
  S: UnicodeString;
  R: TRect;
  SaveFont: HFONT;
  ItemIndex: Integer;
  ButtonSize: TSize;
  NMTVCustomDraw: TNMTVCustomDraw;
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

      ZeroMemory(@NMTVCustomDraw, SizeOf(NMTVCustomDraw));
      NMTVCustomDraw.nmcd.hdc := ADC;
      NMTVCustomDraw.nmcd.rc.Right := FWidth;
      NMTVCustomDraw.nmcd.rc.Bottom := FHeight;
      NMTVCustomDraw.nmcd.dwItemSpec := {$IFDEF WIN64}DWORD_PTR(Self){$ELSE}DWORD(Self){$ENDIF};
      NMTVCustomDraw.nmcd.lItemlParam := FParam;
      NMTVCustomDraw.iLevel := Level;
      if FTreeView.SendNotify(TVN_GETITEMSIZE, @NMTVCustomDraw) <> 0 then
        begin
          FWidth := NMTVCustomDraw.nmcd.rc.Right;
          FHeight := NMTVCustomDraw.nmcd.rc.Bottom;
        end;

      FNeedUpdateSize := False;
    end;

  if Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].UpdateSize(ADC);
end;

procedure TTreeViewItem.InitCheckBoxState;
var
  PrevState: UINT;
  NewState: UINT;
  ItemIndex: Integer;
begin
  if StateIndex <> 1 then
    begin
      PrevState := FState;
      StateIndex := 1;
      NewState := FState;
      FState := PrevState;
      if not TreeView.SendItemChangeNofify(TVN_ITEMCHANGINGW, Self, PrevState, NewState) then
        begin
          FState := NewState;
          TreeView.SendItemChangeNofify(TVN_ITEMCHANGEDW, Self, PrevState, NewState);
        end;
    end;

  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].InitCheckBoxState;
end;

procedure TTreeViewItem.SelectNextCheckState;
var
  NMTVStateImageChanging: TNMTVStateImageChanging;
  PrevState: UINT;
  NewState: UINT;
  IconIndex: Integer;
begin
  IconIndex := StateIndex;
  NMTVStateImageChanging.hti := HTREEITEM(Self);
  NMTVStateImageChanging.iOldStateImageIndex := IconIndex;
  Inc(IconIndex);
  if TreeView.StateImageList <> 0 then
    begin
      if IconIndex = ImageList_GetImageCount(TreeView.StateImageList) then
        IconIndex := 1
    end
  else
    begin
      if IconIndex = TreeView.FCheckBoxStateCount + 1 then
        IconIndex := 1;
    end;
  PrevState := FState;
  StateIndex := IconIndex;
  NewState := FState;
  FState := PrevState;
  NMTVStateImageChanging.iNewStateImageIndex := IconIndex;
  TreeView.SendNotify(NM_TVSTATEIMAGECHANGING, @NMTVStateImageChanging);
  if not TreeView.SendItemChangeNofify(TVN_ITEMCHANGINGW, Self, PrevState, NewState) then
    begin
      FState := NewState;
      TreeView.SendItemChangeNofify(TVN_ITEMCHANGEDW, Self, PrevState, NewState);
      Invalidate;
      if StateIndex = 0 then
        begin
          NeedUpdateSize;
          TreeView.Update;
        end;
    end;
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

procedure TTreeViewItem.PaintConnector(ADC: HDC; AGdiCache: TGdiCache; AIndex: Integer; ADest: TTreeViewItem);
var
  Points: packed array[0..3] of TPoint;
begin
  Points[0].X := Right;
  Points[3].X := ADest.Left;
  if Self = TreeView.AnimationExpandItem then
    Points[3].X := TreeView.CalcAnimation(Points[0].X, Points[3].X)
  else
    if Self = TreeView.AnimationCollapseItem then
      Points[3].X := TreeView.CalcAnimation(Points[3].X, Points[0].X);
  Points[1].X := Points[0].X + (Points[3].X - Points[0].X) div 2;
  Points[2].X := Points[1].X;

  Points[0].Y := Top + Round((Height / (Count + 1)) * (AIndex + 1));
  Points[3].Y := ADest.Top + Round(ADest.Height / 2);
  if Self = TreeView.AnimationExpandItem then
    Points[3].Y := TreeView.CalcAnimation(Points[0].Y, Points[3].Y)
  else
    if Self = TreeView.AnimationCollapseItem then
      Points[3].Y := TreeView.CalcAnimation(Points[3].Y, Points[0].Y);
  Points[1].Y := Points[0].Y;
  Points[2].Y := Points[3].Y;

  FTreeView.PolyBezier(ADC, AGdiCache, Points, 4);
end;

procedure TTreeViewItem.PrePaintConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN);
var
  ConnectorRect: TRect;
  ItemIndex: Integer;
  Item: TTreeViewItem;
  TempRgn: HRGN;
begin
  if (Expanded or (Self = TreeView.AnimationExpandItem) or (Self = TreeView.AnimationCollapseItem)) and (Count > 0) then
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
          FillRect(ADC, ConnectorRect, AGdiCache.ColorBrush);
          TempRgn := CreateRectRgnIndirect(ConnectorRect);
          CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
          DeleteObject(TempRgn);
        end;
    end;

  if (TreeView.AnimationExpandItem <> Self) and Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].PrePaintConnectors(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn);
end;

procedure TTreeViewItem.PaintConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn: HRGN);
var
  ConnectorRect: TRect;
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  if (Expanded or (Self = TreeView.AnimationExpandItem) or (Self = TreeView.AnimationCollapseItem)) and (Count > 0) then
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
          for ItemIndex := 0 to Count - 1 do
            begin
              Item := Items[ItemIndex];
              ConnectorRect.Top := Min(Top, Item.Top);
              ConnectorRect.Bottom := Max(Bottom, Item.Bottom);
              if RectInRegion(AUpdateRgn, ConnectorRect) then
                PaintConnector(ADC, AGdiCache, ItemIndex, Item);
            end;
        end;
    end;

  if (TreeView.AnimationExpandItem <> Self) and Expanded then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].PaintConnectors(ADC, AGdiCache, AUpdateRgn);
end;

procedure TTreeViewItem.PaintBackground(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect; out AFontColor: TColorRef);
var
  StateID: Integer;
  BackgroudBrush: HBRUSH;
begin
  AFontColor := TreeView.TextColor;
  if TreeView.Themed and TreeView.TreeItemThemeExist then
    begin
      FillRect(ADC, ARect, AGdiCache.ColorBrush);

      if (TreeView.TrackSelect and (TreeView.HotItem = Self)) or (TreeView.DropItem = Self) then
        StateID := TREIS_HOTSELECTED
      else
        StateID := TREIS_NORMAL;
      if not Enabled then
        begin
          StateID := TREIS_DISABLED;
          GetThemeColor(TreeView.Theme, TVP_TREEITEM, TREIS_DISABLED, 3803 {TMT_TEXTCOLOR}, AFontColor);
        end
      else
        if Selected then
          begin
            if TreeView.Focused then
              StateID := TREIS_SELECTED
            else
              if TreeView.AlwaysShowSelection then
                begin
                  StateID := TREIS_SELECTED;
                  if IsThemePartDefined(TreeView.Theme, TVP_TREEITEM, TREIS_SELECTEDNOTFOCUS) then
                    StateID := TREIS_SELECTEDNOTFOCUS;
                end;
          end;
      if StateID <> TREIS_NORMAL then
        DrawThemeBackground(TreeView.Theme, ADC, TVP_TREEITEM, StateID, ARect, nil);
    end
  else
    begin
      BackgroudBrush := AGdiCache.ColorBrush;
      if not Enabled then
        AFontColor := GetSysColor(COLOR_GRAYTEXT)
      else
        if Selected then
          begin
            if TreeView.Focused then
              begin
                BackgroudBrush := AGdiCache.HighlightBrush;
                AFontColor := GetSysColor(COLOR_HIGHLIGHTTEXT);
              end
            else
              if TreeView.AlwaysShowSelection then
                BackgroudBrush := AGdiCache.ButtonFaceBrush;
          end
        else
          if TreeView.DropItem = Self then
            begin
              BackgroudBrush := AGdiCache.HighlightBrush;
              AFontColor := GetSysColor(COLOR_HIGHLIGHTTEXT);
            end;
      FillRect(ADC, ARect, BackgroudBrush);
    end;
end;

procedure TTreeViewItem.PaintStateIcon(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect);
var
  IconIndex: Integer;
  StateId: Integer;
  Flags: UINT;
  Pen: HPEN;
  SavePen: HPEN;
  NeedPaintExclude: Boolean;
begin
  IconIndex := StateIndex;
  if TreeView.StateImageList <> 0 then
    ImageList_Draw(TreeView.StateImageList, IconIndex, ADC, ARect.Left, ARect.Top, ILD_NORMAL)
  else
    begin
      {$IFDEF DEBUG}
      if (IconIndex < 1) or (IconIndex > TreeView.FCheckBoxStateCount) then
        RaiseLastOSError(ERROR_INVALID_DATA);
      {$ENDIF}
      StateId := TreeView.FCheckBoxStates[IconIndex];
      NeedPaintExclude := False;
      if TreeView.CheckBoxThemeExist then
        begin
          if not IsVistaOrLater then
            case StateId of
              CBS_IMPLICITNORMAL:
                StateId := CBS_CHECKEDNORMAL;
              CBS_EXCLUDEDNORMAL:
                begin
                  StateId := CBS_UNCHECKEDNORMAL;
                  NeedPaintExclude := True;
                end;
            end;
          if PressCheckBox and HotCheckBox then
            Inc(StateId, 2)
          else
            if HotCheckBox then
              Inc(StateId, 1);
          DrawThemeBackground(TreeView.CheckBoxTheme, ADC, BP_CHECKBOX, StateId, ARect, nil)
        end
      else
        begin
          Flags := DFCS_FLAT or DFCS_BUTTONCHECK;
          case StateId of
            CBS_UNCHECKEDNORMAL:;
            CBS_CHECKEDNORMAL:
              Flags := Flags or DFCS_CHECKED;
            CBS_MIXEDNORMAL:
              Flags := Flags or DFCS_CHECKED or DFCS_BUTTON3STATE;
            CBS_IMPLICITNORMAL:
              Flags := Flags or DFCS_CHECKED;
            CBS_EXCLUDEDNORMAL:
              NeedPaintExclude := True;
          end;
          DrawFrameControl(ADC, ARect, DFC_BUTTON, Flags);
        end;

      if NeedPaintExclude then
        begin
          Pen := AGdiCache.CheckBoxExcludePen;
          SavePen := SelectObject(ADC, Pen);
          MoveToEx(ADC, ARect.Left + 3, ARect.Top + 3, nil);
          LineTo(ADC, ARect.Right - 3, ARect.Bottom - 3);
          MoveToEx(ADC, ARect.Left + 3, ARect.Bottom - 4, nil);
          LineTo(ADC, ARect.Right - 3, ARect.Top + 2);
          SelectObject(ADC, SavePen);
        end;
    end;
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

procedure TTreeViewItem.PaintButton(ADC: HDC; AGdiCache: TGdiCache; const ARect: TRect);
var
  PartID: Integer;
  StateID: Integer;
  Pen: HPEN;
  SavePen: HPEN;
  X, Y: Integer;
begin
  if HasButton then
    if TreeView.Themed and TreeView.ButtonThemeExist then
      begin
        if HotButton and TreeView.HotButtonThemeExist then PartID := TVP_HOTGLYPH
                                                      else PartID := TVP_GLYPH;
        if Expanded then StateID := GLPS_OPENED
                    else StateID := GLPS_CLOSED;
        DrawThemeBackground(TreeView.Theme, ADC, PartID, StateID, ARect, nil);
      end
    else
      begin
        FillRect(ADC, ARect, AGdiCache.ColorBrush);
        FrameRect(ADC, ARect, AGdiCache.GrayTextBrush);
        Pen := AGdiCache.TextColorPen;
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
      end;
end;

procedure TTreeViewItem.Paint(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN; AXOffset, AYOffset: Integer; AEraseBackground: Boolean);
var
  TempRgn: HRGN;
  ItemRect: TRect;
  NMTVCustomDraw: TNMTVCustomDraw;
  PaintRequest: UINT;
  ItemIndex: Integer;
  FontColor: TColorRef;
  R: TRect;
  PaintFocus: Boolean;
begin
  ItemRect := BoundsRect;
  if RectInRegion(AUpdateRgn, ItemRect) then
    begin
      PaintBackground(ADC, AGdiCache, ItemRect, FontColor);

      if TreeView.Focused and (Self = FTreeView.FocusedItem) then
        PaintFocus := not TreeView.FHideFocus
      else
        PaintFocus := False;

      ZeroMemory(@NMTVCustomDraw, SizeOf(NMTVCustomDraw));
      NMTVCustomDraw.clrText := FontColor;
      NMTVCustomDraw.clrTextBk := CLR_NONE;

      if FTreeView.FPaintRequest and CDRF_NOTIFYITEMDRAW <> 0 then
        begin
          NMTVCustomDraw.nmcd.rc := BoundsRect;
          OffsetRect(NMTVCustomDraw.nmcd.rc, -AXOffset, -AYOffset);
          NMTVCustomDraw.nmcd.dwItemSpec := {$IFDEF WIN64}DWORD_PTR(Self){$ELSE}DWORD(Self){$ENDIF};
          if Selected then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_SELECTED;
          if not Enabled then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_DISABLED;
          if PaintFocus then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_FOCUS;
          if Self = TreeView.HotItem then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_HOT;
          if not Enabled then
            NMTVCustomDraw.nmcd.uItemState := NMTVCustomDraw.nmcd.uItemState or CDIS_GRAYED;
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

          if PaintFocus then DrawFocusRect(ADC, ItemRect)
                        else FrameRect(ADC, ItemRect, AGdiCache.LineBrush);

          if (PaintRequest and TVCDRF_NOIMAGES = 0) and HasStateIcon then
            begin
              R := StateIconRect;
              if RectInRegion(AUpdateRgn, R) then
                PaintStateIcon(ADC, AGdiCache, R);
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
                PaintButton(ADC, AGdiCache, R);
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

          if PaintRequest and CDRF_NOTIFYPOSTPAINT <> 0 then
            FTreeView.SendDrawNotify(ADC, CDDS_ITEMPOSTPAINT, NMTVCustomDraw);
        end;

      if AEraseBackground then
        begin
          TempRgn := CreateRectRgnIndirect(ItemRect);
          CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
          DeleteObject(TempRgn);
        end;
    end;

  if Expanded and (TreeView.AnimationExpandItem <> Self) then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].Paint(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn, AXOffset, AYOffset, AEraseBackground);
end;

procedure TTreeViewItem.MouseMove(const APoint: TPoint);
var
  NewHotButton: Boolean;
  NewHotCheckBox: Boolean;
begin
  NewHotButton := False;
  NewHotCheckBox := False;
  if HasButton and TreeView.Themed and TreeView.HotButtonThemeExist then
    NewHotButton := PtInRect(ButtonRect, APoint);
  if HasStateIcon and TreeView.CheckBoxes and (TreeView.StateImageList = 0) and TreeView.CheckBoxThemeExist then
    NewHotCheckBox := PtInRect(StateIconRect, APoint);
  HotButton := NewHotButton;
  HotCheckBox := NewHotCheckBox;
end;

procedure TTreeViewItem.MouseLeave;
begin
  HotButton := False;
  HotCheckBox := False;
end;

function TTreeViewItem.HasStateIcon: Boolean;
var
  IconIndex: Integer;
begin
  Result := FState and TVIS_STATEIMAGEMASK <> 0;
  if Result then
    begin
      Result := TreeView.StateImageList <> 0;
      if not Result then
        begin
          IconIndex := StateIndex;
          Result := (IconIndex > 0) and (IconIndex <= TreeView.FCheckBoxStateCount);
        end;
    end;
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
  case Kids of
    kCompute: Result := Count > 0;
    kCallback:
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
    kForceNo: Result := False;
  else
    Result := True;
  end;
end;

function TTreeViewItem.GetHasChildrenWithoutCallback: Integer;
begin
  case FKids of
    kCompute: Result := Count;
    kCallback: Result := -1;
    kForceNo: Result := 0;
  else
    Result := Count;
  end;
end;

function TTreeViewItem.GetStateIndex: Integer;
begin
  Result := (FState and TVIS_STATEIMAGEMASK) shr 12;
end;

procedure TTreeViewItem.SetStateIndex(AStateIndex: Integer);
begin
  FState := FState and not TVIS_STATEIMAGEMASK;
  FState := FState or ((UINT(AStateIndex) shl 12) and TVIS_STATEIMAGEMASK);
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

function TTreeViewItem.GetLeft: Integer;
begin
  if TreeView.AnimationMode = amNone then
    Result := FLeft
  else
    Result := TreeView.CalcAnimation(FPrevLeft, FLeft);
end;

function TTreeViewItem.GetTop: Integer;
begin
  if TreeView.AnimationMode = amNone then
    Result := FTop
  else
    Result := TreeView.CalcAnimation(FPrevTop, FTop);
end;

function TTreeViewItem.GetRight: Integer;
begin
  Result := Left + Width;
end;

function TTreeViewItem.GetBottom: Integer;
begin
  Result := Top + Height;
end;

function TTreeViewItem.GetBoundsRect: TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Left + Width;
  Result.Bottom := Top + Height;
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

procedure TTreeViewItem.SetHotButton(AHotButton: Boolean);
begin
  if FHotButton = AHotButton then Exit;
  FHotButton := AHotButton;
  if HasButton then
    TreeView.InvalidateItemButton(Self);
end;

procedure TTreeViewItem.SetHotCheckBox(AHotCheckBox: Boolean);
begin
  if FHotCheckBox = AHotCheckBox then Exit;
  FHotCheckBox := AHotCheckBox;
  if HasStateIcon then
    TreeView.InvalidateItemCheckBox(Self);
end;

procedure TTreeViewItem.SetPressCheckBox(APressCheckBox: Boolean);
begin
  if FPressCheckBox = APressCheckBox then Exit;
  FPressCheckBox := APressCheckBox;
  if HasStateIcon then
    TreeView.InvalidateItemCheckBox(Self);
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
  if AInsertAfter = TTreeViewItem(TVI_FIRST) then
    Pos := 0
  else
    if not Assigned(AInsertAfter) or (AInsertAfter = TTreeViewItem(TVI_LAST)) then
      Pos := Count
    else
      if AInsertAfter = TTreeViewItem(TVI_SORT) then
        Pos := Count
      else
        if AInsertAfter = TTreeViewItem(TVI_ROOT) then
          Exit
        else
          begin
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
  if TreeView.CheckBoxes and (Result.StateIndex = 0) then
    Result.StateIndex := 1;
  if AItem.mask and TVIF_STATEEX <> 0 then
    Result.FStateEx := AItem.uStateEx;
  if AItem.mask and TVIF_INTEGRAL <> 0 then
    Result.FIntegral := AItem.iIntegral;
  if AItem.mask and TVIF_CHILDREN <> 0 then
    begin
      Result.FChildren := AItem.cChildren;
      case AItem.cChildren of
        I_CHILDRENAUTO:
          Result.FKids := kCompute;
        I_CHILDRENCALLBACK:
          Result.FKids := kCallback;
        0:
          Result.FKids := kForceNo;
      else
        Result.FKids := kForceYes;
      end;
    end;

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
  Position: Integer;
  CopyCount: Integer;
  Source, Dest: Pointer;
  ItemSize: Integer;
  NewSelectItem: TTreeViewItem;
begin
  for ItemIndex := AItem.Count - 1 downto 0 do
    AItem.Items_.DeleteItem(AItem.Items[ItemIndex]);

  TreeView.SendTreeViewNotify(TVN_DELETEITEMW, AItem, nil, 0);

  if TreeView.FocusedItem = AItem then
    begin
      if AItem.Index_ < Count - 1 then
        NewSelectItem := Items[AItem.Index_ + 1]
      else
        if AItem.Index_ > 0 then
          NewSelectItem := Items[AItem.Index_ - 1]
        else
          NewSelectItem := Parent;
      TreeView.SelectItem(NewSelectItem, True, 0, False);
    end;

  if TreeView.FocusedItem = AItem then TreeView.FFocusedItem := nil;
  if TreeView.FixedItem = AItem then TreeView.FFixedItem := nil;
  if TreeView.ScrollItem = AItem then TreeView.FScrollItem := nil;
  if TreeView.InsertMaskItem = AItem then TreeView.FInsertMaskItem := nil;
  if TreeView.HotItem = AItem then TreeView.FHotItem := nil;
  if TreeView.PressedItem = AItem then TreeView.FPressedItem := nil;
  if TreeView.DropItem = AItem then TreeView.FDropItem := nil;

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
  FIndent := 19;
  FItemHeight := 19;
end;

destructor TTreeView.Destroy;
begin
  FDestroying := True;
  if Assigned(FItems) then
    FItems.Free;
  if Assigned(FTempTextBuffer) then
    FreeMem(FTempTextBuffer);
  if FBufferedPaintInited then
    if Succeeded(FBufferedPaintInitResult) then
      BufferedPaintUnInit;
  inherited Destroy;
end;

function TTreeView.HasBorder: Boolean;
begin
  Result := Border or ClientEdge;
end;

{$IFDEF NATIVE_BORDERS}
procedure TTreeView.CaclClientRect(ARect, AClientRect: PRect);
var
  SW: Integer;
begin
  if HasBorder then
    GetThemeBackgroundContentRect(Theme, 0, 0, 0, ARect^, AClientRect)
  else
    AClientRect^ := ARect^;
  if not NoScroll then
    begin
      if IsHorzScrollBarVisible then
        begin
          SW := GetSystemMetricsForDpi_(SM_CYHSCROLL, Dpi, True);
          Dec(AClientRect.Bottom, SW);
        end;
      if IsVertScrollBarVisible then
        begin
          SW := GetSystemMetricsForDpi_(SM_CXVSCROLL, Dpi, True);
          if FStyleEx and WS_EX_LEFTSCROLLBAR = 0 then Dec(AClientRect.Right, SW)
                                                  else Inc(AClientRect.Left, SW);
        end;
    end;
end;
{$ENDIF}

function TTreeView.PaintBorders(AClipRgn: HRGN): LRESULT;
var
  DC: HDC;
  {$IFNDEF NATIVE_BORDERS}
  HozEdge, VertEdge: Integer;
  {$ENDIF}
  WindowRect: TRect;
  ClientRect: TRect;
  ClipRgn2: HRGN;
  TempRgn: HRGN;
begin
  if not Themed or not HasBorder then
    Result := DefWindowProc(FHandle, WM_NCPAINT, AClipRgn, 0)
  else
    begin
      GetWindowRect(FHandle, WindowRect);
      if AClipRgn = NULLREGION then ClipRgn2 := CreateRectRgnIndirect(WindowRect)
                               else ClipRgn2 := AClipRgn;

      {$IFDEF NATIVE_BORDERS}
      GetThemeBackgroundContentRect(Theme, 0, 0, 0, WindowRect, @ClientRect);
      {$ELSE}
      HozEdge := GetSystemMetrics(SM_CXEDGE);
      VertEdge := GetSystemMetrics(SM_CYEDGE);
      ClientRect.Left := WindowRect.Left + HozEdge;
      ClientRect.Top := WindowRect.Top + VertEdge;
      ClientRect.Right := WindowRect.Right - HozEdge;
      ClientRect.Bottom := WindowRect.Bottom - VertEdge;
      {$ENDIF}

      with ClientRect do
        TempRgn := CreateRectRgn(Left, Top, Right, Bottom);
      CombineRgn(ClipRgn2, ClipRgn2, TempRgn, RGN_AND);
      DeleteObject(TempRgn);

      OffsetRect(ClientRect, -WindowRect.Left, -WindowRect.Top);
      OffsetRect(WindowRect, -WindowRect.Left, -WindowRect.Top);

      {TempRgn := CreateRectRgn(0, 0, 0, 0);
      CombineRgn(TempRgn, ClipRgn2, 0, RGN_COPY);
      DC := GetDCEx(FHandle, TempRgn, DCX_WINDOW or DCX_INTERSECTRGN);
      if DC = 0 then} DC := GetWindowDC(FHandle);
      with ClientRect do
        ExcludeClipRect(DC, Left, Top, Right, Bottom);

      if IsThemeBackgroundPartiallyTransparent(FTheme, 0, 0) then
        DrawThemeParentBackground(FHandle, DC, @WindowRect);
      DrawThemeBackground(Theme, DC, 0, 0, WindowRect, nil);
      //FillRectWithColor(DC, rect, $FF);
      ReleaseDC(FHandle, DC);

      Result := DefWindowProc(FHandle, WM_NCPAINT, ClipRgn2, 0);
      if ClipRgn2 <> AClipRgn then
        DeleteObject(ClipRgn2);
    end;
end;

function TTreeView.GetScrollInfo(ABar: Integer; var AScrollInfo: TScrollInfo): Boolean;
begin
  if NoScroll then
    case ABar of
      SB_HORZ:
        begin
          AScrollInfo := FHorzScrollInfo;
          Result := True;
        end;
      SB_VERT:
        begin
          AScrollInfo := FVertScrollInfo;
          Result := True;
        end;
    else
      Result := False;
    end
  else
    begin
      AScrollInfo.cbSize := SizeOf(AScrollInfo);
      Result := Windows.GetScrollInfo(FHandle, ABar, AScrollInfo);
    end;
end;

function TTreeView.SetScrollInfo(ABar: Integer; var AScrollInfo: TScrollInfo): Integer;

  procedure Assign(var AScrollInfo, ADestScrollInfo: TScrollInfo);
  begin
    if AScrollInfo.fMask and SIF_RANGE <> 0 then
      begin
        ADestScrollInfo.nMin := AScrollInfo.nMin;
        ADestScrollInfo.nMax := AScrollInfo.nMax;
      end;
    if AScrollInfo.fMask and SIF_PAGE <> 0 then
      ADestScrollInfo.nPage := Max(0, Min(AScrollInfo.nPage, ADestScrollInfo.nMax - ADestScrollInfo.nMin));
    if AScrollInfo.fMask and SIF_POS <> 0 then
      ADestScrollInfo.nPos := Max(0, Min(AScrollInfo.nPos, ADestScrollInfo.nMax - ADestScrollInfo.nMin - Integer(ADestScrollInfo.nPage)));
  end;

begin
  if NoScroll then
    case ABar of
      SB_HORZ:
        begin
          Assign(AScrollInfo, FHorzScrollInfo);
          Result := FHorzScrollInfo.nPos;
        end;
      SB_VERT:
        begin
          Assign(AScrollInfo, FVertScrollInfo);
          Result := FVertScrollInfo.nPos;
        end;
    else
      Result := 0;
    end
  else
    begin
      AScrollInfo.cbSize := SizeOf(AScrollInfo);
      Result := Windows.SetScrollInfo(FHandle, ABar, AScrollInfo, True);
    end;
end;

function TTreeView.SetScrollPos(ABar, APos: Integer): Integer;
begin
  if NoScroll then
    case ABar of
      SB_HORZ:
        begin
          Result := FHorzScrollInfo.nPos;
          with FHorzScrollInfo do
            nPos := Max(0, Min(APos, nMax - nMin - Integer(nPage)));
        end;
      SB_VERT:
        begin
          Result := FVertScrollInfo.nPos;
          with FVertScrollInfo do
            nPos := Max(0, Min(APos, nMax - nMin - Integer(nPage)));
        end;
    else
      Result := 0;
    end
  else
    Result := Windows.SetScrollPos(FHandle, ABar, APos, True);
end;

function TTreeView.GetScrollPos(ABar: Integer): Integer;
begin
  if NoScroll then
    case ABar of
      SB_HORZ:
        Result := FHorzScrollInfo.nPos;
      SB_VERT:
        Result := FVertScrollInfo.nPos;
    else
      Result := 0;
    end
  else
    Result := Windows.GetScrollPos(FHandle, ABar);
end;

function TTreeView.PixelsPerLine: UINT;
begin
  Result := (DPI * 10) div 96;
end;

function TTreeView.IsRealScrollBarVisible(ABar: DWORD): Boolean;
var
  ScrollBarInfo: TScrollBarInfo;
begin
  ScrollBarInfo.cbSize := SizeOf(ScrollBarInfo);
  Result := GetScrollBarInfo(FHandle, ABar, ScrollBarInfo);
  if Result then
    Result := ScrollBarInfo.rgstate[0] and STATE_SYSTEM_INVISIBLE = 0;
end;

function TTreeView.IsRealHorzScrollBarVisible: Boolean;
begin
  Result := IsRealScrollBarVisible(OBJID_HSCROLL);
end;

function TTreeView.IsRealVertScrollBarVisible: Boolean;
begin
  Result := IsRealScrollBarVisible(OBJID_VSCROLL);
end;

function TTreeView.IsScrollBarVisible(ABar: DWORD): Boolean;
begin
  if NoScroll then
    begin
      case ABar of
        OBJID_HSCROLL:
          with FHorzScrollInfo do
            Result := Integer(nPage) < (nMax - nMin);
        OBJID_VSCROLL:
          with FVertScrollInfo do
            Result := Integer(nPage) < (nMax - nMin);
      else
        Result := False;
      end;
    end
  else
    Result := IsRealScrollBarVisible(ABar);
end;

function TTreeView.IsHorzScrollBarVisible: Boolean;
begin
  Result := IsScrollBarVisible(OBJID_HSCROLL);
end;

function TTreeView.IsVertScrollBarVisible: Boolean;
begin
  Result := IsScrollBarVisible(OBJID_VSCROLL);
end;

procedure TTreeView.UpdateScrollBarsEx(AClientWidth, AClientHeight: Integer);
var
  ClientRect: TRect;
  ScrollInfo: TScrollInfo;
  XPos, YPos: Double;
  OptimalWidth: Integer;
  OptimalHeight: Integer;
  NeedVertScrollBar, NeedHorzScrollBar: Boolean;
begin
  if FDestroying then Exit;
  if FUpdateScrollBars then Exit;

  FUpdateScrollBars := True;
  try
    if Assigned(FixedItem) then
      OffsetItemRect(FixedItemRect);

    GetClientRect(FHandle, ClientRect);
    AClientWidth := ClientRect.Right - ClientRect.Left;
    AClientHeight := ClientRect.Bottom - ClientRect.Top;

    XPos := 0;
    YPos := 0;

    if IsRealVertScrollBarVisible then
      Inc(AClientWidth, FCXVScroll);
    if IsVertScrollBarVisible then
      begin
        ScrollInfo.cbSize := SizeOf(ScrollInfo);
        ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
        GetScrollInfo(SB_VERT, ScrollInfo);
        with ScrollInfo do
          if nMax > nMin then
            YPos := (nPos + nPage / 2) / (nMax - nMin);
      end;

    if IsRealHorzScrollBarVisible then
      Inc(AClientHeight, FCYHScroll);
    if IsHorzScrollBarVisible then
      begin
        ScrollInfo.cbSize := SizeOf(ScrollInfo);
        ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
        GetScrollInfo(SB_HORZ, ScrollInfo);
        with ScrollInfo do
          if nMax > nMin then
            XPos := (nPos + nPage / 2) / (nMax - nMin);
      end;

    if AClientWidth = 0 then exit;
    if AClientHeight = 0 then exit;

    if AnimationMode = amNone then
      begin
        OptimalWidth := FOptimalWidth;
        OptimalHeight := FOptimalHeight;
      end
    else
      begin
        OptimalWidth := CalcAnimation(FPrevOptimalWidth, FOptimalWidth);
        OptimalHeight := CalcAnimation(FPrevOptimalHeight, FOptimalHeight);
      end;

    NeedVertScrollBar := OptimalHeight > AClientHeight;
    if not NoScroll and NeedVertScrollBar then
      Dec(AClientWidth, FCXVScroll);
    NeedHorzScrollBar := OptimalWidth > AClientWidth;
    if not NoScroll and NeedHorzScrollBar then
      Dec(AClientHeight, FCYHScroll);
    if not NeedVertScrollBar then
      begin
        NeedVertScrollBar := OptimalHeight > AClientHeight;
        if not NoScroll and NeedVertScrollBar then
          Dec(AClientWidth, FCXVScroll);
      end;

    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
    ScrollInfo.nMin := 0;

    if NeedVertScrollBar then
      begin
        ScrollInfo.nMax := OptimalHeight;
        ScrollInfo.nPage := AClientHeight;
        if Assigned(FixedItem) then
          begin
            ScrollInfo.nPos := FixedItem.Top - FixedItemRect.Top;
            ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
            ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          end
        else
          ScrollInfo.nPos := Round(YPos * ScrollInfo.nMax - Integer(ScrollInfo.nPage) / 2);
      end
    else
      ScrollInfo.nMax := 0;
    SetScrollInfo(SB_VERT, ScrollInfo);

    if NeedHorzScrollBar then
      begin
        ScrollInfo.nMax := OptimalWidth;
        ScrollInfo.nPage := AClientWidth;
        if Assigned(FixedItem) then
          begin
            ScrollInfo.nPos := FixedItem.Left - FixedItemRect.Left;
            ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
            ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          end
        else
          ScrollInfo.nPos := Round(XPos * ScrollInfo.nMax - Integer(ScrollInfo.nPage) / 2);
      end
    else
      ScrollInfo.nMax := 0;
    SetScrollInfo(SB_HORZ, ScrollInfo);
    FixedItem := nil;
  finally
    FUpdateScrollBars := False;
  end;
end;

procedure TTreeView.UpdateScrollBars(AMouseMove: Boolean = True);
var
  ClientRect: TRect;
  ClientWidth, ClientHeight: integer;
begin
  if FDestroying then Exit;
  if FUpdateScrollBars then Exit;

  GetClientRect(FHandle, ClientRect);
  ClientWidth := ClientRect.Right - ClientRect.Left;
  ClientHeight := ClientRect.Bottom - ClientRect.Top;
  UpdateScrollBarsEx(ClientWidth, ClientHeight);
  if AMouseMove then
    MouseMove(GetClientCursorPos);
end;

procedure TTreeView.NoScrollBarChanged;
var
  XPos, YPos: Integer;
  ScrollInfo: TScrollInfo;
  PrevXOffset, PrevYOffset: Integer;
  XOffset, YOffset: Integer;
begin
  FResizeMode := True;
  try
    FNoScroll := not FNoScroll;
    CalcBaseOffsets(PrevXOffset, PrevYOffset);
    XPos := GetScrollPos(SB_HORZ);
    YPos := GetScrollPos(SB_VERT);
    FNoScroll := not FNoScroll;
    if NoScroll then
      begin
        ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
        ScrollInfo.cbSize := SizeOf(ScrollInfo);
        ScrollInfo.fMask := SIF_RANGE;
        Windows.SetScrollInfo(FHandle, SB_HORZ, ScrollInfo, True);
        Windows.SetScrollInfo(FHandle, SB_VERT, ScrollInfo, True);
      end;

    UpdateScrollBars;
    SetScrollPos(SB_HORZ, XPos);
    SetScrollPos(SB_VERT, YPos);

    CalcBaseOffsets(XOffset, YOffset);
    if (XOffset <> PrevXOffset) or (YOffset <> PrevYOffset) then
      ScrollWindowEx(FHandle, XOffset - PrevXOffset, YOffset - PrevYOffset, nil, nil, 0, nil, SW_INVALIDATE);
  finally
    FResizeMode := False;
  end;
end;

procedure TTreeView.ScrollMessage(AReason: WPARAM; ABar: DWORD);
var
  ScrollInfo: TScrollInfo;
  NewPos: Integer;
  X, Y: Integer;
begin
  if FDestroying then Exit;

  ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE or SIF_TRACKPOS;
  if not GetScrollInfo(ABar, ScrollInfo) then Exit;

  NewPos := ScrollInfo.nPos;
  case LoWord(AReason) of
    TB_LINEUP:
      Dec(NewPos, PixelsPerLine);
    TB_LINEDOWN:
      Inc(NewPos, PixelsPerLine);
    TB_PAGEUP:
      Dec(NewPos, ScrollInfo.nPage);
    TB_PAGEDOWN:
      Inc(NewPos, ScrollInfo.nPage);
    TB_THUMBPOSITION,
    TB_THUMBTRACK:
      begin
        //NewPos := HiWord(AReason);
        NewPos := ScrollInfo.nTrackPos;
      end;
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
      SetScrollPos(ABar, NewPos);
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
  Optimal: Integer;
begin
  GetClientRect(FHandle, ClientRect);

  if IsHorzScrollBarVisible then
    AXOffset := -GetScrollPos(SB_HORZ)
  else
    if AutoCenter then
      begin
        if AnimationMode <> amNone then
          Optimal := CalcAnimation(FPrevOptimalWidth, FOptimalWidth)
        else
          Optimal := FOptimalWidth;
        AXOffset := (ClientRect.Right - ClientRect.Left - Optimal) div 2
      end
    else
      AXOffset := 0;

  if IsVertScrollBarVisible then
    AYOffset := -GetScrollPos(SB_VERT)
  else
    if AutoCenter then
      begin
        if AnimationMode <> amNone then
          Optimal := CalcAnimation(FPrevOptimalHeight, FOptimalHeight)
        else
          Optimal := FOptimalHeight;
        AYOffset := (ClientRect.Bottom - ClientRect.Top - Optimal) div 2
      end
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

procedure TTreeView.PolyBezier(ADC: HDC; AGdiCache: TGdiCache; const APoints; ACount: DWORD);
var
  GdiPlusDC: HDC;
  Pen: HPEN;
  SavePen: HPEN;
begin
  if ACount = 0 then Exit;

  GdiPlusDC := AGdiCache.GdiPlusDC;
  if GdiPlusDC <> 0 then
    begin
      Pen := AGdiCache.GdiPlusLineColorPen;
      GdipSetSmoothingMode(GdiPlusDC, SmoothingModeHighQuality);
      GdipDrawBeziersI(GdiPlusDC, Pen, @APoints, ACount);
    end
  else
    begin
      Pen := AGdiCache.LinePen;
      SavePen := SelectObject(ADC, Pen);
      Windows.PolyBezier(ADC, APoints, 4);
      SelectObject(ADC, SavePen);
    end;
end;

procedure TTreeView.PaintRootConnector(ADC: HDC; AGdiCache: TGdiCache; ASource, ADest: TTreeViewItem);
var
  Points: packed array[0..3] of TPoint;
begin
  Points[0].X := HorzSpace div 2;
  Points[0].Y := ASource.Top + ASource.Height div 2;
  Points[1].X := Points[0].X - HorzSpace div 2;
  Points[1].Y := Points[0].Y;
  Points[3].X := ADest.Left;
  Points[3].Y := ADest.Top + ADest.Height div 2;
  Points[2].X := Points[3].X - HorzSpace div 2;
  Points[2].Y := Points[3].Y;
  PolyBezier(ADC, AGdiCache, Points, 4);
end;

procedure TTreeView.PrePaintRootConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN);
var
  ConnectorRect: TRect;
  TempRgn: HRGN;
begin
  if not LinesAsRoot or (Count = 0) then Exit;

  ConnectorRect.Left := 0;
  ConnectorRect.Top := Items[0].Top;
  ConnectorRect.Right := HorzSpace div 2;
  ConnectorRect.Bottom := Items[Count - 1].Bottom;
  if RectInRegion(AUpdateRgn, ConnectorRect) then
    begin
      FillRect(ADC, ConnectorRect, AGdiCache.ColorBrush);
      TempRgn := CreateRectRgnIndirect(ConnectorRect);
      CombineRgn(ABackgroupRgn, ABackgroupRgn, TempRgn, RGN_DIFF);
      DeleteObject(TempRgn);
    end;
end;

procedure TTreeView.PaintRootConnectors(ADC: HDC; AGdiCache: TGdiCache; AUpdateRgn, ABackgroupRgn: HRGN; AEraseBackground: Boolean);
var
  ConnectorRect: TRect;
  ItemIndex: Integer;
begin
  if not LinesAsRoot or (Count = 0) then Exit;

  ConnectorRect.Left := 0;
  ConnectorRect.Top := Items[0].Top;
  ConnectorRect.Right := HorzSpace div 2;
  ConnectorRect.Bottom := Items[Count - 1].Bottom;
  if RectInRegion(AUpdateRgn, ConnectorRect) then
    begin
      for ItemIndex := 0 to Count - 2 do
        begin
          ConnectorRect.Top := Items[ItemIndex].Top;
          ConnectorRect.Bottom := Items[ItemIndex + 1].Bottom;
          if RectInRegion(AUpdateRgn, ConnectorRect) then
            PaintRootConnector(ADC, AGdiCache, Items[ItemIndex], Items[ItemIndex + 1]);
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
  DeleteObject(Pen);
end;

procedure TTreeView.PaintTo(ADC: HDC; AGdiCache: TGdiCache; var AUpdateRgn, ABackgroupRgn: HRGN; ASmartEraseBackground: Boolean);
var
  XOffset, YOffset: Integer;
  NMCustomDraw: TNMTVCustomDraw;
  ItemIndex: Integer;
begin
  GetWindowOrgEx(ADC, FSavePoint);
  CalcBaseOffsets(XOffset, YOffset);

  {$IFDEF DEBUG}
  //FillRgnWithColor(ADC, AUpdateRgn, $FF);
  {Sleep(500);{}
  {$ENDIF}

  ZeroMemory(@NMCustomDraw, SizeOf(NMCustomDraw));
  FPaintRequest := SendDrawNotify(ADC, CDDS_PREPAINT, NMCustomDraw);
  if FPaintRequest and CDRF_SKIPDEFAULT = 0 then
    begin
      if ASmartEraseBackground then
        ASmartEraseBackground := FPaintRequest and CDRF_NOTIFYPOSTERASE = 0;

      if not ASmartEraseBackground then
        begin
          {DeleteObject(AUpdateRgn);
          DeleteObject(ABackgroupRgn);
          GetClientRect(FHandle, R);
          AUpdateRgn := CreateRectRgnIndirect(R);
          ABackgroupRgn := CreateRectRgnIndirect(R);}
          FillRgn(ADC, ABackgroupRgn, AGdiCache.ColorBrush);
          SendDrawNotify(ADC, CDDS_POSTERASE, NMCustomDraw);
        end;

      if FPaintRequest and CDRF_DOERASE = 0 then
        begin
          SetWindowOrgEx(ADC, FSavePoint.X - XOffset, FSavePoint.Y - YOffset, nil);
          OffsetRgn(AUpdateRgn, -XOffset, -YOffset);
          OffsetRgn(ABackgroupRgn, -XOffset, -YOffset);

          if ASmartEraseBackground then
            begin
              PrePaintRootConnectors(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn);
              for ItemIndex := 0 to Count - 1 do
                Items[ItemIndex].PrePaintConnectors(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn);
            end;
          PaintRootConnectors(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn, ASmartEraseBackground);
          for ItemIndex := 0 to Count - 1 do
            Items[ItemIndex].PaintConnectors(ADC, AGdiCache, AUpdateRgn);
          AGdiCache.DeleteGdiPlusDC;

          for ItemIndex := 0 to Count - 1 do
            Items[ItemIndex].Paint(ADC, AGdiCache, AUpdateRgn, ABackgroupRgn, XOffset, YOffset, ASmartEraseBackground);

          SetWindowOrgEx(ADC, FSavePoint.X, FSavePoint.Y, nil);
          OffsetRgn(AUpdateRgn, XOffset, YOffset);
          OffsetRgn(ABackgroupRgn, XOffset, YOffset);
        end;

      if ASmartEraseBackground then
        FillRgn(ADC, ABackgroupRgn, AGdiCache.ColorBrush);

      if FPaintRequest and CDRF_NOTIFYPOSTPAINT <> 0 then
        SendDrawNotify(ADC, CDDS_POSTPAINT, NMCustomDraw);
    end;

  if Assigned(InsertMaskItem) and InsertMaskItem.IsVisible then
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
  GdiCache: TGdiCache;
  PaintStruct: TPaintStruct;
  PaintBuffer: HPAINTBUFFER;
  DBWidth, DBHeight: Integer;
  DBDC: HDC;
  DBBitmap: HBITMAP;
  SaveBitmap: HBITMAP;
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
            if FStyle2 and TVS_EX_DOUBLEBUFFER <> 0 then
              if DwmIsCompositionEnabled then
                begin
                  if not FBufferedPaintInited then
                    begin
                      FBufferedPaintInited := True;
                      FBufferedPaintInitResult := BufferedPaintInit;
                    end;
                  PaintBuffer := BeginBufferedPaint(DC, PaintStruct.rcPaint, BPBF_COMPOSITED, nil, DBDC);
                  if PaintBuffer <> 0 then
                    try
                      GdiCache := TGdiCache.Create(Self, DBDC);
                      try
                        PaintTo(DBDC, GdiCache, UpdateRgn, BackgroupRgn, False);
                      finally
                        GdiCache.Free;
                      end;
                      BufferedPaintSetAlpha(PaintBuffer, @PaintStruct.rcPaint, $FF);
                    finally
                      EndBufferedPaint(PaintBuffer, True);
                    end;
                end
              else
                begin
                  DBWidth := PaintStruct.rcPaint.Right - PaintStruct.rcPaint.Left;
                  DBHeight := PaintStruct.rcPaint.Bottom - PaintStruct.rcPaint.Top;
                  DBDC := CreateCompatibleDC(DC);
                  if DBDC <> 0 then
                    try
                      DBBitmap := CreateCompatibleBitmap(DC, DBWidth, DBHeight);
                      if DBBitmap <> 0 then
                        try
                          SaveBitmap := SelectObject(DBDC, DBBitmap);
                          try
                            SetWindowOrgEx(DBDC, PaintStruct.rcPaint.Left, PaintStruct.rcPaint.Top, nil);
                            GdiCache := TGdiCache.Create(Self, DBDC);
                            try
                              PaintTo(DBDC, GdiCache, UpdateRgn, BackgroupRgn, False);
                            finally
                              GdiCache.Free;
                            end;
                            SetWindowOrgEx(DBDC, 0, 0, nil);
                            BitBlt(DC, PaintStruct.rcPaint.Left, PaintStruct.rcPaint.Top, DBWidth, DBHeight, DBDC, 0, 0, SRCCOPY);
                          finally
                            SelectObject(DBDC, SaveBitmap);
                          end;
                        finally
                          DeleteObject(DBBitmap);
                        end;
                    finally
                      DeleteDC(DBDC);
                    end;
                end
            else
              begin
                GdiCache := TGdiCache.Create(Self, DC);
                try
                  PaintTo(DC, GdiCache, UpdateRgn, BackgroupRgn, True);
                finally
                  GdiCache.Free;
                end;
              end;
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
  GdiCache: TGdiCache;
begin
  GetClientRect(FHandle, UpdateRect);
  UpdateRgn := CreateRectRgnIndirect(UpdateRect);
  BackgroupRgn := CreateRectRgnIndirect(UpdateRect);
  try
    GdiCache := TGdiCache.Create(Self, ADC);
    try
      PaintTo(ADC, GdiCache, UpdateRgn, BackgroupRgn, False);
    finally
      GdiCache.Free;
    end;
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
  InvalidateRect(FHandle, @ItemRect, False);
end;

procedure TTreeView.InvalidateItemCheckBox(AItem: TTreeViewItem);
var
  ItemRect: TRect;
begin
  if FDestroying then Exit;
  if not AItem.IsVisible then Exit;
  ItemRect := AItem.StateIconRect;
  OffsetItemRect(ItemRect);
  InvalidateRect(FHandle, @ItemRect, False);
end;

procedure TTreeView.InvalidateItemButton(AItem: TTreeViewItem);
var
  ItemRect: TRect;
begin
  if FDestroying then Exit;
  if not AItem.IsVisible then Exit;
  ItemRect := AItem.ButtonRect;
  OffsetItemRect(ItemRect);
  InvalidateRect(FHandle, @ItemRect, False);
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
      InvalidateRect(FHandle, @ItemRect, False);
    end;
end;

function TTreeView.CalcAnimation(AStart, AFinish: Integer): Integer;
begin
  Result := AStart + Round((AFinish - AStart) / FAnimatioStepCount * FAnimatioStep);
end;

procedure TTreeView.DoAnimation(AExpandItem, ACollapseItem, AMouseItem: TTreeViewItem; AMode: TAnimationMode);
const
  AnimationFrame = 10;
var
  StartItemPos: TPoint;

  function CalcItemLeftTop: TPoint;
  var
    XOffset, YOffset: Integer;
  begin
    CalcBaseOffsets(XOffset, YOffset);
    Result.X := AMouseItem.Left + XOffset;
    Result.Y := AMouseItem.Top + YOffset;
  end;

  procedure UpdateCursorPos;
  var
    NewItemPos: TPoint;
    CursorPos: TPoint;
  begin
    NewItemPos := CalcItemLeftTop;
    GetCursorPos(CursorPos);
    Inc(CursorPos.X, NewItemPos.X - StartItemPos.X);
    Inc(CursorPos.Y, NewItemPos.Y - StartItemPos.Y);
    SetCursorPos(CursorPos.X, CursorPos.Y);
    StartItemPos := NewItemPos;
  end;

var
  EnableAnimation: BOOL;
  PrevCenter, NewCenter: Integer;
  Delta: Integer;
  ItemIndex: Integer;
  NextFrameTime: Cardinal;
  SleepTime: Integer;
begin
  if not SystemParametersInfo(SPI_GETLISTBOXSMOOTHSCROLLING, 0, @EnableAnimation, 0) then
    EnableAnimation := False;
  if EnableAnimation and IsVistaOrLater then
    if not SystemParametersInfo(SPI_GETCLIENTAREAANIMATION, 0, @EnableAnimation, 0) then
      EnableAnimation := False;

  try
    if EnableAnimation then
      begin
        FAnimationExpandItem := AExpandItem;
        FAnimationCollapseItem := ACollapseItem;
        for ItemIndex := 0 to Count - 1 do
          Items[ItemIndex].SavePositionForAnimation;

        if AutoCenter then
          begin
            PrevCenter := FOptimalHeight div 2;
            DoUpdate2;
            NewCenter := FOptimalHeight div 2;
            if Assigned(AExpandItem) then
              begin
                Delta := NewCenter - PrevCenter;
                AExpandItem.PreparePositionsForExpandAnimation(-Delta);
              end;
            if Assigned(ACollapseItem) then
              begin
                Delta := NewCenter - PrevCenter;
                ACollapseItem.PreparePositionsForCollapseAnimation(Delta);
              end;
          end
        else
          begin
            DoUpdate2;
            if Assigned(AExpandItem) then
              AExpandItem.PreparePositionsForExpandAnimation(0);
            if Assigned(ACollapseItem) then
              ACollapseItem.PreparePositionsForCollapseAnimation(0);
          end;
      end
    else
      DoUpdate2;

    FAnimationMode := AMode;
    try
      FAnimatioStepCount := 10;
      FAnimatioStep := 0;
      if Assigned(AMouseItem) then
        StartItemPos := CalcItemLeftTop;

      if EnableAnimation then
        begin
          FAnimatioStep := 1;
          NextFrameTime := GetTickCount + AnimationFrame;

          while FAnimatioStep < FAnimatioStepCount do
            begin
              SleepTime := NextFrameTime - GetTickCount;
              if SleepTime > 0 then
                begin
                  UpdateScrollBars(not Assigned(AMouseItem));
                  if Assigned(AMouseItem) then
                    UpdateCursorPos;

                  if Assigned(AExpandItem) then
                    FixedItem := AExpandItem
                  else
                    FixedItem := ACollapseItem;
                  FixedItemRect := FixedItem.BoundsRect;

                  Invalidate;
                  UpdateWindow(FHandle);
                  Sleep(SleepTime);
                end
              else
                Sleep(0);

              Inc(NextFrameTime, AnimationFrame);
              Inc(FAnimatioStep);
            end;
        end;
    finally
      FAnimationMode := amNone;
    end;
  finally
    FAnimationExpandItem := nil;
    FAnimationCollapseItem := nil;
  end;

  UpdateScrollBars(not Assigned(AMouseItem));
  if Assigned(AMouseItem) then
    UpdateCursorPos;
  Invalidate;
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
  if Assigned(FItems) then Item := FItems.ItemAtPos(P)
                      else Item := nil;
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
          XPos := GetScrollPos(SB_HORZ);
          Inc(XPos, XOffset);
          SetScrollPos(SB_HORZ, XPos);
        end;
      if YOffset <> 0 then
        begin
          YPos := GetScrollPos(SB_VERT);
          Inc(YPos, YOffset);
          SetScrollPos(SB_VERT, YPos);
        end;
      ScrollWindowEx(FHandle, -XOffset, -YOffset, nil, nil, 0, nil, SW_INVALIDATE);
    end;
end;

function TTreeView.ExpandItem(AItem: TTreeViewItem; ACode, AAction: UINT; ANotify: Boolean): Boolean;
var
  PrevExpanded: Boolean;
  RealCode: UINT;
  MouseItem: TTreeViewItem;
begin
  Result := False;
  RealCode := ACode and TVE_ACTIONMASK;
  if (RealCode = 0) or not AItem.HasChildren then Exit;

  PrevExpanded := AItem.Expanded;

  if RealCode = TVE_TOGGLE then
    begin
      if AItem.Expanded then ACode := TVE_COLLAPSE
                        else ACode := TVE_EXPAND;
      RealCode := ACode;
    end;

  case RealCode of
    TVE_COLLAPSE:
      if not AItem.Expanded then
        begin
          Result := True;
          Exit;
        end;
    TVE_EXPAND:
      if AItem.Expanded then
        begin
          Result := True;
          Exit;
        end;
  end;

  if (RealCode = TVE_EXPAND) and (AItem.FState and TVIS_EXPANDEDONCE = 0) then
    ANotify := True;

  if ANotify and (SendTreeViewNotify(TVN_ITEMEXPANDING, nil, AItem, ACode) <> 0) then Exit;

  if Count = 0 then Exit;

	if RealCode = TVE_EXPAND then AItem.FState := AItem.FState or TVIS_EXPANDED
                           else AItem.FState := AItem.FState and not TVIS_EXPANDED;

  if ANotify then
    SendTreeViewNotify(TVN_ITEMEXPANDED, nil, AItem, ACode);

  AItem.FState := AItem.FState or TVIS_EXPANDEDONCE;

  if (ACode and (TVE_ACTIONMASK or TVE_COLLAPSERESET)) = (TVE_COLLAPSE or TVE_COLLAPSERESET) then
    begin
      AItem.FState := AItem.FState and not TVIS_EXPANDEDONCE;
      if Count > 0 then
        Items_.DeleteAll;
      AItem.FKids := kForceYes;
    end;

  if not AItem.Expanded and AItem.IsChild(FocusedItem) then
    begin
      if not SelectItem(AItem, True, AAction, False) then
        begin
          FocusedItem.FState := FocusedItem.FState and not TVIS_SELECTED;
          FFocusedItem := nil;
        end;
    end;

  if not Assigned(FixedItem) then
    begin
      FixedItem := AItem;
      FixedItemRect := AItem.BoundsRect;
    end;
  Update;

  if ((AAction = TVC_BYMOUSE) or (AAction = TVC_BYKEYBOARD)) and (AItem.Expanded <> PrevExpanded) and AItem.IsVisible then
    begin
      if AAction = TVC_BYMOUSE then MouseItem := AItem
                               else MouseItem := nil;
      if AItem.Expanded then DoAnimation(AItem, nil, MouseItem, amExpand)
                        else DoAnimation(nil, AItem, MouseItem, amCollapse);
    end;

  Result := True;
end;

procedure TTreeView.SingleExpandItem(AItem, APrevFocused: TTreeViewItem; AAction: UINT; ANotify: Boolean; ADisableSingleCollapse: Boolean);
var
  NotifyResult: UINT;
  PrevExpanded: Boolean;
  SaveItem: TTreeViewItem;
begin
  if ANotify then NotifyResult := SendTreeViewNotify(TVN_SINGLEEXPAND, APrevFocused, AItem, 0)
             else NotifyResult := 0;
  if NotifyResult and (TVNRET_SKIPNEW or TVNRET_SKIPNEW) = (TVNRET_SKIPNEW or TVNRET_SKIPNEW) then Exit;

  SaveItem := AItem;
  if Assigned(APrevFocused) then
    if (AItem <> APrevFocused) and not AItem.IsChild(APrevFocused) and not (APrevFocused.IsChild(AItem)) then
      begin
        if (NotifyResult and TVNRET_SKIPOLD = 0) and not ADisableSingleCollapse then
          begin
            while Assigned(APrevFocused.ParentItems.Parent) do
              begin
                if APrevFocused.ParentItems.Parent.IsChild(AItem) then Break;
                APrevFocused := APrevFocused.ParentItems.Parent;
              end;

            PrevExpanded := APrevFocused.Expanded;
            APrevFocused.FullExpand(TVE_COLLAPSE, 0, ANotify);
            if APrevFocused.Expanded = PrevExpanded then
              APrevFocused := nil
          end
        else
          APrevFocused := nil
      end
    else
      APrevFocused := nil;

  if NotifyResult and TVNRET_SKIPNEW = 0 then
    begin
      PrevExpanded := AItem.Expanded;
      if AItem.Expanded then AItem.FullExpand(TVE_COLLAPSE, 0, ANotify)
                        else ExpandItem(AItem, TVE_EXPAND, 0, ANotify);
      if AItem.Expanded = PrevExpanded then
        AItem := nil
    end
  else
    AItem := nil;

  Update;

  if not (Assigned(AItem) or Assigned(APrevFocused)) then Exit;
  if not Assigned(AItem) then
    DoAnimation(nil, APrevFocused, SaveItem, amCollapse)
  else
    if AItem.Expanded then
      DoAnimation(AItem, APrevFocused, AItem, amExpand)
    else
      DoAnimation(APrevFocused, AItem, AItem, amCollapse);
end;

function TTreeView.SelectItem(AItem: TTreeViewItem; ANotify: Boolean; AAction: UINT; ADisableSingleCollapse: Boolean): Boolean;
var
  OldFocused: TTreeViewItem;
  OldState, NewState: UINT;
begin
  OldFocused := FFocusedItem;

  if FFocusedItem <> AItem then
    begin
      Result := False;
      if Assigned(AItem) and not AItem.ExpandParents(AAction) then Exit;

      if ANotify and (SendTreeViewNotify(TVN_SELCHANGINGW, FFocusedItem, AItem, AAction) <> 0) then Exit;

      if Assigned(FFocusedItem) then
        begin
          OldState := FFocusedItem.FState;
          NewState := FFocusedItem.FState and not TVIS_SELECTED;
          if not (ANotify and SendItemChangeNofify(TVN_ITEMCHANGINGW, FFocusedItem, OldState, NewState)) then
            begin
              FFocusedItem.FState := NewState;
              if ANotify then
                SendItemChangeNofify(TVN_ITEMCHANGEDW, FFocusedItem, OldState, NewState);
            end;
          InvalidateItem(FFocusedItem);
        end;

      FFocusedItem := AItem;

      if Assigned(AItem) then
        begin
          OldState := AItem.FState;
          NewState := AItem.FState or TVIS_SELECTED;
          if not (ANotify and SendItemChangeNofify(TVN_ITEMCHANGINGW, AItem, OldState, NewState)) then
            begin
              AItem.FState := AItem.FState or TVIS_SELECTED;
              if ANotify then
                SendItemChangeNofify(TVN_ITEMCHANGEDW, AItem, OldState, NewState);
            end;
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
        SendTreeViewNotify(TVN_SELCHANGED, OldFocused, AItem, AAction);

      Result := True;
    end
  else
    Result := True;

  if Result and Assigned(FFocusedItem) and (AAction = TVC_BYMOUSE) and SingleExpand then
    SingleExpandItem(FFocusedItem, OldFocused, AAction, ANotify, ADisableSingleCollapse);
end;

procedure TTreeView.UpdateSelected(AAction: UINT);
begin
  if not Assigned(FocusedItem) then
    if Assigned(FItems) and (FItems.Count > 0) then
      SelectItem(FItems.Items[0], True, AAction, False);
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
  if Assigned(InsertMaskItem) and InsertMaskItem.IsVisible then
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

procedure TTreeView.SetHotItem(AHotItem: TTreeViewItem);
begin
  if FHotItem = AHotItem then Exit;
  if Assigned(FHotItem) then
    begin
      FHotItem.MouseLeave;
      if TrackSelect then
        InvalidateItem(FHotItem);
    end;
  FHotItem := AHotItem;
  if Assigned(FHotItem) then
    if TrackSelect then
      InvalidateItem(FHotItem);
end;

procedure TTreeView.SetPressedItem(APressedItem: TTreeViewItem);
begin
  if FPressedItem = APressedItem then Exit;
  if Assigned(FPressedItem) then
    FPressedItem.PressCheckBox := False;
  FPressedItem := APressedItem;
end;

procedure TTreeView.SetDropItem(ADropItem: TTreeViewItem);
begin
  if FDropItem = ADropItem then Exit;
  if Assigned(FDropItem) then
    InvalidateItem(FDropItem);
  FDropItem := ADropItem;
  if Assigned(FDropItem) then
    InvalidateItem(FDropItem);
end;

function TTreeView.GetClientCursorPos: TPoint;
begin
  GetCursorPos(Result);
  ScreenToClient(FHandle, Result);
end;

procedure TTreeView.KeyDown(AKeyCode: DWORD; AFlags: DWORD);
var
  TVKeyDown: TTVKeyDown;
begin
  TVKeyDown.wVKey := AKeyCode;
  TVKeyDown.flags := 0;
  SendNotify(TVN_KEYDOWN, @TVKeyDown);

  case AKeyCode of
    VK_RETURN:
      SendNotify(NM_RETURN, nil);
    VK_SPACE:
      if CheckBoxes and Assigned(FocusedItem) then
        FocusedItem.SelectNextCheckState;
  else
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
              if not Assigned(FocusedItem) then
                begin
                  UpdateSelected(TVC_BYKEYBOARD);
                  Exit;
                end;
          end;

          case AKeyCode of
            VK_UP, VK_PRIOR:
              begin
                if FocusedItem.Index_ > 0 then
                  SelectItem(FocusedItem.ParentItems.Items[FocusedItem.Index_ - 1], True, TVC_BYKEYBOARD, False)
                else
                  if Assigned(FocusedItem.ParentItems.Parent) then
                    SelectItem(FocusedItem.ParentItems.Parent, True, TVC_BYKEYBOARD, False)
              end;
            VK_DOWN, VK_NEXT:
              begin
                if FocusedItem.Index_ < FocusedItem.ParentItems.Count - 1 then
                  SelectItem(FocusedItem.ParentItems.Items[FocusedItem.Index_ + 1], True, TVC_BYKEYBOARD, False)
                else
                  if Assigned(FocusedItem.ParentItems.Parent) then
                    SelectItem(FocusedItem.ParentItems.Parent, True, TVC_BYKEYBOARD, False)
              end;
            VK_LEFT, VK_BACK:
              begin
                if Assigned(FocusedItem.ParentItems.Parent) then
                  SelectItem(FocusedItem.ParentItems.Parent, True, TVC_BYKEYBOARD, False)
              end;
            VK_RIGHT:
              begin
                if not FocusedItem.Expanded then
                  ExpandItem(FocusedItem, TVE_EXPAND, TVC_BYKEYBOARD, True)
                else
                  if FocusedItem.Count > 0 then
                    SelectItem(FocusedItem.Items[0], True, TVC_BYKEYBOARD, False)
              end;
            VK_SUBTRACT:
              if Assigned(FocusedItem) and FocusedItem.Expanded then
                ExpandItem(FocusedItem, TVE_COLLAPSE, TVC_BYKEYBOARD, True);
            VK_ADD:
              if Assigned(FocusedItem) and not FocusedItem.Expanded then
                ExpandItem(FocusedItem, TVE_EXPAND, TVC_BYKEYBOARD, True);
            VK_MULTIPLY:
              if Assigned(FocusedItem) then
                FocusedItem.FullExpand(TVE_EXPAND, TVC_BYKEYBOARD, True);
            VK_HOME:
              SelectItem(Items[0], True, TVC_BYKEYBOARD, False);
            VK_END:
              SelectItem(Items[Count - 1], True, TVC_BYKEYBOARD, False);
          end;
        end;
    end;
  end;
end;

procedure TTreeView.LButtonDown(APoint: TPoint);
var
  CtrlPressed: Boolean;
  Item: TTreeViewItem;
  ItemPoint: TPoint;
begin
  SetFocus(FHandle);
  if SendNotify(NM_CLICK, nil) <> 0 then Exit;
  if Count = 0 then Exit;
  ItemPoint := APoint;
  OffsetMousePoint(ItemPoint);
  Item := FItems.ItemAtPos(ItemPoint);
  PressedItem := Item;
  if Assigned(Item) then
    begin
      CtrlPressed := GetKeyState(VK_CONTROL) < 0;
      case Item.HitTest(ItemPoint) of
        TVHT_ONITEMSTATEICON:
          if CheckBoxes then
            begin
              Item.SelectNextCheckState;
              if Item.StateIndex <> 0 then
                Item.PressCheckBox := True;
            end
          else
            SelectItem(Item, True, TVC_BYMOUSE, CtrlPressed);
        TVHT_ONITEMBUTTON:
          ExpandItem(Item, TVE_TOGGLE, TVC_BYMOUSE, True);
      else
        SelectItem(Item, True, TVC_BYMOUSE, CtrlPressed);
      end
    end
  else
    if IsHorzScrollBarVisible or IsVertScrollBarVisible then
      begin
        FMoveMode := True;
        FMoveMouseStartPos := APoint;
        FMoveScrollStartPos.X := GetScrollPos(SB_HORZ);
        FMoveScrollStartPos.Y := GetScrollPos(SB_VERT);
        SetCapture(FHandle);
        if FMoveCursor = 0 then
          FMoveCursor := LoadCursor(0, IDC_SIZEALL);
        SetCursor(FMoveCursor);
      end;
end;

procedure TTreeView.LButtonDblDown(APoint: TPoint);
begin
  if SendNotify(NM_DBLCLK, nil) <> 0 then Exit;
end;

procedure TTreeView.LButtonUp(APoint: TPoint);
begin
  ReleaseCapture;
  FMoveMode := False;
  PressedItem := nil;
end;

procedure TTreeView.MButtonDown(APoint: TPoint);
begin
  SetFocus(FHandle);
end;

procedure TTreeView.MButtonDblDown(APoint: TPoint);
begin

end;

procedure TTreeView.MButtonUp(APoint: TPoint);
begin

end;

procedure TTreeView.RButtonDown(APoint: TPoint);
begin
  SetFocus(FHandle);
  if SendNotify(NM_RCLICK, nil) <> 0 then Exit;
end;

procedure TTreeView.RButtonDblDown(APoint: TPoint);
begin
  if SendNotify(NM_RDBLCLK, nil) <> 0 then Exit;
end;

procedure TTreeView.RButtonUp(APoint: TPoint);
begin

end;

procedure TTreeView.TrackMouse;
var
  EventTrack: Windows.TTrackMouseEvent;
begin
  if FTrackMouse then Exit;
  FTrackMouse := True;
  EventTrack.cbSize := SizeOf(EventTrack);
  EventTrack.dwFlags := TME_LEAVE or TME_HOVER;
  EventTrack.hwndTrack := FHandle;
  EventTrack.dwHoverTime := HOVER_DEFAULT;
  TrackMouseEvent(EventTrack);
end;

procedure TTreeView.MouseMove(APoint: TPoint);
var
  XOffset, YOffset: Integer;
  ScrollInfo: TScrollInfo;
  Item: TTreeViewItem;
begin
  TrackMouse;

  if FMoveMode then
    begin
      XOffset := 0;
      YOffset := 0;

      if IsHorzScrollBarVisible then
        begin
          ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
          GetScrollInfo(SB_HORZ, ScrollInfo);
          XOffset := ScrollInfo.nPos;
          ScrollInfo.nPos := FMoveScrollStartPos.X + (FMoveMouseStartPos.X - APoint.X);
          ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
          ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          XOffset := ScrollInfo.nPos - XOffset;
          if XOffset <> 0 then
            SetScrollPos(SB_HORZ, ScrollInfo.nPos);
        end;

      if IsVertScrollBarVisible then
        begin
          ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
          GetScrollInfo(SB_VERT, ScrollInfo);
          YOffset := ScrollInfo.nPos;
          ScrollInfo.nPos := FMoveScrollStartPos.Y + (FMoveMouseStartPos.Y - APoint.Y);
          ScrollInfo.nPos := Max(ScrollInfo.nPos, 0);
          ScrollInfo.nPos := Min(ScrollInfo.nPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
          YOffset := ScrollInfo.nPos - YOffset;
          if YOffset <> 0 then
            SetScrollPos(SB_VERT, ScrollInfo.nPos);
        end;

      if (XOffset <> 0) or (YOffset <> 0) then
        ScrollWindowEx(FHandle, -XOffset, -YOffset, nil, nil, 0, nil, SW_INVALIDATE);
    end
  else
    begin
      if Count = 0 then Exit;
      OffsetMousePoint(APoint);
      Item := Items_.ItemAtPos(APoint);
      HotItem := Item;
      if Assigned(Item) then
        Item.MouseMove(APoint);
    end;
end;

procedure TTreeView.MouseHover(APoint: TPoint);
begin
  TrackMouse;
end;

procedure TTreeView.MouseLeave;
begin
  FTrackMouse := False;
  if not FMoveMode then
    HotItem := nil;
end;

procedure TTreeView.MouseWheel(ADelta: Integer; AVert: Boolean);
var
  Bar: UINT;
  ScrollInfo: TScrollInfo;
  SysParam: UINT;
  LinesPerWHEELDELTA: UINT;
  Lines: Integer;
  Now: UINT;
  NewPos: Integer;
  X, Y: Integer;
begin
  if AVert then
    begin
      if not IsVertScrollBarVisible then Exit;
      Bar := SB_VERT
    end
  else
    begin
      if not IsHorzScrollBarVisible then Exit;
      Bar := SB_HORZ
    end;

  ScrollInfo.fMask := SIF_POS or SIF_PAGE or SIF_RANGE;
  GetScrollInfo(Bar, ScrollInfo);

  if AVert then SysParam := SPI_GETWHEELSCROLLLINES
           else SysParam := SPI_GETWHEELSCROLLCHARS;
  if not SystemParametersInfo(SysParam, 0, @LinesPerWHEELDELTA, 0) then
    LinesPerWHEELDELTA := 3;
  if LinesPerWHEELDELTA = WHEEL_PAGESCROLL then
    LinesPerWHEELDELTA := ScrollInfo.nPage
  else
    LinesPerWHEELDELTA := LinesPerWHEELDELTA * PixelsPerLine;
  if LinesPerWHEELDELTA > ScrollInfo.nPage then
    LinesPerWHEELDELTA := ScrollInfo.nPage;

  Now := GetTickCount;
  if Cardinal(Now - FWheelActivity[AVert]) > GetDoubleClickTime * 2 then
    FWheelAccumulator[AVert] := 0
  else
    if (FWheelAccumulator[AVert] > 0) = (ADelta < 0) then
      FWheelAccumulator[AVert] := 0;
  FWheelActivity[AVert] := Now;

  if LinesPerWHEELDELTA > 0 then
    begin
      Inc(FWheelAccumulator[AVert], ADelta);
      Lines := (FWheelAccumulator[AVert] * Integer(LinesPerWHEELDELTA)) div WHEEL_DELTA;
      Dec(FWheelAccumulator[AVert], (Lines * WHEEL_DELTA) div Integer(LinesPerWHEELDELTA));
    end
  else
    begin
      Lines := 0;
      FWheelAccumulator[AVert] := 0;
    end;

  NewPos := ScrollInfo.nPos - Lines;

  NewPos := Max(NewPos, 0);
  NewPos := Min(NewPos, ScrollInfo.nMax - Integer(ScrollInfo.nPage));
  if NewPos <> ScrollInfo.nPos then
    begin
      SetScrollPos(Bar, NewPos);
      if not AVert then
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
  Str: UnicodeString;
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
      if AWnd <> 0 then ID := GetDlgCtrlID(AWnd) // GetWindowLongPtrW(hwnd, GWL_ID)?
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
          ANMHdr.code := TVN_GETDISPINFOA;
        TVN_GETINFOTIPW:
          ANMHdr.code := TVN_GETINFOTIPA;
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
            if (Item.mask and TVIF_TEXT <> 0) and not IsFlagPtr(Item.pszText) and (Item.cchTextMax > 0)  then
              begin
                Str := ProduceWFromA(PAnsiChar(Item.pszText));
                if Length(Str) >= Item.cchTextMax then
                  SetLength(Str, Item.cchTextMax - 1);
                if Str = '' then
                  Item.pszText^ := #0
                else
                  CopyMemory(Item.pszText, PWideChar(Str), (Length(Str) + 1) * SizeOf(WideChar));
              end;
          end;
        TVN_GETINFOTIPA:
          begin
            NMGetInfoTip := PNMTVGetInfoTipW(ANMHdr);
            if NMGetInfoTip.cchTextMax > 0 then
              begin
                Str := ProduceWFromA(PAnsiChar(NMGetInfoTip.pszText));
                if Length(Str) >= NMGetInfoTip.cchTextMax then
                  SetLength(Str, NMGetInfoTip.cchTextMax - 1);
                if Str = '' then
                  NMGetInfoTip.pszText^ := #0
                else
                  CopyMemory(NMGetInfoTip.pszText, PWideChar(Str), (Length(Str) + 1) * SizeOf(WideChar));
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

function TTreeView.SendTreeViewNotify(ACode: Integer; AOldItem, ANewItem: TTreeViewItem; AAction: UINT): UINT;
var
  NMTreeView: TNMTreeViewW;
begin
  NMTreeView.action := AAction and TVE_ACTIONMASK;

  if Assigned(AOldItem) then
    begin
      NMTreeView.itemOld.mask := TVIF_HANDLE or TVIF_STATE or TVIF_PARAM or TVIF_IMAGE or TVIF_SELECTEDIMAGE;
      NMTreeView.itemOld.hItem := HTreeItem(AOldItem);
      NMTreeView.itemOld.state := AOldItem.FState;
      NMTreeView.itemOld.stateMask := 0;
      NMTreeView.itemOld.iImage := AOldItem.FImageIndex;
      NMTreeView.itemOld.iSelectedImage := AOldItem.FSelectedImageIndex;
      NMTreeView.itemOld.cChildren := AOldItem.FChildren;
      NMTreeView.itemOld.lParam := AOldItem.FParam;
    end
  else
    begin
      NMTreeView.itemOld.mask := 0;
      NMTreeView.itemOld.hItem := nil;
    end;

  if Assigned(ANewItem) then
    begin
      NMTreeView.itemNew.mask := TVIF_HANDLE or TVIF_STATE or TVIF_PARAM or TVIF_IMAGE or TVIF_SELECTEDIMAGE;
      NMTreeView.itemNew.hItem := HTreeItem(ANewItem);
      NMTreeView.itemNew.state := ANewItem.FState;
      NMTreeView.itemNew.stateMask := 0;
      NMTreeView.itemNew.iImage := ANewItem.FImageIndex;
      NMTreeView.itemNew.iSelectedImage := ANewItem.FSelectedImageIndex;
      NMTreeView.itemNew.cChildren := ANewItem.FChildren;
      NMTreeView.itemNew.lParam := ANewItem.FParam;
    end
  else
    begin
      NMTreeView.itemNew.mask := 0;
      NMTreeView.itemNew.hItem := nil;
    end;

  Result := SendNotify(ACode, @NMTreeView);
end;

function TTreeView.SendItemChangeNofify(ACode: Integer; AItem: TTreeViewItem; AOldState, ANewState: UINT): Boolean;
var
  NMTVItemChange: TNMTVItemChange;
begin
  NMTVItemChange.uChanged := TVIF_STATE;
  NMTVItemChange.hItem := HTREEITEM(AItem);
  NMTVItemChange.uStateNew := ANewState;
  NMTVItemChange.uStateOld := AOldState;
  NMTVItemChange.lParam := AItem.FParam;
  Result := SendNotify(ACode, @NMTVItemChange) <> 0;
end;

type
  TRegions = class(TObject)
  public
    destructor Destroy; override;
  private
    Regions: array of HRGN;
    RegionCount: Integer;
    function Push: HRGN;
    procedure Pop;
    function ValidRect(const AItemRect: TRect): Boolean;
    function FindTop(AItemRect: TRect): Integer;
    //function FindTop2(ARegion: HRGN): Integer;
  end;

destructor TRegions.Destroy;
var
  RegionIndex: Integer;
begin
  for RegionIndex := RegionCount - 1 downto 0 do
    DeleteObject(Regions[RegionIndex]);
  inherited Destroy;
end;

function TRegions.Push: HRGN;
begin
  if Length(Regions) = RegionCount then
    SetLength(Regions, RegionCount + 4);
  Result := CreateRectRgn(0, 0, 0, 0);
  Regions[RegionCount] := Result;
  Inc(RegionCount);
end;

procedure TRegions.Pop;
begin
  DeleteObject(Regions[RegionCount - 1]);
  Dec(RegionCount);
end;

function TRegions.ValidRect(const AItemRect: TRect): Boolean;
var
  RegionIndex: Integer;
begin
  for RegionIndex := 0 to RegionCount - 1 do
    if RectInRegion(Regions[RegionIndex], AItemRect) then
      begin
        Result := False;
        Exit;
      end;
  Result := True;
end;

function TRegions.FindTop(AItemRect: TRect): Integer;
var
  Delta: Integer;
begin
  Delta := 0;
  while True do
    begin
      if ValidRect(AItemRect) then Break;
      if Delta = 0 then Delta := 1
                   else Delta := Delta * 2;
      OffsetRect(AItemRect, 0, Delta);
    end;
  while Delta > 0 do
    begin
      OffsetRect(AItemRect, 0, -Delta);
      if not ValidRect(AItemRect) then
        OffsetRect(AItemRect, 0, Delta);
      Delta := Delta div 2;
    end;
  Result := AItemRect.Top;
end;

{$IFDEF DEBUG}
procedure TestRegionsFind;
var
  Regions: TRegions;
  Top: Integer;
  Top2: Integer;
  PrevItemsRgn: HRGN;
  Temp: HRGN;
  R: TRect;
begin
  Regions := TRegions.Create;
  try
    R.Left := 0;
    R.Top := 0;
    R.Right := 10;
    R.Bottom := 1;
    for Top := 1 to 256 do
      begin
        PrevItemsRgn := Regions.Push;
        Temp := CreateRectRgn(0, 0, 10, Top);
        CombineRgn(PrevItemsRgn, PrevItemsRgn, Temp, RGN_OR);
        Top2 := Regions.FindTop(R);
        if Top2 <> Top then
          MessageBox(0, PChar('TestRegionsFind fails'), 'TestRegionsFind', MB_ICONERROR);
        Regions.Pop;
      end;
  finally
    Regions.Free;
  end;
end;
{$ENDIF}

function GetBoundsRectEx(AItem: TTreeViewItem; AHorzSpace, AVertSpace: Integer): TRect; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
begin
  Result.Left := AItem.FLeft;
  Result.Top := AItem.FTop;
  Result.Right := AItem.FLeft + AItem.FWidth + AHorzSpace;
  Result.Bottom := AItem.FTop + AItem.FHeight + AVertSpace;
  if AItem.FIndex = AItem.ParentItems.Count - 1 then
    Inc(Result.Bottom, AVertSpace);
end;

procedure CreateChildsRegion(AItem: TTreeViewItem; ARgn: HRGN; AHorzSpace, AVertSpace: Integer);
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
  ItemRect: TRect;
  ItemRegion: HRGN;
begin
  for ItemIndex := 0 to AItem.Count - 1 do
    begin
      Item := AItem.Items[ItemIndex];
      ItemRect := GetBoundsRectEx(Item, AHorzSpace, AVertSpace);
      ItemRect.Top := Min(0, ItemRect.Top);
      ItemRegion := CreateRectRgnIndirect(ItemRect);
      CombineRgn(ARgn, ARgn, ItemRegion, RGN_OR);
      DeleteObject(ItemRegion);
      if Item.Expanded and (Item.Count > 0) then
        CreateChildsRegion(Item, ARgn, AHorzSpace, AVertSpace);
    end;
end;

procedure MoveChilds(AItem: TTreeViewItem; AXOffset, AYOffset: Integer);
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
begin
  for ItemIndex := 0 to AItem.Count - 1 do
    begin
      Item := AItem.Items[ItemIndex];
      Inc(Item.FLeft, AXOffset);
      Inc(Item.FMinTop, AYOffset);
      Inc(Item.FTop, AYOffset);
      if Item.Expanded and (Item.Count > 0) then
        MoveChilds(Item, AXOffset, AYOffset);
    end;
end;

procedure DoUpdate2Iterate(ARegions: TRegions; AItem: TTreeViewItem; AX, AY, AHorzSpace, AVertSpace: Integer; ARegion: HRGN
  {$IFDEF DEBUG}; AWnd: HWND; ADC: HDC; ASaveXOffset, ASaveYOffset: Integer{$ENDIF});
var
  ItemIndex: Integer;
  Item: TTreeViewItem;
  Item2: TTreeViewItem;
  MinY, MaxY: Integer;
  Y: Integer;
  ChildsRegion: HRGN;
  NeedRebuildChildsRegion: Boolean;
  MoveDelta: Integer;
  StartTop: Integer;
  Temp: HRGN;
  R: TRect;
  CorrectCount: Integer;
  CorrectIndex: Integer;
  FreeSpace: Integer;
  MaxCorrectTop: Integer;
  NextTop: Double;
  ItemSpace: Double;
  ItemsHeight: Integer;
  {$IFDEF DEBUG}
  //RegionIndex: Integer;
  //Brush: HBRUSH;
  ItemText: UnicodeString;
  {$ENDIF}
begin
  {$IFDEF DEBUG}
  {R := AItem.BoundsRect;
  OffsetRect(R, ASaveXOffset, ASaveYOffset);
  FillRectWithColor(ADC, R, $00FF00);;}
  ItemText := AItem.Text;
  {$ENDIF}

  AItem.FLeft := AX;
  AItem.FTop := AY;
  Inc(AX, AItem.FWidth + AHorzSpace);
  if AItem.Expanded and (AItem.Count > 0) then ChildsRegion := ARegions.Push
                                          else ChildsRegion := 0;
  NeedRebuildChildsRegion := False;
  MoveDelta := 0;

  if ChildsRegion <> 0 then
    begin
      Y := 0;
      for ItemIndex := 0 to AItem.Count - 1 do
        begin
          Item := AItem.Items[ItemIndex];
          DoUpdate2Iterate(ARegions, Item, AX, Y, AHorzSpace, AVertSpace, ChildsRegion
            {$IFDEF DEBUG}, AWnd, ADC, ASaveXOffset, ASaveYOffset{$ENDIF});
          Y := Item.FTop + Item.FHeight + AVertSpace;
        end;

      Item := AItem.Items[0];
      MinY := Item.FTop;
      Item := AItem.Items[AItem.Count - 1];
      MaxY := Item.FTop + Item.FHeight;
      Y := MinY + (MaxY - MinY) div 2 - AItem.FHeight div 2;
      if (Y > AY) and (MinY = 0) then
        begin
          Inc(MoveDelta, AY - Y);
          NeedRebuildChildsRegion := True;
          Y := AY;
        end
      else
        if Y < AY then
          begin
            Inc(MoveDelta, AY - Y);
            NeedRebuildChildsRegion := True;
            Y := AY;
          end;
      AItem.FTop := Y;
    end;

  StartTop := AItem.FTop;
  AItem.FTop := ARegions.FindTop(GetBoundsRectEx(AItem, AHorzSpace, AVertSpace));
  if (ChildsRegion <> 0) and (AItem.FTop <> StartTop) then
    begin
      Inc(MoveDelta, AItem.FTop - StartTop);
      NeedRebuildChildsRegion := True;
    end;

  AItem.FMinTop := AItem.FTop;

  if AItem.FIndex = AItem.ParentItems.Count - 1 then
    begin
      CorrectCount := 0;
      for ItemIndex := AItem.FIndex - 1 downto 0 do
        begin
          Item := AItem.ParentItems.Items[ItemIndex];
          if (Item.FWidth <= AItem.FWidth) and not Item.Expanded then
            Inc(CorrectCount)
          else
            if CorrectCount > 0 then
              begin
                ItemsHeight := 0;
                for CorrectIndex := ItemIndex + 1 to ItemIndex + CorrectCount do
                  Inc(ItemsHeight, AItem.ParentItems.Items[CorrectIndex].FHeight);

                MaxCorrectTop := AItem.ParentItems.Items[ItemIndex + CorrectCount + 1].FTop;
                NextTop := Item.FTop + Item.FHeight;
                FreeSpace := MaxCorrectTop - (Item.FTop + Item.FHeight);
                ItemSpace := (FreeSpace - ItemsHeight) / (CorrectCount + 1);

                for CorrectIndex := ItemIndex + 1 to ItemIndex + CorrectCount do
                  begin
                    Item := AItem.ParentItems.Items[CorrectIndex];
                    Item.FTop := Round(NextTop + ItemSpace);

                    Dec(ItemsHeight, Item.FHeight);
                    Dec(CorrectCount);

                    if Item.FTop < Item.FMinTop then
                      begin
                        Item.FTop := Item.FMinTop;
                        NextTop := Item.FTop + Item.FHeight;
                        FreeSpace := MaxCorrectTop - (Item.FTop + Item.FHeight);
                        ItemSpace := (FreeSpace - ItemsHeight) / (CorrectCount + 1);
                      end
                    else
                      NextTop := NextTop + Item.FHeight + ItemSpace;
                  end;

                CorrectCount := 0;
              end;
        end;
      if CorrectCount > 0 then
        for ItemIndex := CorrectCount - 1 downto 0 do
          begin
            Item := AItem.ParentItems.Items[ItemIndex];
            Item2 := AItem.ParentItems.Items[ItemIndex + 1];
            Item.FTop := Item2.FTop - AVertSpace - Item.FHeight;
          end;
    end;

  R := GetBoundsRectEx(AItem, AHorzSpace, AVertSpace);
  R.Top := 0;
  Temp := CreateRectRgnIndirect(R);
  CombineRgn(ARegion, ARegion, Temp, RGN_OR);
  if ChildsRegion <> 0 then
    begin
      if NeedRebuildChildsRegion then
        begin
          MoveChilds(AItem, 0, MoveDelta);
          ARegions.Pop;
          ChildsRegion := ARegions.Push;
          CreateChildsRegion(AItem, ChildsRegion, AHorzSpace, AVertSpace);
        end;
      CombineRgn(ARegion, ARegion, ChildsRegion, RGN_OR);
      ARegions.Pop;
    end;
  DeleteObject(Temp);
  {$IFDEF DEBUG}
  {GetClientRect(AWnd, R);
  FillRectWithColor(ADC, R, $FFFFFF);
  for RegionIndex := 0 to ARegions.RegionCount - 1 do
    begin
      OffsetRgn(ARegions.Regions[RegionIndex], ASaveXOffset, ASaveYOffset);
      FillRgnWithColor(ADC, ARegions.Regions[RegionIndex], $0000FF);
      OffsetRgn(ARegions.Regions[RegionIndex], -ASaveXOffset, -ASaveYOffset);
    end;}
  {OffsetRgn(ARegion, ASaveXOffset, ASaveYOffset);
  //FillRgnWithColor(ADC, ARegion, $0000FF);
  Brush := CreateSolidBrush(0);
  FrameRgn(ADC, ARegion, Brush, 1, 1);
  DeleteObject(Brush);
  OffsetRgn(ARegion, -ASaveXOffset, -ASaveYOffset);
  R := AItem.BoundsRect;
  OffsetRect(R, ASaveXOffset, ASaveYOffset);
  //FillRectWithColor(ADC, R, $FF0000);}

 { R := AItem.BoundsRectEx;
  OffsetRect(R, ASaveXOffset, ASaveYOffset);
  FillRectWithColor(ADC, R, $FF0000);}
  {$ENDIF}
end;

procedure UpdateOptimalSize(AItem: TTreeViewItem; var ALeft, ATop, ARight, AHeight: Integer);
var
  ItemIndex: Integer;
begin
  ALeft := Min(ALeft, AItem.FLeft);
  ATop := Min(ATop, AItem.FTop);
  ARight := Max(ARight, AItem.FLeft + AItem.FWidth);
  AHeight := Max(AHeight, AItem.FTop + AItem.FHeight);
  if AItem.Expanded then
    for ItemIndex := 0 to AItem.Count - 1 do
      UpdateOptimalSize(AItem.Items[ItemIndex], ALeft, ATop, ARight, AHeight);
end;

procedure TTreeView.DoUpdate2;
var
  {$IFDEF DEBUG}
  SaveXOffset: Integer;
  SaveYOffset: Integer;
  {$ENDIF}
  XOffset: Integer;
  YOffset: Integer;
  DC: HDC;
  Regions: TRegions;
  Region: HRGN;
  ChildsRegion: HRGN;
  ItemIndex: Integer;
  Item: TTreeViewItem;
  Left, Top: Integer;
begin
  if FNeedUpdateItemSize then
    for ItemIndex := 0 to Count - 1 do
      Items[ItemIndex].NeedUpdateSizeWithChilds;
  FNeedUpdateItemSize := False;
  FNeedUpdateItemPositions := False;

  {$IFDEF DEBUG}
  CalcBaseOffsets(SaveXOffset, SaveYOffset);
  {$ENDIF}
  FPrevOptimalWidth := FOptimalWidth;
  FPrevOptimalHeight := FOptimalHeight;
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

          Regions := TRegions.Create;
          try
            Region := Regions.Push;
            for ItemIndex := 0 to Count - 1 do
              begin
                Item := Items[ItemIndex];

                ChildsRegion := Regions.Push;
                DoUpdate2Iterate(Regions, Item, XOffset, YOffset, HorzSpace, VertSpace, ChildsRegion
                  {$IFDEF DEBUG}, FHandle, DC, SaveXOffset, SaveYOffset{$ENDIF});
                CombineRgn(Region, Region, ChildsRegion, RGN_OR);
                Regions.Pop;

                YOffset := Item.FTop + Item.FHeight;
              end;
          finally
            Regions.Free;
          end;

          Left := 0;
          Top := 0;
          for ItemIndex := 0 to Count - 1 do
            UpdateOptimalSize(Items[ItemIndex], Left, Top, FOptimalWidth, FOptimalHeight);
          if (Left < 0) or (Top < 0) then
            begin
              for ItemIndex := 0 to Count - 1 do
                begin
                  Items[ItemIndex].FLeft := Items[ItemIndex].FLeft - Left;
                  Items[ItemIndex].FTop := Items[ItemIndex].FTop - Top;
                  MoveChilds(Items[ItemIndex], -Left, -Top);
                end;
              Dec(FOptimalWidth, Left);
              Dec(FOptimalHeight, Top);
            end;
        finally
          ReleaseDC(FHandle, DC);
        end;
    end;
end;

procedure TTreeView.DoUpdate;
begin
  if FLockUpdate or (FUpdateCount > 0) or not FNeedUpdateItemPositions or FDestroying then Exit;
  DoUpdate2;
  UpdateScrollBars;
  Invalidate;
end;

procedure TTreeView.Update;
begin
  FNeedUpdateItemPositions := True;
end;

procedure TTreeView.FullUpdate;
begin
  FNeedUpdateItemSize := True;
  FNeedUpdateItemPositions := True;
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
  XOffset, YOffset: Integer;
  PrevHideFocus: Boolean;
begin
  Inc(FUpdateCount);
  try
    Result := 0;
    case AMsg of
      WM_NCCREATE:
        begin
          CreateStruct := PCreateStruct(ALParam);
          FParentHandle := CreateStruct.hwndParent;
          InitStyles(CreateStruct.style);
          InitStyles2(TVS_EX_DOUBLEBUFFER or{} TVS_EX_AUTOCENTER);
          InitStylesEx(CreateStruct.dwExStyle);
          FUnicode := SendMessage(FParentHandle, WM_NOTIFYFORMAT, FHandle, NF_QUERY) = NFR_UNICODE;
          FSysFont := True;
          Dpi := GetDpiForWindow(FHandle);
          FHideFocus := SendMessage(FHandle, WM_QUERYUISTATE, 0, 0) <> UISF_HIDEFOCUS;
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
      WM_NCDESTROY:;
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
      CCM_GETUNICODEFORMAT:
        if FUnicode then Result := 1;
      CCM_SETUNICODEFORMAT:
        begin
          if FUnicode then Result := 1;
          FUnicode := AWParam <> 0;
        end;
      {$IFDEF NATIVE_BORDERS}
      WM_NCCALCSIZE:
        begin
          R := PRect(ALParam)^;
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if Themed then
            begin
              CaclClientRect(@R, PRect(ALParam));
              Result := 0;
            end;
          {if AWParam <> 0 then
            begin
              PNCCalcSizeParams(ALParam).rgrc[1] := PRect(ALParam)^;
              Result := WVR_VALIDRECTS;
            end;}
        end;
      {$ENDIF}
      WM_NCPAINT:
       PaintBorders(AWParam);

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
      CCM_SETWINDOWTHEME:
        SetWindowTheme(FHandle, PWideChar(ALParam), nil);
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
          Result := FIndent;
          FIndent := AWParam;
        end;
      TVM_GETINDENT:
        Result := FIndent;
      TVM_SETITEMHEIGHT:
        begin
          Result := FItemHeight;
          FItemHeight := AWParam;
        end;
      TVM_GETITEMHEIGHT:
        Result := FItemHeight;

      WM_SETREDRAW:
        FLockUpdate := AWParam = 0;
      WM_UPDATEUISTATE:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if HiWord(AWParam) and UISF_HIDEFOCUS <> 0 then
            begin
              PrevHideFocus := FHideFocus;
              case LoWord(AWParam) of
                UIS_SET:   FHideFocus := True;
                UIS_CLEAR: FHideFocus := False;
              end;
              //FHideFocus := SendMessage(FHandle, WM_QUERYUISTATE, 0, 0) <> UISF_HIDEFOCUS;
              if FHideFocus <> PrevHideFocus then
                if Focused and Assigned(FocusedItem) then
                  InvalidateItem(FocusedItem);
            end;
        end;
      WM_ERASEBKGND:
        Result := 1;
      WM_PAINT:
        if AWParam = 0 then Paint
                       else PaintClient(AWParam);
      WM_PRINTCLIENT:
        PaintClient(AWParam);
      WM_WINDOWPOSCHANGING:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if not FResizeMode then
            CalcBaseOffsets(FPrevXOffset, FPrevYOffset);
        end;
      WM_WINDOWPOSCHANGED:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
        end;
      WM_SIZE:
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          if not FResizeMode then
            begin
              FResizeMode := True;
              try
                UpdateScrollBarsEx(LoWord(ALParam), HiWord(ALParam));
                CalcBaseOffsets(XOffset, YOffset);
                if (XOffset <> FPrevXOffset) or (YOffset <> FPrevYOffset) then
                  ScrollWindowEx(FHandle, XOffset - FPrevXOffset, YOffset - FPrevYOffset, nil, nil, 0, nil, SW_INVALIDATE);
              finally
                FResizeMode := False;
              end;
            end;
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
                  NMMouse.dwItemSpec := {$IFDEF WIN64}DWORD_PTR(TreeItem){$ELSE}DWORD(TreeItem){$ENDIF};
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
        begin
          Result := DefWindowProc(FHandle, AMsg, AWParam, ALParam);
          KeyDown(AWParam, ALParam);
        end;

      WM_LBUTTONDOWN:
        LButtonDown(GetClientCursorPos);
      WM_LBUTTONDBLCLK:
        LButtonDblDown(GetClientCursorPos);
      WM_LBUTTONUP:
        LButtonUp(GetClientCursorPos);
      WM_MBUTTONDOWN:
        MButtonDown(GetClientCursorPos);
      WM_MBUTTONDBLCLK:
        MButtonDblDown(GetClientCursorPos);
      WM_MBUTTONUP:
        MButtonUp(GetClientCursorPos);
      WM_RBUTTONDOWN:
        RButtonDown(GetClientCursorPos);
      WM_RBUTTONDBLCLK:
        RButtonDblDown(GetClientCursorPos);
      WM_RBUTTONUP:
        RButtonUp(GetClientCursorPos);
      WM_MOUSEMOVE:
        MouseMove(GetClientCursorPos);
      WM_MOUSEHOVER:
        MouseHover(GetClientCursorPos);
      WM_MOUSELEAVE:
        MouseLeave;
      WM_MOUSEWHEEL:
        MouseWheel(Short(HiWord(AWParam)), True);
      WM_MOUSEHWHEEL:
        MouseWheel(Short(HiWord(AWParam)), False);
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
            Result := LRESULT(FocusedItem);
        else
          TreeItem := TTreeViewItem(ALParam);
          if not Assigned(TreeItem) then Exit;
          Result := LRESULT(TreeItem.ParentItems.GetNextItem(TreeItem, AWParam));
        end;
      TVM_DELETEITEM:
        if (ALPARAM = LPARAM(TVI_ROOT)) or (ALPARAM = 0) then
          begin
            FFocusedItem := nil;
            FFixedItem := nil;
            FScrollItem := nil;
            FInsertMaskItem := nil;
            FHotItem := nil;
            FPressedItem := nil;
            FDropItem := nil;
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
              if SelectItem(TreeItem, True, TVC_UNKNOWN, False) then
                Result := 1;
            TVGN_DROPHILITE:
              DropItem := TreeItem;
            TVGN_FIRSTVISIBLE:
              if Assigned(TreeItem) then
                MakeVisible(TreeItem);
          end;
        end;
      TVM_EXPAND:
        begin
          TreeItem := TTreeViewItem(ALParam);
          if not Assigned(TreeItem) then Exit;
          if ExpandItem(TreeItem, AWParam, TVC_UNKNOWN, False) then
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
        if Assigned(FocusedItem) then Result := 1;
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
    UpdateSelected(0);
  if Assigned(FocusedItem) then
    InvalidateItem(FocusedItem);
end;

procedure TTreeView.SetNoScroll(ANoScroll: Boolean);
begin
  if FNoScroll = ANoScroll then Exit;
  FNoScroll := ANoScroll;
  NoScrollBarChanged;
end;

procedure TTreeView.UpdateCheckBoxes;
begin
  FCheckBoxes :=
    (FStyle and TVS_CHECKBOXES <> 0) or
    (FStyle2 and TVS_EX_PARTIALCHECKBOXES <> 0) or
    (FStyle2 and TVS_EX_EXCLUSIONCHECKBOXES <> 0) or
    (FStyle2 and TVS_EX_DIMMEDCHECKBOXES <> 0);
  if FCheckBoxes then
    begin
      FCheckBoxStateCount := 2;
      FCheckBoxStates[1] := CBS_UNCHECKEDNORMAL;
      FCheckBoxStates[2] := CBS_CHECKEDNORMAL;
      if FStyle2 and TVS_EX_PARTIALCHECKBOXES <> 0 then
        begin
          Inc(FCheckBoxStateCount);
          FCheckBoxStates[FCheckBoxStateCount] := CBS_MIXEDNORMAL;
        end;
      if FStyle2 and TVS_EX_DIMMEDCHECKBOXES <> 0 then
        begin
          Inc(FCheckBoxStateCount);
          FCheckBoxStates[FCheckBoxStateCount] := CBS_IMPLICITNORMAL
        end;
      if FStyle2 and TVS_EX_EXCLUSIONCHECKBOXES <> 0 then
        begin
          Inc(FCheckBoxStateCount);
          FCheckBoxStates[FCheckBoxStateCount] := CBS_EXCLUDEDNORMAL;
        end;
    end
  else
    FCheckBoxStateCount := 0;
end;

procedure TTreeView.InitItemsCheckBoxStates;
var
  ItemIndex: Integer;
begin
  for ItemIndex := 0 to Count - 1 do
    Items[ItemIndex].InitCheckBoxState;
end;

procedure TTreeView.InitStyles(AStyles: UINT);
begin
  FStyle := AStyles;
  FBorder := AStyles and WS_BORDER <> 0;
  FAlwaysShowSelection := AStyles and TVS_SHOWSELALWAYS <> 0;
  FHasButtons := AStyles and TVS_HASBUTTONS <> 0;
  FLinesAsRoot := AStyles and TVS_LINESATROOT <> 0;
  FSingleExpand := AStyles and TVS_SINGLEEXPAND <> 0;
  FTrackSelect := AStyles and TVS_TRACKSELECT <> 0;
  FNoScroll := AStyles and TVS_NOSCROLL <> 0;
  UpdateCheckBoxes;
end;

procedure TTreeView.InitStyles2(AStyles2: UINT);
begin
  FStyle2 := AStyles2;
  FAutoCenter := AStyles2 and TVS_EX_AUTOCENTER <> 0;
  UpdateCheckBoxes;
end;

procedure TTreeView.InitStylesEx(AStylesEx: UINT);
begin
  FStyleEx := AStylesEx;
  FClientEdge := AStylesEx and WS_EX_CLIENTEDGE <> 0;
end;

procedure TTreeView.SetStyle(AStyle: UINT);
var
  NeedUpdate: Boolean;
  NeedFullUpdate: Boolean;
  NeedInvalidate: Boolean;
  PrevAlwaysShowSelection: Boolean;
  PrevHasButtons: Boolean;
  PrevLinesAsRoot: Boolean;
  PrevNoScroll: Boolean;
  PrevTrackSelect: Boolean;
  PrevCheckBoxes: Boolean;
begin
  NeedUpdate := False;
  NeedFullUpdate := False;
  NeedInvalidate := False;

  PrevAlwaysShowSelection := AlwaysShowSelection;
  PrevHasButtons := HasButtons;
  PrevLinesAsRoot := LinesAsRoot;
  PrevNoScroll := NoScroll;
  PrevTrackSelect := TrackSelect;
  PrevCheckBoxes := CheckBoxes;

  InitStyles(AStyle);

  if AlwaysShowSelection <> PrevAlwaysShowSelection then
    if not Focused and Assigned(FocusedItem) then
      NeedInvalidate := True;
  if HasButtons <> PrevHasButtons then
    NeedFullUpdate := True;
  if LinesAsRoot <> PrevLinesAsRoot then
    NeedFullUpdate := True;
  {if NoScroll <> PrevNoScroll then
    NeedInvalidate := True;}
  if TrackSelect <> PrevTrackSelect then
    NeedInvalidate := True;
  if CheckBoxes <> PrevCheckBoxes then
    begin
      if CheckBoxes then
        begin
          InitItemsCheckBoxStates;
          FStateImageList := 0;
        end;
      NeedFullUpdate := True;
    end;

  if NoScroll <> PrevNoScroll then
    NoScrollBarChanged;

  if NeedFullUpdate then
    FullUpdate
  else
    if NeedUpdate then
      Update
    else
      if NeedInvalidate then
        Invalidate;
end;

procedure TTreeView.SetStyle2(AMask, AStyle2: UINT);
var
  NeedUpdate: Boolean;
  NeedFullUpdate: Boolean;
  NeedInvalidate: Boolean;
  PrevAutoCenter: Boolean;
  PrevCheckBoxes: Boolean;
begin
  NeedUpdate := False;
  NeedFullUpdate := False;
  NeedInvalidate := False;

  PrevAutoCenter := AutoCenter;
  PrevCheckBoxes := CheckBoxes;

  AStyle2 := (FStyle2 and not AMask) or (AStyle2 and AMask);
  InitStyles2(AStyle2);

  if AutoCenter <> PrevAutoCenter then
    NeedInvalidate := True;
  if CheckBoxes <> PrevCheckBoxes then
    begin
      if CheckBoxes then
        begin
          InitItemsCheckBoxStates;
          FStateImageList := 0;
        end;
      NeedFullUpdate := True;
    end;

  if NeedFullUpdate then
    FullUpdate
  else
    if NeedUpdate then
      Update
    else
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
      Update
    else
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
  UpdateCheckSize;
  UpdateScrollBarSize;
end;

procedure TTreeView.CloseTheme;
begin
  if FTheme <> 0 then
    begin
      CloseThemeData(FTheme);
      FTheme := 0;
    end;
  if FCheckBoxTheme <> 0 then
    begin
      CloseThemeData(FCheckBoxTheme);
      FCheckBoxTheme := 0;
    end;
  FTreeItemThemeExist := False;
  FButtonThemeExist := False;
  FHotButtonThemeExist := False;
  FCheckBoxThemeExist := False;
end;

procedure TTreeView.OpenTheme;
var
  SystemDpi: UINT;
begin
  //Exit;
  CloseTheme;
  if UseThemes then
    begin
      SystemDpi := GetDpiForSystem;

      FTheme := {0;//} OpenThemeDataForDpi(FHandle, VSCLASS_TREEVIEW, Dpi, False);
      FDpiTheme := FTheme <> 0;
      if not FDpiTheme then
        begin
          if Dpi = SystemDpi then
            begin
              FTheme := OpenThemeData(FHandle, VSCLASS_TREEVIEW);
              FDpiTheme := True;
            end
          else
            FTheme := OpenThemeDataEx(FHandle, VSCLASS_TREEVIEW, OTD_FORCE_RECT_SIZING);
        end;
      if FTheme <> 0 then
        begin
          FTreeItemThemeExist := IsThemePartDefined(FTheme, TVP_TREEITEM, 0);
          FButtonThemeExist := IsThemePartDefined(FTheme, TVP_GLYPH, 0);
          FHotButtonThemeExist := IsThemePartDefined(FTheme, TVP_HOTGLYPH, 0);
          if not (FButtonThemeExist and FHotButtonThemeExist and Succeeded(GetThemePartSize(FTheme, 0, TVP_GLYPH, GLPS_CLOSED, nil, TS_TRUE, FThemeButtonSize))) then
            begin
              FThemeButtonSize.cx := 15 * Dpi div 96;
              FThemeButtonSize.cy := FThemeButtonSize.cx;
            end;
        end;

      FCheckBoxTheme := {0;//} OpenThemeDataForDpi(0, VSCLASS_BUTTON, Dpi, False);
      FDpiCheckTheme := FCheckBoxTheme <> 0;
      if not FDpiCheckTheme then
        begin
          if Dpi = SystemDpi then
            begin
              FCheckBoxTheme := OpenThemeData(0, VSCLASS_BUTTON);
              FDpiCheckTheme := True;
            end
          else
            FCheckBoxTheme := OpenThemeDataEx(0, VSCLASS_BUTTON, OTD_FORCE_RECT_SIZING);
        end;
      if FCheckBoxTheme <> 0 then
        begin
          FCheckBoxThemeExist := IsThemePartDefined(FCheckBoxTheme, BP_CHECKBOX, 0);
          if not (FCheckBoxThemeExist and Succeeded(GetThemePartSize(FCheckBoxTheme, 0, BP_CHECKBOX, 0, nil, TS_TRUE, FThemeCheckBoxSize))) then
            begin
              FThemeCheckBoxSize.cx := 13 * Dpi div SystemDpi;
              FThemeCheckBoxSize.cx := FThemeCheckBoxSize.cx or 1; // Make it odd
              FThemeCheckBoxSize.cy := FThemeButtonSize.cx;
            end;
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
      DrawTextEx(DC, 'Wq', 1, R, DT_CALCRECT or DT_LEFT or DT_NOPREFIX, nil);
      FButtonSize.cx := Round((R.Bottom / 4) * 3) or 1;
      SelectObject(DC, SaveFont);
    finally
      ReleaseDC(FHandle, DC);
    end;
  FButtonSize.cy := FButtonSize.cx;
end;

procedure TTreeView.UpdateCheckSize;
var
  SystemDpi: UINT;
  Ok: Boolean;
  Bitmap: HBITMAP;
  BitmapSize: TBitmap;
begin
  SystemDpi := GetDpiForSystem;
  Ok := False;
  Bitmap := LoadBitmap(0, PChar(OBM_CHECKBOXES));
  if Bitmap <> 0 then
    begin
      if GetObject(Bitmap, SizeOf(BitmapSize), @BitmapSize) = SizeOf(BitmapSize) then
        begin
          FCheckBoxSize.cx := BitmapSize.bmWidth div 4;
          FCheckBoxSize.cy := BitmapSize.bmHeight div 3;
          if Dpi <> SystemDpi then
            begin
              FCheckBoxSize.cx := FCheckBoxSize.cx * Integer(Dpi) div Integer(SystemDpi);
              FCheckBoxSize.cy := FCheckBoxSize.cy * Integer(Dpi) div Integer(SystemDpi);
            end;
          Ok := True;
        end;
      DeleteObject(Bitmap);
    end;

  if not Ok then
    begin
      FCheckBoxSize.cx := 13 * Dpi div SystemDpi;
      FCheckBoxSize.cy := FCheckBoxSize.cx;
    end;
end;

function TTreeView.GetButtonSize: TSize;
begin
  if Themed and ButtonThemeExist then Result := FThemeButtonSize
                                 else Result := FButtonSize;
end;

function TTreeView.GetCheckBoxSize: TSize;
begin
  if CheckBoxThemeExist then Result := FThemeCheckBoxSize
                        else Result := FCheckBoxSize;
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

function TTreeView.GetStateImageListIconSize: TSize;
begin
  if FStateImageList <> 0 then
    Result := FStateImageListIconSize
  else
    Result := CheckBoxSize;
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
          Result := DefWindowProc(AWindow, AMsg, AWParam, ALParam);
          if Result = 0 then Exit;
          InitLibs;
          TreeView := TTreeView.Create;
          TreeView.FHandle := AWindow;
          {$IFDEF WIN64}
          SetWindowLongPtr(AWindow, 0, LONG_PTR(TreeView));
          {$ELSE}
          SetWindowLong(AWindow, 0, Integer(TreeView));
          {$ENDIF}
          TreeView.WndProc(AMsg, AWParam, ALParam);
        end;
      WM_NCDESTROY:
        begin
          {$IFDEF WIN64}
          TreeView := TTreeView(GetWindowLongPtr(AWindow, 0));
          {$ELSE}
          TreeView := TTreeView(GetWindowLong(AWindow, 0));
          {$ENDIF}
          if Assigned(TreeView) then
            begin
              TreeView.WndProc(AMsg, AWParam, ALParam);
              TreeView.Free;
            end;
          Result := DefWindowProc(AWindow, AMsg, AWParam, ALParam);
        end;
    else
      {$IFDEF WIN64}
      TreeView := TTreeView(GetWindowLongPtr(AWindow, 0));
      {$ELSE}
      TreeView := TTreeView(GetWindowLong(AWindow, 0));
      {$ENDIF}
      if Assigned(TreeView) then
        Result := TreeView.WndProc(AMsg, AWParam, ALParam)
      else
        Result := DefWindowProc(AWindow, AMsg, AWParam, ALParam);
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
  ClassAtom: ATOM;

function InitTreeViewLib: ATOM;
var
  WndClass: TWndClass;
begin
  EnterCriticalSection(LibsCS);
  if ClassAtom = 0 then
    begin
      ZeroMemory(@WndClass, SizeOf(WndClass));
      WndClass.style := CS_DBLCLKS or CS_GLOBALCLASS;
      WndClass.lpfnWndProc := @TreeViewWndProc;
      WndClass.cbWndExtra := SizeOf(TTreeView);
      WndClass.hInstance := HInstance;
      WndClass.lpszClassName := TreeViewClassName;
      ClassAtom := RegisterClass(WndClass);
    end;
  Result := ClassAtom;
  LeaveCriticalSection(LibsCS);
  {$IFDEF DEBUG}
  if Result = 0 then RaiseLastOSError;
  {$ENDIF}
end;

procedure DoneTreeViewLib;
begin
  if ClassAtom <> 0 then
    {$IFDEF DEBUG}
    if not UnregisterClass(PChar(ClassAtom), HInstance) then RaiseLastOSError;
    {$ELSE}
    UnregisterClass(PChar(ClassAtom), HInstance)
    {$ENDIF}
end;

initialization
  if ModuleIsLib then
    IsMultiThread := True;
  InitOSVersion;
  InitializeCriticalSection(LibsCS);
  {$IFDEF DEBUG}
  TestRegionsFind;
  {$ENDIF}

finalization
  DoneTreeViewLib;
  DoneLibs;
  DeleteCriticalSection(LibsCS);

end.
