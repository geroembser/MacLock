//
//  Collections+Extensions.swift
//  MacLock
//
//  Created by Gero Embser on 23.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
