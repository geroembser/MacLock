//
//  AudioErrorHandling.swift
//  MacLock
//
//  Created by Gero Embser on 23.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation

//MARK: - error handling
protocol AudioErrorHandling {
    func handlePossibleError(forStatusCode statusCode: OSStatus) throws
}

extension AudioErrorHandling {
    //for classes...
    static func handlePossibleError(forStatusCode statusCode: OSStatus) throws {
        if statusCode != kAudioHardwareNoError {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(statusCode), userInfo: [NSLocalizedDescriptionKey : "CAError: \(statusCode)" ])
            throw error
        }
    }
    //for instances...
    func handlePossibleError(forStatusCode statusCode: OSStatus) throws {
        try Self.handlePossibleError(forStatusCode: statusCode)
    }
}
