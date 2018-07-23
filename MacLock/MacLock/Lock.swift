//
//  Lock.swift
//  MacLock
//
//  Created by Gero Embser on 17.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation
import Cocoa

class Lock {
    private let pm = PowerManager()
    private let am = AudioManager()
    
    private var locked: Bool = false
    var isLocked: Bool { return locked }
    
    private var screenUnlockNotification: NSObjectProtocol?
    
    ///A configuration of the audio output which is stored when locked and re-applied after unlock
    private var storedAudioOutputConfiguration: AudioManager.AudioOutputConfiguration?
    
    private var alarmSound: NSSound?
}

//MARK: - Locking
extension Lock {
    func lock() throws {
        //lock is only possible, if mac is AC powered
        guard pm.currentPowerSource().isACPower else {
            throw LockError.acPowerNotConnected
        }
        
        //prevent sleeping
        try preventSleep()
        
        //observe power source changes
        try pm.setupPowerSourceChangedNotification(){ [unowned self] (newPowerSource) in
            guard !newPowerSource.isACPower else {
                return //that's fine... 😡
            }
            //alarm!!!
            self.alarm()
        }
        
        //set lock to true
        locked = true
        
        //start observing for unlock events
        startObservingUnlock()
        
        //lock Mac
        macos.lockByShowingLockscreen()
        
        //save audio output configuration
        saveAudioOutputConfiguration()
        
        //mute current audio output (like in sleep mode)
        am.muteCurrentAudioOutput()
    }
    
    func unlock() throws {
        guard isLocked else {
            return //nothing to unlock
        }
        
        //disable disable-sleep
        try enableSleep()
        
        //stop alarm
        stopAlarm()
        
        //unlock
        locked = false
        
        //restore previous audio output configuration
        reapplyAudioOutputConfiguration()
    }
}

extension Lock {
    ///An error that can occur if device is locked
    enum LockError: Error {
        case acPowerNotConnected
    }
}

//MARK: - prevent sleep (when charging!)
extension Lock {
    private func preventSleep() throws {
        try pm.enableSleep(false)
    }
    private func enableSleep() throws {
        try pm.enableSleep(true)
    }
}

//MARK: - unlock notifications
extension Lock {
    private func startObservingUnlock() {
        screenUnlockNotification = DistributedNotificationCenter.default().addObserver(forName: Notification.Name("com.apple.screenIsUnlocked") , object: nil, queue: .main) { [unowned self] (notification) in
            try? self.unlock()
        }
    }
    private func endObservingUnlock() {
        guard let observer = screenUnlockNotification else {
            return
        }
        
        DistributedNotificationCenter.default().removeObserver(observer)
    }
}

//MARK: - alarm handling
extension Lock {
    private func alarm() {
        print("\u{001B}[0;31mALAAAAAARM!!!!!") //print RED alarm! (if in Terminal...)
        
        //play alarm
        playAlarm()
    }
    
    private func playAlarm() {
        //switch audio to internal audio (if not already internal audio for ALL sounds)...
        if !am.allSoundsPlayingThroughInternalOutput {
            try! am.turnOnInternalOutputForAllSounds()
        }
        //unmute internal audio
        am.unmuteCurrentAudioOutput()
        
        //highest volume
        am.maximizeVolumeForCurrentAudioOutput()
        
        alarmSound = NSSound(named: "Basso.aiff")
        alarmSound?.loops = true
        alarmSound?.play()
    }
    
    private func stopAlarm() {
        alarmSound?.stop()
    }
}


//MARK: - sound stuff
extension Lock {
    ///Saves the audio output configuration
    func saveAudioOutputConfiguration() {
        storedAudioOutputConfiguration = am.currentOutputConfiguration
    }
    
    /// - Returns: True if apply the output configuration was successful, otherwise false
    @discardableResult
    func reapplyAudioOutputConfiguration() -> Bool {
        guard let config = storedAudioOutputConfiguration else {
            return false //nothing to apply
        }
        
        //apply...
        do {
            try am.apply(outputConfiguration: config) //if failed, just don't apply the configuration
        }
        catch {
            return false
        }
        
        //delete the stored audio output configuration
        storedAudioOutputConfiguration = nil
        
        return true
    }
}
