@testable import LookInsideHostCore
import Testing

struct DetailFetchPlanningTests {
    typealias Request = DetailFetchPlanning.Request

    /// window (expanded)
    ///   container (folded)
    ///     label
    ///     stack (folded)
    ///       icon
    ///   badge
    private func sampleTree() -> [DetailFetchPlanning.Node] {
        [
            node(children: [1, 4], isExpandable: true, isExpanded: true),
            node(children: [2, 3], isExpandable: true, isExpanded: false),
            node(children: []),
            node(children: [5], isExpandable: true, isExpanded: false),
            node(children: []),
            node(children: []),
        ]
    }

    @Test func onScreenNodesGetTheScreenshotThePreviewShowsAndTheirAttributes() {
        let requests = DetailFetchPlanning.onScreenRequests(for: sampleTree(), displayedIndexes: [0, 1, 4])
        #expect(requests == [
            Request(nodeIndex: 0, screenshot: .solo, wantsAttributes: true),
            Request(nodeIndex: 1, screenshot: .group, wantsAttributes: true),
            Request(nodeIndex: 4, screenshot: .group, wantsAttributes: true),
        ])
    }

    @Test func onScreenRequestsSkipWhatTheNodesAlreadyHave() {
        var nodes = sampleTree()
        nodes[0].hasSoloScreenshot = true
        nodes[0].hasAttributes = true
        nodes[1].hasGroupScreenshot = true
        nodes[4].hasAttributes = true
        let requests = DetailFetchPlanning.onScreenRequests(for: nodes, displayedIndexes: [0, 1, 4])
        #expect(requests == [
            Request(nodeIndex: 1, screenshot: nil, wantsAttributes: true),
            Request(nodeIndex: 4, screenshot: .group, wantsAttributes: false),
        ])
    }

    @Test func anExpandedNodeWithoutPixelBearingChildrenShowsItsGroupScreenshot() {
        var nodes = sampleTree()
        nodes[0].hasPixelBearingSubitems = false
        let requests = DetailFetchPlanning.onScreenRequests(for: nodes, displayedIndexes: [0])
        #expect(requests == [Request(nodeIndex: 0, screenshot: .group, wantsAttributes: true)])
    }

    @Test func nodesThatMayNotBeScreenshotGetAttributesOnlyAndCustomNodesNothing() {
        var nodes = sampleTree()
        nodes[1].mayFetchScreenshot = false
        nodes[4].isUserCustom = true
        let requests = DetailFetchPlanning.onScreenRequests(for: nodes, displayedIndexes: [1, 4])
        #expect(requests == [Request(nodeIndex: 1, screenshot: nil, wantsAttributes: true)])
    }

    @Test func prefetchGoesBreadthFirstThroughWhatExpandingWouldShowThenWhatCollapsingWould() {
        let requests = DetailFetchPlanning.prefetchRequests(for: sampleTree(), displayedIndexes: [0, 1, 4])
        #expect(requests == [
            // Expanding the container: its solo screenshot, its children's group screenshots.
            Request(nodeIndex: 1, screenshot: .solo, wantsAttributes: false),
            Request(nodeIndex: 2, screenshot: .group, wantsAttributes: false),
            Request(nodeIndex: 3, screenshot: .group, wantsAttributes: false),
            // One level further: expanding the stack.
            Request(nodeIndex: 3, screenshot: .solo, wantsAttributes: false),
            Request(nodeIndex: 5, screenshot: .group, wantsAttributes: false),
            // Last, collapsing the window, which shows its solo screenshot now.
            Request(nodeIndex: 0, screenshot: .group, wantsAttributes: false),
        ])
    }

    @Test func prefetchSkipsScreenshotsAlreadyThereAndNodesThatMayNotBeScreenshot() {
        var nodes = sampleTree()
        nodes[0].hasGroupScreenshot = true
        nodes[1].hasSoloScreenshot = true
        nodes[2].hasGroupScreenshot = true
        nodes[3].mayFetchScreenshot = false
        let requests = DetailFetchPlanning.prefetchRequests(for: nodes, displayedIndexes: [0, 1, 4])
        #expect(requests == [Request(nodeIndex: 5, screenshot: .group, wantsAttributes: false)])
    }

    @Test func collapsingAsksForNoScreenshotTheNodeShowsAlready() {
        var nodes = sampleTree()
        // No child draws anything: the expanded window shows its group screenshot.
        nodes[0].hasPixelBearingSubitems = false
        let requests = DetailFetchPlanning.prefetchRequests(for: nodes, displayedIndexes: [0, 1, 4])
        #expect(requests.contains(Request(nodeIndex: 0, screenshot: .group, wantsAttributes: false)) == false)
    }

    @Test func prefetchAsksForNoSoloScreenshotWhenNoChildDrawsAnything() {
        var nodes = sampleTree()
        nodes[1].hasPixelBearingSubitems = false
        let requests = DetailFetchPlanning.prefetchRequests(for: nodes, displayedIndexes: [1])
        #expect(requests.contains(Request(nodeIndex: 1, screenshot: .solo, wantsAttributes: false)) == false)
        #expect(requests.first == Request(nodeIndex: 2, screenshot: .group, wantsAttributes: false))
    }

    @Test func onceEveryNodeIsExpandedOnlyWhatCollapsingWouldShowIsLeft() {
        var nodes = sampleTree()
        nodes[1].isExpanded = true
        nodes[3].isExpanded = true
        let requests = DetailFetchPlanning.prefetchRequests(for: nodes, displayedIndexes: [0, 1, 2, 3, 4, 5])
        #expect(requests == [
            Request(nodeIndex: 0, screenshot: .group, wantsAttributes: false),
            Request(nodeIndex: 1, screenshot: .group, wantsAttributes: false),
            Request(nodeIndex: 3, screenshot: .group, wantsAttributes: false),
        ])
    }

    @Test func aSavedFileGetsEverythingTheNodesMissDisplayedNodesFirst() {
        let requests = DetailFetchPlanning.wholeTreeRequests(for: sampleTree(), displayedIndexes: [0, 1, 4])
        #expect(requests == [
            // What the displayed nodes show, as on screen.
            Request(nodeIndex: 0, screenshot: .solo, wantsAttributes: true),
            Request(nodeIndex: 1, screenshot: .group, wantsAttributes: true),
            Request(nodeIndex: 4, screenshot: .group, wantsAttributes: true),
            // Then, in list order, every other screenshot a node can have and
            // the attributes not asked for yet.
            Request(nodeIndex: 0, screenshot: .group, wantsAttributes: false),
            Request(nodeIndex: 1, screenshot: .solo, wantsAttributes: false),
            Request(nodeIndex: 2, screenshot: .group, wantsAttributes: true),
            Request(nodeIndex: 3, screenshot: .group, wantsAttributes: true),
            Request(nodeIndex: 3, screenshot: .solo, wantsAttributes: false),
            Request(nodeIndex: 5, screenshot: .group, wantsAttributes: true),
        ])
    }

    @Test func aSavedFileAsksOnlyForWhatTheNodesMiss() {
        var nodes = sampleTree()
        for index in nodes.indices {
            nodes[index].hasSoloScreenshot = true
            nodes[index].hasGroupScreenshot = true
            nodes[index].hasAttributes = true
        }
        nodes[2].hasAttributes = false
        nodes[3].hasSoloScreenshot = false
        let requests = DetailFetchPlanning.wholeTreeRequests(for: nodes, displayedIndexes: [0, 1, 4])
        #expect(requests == [
            Request(nodeIndex: 2, screenshot: nil, wantsAttributes: true),
            Request(nodeIndex: 3, screenshot: .solo, wantsAttributes: false),
        ])
    }

    @Test func aSavedFileGetsNoSoloScreenshotWhereNoChildDrawsAnything() {
        var nodes = sampleTree()
        nodes[3].hasPixelBearingSubitems = false
        let requests = DetailFetchPlanning.wholeTreeRequests(for: nodes, displayedIndexes: [])
        #expect(requests.filter { $0.nodeIndex == 3 } == [Request(nodeIndex: 3, screenshot: .group, wantsAttributes: true)])
    }

    @Test func nodesThatMayNotBeScreenshotGoIntoASavedFileWithTheirAttributesAlone() {
        var nodes = sampleTree()
        nodes[2].mayFetchScreenshot = false
        let requests = DetailFetchPlanning.wholeTreeRequests(for: nodes, displayedIndexes: [])
        #expect(requests.filter { $0.nodeIndex == 2 } == [Request(nodeIndex: 2, screenshot: nil, wantsAttributes: true)])
    }

    @Test func customNodesAreNotAskedForWhenSaving() {
        var nodes = sampleTree()
        nodes[5].isUserCustom = true
        let requests = DetailFetchPlanning.wholeTreeRequests(for: nodes, displayedIndexes: [])
        #expect(requests.contains { $0.nodeIndex == 5 } == false)
    }

    private func node(children: [Int], isExpandable: Bool = false, isExpanded: Bool = false) -> DetailFetchPlanning.Node {
        DetailFetchPlanning.Node(
            childIndexes: children,
            isExpandable: isExpandable,
            isExpanded: isExpanded,
            hasPixelBearingSubitems: !children.isEmpty,
            mayFetchScreenshot: true,
            isUserCustom: false,
            hasSoloScreenshot: false,
            hasGroupScreenshot: false,
            hasAttributes: false
        )
    }
}
