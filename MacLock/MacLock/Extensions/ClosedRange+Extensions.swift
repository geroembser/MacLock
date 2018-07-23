//
//  ClosedRange+Extensions.swift
//  MacLock
//
//  Created by Gero Embser on 23.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
