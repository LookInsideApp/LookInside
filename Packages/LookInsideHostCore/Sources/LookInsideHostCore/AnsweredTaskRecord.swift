import Foundation

/// The detail tasks that requests answered in full since the hierarchy was
/// last reloaded, so a task answered without an image (a leaf has no solo
/// screenshot) is not asked for again each time the displayed items change.
///
/// A request notes `treeVersion` when it is sent. One sent before the latest
/// reload records nothing: part of its replies went to the tree the reload
/// replaced, so its tasks are still missing in the new one.
public struct AnsweredTaskRecord<TaskKey: Hashable> {
    /// Goes up with each reload.
    public private(set) var treeVersion = 0
    private var keys = Set<TaskKey>()

    public init() {}

    public func contains(_ key: TaskKey) -> Bool {
        keys.contains(key)
    }

    /// The hierarchy was reloaded: no task is answered for the new tree yet.
    public mutating func startNewTree() {
        treeVersion += 1
        keys.removeAll()
    }

    /// Records the tasks of a request that every task answered; nothing
    /// when it was sent for an earlier tree.
    public mutating func record(_ taskKeys: some Sequence<TaskKey>, sentForTreeVersion: Int) {
        guard sentForTreeVersion == treeVersion else { return }
        keys.formUnion(taskKeys)
    }

    /// Forgets the tasks `shouldForget` matches, so they are asked for
    /// again.
    public mutating func forget(where shouldForget: (TaskKey) -> Bool) {
        keys = keys.filter { !shouldForget($0) }
    }
}
