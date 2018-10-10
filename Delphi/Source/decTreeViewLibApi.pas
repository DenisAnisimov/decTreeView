unit decTreeViewLibApi;

interface

{$if CompilerVersion > 15}
  {$DEFINE SUPPORTS_INLINE}
{$ifend}

uses
  Windows, {$IFDEF DLL_MODE}decCommCtrl{$ELSE}CommCtrl{$ENDIF};

type
  HTHEME = THandle;

const
  TVS_EX_AUTOCENTER      = $80000000; // Non standard
  TVS_EX_VERTDIRECTION   = $40000000; // Non standard
  TVS_EX_INVERTDIRECTION = $20000000; // Non standard

const
  TVM_SETBORDER = TV_FIRST + 35;
  TVSBF_XBORDER = $00000001;
  TVSBF_YBORDER = $00000002;

  TVM_GETBORDER = TV_FIRST + 100; // Non standard

function TreeView_SetBorder(AWnd: HWND; AFlags, AXBorder, AYBorder: UINT): Integer; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetXBorder(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetYBorder(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

const
  TVM_SETSPACE = TV_FIRST + 101; // Non standard
  TVM_GETSPACE = TV_FIRST + 102; // Non standard

  TVSBF_XSPACE = $00000001;
  TVSBF_YSPACE = $00000002;

  TVM_SETGROUPSPACE = TV_FIRST + 103; // Non standard
  TVM_GETGROUPSPACE = TV_FIRST + 104; // Non standard

function TreeView_SetSpace(AWnd: HWND; AFlags, AXSpace, AYSpace: UINT): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetXSpace(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetYSpace(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_SetGroupSpace(AWnd: HWND; AGroupSpace: UINT): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetGroupSpace(AWnd: HWND): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

const
  TVM_GETITEMCHILDCOUNT = TV_FIRST + 107; // Non standard
  TVM_GETITEMCHILD      = TV_FIRST + 108; // Non standard

function TreeView_GetItemChildCount(AWnd: HWND; AItem: HTreeItem): UINT; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
function TreeView_GetItemChild(AWnd: HWND; AItem: HTreeItem; AIndex: UINT): HTreeItem; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

const
  TVM_UPDATEITEMSIZE = TV_FIRST + 109; // Non standard
  TVM_INVALIDATEITEM = TV_FIRST + 110; // Non standard

procedure TreeView_UpdateItemSize(AWnd: HWND; AItem: HTreeItem); {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}
procedure TreeView_InvalidateItem(AWnd: HWND; AItem: HTreeItem; ARect: PRect = nil); {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

const
  TVM_GETTHEME = TV_FIRST + 111; // Non standard
  TVT_TREEVIEW = 0;
  TVT_BUTTON   = 1;
  TVT_WINDOW   = 2;

function TreeView_GetTheme(AWnd: HWND; ATheme: UINT): HTHEME; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

const
  TVM_GETOPTIMALSIZE = TV_FIRST + 112; // Non standard

function TreeView_GetOptimalSize(AWnd: HWND): TSize; {$IFDEF SUPPORTS_INLINE}inline;{$ENDIF}

type
  TNMTVGetItemSize = record
    nmcd: TNMCustomDraw;
    iLevel: Integer;
    StateImageRect: TRect;
    ImageRect: TRect;
    TextRect: TRect;
    ButtonRect: TRect;
  end;
  PNMTVGetItemSize = ^TNMTVGetItemSize;

const
  TVN_GETITEMSIZE     = TVN_FIRST - 100; // Non standard

  TVN_ITEMMOUSEENTER  = TVN_FIRST - 101; // Non standard
  TVN_ITEMMOUSEMOVE   = TVN_FIRST - 102; // Non standard
  TVN_ITEMMOUSELEAVE  = TVN_FIRST - 103; // Non standard
  TVN_ITEMLMOUSEDOWN  = TVN_FIRST - 104; // Non standard
  TVN_ITEMCLICK       = TVN_FIRST - 105; // Non standard
  TVN_ITEMLMOUSEUP    = TVN_FIRST - 106; // Non standard

implementation

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

function TreeView_SetSpace(AWnd: HWND; AFlags, AXSpace, AYSpace: UINT): UINT;
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

function TreeView_SetGroupSpace(AWnd: HWND; AGroupSpace: UINT): UINT;
begin
  Result := SendMessage(AWnd, TVM_SETGROUPSPACE, 0, AGroupSpace);
end;

function TreeView_GetGroupSpace(AWnd: HWND): UINT;
begin
  Result := SendMessage(AWnd, TVM_SETGROUPSPACE, 0, 0);
end;

function TreeView_GetItemChildCount(AWnd: HWND; AItem: HTreeItem): UINT;
begin
  Result := SendMessage(AWnd, TVM_GETITEMCHILDCOUNT, 0, LPARAM(AItem));
end;

function TreeView_GetItemChild(AWnd: HWND; AItem: HTreeItem; AIndex: UINT): HTreeItem;
begin
  Result := HTreeItem(SendMessage(AWnd, TVM_GETITEMCHILD, AIndex, LPARAM(AItem)));
end;

procedure TreeView_UpdateItemSize(AWnd: HWND; AItem: HTreeItem);
begin
  SendMessage(AWnd, TVM_UPDATEITEMSIZE, 0, LPARAM(AItem));
end;

procedure TreeView_InvalidateItem(AWnd: HWND; AItem: HTreeItem; ARect: PRect = nil);
begin
  SendMessage(AWnd, TVM_INVALIDATEITEM, WPARAM(ARect), LPARAM(AItem));
end;

function TreeView_GetTheme(AWnd: HWND; ATheme: UINT): HTHEME;
begin
  Result := SendMessage(AWnd, TVM_GETTHEME, ATheme, 0);
end;

function TreeView_GetOptimalSize(AWnd: HWND): TSize;
begin
  SendMessage(AWnd, TVM_GETOPTIMALSIZE, 0, LPARAM(@Result));
end;

end.

