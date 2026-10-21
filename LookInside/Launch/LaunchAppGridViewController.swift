//
//  LaunchAppGridViewController.swift
//  LookInside
//
//  The launch window's content: the apps of the device selected in the
//  sidebar as a grid of cards, the "searching" state while no app is found,
//  and the progress bar of the hierarchy fetch a click starts.
//

import AppKit
import UIFoundationToolbox

final class LaunchAppGridViewController: NSViewController {
    private enum Section: Hashable {
        case apps
    }

    /// Runs when a clickable card is clicked.
    var onClickApp: ((InspectableApp) -> Void)?

    let progressIndicatorView = ProgressIndicatorView()

    private let scrollView = NSScrollView()
    private let collectionView = NSCollectionView()
    private var dataSource: NSCollectionViewDiffableDataSource<Section, InspectableAppOrigin>?
    private var cardsByOrigin: [InspectableAppOrigin: LaunchAppCard] = [:]
    private var displayedDevice: LaunchDeviceIdentity?

    private let searchingIndicator = NSProgressIndicator()
    private let searchingLabel = NSTextField(labelWithString: NSLocalizedString("Searching for inspectable apps", comment: ""))
    private lazy var searchingStackView = NSStackView(views: [searchingIndicator, searchingLabel])
    private let hintLabel = NSTextField(wrappingLabelWithString: "")
    /// The grid ends at the window's bottom, or above the hint while the
    /// hint shows.
    private var scrollViewBottomToContainer: NSLayoutConstraint?
    private var scrollViewBottomToHint: NSLayoutConstraint?

    override func loadView() {
        let containerView = NSView()

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = LaunchAppCardItem.itemSize
        layout.sectionInset = NSEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColors = [.clear]
        collectionView.isSelectable = false
        collectionView.autoresizingMask = [.width]
        collectionView.box.registerItem(LaunchAppCardItem.self)

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        searchingIndicator.style = .spinning
        searchingIndicator.controlSize = .small
        searchingIndicator.isIndeterminate = true
        searchingLabel.font = .systemFont(ofSize: 14)
        searchingStackView.orientation = .horizontal
        searchingStackView.spacing = 6

        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.alignment = .center
        hintLabel.isSelectable = false
        hintLabel.isHidden = true

        for subview in [scrollView, searchingStackView, hintLabel, progressIndicatorView] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(subview)
        }
        let safeArea = containerView.safeAreaLayoutGuide
        let scrollViewBottomToContainer = scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        self.scrollViewBottomToContainer = scrollViewBottomToContainer
        scrollViewBottomToHint = scrollView.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -8)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollViewBottomToContainer,

            searchingStackView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            searchingStackView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

            hintLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
            hintLabel.bottomAnchor.constraint(equalTo: progressIndicatorView.topAnchor, constant: -12),

            progressIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressIndicatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressIndicatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            progressIndicatorView.heightAnchor.constraint(equalToConstant: 3),
        ])
        view = containerView

        dataSource = NSCollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, origin in
            let item = collectionView.box.makeItem(ofClass: LaunchAppCardItem.self, for: indexPath)
            if let card = self?.cardsByOrigin[origin] {
                item.configure(with: card)
            }
            item.onClick = { [weak self] in
                guard let card = self?.cardsByOrigin[origin] else { return }
                self?.onClickApp?(card.app)
            }
            return item
        }
    }

    /// Shows the cards of `device`. `isSearching` shows the searching state
    /// instead: no app was found on any device.
    func show(_ cards: [LaunchAppCard], of device: LaunchDeviceIdentity?, isSearching: Bool) {
        loadViewIfNeeded()
        let isDifferentDevice = device != displayedDevice
        displayedDevice = device
        // A diffable snapshot traps on a duplicate item; keep the first card
        // of an origin.
        var seenOrigins = Set<InspectableAppOrigin>()
        let uniqueCards = cards.filter { seenOrigins.insert($0.origin).inserted }
        cardsByOrigin = Dictionary(uniqueKeysWithValues: uniqueCards.map { ($0.origin, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, InspectableAppOrigin>()
        snapshot.appendSections([.apps])
        snapshot.appendItems(uniqueCards.map(\.origin), toSection: .apps)
        dataSource?.apply(snapshot, animatingDifferences: !isDifferentDevice)

        // Items whose origin stayed are not recreated; give them this scan's
        // screenshot, name and state.
        for indexPath in collectionView.indexPathsForVisibleItems() {
            guard let origin = dataSource?.itemIdentifier(for: indexPath),
                  let card = cardsByOrigin[origin],
                  let item = collectionView.item(at: indexPath) as? LaunchAppCardItem
            else {
                continue
            }
            item.configure(with: card)
        }

        searchingStackView.isHidden = !isSearching
        if isSearching {
            searchingIndicator.startAnimation(nil)
        } else {
            searchingIndicator.stopAnimation(nil)
        }
        scrollView.isHidden = isSearching

        // Only apps that reported being in the background count: one that
        // did not answer in time is not helped by bringing it forward.
        let everyAppIsInBackground = !uniqueCards.isEmpty && uniqueCards.allSatisfy { $0.app.unresponsiveness == .inBackground }
        hintLabel.stringValue = NSLocalizedString(
            "The apps on this device are in the background. Bring one to the foreground to inspect it.",
            comment: "Launch window hint when every app of the selected device is in the background"
        )
        let showsHint = !isSearching && everyAppIsInBackground
        hintLabel.isHidden = !showsHint
        // Deactivate before activating, so the two never hold at once.
        if showsHint {
            scrollViewBottomToContainer?.isActive = false
            scrollViewBottomToHint?.isActive = true
        } else {
            scrollViewBottomToHint?.isActive = false
            scrollViewBottomToContainer?.isActive = true
        }
    }
}
