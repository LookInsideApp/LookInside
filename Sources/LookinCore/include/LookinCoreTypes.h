#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LookinCoreTypes.h
//  Lookin
//
//  The enums of the LookinCore model classes, moved verbatim out of the class
//  headers when those classes became plain Swift. Their raw values travel on
//  the wire and inside .lookin archives: never renumber a case.
//

#import <Foundation/Foundation.h>

// From LookinDisplayItem.h.

typedef NS_ENUM(NSUInteger, LookinDisplayItemImageEncodeType) {
    LookinDisplayItemImageEncodeTypeNone,   // 不进行 encode
    LookinDisplayItemImageEncodeTypeNSData, // 转换为 NSData
    LookinDisplayItemImageEncodeTypeImage   // 使用 NSImage / UIImage 自身的 encode 方法
};

typedef NS_ENUM(NSUInteger, LookinDoNotFetchScreenshotReason) {
    // 可以同步截图
    LookinFetchScreenshotPermitted,
    // layer 尺寸过大
    LookinDoNotFetchScreenshotForTooLarge,
    // 被 LookinServer 的用户配置拒绝
    LookinDoNotFetchScreenshotForUserConfig,
    // 节点本身没有像素（layout guide 等）——不发截图任务，但照常进预览画线框
    LookinDoNotFetchScreenshotForNoPixels
};

typedef NS_ENUM(NSUInteger, LookinDisplayItemProperty) {
    // 当初次设置 delegate 对象时，会立即以该值触发一次 displayItem:propertyDidChange:
    LookinDisplayItemProperty_None,
    LookinDisplayItemProperty_FrameToRoot,
    LookinDisplayItemProperty_DisplayingInHierarchy,
    LookinDisplayItemProperty_InHiddenHierarchy,
    LookinDisplayItemProperty_IsExpandable,
    LookinDisplayItemProperty_IsExpanded,
    LookinDisplayItemProperty_SoloScreenshot,
    LookinDisplayItemProperty_GroupScreenshot,
    LookinDisplayItemProperty_IsSelected,
    LookinDisplayItemProperty_IsHovered,
    LookinDisplayItemProperty_AvoidSyncScreenshot,
    LookinDisplayItemProperty_InNoPreviewHierarchy,
    LookinDisplayItemProperty_IsInSearch,
    LookinDisplayItemProperty_HighlightedSearchString,
};

/// What a hierarchy node *is*. Append-only: the integers travel on the wire
/// and inside .lookin archives, so existing cases must never be renumbered.
typedef NS_ENUM(NSInteger, LookinDisplayItemNodeKind) {
    /// Data produced before this field existed (old servers, old archives).
    /// Consumers must read resolvedNodeKind, which derives the kind from the
    /// legacy object slots in this case.
    LookinDisplayItemNodeKindUnspecified = 0,
    LookinDisplayItemNodeKindLayer       = 1,
    LookinDisplayItemNodeKindView        = 2,
    LookinDisplayItemNodeKindWindow      = 3,
    LookinDisplayItemNodeKindWindowScene = 4,
    /// A customInfo node (including SwiftUI virtual nodes — those are told
    /// apart by customInfo.isSwiftUI, not by a separate kind).
    LookinDisplayItemNodeKindCustom      = 5,
    LookinDisplayItemNodeKindLayoutGuide = 6,
    /// AppKit-only: an NSControl's cell as a child node of the control
    /// (cell-node proposal). Wireframe preview, attributes read from the cell.
    LookinDisplayItemNodeKindCell        = 7,
    /// UIKit-only: the outermost layer of a view whose backing layer UIKit
    /// wrapped in an intermediate one (_UIMultiLayer, iOS 26+). The geometry and
    /// the group-compositing rules moved onto it while the contents stayed on
    /// the view's own backing layer, so it has no pixels of its own — no
    /// screenshot is ever fetched for it — but it still gets a preview plane of
    /// its own, parallel to the view it wraps, like any other child node
    /// (node-pixel-ownership proposal).
    LookinDisplayItemNodeKindViewOuterLayer = 8,
    /// A view's backing layer, emitted as a child of that view's node when the
    /// show-backing-layers toggle is on (backing-layer-toggle proposal). An
    /// ordinary pixel-bearing node: with the toggle on, content shows on the
    /// layer that really renders it, and the view nodes above render as
    /// wireframes. Never emitted while the toggle is off.
    LookinDisplayItemNodeKindBackingLayer = 9,
};

// From LookinAppInfo.h.

/// 设备类型。该枚举的原始值会经由 wire 协议传给 Lookin 客户端，因此顺序不可调整，
/// 新增的档位只能追加在末尾。上游 Lookin 只认识前三档（0–2），收到更大的值时会落到
/// 自己的 default 分支（表现为设备图标缺失，而非报错）。
typedef NS_ENUM(NSInteger, LookinAppInfoDevice) {
    LookinAppInfoDeviceSimulator,   // 0，模拟器
    LookinAppInfoDeviceIPad,    // 1，iPad 真机
    LookinAppInfoDeviceOthers,   // 2，应该视为 iPhone 真机
    LookinAppInfoDeviceMac, // 3，使用AppKit的Mac应用（非 Catalyst）
    LookinAppInfoDeviceMacCatalyst, // 4，Mac Catalyst 应用：跑在 Mac 上，但界面是 UIKit
};

// From LookinAutoLayoutConstraint.h.

typedef NS_ENUM(NSInteger, LookinConstraintItemType) {
    LookinConstraintItemTypeUnknown,
    LookinConstraintItemTypeNil,
    LookinConstraintItemTypeView,
    LookinConstraintItemTypeSelf,
    LookinConstraintItemTypeSuper,
    LookinConstraintItemTypeLayoutGuide
};

typedef NS_ENUM(NSInteger, LookinConstraintEndpoint) {
    LookinConstraintEndpointFirst = 0,
    LookinConstraintEndpointSecond = 1,
};

// From LookinDashboardBlueprint.h.

/// Which object on a display item an attribute reads from and writes to. The
/// host picks the target oid for a modification with this; the old
/// per-kind boolean queries below remain as wrappers around it.
typedef NS_ENUM(NSInteger, LookinAttrTargetKind) {
    LookinAttrTargetKindLayer = 0,
    LookinAttrTargetKindView,
    LookinAttrTargetKindWindow,
    LookinAttrTargetKindCell,   // AppKit only; wired up in the NSCell phase
};

// From LookinDisplayItemDetail.h.

/// Values of `failureCode`. The property stays a plain NSInteger on the wire.
typedef NS_ENUM(NSInteger, LookinDisplayItemDetailFailureCode) {
    LookinDisplayItemDetailFailureCodeNone = 0,
    /// The oid resolved to an object no detail branch handles — a real fault
    /// worth surfacing. The only value servers sent before 2026-08, so old
    /// hosts alert on exactly this one.
    LookinDisplayItemDetailFailureCodeUnhandledObject = -1,
    /// The oid resolved to nothing: the object was released after the
    /// hierarchy build. The inspected app's short-lived internals (TextKit 2
    /// fragment views, portals) go away on their own, so this is routine —
    /// the node keeps showing the data captured at build time and hosts log
    /// it without alerting. Old hosts treat it as a successful empty detail,
    /// which is harmless.
    LookinDisplayItemDetailFailureCodeObjectGone = -2,
};

// From LookinEventHandler.h.

typedef NS_ENUM(NSInteger, LookinEventHandlerType) {
    LookinEventHandlerTypeTargetAction,
    LookinEventHandlerTypeGesture
};

// From LookinStaticAsyncUpdateTask.h.

typedef NS_ENUM(NSInteger, LookinStaticAsyncUpdateTaskType) {
    LookinStaticAsyncUpdateTaskTypeNoScreenshot,
    LookinStaticAsyncUpdateTaskTypeSoloScreenshot,
    LookinStaticAsyncUpdateTaskTypeGroupScreenshot
};

typedef NS_ENUM(NSInteger, LookinDetailUpdateTaskAttrRequest) {
    /// 由 Server 端自己决定：同一批 task 里，server 端会保证同一个 layer 只会构造一次 attr
    /// 在 Lookin turbo 模式下，由于同一个 layer 的 task 可能位于不同批的 task 里，因此这会导致冗余的 attr 构造行为、浪费一定时间
    LookinDetailUpdateTaskAttrRequest_Automatic,
    /// 需要返回 attr
    LookinDetailUpdateTaskAttrRequest_Need,
    /// 不需要返回 attr
    LookinDetailUpdateTaskAttrRequest_NotNeed
};

// From LookinAttributesSection.h.

typedef NS_ENUM (NSInteger, LookinAttributesSectionStyle) {
    LookinAttributesSectionStyleDefault,    // 每个 attr 独占一行
    LookinAttributesSectionStyle0,  // frame 等卡片使用，前 4 个 attr 每行两个，之后每个 attr 在同一排，每个宽度为 1/4
    LookinAttributesSectionStyle1,  // 第一个 attr 在第一排靠左，第二个 attr 在第一排靠右，之后的 attr 每个独占一行
    LookinAttributesSectionStyle2   // 第一排独占一行，剩下的在同一行且均分宽度
};

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
