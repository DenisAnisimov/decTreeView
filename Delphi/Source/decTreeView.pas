unit decTreeView;

{ $DEFINE ENABLE_GDIPLUS}

interface

{$if CompilerVersion >= 25}
{$LEGACYIFEND ON}
{$ifend}
{$IFDEF BPL_MODE}
  {$UNDEF ENABLE_GDIPLUS}
{$ENDIF}

uses
  Windows, Messages, CommCtrl, Classes, Controls, ComCtrls, Forms {$IFDEF ENABLE_GDIPLUS}, GDIPlus{$ENDIF};

type
  TTVStateIconChangingEvent = procedure(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean) of object;
  TTVStateIconChangedEvent = procedure(Sender: TObject; Node: TTreeNode) of object;
  TTVGetNodeSizeEvent = procedure(Sender: TCustomTreeView; Node: TTreeNode; var ANodeWidth, ANodeHeight: Integer) of object;

  TExtraCheckboxesState = (ecsMixed, ecsDimmed, ecsExclusion);
  TExtraCheckboxesStates = set of TExtraCheckboxesState;

  {$if CompilerVersion >= 23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$ifend}
  TdecTreeView = class(TTreeView)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure WMERASEBKGND(var AMessage: TMessage); message WM_ERASEBKGND;
    procedure GetNodeSize(ANode: TTreeNode; var AItemWidth, AItemHeight: Integer); dynamic;
    procedure CNNotify(var AMessage: TWMNotify); message CN_NOTIFY;
  private
    FInitCheckboxes: Boolean;
    FStateIndexesStream: TMemoryStream;
    procedure SaveStateIndexes;
    procedure RestoreStateIndexes;
    procedure SetStyle(AValue: UINT; AUseStyle: Boolean);
    procedure SetStyleEx(AValue: UINT; AUseStyle: Boolean);
  private
    FAlternativeView: Boolean;
    FAutoCenter: Boolean;
    FItemBorder: Integer;
    FHorzSpace: Integer;
    FVertSpace: Integer;
    FGroupSpace: Integer;
    FCheckboxes: Boolean;
    FExtraCheckboxesStates: TExtraCheckboxesStates;
    FOnGetItemSize: TTVGetNodeSizeEvent;
    FOnStateIconChanging: TTVStateIconChangingEvent;
    FOnStateIconChanged: TTVStateIconChangedEvent;
    procedure SetAlternativeView(AAlternativeView: Boolean);
    procedure SetAutoCenter(AAutoCenter: Boolean);
    procedure SetItemBorder(AItemBorder: Integer);
    procedure SetHorzSpace(AHorzSpace: Integer);
    procedure SetVertSpace(AVertSpace: Integer);
    procedure SetGroupSpace(AGroupSpace: Integer);
    procedure UpdateCheckboxes;
    procedure SetCheckboxes(ACheckboxes: Boolean);
    procedure SetExtraCheckboxesStates(AExtraCheckboxesStates: TExtraCheckboxesStates);
    function IsSetExtraCheckboxesStates: Boolean;
  published
    property AlternativeView: Boolean read FAlternativeView write SetAlternativeView default True;
    property AutoCenter: Boolean read FAutoCenter write SetAutoCenter default True;
    property ItemBorder: Integer read FItemBorder write SetItemBorder default 2;
    property HorzSpace: Integer read FHorzSpace write SetHorzSpace default 30;
    property VertSpace: Integer read FVertSpace write SetVertSpace default 10;
    property GroupSpace: Integer read FGroupSpace write SetGroupSpace default 3;
    property Checkboxes: Boolean read FCheckboxes write SetCheckboxes default False;
    property ExtraCheckboxesStates: TExtraCheckboxesStates read FExtraCheckboxesStates write SetExtraCheckboxesStates stored IsSetExtraCheckboxesStates;
    property OnGetItemSize: TTVGetNodeSizeEvent read FOnGetItemSize write FOnGetItemSize;
    property OnStateIconChanging: TTVStateIconChangingEvent read FOnStateIconChanging write FOnStateIconChanging;
    property OnStateIconChanged: TTVStateIconChangedEvent read FOnStateIconChanged write FOnStateIconChanged;
  end;

implementation

uses
  SysUtils, ImgList, decTreeViewLibApi {$IFNDEF DLL_TEST_MODE}, decTreeViewLib{$ENDIF};

{$if CompilerVersion < 19}
{$I decTreeViewFix.inc}
{$ifend}

{$IFDEF DLL_TEST_MODE}
type
  TInitTreeViewLib = function: ATOM; stdcall;

var
  TreeViewLib: HMODULE;
  InitTreeViewLibProc: TInitTreeViewLib;

const
  TreeViewClassName: PChar = 'decTreeView';

function InitTreeViewLib: ATOM;
var
  DllName: string;
  Error: DWORD;
begin
  if TreeViewLib = 0 then
    begin
      DllName := ExtractFilePath(GetModuleName(HInstance)) +
        {$IFDEF WIN64}'decTreeViewDll.64.dll'{$ELSE}'decTreeViewDll.32.dll'{$ENDIF};
      TreeViewLib := LoadLibrary(PChar(DllName));
      if TreeViewLib = 0 then
        RaiseLastOSError;
      @InitTreeViewLibProc := GetProcAddress(TreeViewLib, 'InitTreeViewLib');
      if not Assigned(InitTreeViewLibProc) then
        RaiseLastOSError;
    end;
  Result := InitTreeViewLibProc;
end;

procedure DoneTreeViewLib;
begin
  if TreeViewLib <> 0 then
    FreeLibrary(TreeViewLib);
end;
{$ENDIF}

constructor TdecTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlternativeView := True;
  FAutoCenter := True;
  FItemBorder := 2;
  FHorzSpace := 30;
  FVertSpace := 10;
  FGroupSpace := 3;
end;

destructor TdecTreeView.Destroy;
begin
  FreeAndNil(FStateIndexesStream);
  inherited Destroy;
end;

type
  TWinControlAccess = class(TWinControl);

procedure TdecTreeView.CreateParams(var AParams: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
  LineStyles: array[Boolean] of DWORD = (0, TVS_HASLINES);
  RootStyles: array[Boolean] of DWORD = (0, TVS_LINESATROOT);
  ButtonStyles: array[Boolean] of DWORD = (0, TVS_HASBUTTONS);
  EditStyles: array[Boolean] of DWORD = (TVS_EDITLABELS, 0);
  HideSelections: array[Boolean] of DWORD = (TVS_SHOWSELALWAYS, 0);
  DragStyles: array[TDragMode] of DWORD = (TVS_DISABLEDRAGDROP, 0);
  RTLStyles: array[Boolean] of DWORD = (0, TVS_RTLREADING);
  ToolTipStyles: array[Boolean] of DWORD = (TVS_NOTOOLTIPS, TVS_INFOTIP);
  AutoExpandStyles: array[Boolean] of DWORD = (0, TVS_SINGLEEXPAND);
  HotTrackStyles: array[Boolean] of DWORD = (0, TVS_TRACKSELECT);
  RowSelectStyles: array[Boolean] of DWORD = (0, TVS_FULLROWSELECT);
var
  GrandPa: procedure(var AParams: TCreateParams) of object;
begin
  if AlternativeView then
    begin
      with TMethod(GrandPa) do
        begin
          Code := @TWinControlAccess.CreateParams;
          Data := Self;
        end;
      GrandPa(AParams);

      InitTreeViewLib;
      CreateSubClass(AParams, TreeViewClassName);
      with AParams do
        begin
          Style := Style or LineStyles[ShowLines] or BorderStyles[BorderStyle] or
            RootStyles[ShowRoot] or ButtonStyles[ShowButtons] or
            EditStyles[ReadOnly] or HideSelections[HideSelection] or
            DragStyles[DragMode] or RTLStyles[UseRightToLeftReading] or
            ToolTipStyles[ToolTips] or AutoExpandStyles[AutoExpand] or
            HotTrackStyles[HotTrack] or RowSelectStyles[RowSelect];
          if Ctl3D and NewStyleControls and (BorderStyle = bsSingle) then
            begin
              Style := Style and not WS_BORDER;
              ExStyle := AParams.ExStyle or WS_EX_CLIENTEDGE;
            end;
          WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
        end;
    end
  else
    inherited CreateParams(AParams);
end;

procedure TdecTreeView.CreateWnd;
var
  Style: UINT;
begin
  inherited CreateWnd;

  Items.BeginUpdate;
  try
    if AlternativeView then
      begin
        if AutoCenter then Style := TVS_EX_AUTOCENTER
                      else Style := 0;
        SendMessage(Handle, TVM_SETEXTENDEDSTYLE, Integer(TVS_EX_AUTOCENTER), Integer(Style));
        TreeView_SetBorder(Handle, TVSBF_XBORDER or TVSBF_YBORDER, FItemBorder, FItemBorder);
        TreeView_SetSpace(Handle, TVSBF_XSPACE or TVSBF_YSPACE, FHorzSpace, FVertSpace);
        TreeView_SetGroupSpace(Handle, FGroupSpace);
      end;

    if Checkboxes then
      begin
        FInitCheckboxes := True;
        try
          SaveStateIndexes;

          if ExtraCheckboxesStates = [] then
            SetStyle(TVS_CHECKBOXES, True)
          else
            begin
              Style := 0;
              if ecsMixed in ExtraCheckboxesStates then
                Style := Style or TVS_EX_PARTIALCHECKBOXES;
              if ecsDimmed in ExtraCheckboxesStates then
                Style := Style or TVS_EX_DIMMEDCHECKBOXES;
              if ecsExclusion in ExtraCheckboxesStates then
                Style := Style or TVS_EX_EXCLUSIONCHECKBOXES;
              SendMessage(Handle, TVM_SETEXTENDEDSTYLE,
                TVS_EX_PARTIALCHECKBOXES or TVS_EX_DIMMEDCHECKBOXES or TVS_EX_EXCLUSIONCHECKBOXES, Style);
            end;

          RestoreStateIndexes;

          if Assigned(StateImages) and StateImages.HandleAllocated then
            TreeView_SetImageList(Handle, StateImages.Handle, TVSIL_STATE)
        finally
          FInitCheckboxes := False;
        end;
      end;
  finally
    Items.EndUpdate;
  end;
end;

procedure TdecTreeView.WMERASEBKGND(var AMessage: TMessage);
begin
  if AlternativeView then
    AMessage.Result := 1
  else
    inherited;
end;

procedure TdecTreeView.GetNodeSize(ANode: TTreeNode; var AItemWidth, AItemHeight: Integer);
begin
  if Assigned(FOnGetItemSize) then
    FOnGetItemSize(Self, ANode, AItemWidth, AItemHeight);
end;

type
  TTreeNodesAccess = class(TTreeNodes);

procedure TdecTreeView.CNNotify(var AMessage: TWMNotify);

  function CanProcessItemChange: Boolean;
  begin
    {$if CompilerVersion < 18}
    Result := not TTreeNodesAccess(Items).Reading and not FInitCheckboxes;
    {$else}
    {$if CompilerVersion < 22}
    Result := not TTreeNodesAccess(Items).Reading and not (csRecreating in ControlState) and not FInitCheckboxes;
    {$else}
    Result := not Reading and not (csRecreating in ControlState) and not FInitCheckboxes;
    {$ifend}
    {$ifend}
  end;

var
  Node: TTreeNode;
  NMTVGetItemSize: PNMTVGetItemSize;
  ItemWidth, ItemHeight: Integer;
  NMTVItemChange: PNMTVItemChange;
  AllowChange: Boolean;
begin
  case AMessage.NMHdr.code of
    TVN_GETITEMSIZE:
      begin
        NMTVGetItemSize := PNMTVGetItemSize(AMessage.NMHdr);
        Node := TTreeNode(NMTVGetItemSize.nmcd.lItemlParam);
        ItemWidth := NMTVGetItemSize.nmcd.rc.Right;
        ItemHeight := NMTVGetItemSize.nmcd.rc.Bottom;
        GetNodeSize(Node, ItemWidth, ItemHeight);
        NMTVGetItemSize.nmcd.rc.Right := ItemWidth;
        NMTVGetItemSize.nmcd.rc.Bottom := ItemHeight;
        AMessage.Result := 1;
      end;
    TVN_ITEMCHANGING:
      begin
        AMessage.Result := 0;
        if CanProcessItemChange and Assigned(FOnStateIconChanging) then
          begin
            NMTVItemChange := PNMTVItemChange(AMessage.NMHdr);
            Node := TTreeNode(NMTVItemChange.lParam);
            if Assigned(Node) then
              if (NMTVItemChange.uStateNew and TVIS_STATEIMAGEMASK) <> (NMTVItemChange.uStateOld and TVIS_STATEIMAGEMASK) then
                begin
                  AllowChange := True;
                  FOnStateIconChanging(Self, Node, AllowChange);
                  if not AllowChange then
                    AMessage.Result := 1;
                end;
          end;
      end;
    TVN_ITEMCHANGED:
      begin
        AMessage.Result := 0;
        if CanProcessItemChange then
          begin
            NMTVItemChange := PNMTVItemChange(AMessage.NMHdr);
            Node := TTreeNode(NMTVItemChange.lParam);
            if Assigned(Node) then
              if (NMTVItemChange.uStateNew and TVIS_STATEIMAGEMASK) <> (NMTVItemChange.uStateOld and TVIS_STATEIMAGEMASK) then
                begin
                  Node.StateIndex := (NMTVItemChange.uStateNew and TVIS_STATEIMAGEMASK) shr 12;
                  if Assigned(FOnStateIconChanged) then
                    FOnStateIconChanged(Self, Node);
                end
          end;
      end;
  else
    inherited;
  end
end;

procedure TdecTreeView.SaveStateIndexes;
var
  Count: Integer;
  Node: TTreeNode;
  IconIndex: Integer;
begin
  if Assigned(FStateIndexesStream) then
    FStateIndexesStream.Clear
  else
    FStateIndexesStream := TMemoryStream.Create;
  Count := Items.Count;
  FStateIndexesStream.WriteBuffer(Count, SizeOf(Count));
  Node := Items.GetFirstNode;
  while Assigned(Node) do
    begin
      IconIndex := Node.StateIndex;
      FStateIndexesStream.WriteBuffer(IconIndex, SizeOf(IconIndex));
      Node := Node.GetNext;
    end;
end;

procedure TdecTreeView.RestoreStateIndexes;
var
  Count, Index: Integer;
  Node: TTreeNode;
  IconIndex: Integer;
  Item: TTVItem;
begin
  FStateIndexesStream.Position := 0;
  FStateIndexesStream.ReadBuffer(Count, SizeOf(Count));
  Index := 0;
  Node := Items.GetFirstNode;
  while (Index < Count) and Assigned(Node) do
    begin
      FStateIndexesStream.ReadBuffer(IconIndex, SizeOf(IconIndex));

      if IconIndex = -1 then
        IconIndex := 0
      else
        if IconIndex >= 0 then
          Dec(IconIndex);
      with Item do
        begin
          mask := TVIF_STATE or TVIF_HANDLE;
          stateMask := TVIS_STATEIMAGEMASK;
          hItem := Node.ItemId;
          state := IndexToStateImageMask(IconIndex + 1);
        end;
      TreeView_SetItemW(Handle, Item);

      Inc(Index);
      Node := Node.GetNext;
    end;
  FStateIndexesStream.Clear;
end;

procedure TdecTreeView.SetStyle(AValue: UINT; AUseStyle: Boolean);
var
  Style: UINT;
begin
  if HandleAllocated then
    begin
      Style := GetWindowLong(Handle, GWL_STYLE);
      if AUseStyle then Style := Style or AValue
                   else Style := Style and not AValue;
      SetWindowLong(Handle, GWL_STYLE, Style);
    end;
end;

procedure TdecTreeView.SetStyleEx(AValue: UINT; AUseStyle: Boolean);
var
  Style: UINT;
begin
  if HandleAllocated then
    begin
      if AUseStyle then Style := AValue
                   else Style := 0;
      SendMessage(Handle, TVM_SETEXTENDEDSTYLE, AValue, Style);
    end;
end;

procedure TdecTreeView.SetAlternativeView(AAlternativeView: Boolean);
begin
  if FAlternativeView = AAlternativeView then Exit;
  FAlternativeView := AAlternativeView;
  if HandleAllocated then
    RecreateWnd;
end;

procedure TdecTreeView.SetAutoCenter(AAutoCenter: Boolean);
begin
  if FAutoCenter = AAutoCenter then Exit;
  FAutoCenter := AAutoCenter;
  if HandleAllocated and AlternativeView then
    SetStyleEx(TVS_EX_AUTOCENTER, FAutoCenter);
end;

procedure TdecTreeView.SetItemBorder(AItemBorder: Integer);
begin
  if FItemBorder = AItemBorder then Exit;
  FItemBorder := AItemBorder;
  if HandleAllocated and AlternativeView then
    TreeView_SetBorder(Handle, TVSBF_XBORDER or TVSBF_YBORDER, FItemBorder, FItemBorder);
end;

procedure TdecTreeView.SetHorzSpace(AHorzSpace: Integer);
begin
  if FHorzSpace = AHorzSpace then Exit;
  FHorzSpace := AHorzSpace;
  if HandleAllocated and AlternativeView then
    TreeView_SetSpace(Handle, TVSBF_XSPACE, FHorzSpace, 0);
end;

procedure TdecTreeView.SetVertSpace(AVertSpace: Integer);
begin
  if FVertSpace = AVertSpace then Exit;
  FVertSpace := AVertSpace;
  if HandleAllocated and AlternativeView then
    TreeView_SetSpace(Handle, TVSBF_YSPACE, 0, FVertSpace);
end;

procedure TdecTreeView.SetGroupSpace(AGroupSpace: Integer);
begin
  if FGroupSpace = AGroupSpace then Exit;
  FGroupSpace := AGroupSpace;
  if HandleAllocated and AlternativeView then
    TreeView_SetGroupSpace(Handle, FGroupSpace);
end;

procedure TdecTreeView.UpdateCheckboxes;
var
  Style: UINT;
begin
  if HandleAllocated then
    if AlternativeView then
      begin
        Items.BeginUpdate;
        try
          FInitCheckboxes := True;
          try
            if Checkboxes then
              begin
                SaveStateIndexes;

                if ExtraCheckboxesStates = [] then
                  SetStyle(TVS_CHECKBOXES, True)
                else
                  begin
                    Style := 0;
                    if ecsMixed in ExtraCheckboxesStates then
                      Style := Style or TVS_EX_PARTIALCHECKBOXES;
                    if ecsDimmed in ExtraCheckboxesStates then
                      Style := Style or TVS_EX_DIMMEDCHECKBOXES;
                    if ecsExclusion in ExtraCheckboxesStates then
                      Style := Style or TVS_EX_EXCLUSIONCHECKBOXES;
                    SendMessage(Handle, TVM_SETEXTENDEDSTYLE,
                      TVS_EX_PARTIALCHECKBOXES or TVS_EX_DIMMEDCHECKBOXES or TVS_EX_EXCLUSIONCHECKBOXES, Style);
                  end;

                RestoreStateIndexes;

                if Assigned(StateImages) and StateImages.HandleAllocated then
                  TreeView_SetImageList(Handle, StateImages.Handle, TVSIL_STATE)
              end
            else
              begin
                SendMessage(Handle, TVM_SETEXTENDEDSTYLE,
                  TVS_EX_PARTIALCHECKBOXES or TVS_EX_DIMMEDCHECKBOXES or TVS_EX_EXCLUSIONCHECKBOXES, 0);
                SetStyle(TVS_CHECKBOXES, False);
              end;
          finally
            FInitCheckboxes := False;
          end;
        finally
          Items.EndUpdate;
        end;
      end
    else
      RecreateWnd;
end;

procedure TdecTreeView.SetCheckboxes(ACheckboxes: Boolean);
begin
  if FCheckboxes = ACheckboxes then Exit;
  FCheckboxes := ACheckboxes;
  UpdateCheckboxes;
end;

procedure TdecTreeView.SetExtraCheckboxesStates(AExtraCheckboxesStates: TExtraCheckboxesStates);
begin
  if FExtraCheckboxesStates = AExtraCheckboxesStates then Exit;
  FExtraCheckboxesStates := AExtraCheckboxesStates;
  if Checkboxes then
    UpdateCheckboxes;
end;

function TdecTreeView.IsSetExtraCheckboxesStates: Boolean;
begin
  Result := Checkboxes and (FExtraCheckboxesStates <> []);
end;

initialization

finalization
  {$IFDEF DLL_TEST_MODE}
  DoneTreeViewLib;
  {$ENDIF}


end.

