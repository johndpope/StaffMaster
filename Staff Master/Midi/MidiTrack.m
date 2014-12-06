/*
 * Copyright (c) 2007-2012 Madhav Vaidyanathan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#import "MidiFile.h"
#import "MidiTrack.h"
#import <Foundation/NSAutoreleasePool.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <assert.h>
#include <stdio.h>
#include <sys/stat.h>
#include <math.h>
#include "MidiMeasure.h"
/** Compare two MidiNotes based on their start times.
 *  If the start times are equal, compare by their numbers.
 *  Used by the C mergesort function.
 */
//int sortbytime(void* v1, void* v2) {
//    MidiNote **m1 = (MidiNote**) v1;
//    MidiNote **m2 = (MidiNote**) v2;
//    MidiNote *note1 = *m1;
//    MidiNote *note2 = *m2;
//
//    if (note1.startTime == note2.startTime) {
//        return note1.number - note2.number;
//    }
//    else {
//        return note1.startTime - note2.startTime;
//    }
//}


/** @class MidiTrack
 * The MidiTrack takes as input the raw MidiEvents for the track, and gets:
 * - The list of midi notes in the track.
 * - The first instrument used in the track.
 *
 * For each NoteOn event in the midi file, a new MidiNote is created
 * and added to the track, using the AddNote() method.
 * 
 * The NoteOff() method is called when a NoteOff event is encountered,
 * in order to update the duration of the MidiNote.
 */ 
@implementation MidiTrack

@synthesize number;
@synthesize notes;
@synthesize measures;
@synthesize instrument;
@synthesize lyrics;

float pulsesPerMicrosecond;


/** Create a MidiTrack based on the Midi events.  Extract the NoteOn/NoteOff
 *  events to gather the list of MidiNotes.
 */
- (id)initWithEvents:(Array*)list andTrack:(int)num andKey:(int)keySignature andPPUS:(float)ppus andTempo:(int)tempo andNumerator:(int)numer{
    number = num;
    notes = [Array new:100];
    pulsesPerMicrosecond = ppus;
    
    instrument = 0;
    NSString *clef = @"";
    if (num == 1) {
        clef = @"Treble";
    }
    else if (num == 2){
        clef = @"Bass";
    }
    
    //NSMutableArray *measures = [[NSMutableArray alloc]init];
    measures = [[NSMutableArray alloc]init];
    int measureLength = numer*tempo;
    MidiMeasure *measure = [[MidiMeasure alloc] initWithStartTime:0 andMeasureLength:measureLength];
    [measures addObject:measure];
    
    for (int i= 0;i < [list count]; i++) {
        MidiEvent *mevent = [list get:i];
        if (mevent.eventFlag == EventNoteOn && mevent.velocity > 0) {
            MidiNote *note = [[MidiNote alloc] initWithKey:keySignature andClef:clef];
            note.startTime = mevent.startTime;
            note.startTimeuS = mevent.startTime*(1.0/(pulsesPerMicrosecond)) + 1; //Add 1 to round precision errors.  Timer is not even precise enough to detect 1 uS differece.
            note.channel = mevent.channel;
            note.number = mevent.notenumber;
            note.velocity = mevent.velocity;
            note.name = [note name];
            note.normalState = [note normalState];
            note.isAccidental = [note isAccidental];
            note.ledgerLines = [note ledgerLinesFromNote:note.name andClef:clef];
            
            //NSLog(@"%i", note.number);
            
            while (note.startTimeuS >= measure.startTime + measure.duration) {
                measure = [[MidiMeasure alloc] initWithStartTime:(int)[measures count]*measureLength andMeasureLength:measureLength];
                [measures addObject:measure];
            }
            
            if (note.startTimeuS >= measure.startTime && note.startTimeuS < (measure.startTime + measure.duration))
            {
                
                
                note.showAccidental = [self decideToShowAccidental:measure withNote:note];
                [measure.notes addObject:note];
                //int index = (int)[measure.notes count];
                
                
            }
            
           
         
        }
        else if (mevent.eventFlag == EventNoteOn && mevent.velocity == 0) {
            [self noteOffWithChannel:mevent.channel andNumber:mevent.notenumber
                  andTime:mevent.startTime ];
        }
        else if (mevent.eventFlag == EventNoteOff) {
            [self noteOffWithChannel:mevent.channel andNumber:mevent.notenumber
                  andTime:mevent.startTime ];
        }
        else if (mevent.eventFlag == EventProgramChange) {
            instrument = mevent.instrument;
        }
        
    }
    if ([notes count] > 0 && [(MidiNote*)[notes get:0] channel] == 9) {
        instrument = 128;  /* Percussion */
    }
    return self;
}


- (void)dealloc {
    notes = nil;
    lyrics = nil;
}


/** Add a MidiNote to this track.  This is called for each NoteOn event */
- (void)addNote:(MidiNote*)m {
    [notes add:m];
}

/** A NoteOff event occured.  Find the MidiNote of the corresponding
 * NoteOn event, and update the duration of the MidiNote.
 */
- (void)noteOffWithChannel:(int)channel andNumber:(int)num andTime:(int)endtime{

    
    for (int measureNum = 0; measureNum < [measures count]; measureNum++) {
        MidiMeasure* measure = measures[measureNum];
        
        for (int i = 0; i < [measure.notes count]; i++)
        {
            MidiNote* note = measure.notes[i];
            if (note.channel == channel && note.number == num &&
                note.duration == 0) {
                [note noteOff:endtime];
                [note noteOffuS: endtime*(1.0/(pulsesPerMicrosecond))];
                return;
            }
        }
    }
    
}

-(bool)decideToShowAccidental:(MidiMeasure*)measure withNote:(MidiNote*)currentNote {
    
    bool showAccidental;
    MidiNote* previousNote;

    if (currentNote.isAccidental) {
         showAccidental = YES;
        if ([measure.notes count] > 0) {
            int i =(int)[measure.notes count] - 1;
            while((previousNote.name != currentNote.name) && i >= 0){
                previousNote = measure.notes[i];
            
                if (previousNote.name == currentNote.name) {
                    if(currentNote.number == previousNote.number)
                    {
                        showAccidental = NO;
                    }
                    else
                    {
                        showAccidental = YES;
                        break;
                    }
                }
                i--;
            };
        }
    }
    else
    {
        showAccidental = NO;
        if ([measure.notes count] > 0) {
            int i =(int)[measure.notes count] - 1;
            do{
                previousNote = measure.notes[i];
                
                if (previousNote.name == currentNote.name) {
                    if(currentNote.number == previousNote.number)
                    {
                        showAccidental = NO;
                    }
                    else
                    {
                        showAccidental = YES;
                        break;
                    }
                }
                
                
                i--;
            }while((previousNote.name != currentNote.name) && i >= 0);
        }
    }
    
    return showAccidental;
    
    
    
}

- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                      @"Track number=%d instrument=%d\n", number, instrument];
    for (int i = 0; i < [notes count]; i++) {
        MidiNote *m = [notes get:i];
        s = [s stringByAppendingString:[m description]];
        s = [s stringByAppendingString:@"\n"];
    }
    s = [s stringByAppendingString:@"End Track\n"];
    return s;
}


@end /* class MidiTrack */

