//
//  Debug Stuff.swift
//  MacLock
//
//  Created by Gero Embser on 23.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//
//
// A file that just contains a lot of debug stuff for me (which could be helpful in some situations)...

import Foundation

extension AudioManager {
    ///A method that can be used to query some properties of AudioDevices simply from lldb...
    ///Helpful when you're experiencing the well documented CoreAudio-API's
    func get<T>(valueForSelector selector: AudioObjectPropertySelector,
                for deviceID: AudioDeviceID,
                scope: AudioObjectPropertyScope = kAudioDevicePropertyScopeOutput,
                element: AudioObjectPropertyElement = kAudioObjectPropertyElementMaster) throws -> [T] {
        var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
        
        var propertySize: UInt32 = 0
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize))
        
        let numberOfInstances = Int(propertySize)/(MemoryLayout<T>.stride)
        print(numberOfInstances)
        let resultPointer = UnsafeMutablePointer<T>.allocate(capacity: numberOfInstances)
        
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, resultPointer))
        
        return Array(UnsafeBufferPointer(start: resultPointer, count: numberOfInstances))
    }
}
