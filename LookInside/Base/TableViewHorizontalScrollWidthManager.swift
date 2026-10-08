//
//  TableViewHorizontalScrollWidthManager.swift
//  LookInside
//
//  Created by likaimacbookhome on 2023/12/17.
//  Copyright © 2023 hughkli. All rights reserved.
//

import Foundation

class TableViewHorizontalScrollWidthManager: NSObject {
    @objc var maxRowWidth: CGFloat = 0

    @objc var didReachNewMaxWidth: (() -> Void)?

    @objc(rowDidLayoutWithWidth:)
    func rowDidLayout(withWidth width: CGFloat) {
        guard width > maxRowWidth else {
            return
        }
        maxRowWidth = width
        didReachNewMaxWidth?()
    }
}
