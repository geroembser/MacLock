//
//  AudioManager.swift
//  MacLock
//
//  Created by Gero Embser on 22.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation
import CoreAudio

class AudioManager {
    //MARK: - instance variables
    let systemAudioObject = AudioObjectID(kAudioObjectSystemObject)
    
    ///Stores a previous sound output configuration (important for switch sound output methods
    private var previousOutputConfiguration: AudioOutputConfiguration?
}

//MARK: - getting devices
extension AudioManager {
    func getAllDeviceIDs() throws -> [AudioDeviceID] {
        //create a property-address/query that defines which things to query
        var devicesPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        
        
        //get the size of the property if queried/addressed
        var propertySize: UInt32 = 0
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyDataSize(systemAudioObject, &devicesPropertyAddress, 0, nil, &propertySize))
        
        //get number of devices
        let numberOfDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.stride
        
        //create result array
        var deviceIDs: [AudioDeviceID] = Array(repeating: AudioDeviceID(), count: numberOfDevices)
        
        //now, query all available devices (by really getting the data for the property
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(systemAudioObject, &devicesPropertyAddress, 0, nil, &propertySize, &deviceIDs))
        
        return deviceIDs
    }
    var allDevices: [AudioDevice] {
        guard let allDeviceIDs = try? getAllDeviceIDs() else {
            return []
        }
        
        return allDeviceIDs.map { AudioDevice(withDeviceID: $0) }
    }
    
    var outputDevices: [AudioDevice] {
        return allDevices.filter { $0.isOutputDevice }
    }
    var inputDevices: [AudioDevice] {
        return allDevices.filter { $0.isInputDevice }
    }
    
    
    var hasInternalOutput: Bool { return internalOutput != nil }
    var internalOutput: AudioDevice? {
        return outputDevices.first { $0.type == .builtIn }
    }
}

//MARK: - changing default output device for sound
extension AudioManager {
    private func getNewDefaultOutputDevicePropertyAddress(forSystemSounds systemSounds: Bool) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(mSelector: systemSounds ? kAudioHardwarePropertyDefaultSystemOutputDevice : kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
    }
    
    func getDefaultOutputDevice(forSystemSounds systemSounds: Bool) -> AudioDevice? {
        var propertyAddress = getNewDefaultOutputDevicePropertyAddress(forSystemSounds: systemSounds)
        
        var defaultOutputDeviceID: UInt32 = 0
        var propertySize = UInt32(MemoryLayout.size(ofValue:defaultOutputDeviceID))
        
        do {
            try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(systemAudioObject, &propertyAddress, 0, nil, &propertySize, &defaultOutputDeviceID))
            
            
            return AudioDevice(withDeviceID: defaultOutputDeviceID)
        }
        catch {
            return nil //nil by default means no default output device (or any other error)
        }
    }
    
    func setDefaultOutputDevice(_ newOutputDevice: AudioDevice, forSystemSounds systemSounds: Bool) throws {
        var propertyAddress = getNewDefaultOutputDevicePropertyAddress(forSystemSounds: systemSounds)
        
        var newOutputDeviceID = newOutputDevice.deviceID
        let propertySize = UInt32(MemoryLayout.size(ofValue: newOutputDeviceID))
        
        try handlePossibleError(forStatusCode: AudioObjectSetPropertyData(systemAudioObject, &propertyAddress, 0, nil, propertySize, &newOutputDeviceID))
    }
    
    
    ///Turns on internal output
    func turnOnInternalOutputForAllSounds() throws {
        guard let internalOutput = internalOutput else {
            //no internal output available
            throw AudioManagerError.internalOutputUnavailable
        }
        try setDefaultOutputDevice(internalOutput, forSystemSounds: true)
        try setDefaultOutputDevice(internalOutput, forSystemSounds: false)
    }
    
    ///Turn on a (possibly) previoiusly stored sound configuration
    func turnOnPreviouslyStoredOutputConfiguration() throws {
        guard let soundConfig = previousOutputConfiguration else {
            return
        }
        
        try setDefaultOutputDevice(soundConfig.soundDeviceState.device, forSystemSounds: false)
        try setDefaultOutputDevice(soundConfig.systemSoundDeviceState.device, forSystemSounds: true)
    }
    
    ///Switches between internal output (for both system sound and other sounds) and (previously selected) (external/internal) output/sound configuration (if available and if it differs playing all sounds through internal output)
    func internalExternalOutputSwitch() throws {
        //make sure, we have an internal output
        guard internalOutput != nil else {
            throw AudioManagerError.internalOutputUnavailable
        }
        
        //if no current sound output configuration exists, turn on internal
        guard let currentOutputConfiguration = currentOutputConfiguration else {
            try turnOnInternalOutputForAllSounds()
            
            return //no need to save any previous configuration (because there was no one)
        }
        
        //if current output configuration is already internal for (system) sounds, turn on the previously stored configuration (if one exists, otherwise do nothing)
        if allSoundsPlayingThroughInternalOutput {
            //swith to previous output configuration
            try turnOnPreviouslyStoredOutputConfiguration()
        }
        else {
            //save current configuration as previous
            self.previousOutputConfiguration = currentOutputConfiguration
            
            //then! turn on internal output for all sounds
            try turnOnInternalOutputForAllSounds()
        }
    }
    
    ///Return true iff general sound output and system sound output both are internal output
    var allSoundsPlayingThroughInternalOutput: Bool {
        guard let currentOutputConfiguration = currentOutputConfiguration else {
            return false
        }
        
        guard hasInternalOutput else {
            return false
        }
        
        return currentOutputConfiguration.systemSoundDeviceState.kind == .builtIn && currentOutputConfiguration.soundDeviceState.kind == .builtIn
    }
}

//MARK: - default output related stuff
extension AudioManager {
    ///just mutes the current audio output (for all kind of sounds, system and all other sounds)
    func muteCurrentAudioOutput() {
        try? getDefaultOutputDevice(forSystemSounds: true)?.mute(on: true)
        try? getDefaultOutputDevice(forSystemSounds: false)?.mute(on: true)
    }
    ///just unmutes the current audio output (for all kind of sounds, system and all other sounds)
    func unmuteCurrentAudioOutput() {
        try? getDefaultOutputDevice(forSystemSounds: true)?.mute(on: false)
        try? getDefaultOutputDevice(forSystemSounds: false)?.mute(on: false)
    }
    func maximizeVolumeForCurrentAudioOutput() {
        try? getDefaultOutputDevice(forSystemSounds: true)?.setOutputVolumeLeftAndRightSimultaneously(to: 1.0)
        try? getDefaultOutputDevice(forSystemSounds: false)?.setOutputVolumeLeftAndRightSimultaneously(to: 1.0)
    }
}

//MARK: - audio configuration states
extension AudioManager {
    struct AudioOutputConfiguration: Equatable {
        let systemSoundDeviceState: AudioDevice.State
        let soundDeviceState: AudioDevice.State
    }
    
    ///Changes default output as the configuration states
    func apply(outputConfiguration: AudioOutputConfiguration) throws {
        let systemSoundDeviceState = outputConfiguration.systemSoundDeviceState
        let soundDeviceState = outputConfiguration.soundDeviceState
        
        try setDefaultOutputDevice(systemSoundDeviceState.device, forSystemSounds: true)
        try setDefaultOutputDevice(soundDeviceState.device, forSystemSounds: false)
        
        try systemSoundDeviceState.device.apply(state: systemSoundDeviceState)
        try soundDeviceState.device.apply(state: soundDeviceState)
    }
    
    ///Get the current output configuration (which can be later applied, if it is then still a valid configuration
    var currentOutputConfiguration: AudioOutputConfiguration? {
        guard let currentSystemSoundOutputDevice = getDefaultOutputDevice(forSystemSounds: true),
            let currentSoundOutputDevice = getDefaultOutputDevice(forSystemSounds: false) else {
                return nil
        }
        
        return AudioOutputConfiguration(systemSoundDeviceState: currentSystemSoundOutputDevice.getState(),
                                        soundDeviceState: currentSoundOutputDevice.getState())
    }
}

//MARK: - error handling
extension AudioManager: AudioErrorHandling {}

extension AudioManager {
    enum AudioManagerError: Error {
        case internalOutputUnavailable
    }
}
