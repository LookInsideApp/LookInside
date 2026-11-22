//
//  DashboardRowsCountTests.swift
//  LookInsideAppTests
//
//  A table view with no sections has no rows to count: the Server's
//  `lks_numberOfRows` answers nil, and the attribute arrives without a value
//  (upstream Lookin sends it the same way). The rows-count view stopped a
//  debug Host at an assertion on it, and a release Host kept the rows of the
//  table it showed before — the view is reused when another node is
//  selected. A missing value now shows no rows.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct DashboardRowsCountTests {
        private func rowsCountAttribute(_ numbers: [Int]?) -> InspectedAttribute {
            let attribute = InspectedAttribute()
            // InspectedAttribute.Identifier.UITableView.RowsNumber.number.
            attribute.identifier = "tv_r_n"
            attribute.attrType = .customObject
            attribute.value = numbers.map { $0.map(NSNumber.init(value:)) as NSArray }
            return attribute
        }

        private func shownRows(of view: DashboardAttributeRowsCountView) -> [String] {
            view.subviews.compactMap { ($0 as? NumberInputView)?.textFieldView.textField.stringValue }
        }

        @Test func tableWithoutSectionsShowsNoRows() {
            let view = DashboardAttributeRowsCountView(frame: .zero)

            view.attribute = rowsCountAttribute(nil)

            #expect(shownRows(of: view).isEmpty)
        }

        @Test func tableWithoutSectionsDropsTheRowsShownBefore() {
            let view = DashboardAttributeRowsCountView(frame: .zero)
            view.attribute = rowsCountAttribute([4, 2])
            #expect(shownRows(of: view) == ["4", "2"])

            view.attribute = rowsCountAttribute(nil)

            #expect(shownRows(of: view).isEmpty)
        }
    }
}
