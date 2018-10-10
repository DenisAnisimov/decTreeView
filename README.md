# decTreeView

You can use decTreeView control to display a tree structure like this:

![decTreeView](https://raw.githubusercontent.com/DenisAnisimov/decTreeView/master/Img/decTreeView.png)
![decTreeView](https://raw.githubusercontent.com/DenisAnisimov/decTreeView/master/Img/decTreeViewStyle.png)

The decTreeView library is written in Delphi but can be used in almost any Windows project regardless of its programming language, provided that third-party DLLs can be used.

### Using decTreeView in Delphi programs

If your project is created in Delphi, you are lucky, because you can easily integrate the decTreeView library into your application.

Before you can use the decTreeView control in your Delphi project, you need to install the decTreeView design-time package in the Delphi IDE. If the installation is successful, an icon for the new component will appear on the Win32 tab. After that, you can use decTreeView just like any other control: add it to a form, change its properties in the Object Inspector, set different event handlers, etc.

You can also use the decTreeView component without installing its design-time package. In that case, you will need to create it at run-time, or you can use this little hack:

```
type
  TTreeView = class(TdecTreeView);

  TForm1 = class(TForm)
    TreeView1: TTreeView;
  public
  end;
```

### Using decTreeView in non-Delphi programs

Though decTreeView is written in Delphi, it is a low-level library, it does not use any frameworks, and it only uses direct calls to Windows API functions. Thanks to that, you can use decTreeView in almost any Windows project.

The pseudo code for creating the standard TreeView control looks like this:

```
InitCommonControl(ICC_TREEVIEW_CLASSES);
CreateWindowEx(…, WC_TREEVIEW, …);
```

The decTreeView library has been designed in such a way that you can easily start using it in place of TreeView. You only need to replace the above pseudo code with the following code:

```
M = LoadLibrary("decTreeViewLib.dll");
InitProc = GetProcAddress(M, "InitTreeViewLib");
InitProc;
CreateWindowEx(…, "decTreeView", …);
```
It’s very easy. If you have created a decTreeView control, you can use it just like the standard TreeView control. That is, the same TVS_* and TVS_EX_* styles are used, the same TVM_* messages are sent, and the same TVN_* notifications are processed.

The InitTreeViewLib function has the following prototype:

```
function InitTreeViewLib: ATOM; stdcall;
```

### Antialiasing

The decTreeView control can render lines in two modes: without antialiasing or with antialiasing.

![decTreeView](https://raw.githubusercontent.com/DenisAnisimov/decTreeView/master/Img/decTreeViewAntialiasing.png)

The choice of the rendering mode depends on whether your application is using the GDI+ library. Anti-aliasing is only available if GDI+ has been initialized. In that case, decTreeView will use the rendering functions of that library to produce better-looking results.

### Limitations

Currently, the following styles, messages, and notifications (and the associated functionality) are not supported:

Styles:
- TVS_DISABLEDRAGDROP
- TVS_EDITLABELS
- TVS_FULLROWSELECT (not applicable)
- TVS_HASLINES
- TVS_INFOTIP
- TVS_NOHSCROLL
- TVS_NONEVENHEIGHT
- TVS_NOTOOLTIPS
- TVS_RTLREADING

ExtStyles:
- TVS_EX_AUTOHSCROLL
- TVS_EX_DRAWIMAGEASYNC
- TVS_EX_FADEINOUTEXPANDOS
- TVS_EX_MULTISELECT
- TVS_EX_NOINDENTSTATE
- TVS_EX_NOSINGLECOLLAPSE
- TVS_EX_RICHTOOLTIP

Messages:
- CCM_DPISCALE
- CCM_GETVERSION
- CCM_SETVERSION
- TVM_CREATEDRAGIMAGE
- TVM_EDITLABEL
- TVM_ENDEDITLABELNOW
- TVM_GETEDITCONTROL
- TVM_GETISEARCHSTRING
- TVM_GETITEMHEIGHT
- TVM_GETITEMPARTRECT
- TVM_GETSCROLLTIME
- TVM_GETTOOLTIPS
- TVM_GETVISIBLECOUNT
- TVM_MAPACCIDTOHTREEITEM
- TVM_MAPHTREEITEMTOACCID
- TVM_SETAUTOSCROLLINFO
- TVM_SETHOT
- TVM_SETITEMHEIGHT
- TVM_SETSCROLLTIME
- TVM_SETTOOLTIPS
- TVM_SHOWINFOTIP
- TVM_SORTCHILDREN
- TVM_SORTCHILDRENCB

Notification:
- TVN_ASYNCDRAW
- TVN_BEGINDRAG
- TVN_BEGINLABELEDIT
- TVN_BEGINRDRAG
- TVN_ENDLABELEDIT
- TVN_GETINFOTIP
- TVN_SETDISPINFO
