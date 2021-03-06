//
//  BAudioController.h
//  CoreAudio Starter Kit
//
//  Created by Ben Smiley-Andrews on 28/01/2013.
//  Copyright (c) 2013 Ben Smiley-Andrews. All rights reserved.
//

#import <AudioToolbox/MusicPlayer.h>
#import <AVFoundation/AVFoundation.h>


@interface BAudioController : NSObject  {
    
    AUGraph audioGraph;
    AudioUnit synthUnit;
    AudioUnit synthUnitFile;
    AudioUnit mixerUnit;
    AudioUnit outputUnit;

    
}


-(void) setInputVolume: (Float32) volume withBus: (AudioUnitElement) bus;
-(void) noteOn:(Byte)note withVelocity:(UInt32)velocity;
-(void) noteOff:(Byte)note;
-(void) noteOnFile:(Byte)note withVelocity:(UInt32)velocity;
-(void) noteOffFile:(Byte)note;
@end
