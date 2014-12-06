//
//  MidiMeasure.m
//  Staff Master
//
//  Created by Taylor Moss on 11/19/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import "MidiMeasure.h"

@implementation MidiMeasure


@synthesize startTime;  //measure start time in microseconds
@synthesize duration;   //measure duration in microseconds
@synthesize notes;

- (id)initWithStartTime:(int)start andMeasureLength:(int)length {
    startTime = start;
    duration = length;
    notes = [[NSMutableArray alloc] init];
    return self;
    
}
@end
