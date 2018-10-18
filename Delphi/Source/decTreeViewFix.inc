const
  SPI_GETWHEELSCROLLCHARS                   = $006C;
  SPI_GETCLIENTAREAANIMATION                = $1042;

  WM_MOUSEHWHEEL = $020E; 
  
  CCM_SETWINDOWTHEME      = CCM_FIRST + $B;
  
  CDRF_DOERASE            = $00000008; { draw the background }
  CDRF_SKIPPOSTPAINT      = $00000100; { don't draw the focus rect }

  NM_TVSTATEIMAGECHANGING = NM_FIRST-24;    { uses NMTVSTATEIMAGECHANGING struct, defined after HTREEITEM }

  TVS_EX_MULTISELECT          = $0002;
  TVS_EX_DOUBLEBUFFER         = $0004;
  TVS_EX_NOINDENTSTATE        = $0008;
  TVS_EX_RICHTOOLTIP          = $0010;
  TVS_EX_AUTOHSCROLL          = $0020;
  TVS_EX_FADEINOUTEXPANDOS    = $0040;
  TVS_EX_PARTIALCHECKBOXES    = $0080;
  TVS_EX_EXCLUSIONCHECKBOXES  = $0100;
  TVS_EX_DIMMEDCHECKBOXES     = $0200;
  TVS_EX_DRAWIMAGEASYNC       = $0400;
  
  TVIF_STATEEX            = $0100;
  TVIF_EXPANDEDIMAGE      = $0200;

  TVIS_EX_FLAT            = $0001;
  TVIS_EX_ALL             = $0002;
  TVIS_EX_DISABLED        = $0002;

  TVGN_NEXTSELECTED       = $000B;

type
  TNMTVStateImageChanging = record
    hdr: NMHDR;
    hti: HTREEITEM;
    iOldStateImageIndex: Integer;
    iNewStateImageIndex: Integer;
  end;
  PNMTVStateImageChanging = ^TNMTVStateImageChanging;

  TTVItemA = record
    mask: UINT;
    hItem: HTreeItem;
    state: UINT;
    stateMask: UINT;
    pszText: LPSTR;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
  end;
  PTVItemA = ^TTVItemA;
  TTVItemW = record
    mask: UINT;
    hItem: HTreeItem;
    state: UINT;
    stateMask: UINT;
    pszText: LPWSTR;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
  end;
  PTVItemW = ^TTVItemW;

  TTVItemExA = record
    mask: UINT;
    hItem: HTREEITEM;
    state: UINT;
    stateMask: UINT;
    pszText: LPSTR;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
    iIntegral: Integer;
    uStateEx: UINT;
    hwnd: HWND;
    iExpandedImage: Integer;
    iReserved: Integer;
  end;
  PTVItemExA = ^TTVItemExA;

  TTVItemExW = record
    mask: UINT;
    hItem: HTREEITEM;
    state: UINT;
    stateMask: UINT;
    pszText: LPWSTR;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
    iIntegral: Integer;
    uStateEx: UINT;
    hwnd: HWND;
    iExpandedImage: Integer;
    iReserved: Integer;
  end;
  PTVItemExW = ^TTVItemExW;

const  
  TVM_GETITEMSTATE            = TV_FIRST + 39;
  TVM_SETLINECOLOR            = TV_FIRST + 40;
  TVM_GETLINECOLOR            = TV_FIRST + 41;
  TVM_MAPACCIDTOHTREEITEM     = TV_FIRST + 42;
  TVM_MAPHTREEITEMTOACCID     = TV_FIRST + 43;
  TVM_SETEXTENDEDSTYLE        = TV_FIRST + 44;
  TVM_GETEXTENDEDSTYLE        = TV_FIRST + 45;

  TVM_GETSELECTEDCOUNT        = TV_FIRST + 70;
  TVM_SHOWINFOTIP             = TV_FIRST + 71;

  TVNRET_DEFAULT          = 0;
  TVNRET_SKIPOLD          = 1;
  TVNRET_SKIPNEW          = 2;

  TVN_ITEMCHANGINGA       = TVN_FIRST - 16;
  TVN_ITEMCHANGINGW       = TVN_FIRST - 17;
  TVN_ITEMCHANGEDA        = TVN_FIRST - 18;
  TVN_ITEMCHANGEDW        = TVN_FIRST - 19;
  TVN_ASYNCDRAW           = TVN_FIRST - 20;

  {$IFDEF UNICODE}
  TVN_ITEMCHANGING        = TVN_ITEMCHANGINGW;
  TVN_ITEMCHANGED         = TVN_ITEMCHANGEDW;
  {$ELSE}
  TVN_ITEMCHANGING        = TVN_ITEMCHANGINGA;
  TVN_ITEMCHANGED         = TVN_ITEMCHANGEDA;
  {$ENDIF}

type
  TNMTVItemChange = record
    hdr: NMHDR;
    uChanged: UINT;
    hItem: HTREEITEM;
    uStateNew: UINT;
    uStateOld: UINT;
    lParam: LPARAM;
  end;
  PNMTVItemChange = ^TNMTVItemChange;

  TNMTVAsyncDraw = record
    hdr: NMHDR;
    pimldp: PImageListDrawParams;  // the draw that failed
    hr: HRESULT;                   // why it failed
    hItem: HTREEITEM;              // item that failed to draw icon
    lParam: LPARAM;                // its data
    // Out Params
    dwRetFlags: DWORD;             // What listview should do on return
    iRetImageIndex: Integer;       // used if ADRF_DRAWIMAGE is returned
  end;
  PNMTVAsyncDraw = ^TNMTVAsyncDraw;

function TreeView_SetItemW(hwnd: HWND; const pitem: TTVItemW): Bool;
begin
  Result := SendMessage(hwnd, TVM_SETITEMW, 0, LPARAM(@pitem)) <> 0;
end;

const
  TTN_GETDISPINFOA         = TTN_FIRST - 0;
  TTN_NEEDTEXTA            = TTN_GETDISPINFOA;
  TTN_GETDISPINFOW         = TTN_FIRST - 10;
  TTN_NEEDTEXTW            = TTN_GETDISPINFOW;

  {$IFDEF UNICODE}
  TTN_GETDISPINFO         = TTN_GETDISPINFOW;
  TTN_NEEDTEXT            = TTN_NEEDTEXTW;
  {$ELSE}
  TTN_GETDISPINFO         = TTN_GETDISPINFOA;
  TTN_NEEDTEXT            = TTN_NEEDTEXTA;
  {$ENDIF}

  TTN_SHOW                = TTN_FIRST - 1;
  TTN_POP                 = TTN_FIRST - 2;

type
  TNMTTDispInfoA = record
    hdr: TNMHdr;
    lpszText: LPSTR;
    szText: array[0..79] of AnsiChar;
    hinst: HINST;
    uFlags: UINT;
    lParam: LPARAM;
  end;
  PNMTTDispInfoA = ^TNMTTDispInfoA;

  TNMTTDispInfoW = record
    hdr: TNMHdr;
    lpszText: LPWSTR;
    szText: array[0..79] of WideChar;
    hinst: HINST;
    uFlags: UINT;
    lParam: LPARAM;
  end;
  PNMTTDispInfoW = ^TNMTTDispInfoW;

const
  TTM_ADJUSTRECT          = WM_USER + 31;

const
  EVENT_OBJECT_INVOKED              = $8013;
  EVENT_OBJECT_TEXTSELECTIONCHANGED = $8014;

{$if CompilerVersion < 18}
function LresultFromObject(const riid: TGUID; wParam: WPARAM; punk: IUnknown): LRESULT; stdcall; external 'oleacc.dll' name 'LresultFromObject';
function AccessibleObjectFromWindow(hwnd: THandle; dwId: DWORD; const riid: TGUID; out ppvObject): HRESULT; stdcall; external 'oleacc.dll' name 'AccessibleObjectFromWindow';

const
  AccessibilityMajorVersion = 1;
  AccessibilityMinorVersion = 1;

  LIBID_Accessibility: TGUID = '{1EA4DBF0-3C3B-11CF-810C-00AA00389B71}';

  IID_IAccessible: TGUID = '{618736E0-3C3D-11CF-810C-00AA00389B71}';
  IID_IAccessibleHandler: TGUID = '{03022430-ABC4-11D0-BDE2-00AA001A1953}';
  IID_IAccIdentity: TGUID = '{7852B78D-1CFD-41C1-A615-9C0C85960B5F}';
  IID_IAccPropServer: TGUID = '{76C0DBBB-15E0-4E7B-B61B-20EEEA2001E0}';
  IID_IAccPropServices: TGUID = '{6E26E776-04F0-495D-80E4-3330352E3169}';
  CLASS_CAccPropServices: TGUID = '{B5F8350B-0548-48B1-A6EE-88BD00B4A5E7}';

type
  TOleEnum = type LongWord;

  SYSINT = Integer;
  AnnoScope = TOleEnum;

const
  ANNO_THIS      = $00000000;
  ANNO_CONTAINER = $00000001;

  DISPID_ACC_PARENT           = -5000;
  DISPID_ACC_CHILDCOUNT       = -5001;
  DISPID_ACC_CHILD            = -5002;
  DISPID_ACC_NAME             = -5003;
  DISPID_ACC_VALUE            = -5004;
  DISPID_ACC_DESCRIPTION      = -5005;
  DISPID_ACC_ROLE             = -5006;
  DISPID_ACC_STATE            = -5007;
  DISPID_ACC_HELP             = -5008;
  DISPID_ACC_HELPTOPIC        = -5009;
  DISPID_ACC_KEYBOARDSHORTCUT = -5010;
  DISPID_ACC_FOCUS            = -5011;
  DISPID_ACC_SELECTION        = -5012;
  DISPID_ACC_DEFAULTACTION    = -5013;
  DISPID_ACC_SELECT           = -5014;
  DISPID_ACC_LOCATION         = -5015;
  DISPID_ACC_NAVIGATE         = -5016;
  DISPID_ACC_HITTEST          = -5017;
  DISPID_ACC_DODEFAULTACTION  = -5018;

  NAVDIR_MIN                  = 0;
  NAVDIR_UP                   = $1;
  NAVDIR_DOWN                 = $2;
  NAVDIR_LEFT                 = $3;
  NAVDIR_RIGHT                = $4;
  NAVDIR_NEXT                 = $5;
  NAVDIR_PREVIOUS             = $6;
  NAVDIR_FIRSTCHILD           = $7;
  NAVDIR_LASTCHILD            = $8;
  NAVDIR_MAX                  = $9;

  SELFLAG_NONE                = 0;
  SELFLAG_TAKEFOCUS           = $1;
  SELFLAG_TAKESELECTION       = $2;
  SELFLAG_EXTENDSELECTION     = $4;
  SELFLAG_ADDSELECTION        = $8;
  SELFLAG_REMOVESELECTION     = $10;
  SELFLAG_VALID               = $1F;

  STATE_SYSTEM_NORMAL          = 0;
  STATE_SYSTEM_UNAVAILABLE     = $1;
  STATE_SYSTEM_SELECTED        = $2;
  STATE_SYSTEM_FOCUSED         = $4;
  STATE_SYSTEM_PRESSED         = $8;
  STATE_SYSTEM_CHECKED         = $10;
  STATE_SYSTEM_MIXED           = $20;
  STATE_SYSTEM_INDETERMINATE   = STATE_SYSTEM_MIXED;
  STATE_SYSTEM_READONLY        = $40;
  STATE_SYSTEM_HOTTRACKED      = $80;
  STATE_SYSTEM_DEFAULT         = $100;
  STATE_SYSTEM_EXPANDED        = $200;
  STATE_SYSTEM_COLLAPSED       = $400;
  STATE_SYSTEM_BUSY            = $800;
  STATE_SYSTEM_FLOATING        = $1000;
  STATE_SYSTEM_MARQUEED        = $2000;
  STATE_SYSTEM_ANIMATED        = $4000;
  STATE_SYSTEM_INVISIBLE       = $8000;
  STATE_SYSTEM_OFFSCREEN       = $10000;
  STATE_SYSTEM_SIZEABLE        = $20000;
  STATE_SYSTEM_MOVEABLE        = $40000;
  STATE_SYSTEM_SELFVOICING     = $80000;
  STATE_SYSTEM_FOCUSABLE       = $100000;
  STATE_SYSTEM_SELECTABLE      = $200000;
  STATE_SYSTEM_LINKED          = $400000;
  STATE_SYSTEM_TRAVERSED       = $800000;
  STATE_SYSTEM_MULTISELECTABLE = $1000000;
  STATE_SYSTEM_EXTSELECTABLE   = $2000000;
  STATE_SYSTEM_ALERT_LOW       = $4000000;
  STATE_SYSTEM_ALERT_MEDIUM    = $8000000;
  STATE_SYSTEM_ALERT_HIGH      = $10000000;
  STATE_SYSTEM_PROTECTED       = $20000000;
  STATE_SYSTEM_HASPOPUP        = $40000000;
  STATE_SYSTEM_VALID           = $3FFFFFFF;

  ROLE_SYSTEM_TITLEBAR           = $1;
  ROLE_SYSTEM_MENUBAR            = $2;
  ROLE_SYSTEM_SCROLLBAR          = $3;
  ROLE_SYSTEM_GRIP               = $4;
  ROLE_SYSTEM_SOUND              = $5;
  ROLE_SYSTEM_CURSOR             = $6;
  ROLE_SYSTEM_CARET              = $7;
  ROLE_SYSTEM_ALERT              = $8;
  ROLE_SYSTEM_WINDOW             = $9;
  ROLE_SYSTEM_CLIENT             = $A;
  ROLE_SYSTEM_MENUPOPUP          = $B;
  ROLE_SYSTEM_MENUITEM           = $C;
  ROLE_SYSTEM_TOOLTIP            = $D;
  ROLE_SYSTEM_APPLICATION        = $E;
  ROLE_SYSTEM_DOCUMENT           = $F;
  ROLE_SYSTEM_PANE               = $10;
  ROLE_SYSTEM_CHART              = $11;
  ROLE_SYSTEM_DIALOG             = $12;
  ROLE_SYSTEM_BORDER             = $13;
  ROLE_SYSTEM_GROUPING           = $14;
  ROLE_SYSTEM_SEPARATOR          = $15;
  ROLE_SYSTEM_TOOLBAR            = $16;
  ROLE_SYSTEM_STATUSBAR          = $17;
  ROLE_SYSTEM_TABLE              = $18;
  ROLE_SYSTEM_COLUMNHEADER       = $19;
  ROLE_SYSTEM_ROWHEADER          = $1A;
  ROLE_SYSTEM_COLUMN             = $1B;
  ROLE_SYSTEM_ROW                = $1C;
  ROLE_SYSTEM_CELL               = $1D;
  ROLE_SYSTEM_LINK               = $1E;
  ROLE_SYSTEM_HELPBALLOON        = $1F;
  ROLE_SYSTEM_CHARACTER          = $20;
  ROLE_SYSTEM_LIST               = $21;
  ROLE_SYSTEM_LISTITEM           = $22;
  ROLE_SYSTEM_OUTLINE            = $23;
  ROLE_SYSTEM_OUTLINEITEM        = $24;
  ROLE_SYSTEM_PAGETAB            = $25;
  ROLE_SYSTEM_PROPERTYPAGE       = $26;
  ROLE_SYSTEM_INDICATOR          = $27;
  ROLE_SYSTEM_GRAPHIC            = $28;
  ROLE_SYSTEM_STATICTEXT         = $29;
  ROLE_SYSTEM_TEXT               = $2A;
  ROLE_SYSTEM_PUSHBUTTON         = $2B;
  ROLE_SYSTEM_CHECKBUTTON        = $2C;
  ROLE_SYSTEM_RADIOBUTTON        = $2D;
  ROLE_SYSTEM_COMBOBOX           = $2E;
  ROLE_SYSTEM_DROPLIST           = $2F;
  ROLE_SYSTEM_PROGRESSBAR        = $30;
  ROLE_SYSTEM_DIAL               = $31;
  ROLE_SYSTEM_HOTKEYFIELD        = $32;
  ROLE_SYSTEM_SLIDER             = $33;
  ROLE_SYSTEM_SPINBUTTON         = $34;
  ROLE_SYSTEM_DIAGRAM            = $35;
  ROLE_SYSTEM_ANIMATION          = $36;
  ROLE_SYSTEM_EQUATION           = $37;
  ROLE_SYSTEM_BUTTONDROPDOWN     = $38;
  ROLE_SYSTEM_BUTTONMENU         = $39;
  ROLE_SYSTEM_BUTTONDROPDOWNGRID = $3A;
  ROLE_SYSTEM_WHITESPACE         = $3B;
  ROLE_SYSTEM_PAGETABLIST        = $3C;
  ROLE_SYSTEM_CLOCK              = $3D;

  CHILDID_SELF = 0;

type
  IAccessible = interface;
  IAccessibleDisp = dispinterface;
  IAccessibleHandler = interface;
  IAccIdentity = interface;
  IAccPropServer = interface;
  IAccPropServices = interface;

  CAccPropServices = IAccPropServices;

  wireHWND = ^_RemotableHandle;
  wireHMENU = ^_RemotableHandle;
  PByte1 = ^Byte;
  PUserType1 = ^TGUID;

  __MIDL_IWinTypes_0009 = record
    case Integer of
      0: (hInproc: Integer);
      1: (hRemote: Integer);
  end;

  _RemotableHandle = record
    fContext: Integer;
    u: __MIDL_IWinTypes_0009;
  end;

  IAccessible = interface(IDispatch)
    ['{618736E0-3C3D-11CF-810C-00AA00389B71}']
    function Get_accParent(out ppdispParent: IDispatch): HResult; stdcall;
    function Get_accChildCount(out pcountChildren: Integer): HResult; stdcall;
    function Get_accChild(varChild: OleVariant; out ppdispChild: IDispatch): HResult; stdcall;
    function Get_accName(varChild: OleVariant; out pszName: WideString): HResult; stdcall;
    function Get_accValue(varChild: OleVariant; out pszValue: WideString): HResult; stdcall;
    function Get_accDescription(varChild: OleVariant; out pszDescription: WideString): HResult; stdcall;
    function Get_accRole(varChild: OleVariant; out pvarRole: OleVariant): HResult; stdcall;
    function Get_accState(varChild: OleVariant; out pvarState: OleVariant): HResult; stdcall;
    function Get_accHelp(varChild: OleVariant; out pszHelp: WideString): HResult; stdcall;
    function Get_accHelpTopic(out pszHelpFile: WideString; varChild: OleVariant;
                              out pidTopic: Integer): HResult; stdcall;
    function Get_accKeyboardShortcut(varChild: OleVariant; out pszKeyboardShortcut: WideString): HResult; stdcall;
    function Get_accFocus(out pvarChild: OleVariant): HResult; stdcall;
    function Get_accSelection(out pvarChildren: OleVariant): HResult; stdcall;
    function Get_accDefaultAction(varChild: OleVariant; out pszDefaultAction: WideString): HResult; stdcall;
    function accSelect(flagsSelect: Integer; varChild: OleVariant): HResult; stdcall;
    function accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
                         out pcyHeight: Integer; varChild: OleVariant): HResult; stdcall;
    function accNavigate(navDir: Integer; varStart: OleVariant; out pvarEndUpAt: OleVariant): HResult; stdcall;
    function accHitTest(xLeft: Integer; yTop: Integer; out pvarChild: OleVariant): HResult; stdcall;
    function accDoDefaultAction(varChild: OleVariant): HResult; stdcall;
    function Set_accName(varChild: OleVariant; const pszName: WideString): HResult; stdcall;
    function Set_accValue(varChild: OleVariant; const pszValue: WideString): HResult; stdcall;
  end;

  IAccessibleDisp = dispinterface
    ['{618736E0-3C3D-11CF-810C-00AA00389B71}']
    property accParent: IDispatch readonly dispid -5000;
    property accChildCount: Integer readonly dispid -5001;
    property accChild[varChild: OleVariant]: IDispatch readonly dispid -5002;
    property accName[varChild: OleVariant]: WideString dispid -5003;
    property accValue[varChild: OleVariant]: WideString dispid -5004;
    property accDescription[varChild: OleVariant]: WideString readonly dispid -5005;
    property accRole[varChild: OleVariant]: OleVariant readonly dispid -5006;
    property accState[varChild: OleVariant]: OleVariant readonly dispid -5007;
    property accHelp[varChild: OleVariant]: WideString readonly dispid -5008;
    property accHelpTopic[out pszHelpFile: WideString; varChild: OleVariant]: Integer readonly dispid -5009;
    property accKeyboardShortcut[varChild: OleVariant]: WideString readonly dispid -5010;
    property accFocus: OleVariant readonly dispid -5011;
    property accSelection: OleVariant readonly dispid -5012;
    property accDefaultAction[varChild: OleVariant]: WideString readonly dispid -5013;
    procedure accSelect(flagsSelect: Integer; varChild: OleVariant); dispid -5014;
    procedure accLocation(out pxLeft: Integer; out pyTop: Integer; out pcxWidth: Integer;
                          out pcyHeight: Integer; varChild: OleVariant); dispid -5015;
    function accNavigate(navDir: Integer; varStart: OleVariant): OleVariant; dispid -5016;
    function accHitTest(xLeft: Integer; yTop: Integer): OleVariant; dispid -5017;
    procedure accDoDefaultAction(varChild: OleVariant); dispid -5018;
  end;

  IAccessibleHandler = interface(IUnknown)
    ['{03022430-ABC4-11D0-BDE2-00AA001A1953}']
    function AccessibleObjectFromID(hwnd: Integer; lObjectID: Integer; out pIAccessible: IAccessible): HResult; stdcall;
  end;

  IAccIdentity = interface(IUnknown)
    ['{7852B78D-1CFD-41C1-A615-9C0C85960B5F}']
    function GetIdentityString(dwIDChild: LongWord; out ppIDString: PByte1;
                               out pdwIDStringLen: LongWord): HResult; stdcall;
  end;

  IAccPropServer = interface(IUnknown)
    ['{76C0DBBB-15E0-4E7B-B61B-20EEEA2001E0}']
    function GetPropValue(var pIDString: Byte; dwIDStringLen: LongWord; idProp: TGUID;
                          out pvarValue: OleVariant; out pfHasProp: Integer): HResult; stdcall;
  end;

  IAccPropServices = interface(IUnknown)
    ['{6E26E776-04F0-495D-80E4-3330352E3169}']
    function SetPropValue(var pIDString: Byte; dwIDStringLen: LongWord; idProp: TGUID;
                          var_: OleVariant): HResult; stdcall;
    function SetPropServer(var pIDString: Byte; dwIDStringLen: LongWord; var paProps: TGUID;
                           cProps: SYSINT; const pServer: IAccPropServer; AnnoScope: AnnoScope): HResult; stdcall;
    function ClearProps(var pIDString: Byte; dwIDStringLen: LongWord; var paProps: TGUID;
                        cProps: SYSINT): HResult; stdcall;
    function SetHwndProp(var hwnd: _RemotableHandle; idObject: LongWord; idChild: LongWord;
                         idProp: TGUID; var_: OleVariant): HResult; stdcall;
    function SetHwndPropStr(var hwnd: _RemotableHandle; idObject: LongWord; idChild: LongWord;
                            idProp: TGUID; str: PWideChar): HResult; stdcall;
    function SetHwndPropServer(var hwnd: _RemotableHandle; idObject: LongWord; idChild: LongWord;
                               var paProps: TGUID; cProps: SYSINT; const pServer: IAccPropServer;
                               AnnoScope: AnnoScope): HResult; stdcall;
    function ClearHwndProps(var hwnd: _RemotableHandle; idObject: LongWord; idChild: LongWord;
                            var paProps: TGUID; cProps: SYSINT): HResult; stdcall;
    function ComposeHwndIdentityString(var hwnd: _RemotableHandle; idObject: LongWord;
                                       idChild: LongWord; out ppIDString: PByte1;
                                       out pdwIDStringLen: LongWord): HResult; stdcall;
    function DecomposeHwndIdentityString(var pIDString: Byte; dwIDStringLen: LongWord;
                                         out phwnd: wireHWND; out pidObject: LongWord;
                                         out pidChild: LongWord): HResult; stdcall;
    function SetHmenuProp(var hmenu: _RemotableHandle; idChild: LongWord; idProp: TGUID;
                          var_: OleVariant): HResult; stdcall;
    function SetHmenuPropStr(var hmenu: _RemotableHandle; idChild: LongWord; idProp: TGUID;
                             str: PWideChar): HResult; stdcall;
    function SetHmenuPropServer(var hmenu: _RemotableHandle; idChild: LongWord; var paProps: TGUID;
                                cProps: SYSINT; const pServer: IAccPropServer; AnnoScope: AnnoScope): HResult; stdcall;
    function ClearHmenuProps(var hmenu: _RemotableHandle; idChild: LongWord; var paProps: TGUID;
                             cProps: SYSINT): HResult; stdcall;
    function ComposeHmenuIdentityString(var hmenu: _RemotableHandle; idChild: LongWord;
                                        out ppIDString: PByte1; out pdwIDStringLen: LongWord): HResult; stdcall;
    function DecomposeHmenuIdentityString(var pIDString: Byte; dwIDStringLen: LongWord;
                                          out phmenu: wireHMENU; out pidChild: LongWord): HResult; stdcall;
  end;
{$ifend}
