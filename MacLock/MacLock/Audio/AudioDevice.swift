//
//  AudioDevice.swift
//  MacLock
//
//  Created by Gero Embser on 23.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation
import CoreAudio

//MARK: - instance stuff
struct AudioDevice {
    let deviceID: AudioDeviceID
    let deviceName: String?
    
    init(withDeviceID deviceID: AudioDeviceID) {
        self.deviceID = deviceID
        self.deviceName = try? AudioDevice.getDeviceName(forDeviceWithID: deviceID)
    }
}

//MARK: - input/output
extension AudioDevice {
    var outputChannelCount: Int {
        return (try? AudioDevice.getOutputChannelCount(forDeviceWithID: deviceID)) ?? 0
    }
    var inputChannelCount: Int {
        return (try? AudioDevice.getInputChannelCount(forDeviceWithID: deviceID)) ?? 0
    }
    
    var isInputDevice: Bool {
        return inputChannelCount > 0
    }
    
    var isOutputDevice: Bool {
        return outputChannelCount > 0
    }
}

//MARK: - equatable (devices identify itself via their deviceID
extension AudioDevice: Equatable {
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.deviceID == rhs.deviceID
    }
}

//MARK: - controlling volume
//MARK: channels
extension AudioDevice {
    ///if available, two channels, left and right (first element -> left, second element -> right)
    var outputStereoChannels: [UInt32]? {
        var channelPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyPreferredChannelsForStereo, mScope: kAudioDevicePropertyScopeOutput , mElement: kAudioObjectPropertyElementMaster)
        
        var channels: [UInt32] = Array(repeating: 0, count: 2)
        var propertySize = UInt32(MemoryLayout.size(ofValue: channels))
        
        do {
            try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &channelPropertyAddress, 0, nil, &propertySize, &channels))
            
            return channels
        }
        catch {
            return nil
        }
    }
    var outputStereoChannelLeft: UInt32? {
        return outputStereoChannels?[safe:0]
    }
    var outputStereoChannelRight: UInt32? {
        return outputStereoChannels?[safe:1]
    }
}

//MARK: volume
extension AudioDevice {
    func getOutputVolume(forChannel channel: UInt32) throws -> Float {
        var volumePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: kAudioDevicePropertyScopeOutput, mElement: channel)
        
        var volume: Float32 = 0
        var propertySize = UInt32(MemoryLayout.size(ofValue: volume))
        
        
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &volumePropertyAddress, 0, nil, &propertySize, &volume))
        
        return volume
    }
    
    func setOutputVolume(to newVolume: Float, forChannel channel: UInt32) throws {
        var newVolume = (0.0 ... 1.0).clamp(newVolume) //allowed range of volumes
        
        var volumePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar, mScope: kAudioDevicePropertyScopeOutput, mElement: channel)
        
        newVolume = Float32(newVolume)
        let propertySize = UInt32(MemoryLayout.size(ofValue: newVolume))
        
        try handlePossibleError(forStatusCode: AudioObjectSetPropertyData(deviceID, &volumePropertyAddress, 0, nil, propertySize, &newVolume))
    }
    
    var outputVolumeLeft: Float? {
        guard let leftChannel = outputStereoChannelLeft else {
            return nil
        }
        
        return try? getOutputVolume(forChannel: leftChannel)
    }
    var outputVolumeRight: Float? {
        guard let rightChannel = outputStereoChannelRight else {
            return nil
        }
        
        return try? getOutputVolume(forChannel: rightChannel)
    }
    var outputVolumeMaster: Float? {
        return try? getOutputVolume(forChannel: kAudioObjectPropertyElementMaster) //0 as master channel
    }
    
    struct StereoVolume: Equatable {
        let left: Float
        let right: Float
    }
    var outputVolumeStereo: StereoVolume? {
        guard let left = outputVolumeLeft, let right = outputVolumeRight else {
            return nil
        }
        
        return StereoVolume(left: left, right: right)
    }
    func set(outputVolumeStereo newStereoVolume: StereoVolume) throws {
        guard let leftChannel = outputStereoChannelLeft,
            let rightChannel = outputStereoChannelRight else {
                throw AudioDeviceError.steoreoUnavailable
        }
        
        try setOutputVolume(to: newStereoVolume.left, forChannel: leftChannel)
        try setOutputVolume(to: newStereoVolume.right, forChannel: rightChannel)
    }
    
    ///just for convenience in some situation (primarily during debugging)
    ///combines left and right output volume
    ///if nil, left and right volume differ
    var outputVolumeGeneral: Float? {
        if outputVolumeRight == outputVolumeLeft {
            return outputVolumeLeft
        }
        
        return nil
    }
    func setOutputVolumeLeftAndRightSimultaneously(to newVolume: Float) throws {
        try set(outputVolumeStereo: StereoVolume(left: newVolume, right: newVolume))
    }
}

//MARK: mute/unmute
extension AudioDevice {
    ///Returns a new instance of a mute property address
    private func getNewMutePropertyAddress() -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
    }
    var mute: Bool {
        var mutePropertyAddress = getNewMutePropertyAddress()
        
        var mute: UInt32 = 1 //everything else by default muted
        var propertySize = UInt32(MemoryLayout.size(ofValue: mute))
        
        _ = AudioObjectGetPropertyData(deviceID, &mutePropertyAddress, 0, nil, &propertySize, &mute)
        
        return mute == 0 ? false : true
    }
    
    func mute(on mute: Bool) throws {
        var mutePropertyAddress = getNewMutePropertyAddress()
        
        var mute: UInt32 = mute ? 1 : 0
        let propertySize = UInt32(MemoryLayout.size(ofValue: mute))
        
        try handlePossibleError(forStatusCode: AudioObjectSetPropertyData(deviceID, &mutePropertyAddress, 0, nil, propertySize, &mute))
    }
}


//MARK: - jack connection
extension AudioDevice {
    private func getNewJackPropertyAddress() -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyJackIsConnected, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
    }
    var jackIsConnected: Bool {
        var mutePropertyAddress = getNewJackPropertyAddress()
        
        var jackConnected: UInt32 = 0 //everything else: by default not connected
        var propertySize = UInt32(MemoryLayout.size(ofValue: jackConnected))
        
        _ = AudioObjectGetPropertyData(deviceID, &mutePropertyAddress, 0, nil, &propertySize, &jackConnected)
        
        return jackConnected == 0 ? false : true
    }
    //DOES NOT WORK -> THIS PROPERTY IS NOT WRITABLE
//    func playThroughJack(_ jackOn: Bool) throws {
//        var mutePropertyAddress = getNewJackPropertyAddress()
//
//        var jackConnected: UInt32 = jackOn ? 1 : 0
//        let propertySize = UInt32(MemoryLayout.size(ofValue: jackConnected))
//
//        try handlePossibleError(forStatusCode: AudioObjectSetPropertyData(deviceID, &mutePropertyAddress, 0, nil, propertySize, &jackConnected))
//    }
}

extension AudioDevice {
    enum Kind {
        case builtIn
        case unknown
    }
    var type: AudioDevice.Kind {
        switch deviceName {
        case "Built-in Output":
            return .builtIn
        default:
            return .unknown
        }
    }
}

//MARK: - convenience class methods for accessing properties of AudioDevices via AudioDeviceID's
extension AudioDevice {
    static func getDeviceName(forDeviceWithID deviceID: AudioDeviceID) throws -> String {
        var deviceNamePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        
        var name = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.stride)
        
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &deviceNamePropertyAddress, 0, nil, &propertySize, &name))
        
        return name as String
    }
    
    static func getInputChannelCount(forDeviceWithID deviceID: AudioDeviceID) throws -> Int {
        return try getNumberOfChannels(ofDeviceWithID: deviceID, inScope: kAudioDevicePropertyScopeInput)
    }
    static func getOutputChannelCount(forDeviceWithID deviceID: AudioDeviceID) throws -> Int {
        return try getNumberOfChannels(ofDeviceWithID: deviceID, inScope: kAudioDevicePropertyScopeOutput)
    }
    
    static func getAudioBufferList(ofDevice deviceID: AudioDeviceID, forScope scope: AudioObjectPropertyScope) throws -> UnsafeMutableAudioBufferListPointer {
        var streamConfigurationAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: scope, mElement: kAudioObjectPropertyElementMaster)
        
        var propertySize: UInt32 = 0
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyDataSize(deviceID, &streamConfigurationAddress, 0, nil, &propertySize))
        
        //create buffer
        let audioBufferList = AudioBufferList.allocate(maximumBuffers: Int(propertySize))
        try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &streamConfigurationAddress, 0, nil, &propertySize, audioBufferList.unsafeMutablePointer))
        
        return audioBufferList
    }
    static func getNumberOfChannels(ofDeviceWithID deviceID: AudioDeviceID, inScope scope: AudioObjectPropertyScope) throws -> Int {
        let bufferList = try getAudioBufferList(ofDevice: deviceID, forScope: scope)
        
        let numberOfChannels: Int = bufferList.reduce(0) { $0+Int($1.mNumberChannels) }
        
        return numberOfChannels
    }
}

//MARK: - device state
extension AudioDevice {
    ///encapsules and stores state of the device with a specific configuration
    struct State: Equatable {
        let deviceID: AudioDeviceID
        let deviceName: String?
        let volume: StereoVolume?
        let mute: Bool
        let kind: Kind
        
        ///Returns the AudioDevice to which the state was related to
        var device: AudioDevice {
            return AudioDevice(withDeviceID: deviceID)
        }
    }
    
    func getState() -> State {
        return State(deviceID: deviceID, deviceName: deviceName, volume: outputVolumeStereo, mute: mute, kind: type)
    }
    
    func apply(state: State) throws {
        if let volume = state.volume {
            try set(outputVolumeStereo: volume)
        }
        
        try mute(on: state.mute)
    }
}



//MARK: - simplify error handling
extension AudioDevice: AudioErrorHandling {}

extension AudioDevice {
    enum AudioDeviceError: Error {
        case steoreoUnavailable
    }
}




// I don't know what this does, if it does something...
/*extension AudioDevice {
 var dataSources: [UInt32]? {
 var dataSourcesPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDataSources, mScope: kAudioDevicePropertyScopeOutput , mElement: kAudioObjectPropertyElementMaster)
 
 var dataSources: [UInt32] = Array(repeating: 0, count: 2)
 var propertySize = UInt32(MemoryLayout.size(ofValue: dataSources))
 
 do {
 try handlePossibleError(forStatusCode: AudioObjectGetPropertyData(deviceID, &dataSourcesPropertyAddress, 0, nil, &propertySize, &dataSources))
 
 return dataSources
 }
 catch {
 return nil
 }
 }
 }*/
