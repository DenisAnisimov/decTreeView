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

  TTVItem = TTVItemW;
  PTVItem = PTVItemW;

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

  TTVItemEx = TTVItemExW;
  PTVItemEx = PTVItemExW;

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

  TVN_ITEMCHANGING        = TVN_ITEMCHANGINGW;
  TVN_ITEMCHANGED         = TVN_ITEMCHANGEDW;

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
