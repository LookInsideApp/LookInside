//
//  KuGouHierarchyCollapse.swift
//  LookInside
//
//  酷狗（KuGou）KGMainViewController 层级折叠，从 ObjC 版 LookinDisplayItem 的
//  lk_kg_* 分类方法移植而来，逻辑保持一致。
//

import AppKit

/// 酷狗 iOS 客户端没有使用 UINavigationController / UITabBarController 管理页面，而是用
/// KGMainViewController 不断 addChildViewController:，被 add 的所有 subVC 始终都实时挂在视图树上
/// （系统容器在页面离屏后会 remove，而酷狗不会）。这导致每次 snapshot 都会渲染海量控件。
/// 这里在打平层级之前，把 KGMainViewController.view 下的子树折叠为「只显示最上面的那个 VC」，
/// 并默认隐藏抽屉（_setViewContainer）。
///
/// 两个开关相互独立（都默认关闭，即默认折叠、隐藏抽屉）：
///   - showAllPages：打开时不折叠页面栈，显示全部页面；
///   - showDrawer：  打开时保留抽屉（_setViewContainer）的子层级。
/// 即使打开「显示全部页面」，抽屉仍只受「显示抽屉」控制，不会被连带展示。
///
/// 折叠会就地修改 subitems，宿主的层级列表、预览和内置 MCP 读到的都是折叠后的树。
enum KuGouHierarchyCollapse {
    /// 按偏好设置里的两个开关，就地折叠 items 这棵层级树。
    static func apply(to items: [DisplayItem]?) {
        let preferences = PreferenceManager.shared
        let options = Options(
            showAllPages: preferences.kgShowAllPages.currentBOOLValue,
            showDrawer: preferences.kgShowDrawer.currentBOOLValue
        )
        apply(to: items, options: options)
    }

    struct Options {
        var showAllPages: Bool
        var showDrawer: Bool
    }

    static func apply(to items: [DisplayItem]?, options: Options) {
        for item in items ?? [] {
            if isMainViewControllerView(item) {
                item.subitems = filterSubitems(item.subitems, options: options)
            }
            if let subitems = item.subitems, !subitems.isEmpty {
                apply(to: subitems, options: options)
            }
        }
    }

    // MARK: - 识别

    /// KGMainViewController.view 对应的节点（specialTrace 形如 "KGMainViewController.view"）。
    private static func isMainViewControllerView(_ item: DisplayItem) -> Bool {
        guard let trace = item.viewObject?.specialTrace else {
            return false
        }
        return trace.contains("KGMainViewController") && trace.contains(".view")
    }

    /// 节点是否被某个宿主对象以 ivarName 这个成员变量持有。
    private static func item(_ item: DisplayItem, hasIvar ivarName: String) -> Bool {
        guard let traces = item.viewObject?.ivarTraces else {
            return false
        }
        return traces.contains { $0.ivarName == ivarName }
    }

    // MARK: - 折叠

    /// KGMainViewController.view 的直接子层。新框架下存在 _contentContainer（主框架容器），
    /// 旧框架下则没有，直接把 KGMainViewController.view 的子层当作内容容器处理。
    private static func filterSubitems(_ subitems: [DisplayItem]?, options: Options) -> [DisplayItem]? {
        guard let subitems else {
            return nil
        }
        var hasFoundContentContainer = false
        var count = 0
        for subitem in subitems {
            if item(subitem, hasIvar: "_contentContainer") {
                // 主框架容器
                subitem.subitems = filterContentContainerSubitems(subitem.subitems, options: options)
                count += 1
                hasFoundContentContainer = true
            }
            if count >= 2 {
                break
            }
        }

        if !hasFoundContentContainer {
            // 旧版本：没有 _contentContainer，直接按内容容器处理
            return filterContentContainerSubitems(subitems, options: options)
        }
        return subitems
    }

    private static func filterContentContainerSubitems(_ subitems: [DisplayItem]?, options: Options) -> [DisplayItem]? {
        guard let subitems else {
            return nil
        }
        var isSetContentNotEmpty = false
        for subitem in subitems {
            if item(subitem, hasIvar: "_setViewContainer") {
                // 抽屉：只由「显示抽屉」控制，和「显示全部页面」相互独立
                if !options.showDrawer {
                    subitem.subitems = nil
                }
            } else if !options.showAllPages, item(subitem, hasIvar: "_mainBackScaleView") {
                // 页面折叠相关：仅在未开启「显示全部页面」时进行
                subitem.subitems = filterMainBackScaleViewSubitems(subitem.subitems)
            } else if !options.showAllPages, item(subitem, hasIvar: "_setContentView") {
                subitem.subitems = filterContentViewSubitems(subitem.subitems)
                isSetContentNotEmpty = !(subitem.subitems ?? []).isEmpty
            }
        }

        if !options.showAllPages, isSetContentNotEmpty {
            // 设置层（抽屉内容层）非空时，主缩放层让位；抽屉本身仍只由「显示抽屉」控制
            for subitem in subitems {
                if item(subitem, hasIvar: "_setViewContainer") {
                    if !options.showDrawer {
                        subitem.subitems = nil
                    }
                } else if item(subitem, hasIvar: "_mainBackScaleView") {
                    subitem.subitems = nil
                } else if item(subitem, hasIvar: "_setContentView") {
                    subitem.subitems = filterContentViewSubitems(subitem.subitems)
                }
            }
        }
        return subitems
    }

    private static func filterMainBackScaleViewSubitems(_ subitems: [DisplayItem]?) -> [DisplayItem]? {
        guard let subitems else {
            return nil
        }
        for subitem in subitems where item(subitem, hasIvar: "_mainBackView") {
            subitem.subitems = filterMainBackViewSubitems(subitem.subitems)
            break
        }
        return subitems
    }

    private static func filterMainBackViewSubitems(_ subitems: [DisplayItem]?) -> [DisplayItem]? {
        guard let subitems else {
            return nil
        }
        var count = 0
        for subitem in subitems {
            if item(subitem, hasIvar: "_guideBarContainer") {
                // 侧边栏，保持原样
            } else if item(subitem, hasIvar: "_contentView") {
                subitem.subitems = filterContentViewSubitems(subitem.subitems)
                count += 1
            } else if item(subitem, hasIvar: "_fullSizeContentView") {
                subitem.subitems = filterContentViewSubitems(subitem.subitems)
                if (subitem.subitems?.count ?? 0) >= 2 {
                    count += 1
                }
            }
            if count >= 2 {
                break
            }
        }

        if count > 1 {
            // 两个内容容器都有内容时，只保留 _fullSizeContentView
            for subitem in subitems {
                if item(subitem, hasIvar: "_fullSizeContentView") {
                    subitem.subitems = filterContentViewSubitems(subitem.subitems)
                }
                if item(subitem, hasIvar: "_contentView") {
                    subitem.subitems = nil
                }
            }
        }
        return subitems
    }

    /// 页面容器的子层：只保留「最上面 VC 下面第一层的阴影」和「最上面的那个 VC」。
    private static func filterContentViewSubitems(_ subitems: [DisplayItem]?) -> [DisplayItem]? {
        guard let subitems else {
            return nil
        }
        var filteredItems: [DisplayItem] = []
        for (index, subitem) in subitems.enumerated() {
            if item(subitem, hasIvar: "_backShadowView") {
                // 最上面 VC 下面第一层的阴影
                filteredItems.append(subitem)
            } else if index == subitems.count - 1 {
                // 最上面的那个 VC
                filteredItems.append(subitem)
            }
            if filteredItems.count >= 2 {
                break
            }
        }

        // 在首页时，阴影不会移动到下方，此时保留原始子层
        if filteredItems.count < 2 {
            return subitems
        }
        return filteredItems
    }
}
