unit decTreeViewDCommon;

interface

procedure Register;

implementation

uses
  Classes, DesignIntf, decTreeView;

{$if CompilerVersion >= 25}
{$LEGACYIFEND ON}
{$ifend}

{$if CompilerVersion > 22}
{$R ..\Packages\Resources\decTreeViewMainIcon.res}
{$ifend}
{$R ..\Packages\Resources\decTreeViewDVersion.res}

{$if CompilerVersion < 16}
{$R ..\Packages\Resources\decTreeViewIconDelphi7.res}
{$else}
{$if CompilerVersion < 17}
{$R ..\Packages\Resources\decTreeViewIconDelphi2005.res}
{$else}
{$if CompilerVersion < 32}
{$R ..\Packages\Resources\decTreeViewIconDelphi2006.res}
{$else}
{$R ..\Packages\Resources\decTreeViewIconDelphi10.2.res}
{$ifend}
{$ifend}
{$ifend}


procedure Register;
begin
  RegisterComponents('Win32', [TdecTreeView]);
  RegisterPropertiesInCategory('Visual', TdecTreeView, ['AlternativeView', 'AutoCenter']);
end;

end.

