/*
 * Copyright (c) 2007-2011 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSException.h>

#import "Array.h"
#import "TimeSignature.h"
#import "MidiNote.h"
#import "MidiMeasure.h"
int sortbynote(void* note1, void* note2);
int sortbytime(void* note1, void* note2);

@interface MidiTrack : NSObject{
    int number;            /** The track number */
    Array* notes;          /** Array of Midi notes */
    NSMutableArray* measures;
    int instrument;        /** Instrument for this track */
    Array* lyrics;         /** The lyrics in this track */
}

@property (nonatomic, assign) int number;
@property (nonatomic, readonly) Array *notes;
@property (nonatomic, readonly) NSMutableArray *measures;
@property (nonatomic, assign) int instrument;
@property (nonatomic, retain) Array *lyrics;

-(id)initWithEvents:(Array*)events andTrack:(int)tracknum andKey:(int)keySignature andPPUS:(float)ppus andTempo:(int)tempo andNumerator:(int)numer;
-(void)addNote:(MidiNote *)m;
-(void)noteOffWithChannel:(int)channel andNumber:(int)num andTime:(int)endtime;
-(bool)decideToShowAccidental:(MidiMeasure*)measure withNote:(MidiNote*)currentNote;

@end

