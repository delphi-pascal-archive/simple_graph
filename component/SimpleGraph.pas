{------------------------------------------------------------------------------}
{                                                                              }
{  TSimpleGraph v1.542                                                         }
{  by Kambiz R. Khojasteh                                                      }
{                                                                              }
{  kambiz@delphiarea.com                                                       }
{  http://www.delphiarea.com                                                   }
{                                                                              }
{------------------------------------------------------------------------------}

{$I DELPHIAREA.INC}

{$Q-R-O+}

unit SimpleGraph;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, Menus;

const
  crHandFlat  = 51;
  crHandGrab  = 52;
  crHandPnt   = 53;
  crXHair1    = 54;
  crXHair2    = 55;

type

  TSimpleGraph = class;
  TGraphObject = class;

  EGraphStreamError = class(EStreamError);

  { MemoryHandleStream }

  TMemoryHandleStream = class(TMemoryStream)
  private
    fHandle: THandle;
    fReleaseHandle: Boolean;
  protected
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(MemHandle: THandle); virtual;
    destructor Destroy; override;
    property Handle: THandle read fHandle;
    property ReleaseHandle: Boolean read fReleaseHandle write fReleaseHandle;
  end;

  { TGraphScrollBar -- for internal use only }

  TGraphScrollBar = class(TPersistent)
  private
    fOwner: TSimpleGraph;
    fIncrement: TScrollBarInc;
    fPageIncrement: TScrollbarInc;
    fPosition: Integer;
    fRange: Integer;
    fCalcRange: Integer;
    fKind: TScrollBarKind;
    fMargin: Word;
    fVisible: Boolean;
    fTracking: Boolean;
    fSmooth: Boolean;
    fDelay: Integer;
    fButtonSize: Integer;
    fColor: TColor;
    fParentColor: Boolean;
    fSize: Integer;
    fStyle: TScrollBarStyle;
    fThumbSize: Integer;
    fPageDiv: Integer;
    fLineDiv: Integer;
    fUpdateNeeded: Boolean;
    constructor Create(AOwner: TSimpleGraph; AKind: TScrollBarKind);
    procedure CalcAutoRange;
    function ControlSize(ControlSB, AssumeSB: Boolean): Integer;
    procedure DoSetRange(Value: Integer);
    function GetScrollPos: Integer;
    function NeedsScrollBarVisible: Boolean;
    function IsIncrementStored: Boolean;
    procedure ScrollMessage(var Msg: TWMScroll);
    procedure SetButtonSize(Value: Integer);
    procedure SetColor(Value: TColor);
    procedure SetParentColor(Value: Boolean);
    procedure SetPosition(Value: Integer);
    procedure SetSize(Value: Integer);
    procedure SetStyle(Value: TScrollBarStyle);
    procedure SetThumbSize(Value: Integer);
    procedure SetVisible(Value: Boolean);
    procedure Update(ControlSB, AssumeSB: Boolean);
  public
    procedure Assign(Source: TPersistent); override;
    procedure ChangeBiDiPosition;
    property Kind: TScrollBarKind read FKind;
    function IsScrollBarVisible: Boolean;
    property ScrollPos: Integer read GetScrollPos;
    property Range: Integer read fRange;
    property Owner: TSimpleGraph read fOwner;
  published
    property ButtonSize: Integer read fButtonSize write SetButtonSize default 0;
    property Color: TColor read fColor write SetColor default clBtnHighlight;
    property Increment: TScrollBarInc read fIncrement write FIncrement stored IsIncrementStored default 8;
    property Margin: Word read fMargin write fMargin default 0;
    property ParentColor: Boolean read fParentColor write SetParentColor default True;
    property Position: Integer read fPosition write SetPosition default 0;
    property Smooth: Boolean read fSmooth write FSmooth default False;
    property Size: Integer read fSize write SetSize default 0;
    property Style: TScrollBarStyle read fStyle write SetStyle default ssRegular;
    property ThumbSize: Integer read fThumbSize write SetThumbSize default 0;
    property Tracking: Boolean read fTracking write FTracking default False;
    property Visible: Boolean read fVisible write SetVisible default True;
  end;

  { TGraphObject }

  TMarkerType = (mtNone, mtSizeW, mtSizeE, mtSizeN, mtSizeS, mtSizeNW,
    mtSizeNE, mtSizeSW, mtSizeSE, mtMove, mtMoveStrartPt, mtMoveEndPt,
    mtSelect);

  TGraphObjectState = (osNone, osCreating, osDestroying, osReading, osWriting);

  TGraphObjectClass = class of TGraphObject;

  TGraphObject = class(TPersistent)
  private
    fID: DWORD;
    fOldID: DWORD;
    fOwner: TSimpleGraph;
    fBrush: TBrush;
    fPen: TPen;
    fText: String;
    fFont: TFont;
    fParentFont: Boolean;
    fTag: Integer;
    fVisible: Boolean;
    fSelected: Boolean;
    fDragging: Boolean;
    fState: TGraphObjectState;
    fIsLink: Boolean;
    InSyncFont: Boolean;
    procedure SetBrush(Value: TBrush);
    procedure SetPen(Value: TPen);
    procedure SetText(const Value: String);
    procedure SetFont(Value: TFont);
    procedure SetParentFont(Value: Boolean);
    procedure SetVisible(Value: Boolean);
    procedure SetSelected(Value: Boolean);
    procedure SetDragging(Value: Boolean);
    function GetZOrder: Integer;
    procedure SetZOrder(Value: Integer);
    procedure SetState(Value: TGraphObjectState);
    function GetShowing: Boolean;
    function IsFontStored: Boolean;
    procedure StyleChanged(Sender: TObject);
  protected
    constructor Create(AOwner: TSimpleGraph); reintroduce; virtual;
    procedure SyncFontToParent;
    procedure InitializeInstance; virtual;
    procedure LocateLinkedObjects(StartIndex: Integer); virtual;
    function VerifyLinkedObjects: Boolean; virtual;
    function ChangeLinkedObject(OldObject, NewObject: TGraphObject): Boolean; virtual;
    procedure Changed(DataModified: Boolean); virtual;
    procedure CalculateTextParameters(Recalc: Boolean; dX, dY: Integer); virtual;
    function MarkerRect(MarkerType: TMarkerType): TRect; virtual; abstract;
    function FindMarkerAt(X, Y: Integer): TMarkerType; virtual; abstract;
    procedure DrawMarkers(Canvas: TCanvas); virtual; abstract;
    procedure DrawText(Canvas: TCanvas); virtual; abstract;
    procedure DrawBody(Canvas: TCanvas); virtual; abstract;
    procedure Draw(Canvas: TCanvas); virtual;
    function IsVisibleOn(Canvas: TCanvas): Boolean;
    procedure SetBoundsRect(const Rect: TRect); virtual; abstract;
    function GetBoundsRect: TRect; virtual; abstract;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); virtual; abstract;
    property Dragging: Boolean read fDragging write SetDragging;
    property State: TGraphObjectState read fState write SetState;
    property ID: DWORD read fID write fID;
    property OldID: DWORD read fOldID write fOldID;
  public
    destructor Destroy; override;
    function ContainsPoint(X, Y: Integer): Boolean; virtual; abstract;
    procedure Assign(Source: TPersistent); override;
    procedure BringToFront; virtual;
    procedure SendToBack; virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    function ConvertTo(AnotherClass: TGraphObjectClass): Boolean; virtual;
    property IsLink: Boolean read fIsLink;
    property Owner: TSimpleGraph read fOwner;
    property Showing: Boolean read GetShowing;
    property ZOrder: Integer read GetZOrder write SetZOrder;
    property Selected: Boolean read fSelected write SetSelected default False;
    property BoundsRect: TRect read GetBoundsRect write SetBoundsRect;
  published
    property Text: String read fText write SetText;
    property Brush: TBrush read fBrush write SetBrush;
    property Pen: TPen read fPen write SetPen;
    property Font: TFont read fFont write SetFont stored IsFontStored;
    property ParentFont: Boolean read fParentFont write SetParentFont default True;
    property Visible: Boolean read fVisible write SetVisible default True;
    property Tag: Integer read fTag write fTag default 0;
  end;

  { TGraphStreamableObject -- for internal use only }

  TGraphStreamableObject = class(TComponent)
  private
    fID: DWORD;
    fG: TGraphObject;
    fDummy: Integer;
  published
    property ID: DWORD read fID write fID;
    property G: TGraphObject read fG write fG stored True;
    property Left: Integer read fDummy write fDummy stored False;
    property Top: Integer read fDummy write fDummy stored False;
    property Tag stored False;
    property Name stored False;
  end;

  { TGraphLink }

  TGraphNode = class;

  TLinkKind = (lkUndirected, lkDirected, lkBidirected);

  TArrowSize = 2..10;

  TGraphLink = class(TGraphObject)
  private
    fFromNode: TGraphNode;
    fToNode: TGraphNode;
    fKind: TLinkKind;
    fStartPt: TPoint;
    fEndPt: TPoint;
    fArrowSize: TArrowSize;
    fAngle: Extended;
    fTextRegion: HRGN;
    TextCenter: TPoint;
    TextToShow: String;
    FromNodeID: DWORD;
    ToNodeID: DWORD;
    procedure SetFromNode(Value: TGraphNode);
    procedure SetToNode(Value: TGraphNode);
    procedure SetKind(Value: TLinkKind);
    procedure SetArrowSize(Value: TArrowSize);
    procedure ReadFromNode(Reader: TReader);
    procedure WriteFromNode(Writer: TWriter);
    procedure ReadToNode(Reader: TReader);
    procedure WriteToNode(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure InitializeInstance; override;
    procedure LocateLinkedObjects(StartIndex: Integer); override;
    function VerifyLinkedObjects: Boolean; override;
    function ChangeLinkedObject(OldObject, NewObject: TGraphObject): Boolean; override;
    procedure Changed(DataModified: Boolean); override;
    procedure CalculateTextParameters(Recalc: Boolean; dX, dY: Integer); override;
    procedure CalculateEndPoints; virtual;
    function GetTextRegion: HRGN; virtual;
    function MarkerRect(MarkerType: TMarkerType): TRect; override;
    function FindMarkerAt(X, Y: Integer): TMarkerType; override;
    procedure DrawMarkers(Canvas: TCanvas); override;
    procedure DrawText(Canvas: TCanvas); override;
    procedure DrawBody(Canvas: TCanvas); override;
    procedure Draw(Canvas: TCanvas); override;
    procedure SetBoundsRect(const Rect: TRect); override;
    function GetBoundsRect: TRect; override;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); override;
  protected
    constructor Create(AOwner: TSimpleGraph); override;
    property StartPt: TPoint read fStartPt;
    property EndPt: TPoint read fEndPt;
    property Angle: Extended read fAngle;
    property TextRegion: HRGN read fTextRegion;
  public
    destructor Destroy; override;
    procedure Reverse; virtual;
    procedure Assign(Source: TPersistent); override;
    function ContainsPoint(X, Y: Integer): Boolean; override;
    property FromNode: TGraphNode read fFromNode write SetFromNode;
    property ToNode: TGraphNode read fToNode write SetToNode;
  published
    property Kind: TLinkKind read fKind write SetKind default lkDirected;
    property ArrowSize: TArrowSize read fArrowSize write SetArrowSize default 4;
  end;

  { TGraphNode }

  TQueryLinkResult = (qlrNone, qlrLinked, qlrLinkedIn, qlrLinkedOut, qlrLinkedInOut);

  TGraphNode = class(TGraphObject)
  private
    fLeft: Integer;
    fTop: Integer;
    fWidth: Integer;
    fHeight: Integer;
    fAlignment: TAlignment;
    fMargin: Integer;
    fBackground: TPicture;
    fRegion: HRGN;
    fTextRect: TRect;
    procedure SetLeft(Value: Integer);
    procedure SetTop(Value: Integer);
    procedure SetWidth(Value: Integer);
    procedure SetHeight(Value: Integer);
    procedure SetAlignment(Value: TAlignment);
    procedure SetMargin(Value: Integer);
    procedure SetBackground(Value: TPicture);
    procedure BackgroundChanged(Sender: TObject);
  protected
    procedure InitializeInstance; override;
    procedure BoundsChanged(dX, dY, dCX, dCY: Integer); virtual;
    procedure CalculateTextParameters(Recalc: Boolean; dX, dY: Integer); override;
    function GetMaxTextRect: TRect; virtual;
    function GetTextRect: TRect; virtual;
    function GetCenter: TPoint; virtual;
    function GetRegion: HRGN; virtual; abstract;
    function CreateClipRgn(Canvas: TCanvas): HRGN;
    function MarkerRect(MarkerType: TMarkerType): TRect; override;
    function FindMarkerAt(X, Y: Integer): TMarkerType; override;
    procedure DrawMarkers(Canvas: TCanvas); override;
    procedure DrawText(Canvas: TCanvas); override;
    procedure DrawBackground(Canvas: TCanvas); virtual;
    procedure SetBoundsRect(const Rect: TRect); override;
    function GetBoundsRect: TRect; override;
    function LinkIntersect(const LinkAngle: Extended; Backward: Boolean): TPoint; virtual; abstract;
  protected
    constructor Create(AOwner: TSimpleGraph); override;
    procedure MoveMarkerBy(MarkerType: TMarkerType; const Delta: TPoint);
    property Region: HRGN read fRegion;
    property TextRect: TRect read fTextRect;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ContainsPoint(X, Y: Integer): Boolean; override;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: Integer); virtual;
    function QueryLinkTo(Node: TGraphNode): TQueryLinkResult; virtual;
    property Center: TPoint read GetCenter;
  published
    property Left: Integer read fLeft write SetLeft;
    property Top: Integer read fTop write SetTop;
    property Width: Integer read fWidth write SetWidth;
    property Height: Integer read fHeight write SetHeight;
    property Alignment: TAlignment read fAlignment write SetAlignment default taCenter;
    property Margin: Integer read fMargin write SetMargin default 8;
    property Background: TPicture read fBackground write SetBackground;
  end;

  { TPolygonalNode }
  { NOTE: Vertices are in clockwise order, and the first vertex is at 12 O'clock }

  TPointArray = array of TPoint;

  TPolygonalNode = class(TGraphNode)
  private
    fVertices: TPointArray;
  protected
    procedure BoundsChanged(dX, dY, dCX, dCY: Integer); override;
    function GetCenter: TPoint; override;
    function GetRegion: HRGN; override;
    procedure DrawBody(Canvas: TCanvas); override;
    function LinkIntersect(const LinkAngle: Extended; Backward: Boolean): TPoint; override;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); override;
    class procedure DefineVertices(const ARect: TRect; var Points: TPointArray); virtual; abstract;
    property Vertices: TPointArray read fVertices;
  public
    destructor Destroy; override;
  end;

  { TRectangularNode }

  TRectangularNode = class(TGraphNode)
  protected
    function GetRegion: HRGN; override;
    procedure DrawBody(Canvas: TCanvas); override;
    function LinkIntersect(const LinkAngle: Extended; Backward: Boolean): TPoint; override;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); override;
  end;

  { TRoundRectangularNode }

  TRoundRectangularNode = class(TGraphNode)
  protected
    function GetRegion: HRGN; override;
    procedure DrawBody(Canvas: TCanvas); override;
    function LinkIntersect(const LinkAngle: Extended; Backward: Boolean): TPoint; override;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); override;
  end;

  { TEllipticNode }

  TEllipticNode = class(TGraphNode)
  protected
    function GetRegion: HRGN; override;
    procedure DrawBody(Canvas: TCanvas); override;
    function LinkIntersect(const LinkAngle: Extended; Backward: Boolean): TPoint; override;
    class procedure DrawDraft(Canvas: TCanvas; const ARect: TRect); override;
  end;

  { TTriangularNode }

  TTriangularNode = class(TPolygonalNode)
  protected
    function GetMaxTextRect: TRect; override;
    class procedure DefineVertices(const ARect: TRect; var Points: TPointArray); override;
  end;

  { TRhomboidalNode }

  TRhomboidalNode = class(TPolygonalNode)
  protected
    function GetMaxTextRect: TRect; override;
    class procedure DefineVertices(const ARect: TRect; var Points: TPointArray); override;
  end;

  { TPentagonalNode }

  TPentagonalNode = class(TPolygonalNode)
  protected
    function GetMaxTextRect: TRect; override;
    class procedure DefineVertices(const ARect: TRect; var Points: TPointArray); override;
  end;

  { TGraphObjectList }

  TGraphObjectListAction = (glAdded, glRemoved, glReordered);

  TGraphObjectListEvent = procedure(Sender: TObject; GraphObject: TGraphObject;
    Action: TGraphObjectListAction) of object;

  TGraphObjectList = class(TList)
  private
    fOnChange: TGraphObjectListEvent;
    function GetItems(Index: Integer): TGraphObject;
  protected
    procedure NotifyAction(GraphObject: TGraphObject;
      Action: TGraphObjectListAction); virtual;
    function Replace(OldItem, NewItem: TGraphObject): Integer;
    property OnChange: TGraphObjectListEvent read fOnChange write fOnChange;
  public
    procedure Clear; override;
    procedure Exchange(Index1, Index2: Integer);
    procedure Move(CurIndex, NewIndex: Integer);
    function Add(Item: TGraphObject): Integer;
    procedure Insert(Index: Integer; Item: TGraphObject);
    procedure Extract(Item: TGraphObject);
    procedure Delete(Index: Integer);
    function Remove(Item: TGraphObject): Integer;
    function First: TGraphObject;
    function Last: TGraphObject;
    property Items[Index: Integer]: TGraphObject read GetItems; default;
  end;

  { TSimpleGraph }

  TGraphNodeClass = class of TGraphNode;
  TGraphLinkClass = class of TGraphLink;

  TGridSize = 4..128;
  TMarkerSize = 3..9;
  TZoom = 10..1000;

  TGraphMouseState = (gsNone, gsMoveResizeNode, gsSelectRect, gsMoveLink);
  TGraphCommandMode = (cmViewOnly, cmEdit, cmInsertNode, cmLinkNodes);

  TGraphNotifyEvent = procedure(Graph: TSimpleGraph;
    GraphObject: TGraphObject) of object;
  TGraphContextPopupEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    const MousePos: TPoint; var Handled: Boolean) of object;
  TCanMoveResizeNodeEvent = procedure(Graph: TSimpleGraph; Node: TGraphNode;
    var NewLeft, NewTop, NewWidth, NewHeight: Integer;
    var CanMove, CanResize: Boolean) of object;
  TCanLinkNodesEvent = procedure(Graph: TSimpleGraph;
    FromNode, ToNode: TGraphNode; var CanLink: Boolean) of object;

  {$IFNDEF DELPHI5_UP}
  TContextPopupEvent = procedure(Sender: TObject; MousePos: TPoint;
    var Handled: Boolean) of object;
  {$ENDIF}

  TSimpleGraph = class(TCustomControl)
  private
    fGridSize: TGridSize;
    fGridColor: TColor;
    fShowGrid: Boolean;
    fSnapToGrid: Boolean;
    fShowHiddenObjects: Boolean;
    fHideSelection: Boolean;
    fLockNodes: Boolean;
    fMarkerColor: TColor;
    fMarkerSize: TMarkerSize;
    fZoom: TZoom;
    fZoomMin: TZoom;
    fZoomMax: TZoom;
    fZoomStep: Byte;
    fObjects: TGraphObjectList;
    fSelectedObjects: TGraphObjectList;
    fDefaultKeyMap: Boolean;
    fObjectPopupMenu: TPopupMenu;
    fDefaultNodeClass: TGraphNodeClass;
    fDefaultLinkClass: TGraphLinkClass;
    fModified: Boolean;
    fState: TGraphMouseState;
    fCommandMode: TGraphCommandMode;
    fHorzScrollBar: TGraphScrollBar;
    fVertScrollBar: TGraphScrollBar;
    fVisibleBounds: TRect;
    fFreezeTopLeft: Boolean;
    fMinNodeSize: Word;
    fOnObjectInsert: TGraphNotifyEvent;
    fOnObjectRemove: TGraphNotifyEvent;
    fOnObjectSelect: TGraphNotifyEvent;
    fOnObjectDblClick: TGraphNotifyEvent;
    fOnObjectContextPopup: TGraphContextPopupEvent;
    fOnCanMoveResizeNode: TCanMoveResizeNodeEvent;
    fOnCanLinkNodes: TCanLinkNodesEvent;
    fOnGraphChange: TNotifyEvent;
    fOnCommandModeChange: TNotifyEvent;
    {$IFNDEF DELPHI5_UP}
    fOnContextPopup: TContextPopupEvent;
    {$ENDIF}
    UpdatingScrollBars: Boolean;
    ObjectAtCursor: TGraphObject;
    MarkerAtCursor: TMarkerType;
    Grid: TBitmap;
    StartPoint: TPoint;
    StopPoint: TPoint;
    SelectionRect: TRect;
    FirstNodeOfLink: TGraphNode;
    UpdateCount: Integer;
    GraphModified: Boolean;
    Linking: Boolean;
    IgnoreNotification: Boolean;
    WheelAccumulator: Integer;
    procedure SetGridSize(Value: TGridSize);
    procedure SetGridColor(Value: TColor);
    procedure SetShowGrid(Value: Boolean);
    procedure SetShowHiddenObjects(Value: Boolean);
    procedure SetHideSelection(Value: Boolean);
    procedure SetLockNodes(Value: Boolean);
    procedure SetMarkerColor(Value: TColor);
    procedure SetMarkerSize(Value: TMarkerSize);
    procedure SetZoom(Value: TZoom);
    procedure SetZoomMin(Value: TZoom);
    procedure SetZoomMax(Value: TZoom);
    procedure SetState(Value: TGraphMouseState);
    procedure SetCommandMode(Value: TGraphCommandMode);
    procedure SetHorzScrollBar(Value: TGraphScrollBar);
    procedure SetVertScrollBar(Value: TGraphScrollBar);
    function GetGraphBounds(Mode: Integer): TRect;
    {$IFNDEF DELPHI5_UP}
    procedure WMContextMenu(var Message: TMessage); message WM_CONTEXTMENU;
    {$ENDIF}
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure CNKeyDOwn(var Msg: TWMKeyDown); message CN_KEYDOWN;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure CMBiDiModeChanged(var Msg: TMessage); message CM_BIDIMODECHANGED;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure WMMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL;
    procedure ObjectListChanged(Sender: TObject; GraphObject: TGraphObject;
      Action: TGraphObjectListAction);
    procedure SelectionListChanged(Sender: TObject; GraphObject: TGraphObject;
      Action: TGraphObjectListAction);
    function ChangeObjectClass(GraphObject: TGraphObject;
      AnotherClass: TGraphObjectClass): Boolean;
    procedure ObjectChanged(GraphObject: TGraphObject; DataModified: Boolean);
    function VerifyNodeMoveResize(Node: TGraphNode;
      var aLeft, aTop, aWidth, aHeight: Integer;
      var CanMove, CanResize: Boolean): Boolean;
    procedure UpdateScrollBars;
    procedure CalcAutoRange;
    procedure CalcVisibleBounds;
    function ReadGraphObject(Stream: TStream): TGraphObject;
    procedure WriteGraphObject(Stream: TStream; GraphObject: TGraphObject);
  protected
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); {$IFDEF DELPHI5_UP} override; {$ENDIF}
    procedure DblClick; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoGraphChange; virtual;
    procedure DoCommandModeChange; virtual;
    procedure DoObjectDblClick(GraphObject: TGraphObject); virtual;
    procedure DoObjectInsert(GraphObject: TGraphObject); virtual;
    procedure DoObjectRemove(GraphObject: TGraphObject); virtual;
    procedure DoObjectSelect(GraphObject: TGraphObject); virtual;
    procedure DoObjectContextPopup(GraphObject: TGraphObject; const MousePos: TPoint;
      var Handled: Boolean); virtual;
    procedure DoCanMoveResizeNode(Node: TGraphNode; var aLeft, aTop, aWidth, aHeight: Integer;
      var CanMove, CanResize: Boolean); virtual;
    function CanLinkNodes(FromNode, ToNode: TGraphNode): Boolean; virtual;
    function FindObjectMarkerAt(X, Y: Integer;
      var GraphObject: TGraphObject): TMarkerType; virtual;
    function FindObjectByID(ID: DWORD;
      GraphObjectClass: TGraphObjectClass): TGraphObject; virtual;
    function FindObjectByOldID(StartIndex: Integer; OldID: DWORD;
      GraphObjectClass: TGraphObjectClass): TGraphObject; virtual;
    procedure ReadObjects(Stream: TStream); virtual;
    procedure WriteObjects(Stream: TStream; SelectedOnly: Boolean); virtual;
    procedure DrawBackground(Canvas: TCanvas); virtual;
    function GetUniqueID(PreferredID: DWORD): DWORD; virtual;
    function GetAsMetafile: TMetafile; virtual;
    property State: TGraphMouseState read fState write SetState;
  public
    class procedure Register(ANodeClass: TGraphNodeClass); overload;
    class procedure Unregister(ANodeClass: TGraphNodeClass); overload;
    class function NodeClassCount: Integer;
    class function NodeClasses(Index: Integer): TGraphNodeClass;
    class procedure Register(ALinkClass: TGraphLinkClass); overload;
    class procedure Unregister(ALinkClass: TGraphLinkClass); overload;
    class function LinkClassCount: Integer;
    class function LinkClasses(Index: Integer): TGraphLinkClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Invalidate; override;
    procedure Draw(Canvas: TCanvas);
    procedure Print(Canvas: TCanvas; const Rect: TRect);
    procedure ToggleNodesAt(const Rect: TRect; KeepOld: Boolean);
    function FindObjectAt(X, Y: Integer;
      GraphObjectClass: TGraphObjectClass = nil): TGraphObject;
    function InsertNode(pBounds: PRect = nil;
      ANodeClass: TGraphNodeClass = nil): TGraphNode;
    function LinkNodes(FromNode, ToNode: TGraphNode;
      ALinkClass: TGraphLinkClass = nil): TGraphLink;
    function IsValidLink(Link: TGraphLink;
      FromNode, ToNode: TGraphNode): Boolean;
    procedure ScrollInView(GraphObject: TGraphObject); overload;
    procedure ScrollInView(const Rect: TRect); overload;
    procedure ScrollInView(const Point: TPoint); overload;
    function ZoomRect(const Rect: TRect): Boolean;
    function ZoomObject(GraphObject: TGraphObject): Boolean;
    function ZoomSelection: Boolean;
    function ZoomGraph: Boolean;
    function FindNextObject(StartIndex: Integer; Inclusive, Backward,
      Wrap: Boolean; GraphObjectClass: TGraphObjectClass = nil): TGraphObject;
    function SelectNextObject(Backward: Boolean;
      GraphObjectClass: TGraphObjectClass = nil): Boolean;
    function ObjectsCount(GraphObjectClass: TGraphObjectClass = nil): Integer;
    function SelectedObjectsCount(GraphObjectClass: TGraphObjectClass = nil): Integer;
    procedure Clear;
    procedure SaveAsMetafile(const Filename: String);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromFile(const Filename: String);
    procedure SaveToFile(const Filename: String);
    procedure CopyToClipboard(Selection: Boolean = True);
    function PasteFromClipboard: Boolean;
    function ClientToGraph(X, Y: Integer): TPoint;
    function GraphToClient(X, Y: Integer): TPoint;
    property VisibleBounds: TRect read fVisibleBounds;
    property GraphBounds: TRect index 0 read GetGraphBounds;
    property SelectionBounds: TRect index 1 read GetGraphBounds;
    property Objects: TGraphObjectList read fObjects;
    property SelectedObjects: TGraphObjectList read fSelectedObjects;
    property Modified: Boolean read fModified write fModified;
    property CommandMode: TGraphCommandMode read fCommandMode write SetCommandMode;
    property DefaultNodeClass: TGraphNodeClass read fDefaultNodeClass write fDefaultNodeClass;
    property DefaultLinkClass: TGraphLinkClass read fDefaultLinkClass write fDefaultLinkClass;
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property Color;
    property Constraints;
    property DefaultKeyMap: Boolean read fDefaultKeyMap write fDefaultKeyMap default True;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FreezeTopLeft: Boolean read fFreezeTopLeft write fFreezeTopLeft default False;
    property GridColor: TColor read fGridColor write SetGridColor default clGray;
    property GridSize: TGridSize read fGridSize write SetGridSize default 8;
    property Height;
    property HideSelection: Boolean read fHideSelection write SetHideSelection default False;
    property HorzScrollBar: TGraphScrollBar read fHorzScrollBar write SetHorzScrollBar;
    property LockNodes: Boolean read fLockNodes write SetLockNodes default False;
    property MarkerColor: TColor read fMarkerColor write SetMarkerColor default clBlack;
    property MarkerSize: TMarkerSize read fMarkerSize write SetMarkerSize default 3;
    property MinNodeSize: Word read fMinNodeSize write fMinNodeSize default 16;
    property ObjectPopupMenu: TPopupMenu read fObjectPopupMenu write fObjectPopupMenu;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowGrid: Boolean read fShowGrid write SetShowGrid default True;
    property ShowHiddenObjects: Boolean read fShowHiddenObjects write SetShowHiddenObjects default False;
    property ShowHint;
    property SnapToGrid: Boolean read fSnapToGrid write fSnapToGrid default True;
    property TabOrder;
    property TabStop;
    property VertScrollBar: TGraphScrollBar read fVertScrollBar write SetVertScrollBar;
    property Visible;
    property Width;
    property Zoom: TZoom read fZoom write SetZoom default 100;
    property ZoomMax: TZoom read fZoomMax write SetZoomMax default Low(TZoom);
    property ZoomMin: TZoom read fZoomMin write SetZoomMin default Low(TZoom);
    property ZoomStep: Byte read fZoomStep write fZoomStep default 25;
    property OnCanResize;
    property OnConstrainedResize;
    {$IFNDEF DELPHI5_UP}
    property OnContextPopup: TContextPopupEvent read fOnContextPopup write fOnContextPopup;
    {$ELSE}
    property OnContextPopup;
    {$ENDIF}
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDockDrop;
    property OnDockOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnObjectInsert: TGraphNotifyEvent read fOnObjectInsert write fOnObjectInsert;
    property OnObjectRemove: TGraphNotifyEvent read fOnObjectRemove write fOnObjectRemove;
    property OnObjectSelect: TGraphNotifyEvent read fOnObjectSelect write fOnObjectSelect;
    property OnObjectDblClick: TGraphNotifyEvent read fOnObjectDblClick write fOnObjectDblClick;
    property OnObjectContextPopup: TGraphContextPopupEvent read fOnObjectContextPopup write fOnObjectContextPopup;
    property OnCanMoveResizeNode: TCanMoveResizeNodeEvent read fOnCanMoveResizeNode write fOnCanMoveResizeNode;
    property OnCanLinkNodes: TCanLinkNodesEvent read fOnCanLinkNodes write fOnCanLinkNodes;
    property OnGraphChange: TNotifyEvent read fOnGraphChange write fOnGraphChange;
    property OnCommandModeChange: TNotifyEvent read fOnCommandModeChange write fOnCommandModeChange;
  end;

function IsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;

procedure TransformPoints(var Points: array of TPoint; const XForm: TXForm);
procedure RotatePoints(var Points: array of TPoint; const Angle: Extended; const Org: TPoint);
procedure OffsetPoints(var Points: array of TPoint; dX, dY: Integer);
function CenterOfPoints(const Points: array of TPoint): TPoint;
function BoundsRectOfPoints(const Points: array of TPoint): TRect;

function MakeRect(const Corner1, Corner2: TPoint): TRect;
function CenterOfRect(const Rect: TRect): TPoint;

function LineSlopeAngle(const LinePt1, LinePt2: TPoint): Extended;
function DistanceToLine(const LinePt1, LinePt2, QueryPt: TPoint): Integer;
function NextPointOfLine(const LineAngle: Extended; const ThisPoint: TPoint; Distance: Integer): TPoint;

function IntersectLines(const Line1Pt: TPoint;
  const Line1Angle: Extended; const Line2Pt: TPoint;
  const Line2Angle: Extended; out Intersect: TPoint): Boolean;

// In the following functions, the line passes through the center of shape
function IntersectLineRect(const LineAngle: Extended;
  const Rect: TRect; Backward: Boolean): TPoint;
function IntersectLineEllipse(const LineAngle: Extended;
  const Bounds: TRect; Backward: Boolean): TPoint;
function IntersectLineRoundRect(const LineAngle: Extended;
  const Bounds: TRect; Backward: Boolean; Rgn: HRgn): TPoint;
function IntersectLinePolygon(const LineAngle: Extended;
  const Vertices: array of TPoint; Backward: Boolean): TPoint;

var
  CF_SIMPLEGRAPH: Integer = 0;

procedure Register;

implementation

{$R *.RES}

uses
  Math, SysUtils, CommCtrl, Clipbrd;

const
  StreamSignature: DWORD =
    (Ord('S') shl 24) or (Ord('G') shl 16) or (Ord('.') shl 8) or Ord('0');

const
  MarkerCursors: array[TMarkerType] of TCursor =
    (crDefault, crSizeWE, crSizeWE, crSizeNS, crSizeNS, crSizeNWSE, crSizeNESW,
     crSizeNESW, crSizeNWSE, crHandFlat, crXHair2, crXHair2, crHandPnt);

const
  TextAlignFlags: array[TAlignment] of Integer = (DT_LEFT, DT_RIGHT, DT_CENTER);

var
  RegisteredNodeClasses: TList;
  RegisteredLinkClasses: TList;

{ Helper Functions }

function IsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;
begin
  if Bound1 > Bound2 then
  begin
    Bound1 := Bound1 xor Bound2;
    Bound2 := Bound1 xor Bound2;
    Bound1 := Bound1 xor Bound2;
  end;
  Result := (Value >= Bound1) and (Value <= Bound2);
end;

procedure TransformPoints(var Points: array of TPoint; const XForm: TXForm);
var
  I: Integer;
begin
 for I := Low(Points) to High(Points) do
   with Points[I], XForm do
   begin
     X := Round(X * eM11 + Y * eM21 + eDx);
     Y := Round(X * eM12 + Y * eM22 + eDy);
   end;
end;

procedure RotatePoints(var Points: array of TPoint;
  const Angle: Extended; const Org: TPoint);
var
  Sin, Cos: Extended;
  Prime: TPoint;
  I: Integer;
begin
 SinCos(Angle, Sin, Cos);
 for I := Low(Points) to High(Points) do
   with Points[I] do
   begin
     Prime.X := X - Org.X;
     Prime.Y := Y - Org.Y;
     X := Round(Prime.X * Cos - Prime.Y * Sin) + Org.X;
     Y := Round(Prime.X * Sin + Prime.Y * Cos) + Org.Y;
   end;
end;

procedure OffsetPoints(var Points: array of TPoint; dX, dY: Integer);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(X, dX);
      Inc(Y, dY);
    end;
end;

function CenterOfPoints(const Points: array of TPoint): TPoint;
var
  I: Integer;
  Sum: TPoint;
begin
  Sum.X := 0;
  Sum.Y := 0;
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(Sum.X, X);
      Inc(Sum.Y, Y);
    end;
  Result.X := Sum.X div Length(Points);
  Result.Y := Sum.Y div Length(Points);
end;

function BoundsRectOfPoints(const Points: array of TPoint): TRect;
var
  I: Integer;
begin
  Result.TopLeft := Points[Low(Points)];
  Result.BottomRight := Points[Low(Points)];
  for I := Low(Points) + 1 to High(Points) do
    with Points[I], Result do
    begin
      if X < Left then Left := X;
      if Y < Top then Top := Y;
      if X > Right then Right := X;
      if Y > Bottom then Bottom := Y;
    end;
end;

function MakeRect(const Corner1, Corner2: TPoint): TRect;
begin
  if Corner1.X > Corner2.X then
  begin
    Result.Left := Corner2.X;
    Result.Right := Corner1.X;
  end
  else
  begin
    Result.Left := Corner1.X;
    Result.Right := Corner2.X;
  end;
  if Corner1.Y > Corner2.Y then
  begin
    Result.Top := Corner2.Y;
    Result.Bottom := Corner1.Y;
  end
  else
  begin
    Result.Top := Corner1.Y;
    Result.Bottom := Corner2.Y;
  end
end;

function CenterOfRect(const Rect: TRect): TPoint;
begin
  Result.X := (Rect.Left + Rect.Right) div 2;
  Result.Y := (Rect.Top + Rect.Bottom) div 2;
end;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;
var
  RgnData: PRgnData;
  RgnDataSize: DWORD;
begin
  Result := 0;
  RgnDataSize := GetRegionData(Rgn, 0, nil);
  if RgnDataSize > 0 then
  begin
    GetMem(RgnData, RgnDataSize);
    try
      GetRegionData(Rgn, RgnDataSize, RgnData);
      Result := ExtCreateRegion(@Xform, RgnDataSize, RgnData^);
    finally
      FreeMem(RgnData);
    end;
  end;
end;

function LineSlopeAngle(const LinePt1, LinePt2: TPoint): Extended;
var
  dX, dY: Integer;
begin
  dX := LinePt2.X - LinePt1.X;
  dY := LinePt2.Y - LinePt1.Y;
  if dX <> 0 then
    Result := ArcTan2(dY, dX)
  else
    Result := Pi / 2;
end;

function DistanceToLine(const LinePt1, LinePt2, QueryPt: TPoint): Integer;
var
  M: Extended;
  Pt: TPoint;
begin
  if LinePt1.X = LinePt2.X then
    Result := Abs(QueryPt.X - LinePt1.X)
  else if LinePt1.Y = LinePt2.Y then
    Result := Abs(QueryPt.Y - LinePt1.Y)
  else
  begin
    M := (LinePt2.Y - LinePt1.Y) / (LinePt2.X - LinePt1.X);
    if (M <> +1) and (M <> -1) then
    begin
      Pt.X := Round((QueryPt.Y - LinePt1.Y + M * LinePt1.X - QueryPt.X / M) / (M - 1 / M));
      Pt.Y := Round(LinePt1.Y + M * (Pt.X - LinePt1.X));
    end
    else
    begin
      Pt.Y := Round((M * (QueryPt.X - LinePt1.X) + (QueryPt.Y + LinePt1.Y)) / 2);
      Pt.X := Round(LinePt1.X + (Pt.Y - LinePt1.Y) / M);
    end;
    Result := Round(Sqrt(Sqr(QueryPt.X - Pt.X) + Sqr(QueryPt.Y - Pt.Y)));
  end;
end;

function NextPointOfLine(const LineAngle: Extended; const ThisPoint: TPoint;
  Distance: Integer): TPoint;
var
  X, Y, M: Extended;
begin
  if Abs(LineAngle) <> Pi / 2 then
  begin
    if Abs(LineAngle) < Pi / 2 then
      Distance := -Distance;
    M := Tan(LineAngle);
    X := ThisPoint.X + Distance / Sqrt(1 + Sqr(M));
    Y := ThisPoint.Y + M * (X - ThisPoint.X);
    Result := Point(Round(X), Round(Y));
  end
  else
  begin
    if LineAngle > 0 then Distance := -Distance;
    Result := Point(ThisPoint.X, ThisPoint.Y + Distance);
  end;
end;

function IntersectLines(const Line1Pt: TPoint; const Line1Angle: Extended;
  const Line2Pt: TPoint; const Line2Angle: Extended; out Intersect: TPoint): Boolean;
var
  M1, M2: Extended;
  C1, C2: Extended;
begin
  Result := True;
  if (Line1Angle = Line2Angle) or
    ((Abs(Line1Angle) = Pi / 2) and (Abs(Line2Angle) = Pi / 2))
  then  // Lines have identical slope, so they are either parallel or identical
    Result := False
  else if Abs(Line1Angle) = Pi / 2 then
  begin
    M2 := Tan(Line2Angle);
    C2 := Line2Pt.Y - M2 * Line2Pt.X;
    Intersect.X := Line1Pt.X;
    Intersect.Y := Round(M2 * Line2Pt.X + C2);
  end
  else if Abs(Line2Angle) = Pi / 2 then
  begin
    M1 := Tan(Line1Angle);
    C1 := Line1Pt.Y - M1 * Line1Pt.X;
    Intersect.X := Line2Pt.X;
    Intersect.Y := Round(M1 * Line1Pt.X + C1);
  end
  else
  begin
    M1 := Tan(Line1Angle);
    C1 := Line1Pt.Y - M1 * Line1Pt.X;
    M2 := Tan(Line2Angle);
    C2 := Line2Pt.Y - M2 * Line2Pt.X;
    Intersect.X := Round((C1 - C2) / (M2 - M1));
    Intersect.Y := Round((M2 * C1 - M1 * C2) / (M2 - M1));
  end;
end;

function IntersectLineRect(const LineAngle: Extended;
  const Rect: TRect; Backward: Boolean): TPoint;
var
  M, C, A: Extended;
  Xc, Yc: Extended;
begin
  Xc := (Rect.Left + Rect.Right) / 2;
  Yc := (Rect.Top + Rect.Bottom) / 2;
  if Abs(LineAngle) = Pi / 2 then
  begin
    if (LineAngle > 0) xor Backward then
      Result := Point(Round(Xc), Rect.Bottom)
    else
      Result := Point(Round(Xc), Rect.Top);
  end
  else if (LineAngle = 0) or (Abs(LineAngle) = Pi) then
  begin
    if (LineAngle <> 0) xor Backward then
      Result := Point(Rect.Left, Round(Yc))
    else
      Result := Point(Rect.Right, Round(Yc));
  end
  else
  begin
    M := Tan(LineAngle);
    C := Yc - M * Xc;
    A := 0;
    if (Rect.Right - Rect.Left) > 0 then
      A := ArcTan2((Rect.Bottom - Rect.Top) / 2, (Rect.Right - Rect.Left) / 2);
    if ((Abs(LineAngle) >= 0) and (Abs(LineAngle) <= A) and Backward) or
       ((Pi - Abs(LineAngle) >= 0) and (Pi - Abs(LineAngle) <= A) and not Backward)
    then
      Result := Point(Rect.Left, Round(M * Rect.Left + C))
    else if ((Abs(LineAngle) >= 0) and (Abs(LineAngle) <= A) and not Backward) or
            ((Pi - Abs(LineAngle) >= 0) and (Pi - Abs(LineAngle) <= A) and Backward)
    then
      Result := Point(Rect.Right, Round(M * Rect.Right + C))
    else if (LineAngle > 0) xor Backward then
      Result := Point(Round((Rect.Bottom - C) / M), Rect.Bottom)
    else
      Result := Point(Round((Rect.Top - C) / M), Rect.Top);
  end;
end;

function IntersectLineEllipse(const LineAngle: Extended;
  const Bounds: TRect; Backward: Boolean): TPoint;
var
  A2, B2, M, T: Extended;
  Xc, Yc, X, Y: Extended;
begin
  Xc := (Bounds.Left + Bounds.Right) / 2;
  Yc := (Bounds.Top + Bounds.Bottom) / 2;
  if Abs(LineAngle) = Pi / 2 then
  begin
    if (LineAngle > 0) xor Backward then
      Result := Point(Round(Xc), Bounds.Bottom)
    else
      Result := Point(Round(Xc), Bounds.Top);
  end
  else if (LineAngle = 0) or (Abs(LineAngle) = Pi) then
  begin
    if (LineAngle <> 0) xor Backward then
      Result := Point(Bounds.Left, Round(Yc))
    else
      Result := Point(Bounds.Right, Round(Yc));
  end
  else
  begin
    M := Tan(LineAngle);
    A2 := Sqr((Bounds.Right - Bounds.Left) / 2);
    B2 := Sqr((Bounds.Bottom - Bounds.Top) / 2);
    T := B2 + A2 * Sqr(M);
    if (Abs(LineAngle) < Pi / 2) xor Backward then
      X := Sqrt(T * (A2 * B2)) / T
    else
      X := -Sqrt(T * (A2 * B2)) / T;
    Y := M * X;
    Result := Point(Round(X+Xc), Round(Y+Yc));
  end;
end;

function IntersectLineRoundRect(const LineAngle: Extended;
  const Bounds: TRect; Backward: Boolean; Rgn: HRgn): TPoint;
var
  CR: TRect;
  Sw, Sh, W, H: Integer;
  A2, B2, M, C: Extended;
  Xc, Yc, X, Y: Extended;
  a, b, d: Extended;
begin
  Result := IntersectLineRect(LineAngle, Bounds, Backward);
  SetRect(CR, Result.X, Result.Y, Result.X, Result.Y);
  InflateRect(CR, 1, 1);
  if not RectInRegion(Rgn, CR) and (Abs(LineAngle) <> Pi / 2) then
  begin
    W := Bounds.Right - Bounds.Left;
    H := Bounds.Bottom - Bounds.Top;
    if W > H then
    begin
      Sw := W div 4;
      if Sw > H then
        Sh := H
      else
        Sh := Sw;
    end
    else
    begin
      Sh := H div 4;
      if Sh > W then
        Sw := W
      else
        Sw := Sh;
    end;
    if ((LineAngle > 0) and (LineAngle < Pi / 2) and Backward) or
       ((LineAngle < -Pi / 2) and (LineAngle > -Pi) and not Backward)
    then
      SetRect(CR, Bounds.Left, Bounds.Top, Bounds.Left + Sw, Bounds.Top + Sh)
    else if ((LineAngle > 0) and (LineAngle < Pi / 2) and not Backward) or
            ((LineAngle < -Pi / 2) and (LineAngle > -Pi) and Backward)
    then
      SetRect(CR, Bounds.Right - Sw, Bounds.Bottom - Sh, Bounds.Right, Bounds.Bottom)
    else if ((LineAngle < 0) and (LineAngle > -Pi / 2) and Backward) or
            ((LineAngle > Pi / 2) and (LineAngle < Pi) and not Backward)
    then
      SetRect(CR, Bounds.Left, Bounds.Bottom - Sh, Bounds.Left + Sw, Bounds.Bottom)
    else if ((LineAngle < 0) and (LineAngle > -Pi / 2) and not Backward) or
            ((LineAngle > Pi / 2) and (LineAngle < Pi) and Backward)
    then
      SetRect(CR, Bounds.Right - Sw, Bounds.Top, Bounds.Right, Bounds.Top + Sh);
    Xc := (Bounds.Left + Bounds.Right) / 2;
    Yc := (Bounds.Top + Bounds.Bottom) / 2;
    M := Tan(LineAngle);
    C := Yc - M * Xc;
    Xc := (CR.Left + CR.Right) / 2;
    Yc := (CR.Top + CR.Bottom) / 2;
    A2 := Sqr(Sw / 2);
    B2 := Sqr(Sh / 2);
    a := (B2 + A2 * Sqr(M));
    b := (A2 * M * (C - Yc)) - B2 * Xc;
    d := Sqr(b) - a * (B2 * Sqr(Xc) + A2 * Sqr(C - Yc) - A2 * B2);
    if d > 0 then
    begin
      if (Abs(LineAngle) < Pi / 2) xor Backward then
        X := (-b + Sqrt(d)) / a
      else
        X := (-b - Sqrt(Sqr(b) - a * (B2 * Sqr(Xc) + A2 * Sqr(C - Yc) - A2 * B2))) / a;
      Y := M * X + C;
      Result := Point(Round(X), Round(Y));
    end;
  end;
end;

{ NOTE: Vertices are in clockwise order, and the first vertex is at 12 O'clock }
function IntersectLinePolygon(const LineAngle: Extended;
  const Vertices: array of TPoint; Backward: Boolean): TPoint;

  function IntersectEdge(const Center: TPoint;
    V1, V2: Integer; out Intersect: TPoint): Boolean;
  var
    EdgeAngle: Extended;
  begin
    EdgeAngle := LineSlopeAngle(Vertices[V1], Vertices[V2]);
    Result := IntersectLines(Center, LineAngle, Vertices[V1], EdgeAngle, Intersect)
      and IsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X)
      and IsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y);
  end;

var
  I: Integer;
  Center: TPoint;
begin
  Center := CenterOfPoints(Vertices);
  if not Backward xor ((LineAngle >= -Pi / 2) and (LineAngle < Pi / 2)) then
  begin
    if IntersectEdge(Center, Low(Vertices), High(Vertices), Result) and
     ((Result.X <> Vertices[Low(Vertices)].X) or (Result.Y <> Vertices[Low(Vertices)].Y))
    then
      Exit;
    for I := High(Vertices) downto Low(Vertices) + 1 do
      if IntersectEdge(Center, I, I-1, Result) then
        Exit;
  end
  else
  begin
    for I := Low(Vertices) to High(Vertices) - 1 do
      if IntersectEdge(Center, I, I+1, Result) then
        Exit;
    if IntersectEdge(Center, High(Vertices), Low(Vertices), Result) then
      Exit;
  end;
  Result := Center;
end;

{ TMemoryHandleStream }

constructor TMemoryHandleStream.Create(MemHandle: THandle);
begin
  fHandle := MemHandle;
  if fHandle <> 0 then Size := GlobalSize(fHandle);
end;

destructor TMemoryHandleStream.Destroy;
begin
  if not fReleaseHandle and (fHandle <> 0) then
  begin
    GlobalUnlock(fHandle);
    if Capacity > Size then
      GlobalReAlloc(fHandle, Size, GMEM_MOVEABLE);
    fHandle := 0; 
  end;
  inherited Destroy;
end;

function TMemoryHandleStream.Realloc(var NewCapacity: Integer): Pointer;
const
  MemoryDelta = $2000; { Must be a power of 2 }
begin
  if (NewCapacity > 0) and (NewCapacity <> Size) then
    NewCapacity := (NewCapacity + (MemoryDelta - 1)) and not (MemoryDelta - 1);
  Result := Memory;
  if NewCapacity <> Capacity then
  begin
    if NewCapacity = 0 then
    begin
      if fHandle <> 0 then
      begin
        GlobalUnlock(fHandle);
        GlobalFree(fHandle);
        fHandle := 0;
      end;
      Result := nil;
    end
    else
    begin
      if fHandle = 0 then
        fHandle := GlobalAlloc(GMEM_MOVEABLE, NewCapacity)
      else
      begin
        GlobalUnlock(fHandle);
        fHandle := GlobalReAlloc(fHandle, NewCapacity, GMEM_MOVEABLE);
      end;
      Result := GlobalLock(fHandle);
    end;
  end;
end;

{ TGraphScrollBar }

constructor TGraphScrollBar.Create(AOwner: TSimpleGraph; AKind: TScrollBarKind);
begin
  inherited Create;
  fOwner := AOwner;
  fKind := AKind;
  fPageIncrement := 80;
  fIncrement := fPageIncrement div 10;
  fVisible := True;
  fDelay := 10;
  fLineDiv := 4;
  fPageDiv := 12;
  fColor := clBtnHighlight;
  fParentColor := True;
  fUpdateNeeded := True;
  fStyle := ssRegular;
end;

function TGraphScrollBar.IsIncrementStored: Boolean;
begin
  Result := not Smooth;
end;

procedure TGraphScrollBar.Assign(Source: TPersistent);
begin
  if Source is TGraphScrollBar then
  begin
    Visible := TGraphScrollBar(Source).Visible;
    Position := TGraphScrollBar(Source).Position;
    Increment := TGraphScrollBar(Source).Increment;
    DoSetRange(TGraphScrollBar(Source).Range);
  end
  else
    inherited Assign(Source);
end;

procedure TGraphScrollBar.ChangeBiDiPosition;
begin
  if Kind = sbHorizontal then
    if IsScrollBarVisible then
      if not Owner.UseRightToLeftScrollBar then
        Position := 0
      else
        Position := Range;
end;

procedure TGraphScrollBar.CalcAutoRange;
var
  I: Integer;
  NewRange: Integer;
  GraphObject: TGraphObject;
begin
  if Kind = sbHorizontal then
  begin
    NewRange := Owner.SelectionRect.Right + 1;
    for I := Owner.Objects.Count - 1 downto 0 do
    begin
      GraphObject := Owner.Objects[I];
      if GraphObject.Showing and not GraphObject.IsLink then
        with TGraphNode(GraphObject) do
          NewRange := Max(NewRange, Left + Width);
    end;
  end
  else
  begin
    NewRange := Owner.SelectionRect.Bottom + 1;
    for I := Owner.Objects.Count - 1 downto 0 do
    begin
      GraphObject := Owner.Objects[I];
      if GraphObject.Showing and not GraphObject.IsLink then
        with TGraphNode(GraphObject) do
          NewRange := Max(NewRange, Top + Height);
    end;
  end;
  DoSetRange(NewRange + Margin);
end;

function TGraphScrollBar.IsScrollBarVisible: Boolean;
var
  Style: Longint;
begin
  Style := WS_HSCROLL;
  if Kind = sbVertical then Style := WS_VSCROLL;
  Result := (Visible) and
            (GetWindowLong(Owner.Handle, GWL_STYLE) and Style <> 0);
end;

function TGraphScrollBar.ControlSize(ControlSB, AssumeSB: Boolean): Integer;
var
  BorderAdjust: Integer;

  function ScrollBarVisible(Code: Word): Boolean;
  var
    Style: Longint;
  begin
    Style := WS_HSCROLL;
    if Code = SB_VERT then Style := WS_VSCROLL;
    Result := GetWindowLong(Owner.Handle, GWL_STYLE) and Style <> 0;
  end;

  function Adjustment(Code, Metric: Word): Integer;
  begin
    Result := 0;
    if not ControlSB then
      if AssumeSB and not ScrollBarVisible(Code) then
        Result := -(GetSystemMetrics(Metric) - BorderAdjust)
      else if not AssumeSB and ScrollBarVisible(Code) then
        Result := GetSystemMetrics(Metric) - BorderAdjust;
  end;

begin
  BorderAdjust := Integer(GetWindowLong(Owner.Handle, GWL_STYLE) and
    (WS_BORDER or WS_THICKFRAME) <> 0);
  if Kind = sbVertical then
    Result := Owner.ClientHeight + Adjustment(SB_HORZ, SM_CXHSCROLL) else
    Result := Owner.ClientWidth + Adjustment(SB_VERT, SM_CYVSCROLL);
end;

function TGraphScrollBar.GetScrollPos: Integer;
begin
  Result := 0;
  if Visible then Result := Position;
end;

function TGraphScrollBar.NeedsScrollBarVisible: Boolean;
begin
  Result := fRange > ControlSize(False, False);
end;

procedure TGraphScrollBar.ScrollMessage(var Msg: TWMScroll);
var
  Incr, FinalIncr, Count: Integer;
  CurrentTime, StartTime, ElapsedTime: Longint;

  function GetRealScrollPosition: Integer;
  var
    SI: TScrollInfo;
    Code: Integer;
  begin
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_TRACKPOS;
    Code := SB_HORZ;
    if fKind = sbVertical then Code := SB_VERT;
    Result := Msg.Pos;
    if FlatSB_GetScrollInfo(Owner.Handle, Code, SI) then
      Result := SI.nTrackPos;
  end;

begin
  with Msg do
  begin
    if fSmooth and (ScrollCode in [SB_LINEUP, SB_LINEDOWN, SB_PAGEUP, SB_PAGEDOWN]) then
    begin
      case ScrollCode of
        SB_LINEUP, SB_LINEDOWN:
          begin
            Incr := fIncrement div fLineDiv;
            FinalIncr := fIncrement mod fLineDiv;
            Count := fLineDiv;
          end;
        SB_PAGEUP, SB_PAGEDOWN:
          begin
            Incr := FPageIncrement;
            FinalIncr := Incr mod fPageDiv;
            Incr := Incr div fPageDiv;
            Count := fPageDiv;
          end;
      else
        Count := 0;
        Incr := 0;
        FinalIncr := 0;
      end;
      CurrentTime := 0;
      while Count > 0 do
      begin
        StartTime := GetTickCount;
        ElapsedTime := StartTime - CurrentTime;
        if ElapsedTime < fDelay then Sleep(fDelay - ElapsedTime);
        CurrentTime := StartTime;
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - Incr);
          SB_LINEDOWN: SetPosition(fPosition + Incr);
          SB_PAGEUP: SetPosition(fPosition - Incr);
          SB_PAGEDOWN: SetPosition(fPosition + Incr);
        end;
        Owner.Update;
        Dec(Count);
      end;
      if FinalIncr > 0 then
      begin
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - FinalIncr);
          SB_LINEDOWN: SetPosition(fPosition + FinalIncr);
          SB_PAGEUP: SetPosition(fPosition - FinalIncr);
          SB_PAGEDOWN: SetPosition(fPosition + FinalIncr);
        end;
      end;
    end
    else
      case ScrollCode of
        SB_LINEUP: SetPosition(fPosition - fIncrement);
        SB_LINEDOWN: SetPosition(fPosition + fIncrement);
        SB_PAGEUP: SetPosition(fPosition - ControlSize(True, False));
        SB_PAGEDOWN: SetPosition(fPosition + ControlSize(True, False));
        SB_THUMBPOSITION:
            if fCalcRange > 32767 then
              SetPosition(GetRealScrollPosition) else
              SetPosition(Pos);
        SB_THUMBTRACK:
          if Tracking then
            if fCalcRange > 32767 then
              SetPosition(GetRealScrollPosition) else
              SetPosition(Pos);
        SB_TOP: SetPosition(0);
        SB_BOTTOM: SetPosition(fCalcRange);
        SB_ENDSCROLL: begin end;
      end;
  end;
end;

procedure TGraphScrollBar.SetButtonSize(Value: Integer);
const
  SysConsts: array[TScrollBarKind] of Integer = (SM_CXHSCROLL, SM_CXVSCROLL);
var
  NewValue: Integer;
begin
  if Value <> ButtonSize then
  begin
    NewValue := Value;
    if NewValue = 0 then
      Value := GetSystemMetrics(SysConsts[Kind]);
    fButtonSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fButtonSize := 0;
  end;
end;

procedure TGraphScrollBar.SetColor(Value: TColor);
begin
  if Value <> Color then
  begin
    fColor := Value;
    fParentColor := False;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetParentColor(Value: Boolean);
begin
  if ParentColor <> Value then
  begin
    fParentColor := Value;
    if Value then Color := clBtnHighlight;
  end;
end;

procedure TGraphScrollBar.SetPosition(Value: Integer);
var
  Code: Word;
  Form: TCustomForm;
  OldPos: Integer;
begin
  if csReading in Owner.ComponentState then
    fPosition := Value
  else
  begin
    if Value > fCalcRange then
      Value := fCalcRange
    else if Value < 0 then
      Value := 0;
    if Kind = sbHorizontal then
      Code := SB_HORZ
    else
      Code := SB_VERT;
    if Value <> FPosition then
    begin
      OldPos := FPosition;
      fPosition := Value;
      if Kind = sbHorizontal then
        Owner.ScrollBy(OldPos - Value, 0)
      else
        Owner.ScrollBy(0, OldPos - Value);
      if csDesigning in Owner.ComponentState then
      begin
        Form := GetParentForm(Owner);
        if (Form <> nil) and (Form.Designer <> nil) then Form.Designer.Modified;
      end;
    end;
    if FlatSB_GetScrollPos(Owner.Handle, Code) <> fPosition then
      FlatSB_SetScrollPos(Owner.Handle, Code, fPosition, True);
    Owner.CalcVisibleBounds;
  end;
end;

procedure TGraphScrollBar.SetSize(Value: Integer);
const
  SysConsts: array[TScrollBarKind] of Integer = (SM_CYHSCROLL, SM_CYVSCROLL);
var
  NewValue: Integer;
begin
  if Value <> Size then
  begin
    NewValue := Value;
    if NewValue = 0 then
      Value := GetSystemMetrics(SysConsts[Kind]);
    fSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fSize := 0;
  end;
end;

procedure TGraphScrollBar.SetStyle(Value: TScrollBarStyle);
begin
  if Style <> Value then
  begin
    fStyle := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetThumbSize(Value: Integer);
begin
  if ThumbSize <> Value then
  begin
    fThumbSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.DoSetRange(Value: Integer);
var
  NewRange: Integer;
begin
  if Value <= 0 then
    NewRange := 0
  else
    NewRange := MulDiv(Value, Owner.Zoom, 100);
  if fRange <> NewRange then
  begin
    fRange := NewRange;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetVisible(Value: Boolean);
begin
  if fVisible <> Value then
  begin
    fVisible := Value;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.Update(ControlSB, AssumeSB: Boolean);
type
  TPropKind = (pkStyle, pkButtonSize, pkThumbSize, pkSize, pkBkColor);
const
  Kinds: array[TScrollBarKind] of Integer = (WSB_PROP_HSTYLE, WSB_PROP_VSTYLE);
  Styles: array[TScrollBarStyle] of Integer = (FSB_REGULAR_MODE,
    FSB_ENCARTA_MODE, FSB_FLAT_MODE);
  Props: array[TScrollBarKind, TPropKind] of Integer = (
    { Horizontal }
    (WSB_PROP_HSTYLE, WSB_PROP_CXHSCROLL, WSB_PROP_CXHTHUMB, WSB_PROP_CYHSCROLL,
     WSB_PROP_HBKGCOLOR),
    { Vertical }
    (WSB_PROP_VSTYLE, WSB_PROP_CYVSCROLL, WSB_PROP_CYVTHUMB, WSB_PROP_CXVSCROLL,
     WSB_PROP_VBKGCOLOR));
var
  Code: Word;
  ScrollInfo: TScrollInfo;

  procedure UpdateScrollProperties(Redraw: Boolean);
  begin
    FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkStyle], Styles[Style], Redraw);
    if ButtonSize > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkButtonSize], ButtonSize, False);
    if ThumbSize > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkThumbSize], ThumbSize, False);
    if Size > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkSize], Size, False);
    FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkBkColor],
      ColorToRGB(Color), False);
  end;

begin
  fCalcRange := 0;
  Code := SB_HORZ;
  if Kind = sbVertical then Code := SB_VERT;
  if Visible then
  begin
    fCalcRange := Range - ControlSize(ControlSB, AssumeSB);
    if fCalcRange < 0 then fCalcRange := 0;
  end;
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  ScrollInfo.nMin := 0;
  if fCalcRange > 0 then
    ScrollInfo.nMax := Range else
    ScrollInfo.nMax := 0;
  ScrollInfo.nPage := ControlSize(ControlSB, AssumeSB) + 1;
  ScrollInfo.nPos := fPosition;
  ScrollInfo.nTrackPos := fPosition;
  UpdateScrollProperties(fUpdateNeeded);
  fUpdateNeeded := False;
  FlatSB_SetScrollInfo(Owner.Handle, Code, ScrollInfo, True);
  SetPosition(fPosition);
  fPageIncrement := (ControlSize(True, False) * 9) div 10;
  if Smooth then fIncrement := fPageIncrement div 10;
end;

{ TGraphObject }

constructor TGraphObject.Create(AOwner: TSimpleGraph);
begin
  fState := osCreating; // Owner should reset the state
  fIsLink := (Self is TGraphLink);
  fID := AOwner.GetUniqueID(1);
  inherited Create;
  fOwner := AOwner;
  fFont := TFont.Create;
  fFont.OnChange := StyleChanged;
  fBrush := TBrush.Create;
  fBrush.OnChange := StyleChanged;
  fPen := TPen.Create;
  fPen.OnChange := StyleChanged;
  fVisible := True;
  SyncFontToParent;
end;

destructor TGraphObject.Destroy;
begin
  State := osDestroying;
  fPen.Free;
  fBrush.Free;
  fFont.Free;
  inherited Destroy;
end;

procedure TGraphObject.InitializeInstance;
begin
  // Nothing to do
end;

procedure TGraphObject.LocateLinkedObjects(StartIndex: Integer);
begin
  // Nothing to do
end;

procedure TGraphObject.CalculateTextParameters;
begin
  // Nothing to do
end;

function TGraphObject.VerifyLinkedObjects: Boolean;
begin
  Result := True;
end;

function TGraphObject.ChangeLinkedObject(OldObject, NewObject: TGraphObject): Boolean;
begin
  Result := True;
end;

procedure TGraphObject.Changed(DataModified: Boolean);
begin
  if State = osNone then
    Owner.ObjectChanged(Self, DataModified);
end;

function TGraphObject.IsFontStored: Boolean;
begin
  Result := not ParentFont;
end;

procedure TGraphObject.SetFont(Value: TFont);
begin
  Font.Assign(Value);
end;

procedure TGraphObject.SetParentFont(Value: Boolean);
begin
  if ParentFont <> Value then
  begin
    fParentFont := Value;
    if ParentFont then
      SyncFontToParent;
    Changed(True);
  end;
end;

procedure TGraphObject.SetBrush(Value: TBrush);
begin
  Brush.Assign(Value);
end;

procedure TGraphObject.SetPen(Value: TPen);
begin
  Pen.Assign(Value);
end;

procedure TGraphObject.SetText(const Value: String);
begin
  if Text <> Value then
  begin
    fText := Value;
    CalculateTextParameters(True, 0, 0);
    Changed(True);
  end;
end;

procedure TGraphObject.SetDragging(Value: Boolean);
begin
  if Dragging <> Value then
  begin
    fDragging := Value;
    Changed(False);
  end;
end;

function TGraphObject.GetZOrder: Integer;
begin
  Result := Owner.Objects.IndexOf(Self);
end;

procedure TGraphObject.SetZOrder(Value: Integer);
begin
  if (Value < 0) or (Value >= Owner.Objects.Count) then
    Value := Owner.Objects.Count - 1;
  Owner.Objects.Move(ZOrder, Value);
end;

procedure TGraphObject.SetState(Value: TGraphObjectState);
var
  OldState: TGraphObjectState;
begin
  if State <> Value then
  begin
    if State = osCreating then
      Owner.Objects.Add(Self);
    OldState := State;
    fState := Value;
    if State = osDestroying then
      Owner.Objects.Remove(Self)
    else if (State = osNone) and (OldState in [osCreating, osReading]) then
      InitializeInstance;
  end;
end;

procedure TGraphObject.SetSelected(Value: Boolean);
begin
  if Selected <> Value then
  begin
    fSelected := Value;
    if Selected then
      Owner.SelectedObjects.Add(Self)
    else
      Owner.SelectedObjects.Remove(Self)
  end;
end;

procedure TGraphObject.SetVisible(Value: Boolean);
begin
  if Visible <> Value then
  begin
    fVisible := Value;
    Changed(True);
  end;
end;

procedure TGraphObject.StyleChanged(Sender: TObject);
begin
  if Sender <> Font then
    Changed(True)
  else
  begin
    CalculateTextParameters(True, 0, 0);
    if not InSyncFont then
    begin
      fParentFont := False;
      Changed(True);
    end
    else
      fParentFont := True;
  end;
end;

function TGraphObject.GetShowing: Boolean;
begin
  Result := (State = osNone) and (Visible or Owner.ShowHiddenObjects);
end;

function TGraphObject.IsVisibleOn(Canvas: TCanvas): Boolean;
var
  Rect: TRect;
  Grow: Integer;
begin
  if Showing then
    if Canvas = Owner.Canvas then
    begin
      Rect := BoundsRect;
      Grow := Pen.Width;
      if Selected then
        Inc(Grow, Owner.MarkerSize);
      InflateRect(Rect, Grow, Grow);
      Result := IntersectRect(Rect, Rect, Owner.VisibleBounds);
    end
    else
      Result := True
  else
    Result := False;
end;

procedure TGraphObject.SyncFontToParent;
begin
  InSyncFont := True;
  try
    Font.Assign(Owner.Font);
  finally
    InSyncFont := False;
  end;
end;

procedure TGraphObject.BringToFront;
begin
  ZOrder := MaxInt;
end;

procedure TGraphObject.SendToBack;
begin
  ZOrder := 0;
end;

procedure TGraphObject.Assign(Source: TPersistent);
begin
  if Source is TGraphObject then
  begin
    Owner.BeginUpdate;
    try
      Text := TGraphObject(Source).Text;
      Brush := TGraphObject(Source).Brush;
      Pen := TGraphObject(Source).Pen;
      Font := TGraphObject(Source).Font;
      ParentFont := TGraphObject(Source).ParentFont;
      Visible := TGraphObject(Source).Visible;
      Tag := TGraphObject(Source).Tag;
    finally
      Owner.EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TGraphObject.Draw(Canvas: TCanvas);
begin
  if IsVisibleOn(Canvas) then
  begin
    Canvas.Brush := Brush;
    Canvas.Pen := Pen;
    DrawBody(Canvas);
    if Text <> '' then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Font := Font;
      DrawText(Canvas);
    end;
  end;
end;

function TGraphObject.ConvertTo(AnotherClass: TGraphObjectClass): Boolean;
begin
  Result := False;
  if (AnotherClass <> nil) and (ClassType <> AnotherClass) then
    Result := Owner.ChangeObjectClass(Self, AnotherClass);
end;

procedure TGraphObject.LoadFromStream(Stream: TStream);
var
  Streamable: TGraphStreamableObject;
begin
  State := osReading;
  try
    Streamable := TGraphStreamableObject.Create(nil);
    try
      Streamable.G := Self;
      Stream.ReadComponent(Streamable);
      Self.OldID := Streamable.ID;
      Self.ID := Owner.GetUniqueID(Streamable.ID);
    finally
      Streamable.Free;
    end;
  finally
    State := osNone;
  end;
end;

procedure TGraphObject.SaveToStream(Stream: TStream);
var
  Streamable: TGraphStreamableObject;
begin
  State := osWriting;
  try
    Streamable := TGraphStreamableObject.Create(nil);
    try
      Streamable.G := Self;
      Streamable.ID := Self.ID;
      Stream.WriteComponent(Streamable);
    finally
      Streamable.Free;
    end;
  finally
    State := osNone;
  end;
end;

{ TGraphLink }

constructor TGraphLink.Create(AOwner: TSimpleGraph);
begin
  inherited Create(AOwner);
  fKind := lkDirected;
  fArrowSize := 4;
end;

destructor TGraphLink.Destroy;
begin
  if TextRegion <> 0 then
    DeleteObject(TextRegion);
  inherited Destroy;
end;

procedure TGraphLink.Assign(Source: TPersistent);
begin
  Owner.BeginUpdate;
  try
    if Source is TGraphLink then
    begin
      FromNodeID := TGraphLink(Source).FromNodeID;
      ToNodeID := TGraphLink(Source).ToNodeID;
    end;
    inherited Assign(Source);
  finally
    Owner.EndUpdate;
  end;
end;

function TGraphLink.FindMarkerAt(X, Y: Integer): TMarkerType;
var
  Marker: TMarkerType;
  Pt: TPoint;
begin
  Result := mtNone;
  if Showing then
  begin
    if Selected then
    begin
      Pt := Point(X, Y);
      for Marker := mtMoveStrartPt to mtMoveEndPt do
        if PtInRect(MarkerRect(Marker), Pt) then
        begin
          Result := Marker;
          Exit;
        end;
    end;
    if ContainsPoint(X, Y) then
      Result := mtSelect;
  end;
end;

function TGraphLink.MarkerRect(MarkerType: TMarkerType): TRect;
begin
  FillChar(Result, SizeOf(TRect), 0);
  case MarkerType of
    mtMoveStrartPt:
      if FromNode <> nil then
      begin
        with StartPt do SetRect(Result, X, Y, X, Y);
        InflateRect(Result, Owner.MarkerSize, Owner.MarkerSize);
      end;
    mtMoveEndPt:
      if ToNode <> nil then
      begin
        with EndPt do SetRect(Result, X, Y, X, Y);
        InflateRect(Result, Owner.MarkerSize, Owner.MarkerSize);
      end;
  end;
end;

function TGraphLink.ContainsPoint(X, Y: Integer): Boolean;
var
  Margin: Integer;
  R: TRect;
begin
  Result := False;
  if Showing and (FromNode <> nil) and (ToNode <> nil) then
  begin
    if (TextRegion <> 0) and PtInRegion(TextRegion, X, Y) then
      Result := True
    else
    begin
      Margin := Pen.Width + Owner.MarkerSize;
      if DistanceToLine(StartPt, EndPt, Point(X, Y)) <= Margin then
      begin
        Margin := Margin div 2;
        R := MakeRect(StartPt, EndPt);
        InflateRect(R, Margin, Margin);
        Result := PtInRect(R, Point(X, Y));
      end;
    end;
  end;
end;

procedure TGraphLink.DrawMarkers(Canvas: TCanvas);
begin
  if not Dragging and IsVisibleOn(Canvas) then
  begin
    Canvas.Brush.Color := Owner.MarkerColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(MarkerRect(mtMoveStrartPt));
    Canvas.FillRect(MarkerRect(mtMoveEndPt));
  end;
end;

procedure TGraphLink.DrawText(Canvas: TCanvas);
var
  LogFont: TLogFont;
  FontHandle: THandle;
  TextAlign, TextFlags: Integer;
begin
  if TextToShow <> '' then
  begin
    GetObject(Canvas.Font.Handle, SizeOf(LogFont), @LogFont);
    if Abs(Angle) > Pi / 2 then
      LogFont.lfEscapement := Round(-1800 * (Angle - Pi) / Pi)
    else
      LogFont.lfEscapement := Round(-1800 * Angle / Pi);
    LogFont.lfOrientation := LogFont.lfEscapement;
    LogFont.lfQuality := PROOF_QUALITY;
    FontHandle := SelectObject(Canvas.Handle, CreateFontIndirect(LogFont));
    TextAlign := SetTextAlign(Canvas.Handle, TA_BOTTOM or TA_CENTER);
    TextFlags := Canvas.TextFlags;
    if Owner.UseRightToLeftReading then
      Canvas.TextFlags := Canvas.TextFlags or ETO_RTLREADING
    else
      Canvas.TextFlags := Canvas.TextFlags and not ETO_RTLREADING;
    Canvas.TextOut(TextCenter.X, TextCenter.Y, TextToShow);
    Canvas.TextFlags := TextFlags;
    SetTextAlign(Canvas.Handle, TextAlign);
    DeleteObject(SelectObject(Canvas.Handle, FontHandle));
  end;
end;

procedure TGraphLink.DrawBody(Canvas: TCanvas);

  procedure DrawArrow(const Pt: TPoint; ArrowScale: Integer);
  var
    ArrowHeight: Integer;
    ArrowPts: array[1..4] of TPoint;
  begin
    if Owner.MarkerSize > Pen.Width then
      ArrowHeight := ArrowScale * Owner.MarkerSize
    else
      ArrowHeight := ArrowScale * Pen.Width;
    ArrowPts[1] := Pt;
    ArrowPts[2] := NextPointOfLine(Angle+Pi/6, Pt, ArrowHeight);
    ArrowPts[3] := NextPointOfLine(Angle, Pt, MulDiv(ArrowHeight, 2, 3));
    ArrowPts[4] := NextPointOfLine(Angle-Pi/6, Pt, ArrowHeight);
    Canvas.Polygon(ArrowPts);
  end;

begin
  with StartPt do Canvas.MoveTo(X, Y);
  with EndPt do Canvas.LineTo(X, Y);
  if Kind <> lkUndirected then
  begin
    DrawArrow(EndPt, ArrowSize);
    if Kind = lkBidirected then
      DrawArrow(StartPt, -ArrowSize);
  end;
end;

procedure TGraphLink.Draw(Canvas: TCanvas);
begin
  if not Dragging then inherited Draw(Canvas);
end;

class procedure TGraphLink.DrawDraft(Canvas: TCanvas; const ARect: TRect);
var
  Pts: array[0..1] of TPoint absolute ARect;
begin
  Canvas.Polyline(Pts);
end;

procedure TGraphLink.SetBoundsRect(const Rect: TRect);
begin
  // Nothing to do
end;

function TGraphLink.GetBoundsRect: TRect;
begin
  Result := MakeRect(fStartPt, fEndPt);
end;

procedure TGraphLink.CalculateEndPoints;
begin
  if (FromNode <> nil) and (ToNode <> nil) and (State = osNone) then
  begin
    fStartPt := FromNode.Center;
    fEndPt := ToNode.Center;
    if fStartPt.X <> fEndPt.X then
      fAngle := ArcTan2((EndPt.Y - StartPt.Y), (EndPt.X - StartPt.X))
    else if fStartPt.Y >= fEndPt.Y then
      fAngle := -Pi / 2
    else
      fAngle := Pi / 2;
    fStartPt := FromNode.LinkIntersect(Angle, False);
    fEndPt := ToNode.LinkIntersect(Angle, True);
    CalculateTextParameters(True, 0, 0);
  end;
end;

procedure TGraphLink.CalculateTextParameters(Recalc: Boolean; dX, dY: Integer);
begin
  if State = osNone then
  begin
    if Recalc then
    begin
      if fTextRegion <> 0 then
      begin
        DeleteObject(TextRegion);
        fTextRegion := 0;
      end;
      fTextRegion := GetTextRegion;
    end
    else if fTextRegion <> 0 then
    begin
      Inc(TextCenter.X, dX);
      Inc(TextCenter.Y, dY);
      OffsetRgn(fTextRegion, dX, dY);
    end;
  end;
end;

function TGraphLink.GetTextRegion: HRGN;
const
  DrawTextFlags = DT_NOPREFIX or DT_END_ELLIPSIS or DT_EDITCONTROL or DT_MODIFYSTRING;
var
  RgnPts: array[1..4] of TPoint;
  ArrowHeight: Integer;
  LineWidth: Integer;
  TextRect: TRect;
  TextTemp: PChar;
begin
  Result := 0;
  TextToShow := '';
  if (Text <> '') and (FromNode <> nil) and (ToNode <> nil) then
  begin
    if Owner.MarkerSize > Pen.Width then
      ArrowHeight := 4 * Owner.MarkerSize
    else
      ArrowHeight := 4 * Pen.Width;
    LineWidth := Trunc(Sqrt(Sqr(StartPt.X - EndPt.X) + Sqr(StartPt.Y - EndPt.Y)));
    if LineWidth > 3 * ArrowHeight then
    begin
      Dec(LineWidth, 3 * ArrowHeight);
      SetRect(TextRect, 0, 0, LineWidth, 0);
      Owner.Canvas.Font := Font;
      TextTemp := StrNew(PChar(Text));
      try
        Windows.DrawText(Owner.Canvas.Handle, TextTemp, StrLen(TextTemp), TextRect,
          Owner.DrawTextBiDiModeFlags(DrawTextFlags) or DT_CALCRECT);
        TextToShow := StrPas(TextTemp);
      finally
        StrDispose(TextTemp);
      end;
      TextCenter.X := (StartPt.X + EndPt.X) div 2;
      TextCenter.Y := (StartPt.Y + EndPt.Y) div 2;
      TextCenter := NextPointOfLine(Angle - Pi / 2, TextCenter, TextRect.Top);
      OffsetRect(TextRect, TextCenter.X - TextRect.Right div 2,
                         TextCenter.Y - TextRect.Bottom);
      RgnPts[1] := TextRect.TopLeft;
      RgnPts[2] := Point(TextRect.Right, TextRect.Top);
      RgnPts[3] := TextRect.BottomRight;
      RgnPts[4] := Point(TextRect.Left, TextRect.Bottom);
      if Abs(Angle) > Pi / 2 then
        RotatePoints(RgnPts, Angle - Pi, TextCenter)
      else
        RotatePoints(RgnPts, Angle, TextCenter);
      Result := CreatePolygonRgn(RgnPts, 4, ALTERNATE);
    end;
  end;
end;

procedure TGraphLink.Reverse;
var
  Node: TGraphNode;
  NodeID: Integer;
begin
  Node := fFromNode;
  NodeID := FromNodeID;
  fFromNode := fToNode;
  FromNodeID := ToNodeID;
  fToNode := Node;
  ToNodeID := NodeID;
  Changed(True);
end;

procedure TGraphLink.SetFromNode(Value: TGraphNode);
begin
  if (FromNode <> Value) and (Value <> nil) and (ToNode <> Value) then
  begin
    fFromNode := Value;
    if FromNode = nil then
      FromNodeID := 0
    else
      FromNodeID := FromNode.ID;
    Changed(True);
  end;
end;

procedure TGraphLink.SetToNode(Value: TGraphNode);
begin
  if (ToNode <> Value) and (Value <> nil) and (FromNode <> Value) then
  begin
    fToNode := Value;
    if ToNode = nil then
      ToNodeID := 0
    else
      ToNodeID := ToNode.ID;
    Changed(True);
  end;
end;

procedure TGraphLink.SetKind(Value: TLinkKind);
begin
  if Kind <> Value then
  begin
    fKind := Value;
    Changed(True);
  end;
end;

procedure TGraphLink.SetArrowSize(Value: TArrowSize);
begin
  if ArrowSize <> Value then
  begin
    fArrowSize := Value;
    Changed(True);
  end;
end;

procedure TGraphLink.Changed(DataModified: Boolean);
begin
  if DataModified and (State = osNone) then
    CalculateEndPoints;
  inherited Changed(DataModified);
end;

procedure TGraphLink.InitializeInstance;
begin
  CalculateEndPoints;
end;

procedure TGraphLink.LocateLinkedObjects(StartIndex: Integer);
var
  Node: TGraphNode;
begin
  Node := TGraphNode(Owner.FindObjectByOldID(StartIndex, FromNodeID, TGraphNode));
  if Node <> nil then
    FromNodeID := Node.ID;
  Node := TGraphNode(Owner.FindObjectByOldID(StartIndex, ToNodeID, TGraphNode));
  if Node <> nil then
    ToNodeID := Node.ID;
end;

function TGraphLink.VerifyLinkedObjects: Boolean;
var
  AFromNode, AToNode: TGraphNode;
begin
  Result := False;
  AFromNode := TGraphNode(Owner.FindObjectByID(FromNodeID, TGraphNode));
  AToNode := TGraphNode(Owner.FindObjectByID(ToNodeID, TGraphNode));
  if Owner.IsValidLink(Self, AFromNode, AToNode) then
  begin
    fFromNode := AFromNode;
    fToNode := AToNode;
    CalculateEndPoints;
    Result := True;
  end;
end;

function TGraphLink.ChangeLinkedObject(OldObject, NewObject: TGraphObject): Boolean;
begin
  if FromNode = OldObject then
    if NewObject <> nil then
      FromNodeID := NewObject.ID
    else
      FromNodeID := 0;
  if ToNode = OldObject then
    if NewObject <> nil then
      ToNodeID := NewObject.ID
    else
      ToNodeID := 0;
  Result := VerifyLinkedObjects;
end;

procedure TGraphLink.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('FromNode', ReadFromNode, WriteFromNode, FromNode <> nil);
  Filer.DefineProperty('ToNode', ReadToNode, WriteToNode, ToNode <> nil);
end;

procedure TGraphLink.ReadFromNode(Reader: TReader);
begin
  FromNodeID := Reader.ReadInteger;
end;

procedure TGraphLink.WriteFromNode(Writer: TWriter);
begin
  Writer.WriteInteger(FromNodeID);
end;

procedure TGraphLink.ReadToNode(Reader: TReader);
begin
  ToNodeID := Reader.ReadInteger;
end;

procedure TGraphLink.WriteToNode(Writer: TWriter);
begin
  Writer.WriteInteger(ToNodeID);
end;

{ TGraphNode }

constructor TGraphNode.Create(AOwner: TSimpleGraph);
begin
  inherited Create(AOwner);
  fMargin := 8;
  fAlignment := taCenter;
  fBackground := TPicture.Create;
  fBackground.OnChange := BackgroundChanged;
end;

destructor TGraphNode.Destroy;
begin
  if Region <> 0 then
    DeleteObject(Region);
  fBackground.Free;
  inherited Destroy;
end;

procedure TGraphNode.Assign(Source: TPersistent);
begin
  Owner.BeginUpdate;
  try
    if Source is TGraphNode then
      with Source as TGraphNode do
      begin
        Self.SetBounds(Left, Top, Width, Height);
        Self.Background := Background;
        Self.Alignment := Alignment;
        Self.Margin := Margin;
      end;
    inherited Assign(Source);
  finally
    Owner.EndUpdate;
  end;
end;

function TGraphNode.MarkerRect(MarkerType: TMarkerType): TRect;
var
  R: TRect;
begin
  R := BoundsRect;
  InflateRect(R, -1, -1);
  case MarkerType of
    mtSizeW:
      SetRect(Result, R.Left, R.Top + (R.Bottom - R.Top) div 2, R.Left, R.Top + (R.Bottom - R.Top) div 2);
    mtSizeE:
      SetRect(Result, R.Right, R.Top + (R.Bottom - R.Top) div 2, R.Right, R.Top + (R.Bottom - R.Top) div 2);
    mtSizeN:
      SetRect(Result, R.Left + (R.Right - R.Left) div 2, R.Top, R.Left + (R.Right - R.Left) div 2, R.Top);
    mtSizeS:
      SetRect(Result, R.Left + (R.Right - R.Left) div 2, R.Bottom, R.Left + (R.Right - R.Left) div 2, R.Bottom);
    mtSizeNW:
      SetRect(Result, R.Left, R.Top, R.Left, R.Top);
    mtSizeNE:
      SetRect(Result, R.Right, R.Top, R.Right, R.Top);
    mtSizeSW:
      SetRect(Result, R.Left, R.Bottom, R.Left, R.Bottom);
    mtSizeSE:
      SetRect(Result, R.Right, R.Bottom, R.Right, R.Bottom);
  else
    FillChar(Result, SizeOf(TRect), 0);
    Exit;
  end;
  InflateRect(Result, Owner.MarkerSize, Owner.MarkerSize);
end;

procedure TGraphNode.MoveMarkerBy(MarkerType: TMarkerType; const Delta: TPoint);
var
  OldWidth, OldHeight: Integer;
begin
  case MarkerType of
    mtMove:
      SetBounds(Left + Delta.X, Top + Delta.Y, Width, Height);
    mtSizeW:
    begin
      OldWidth := Width;
      SetBounds(Left, Top, Width - Delta.X, Height);
      SetBounds(Left + (OldWidth - Width), Top, Width, Height);
    end;
    mtSizeE:
      SetBounds(Left, Top, Width + Delta.X, Height);
    mtSizeN:
    begin
      OldHeight := Height;
      SetBounds(Left, Top, Width, Height - Delta.Y);
      SetBounds(Left, Top + (OldHeight - Height), Width, Height);
    end;
    mtSizeS:
      SetBounds(Left, Top, Width, Height + Delta.Y);
    mtSizeNW:
    begin
      OldWidth := Width;
      OldHeight := Height;
      SetBounds(Left, Top, Width - Delta.X, Height - Delta.Y);
      SetBounds(Left + (OldWidth - Width), Top + (OldHeight - Height), Width, Height);
    end;
    mtSizeNE:
    begin
      OldHeight := Height;
      SetBounds(Left, Top, Width + Delta.X, Height - Delta.Y);
      SetBounds(Left, Top + (OldHeight - Height), Width, Height);
    end;
    mtSizeSW:
    begin
      OldWidth := Width;
      SetBounds(Left, Top, Width - Delta.X, Height + Delta.Y);
      SetBounds(Left + (OldWidth - Width), Top, Width, Height);
    end;
    mtSizeSE:
      SetBounds(Left, Top, Width + Delta.X, Height + Delta.Y);
  end;
end;

function TGraphNode.FindMarkerAt(X, Y: Integer): TMarkerType;
var
  Marker: TMarkerType;
  Pt: TPoint;
begin
  Result := mtNone;
  if Showing then
  begin
    if Selected then
    begin
      Pt := Point(X, Y);
      for Marker := Succ(mtNone) to Pred(mtMove) do
        if PtInRect(MarkerRect(Marker), Pt) then
        begin
          Result := Marker;
          Exit;
        end;
    end;
    if ContainsPoint(X, Y) then
      Result := mtMove;
  end;
end;

function TGraphNode.ContainsPoint(X, Y: Integer): Boolean;
begin
  Result := Showing and PtInRegion(Region, X, Y);
end;

function TGraphNode.CreateClipRgn(Canvas: TCanvas): HRGN;
var
  XForm: TXForm;
  DevExt: TSize;
  LogExt: TSize;
  Org: TPoint;
begin
  GetViewportExtEx(Canvas.Handle, DevExt);
  GetWindowExtEx(Canvas.Handle, LogExt);
  GetViewportOrgEx(Canvas.Handle, Org);
  with XForm do
  begin
    eM11 := DevExt.CX / LogExt.CX;
    eM12 := 0;
    eM21 := 0;
    eM22 := DevExt.CY / LogExt.CY;
    eDx := Org.X;
    eDy := Org.Y;
  end;
  Result := TransformRgn(Region, XForm);
end;

procedure TGraphNode.DrawMarkers(Canvas: TCanvas);
var
  Marker: TMarkerType;
  R: TRect;
begin
  if IsVisibleOn(Canvas) then
  begin
    if not Dragging then
    begin
      if not Owner.LockNodes then
      begin
        Canvas.Brush.Style := bsSolid;
        Canvas.Brush.Color := Owner.MarkerColor;
        for Marker := Succ(mtNone) to Pred(mtMove) do
          Canvas.FillRect(MarkerRect(Marker));
      end
      else
      begin
        Canvas.Pen.Color := Owner.MarkerColor;
        Canvas.Pen.Mode := pmCopy;
        Canvas.Pen.Style := psInsideFrame;
        Canvas.Pen.Width := 1;
        Canvas.Brush.Style := bsClear;
        for Marker := Succ(mtNone) to Pred(mtMove) do
          with MarkerRect(Marker) do
            Canvas.Rectangle(Left, Top, Right, Bottom);
      end;
    end
    else
    begin
      Canvas.Pen.Mode := pmNot;
      Canvas.Pen.Style := psInsideFrame;
      Canvas.Pen.Width := Owner.MarkerSize-1;
      Canvas.Brush.Style := bsClear;
      R := BoundsRect;
      InflateRect(R, Owner.MarkerSize-1, Owner.MarkerSize-1);
      Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
    end;
  end;
end;

function TGraphNode.GetCenter: TPoint;
begin
  Result.X := Left + Width div 2;
  Result.Y := Top + Height div 2;
end;

function TGraphNode.GetMaxTextRect: TRect;
begin
  SetRect(Result, Margin, Margin, Width - Margin, Height - Margin);
end;

function TGraphNode.GetTextRect: TRect;
var
  MaxTextRect: TRect;
  DrawTextFlags: Integer;
begin
  if Text <> '' then
  begin
    MaxTextRect := GetMaxTextRect;
    DrawTextFlags := DT_WORDBREAK or DT_NOPREFIX or DT_END_ELLIPSIS or
      DT_EDITCONTROL or TextAlignFlags[Alignment];
    Owner.Canvas.Font := Font;
    Result := MaxTextRect;
    Windows.DrawText(Owner.Canvas.Handle, PChar(Text), Length(Text), Result,
      Owner.DrawTextBiDiModeFlags(DrawTextFlags) or DT_CALCRECT);
    if Result.Right > MaxTextRect.Right then
      Result.Right := MaxTextRect.Right;
    if Result.Bottom > MaxTextRect.Bottom then
      Result.Bottom := MaxTextRect.Bottom;
    if not IsRectEmpty(Result) then
    begin
      case Alignment of
        taLeftJustify:
          OffsetRect(Result, Left,
                             Top + (MaxTextRect.Bottom - Result.Bottom) div 2);
        taRightJustify:
          OffsetRect(Result, Left + (MaxTextRect.Right - Result.Right) - Margin,
                             Top + (MaxTextRect.Bottom - Result.Bottom) div 2);
      else
        OffsetRect(Result, Left + (MaxTextRect.Right - Result.Right) div 2,
                            Top + (MaxTextRect.Bottom - Result.Bottom) div 2);
      end;
    end;
  end
  else
    FillChar(Result, SizeOf(Result), 0);
end;

procedure TGraphNode.DrawText(Canvas: TCanvas);
var
  Rect: TRect;
  DrawTextFlags: Integer;
begin
  if not IsRectEmpty(TextRect) then
  begin
    Rect := TextRect;
    DrawTextFlags := DT_WORDBREAK or DT_NOPREFIX or DT_END_ELLIPSIS or
      DT_EDITCONTROL or TextAlignFlags[Alignment];
    Windows.DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect,
      Owner.DrawTextBiDiModeFlags(DrawTextFlags));
  end;
end;

procedure TGraphNode.DrawBackground(Canvas: TCanvas);
var
  ClipRgn: HRGN;
begin
  if Background.Graphic <> nil then
  begin
    ClipRgn := CreateClipRgn(Canvas);
    try
      SelectClipRgn(Canvas.Handle, ClipRgn);
      try
        Background.OnChange := nil;
        try
          Canvas.StretchDraw(BoundsRect, Background.Graphic);
        finally
          Background.OnChange := BackgroundChanged;
        end;
      finally
        SelectClipRgn(Canvas.Handle, 0);
      end;
    finally
      DeleteObject(ClipRgn);
    end;
    Canvas.Brush.Style := bsClear;
  end;
end;

function TGraphNode.QueryLinkTo(Node: TGraphNode): TQueryLinkResult;
var
  I: Integer;
begin
  Result := qlrNone;
  for I := 0 to Owner.Objects.Count - 1 do
    if Owner.Objects[I].IsLink then
      with TGraphLink(Owner.Objects[I]) do
        if (FromNode = Self) and (ToNode = Node) then
        begin
          case Kind of
            lkUndirected: Result := qlrLinked;
            lkDirected: Result := qlrLinkedOut;
            lkBidirected: Result := qlrLinkedInOut;
          end;
          Break;
        end
        else if (ToNode = Self) and (FromNode = Node) then
        begin
          case Kind of
            lkUndirected: Result := qlrLinked;
            lkDirected: Result := qlrLinkedIn;
            lkBidirected: Result := qlrLinkedInOut;
          end;
          Break;
        end;
end;

procedure TGraphNode.CalculateTextParameters(Recalc: Boolean; dX, dY: Integer);
begin
  if State = osNone then
  begin
    if Recalc then
      fTextRect := GetTextRect
    else
      OffsetRect(fTextRect, dX, dY);
  end;
end;

procedure TGraphNode.BoundsChanged(dX, dY, dCX, dCY: Integer);
var
  I: Integer;
begin
  for I := 0 to Owner.Objects.Count - 1 do
    if Owner.Objects[I].IsLink then
      with TGraphLink(Owner.Objects[I]) do
        if (FromNode = Self) or (ToNode = Self) then
          CalculateEndPoints;
  if Region <> 0 then
    DeleteObject(Region);
  fRegion := GetRegion;
  CalculateTextParameters((dCX <> 0) or (dCY <> 0), dX, dY);
end;

procedure TGraphNode.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
var
  CanMove, CanResize: Boolean;
  dX, dY, dCX, dCY: Integer;
begin
  if Owner.VerifyNodeMoveResize(Self, aLeft, aTop,
     aWidth, aHeight, CanMove, CanResize) then
  begin
    dX := 0;
    dY := 0;
    if CanMove then
    begin
      dX := aLeft - fLeft;
      fLeft := aLeft;
      dY := aTop - fTop;
      fTop := aTop;
    end;
    dCX := 0;
    dCY := 0;
    if CanResize then
    begin
      dCX := aWidth - fWidth;
      fWidth := aWidth;
      dCY := aHeight - fHeight;
      fHeight := aHeight;
    end;
    if State = osNone then
    begin
      BoundsChanged(dX, dY, dCX, dCY);
      Changed(True);
    end;
  end;
end;

procedure TGraphNode.SetBoundsRect(const Rect: TRect);
begin
  with Rect do SetBounds(Left, Top, Right - Left, Bottom - Top);
end;

function TGraphNode.GetBoundsRect: TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Left + Width;
  Result.Bottom := Top + Height;
end;

procedure TGraphNode.SetLeft(Value: Integer);
begin
  if State = osReading then
    fLeft := Value
  else if Left <> Value then
    SetBounds(Value, Top, Width, Height);
end;

procedure TGraphNode.SetTop(Value: Integer);
begin
  if State = osReading then
    fTop := Value
  else if Top <> Value then
    SetBounds(Left, Value, Width, Height);
end;

procedure TGraphNode.SetWidth(Value: Integer);
begin
  if State = osReading then
    fWidth := Value
  else if Width <> Value then
    SetBounds(Left, Top, Value, Height);
end;

procedure TGraphNode.SetHeight(Value: Integer);
begin
  if State = osReading then
    fHeight := Value
  else if Height <> Value then
    SetBounds(Left, Top, Width, Value);
end;

procedure TGraphNode.SetAlignment(Value: TAlignment);
begin
  if Alignment <> Value then
  begin
    fAlignment := Value;
    CalculateTextParameters(True, 0, 0);
    Changed(True);
  end;
end;

procedure TGraphNode.SetMargin(Value: Integer);
begin
  if Margin <> Value then
  begin
    fMargin := Value;
    CalculateTextParameters(True, 0, 0);
    Changed(True);
  end;
end;

procedure TGraphNode.SetBackground(Value: TPicture);
begin
  if fBackground <> Value then
    fBackground.Assign(Value);
end;

procedure TGraphNode.BackgroundChanged(Sender: TObject);
begin
  Changed(True);
end;

procedure TGraphNode.InitializeInstance;
begin
  BoundsChanged(Left, Top, Width, Height);
end;

{ TPlygonalNode }

destructor TPolygonalNode.Destroy;
begin
  fVertices := nil;
  inherited Destroy;
end;

procedure TPolygonalNode.BoundsChanged(dX, dY, dCX, dCY: Integer);
begin
  if not Assigned(fVertices) or (dCX <> 0) or (dCY <> 0) then
    DefineVertices(BoundsRect, fVertices)
  else
    OffsetPoints(fVertices, dX, dY);
  inherited BoundsChanged(dX, dY, dCX, dCY);
end;

function TPolygonalNode.LinkIntersect(const LinkAngle: Extended;
  Backward: Boolean): TPoint;
begin
  Result := IntersectLinePolygon(LinkAngle, Vertices, Backward);
end;

function TPolygonalNode.GetCenter: TPoint;
begin
  Result := CenterOfPoints(Vertices);
end;

function TPolygonalNode.GetRegion: HRGN;
begin
  Result := CreatePolygonRgn(Vertices[0], Length(Vertices), WINDING);
end;

procedure TPolygonalNode.DrawBody(Canvas: TCanvas);
begin
  DrawBackground(Canvas);
  Canvas.Polygon(Vertices);
end;

class procedure TPolygonalNode.DrawDraft(Canvas: TCanvas; const ARect: TRect);
var
  Points: TPointArray;
  I: Integer;
begin
  DefineVertices(ARect, Points);
  try
    with Points[0] do Canvas.MoveTo(X, Y);
    for I := Length(Points) - 1 downto 0 do
      with Points[I] do Canvas.LineTo(X, Y);
  finally
    Points := nil;
  end;
end;

{ TRectangularNode }

function TRectangularNode.LinkIntersect(const LinkAngle: Extended;
  Backward: Boolean): TPoint;
begin
  Result := IntersectLineRect(LinkAngle, BoundsRect, Backward);
end;

function TRectangularNode.GetRegion: HRGN;
begin
  Result := CreateRectRgn(Left, Top, Left + Width, Top + Height);
end;

procedure TRectangularNode.DrawBody(Canvas: TCanvas);
begin
  DrawBackground(Canvas);
  Canvas.Rectangle(Left, Top, Left + Width, Top + Height);
end;

class procedure TRectangularNode.DrawDraft(Canvas: TCanvas;
  const ARect: TRect);
begin
  Canvas.Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
end;

{ TRoundRectangularNode }

function TRoundRectangularNode.LinkIntersect(const LinkAngle: Extended;
  Backward: Boolean): TPoint;
begin
  Result := IntersectLineRoundRect(LinkAngle, BoundsRect, Backward, Region);
end;

function TRoundRectangularNode.GetRegion: HRGN;
var
  S: Integer;
begin
  if Width > Height then S := Width div 4 else S := Height div 4;
  Result := CreateRoundRectRgn(Left, Top, Left + Width + 1, Top + Height + 1, S, S);
end;

procedure TRoundRectangularNode.DrawBody(Canvas: TCanvas);
var
  S: Integer;
begin
  DrawBackground(Canvas);
  if Width > Height then S := Width div 4 else S := Height div 4;
  Canvas.RoundRect(Left, Top, Left + Width, Top + Height, S, S);
end;

class procedure TRoundRectangularNode.DrawDraft(Canvas: TCanvas;
  const ARect: TRect);
var
  S: Integer;
  Width, Height: Integer;
begin
  Width := ARect.Right - ARect.Left;
  Height := ARect.Bottom - ARect.Top;
  if Width > Height then S := Width div 4 else S := Height div 4;
  Canvas.RoundRect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom, S, S);
end;

{ TEllipticNode }

function TEllipticNode.LinkIntersect(const LinkAngle: Extended;
  Backward: Boolean): TPoint;
begin
  Result := IntersectLineEllipse(LinkAngle, BoundsRect, Backward);
end;

function TEllipticNode.GetRegion: HRGN;
begin
  Result := CreateEllipticRgn(Left, Top, Left + Width + 1, Top + Height + 1);
end;

procedure TEllipticNode.DrawBody(Canvas: TCanvas);
begin
  DrawBackground(Canvas);
  Canvas.Ellipse(Left, Top, Left + Width, Top + Height);
end;

class procedure TEllipticNode.DrawDraft(Canvas: TCanvas;
  const ARect: TRect);
begin
  Canvas.Ellipse(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
end;

{ TTriangularNode }

function TTriangularNode.GetMaxTextRect: TRect;
begin
  with Result do
  begin
    Left := (Vertices[0].X + Vertices[2].X) div 2;
    Top := (Vertices[0].Y + Vertices[2].Y) div 2;
    Right := (Vertices[0].X + Vertices[1].X) div 2;
    Bottom := Vertices[1].Y;
  end;
  OffsetRect(Result, -Left, -Top);
  IntersectRect(Result, Result, inherited GetMaxTextRect);
end;

class procedure TTriangularNode.DefineVertices(const ARect: TRect;
  var Points: TPointArray);
begin
  SetLength(Points, 3);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := Bottom;
    end;
    with Points[2] do
    begin
      X := Left;
      Y := Bottom;
    end;
  end;
end;

{ TRhomboidalNode }

function TRhomboidalNode.GetMaxTextRect: TRect;
begin
  with Result do
  begin
    Left := (Vertices[0].X + Vertices[3].X) div 2;
    Top := (Vertices[0].Y + Vertices[3].Y) div 2;
    Right := (Vertices[1].X + Vertices[2].X) div 2;
    Bottom := (Vertices[1].Y + Vertices[2].Y) div 2;
  end;
  OffsetRect(Result, -Left, -Top);
  IntersectRect(Result, Result, inherited GetMaxTextRect);
end;

class procedure TRhomboidalNode.DefineVertices(const ARect: TRect;
  var Points: TPointArray);
begin
  SetLength(Points, 4);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := (Left + Right) div 2;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

{ TPentagonalNode }

function TPentagonalNode.GetMaxTextRect: TRect;
begin
  with Result do
  begin
    Left := Vertices[3].X;
    Top := (Vertices[0].Y + Vertices[4].Y) div 2;
    Right := Vertices[2].X;
    Bottom := Vertices[2].Y;
  end;
  OffsetRect(Result, -Left, -Top);
  IntersectRect(Result, Result, inherited GetMaxTextRect);
end;

class procedure TPentagonalNode.DefineVertices(const ARect: TRect;
  var Points: TPointArray);
begin
  SetLength(Points, 5);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[4] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

{ TGraphObjectList }

function TGraphObjectList.GetItems(Index: Integer): TGraphObject;
begin
  Result := TGraphObject(Get(Index));
end;

procedure TGraphObjectList.Clear;
begin
  while Count > 0 do
    Delete(Count - 1);
  inherited Clear;
end;

function TGraphObjectList.First: TGraphObject;
begin
  Result := TGraphObject(Get(0));
end;

function TGraphObjectList.Last: TGraphObject;
begin
  Result := TGraphObject(Get(Count - 1));
end;

function TGraphObjectList.Add(Item: TGraphObject): Integer;
begin
  Result := IndexOf(Item);
  if Result < 0 then
  begin
    Result := inherited Add(Item);
    NotifyAction(Item, glAdded);
  end;
end;

procedure TGraphObjectList.Insert(Index: Integer; Item: TGraphObject);
var
  CurIndex: Integer;
begin
  CurIndex := IndexOf(Item);
  if CurIndex < 0 then
  begin
    inherited Insert(Index, Item);
    NotifyAction(Item, glAdded);
  end
  else
    Move(CurIndex, Index);
end;

procedure TGraphObjectList.Extract(Item: TGraphObject);
begin
  Remove(Item);
end;

procedure TGraphObjectList.Exchange(Index1, Index2: Integer);
begin
  inherited Exchange(Index1, Index2);
  NotifyAction(nil, glReordered);
end;

procedure TGraphObjectList.Move(CurIndex, NewIndex: Integer);
begin
  inherited Move(CurIndex, NewIndex);
  NotifyAction(TGraphObject(Get(NewIndex)), glReordered);
end;

procedure TGraphObjectList.Delete(Index: Integer);
begin
  Remove(TGraphObject(Get(Index)));
end;

function TGraphObjectList.Remove(Item: TGraphObject): Integer;
begin
  Result := inherited Remove(Item);
  if Result >= 0 then NotifyAction(Item, glRemoved);
end;

function TGraphObjectList.Replace(OldItem, NewItem: TGraphObject): Integer;
begin
  Result := IndexOf(OldItem);
  if Result >= 0 then Put(Result, NewItem);
end;

procedure TGraphObjectList.NotifyAction(GraphObject: TGraphObject;
  Action: TGraphObjectListAction);
begin
  if Assigned(OnChange) then
    OnChange(Self, GraphObject, Action);
end;

{ TSimpleGraph }

constructor TSimpleGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fObjects := TGraphObjectList.Create;
  fObjects.OnChange := ObjectListChanged;
  fSelectedObjects := TGraphObjectList.Create;
  fSelectedObjects.OnChange := SelectionListChanged;
  fGridSize := 8;
  fGridColor := clGray;
  fShowGrid := True;
  fSnapToGrid := True;
  fLockNodes := False;
  fMarkerColor := clBlack;
  fMarkerSize := 3;
  fMinNodeSize := 16;
  fFreezeTopLeft := False;
  fZoom := 100;
  fZoomMin := Low(TZoom);
  fZoomMax := High(TZoom);
  fZoomStep := 25;
  fDefaultKeyMap := True;
  fState := gsNone;
  fCommandMode := cmEdit;
  fModified := False;
  fHorzScrollBar := TGraphScrollBar.Create(Self, sbHorizontal);
  fVertScrollBar := TGraphScrollBar.Create(Self, sbVertical);
  Grid := TBitmap.Create;
  Grid.Width := 8;
  Grid.Height := 8;
  SetRect(SelectionRect, -1, -1, -1, -1);
  if NodeClassCount > 0 then fDefaultNodeClass := NodeClasses(0);
  if LinkClassCount > 0 then fDefaultLinkClass := LinkClasses(0);
end;

destructor TSimpleGraph.Destroy;
begin
  Clear;
  Grid.Free;
  Objects.Free;
  SelectedObjects.Free;
  fHorzScrollBar.Free;
  fVertScrollBar.Free;
  inherited Destroy;
end;

{$IFNDEF DELPHI5_UP}
procedure TSimpleGraph.WMContextMenu(var Message: TMessage);
var
  Handled: Boolean;
  MousePos: TPoint;
begin
  Handled := False;
  MousePos.X := LoWord(Message.LParam);
  MousePos.Y := HiWord(Message.LParam);
  MousePos := ScreenToClient(MousePos);
  DoContextPopup(MousePos, Handled);
  if Handled then
    Message.Result := 1
  else
    inherited;
end;
{$ENDIF}

procedure TSimpleGraph.WMPaint(var Msg: TWMPaint);
var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  PS: TPaintStruct;
  SavedDC: Integer;
  Offset: Integer;
begin
  if Msg.DC <> 0 then
  begin
    if not (csCustomPaint in ControlState) and (ControlCount = 0) then
      inherited
    else
      PaintHandler(Msg);
  end
  else
  begin
    Offset := Zoom div 100;
    DC := GetDC(0);
    try
      with ClientRect do
        MemBitmap := CreateCompatibleBitmap(DC,
          Right + HorzScrollBar.Position + Offset,
          Bottom + VertScrollBar.Position + Offset);
    finally
      ReleaseDC(0, DC);
    end;
    MemDC := CreateCompatibleDC(0);
    OldBitmap := SelectObject(MemDC, MemBitmap);
    try
      SavedDC := SaveDC(MemDC);
      try
        SetMapMode(MemDC, MM_ANISOTROPIC);
        SetWindowExtEx(MemDC, 100, 100, nil);
        SetViewPortExtEx(MemDC, Zoom, Zoom, nil);
        Msg.DC := MemDC;
        try
          WMPaint(Msg);
        finally
          Msg.DC := 0;
        end;
      finally
        RestoreDC(MemDC, SavedDC);
      end;
      DC := BeginPaint(WindowHandle, PS);
      try
        BitBlt(DC, 0, 0, ClientRect.Right, ClientRect.Bottom, MemDC,
          HorzScrollBar.Position, VertScrollBar.Position, SRCCOPY);
      finally
        EndPaint(WindowHandle, PS);
      end;
    finally
      SelectObject(MemDC, OldBitmap);
      DeleteDC(MemDC);
      DeleteObject(MemBitmap);
    end;
  end;
end;

procedure TSimpleGraph.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TSimpleGraph.WMSize(var Msg: TWMSize);
begin
  UpdatingScrollBars := True;
  try
    CalcAutoRange;
  finally
    UpdatingScrollBars := False;
  end;
  if HorzScrollBar.Visible or VertScrollBar.Visible then
    UpdateScrollBars
  else
    CalcVisibleBounds;
end;

procedure TSimpleGraph.WMHScroll(var Msg: TWMHScroll);
begin
  if (Msg.ScrollBar = 0) and HorzScrollBar.Visible then
    HorzScrollBar.ScrollMessage(Msg)
  else
    inherited;
end;

procedure TSimpleGraph.WMVScroll(var Msg: TWMVScroll);
begin
  if (Msg.ScrollBar = 0) and VertScrollBar.Visible then
    VertScrollBar.ScrollMessage(Msg)
  else
    inherited;
end;

procedure TSimpleGraph.CNKeyDOwn(var Msg: TWMKeyDown);

  procedure MoveResize(Key: Integer; Node: TGraphNode);
  var
    Resize: Boolean;
    Step: Integer;
  begin
    if WordBool(GetKeyState(VK_CONTROL) and $8000) then
      Step := 1
    else
      Step := GridSize;
    Resize := WordBool(GetKeyState(VK_SHIFT) and $8000);
    case Key of
      VK_UP:
        if Resize then
          Node.Height := Node.Height - Step
        else
          Node.Top := Node.Top - Step;
      VK_DOWN:
        if Resize then
          Node.Height := Node.Height + Step
        else
          Node.Top := Node.Top + Step;
      VK_LEFT:
        if Resize then
          Node.Width := Node.Width - Step
        else
          Node.Left := Node.Left - Step;
      VK_RIGHT:
        if Resize then
          Node.Width := Node.Width + Step
        else
          Node.Left := Node.Left + Step;
    end;
  end;

  procedure LinkSelectedNodes;
  var
    I: Integer;
    TheNodes: TGraphObjectList;
  begin
    TheNodes := TGraphObjectList.Create;
    try
      for I := 0 to SelectedObjects.Count - 1 do
        if not SelectedObjects[I].IsLink then
          TheNodes.Add(SelectedObjects[I]);
      if TheNodes.Count > 1 then
        for I := 0 to TheNodes.Count - 2 do
          LinkNodes(TGraphNode(TheNodes[I]), TGraphNode(TheNodes[I+1]));
    finally
      TheNodes.Free;
    end;
  end;

var
  I: Integer;
  Handled: Boolean;
begin
  Handled := False;
  if DefaultKeyMap then
  begin
    if CommandMode <> cmViewOnly then
    begin
      case Msg.CharCode of
        VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN:
          if not LockNodes then
          begin
            for I := SelectedObjects.Count - 1 downto 0 do
              if not SelectedObjects[I].IsLink then
              begin
                MoveResize(Msg.CharCode, TGraphNode(SelectedObjects[I]));
                Handled := True;
              end;
          end;
        VK_DELETE:
          while SelectedObjects.Count > 0 do
          begin
            SelectedObjects.Last.Free;
            Handled := True;
          end;
        VK_RETURN:
          if SelectedObjects.Count > 0 then
          begin
            DoObjectDblClick(SelectedObjects[0]);
            Handled := True;
          end;
        VK_ESCAPE:
        begin
          State := gsNone;
          CommandMode := cmEdit;
          SelectedObjects.Clear;
          Handled := True;
        end;
        VK_INSERT:
        begin
          if WordBool(GetKeyState(VK_CONTROL) and $8000) then
            LinkSelectedNodes
          else
            InsertNode;
          Handled := True;
        end;
        VK_TAB:
        begin
          if WordBool(GetKeyState(VK_SHIFT) and $8000) then
            if WordBool(GetKeyState(VK_CONTROL) and $8000) then
              SelectNextObject(True, TGraphLink)
            else
              SelectNextObject(True, TGraphNode)
          else
            if (GetKeyState(VK_CONTROL) and $8000) <> 0 then
              SelectNextObject(False, TGraphLink)
            else
              SelectNextObject(False, TGraphNode);
          Handled := True;
        end;
        Ord('X'), Ord('x'):
          if (SelectedObjects.Count > 0) and WordBool(GetKeyState(VK_CONTROL) and $8000) then
          begin
            CopyToClipboard(True);
            while SelectedObjects.Count > 0 do
              SelectedObjects.Last.Free;
            Handled := True;
          end;
        Ord('C'), Ord('c'):
          if (SelectedObjects.Count > 0) and WordBool(GetKeyState(VK_CONTROL) and $8000) then
          begin
            CopyToClipboard(True);
            Handled := True;
          end;
        Ord('V'), Ord('v'):
          if (GetKeyState(VK_CONTROL) and $8000) <> 0 then
          begin
            PasteFromClipboard;
            Handled := True;
          end;
      end;
    end;
    case Msg.CharCode of
      VK_ADD:
      begin
        Zoom := Zoom + ZoomStep;
        Handled := True;
      end;
      VK_SUBTRACT:
      begin
        if Zoom > ZoomStep then
          Zoom := Zoom - ZoomStep
        else
          Zoom := ZoomMin;
        Handled := True;
      end;
    end;
  end;
  if not Handled then
    inherited;
end;

procedure TSimpleGraph.CMFontChanged(var Msg: TMessage);
var
  I: Integer;
begin
  inherited;
  for I := 0 to Objects.Count - 1 do
    with Objects[I] do if ParentFont then SyncFontToParent;
end;

procedure TSimpleGraph.CMBiDiModeChanged(var Msg: TMessage);
var
  Save: Integer;
begin
  Save := Msg.WParam;
  try
    { prevent inherited from calling Invalidate & RecreateWnd }
    if not (Self is TSimpleGraph) then Msg.wParam := 1;
    inherited;
  finally
    Msg.wParam := Save;
  end;
  if HandleAllocated then
  begin
    HorzScrollBar.ChangeBiDiPosition;
    UpdateScrollBars;
  end;
end;

procedure TSimpleGraph.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if (GetCapture <> WindowHandle) then
    Screen.Cursor := crDefault;
end;

procedure TSimpleGraph.WMMouseWheel(var Message: TMessage);
var
  IsNeg: Boolean;
  Rect: TRect;
  Pt: TPoint;
begin
  GetWindowRect(WindowHandle, Rect);
  Pt.X := LoWord(Message.LParam);
  Pt.Y := HiWord(Message.LParam);
  if PtInRect(Rect, Pt) then
  begin
    Message.Result := 1;
    Inc(WheelAccumulator, SmallInt(HiWord(Message.WParam)));
    while Abs(WheelAccumulator) >= WHEEL_DELTA do
    begin
      IsNeg := WheelAccumulator < 0;
      WheelAccumulator := Abs(WheelAccumulator) - WHEEL_DELTA;
      if IsNeg then
      begin
        WheelAccumulator := -WheelAccumulator;
        if Zoom > ZoomStep then
          Zoom := Zoom - ZoomStep
        else
          Zoom := ZoomMin;
      end
      else
        Zoom := Zoom + ZoomStep;
    end;
  end;
end;

procedure TSimpleGraph.CreateWnd;
begin
  inherited CreateWnd;
  if not SysLocale.MiddleEast then
    InitializeFlatSB(WindowHandle);
  UpdateScrollBars;
end;

procedure TSimpleGraph.Print(Canvas: TCanvas; const Rect: TRect);
var
  GraphRect: TRect;
  Metafile: TMetafile;
  RectSize, GraphSize: TPoint;
begin
  GraphRect := GraphBounds;
  if not IsRectEmpty(GraphRect) then
  begin
    GraphSize.X := GraphRect.Right - GraphRect.Left;
    GraphSize.Y := GraphRect.Bottom - GraphRect.Top;
    RectSize.X := Rect.Right - Rect.Left;
    RectSize.Y := Rect.Bottom - Rect.Top;
    if (RectSize.X / GraphSize.X) < (RectSize.Y / GraphSize.Y) then
    begin
      GraphSize.Y := MulDiv(GraphSize.Y, RectSize.X, GraphSize.X);
      GraphSize.X := RectSize.X;
    end
    else
    begin
      GraphSize.X := MulDiv(GraphSize.X, RectSize.Y, GraphSize.Y);
      GraphSize.Y := RectSize.Y;
    end;
    SetRect(GraphRect, 0, 0, GraphSize.X, GraphSize.Y);
    OffsetRect(GraphRect,
      Rect.Left + (RectSize.X - GraphSize.X) div 2,
      Rect.Top + (RectSize.Y - GraphSize.Y) div 2);
    Metafile := GetAsMetafile;
    try
      Canvas.StretchDraw(GraphRect, Metafile);
    finally
      Metafile.Free;
    end;
  end;
end;

procedure TSimpleGraph.Draw(Canvas: TCanvas);
var
  I: Integer;
begin
  for I := 0 to Objects.Count - 1 do
    with Objects[I] do if IsLink then Draw(Canvas);
  if Linking and ((State = gsMoveLink) or
    ((CommandMode = cmLinkNodes) and (FirstNodeOfLink <> nil))) then
  begin
    Canvas.Pen.Mode := pmNot;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style := psSolid;
    DefaultLinkClass.DrawDraft(Canvas,
      Rect(StartPoint.X, StartPoint.Y, StopPoint.X, StopPoint.Y));
  end;
  for I := 0 to Objects.Count - 1 do
    with Objects[I] do if not IsLink then Draw(Canvas);
  if Linking and (CommandMode = cmLinkNodes) and (FirstNodeOfLink <> nil) then
    FirstNodeOfLink.DrawMarkers(Canvas);
  if not HideSelection or Focused then
  begin
    for I := 0 to SelectedObjects.Count - 1 do
      SelectedObjects[I].DrawMarkers(Canvas);
  end;
  if (State = gsSelectRect) or (CommandMode = cmInsertNode) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Mode := pmNot;
    if CommandMode = cmInsertNode then
    begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Style := psInsideFrame;
      DefaultNodeClass.DrawDraft(Canvas, SelectionRect);
    end
    else
    begin
      Canvas.Pen.Width := 0;
      Canvas.Pen.Style := psDot;
      with SelectionRect do Canvas.Rectangle(Left, Top, Right, Bottom);
    end;
  end;
end;

procedure TSimpleGraph.DrawBackground(Canvas: TCanvas);
var
  DC: HDC;
  Rect: TRect;
  X, Y: Integer;
  DotColor: Integer;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Rect := Canvas.ClipRect;
  Canvas.FillRect(Rect);
  if ShowGrid then
  begin
    DotColor := ColorToRGB(GridColor);
    DC := Canvas.Handle;
    Y := 0;
    while Y < Rect.Bottom do
    begin
      X := 0;
      while X < Rect.Right do
      begin
        SetPixel(DC, X, Y, DotColor);
        Inc(X, GridSize);
      end;
      Inc(Y, GridSize);
    end;
  end;
end;

procedure TSimpleGraph.Paint;
begin
  Canvas.Lock;
  try
    DrawBackground(Canvas);
    Draw(Canvas);
    if csDesigning in ComponentState then
      with Canvas do
      begin
        Pen.Style := psDash;
        Brush.Style := bsClear;
        Rectangle(0, 0, Width, Height);
      end;
  finally
    Canvas.Unlock;
  end;
end;

procedure TSimpleGraph.ToggleNodesAt(const Rect: TRect; KeepOld: Boolean);
var
  GraphObject: TGraphObject;
  I: Integer;
  R: TRect;
begin
  if not KeepOld then
    SelectedObjects.Clear;
  for I := Objects.Count - 1 downto 0 do
  begin
    GraphObject := Objects[I];
    if not GraphObject.IsLink and
       IntersectRect(R, Rect, TGraphNode(GraphObject).BoundsRect)
    then
      GraphObject.Selected := not GraphObject.Selected;
  end;
end;

function TSimpleGraph.FindObjectMarkerAt(X, Y: Integer;
  var GraphObject: TGraphObject): TMarkerType;
var
  I: Integer;
  NearestObject: TGraphObject;
  NearestMarker: TMarkerType;
begin
  NearestObject := nil;
  NearestMarker := mtNone;
  for I := Objects.Count - 1 downto 0 do
  begin
    GraphObject := Objects[I];
    Result := GraphObject.FindMarkerAt(X, Y);
    if Result <> mtNone then
    begin
      if not (Result in [mtMove, mtSelect]) and GraphObject.Selected then
        Exit
      else if NearestObject = nil then
      begin
        NearestObject := GraphObject;
        NearestMarker := Result;
      end;
    end;
  end;
  GraphObject := NearestObject;
  Result := NearestMarker;
end;

function TSimpleGraph.FindObjectAt(X, Y: Integer;
  GraphObjectClass: TGraphObjectClass): TGraphObject;
var
  I: Integer;
  GraphObject: TGraphObject;
begin
  Result := nil;
  if GraphObjectClass = nil then
    GraphObjectClass := TGraphObject;
  for I := Objects.Count - 1 downto 0 do
  begin
    GraphObject := Objects[I];
    if GraphObject.ContainsPoint(X, Y) and (GraphObject is GraphObjectClass) then
    begin
      Result := GraphObject;
      Exit;
    end;
  end;
end;

procedure TSimpleGraph.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
begin
  Pt := ClientToGraph(X, Y);
  if not Focused then SetFocus;
  State := gsNone;
  if CommandMode = cmEdit then
  begin
    // Finds object under the cursor
    MarkerAtCursor := FindObjectMarkerAt(Pt.X, Pt.Y, ObjectAtCursor);
    // No Object; Initiates the selecteion rectangle
    if ObjectAtCursor = nil then
    begin
      if (Button <> mbLeft) or not (ssShift in Shift) then
        SelectedObjects.Clear;
      if (Button = mbLeft) and not (ssDouble in Shift) then
      begin
        StartPoint := Pt;
        State := gsSelectRect;
      end;
    end
    else // Object found
    begin
      // Selects object under the cursor
      if (Button = mbLeft) and (ssShift in Shift) then
        ObjectAtCursor.Selected := not ObjectAtCursor.Selected
      else if not (ssShift in Shift) and not ObjectAtCursor.Selected then
      begin
        SelectedObjects.Clear;
        ObjectAtCursor.Selected := True;
      end;
      // A node is under the cursor
      if not ObjectAtCursor.IsLink then
      begin
        if (Button = mbLeft) and not (ssDouble in Shift) then
        begin
          if SnapToGrid and not (ssCtrl in Shift) then
            StartPoint := Point(Pt.X div GridSize * GridSize, Pt.Y div GridSize * GridSize)
          else
            StartPoint := Pt;
          if not LockNodes then
          begin
            State := gsMoveResizeNode;
            if MarkerAtCursor = mtMove then
              Screen.Cursor := crHandGrab;
          end;
        end;
      end
      // A Link is under cursor
      else
      begin
        if (Button = mbLeft) and not (ssDouble in Shift) and
           (MarkerAtCursor in [mtMoveEndPt, mtMoveStrartPt]) then
        begin
          if MarkerAtCursor = mtMoveEndPt then
            StartPoint := TGraphLink(ObjectAtCursor).FromNode.Center
          else
            StartPoint := TGraphLink(ObjectAtCursor).ToNode.Center;
          StopPoint := Pt;
          State := gsMoveLink;
          Linking := True;
        end;
      end;
    end;
  end
  else if CommandMode = cmInsertNode then
  begin
    if (Button = mbLeft) and not (ssDouble in Shift) then
    begin
      if SnapToGrid and not (ssCtrl in Shift) then
        StartPoint := Point(Pt.X div GridSize * GridSize, Pt.Y div GridSize * GridSize)
      else
        StartPoint := Pt;
    end
    else
      CommandMode := cmEdit;
  end
  else if CommandMode = cmLinkNodes then
  begin
    FirstNodeOfLink := TGraphNode(FindObjectAt(Pt.X, Pt.Y, TGraphNode));
    if (Button = mbLeft) and not (ssDouble in Shift) and
       (FirstNodeOfLink <> nil) and CanLinkNodes(FirstNodeOfLink, nil) then
    begin
      FirstNodeOfLink.Dragging := True;
      StartPoint := FirstNodeOfLink.Center;
      StopPoint := Pt;
      Linking := True;
    end
    else
      CommandMode := cmEdit;
  end
  else
    inherited MouseDown(Button, Shift, X, Y);
end;

procedure TSimpleGraph.MouseMove(Shift: TShiftState; X, Y: Integer);
const
  FreezeTopMarkers  = [mtMove, mtSizeNW, mtSizeN, mtSizeNE];
  FreezeLeftMarkers = [mtMove, mtSizeNW, mtSizeW, mtSizeSW];
var
  I: Integer;
  Pt: TPoint;
  Delta: TPoint;
  CanLink: Boolean;
  NodeAtCursor: TGraphNode;
  LinkAtCursor: TGraphLink;
begin
  Pt := ClientToGraph(X, Y);
  if (Pt.X <> StartPoint.X) and (Pt.Y <> StartPoint.Y) then
  begin
    if State = gsMoveResizeNode then
    begin
      if SnapToGrid and not (ssCtrl in Shift) then
        StopPoint := Point(Pt.X div GridSize * GridSize, Pt.Y div GridSize * GridSize)
      else
        StopPoint := Pt;
      Delta := Point(StopPoint.X - StartPoint.X, StopPoint.Y - StartPoint.Y);
      StartPoint := StopPoint;
      if FreezeTopLeft then
        with SelectionBounds do
        begin
          if (Left + Delta.X < 0) and (MarkerAtCursor in FreezeLeftMarkers) then
            Delta.X := -Left;
          if (Top + Delta.Y < 0) and (MarkerAtCursor in FreezeTopMarkers) then
            Delta.Y := -Top;
        end;
      if (Delta.X <> 0) or (Delta.Y <> 0) then
        for I := SelectedObjects.Count - 1 downto 0 do
          if not SelectedObjects[I].IsLink then
            TGraphNode(SelectedObjects[I]).MoveMarkerBy(MarkerAtCursor, Delta);
    end
    else if State = gsSelectRect then
    begin
      StopPoint := Pt;
      SelectionRect := MakeRect(StartPoint, StopPoint);
      ScrollInView(StopPoint);
      Invalidate;
    end
    else if State = gsMoveLink then
    begin
      CanLink := False;
      NodeAtCursor := TGraphNode(FindObjectAt(Pt.X, Pt.Y, TGraphNode));
      if NodeAtCursor <> nil then
      begin
        LinkAtCursor := TGraphLink(ObjectAtCursor);
        case MarkerAtCursor of
          mtMoveStrartPt:
            if IsValidLink(LinkAtCursor, NodeAtCursor, LinkAtCursor.ToNode) then
              CanLink := CanLinkNodes(NodeAtCursor, LinkAtCursor.ToNode);
          mtMoveEndPt:
            if IsValidLink(LinkAtCursor, LinkAtCursor.FromNode, NodeAtCursor) then
              CanLink := CanLinkNodes(LinkAtCursor.FromNode, NodeAtCursor);
        end;
      end;
      StopPoint := Pt;
      SelectionRect := MakeRect(StartPoint, StopPoint);
      CalcAutoRange;
      Invalidate;
      if CanLink and (NodeAtCursor <> nil) then
        Screen.Cursor := crDrag
      else
        Screen.Cursor := crNoDrop;
    end
    else if CommandMode = cmInsertNode then
    begin
      Screen.Cursor := crXHair1;
      if (ssLeft in Shift) and not (ssDouble in Shift) then
      begin
        if SnapToGrid and not (ssCtrl in Shift) then
          StopPoint := Point(Pt.X div GridSize * GridSize, Pt.Y div GridSize * GridSize)
        else
          StopPoint := Pt;
        SelectionRect := MakeRect(StartPoint, StopPoint);
        CalcAutoRange;
        Invalidate;
      end;
    end
    else if CommandMode = cmLinkNodes then
    begin
      CanLink := False;
      NodeAtCursor := TGraphNode(FindObjectAt(Pt.X, Pt.Y, TGraphNode));
      if (NodeAtCursor <> nil) and not (ssDouble in Shift) then
      begin
        if not (ssLeft in Shift) then
          CanLink := CanLinkNodes(NodeAtCursor, nil)
        else if IsValidLink(nil, FirstNodeOfLink, NodeAtCursor) then
          CanLink := CanLinkNodes(FirstNodeOfLink, NodeAtCursor);
      end;
      if FirstNodeOfLink <> nil then
      begin
        StopPoint := Pt;
        SelectionRect := MakeRect(StartPoint, StopPoint);
        CalcAutoRange;
        Invalidate;
        if CanLink and (NodeAtCursor <> nil) then
          Screen.Cursor := DragCursor
        else if NodeAtCursor = FirstNodeOfLink then
          Screen.Cursor := DragCursor
        else
          Screen.Cursor := crNoDrop;
      end
      else if CanLink then
        Screen.Cursor := DragCursor
      else
        Screen.Cursor := crNoDrop;
    end
    else if ([ssLeft, ssRight, ssMiddle] * Shift) = [] then
    begin
      MarkerAtCursor := FindObjectMarkerAt(Pt.X, Pt.Y, ObjectAtCursor);
      if (ObjectAtCursor = nil) or (CommandMode = cmViewOnly) or
         (LockNodes and not ObjectAtCursor.IsLink)
      then
        Screen.Cursor := crDefault
      else
        Screen.Cursor := MarkerCursors[MarkerAtCursor];
      inherited MouseMove(Shift, X, Y);
    end
  end;
end;

procedure TSimpleGraph.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
  NodeAtCursor: TGraphNode;
  LinkAtCursor: TGraphLink;
begin
  Linking := False;
  Pt := ClientToGraph(X, Y);
  if CommandMode = cmEdit then
  begin
    if State = gsSelectRect then
      if not (ssAlt in Shift) then
        ToggleNodesAt(SelectionRect, ssShift in Shift)
      else
        ZoomRect(SelectionRect)
    else if State = gsMoveResizeNode then
    begin
      if MarkerAtCursor = mtMove then
        Screen.Cursor := crHandFlat;
    end
    else if State = gsMoveLink then
    begin
      NodeAtCursor := TGraphNode(FindObjectAt(Pt.X, Pt.Y, TGraphNode));
      if NodeAtCursor <> nil then
      begin
        LinkAtCursor := TGraphLink(ObjectAtCursor);
        case MarkerAtCursor of
          mtMoveStrartPt:
            if IsValidLink(LinkAtCursor, NodeAtCursor, LinkAtCursor.ToNode) and
               CanLinkNodes(NodeAtCursor, LinkAtCursor.ToNode)
            then
              LinkAtCursor.FromNode := NodeAtCursor;
          mtMoveEndPt:
            if IsValidLink(LinkAtCursor, LinkAtCursor.FromNode, NodeAtCursor) and
               CanLinkNodes(LinkAtCursor.FromNode, NodeAtCursor)
            then
              LinkAtCursor.ToNode := NodeAtCursor;
        end;
      end;
    end;
    State := gsNone;
    Screen.Cursor := MarkerCursors[MarkerAtCursor];
  end
  else if CommandMode = cmInsertNode then
  begin
    if (Button = mbLeft) and not (ssDouble in Shift) and
        not IsRectEmpty(SelectionRect)
    then
      InsertNode(@SelectionRect);
    CommandMode := cmEdit;
    if ssShift in Shift then
      CommandMode := cmInsertNode;
  end
  else if CommandMode = cmLinkNodes then
  begin
    NodeAtCursor := TGraphNode(FindObjectAt(Pt.X, Pt.Y, TGraphNode));
    if (NodeAtCursor <> nil) and CanLinkNodes(FirstNodeOfLink, NodeAtCursor) then
      LinkNodes(FirstNodeOfLink, NodeAtCursor);
    CommandMode := cmEdit;
    if ssShift in Shift then
      CommandMode := cmLinkNodes;
  end
  else
    inherited MouseUp(Button, Shift, X, Y);
end;

procedure TSimpleGraph.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  if SelectedObjects.Count > 0 then
  begin
    DoObjectContextPopup(SelectedObjects[0], MousePos, Handled);
    if not Handled and Assigned(ObjectPopupMenu) then
    begin
      with ClientToScreen(MousePos) do ObjectPopupMenu.Popup(X, Y);
      Handled := True;
    end;
  end;
  if not Handled then
    {$IFDEF DELPHI5_UP}
    inherited DoContextPopup(MousePos, Handled);
    {$ELSE}
    if Assigned(fOnContextPopup) then
      fOnContextPopup(Self, MousePos, Handled);
    {$ENDIF}
end;

procedure TSimpleGraph.DblClick;
begin
  if SelectedObjects.Count > 0 then
    DoObjectDblClick(SelectedObjects[0])
  else
    inherited DblClick;
end;

procedure TSimpleGraph.DoEnter;
begin
  inherited DoEnter;
  if HideSelection then
    Invalidate;
end;

procedure TSimpleGraph.DoExit;
begin
  inherited DoExit;
  if HideSelection then
    Invalidate;
end;

function TSimpleGraph.InsertNode(pBounds: PRect; ANodeClass: TGraphNodeClass): TGraphNode;
begin
  BeginUpdate;
  try
    SelectedObjects.Clear;
    if ANodeClass = nil then
      ANodeClass := DefaultNodeClass;
    Result := ANodeClass.Create(Self);
    if pBounds <> nil then
      Result.BoundsRect := pBounds^;
    Result.State := osNone;
    Result.Selected := True;
  finally
    EndUpdate;
  end;
end;

function TSimpleGraph.LinkNodes(FromNode, ToNode: TGraphNode;
  ALinkClass: TGraphLinkClass): TGraphLink;
begin
  Result := nil;
  if IsValidLink(nil, FromNode, ToNode) then
  begin
    BeginUpdate;
    try
      SelectedObjects.Clear;
      if ALinkClass = nil then
        ALinkClass := DefaultLinkClass;
      Result := ALinkClass.Create(Self);
      Result.FromNode := FromNode;
      Result.ToNode := ToNode;
      Result.State := osNone;
      Result.Selected := True;
    finally
      EndUpdate;
    end;
  end;
end;

function TSimpleGraph.IsValidLink(Link: TGraphLink; FromNode, ToNode: TGraphNode): Boolean;
begin
  Result := (FromNode <> nil) and (ToNode <> nil) and (FromNode <> ToNode) and
  ((FromNode.QueryLinkTo(ToNode) = qlrNone) or ((Link <> nil) and
   (Link.FromNode = FromNode) and (Link.ToNode = ToNode)));
end;

procedure TSimpleGraph.ScrollInView(GraphObject: TGraphObject);
begin
  if GraphObject <> nil then
    ScrollInView(GraphObject.BoundsRect);
end;

procedure TSimpleGraph.ScrollInView(const Rect: TRect);
begin
  ScrollInView(Rect.BottomRight);
  ScrollInView(Rect.TopLeft);
end;

procedure TSimpleGraph.ScrollInView(const Point: TPoint);
var
  X, Y: Integer;
begin
  X := MulDiv(Point.X, Zoom, 100);
  Y := MulDiv(Point.Y, Zoom, 100);
  with HorzScrollBar do
    if IsScrollBarVisible then
    begin
      if X < Position then
        Position := X
      else if X > Position + ClientWidth then
        Position := X - ClientWidth;
    end;
  with VertScrollBar do
    if IsScrollBarVisible then
    begin
      if Y < Position then
        Position := Y
      else if Y > Position + ClientHeight then
        Position := Y - ClientHeight;
    end;
end;

function TSimpleGraph.FindNextObject(StartIndex: Integer; Inclusive, Backward,
  Wrap: Boolean; GraphObjectClass: TGraphObjectClass): TGraphObject;
var
  I: Integer;
begin
  Result := nil;
  if GraphObjectClass = nil then
    GraphObjectClass := TGraphObject;
  if Backward then
  begin
    for I := StartIndex - Ord(not Inclusive) downto 0 do
      if Objects[I] is GraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if Wrap then
    begin
      for I := Objects.Count - 1 downto StartIndex + 1 do
        if Objects[I] is GraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end
  else
  begin
    for I := StartIndex + Ord(not Inclusive) to Objects.Count - 1 do
      if Objects[I] is GraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if Wrap then
    begin
      for I := 0 to StartIndex - 1 do
        if Objects[I] is GraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end;
end;

function TSimpleGraph.SelectNextObject(Backward: Boolean;
  GraphObjectClass: TGraphObjectClass): Boolean;
var
  Index, I: Integer;
  GraphObject: TGraphObject;
begin
  Result := False;
  if GraphObjectClass = nil then
    GraphObjectClass := TGraphObject;
  if Objects.Count > 0 then
  begin
    Index := -1;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is GraphObjectClass then
      begin
        Index := SelectedObjects[I].ZOrder;
        Break;
      end;
    GraphObject := FindNextObject(Index, False, Backward, True, GraphObjectClass);
    if (GraphObject = nil) and (Index >= 0) then
      GraphObject := Objects[Index];
    SelectedObjects.Clear;
    if GraphObject <> nil then
    begin
      GraphObject.Selected := True;
      ScrollInView(GraphObject);
      Result := True;
    end;
  end;
end;

function TSimpleGraph.ObjectsCount(GraphObjectClass: TGraphObjectClass): Integer;
var
  I: Integer;
begin
  if GraphObjectClass = nil then
    Result := Objects.Count
  else
  begin
    Result := 0;
    for I := 0 to Objects.Count - 1 do
      if Objects[I] is GraphObjectClass then
        Inc(Result);
  end;
end;

function TSimpleGraph.SelectedObjectsCount(GraphObjectClass: TGraphObjectClass): Integer;
var
  I: Integer;
begin
  if GraphObjectClass = nil then
    Result := SelectedObjects.Count
  else
  begin
    Result := 0;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is GraphObjectClass then
        Inc(Result);
  end;
end;

procedure TSimpleGraph.BeginUpdate;
begin
  Inc(UpdateCount);
end;

procedure TSimpleGraph.EndUpdate;
begin
  Dec(UpdateCount);
  if UpdateCount = 0 then
    ObjectChanged(nil, GraphModified);
end;

procedure TSimpleGraph.Invalidate;
begin
  if (WindowHandle <> 0) and (UpdateCount = 0) then
    InvalidateRect(WindowHandle, nil, False);
end;

function TSimpleGraph.FindObjectByID(ID: DWORD;
  GraphObjectClass: TGraphObjectClass): TGraphObject;
var
  I: Integer;
begin
  Result := nil;
  for I := Objects.Count - 1 downto 0 do
    if (Objects[I].ID = ID) and (Objects[I] is GraphObjectClass) then
    begin
      Result := Objects[I];
      Exit;
    end;
end;

function TSimpleGraph.FindObjectByOldID(StartIndex: Integer; OldID: DWORD;
  GraphObjectClass: TGraphObjectClass): TGraphObject;
var
  I: Integer;
begin
  Result := nil;
  for I := Objects.Count - 1 downto StartIndex do
    if (Objects[I].OldID = OldID) and (Objects[I] is GraphObjectClass) then
    begin
      Result := Objects[I];
      Exit;
    end;
end;

procedure TSimpleGraph.Clear;
begin
  if Objects.Count > 0 then
  begin
    BeginUpdate;
    IgnoreNotification := True;
    try
      Objects.Clear;
      SelectedObjects.Clear;
      State := gsNone;
      CommandMode := cmEdit;
    finally
      IgnoreNotification := False;
      EndUpdate;
    end;
  end;
  Modified := False;
end;

function TSimpleGraph.GetUniqueID(PreferredID: DWORD): DWORD;
var
  I: Integer;
  IsUnique: Boolean;
  CandidateID: DWORD;
begin
  CandidateID := PreferredID;
  repeat
    IsUnique := True;
    for I := Objects.Count - 1 downto 0 do
      if Objects[I].ID = CandidateID then
      begin
        IsUnique := False;
        Inc(CandidateID);
        Break;
      end;
  until IsUnique;
  Result := CandidateID;
end;

function TSimpleGraph.ReadGraphObject(Stream: TStream): TGraphObject;
var
  ClassName: array[0..255] of Char;
  ClassNameLen: Integer;
begin
  Stream.Read(ClassNameLen, SizeOf(ClassNameLen));
  Stream.Read(ClassName, ClassNameLen);
  Result := TGraphObjectClass(FindClass(ClassName)).Create(Self);
  Result.LoadFromStream(Stream);
end;

procedure TSimpleGraph.WriteGraphObject(Stream: TStream; GraphObject: TGraphObject);
var
  ClassName: array[0..255] of Char;
  ClassNameLen: Integer;
begin
  ClassNameLen := Length(GraphObject.ClassName) + 1;
  Stream.Write(ClassNameLen, SizeOf(ClassNameLen));
  StrPCopy(ClassName, GraphObject.ClassName);
  Stream.Write(ClassName, ClassNameLen);
  GraphObject.SaveToStream(Stream);
end;

procedure TSimpleGraph.ReadObjects(Stream: TStream);
var
  OldObjectCount: Integer;
  ObjectCount: Integer;
  I: Integer;
begin
  BeginUpdate;
  IgnoreNotification := True;
  try
    OldObjectCount := Objects.Count;
    Stream.Read(ObjectCount, SizeOf(ObjectCount));
    if ObjectCount > 0 then
    begin
      Objects.Capacity := OldObjectCount + ObjectCount;
      for I := 0 to ObjectCount - 1 do
        ReadGraphObject(Stream);
      for I := Objects.Count - 1 downto OldObjectCount do
        Objects[I].LocateLinkedObjects(OldObjectCount);
      for I := Objects.Count - 1 downto OldObjectCount do
        if Objects[I].VerifyLinkedObjects then
          Objects[I].OldID := 0
        else
          Objects[I].Free;
    end;
  finally
    IgnoreNotification := False;
    EndUpdate;
  end;
end;

procedure TSimpleGraph.WriteObjects(Stream: TStream; SelectedOnly: Boolean);
var
  ObjectList: TGraphObjectList;
  ObjectCount: Integer;
  I: Integer;
begin
  if SelectedOnly then
    ObjectList := SelectedObjects
  else
    ObjectList := Objects;
  ObjectCount := ObjectList.Count;
  Stream.Write(ObjectCount, SizeOf(ObjectCount));
  for I := 0 to ObjectList.Count - 1 do
    WriteGraphObject(Stream, ObjectList[I]);
end;

function TSimpleGraph.GetAsMetafile: TMetafile;
var
  I: Integer;
  GraphRect: TRect;
  MetaCanvas: TMetafileCanvas;
begin
  GraphRect := GraphBounds;
  Result := TMetafile.Create;
  Result.Width := GraphRect.Right - GraphRect.Left;
  Result.Height := GraphRect.Bottom - GraphRect.Top;
  MetaCanvas := TMetafileCanvas.Create(Result, 0);
  try
    SetViewportOrgEx(MetaCanvas.Handle, -GraphRect.Left, -GraphRect.Top, nil);
    for I := 0 to Objects.Count - 1 do
      with Objects[I] do if IsLink then Draw(MetaCanvas);
    for I := 0 to Objects.Count - 1 do
      with Objects[I] do if not IsLink then Draw(MetaCanvas);
  finally
    MetaCanvas.Free;
  end;
end;

procedure TSimpleGraph.SaveAsMetafile(const Filename: String);
var
  Metafile: TMetafile;
begin
  Metafile := GetAsMetafile;
  try
    Metafile.SaveToFile(Filename);
  finally
    Metafile.Free;
  end;
end;

procedure TSimpleGraph.LoadFromStream(Stream: TStream);
var
  Signature: DWORD;
begin
  BeginUpdate;
  try
    Clear;
    Stream.Read(Signature, SizeOf(Signature));
    if Signature = StreamSignature then
      ReadObjects(Stream)
    else
      raise EGraphStreamError.Create('Invalid stream content');
  finally
    EndUpdate;
    Modified := False;
  end;
end;

procedure TSimpleGraph.SaveToStream(Stream: TStream);
begin
  Stream.Write(StreamSignature, SizeOf(StreamSignature));
  WriteObjects(Stream, False);
  Modified := False;
end;

procedure TSimpleGraph.LoadFromFile(const Filename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSimpleGraph.SaveToFile(const Filename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmCreate or fmShareExclusive);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSimpleGraph.CopyToClipboard(Selection: Boolean);
var
  Stream: TMemoryHandleStream;
begin
  Stream := TMemoryHandleStream.Create(0);
  try
    WriteObjects(Stream, Selection);
    Clipboard.Clear;
    Clipboard.SetAsHandle(CF_SIMPLEGRAPH, Stream.Handle);
  finally
    Stream.Free;
  end;
end;

function TSimpleGraph.PasteFromClipboard: Boolean;
var
  Stream: TMemoryHandleStream;
  I, Count: Integer;
begin
  Result := False;
  if Clipboard.HasFormat(CF_SIMPLEGRAPH) then
  begin
    Clipboard.Open;
    BeginUpdate;
    try
      Stream := TMemoryHandleStream.Create(Clipboard.GetAsHandle(CF_SIMPLEGRAPH));
      try
        SelectedObjects.Clear;
        Count := Objects.Count;
        ReadObjects(Stream);
        SelectedObjects.Capacity := Objects.Count - Count;
        for I := Objects.Count - 1 downto Count do
          Objects[I].Selected := True;
        Result := True;
      finally
        Stream.Free;
      end;
    finally
      EndUpdate;
      Clipboard.Close;
    end;
  end;
end;

function TSimpleGraph.GetGraphBounds(Mode: Integer): TRect;
var
  I: Integer;
  AnyFound: Boolean;
  GraphObject: TGraphObject;
begin
  AnyFound := False;
  FillChar(Result, SizeOf(TRect), 0);
  for I := 0 to Objects.Count - 1 do
  begin
    GraphObject := Objects[I];
    if GraphObject.Visible and ((Mode = 0) or GraphObject.Selected) then
    begin
      if AnyFound then
        with GraphObject.BoundsRect do
        begin
          if Result.Left > Left then
            Result.Left := Left;
          if Result.Top > Top then
            Result.Top := Top;
          if Result.Right < Right then
            Result.Right := Right;
          if Result.Bottom < Bottom then
            Result.Bottom := Bottom;
        end
      else
      begin
        AnyFound := True;
        Result := GraphObject.BoundsRect;
      end
    end;
  end;
end;

procedure TSimpleGraph.SetGridSize(Value: TGridSize);
begin
  if (GridSize <> Value) and
     (Value in [Low(TGridSize).. High(TGridSize)]) then
  begin
    fGridSize := Value;
    if ShowGrid then Invalidate;
  end;
end;

procedure TSimpleGraph.SetGridColor(Value: TColor);
begin
  if GridColor <> Value then
  begin
    fGridColor := Value;
    if ShowGrid then Invalidate;
  end;
end;

procedure TSimpleGraph.SetShowGrid(Value: Boolean);
begin
  if ShowGrid <> Value then
  begin
    fShowGrid := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetShowHiddenObjects(Value: Boolean);
begin
  if ShowHiddenObjects <> Value then
  begin
    fShowHiddenObjects := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetHideSelection(Value: Boolean);
begin
  if HideSelection <> Value then
  begin
    fHideSelection := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetLockNodes(Value: Boolean);
begin
  if LockNodes <> Value then
  begin
    fLockNodes := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetMarkerColor(Value: TColor);
begin
  if MarkerColor <> Value then
  begin
    fMarkerColor := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetMarkerSize(Value: TMarkerSize);
begin
  if MarkerSize <> Value then
  begin
    fMarkerSize := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetZoom(Value: TZoom);
begin
  if Value < ZoomMin then
    Value := ZoomMin
  else if Value > ZoomMax then
    Value := ZoomMax;
  if Zoom <> Value then
  begin
    fZoom := Value;
    CalcAutoRange;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetZoomMin(Value: TZoom);
begin
  if Value < Low(Zoom) then
    Value := Low(Zoom)
  else if Value > High(Zoom) then
    Value := High(Zoom);
  if ZoomMin <> Value then
  begin
    fZoomMin := Value;
    SetZoom(Zoom);
  end;
end;

procedure TSimpleGraph.SetZoomMax(Value: TZoom);
begin
  if Value < Low(Zoom) then
    Value := Low(Zoom)
  else if Value > High(Zoom) then
    Value := High(Zoom);
  if ZoomMax <> Value then
  begin
    fZoomMax := Value;
    SetZoom(Zoom);
  end;
end;

procedure TSimpleGraph.SetState(Value: TGraphMouseState);
var
  I: Integer;
begin
  if State <> Value then
  begin
    if State = gsSelectRect then
      Invalidate
    else if State = gsMoveResizeNode then
    begin
      for I := 0 to Objects.Count - 1 do
        Objects[I].Dragging := False
    end
    else if State = gsMoveLink then
    begin
      for I := 0 to Objects.Count - 1 do
        Objects[I].Dragging := False;
      Invalidate;
    end;
    fState := Value;
    if State = gsMoveResizeNode then
    begin
      for I := 0 to SelectedObjects.Count - 1 do
        if not SelectedObjects[I].IsLink then
          SelectedObjects[I].Dragging := True;
    end
    else if State = gsMoveLink then
    begin
      for I := SelectedObjects.Count - 1 downto 0 do
        if SelectedObjects[I] = ObjectAtCursor then
          SelectedObjects[I].Dragging := True
        else
          SelectedObjects[I].Selected := False;
    end;
    SetRect(SelectionRect, -1, -1, -1, -1);
    CalcAutoRange;
  end;
end;

procedure TSimpleGraph.SetCommandMode(Value: TGraphCommandMode);
begin
  if CommandMode <> Value then
  begin
    if CommandMode in [cmInsertNode, cmLinkNodes] then
    begin
      if not UpdateCount = 0 then
        Invalidate;
      SetRect(SelectionRect, -1, -1, -1, -1);
      if FirstNodeOfLink <> nil then
      begin
        FirstNodeOfLink.Dragging := False;
        FirstNodeOfLink := nil;
      end;
    end;
    fCommandMode := Value;
    if CommandMode = cmViewOnly then
      SelectedObjects.Clear;
    CalcAutoRange;
    if CommandMode in [cmViewOnly, cmEdit] then
      Screen.Cursor := Cursor;
    DoCommandModeChange;
  end;
end;

procedure TSimpleGraph.SetHorzScrollBar(Value: TGraphScrollBar);
begin
  HorzScrollBar.Assign(Value);
end;

procedure TSimpleGraph.SetVertScrollBar(Value: TGraphScrollBar);
begin
  VertScrollBar.Assign(Value);
end;

procedure TSimpleGraph.UpdateScrollBars;
begin
  if not UpdatingScrollBars and HandleAllocated then
  begin
    try
      UpdatingScrollBars := True;
      if VertScrollBar.NeedsScrollBarVisible then
      begin
        HorzScrollBar.Update(False, True);
        VertScrollBar.Update(True, False);
      end
      else if HorzScrollBar.NeedsScrollBarVisible then
      begin
        VertScrollBar.Update(False, True);
        HorzScrollBar.Update(True, False);
      end
      else
      begin
        VertScrollBar.Update(False, False);
        HorzScrollBar.Update(True, False);
      end;
    finally
      UpdatingScrollBars := False;
    end;
    CalcVisibleBounds;
  end;
end;

procedure TSimpleGraph.CalcAutoRange;
begin
  HorzScrollBar.CalcAutoRange;
  VertScrollBar.CalcAutoRange;
end;

procedure TSimpleGraph.CalcVisibleBounds;
begin
  with ClientRect do
  begin
    fVisibleBounds.TopLeft := ClientToGraph(Left, Top);
    fVisibleBounds.BottomRight := ClientToGraph(Right, Bottom);
  end;
end;

procedure TSimpleGraph.ObjectChanged(GraphObject: TGraphObject; DataModified: Boolean);
begin
  GraphModified := GraphModified or DataModified;
  if (UpdateCount = 0) and not (csDestroying in ComponentState) then
  begin
    if GraphModified then
    begin
      GraphModified := False;
      Modified := True;
      CalcAutoRange;
      DoGraphChange;
    end;
    Invalidate;
  end;
end;

function TSimpleGraph.ChangeObjectClass(GraphObject: TGraphObject;
  AnotherClass: TGraphObjectClass): Boolean;
var
  NewObject: TGraphObject;
  I: Integer;
begin
  BeginUpdate;
  try
    Result := False;
    NewObject := AnotherClass.Create(Self);
    if not (NewObject.IsLink xor GraphObject.IsLink) then
    begin
      NewObject.Assign(GraphObject);
      Objects.Replace(GraphObject, NewObject);
      SelectedObjects.Replace(GraphObject, NewObject);
      NewObject.State := osNone;
      for I := Objects.Count - 1 downto 0 do
        Objects[I].ChangeLinkedObject(GraphObject, NewObject);
      Result := NewObject.VerifyLinkedObjects;
    end;
    if not Result then
      NewObject.Free
    else
    begin
      GraphObject.Free;
      ObjectChanged(NewObject, True);
    end;
  finally
    EndUpdate;
  end;
end;

function TSimpleGraph.VerifyNodeMoveResize(Node: TGraphNode;
  var aLeft, aTop, aWidth, aHeight: Integer;
  var CanMove, CanResize: Boolean): Boolean;
begin
  CanMove := True;
  CanResize := True;
  if aWidth < MinNodeSize then aWidth := MinNodeSize;
  if aHeight < MinNodeSize then aHeight := MinNodeSize;
  DoCanMoveResizeNode(Node, aLeft, aTop, aWidth, aHeight, CanMove, CanResize);
  Result := CanMove or CanResize;
end;

procedure TSimpleGraph.ObjectListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
var
  I: Integer;
begin
  if csDestroying in ComponentState then
    Exit;
  case Action of
    glAdded:
      if GraphObject.Owner = Self then
      begin
        ObjectChanged(GraphObject, True);
        DoObjectInsert(GraphObject);
      end
      else
        TGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        GraphObject.Selected := False;
        DoObjectRemove(GraphObject);
        ObjectChanged(GraphObject, True);
        if GraphObject.State <> osDestroying then
          GraphObject.Free;
        for I := Objects.Count - 1 downto 0 do
          if Objects[I] <> GraphObject then
            with Objects[I] do
              if (State <> osDestroying) and not VerifyLinkedObjects then
              begin
                Free;
                Break;
              end;
      end;
    glReordered:
      ObjectChanged(GraphObject, True);
  end;
end;

procedure TSimpleGraph.SelectionListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
begin
  if csDestroying in ComponentState then
    Exit;
  case Action of
    glAdded:
      if GraphObject.Owner = Self then
      begin
        GraphObject.Selected := True;
        ObjectChanged(GraphObject, False);
        DoObjectSelect(GraphObject);
      end
      else
        TGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        GraphObject.Selected := False;
        ObjectChanged(GraphObject, False);
        DoObjectSelect(GraphObject);
      end;
  end;
end;

procedure TSimpleGraph.DoCommandModeChange;
begin
  if not (csDestroying in ComponentState) and Assigned(fOnCommandModeChange) then
    fOnCommandModeChange(Self);
end;

procedure TSimpleGraph.DoGraphChange;
begin
  if Assigned(fOnGraphChange) then
    fOnGraphChange(Self);
end;

procedure TSimpleGraph.DoObjectDblClick(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectDblClick) then
    fOnObjectDblClick(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectInsert(GraphObject: TGraphObject);
begin
  if not IgnoreNotification and Assigned(fOnObjectInsert) then
    fOnObjectInsert(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectRemove(GraphObject: TGraphObject);
begin
  if not IgnoreNotification and Assigned(fOnObjectRemove) then
    fOnObjectRemove(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectSelect(GraphObject: TGraphObject);
begin
  if not IgnoreNotification and Assigned(fOnObjectSelect) then
    fOnObjectSelect(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectContextPopup(GraphObject: TGraphObject;
  const MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(fOnObjectContextPopup) then
    fOnObjectContextPopup(Self, GraphObject, MousePos, Handled);
end;

procedure TSimpleGraph.DoCanMoveResizeNode(Node: TGraphNode; var aLeft,
  aTop, aWidth, aHeight: Integer; var CanMove, CanResize: Boolean);
begin
  if FreezeTopLeft then
  begin
    if aLeft < 0 then aLeft := 0;
    if aTop < 0 then aTop := 0;
  end;
  if Assigned(fOnCanMoveResizeNode) then
    fOnCanMoveResizeNode(Self, Node, aLeft, aTop, aWidth, aHeight, CanMove, CanResize);
end;

function TSimpleGraph.CanLinkNodes(FromNode, ToNode: TGraphNode): Boolean;
begin
  Result := True;
  if Assigned(fOnCanLinkNodes) then
    fOnCanLinkNodes(Self, FromNode, ToNode, Result);
end;

function TSimpleGraph.ClientToGraph(X, Y: Integer): TPoint;
begin
  Result.X := MulDiv(X + HorzScrollBar.Position, 100, Zoom);
  Result.Y := MulDiv(Y + VertScrollBar.Position, 100, Zoom);
end;

function TSimpleGraph.GraphToClient(X, Y: Integer): TPoint;
begin
  Result.X := MulDiv(X, Zoom, 100) - HorzScrollBar.Position;
  Result.Y := MulDiv(Y, Zoom, 100) - VertScrollBar.Position;
end;

function TSimpleGraph.ZoomRect(const Rect: TRect): Boolean;
var
  HZoom, VZoom: Integer;
  CRect: TRect;
begin
  CRect := ClientRect;
  if not VertScrollBar.IsScrollBarVisible then
    Dec(CRect.Right, GetSystemMetrics(SM_CXVSCROLL));
  if not HorzScrollBar.IsScrollBarVisible then
    Dec(CRect.Bottom, GetSystemMetrics(SM_CYHSCROLL));
  HZoom := MulDiv(100, CRect.Right - CRect.Left, Rect.Right - Rect.Left);
  VZoom := MulDiv(100, CRect.Bottom - CRect.Top, Rect.Bottom - Rect.Top);
  if HZoom < VZoom then
    Zoom := HZoom
  else
    Zoom := VZoom;
  ScrollInView(Rect);
  Result := (Zoom = HZoom) or (Zoom = VZoom);
end;

function TSimpleGraph.ZoomObject(GraphObject: TGraphObject): Boolean;
begin
  if GraphObject <> nil then
    Result := ZoomRect(GraphObject.BoundsRect)
  else
    Result := False;
end;

function TSimpleGraph.ZoomSelection: Boolean;
begin
  if SelectedObjects.Count > 0 then
    Result := ZoomRect(SelectionBounds)
  else
    Result := False;
end;

function TSimpleGraph.ZoomGraph: Boolean;
begin
  if Objects.Count > 0 then
    Result := ZoomRect(GraphBounds)
  else
    Result := False;
end;

class procedure TSimpleGraph.Register(ANodeClass: TGraphNodeClass);
begin
  if RegisteredNodeClasses = nil then
    RegisteredNodeClasses := TList.Create;
  if RegisteredNodeClasses.IndexOf(ANodeClass) < 0 then
  begin
    RegisteredNodeClasses.Add(ANodeClass);
    RegisterClass(ANodeClass);
  end;
end;

class procedure TSimpleGraph.Unregister(ANodeClass: TGraphNodeClass);
begin
  if RegisteredNodeClasses <> nil then
  begin
    UnregisterClass(ANodeClass);
    RegisteredNodeClasses.Remove(ANodeClass);
    if RegisteredNodeClasses.Count = 0 then
    begin
      RegisteredNodeClasses.Free;
      RegisteredNodeClasses := nil;
    end;
  end;
end;

class function TSimpleGraph.NodeClassCount: Integer;
begin
  if RegisteredNodeClasses <> nil then
    Result := RegisteredNodeClasses.Count
  else
    Result := 0;
end;

class function TSimpleGraph.NodeClasses(Index: Integer): TGraphNodeClass;
begin
  Result := TGraphNodeClass(RegisteredNodeClasses[Index]);
end;

class procedure TSimpleGraph.Register(ALinkClass: TGraphLinkClass);
begin
  if RegisteredLinkClasses = nil then
    RegisteredLinkClasses := TList.Create;
  if RegisteredLinkClasses.IndexOf(ALinkClass) < 0 then
  begin
    RegisteredLinkClasses.Add(ALinkClass);
    RegisterClass(ALinkClass);
  end;
end;

class procedure TSimpleGraph.Unregister(ALinkClass: TGraphLinkClass);
begin
  if RegisteredLinkClasses <> nil then
  begin
    UnregisterClass(ALinkClass);
    RegisteredLinkClasses.Remove(ALinkClass);
    if RegisteredLinkClasses.Count = 0 then
    begin
      RegisteredLinkClasses.Free;
      RegisteredLinkClasses := nil;
    end;
  end;
end;

class function TSimpleGraph.LinkClassCount: Integer;
begin
  if RegisteredLinkClasses <> nil then
    Result := RegisteredLinkClasses.Count
  else
    Result := 0;
end;

class function TSimpleGraph.LinkClasses(Index: Integer): TGraphLinkClass;
begin
  Result := TGraphLinkClass(RegisteredLinkClasses[Index]);
end;

procedure Register;
begin
  RegisterComponents('Delphi Area', [TSimpleGraph]);
end;

initialization
  // Loads Custom Cursors
  Screen.Cursors[crHandFlat] := LoadCursor(HInstance, 'SG_HANDFLAT');
  Screen.Cursors[crHandGrab] := LoadCursor(HInstance, 'SG_HANDGRAB');
  Screen.Cursors[crHandPnt] := LoadCursor(HInstance, 'SG_HANDPNT');
  Screen.Cursors[crXHair1] := LoadCursor(HInstance, 'SG_XHAIR1');
  Screen.Cursors[crXHair2] := LoadCursor(HInstance, 'SG_XHAIR2');
  // Registers Clipboard Format
  CF_SIMPLEGRAPH := RegisterClipboardFormat('Simple Graph Format');
  // Registers Link and Node classes
  TSimpleGraph.Register(TGraphLink);
  TSimpleGraph.Register(TRectangularNode);
  TSimpleGraph.Register(TRoundRectangularNode);
  TSimpleGraph.Register(TEllipticNode);
  TSimpleGraph.Register(TTriangularNode);
  TSimpleGraph.Register(TRhomboidalNode);
  TSimpleGraph.Register(TPentagonalNode);
finalization
  // Unregisters Link and Node classes
  TSimpleGraph.Unregister(TPentagonalNode);
  TSimpleGraph.Unregister(TRhomboidalNode);
  TSimpleGraph.Unregister(TTriangularNode);
  TSimpleGraph.Unregister(TEllipticNode);
  TSimpleGraph.Unregister(TRoundRectangularNode);
  TSimpleGraph.Unregister(TRectangularNode);
  TSimpleGraph.Unregister(TGraphLink);
end.
