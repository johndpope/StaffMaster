//
//  BAudioController.m
//  CoreAudio Starter Kit
//
//  Created by Ben Smiley-Andrews on 28/01/2013.
//  Copyright (c) 2013 Ben Smiley-Andrews. All rights reserved.
//

#import "AudioUtility.h"
//#import "UIKit/UIKit.h"

@implementation BAudioController

#define bSampleRate 44100.0

-(id) init {
    if((self = [super init])) {
        
        NewAUGraph(&audioGraph);
        
        AudioComponentDescription cd;
        AUNode outputNode;
        
        cd.componentManufacturer = kAudioUnitManufacturer_Apple;
        cd.componentFlags = 0;
        cd.componentFlagsMask = 0;
        cd.componentType = kAudioUnitType_Output;
        cd.componentSubType = kAudioUnitSubType_DefaultOutput;
        
        
        AUGraphAddNode(audioGraph, &cd, &outputNode);
        
        AUGraphNodeInfo(audioGraph, outputNode, &cd, &outputUnit);
        
        AUNode mixerNode;
        
        cd.componentManufacturer = kAudioUnitManufacturer_Apple;
        cd.componentFlags = 0;
        cd.componentFlagsMask = 0;
        cd.componentType = kAudioUnitType_Mixer;
        cd.componentSubType = kAudioUnitSubType_StereoMixer;
        
        AUGraphAddNode(audioGraph, &cd, &mixerNode);
        AUGraphNodeInfo(audioGraph, mixerNode, &cd, &mixerUnit);
        
        AUGraphConnectNodeInput(audioGraph, mixerNode, 0, outputNode, 0);
        
        AUGraphOpen(audioGraph);
        AUGraphInitialize(audioGraph);
        AUGraphStart(audioGraph);
        
        AUNode synthNode;
        
        
        cd.componentManufacturer = kAudioUnitManufacturer_Apple;
        cd.componentFlags = 0;
        cd.componentFlagsMask = 0;
        cd.componentType = kAudioUnitType_MusicDevice;
        cd.componentSubType = kAudioUnitSubType_DLSSynth;
        
        AUGraphAddNode(audioGraph, &cd, &synthNode);
        AUGraphNodeInfo(audioGraph, synthNode, &cd, &synthUnit);
        
        AUGraphConnectNodeInput(audioGraph, synthNode, 0, mixerNode, 0);
        
        AUGraphUpdate(audioGraph, NULL);
        CAShow(audioGraph);
        
    }
    return self;
}

-(void) setInputVolume: (Float32) volume withBus: (AudioUnitElement) bus {
    OSStatus result = AudioUnitSetParameter(mixerUnit,
                                     kMultiChannelMixerParam_Volume,
                                     kAudioUnitScope_Input,
                                     bus,
                                     volume, 0);
    NSAssert (result == noErr, @"Unable to set mixer input volume. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

-(void) loadSoundFont: (NSString*) path withPatch: (int) patch withBank: (UInt8) bank withSampler: (AudioUnit) sampler {
        
    NSLog(@"Sound font: %@", path);
    
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:path ofType:@"sf2"]];
    [self loadFromDLSOrSoundFont: (NSURL *)presetURL withBank: bank withPatch: patch  withSampler:sampler];
    [presetURL relativePath];
}
        
// Load a SoundFont into a sampler
-(OSStatus) loadFromDLSOrSoundFont: (NSURL *)bankURL withBank: (UInt8) bank withPatch: (int)presetNumber withSampler: (AudioUnit) sampler {
    OSStatus result = noErr;
    
    // fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef)(bankURL);
    bpdata.bankMSB  = bank;
    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
    bpdata.presetID = (UInt8) presetNumber;
    
    // set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(sampler,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    
    // check for errors
    NSCAssert (result == noErr,
               @"Unable to set the preset property on the Sampler. Error code:%d '%.4s'",
               (int) result,
               (const char *)&result);
    
    return result;
}


-(void) noteOn:(Byte)note withVelociy:(UInt32)velocity
{
    MusicDeviceMIDIEvent(synthUnit, 0x90, note,  velocity, 0);
}
-(void) noteOff:(Byte)note {
    MusicDeviceMIDIEvent(synthUnit, 0x80, note, 0, 0);
}



@end
