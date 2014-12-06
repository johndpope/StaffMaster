//
//  MIDIUtility.h
//  MIDIExplore
//
//  Created by Taylor Moss on 11/8/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIUtility : NSObject

@property (nonatomic, readwrite) Byte midiNote;


+(void)setupDeviceWithCallBack:(MIDIReadProc)callback;
+(void)processMessage: (const MIDIPacketList*) list;
+(int)getNoteNumber:(const MIDIPacketList *)list;
+(unsigned char)getMessageType:(const MIDIPacketList *)list;
@end
