//
//  MIDIUtility.h
//  MIDIExplore
//
//  Created by Taylor Moss on 11/8/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MIDIUtility : NSObject

@property (nonatomic, readwrite) Byte midiNote;


+(void)setupDevice;

@end
