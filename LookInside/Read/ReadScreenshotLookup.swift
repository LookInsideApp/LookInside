//
//  ReadScreenshotLookup.swift
//  LookInside
//
//  Which of a `.lookin` file's stored screenshots belong to a display item.
//

import Foundation

enum ReadScreenshotLookup {
    /// The solo and group screenshot data stored for one item.
    ///
    /// `oids` are the item's object ids in preference order. The first oid
    /// that has either screenshot wins, and both screenshots are taken from
    /// that oid only: a solo screenshot of one object is never paired with
    /// the group screenshot of another.
    static func screenshots(
        forOids oids: [NSNumber],
        solo: [NSNumber: Data]?,
        group: [NSNumber: Data]?
    ) -> (solo: Data?, group: Data?) {
        for oid in oids {
            let soloData = solo?[oid]
            let groupData = group?[oid]
            if soloData != nil || groupData != nil {
                return (soloData, groupData)
            }
        }
        return (nil, nil)
    }
}
