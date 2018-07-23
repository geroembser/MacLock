//
//  macos.swift
//  MacLock
//
//  Created by Gero Embser on 18.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation

@_silgen_name("SACLockScreenImmediate") func SACLockScreenImmediate() -> Void
enum macos {
    static func lockByShowingLockscreen() {
        SACLockScreenImmediate()
    }
}
