//
//  Deprecated.swift
//  LookinCoreImpl
//
//  The type names from before the LK / LKS / Lookin prefixes were dropped,
//  kept so that client code still compiles. Removed in 2.0.0.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    @available(*, deprecated, renamed: "MultiplatformAdapter")
    public typealias LKS_MultiplatformAdapter = MultiplatformAdapter

    @available(*, deprecated, renamed: "InspectedAppInfo")
    public typealias LookinAppInfo = InspectedAppInfo

    @available(*, deprecated, renamed: "InspectedAttribute")
    public typealias LookinAttribute = InspectedAttribute

    @available(*, deprecated, renamed: "AttributeModification")
    public typealias LookinAttributeModification = AttributeModification

    @available(*, deprecated, renamed: "AttributesGroup")
    public typealias LookinAttributesGroup = AttributesGroup

    @available(*, deprecated, renamed: "AttributesSection")
    public typealias LookinAttributesSection = AttributesSection

    @available(*, deprecated, renamed: "AutoLayoutConstraint")
    public typealias LookinAutoLayoutConstraint = AutoLayoutConstraint

    @available(*, deprecated, renamed: "ConnectionAttachment")
    public typealias LookinConnectionAttachment = ConnectionAttachment

    @available(*, deprecated, renamed: "ConnectionResponseAttachment")
    public typealias LookinConnectionResponseAttachment = ConnectionResponseAttachment

    @available(*, deprecated, renamed: "CustomAttributeModification")
    public typealias LookinCustomAttrModification = CustomAttributeModification

    @available(*, deprecated, renamed: "CustomDisplayItemInfo")
    public typealias LookinCustomDisplayItemInfo = CustomDisplayItemInfo

    @available(*, deprecated, renamed: "DashboardBlueprint")
    public typealias LookinDashboardBlueprint = DashboardBlueprint

    @available(*, deprecated, renamed: "DisplayItem")
    public typealias LookinDisplayItem = DisplayItem

    @available(*, deprecated, renamed: "DisplayItemDelegate")
    public typealias LookinDisplayItemDelegate = DisplayItemDelegate

    @available(*, deprecated, renamed: "DisplayItemDetail")
    public typealias LookinDisplayItemDetail = DisplayItemDetail

    @available(*, deprecated, renamed: "EventHandlerDescription")
    public typealias LookinEventHandler = EventHandlerDescription

    @available(*, deprecated, renamed: "TransportFrame")
    public typealias LookinFrame = TransportFrame

    @available(*, deprecated, renamed: "FrameChannel")
    public typealias LookinFrameChannel = FrameChannel

    @available(*, deprecated, renamed: "FrameDecoder")
    public typealias LookinFrameDecoder = FrameDecoder

    @available(*, deprecated, renamed: "FrameError")
    public typealias LookinFrameError = FrameError

    @available(*, deprecated, renamed: "FrameHeader")
    public typealias LookinFrameHeader = FrameHeader

    @available(*, deprecated, renamed: "FrameListener")
    public typealias LookinFrameListener = FrameListener

    @available(*, deprecated, renamed: "FrameProtocolConstants")
    public typealias LookinFrameProtocol = FrameProtocolConstants

    @available(*, deprecated, renamed: "HierarchyFile")
    public typealias LookinHierarchyFile = HierarchyFile

    @available(*, deprecated, renamed: "HierarchyInfo")
    public typealias LookinHierarchyInfo = HierarchyInfo

    @available(*, deprecated, renamed: "InstanceVariableTrace")
    public typealias LookinIvarTrace = InstanceVariableTrace

    @available(*, deprecated, renamed: "InspectedObject")
    public typealias LookinObject = InspectedObject

    @available(*, deprecated, renamed: "SocketConnector")
    public typealias LookinSocket = SocketConnector

    @available(*, deprecated, renamed: "StaticAsyncUpdateTask")
    public typealias LookinStaticAsyncUpdateTask = StaticAsyncUpdateTask

    @available(*, deprecated, renamed: "StaticAsyncUpdateTasksPackage")
    public typealias LookinStaticAsyncUpdateTasksPackage = StaticAsyncUpdateTasksPackage

    @available(*, deprecated, renamed: "StringTwoTuple")
    public typealias LookinStringTwoTuple = StringTwoTuple

    @available(*, deprecated, renamed: "TwoTuple")
    public typealias LookinTwoTuple = TwoTuple

    @available(*, deprecated, renamed: "USBMux")
    public typealias LookinUSBMux = USBMux

    @available(*, deprecated, renamed: "USBMuxDecoder")
    public typealias LookinUSBMuxDecoder = USBMuxDecoder

    @available(*, deprecated, renamed: "USBMuxError")
    public typealias LookinUSBMuxError = USBMuxError

    @available(*, deprecated, renamed: "USBMuxPacket")
    public typealias LookinUSBMuxPacket = USBMuxPacket

    @available(*, deprecated, renamed: "WeakContainer")
    public typealias LookinWeakContainer = WeakContainer

    #if canImport(UIKit) || os(macOS)

        @available(*, deprecated, renamed: "PlatformApplication")
        public typealias LookinApplication = PlatformApplication

        @available(*, deprecated, renamed: "PlatformCollectionView")
        public typealias LookinCollectionView = PlatformCollectionView

        @available(*, deprecated, renamed: "PlatformColor")
        public typealias LookinColor = PlatformColor

        @available(*, deprecated, renamed: "PlatformControl")
        public typealias LookinControl = PlatformControl

        @available(*, deprecated, renamed: "PlatformFont")
        public typealias LookinFont = PlatformFont

        @available(*, deprecated, renamed: "PlatformGestureRecognizer")
        public typealias LookinGestureRecognizer = PlatformGestureRecognizer

        @available(*, deprecated, renamed: "PlatformImage")
        public typealias LookinImage = PlatformImage

        @available(*, deprecated, renamed: "PlatformImageView")
        public typealias LookinImageView = PlatformImageView

        @available(*, deprecated, renamed: "PlatformEdgeInsets")
        public typealias LookinInsets = PlatformEdgeInsets

        @available(*, deprecated, renamed: "PlatformLayoutGuide")
        public typealias LookinLayoutGuide = PlatformLayoutGuide

        @available(*, deprecated, renamed: "PlatformResponder")
        public typealias LookinResponder = PlatformResponder

        @available(*, deprecated, renamed: "PlatformTextField")
        public typealias LookinTextField = PlatformTextField

        @available(*, deprecated, renamed: "PlatformTextView")
        public typealias LookinTextView = PlatformTextView

        @available(*, deprecated, renamed: "PlatformView")
        public typealias LookinView = PlatformView

        @available(*, deprecated, renamed: "PlatformViewController")
        public typealias LookinViewController = PlatformViewController

        @available(*, deprecated, renamed: "PlatformWindow")
        public typealias LookinWindow = PlatformWindow

    #endif

    #if os(macOS)

        @available(*, deprecated, renamed: "USBMuxClient")
        public typealias LookinUSBMuxClient = USBMuxClient

    #endif

#endif
