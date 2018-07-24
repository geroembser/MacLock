//
//  Audio.m
//  MacLock
//
//  Created by Gero Embser on 22.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

//Here, we can write some c++ CoreAudio Helper functions (if we like....)

Float32 GetVolumeScalar(AudioDeviceID inDevice, bool inIsInput, UInt32 inChannel)
{
    Float32 theAnswer = 0;
    UInt32 theSize = sizeof(Float32);
    AudioObjectPropertyScope theScope = inIsInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput;
    AudioObjectPropertyAddress theAddress = { kAudioDevicePropertyVolumeScalar,
        theScope,
        inChannel };
    
    OSStatus theError = AudioObjectGetPropertyData(inDevice,
                                                   &theAddress,
                                                   0,
                                                   NULL,
                                                   &theSize,
                                                   &theAnswer);
    // handle errors
    NSLog(@"error: %i", theError);
    
    return theAnswer;
}

AudioDeviceID GetDefaultOutputDevice()
{
    AudioDeviceID theAnswer = 0;
    UInt32 theSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };
    
    OSStatus theError = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                   &theAddress,
                                                   0,
                                                   NULL,
                                                   &theSize,
                                                   &theAnswer);
    // handle errors
    if (theError != kAudioHardwareNoError) {
        // do something...
    }
    
    return theAnswer;
}

AudioDeviceID GetDefaultInputDevice()
{
    AudioDeviceID theAnswer = 0;
    UInt32 theSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };
    
    OSStatus theError = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                   &theAddress,
                                                   0,
                                                   NULL,
                                                   &theSize,
                                                   &theAnswer);
    // handle errors
    if (theError != kAudioHardwareNoError) {
        // do something...
    }
    
    return theAnswer;
}
