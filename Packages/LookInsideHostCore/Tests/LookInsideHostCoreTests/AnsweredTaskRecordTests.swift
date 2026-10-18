@testable import LookInsideHostCore
import Testing

struct AnsweredTaskRecordTests {
    @Test func theTasksOfARequestAnsweredInFullAreRecorded() {
        var record = AnsweredTaskRecord<String>()
        record.record(["window solo", "label group"], sentForTreeVersion: record.treeVersion)
        #expect(record.contains("window solo"))
        #expect(record.contains("label group"))
    }

    @Test func aReloadForgetsEveryTask() {
        var record = AnsweredTaskRecord<String>()
        record.record(["window solo"], sentForTreeVersion: record.treeVersion)
        record.startNewTree()
        #expect(record.contains("window solo") == false)
    }

    /// The bug this guards against: a request sent for the tree a reload
    /// replaced finished afterwards, and the tasks it marked as answered
    /// were never asked for in the new tree.
    @Test func aRequestSentBeforeAReloadRecordsNothing() {
        var record = AnsweredTaskRecord<String>()
        let treeVersionAtSend = record.treeVersion
        record.startNewTree()
        record.record(["window solo"], sentForTreeVersion: treeVersionAtSend)
        #expect(record.contains("window solo") == false)
    }

    @Test func forgottenTasksAreNoLongerRecorded() {
        var record = AnsweredTaskRecord<String>()
        record.record(["window solo", "label group"], sentForTreeVersion: record.treeVersion)
        record.forget { $0.hasPrefix("window") }
        #expect(record.contains("window solo") == false)
        #expect(record.contains("label group"))
    }
}
