//
//  ReadViewController.swift
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

import AppKit

/// The reader window's content: the hierarchy list on the left; the
/// preview, the dashboard or the measure panel on the right; and a tip
/// while the tree is in focus mode.
@objc(LKReadViewController)
final class ReadViewController: BaseViewController, NSSplitViewDelegate {
    @objc let hierarchyDataSource: ReadHierarchyDataSource

    private let splitView = SplitView()
    private let hierarchyController: ReadHierarchyController
    private let splitRightView = BaseView()
    private let previewController: PreviewController
    private let dashboardController: DashboardViewController
    private let measureController: MeasureController
    private let focusTipView = YellowTipsView()
    private var stateObservation: NSKeyValueObservation?

    @objc(initWithFile:preferenceManager:)
    init(file: HierarchyFile, preferenceManager manager: PreferenceManager) {
        let dataSource = ReadHierarchyDataSource(file: file, preferenceManager: manager)
        hierarchyDataSource = dataSource
        hierarchyController = ReadHierarchyController(dataSource: dataSource)
        previewController = PreviewController(dataSource: dataSource)
        dashboardController = DashboardViewController(readDataSource: dataSource)
        measureController = MeasureController(dataSource: dataSource)
        super.init(containerView: nil)

        addChild(hierarchyController)
        splitView.addArrangedSubview(hierarchyController.view)
        splitView.addArrangedSubview(splitRightView)

        splitRightView.addSubview(previewController.view)
        addChild(previewController)

        splitRightView.addSubview(dashboardController.view)
        addChild(dashboardController)

        measureController.view.isHidden = true
        splitRightView.addSubview(measureController.view)
        addChild(measureController)

        focusTipView.image = NSImage(named: "icon_info")
        focusTipView.title = NSLocalizedString("Currently in focus mode", comment: "")
        focusTipView.isHidden = true
        focusTipView.buttonText = NSLocalizedString("Exit", comment: "")
        focusTipView.target = self
        focusTipView.clickAction = #selector(handleExitFocusTipView)
        view.addSubview(focusTipView)

        manager.measureState.subscribe(self, action: #selector(handleMeasureStateChange(_:)), relatedObject: nil)

        stateObservation = dataSource.observe(\.state, options: [.initial, .new]) { [weak self] dataSource, _ in
            MainActor.assumeIsolated {
                self?.updateFocusTip(isFocus: dataSource.state == .focus)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func makeContainerView() -> NSView {
        splitView.didFinishFirstLayout = { view in
            view.setPosition(350, ofDividerAt: 0)
        }
        splitView.arrangesAllSubviews = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        return splitView
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        ViewFrameLayout(previewController.view).fullFrame()
        ViewFrameLayout(dashboardController.view).width(DashboardViewWidth).right(0).fullHeight()
        ViewFrameLayout(measureController.view).width(MeasureViewWidth).right(DashboardHorInset).fullHeight()

        var tipsY = NavigationManager.shared.windowTitleBarHeight + 10
        let visibleTips = [focusTipView].filter { !$0.isHidden && $0.superview != nil && $0.alphaValue >= 0.01 }
        for tipsView in visibleTips {
            let midX = hierarchyController.view.bounds.width + (previewController.view.bounds.width - DashboardViewWidth) / 2
            ViewFrameLayout(tipsView).sizeToFit().y(tipsY).midX(midX)
            tipsY = tipsView.frame.maxY + 5
        }
    }

    /// The reader's hierarchy list.
    @objc func currentHierarchyView() -> HierarchyView? {
        hierarchyController.hierarchyView
    }

    private func updateFocusTip(isFocus: Bool) {
        focusTipView.isHidden = !isFocus
        if isFocus {
            focusTipView.startAnimation()
        } else {
            focusTipView.endAnimation()
        }
        view.needsLayout = true
    }

    @objc private func handleMeasureStateChange(_ param: MessageActionParameters) {
        let isMeasure = param.integerValue != MeasureState.no.rawValue
        dashboardController.view.isHidden = isMeasure
        measureController.view.isHidden = !isMeasure
    }

    @objc private func handleExitFocusTipView() {
        hierarchyDataSource.endFocus()
    }

    // MARK: - NSSplitViewDelegate

    func splitView(_: NSSplitView, canCollapseSubview _: NSView) -> Bool {
        false
    }

    func splitView(_: NSSplitView, constrainMinCoordinate _: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        200
    }

    func splitView(_: NSSplitView, constrainMaxCoordinate _: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        700
    }
}
