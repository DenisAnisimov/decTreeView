unit decTreeView;

{$DEFINE ENABLE_GDIPLUS}

interface

uses
  Windows, Messages, CommCtrl, Classes, Controls, ComCtrls, Forms {$IFDEF ENABLE_GDIPLUS}, GDIPlus{$ENDIF};

type
  TOnGetItemSize = procedure(ASender: TCustomTreeView; AItem: TTreeNode; var AWidth, AHeight: Integer) of object;

  TdecTreeView = class(TTreeView)
  public
    constructor Create(AOwner: TComponent); override;
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure CreateWnd; override;
    procedure WMERASEBKGND(var AMessage: TMessage); message WM_ERASEBKGND;
    procedure CNNotify(var AMessage: TWMNotifyTV); message CN_NOTIFY;
  private
    FAlternativeView: Boolean;
    FAutoCenter: Boolean;
    FOnGetItemSize: TOnGetItemSize;
    procedure SetAlternativeView(AAlternativeView: Boolean);
    procedure SetAutoCenter(AAutoCenter: Boolean);
  published
    property AlternativeView: Boolean read FAlternativeView write SetAlternativeView default True;
    property AutoCenter: Boolean read FAutoCenter write SetAutoCenter default True;
    property OnGetItemSize: TOnGetItemSize read FOnGetItemSize write FOnGetItemSize;
  end;

implementation

uses
  decTreeViewLib;

constructor TdecTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlternativeView := True;
  FAutoCenter := True;
end;

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
          Code := @TWinControl.CreateParams;
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
  ExtStyle: UINT;
begin
  inherited CreateWnd;
  if AlternativeView then
    begin
      ExtStyle := TreeView_GetExtendedStyle(Handle);
      if AutoCenter then ExtStyle := ExtStyle or TVS_EX_AUTOCENTER
                    else ExtStyle := ExtStyle and not TVS_EX_AUTOCENTER;
      TreeView_SetExtendedStyle(Handle, ExtStyle, (TVS_EX_AUTOCENTER));
    end;
end;

procedure TdecTreeView.WMERASEBKGND(var AMessage: TMessage);
begin
  if AlternativeView then
    AMessage.Result := 1
  else
    inherited;
end;

procedure TdecTreeView.CNNotify(var AMessage: TWMNotifyTV);
var
  Item: TTreeNode;
  ItemWidth, ItemHeight: Integer;
begin
  if AMessage.NMHdr.code = TVN_GETITEMSIZE then
    begin
      if Assigned(FOnGetItemSize) then
        begin
          Item := TTreeNode(AMessage.NMTVCustomDraw.nmcd.lItemlParam);
          ItemWidth := AMessage.NMTVCustomDraw.nmcd.rc.Right;
          ItemHeight := AMessage.NMTVCustomDraw.nmcd.rc.Bottom;
          FOnGetItemSize(Self, Item, ItemWidth, ItemHeight);
          AMessage.NMTVCustomDraw.nmcd.rc.Right := ItemWidth;
          AMessage.NMTVCustomDraw.nmcd.rc.Bottom := ItemHeight;
          AMessage.Result := 1;
        end
      else
        AMessage.Result := 0;
    end
  else
    inherited;
end;

procedure TdecTreeView.SetAlternativeView(AAlternativeView: Boolean);
begin
  if FAlternativeView = AAlternativeView then Exit;
  FAlternativeView := AAlternativeView;
  if HandleAllocated then
    RecreateWnd;
end;

procedure TdecTreeView.SetAutoCenter(AAutoCenter: Boolean);
var
  ExtStyle: UINT;
begin
  if FAutoCenter = AAutoCenter then Exit;
  FAutoCenter := AAutoCenter;
  if FAutoCenter then ExtStyle := TVS_EX_AUTOCENTER
                 else ExtStyle := 0;
  if HandleAllocated and AlternativeView then
    TreeView_SetExtendedStyle(Handle, ExtStyle, TVS_EX_AUTOCENTER);
end;

end.

