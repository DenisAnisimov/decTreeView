unit decTreeView;

{$DEFINE ENABLE_GDIPLUS}

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
  TTVStateIconChangingEvent = procedure(Sender: TObject; Node: TTreeNode; var AAllowChange: Boolean) of object;
  TTVStateIconChangedEvent = procedure(Sender: TObject; Node: TTreeNode) of object;
  TTVGetItemSizeEvent = procedure(ASender: TCustomTreeView; Node: TTreeNode; var AWidth, AHeight: Integer) of object;

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
    FCheckboxes: Boolean;
    FExtraCheckboxesStates: TExtraCheckboxesStates;
    FOnGetItemSize: TTVGetItemSizeEvent;
    FOnStateIconChanging: TTVStateIconChangingEvent;
    FOnStateIconChanged: TTVStateIconChangedEvent;
    procedure SetAlternativeView(AAlternativeView: Boolean);
    procedure SetAutoCenter(AAutoCenter: Boolean);
    procedure UpdateCheckboxes;
    procedure SetCheckboxes(ACheckboxes: Boolean);
    procedure SetExtraCheckboxesStates(AExtraCheckboxesStates: TExtraCheckboxesStates);
    function IsSetExtraCheckboxesStates: Boolean;
  published
    property AlternativeView: Boolean read FAlternativeView write SetAlternativeView default True;
    property AutoCenter: Boolean read FAutoCenter write SetAutoCenter default True;
    property Checkboxes: Boolean read FCheckboxes write SetCheckboxes default False;
    property ExtraCheckboxesStates: TExtraCheckboxesStates read FExtraCheckboxesStates write SetExtraCheckboxesStates stored IsSetExtraCheckboxesStates;
    property OnGetItemSize: TTVGetItemSizeEvent read FOnGetItemSize write FOnGetItemSize;
    property OnStateIconChanging: TTVStateIconChangingEvent read FOnStateIconChanging write FOnStateIconChanging;
    property OnStateIconChanged: TTVStateIconChangedEvent read FOnStateIconChanged write FOnStateIconChanged;
  end;

implementation

uses
  SysUtils, decTreeViewLib;

{$if CompilerVersion < 19}
{$I decTreeViewFix.inc}
{$ifend}

constructor TdecTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlternativeView := True;
  FAutoCenter := True;
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
  //CheckboxesStyles: array[Boolean] of DWORD = (0, TVS_CHECKBOXES);
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
          {if ExtraCheckboxesStates = [] then
            Style := Style or CheckboxesStyles[Checkboxes];}
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
  NMTVCustomDraw: PNMTVCustomDraw;
  ItemWidth, ItemHeight: Integer;
  NMTVItemChange: PNMTVItemChange;
  AllowChange: Boolean;
begin
  case AMessage.NMHdr.code of
    TVN_GETITEMSIZE:
      begin
        if Assigned(FOnGetItemSize) then
          begin
            NMTVCustomDraw := PNMTVCustomDraw(AMessage.NMHdr);
            Node := TTreeNode(NMTVCustomDraw.nmcd.lItemlParam);
            ItemWidth := NMTVCustomDraw.nmcd.rc.Right;
            ItemHeight := NMTVCustomDraw.nmcd.rc.Bottom;
            FOnGetItemSize(Self, Node, ItemWidth, ItemHeight);
            NMTVCustomDraw.nmcd.rc.Right := ItemWidth;
            NMTVCustomDraw.nmcd.rc.Bottom := ItemHeight;
            AMessage.Result := 1;
          end
        else
          AMessage.Result := 0;
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
        if CanProcessItemChange and Assigned(FOnStateIconChanging) then
          begin
            NMTVItemChange := PNMTVItemChange(AMessage.NMHdr);
            Node := TTreeNode(NMTVItemChange.lParam);
            if Assigned(Node) then
              if (NMTVItemChange.uStateNew and TVIS_STATEIMAGEMASK) <> (NMTVItemChange.uStateOld and TVIS_STATEIMAGEMASK) then
                FOnStateIconChanged(Self, Node);
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

end.

