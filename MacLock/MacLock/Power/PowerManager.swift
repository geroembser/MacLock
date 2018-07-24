//
//  PowerManager.swift
//  MacLock
//
//  Created by Gero Embser on 17.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation
import IOKit.ps

class PowerManager {
    //MARK: - instance variables
    private var powerSourceChangedNotification: CFRunLoopSource?
    
    typealias PowerSourceChangeHandler = (PowerSource) -> Void
    var powerSourceChangeHandler: PowerSourceChangeHandler?
}

//MARK: - sleep management
extension PowerManager {
    func enableSleep(_ enable: Bool) throws {
        var error: NSDictionary?
        NSAppleScript(source: "do shell script \"sudo pmset -c disablesleep \(NSNumber(value:!enable))\" with administrator privileges")?.executeAndReturnError(&error)
        
        if let error = error {
            throw NSError(domain: "pmsetError", code: 0, userInfo: error as? [String: Any])
        }
    }
}

//MARK: - power sources
extension PowerManager {
    // DEBUG: for debugging primarily
    func printPowerSourceInfo() {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]
        
        for ps in psList {
            if let psDesc = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
                for (key, value) in psDesc {
                    print("\(key): \(value)")
                }
            }
        }
    }
    
    ///Returns the current power source as a type which represents a custom abstraction for more low level c types
    func currentPowerSource() -> PowerSource {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        
        //current type
        guard let powerSourceType = IOPSGetProvidingPowerSourceType(psInfo)?.takeRetainedValue() else {
            return .unknown
        }
        
        return PowerSource(identifier: powerSourceType as String)
    }
    
    func setupPowerSourceChangedNotification(handler: @escaping PowerSourceChangeHandler) throws {
        guard powerSourceChangedNotification == nil else {
            powerSourceChangeHandler = handler
            return //nothing to setup, just change handler
        }
        
        //create a context that has a reference to "self", because it's the only way to refer to self inside the power source changed notification closure...
        let context = Unmanaged.passRetained(self).toOpaque()
        
        guard let runLoopSource = IOPSCreateLimitedPowerNotification({ (context) in
            guard let context = context else {
                return
            }
            let contextSelf = Unmanaged<PowerManager>.fromOpaque(context).takeUnretainedValue()
            
            contextSelf.powerSourceDidChanged()
            
        }, context) else {
            //error setting up power source change notification -> can not work!
            throw PowerError.cannotSetupPowerObserver
        }
        
        powerSourceChangedNotification = runLoopSource.takeRetainedValue() //store runloop source
        
        powerSourceChangeHandler = handler //store handler
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSourceChangedNotification, .defaultMode) //add observer to runloop
    }
    
    func removePowerSourceChangedNotification() {
        guard let runLoopSource = powerSourceChangedNotification else {
            return //no notification to remove
        }
        //remove from run loop
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        //free memory
        powerSourceChangedNotification = nil //setting nil is enough, because this variable was the "owner" of the above runLoopSource's opaque pointer, because it was assigned with a takeRetainedValue
        Unmanaged.passUnretained(self).release() //release context
        
        powerSourceChangeHandler = nil //reset handler
    }
    
    func powerSourceDidChanged() {
        //call handler with current power source
        powerSourceChangeHandler?(currentPowerSource())
    }
    
}


//MARK: - custom types
extension PowerManager {
    ///A high level abstraction for power source from apple's more low level APIs
    enum PowerSource {
        init(identifier: String) {
            switch identifier {
            case kIOPMACPowerKey, kIOPMUPSPowerKey:
                self = .externalUnlimited
            case kIOPMBatteryPowerKey:
                self = .internalBattery
            default:
                self = .unknown
            }
        }
        
        ///corresponds to kIOPMACPowerKey
        case externalUnlimited
        ///corresponds to kIOPMBatteryPowerKey
        case internalBattery
        ///corresponds to kIOPMUPSPowerKey
        ///UPS source (i. e. Uninterruptible Power Supply)
        case externalUPSPowerSource
        
        case unknown
        
        ///True, whether connected to a power source
        var isACPower: Bool {
            return [PowerSource.externalUnlimited, PowerSource.externalUPSPowerSource].contains(self)
        }
    }
    
    enum PowerError: Error {
        case cannotSetupPowerObserver
    }
}
