//
//  MidiMeasure.h
//  Staff Master
//
//  Created by Taylor Moss on 11/19/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MidiMeasure : NSObject

//values are in microseconds
@property (nonatomic, assign) int startTime;    //measure start time in microseconds
@property (nonatomic, assign) int duration;     //measure duration in microseconds
@property (nonatomic, readonly) NSMutableArray *notes;

- (id)initWithStartTime:(int)start andMeasureLength:(int)length;

@end
