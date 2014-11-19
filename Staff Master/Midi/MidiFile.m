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

/* This file contains the classes for parsing and modifying MIDI music files */

/* Midi file format.
 *
 * The Midi File format is described below.  The description uses
 * the following abbreviations.
 *
 * u1     - One byte
 * u2     - Two bytes (big endian)
 * u4     - Four bytes (big endian)
 * varlen - A variable length integer, that can be 1 to 4 bytes. The 
 *          integer ends when you encounter a byte that doesn't have 
 *          the 8th bit set (a byte less than 0x80).
 * len?   - The length of the data depends on some code
 *          
 *
 * The Midi files begins with the main Midi header
 * u4 = The four ascii characters 'MThd'
 * u4 = The length of the MThd header = 6 bytes
 * u2 = 0 if the file contains a single track
 *      1 if the file contains one or more simultaneous tracks
 *      2 if the file contains one or more independent tracks
 * u2 = number of tracks
 * u2 = if >  0, the number of pulses per quarter note
 *      if <= 0, then ???
 *
 * Next come the individual Midi tracks.  The total number of Midi
 * tracks was given above, in the MThd header.  Each track starts
 * with a header:
 *
 * u4 = The four ascii characters 'MTrk'
 * u4 = Amount of track data, in bytes.
 * 
 * The track data consists of a series of Midi events.  Each Midi event
 * has the following format:
 *
 * varlen  - The time between the previous event and this event, measured
 *           in "pulses".  The number of pulses per quarter note is given
 *           in the MThd header.
 * u1      - The Event code, always betwee 0x80 and 0xFF
 * len?    - The event data.  The length of this data is determined by the
 *           event code.  The first byte of the event data is always < 0x80.
 *
 * The event code is optional.  If the event code is missing, then it
 * defaults to the previous event code.  For example:
 *
 *   varlen, eventcode1, eventdata,
 *   varlen, eventcode2, eventdata,
 *   varlen, eventdata,  // eventcode is eventcode2
 *   varlen, eventdata,  // eventcode is eventcode2
 *   varlen, eventcode3, eventdata,
 *   ....
 *
 *   How do you know if the eventcode is there or missing? Well:
 *   - All event codes are between 0x80 and 0xFF
 *   - The first byte of eventdata is always less than 0x80.
 *   So, after the varlen delta time, if the next byte is between 0x80
 *   and 0xFF, its an event code.  Otherwise, its event data.
 *
 * The Event codes and event data for each event code are shown below.
 *
 * Code:  u1 - 0x80 thru 0x8F - Note Off event.
 *             0x80 is for channel 1, 0x8F is for channel 16.
 * Data:  u1 - The note number, 0-127.  Middle C is 60 (0x3C)
 *        u1 - The note velocity.  This should be 0
 * 
 * Code:  u1 - 0x90 thru 0x9F - Note On event.
 *             0x90 is for channel 1, 0x9F is for channel 16.
 * Data:  u1 - The note number, 0-127.  Middle C is 60 (0x3C)
 *        u1 - The note velocity, from 0 (no sound) to 127 (loud).
 *             A value of 0 is equivalent to a Note Off.
 *
 * Code:  u1 - 0xA0 thru 0xAF - Key Pressure
 * Data:  u1 - The note number, 0-127.
 *        u1 - The pressure.
 *
 * Code:  u1 - 0xB0 thru 0xBF - Control Change
 * Data:  u1 - The controller number
 *        u1 - The value
 *
 * Code:  u1 - 0xC0 thru 0xCF - Program Change
 * Data:  u1 - The program number.
 *
 * Code:  u1 - 0xD0 thru 0xDF - Channel Pressure
 *        u1 - The pressure.
 *
 * Code:  u1 - 0xE0 thru 0xEF - Pitch Bend
 * Data:  u2 - Some data
 *
 * Code:  u1     - 0xFF - Meta Event
 * Data:  u1     - Metacode
 *        varlen - Length of meta event
 *        u1[varlen] - Meta event data.
 *
 *
 * The Meta Event codes are listed below:
 *
 * Metacode: u1         - 0x0  Sequence Number
 *           varlen     - 0 or 2
 *           u1[varlen] - Sequence number
 *
 * Metacode: u1         - 0x1  Text
 *           varlen     - Length of text
 *           u1[varlen] - Text
 *
 * Metacode: u1         - 0x2  Copyright
 *           varlen     - Length of text
 *           u1[varlen] - Text
 *
 * Metacode: u1         - 0x3  Track Name
 *           varlen     - Length of name
 *           u1[varlen] - Track Name
 *
 * Metacode: u1         - 0x58  Time Signature
 *           varlen     - 4 
 *           u1         - numerator
 *           u1         - log2(denominator)
 *           u1         - clocks in metronome click
 *           u1         - 32nd notes in quarter note (usually 8)
 *
 * Metacode: u1         - 0x59  Key Signature
 *           varlen     - 2
 *           u1         - if >= 0, then number of sharps
 *                        if < 0, then number of flats * -1
 *           u1         - 0 if major key
 *                        1 if minor key
 *
 * Metacode: u1         - 0x51  Tempo
 *           varlen     - 3  
 *           u3         - quarter note length in microseconds
 */







/** @class MidiFile
 *
 * The MidiFile class contains the parsed data from the Midi File.
 * It contains:
 * - All the tracks in the midi file, including all MidiNotes per track.
 * - The time signature (e.g. 4/4, 3/4, 6/8)
 * - The number of pulses per quarter note.
 * - The tempo (number of microseconds per quarter note).
 *
 * The constructor takes a filename as input, and upon returning,
 * contains the parsed data from the midi file.
 *
 * The methods readTrack() and readMetaEvent() are helper functions called
 * by the constructor during the parsing.
 *
 * After the MidiFile is parsed and created, the user can retrieve the 
 * tracks and notes by using the method tracks and tracks.notes.
 *
 * There are two methods for modifying the midi data based on the menu
 * options selected:
 *
 * - changeMidiNotes()
 *   Apply the menu options to the parsed MidiFile.  This uses the helper functions:
 *     splitTrack()
 *     combineToTwoTracks()
 *     shiftTime()
 *     transpose()
 *     roundStartTimes()
 *     roundDurations()
 *
 * - changeSound()
 *   Apply the menu options to the MIDI music data, and save the modified midi data
 *   to a file, for playback.  This uses the helper functions:
 *     addTempoEvent()
 *     changeSoundPerChannel
 */

@implementation MidiFile

@synthesize tracks;
@synthesize time;
@synthesize filename;
@synthesize totalpulses;


/** Parse the given Midi file, and return an instance of this MidiFile
 * class.  After reading the midi file, this object will contain:
 * - The raw list of midi events
 * - The Time Signature of the song
 * - All the tracks in the song which contain notes. 
 * - The number, starttime, and duration of each note.
 */
- (id)initWithFile:(NSString*)path {
    const char *hdr;
    int len;

    filename = path;
    tracks = [Array new:5];
    trackPerChannel = NO;

    MidiFileReader *file = [[MidiFileReader alloc] initWithFile:filename];
    hdr = [file readAscii:4];
    if (strncmp(hdr, "MThd", 4) != 0) {
       
        MidiFileException *e =
           [MidiFileException init:@"Bad MThd header" offset:0];
        @throw e;
    }
    len = [file readInt];
    if (len !=  6) {
       
        MidiFileException *e =
           [MidiFileException init:@"Bad MThd len" offset:4];
        @throw e;
    }
    trackmode = [file readShort];
    int num_tracks = [file readShort];
    quarternote = [file readShort];


    events = [Array new:num_tracks] ;
    for (int tracknum = 0; tracknum < num_tracks; tracknum++) {
        
        Array *trackevents = [self readTrack:file];
        MidiTrack *track = 
          [[MidiTrack alloc] initWithEvents:trackevents andTrack:tracknum];
        [events add:trackevents];
        track.number = tracknum;
        if ([track.notes count] > 0) {
            [tracks add:track];
        }
        
        MidiNote *last = [track.notes get:([track.notes count] -1) ];
        if (totalpulses < last.startTime + last.duration) {
            totalpulses = last.startTime + last.duration;
        }
        
        
    }

    /* Get the length of the song in pulses */
//    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
//        MidiTrack *track = [tracks get:tracknum];
//        MidiNote *past = [track.notes get:([track.notes count] -1) ];
//        if (totalpulses < past.startTime + past.duration) {
//            totalpulses = past.startTime + past.duration;
//        }
//    }

    /* If we only have one track with multiple channels, then treat
     * each channel as a separate track.
     */
//    if ([tracks count] == 1 && [MidiFile hasMultipleChannels:[tracks get:0]]) {
//        MidiTrack *track = [tracks get:0];
//        Array *trackevents = [events get:track.number];
//        Array* newtracks = [MidiFile splitChannels:track withEvents:trackevents];
//        trackPerChannel = YES;
//      
//        tracks = newtracks;
//    }

    //[MidiFile checkStartTimes:tracks];

    /* Determine the time signature */
    int tempo = 0;
    int numer = 0;
    int denom = 0;
    for (int tracknum = 0; tracknum < [events count]; tracknum++) {
        Array *eventlist = [events get:tracknum];
        for (int i = 0; i < [eventlist count]; i++) {
            MidiEvent *mevent = [eventlist get:i];
            if (mevent.metaevent == MetaEventTempo && tempo == 0) {
                tempo = mevent.tempo;
            }
            if (mevent.metaevent == MetaEventTimeSignature && numer == 0) {
                numer = mevent.numerator;
                denom = mevent.denominator;
            }
        }
    }

    if (tempo == 0) {
        tempo = 500000; /* 500,000 microseconds = 0.05 sec */
    }
    if (numer == 0) {
        numer = 4; denom = 4;
    }
    time = [[TimeSignature alloc] initWithNumerator:numer
                     andDenominator:denom
                     andQuarter:quarternote
                     andTempo:tempo];
   
    double ppus= quarternote * (1.0/tempo);;
     for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
        
         [[self.tracks get:tracknum] setTimeWithPPUS:ppus andTotalPulses:totalpulses];
     }
    
    //MidiTrack *_track = [self combineToSingleTrack:tracks];
   
    //tracks = [Array new:1];
    //[tracks add:_track];
    
    return self;
}

- (void)dealloc {
    
}

/** Parse a single track into a list of MidiEvents.
 * Entering this function, the file offset should be at the start of
 * the MTrk header.  Upon exiting, the file offset should be at the
 * start of the next MTrk header.
 */
- (Array*)readTrack:(MidiFileReader*)file {
    Array *result = [Array new:20];
    int starttime = 0;
    const char *hdr = [file readAscii:4];

    if (strncmp(hdr, "MTrk", 4) != 0) {
        MidiFileException *e =
           [MidiFileException init:@"Bad MTrk header" offset:([file offset] -4)];
        @throw e;
    }
    int tracklen = [file readInt];
    int trackend = tracklen + [file offset];

    int eventflag = 0;

    while ([file offset] < trackend) {
        /* If the midi file is truncated here, we can still recover.
         * Just return what we've parsed so far.
         */
        int startoffset, deltatime;
        u_char peekevent;
        @try {
            startoffset = [file offset];
            deltatime = [file readVarlen];
            starttime += deltatime;
            peekevent = [file peek];
        }
        @catch (MidiFileException* e) {
            return result;
        } 

        MidiEvent *mevent = [[MidiEvent alloc] init];
        [result add:mevent];
        mevent.deltaTime = deltatime;
        mevent.startTime = starttime;

        if (peekevent >= EventNoteOff) {
            mevent.hasEventflag = YES;
            eventflag = [file readByte];
            /* printf("Read new event %d %s\n", eventflag, eventName(eventflag)); */
        }

        /**
        printf("offset %d:event %d %s delta %d\n",
               startoffset, eventflag, eventName(eventflag), [mevent deltatime]);
        **/

        if (eventflag >= EventNoteOn && eventflag < EventNoteOn + 16) {
            mevent.eventFlag = EventNoteOn;
            mevent.channel = (u_char)(eventflag - EventNoteOn);
            mevent.notenumber = [file readByte];
            mevent.velocity = [file readByte];
        }
        else if (eventflag >= EventNoteOff && eventflag < EventNoteOff + 16) {
            mevent.eventFlag = EventNoteOff;
            mevent.channel = (u_char)(eventflag - EventNoteOff);
            mevent.notenumber = [file readByte];
            mevent.velocity = [file readByte];
        }
        else if (eventflag >= EventKeyPressure && 
                 eventflag < EventKeyPressure + 16) {
            mevent.eventFlag = EventKeyPressure;
            mevent.channel = (u_char)(eventflag - EventKeyPressure);
            mevent.notenumber = [file readByte];
            mevent.keyPressure = [file readByte];
        }
        else if (eventflag >= EventControlChange && 
                 eventflag < EventControlChange + 16) {
            mevent.eventFlag = EventControlChange;
            mevent.channel = (u_char)(eventflag - EventControlChange);
            mevent.controlNum = [file readByte];
            mevent.controlValue = [file readByte];
        }
        else if (eventflag >= EventProgramChange && 
                 eventflag < EventProgramChange + 16) {
            mevent.eventFlag = EventProgramChange;
            mevent.channel = (u_char)(eventflag - EventProgramChange);
            mevent.instrument = [file readByte];
            
        }
        else if (eventflag >= EventChannelPressure && 
                 eventflag < EventChannelPressure + 16) {
            mevent.eventFlag = EventChannelPressure;
            mevent.channel = (u_char)(eventflag - EventChannelPressure);
            mevent.chanPressure = [file readByte];
        }
        else if (eventflag >= EventPitchBend && 
                 eventflag < EventPitchBend + 16) {
            mevent.eventFlag = EventPitchBend;
            mevent.channel = (u_char)(eventflag - EventPitchBend);
            mevent.pitchBend = [file readShort];
        }
        else if (eventflag == SysexEvent1) {
            mevent.eventFlag = SysexEvent1;
            mevent.metalength = [file readVarlen];
            mevent.metavalue = [file readBytes:mevent.metalength] ;
        }
        else if (eventflag == SysexEvent2) {
            mevent.eventFlag = SysexEvent2;
            mevent.metalength = [file readVarlen];
            mevent.metavalue = [file readBytes:mevent.metalength] ;
        }
        else if (eventflag == MetaEvent) {
            mevent.eventFlag = MetaEvent;
            mevent.metaevent = [file readByte];
            mevent.metalength = [file readVarlen];
            mevent.metavalue = [file readBytes:mevent.metalength] ;

            if (mevent.metaevent == MetaEventTimeSignature) {
                if (mevent.metalength < 2) {
                    MidiFileException *e = 
                    [MidiFileException init:@"Bad Meta Event Time Signature len" 
                      offset:[file offset]];
                    @throw e;
                }
                else if (mevent.metalength >= 2 && mevent.metalength < 4) {
                    mevent.numerator = mevent.metavalue[0] ;
                    u_char log2 = mevent.metavalue[1];
                    mevent.denominator = (int)pow(2, log2);
                }
                else {
                    mevent.numerator = mevent.metavalue[0] ;
                    u_char log2 = mevent.metavalue[1];
                    mevent.denominator = (int)pow(2, log2);
                }
            }
            else if (mevent.metaevent == MetaEventTempo) {
                if (mevent.metalength != 3) {
                    MidiFileException *e = 
                    [MidiFileException init:@"Bad Meta Event Tempo len" 
                      offset:[file offset]];
                    @throw e;
                }
                u_char *value = mevent.metavalue;
                mevent.tempo = ((value[0] << 16) | (value[1] << 8) | value[2]);
            }
            else if (mevent.metaevent == MetaEventEndOfTrack) {
             
                break; 
            }
        }
        else {
            /* printf("Unknown eventflag %d offset %d\n", eventflag, [file offset]); */
            MidiFileException *e =
                [MidiFileException init:@"Unknown event" offset:([file offset] -4)];
            @throw e;
        }
       
    }

    return result;
}




/* Split the given MidiTrack into two tracks, top and bottom.
 * The highest notes will go into top, the lowest into bottom.
 * This function is used to split piano songs into left-hand (bottom)
 * and right-hand (top) tracks.
 */
//+(Array*)splitTrack:(MidiTrack*) track withMeasure:(int)measurelen{
//    Array *notes = track.notes;
//    int notes_count = [notes count];
//
//    MidiTrack *top = [[MidiTrack alloc] initWithTrack:1];
//    MidiTrack *bottom = [[MidiTrack alloc] initWithTrack:2];
//    Array* result = [Array new:2];
//    [result add:top]; 
//    [result add:bottom];
//
//    if (notes_count == 0)
//        return result;
//
//    int prevhigh  = 76; /* E5, top of treble staff */
//    int prevlow   = 45; /* A3, bottom of bass staff */
//    int startindex = 0;
//
//    for (int i = 0; i < notes_count; i++) {
//        MidiNote *note = [notes get:i];
//        int number = note.number;
//
//        int high, low, highExact, lowExact;
//        high = low = highExact = lowExact = number;
//
//        while ([(MidiNote*)[notes get:startindex] endTime] < note.startTime) {
//            startindex++;
//        }
//
//        /* I've tried several algorithms for splitting a track in two,
//         * and the one below seems to work the best:
//         * - If this note is more than an octave from the high/low notes
//         *   (that start exactly at this start time), choose the closest one.
//         * - If this note is more than an octave from the high/low notes
//         *   (in this note's time duration), choose the closest one.
//         * - If the high and low notes (that start exactly at this starttime)
//         *   are more than an octave apart, choose the closest note.
//         * - If the high and low notes (that overlap this starttime)
//         *   are more than an octave apart, choose the closest note.
//         * - Else, look at the previous high/low notes that were more than an
//         *   octave apart.  Choose the closeset note.
//         */
//        [MidiFile findHighLowNotes:notes withMeasure:measurelen startIndex:startindex
//                  fromStart:note.startTime toEnd:note.endTime
//                  withHigh:&high andLow:&low];
//        [MidiFile findExactHighLowNotes:notes startIndex:startindex withStart:note.startTime
//                  withHigh:&highExact andLow:&lowExact];
//
//        if (highExact - number > 12 || number - lowExact > 12) {
//            if (highExact - number <= number - lowExact) {
//                [top addNote:note];
//            }
//            else {
//                [bottom addNote:note];
//            }
//        }
//        else if (high - number > 12 || number - low > 12) {
//            if (high - number <= number - low) {
//                [top addNote:note];
//            }
//            else {
//                [bottom addNote:note];
//            }
//        }
//        else if (highExact - lowExact > 12) {
//            if (highExact - number <= number - lowExact) {
//                [top addNote:note];
//            }
//            else {
//                [bottom addNote:note];
//            }
//        }
//        else if (high - low > 12) {
//            if (high - number <= number - low) {
//                [top addNote:note];
//            }
//            else {
//                [bottom addNote:note];
//            }
//        }
//        else {
//            if (prevhigh - number <= number - prevlow) {
//                [top addNote:note];
//            }
//            else {
//                [bottom addNote:note];
//            }
//        }
//
//        /* The prevhigh/prevlow are set to the last high/low
//         * that are more than an octave apart.
//         */
//        if (high - low > 12) {
//            prevhigh = high;
//            prevlow = low;
//        }
//    }
//
//    [top.notes sort:sortbytime];
//    [bottom.notes sort:sortbytime];
//
//    return result;
//}



/** Combine the notes in the given tracks into a single MidiTrack.
 *  The individual tracks are already sorted.  To merge them, we
 *  use a mergesort-like algorithm.
 */
-(MidiTrack*) combineToSingleTrack:(Array*)tracksArray {
    /* Add all notes into one track */
    MidiTrack *result = [[MidiTrack alloc] initWithTrack:1];

    if ([tracksArray count] == 0) {
        return result;
    }
    else if ([tracksArray count] == 1) {
        MidiTrack *track = [tracksArray get:0];
        for (int i = 0; i < [track.notes count]; i++) {
            [result addNote:[track.notes get:i] ];
        }
        return result;
    }

    int noteindex[64];
    int notecount[64];
    for (int tracknum = 0; tracknum < [tracksArray count]; tracknum++) {
        MidiTrack *track = [tracksArray get:tracknum];
        noteindex[tracknum] = 0;
        notecount[tracknum] = [track.notes count];
    }

    MidiNote *prevnote = nil;
    while (1) {
        MidiNote *lowestnote = nil;
        int lowestTrack = -1;
        for (int tracknum = 0; tracknum < [tracksArray count]; tracknum++) {
            MidiTrack *track = [tracksArray get:tracknum];
            if (noteindex[tracknum] >= notecount[tracknum]) {
                continue;
            }
            MidiNote *note = [track.notes get:noteindex[tracknum]];
            if (lowestnote == nil) {
                lowestnote = note;
                lowestTrack = tracknum;
            }
            else if (note.startTime < lowestnote.startTime) {
                lowestnote = note;
                lowestTrack = tracknum;
            }
            else if (note.startTime == lowestnote.startTime &&
                     note.number < lowestnote.number) {
                lowestnote = note;
                lowestTrack = tracknum;
            }
        }
        if (lowestnote == nil) {
            /* We've finished the merge */
            break;
        }
        noteindex[lowestTrack]++;
        if ((prevnote != nil) && (prevnote.startTime == lowestnote.startTime) &&
            (prevnote.number == lowestnote.number) ) {

            /* Don't add duplicate notes, with the same start time and number */
            if (lowestnote.duration > prevnote.duration) {
                prevnote.duration = lowestnote.duration;
            }
        }
        else {
            [result addNote:lowestnote];
            prevnote = lowestnote;
        }
    }

    return result;
}


/** Combine the notes in all the tracks given into two MidiTracks,
 * and return them.
 * 
 * This function is intended for piano songs, when we want to display
 * a left-hand track and a right-hand track.  The lower notes go into 
 * the left-hand track, and the higher notes go into the right hand 
 * track.
 */
//+(Array*) combineToTwoTracks:(Array*) tracks withMeasure:(int)measurelen {
//    MidiTrack *single = [MidiFile combineToSingleTrack:tracks];
//    Array* result = [MidiFile splitTrack:single withMeasure:measurelen];
//
//    Array* lyrics = [Array new:20];
//    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
//        MidiTrack *track = [tracks get:tracknum];
//        if (track.lyrics != nil) {
//            [lyrics addArray:track.lyrics];
//        }
//    }
//    if ([lyrics count] > 0) {
//        [lyrics sort:sortMidiEvent];
//        MidiTrack *track = [result get:0];
//        track.lyrics = lyrics;
//    }
//    return result;
//}


///** Check that the MidiNote start times are in increasing order.
// * This is for debugging purposes.
// */
//+(void)checkStartTimes:(Array*) tracks {
//    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
//        MidiTrack *track = [tracks get:tracknum];
//        int prevtime = -1;
//        for (int j = 0; j < [track.notes count]; j++) {
//            MidiNote *note = [track.notes get:j];
//            assert(note.startTime >= prevtime);
//            prevtime = note.startTime;
//        }
//    }
//}





/** We want note durations to span up to the next note in general.
 * The sheet music looks nicer that way.  In contrast, sheet music
 * with lots of 16th/32nd notes separated by small rests doesn't
 * look as nice.  Having nice looking sheet music is more important
 * than faithfully representing the Midi File data.
 *
 * Therefore, this function rounds the duration of MidiNotes up to
 * the next note where possible.
 */
//+(void)roundDurations:(Array*)tracks withQuarter:(int) quarternote {
//    for (int tracknum = 0; tracknum < [tracks count]; tracknum++) {
//        MidiTrack *track = [tracks get:tracknum];
//        MidiNote *prevNote = nil;
//
//        for (int i = 0; i < [track.notes count] - 1; i++) {
//            MidiNote *note1 = [track.notes get:i];
//            if (prevNote == nil) {
//                prevNote = note1;
//            }
//
//            /* Get the next note that has a different start time */
//            MidiNote *note2 = note1;
//            for (int j = i+1; j < [track.notes count]; j++) {
//                note2 = [track.notes get:j];
//                if (note1.startTime < note2.startTime) {
//                    break;
//                }
//            }
//            int maxduration = note2.startTime - note1.startTime;
//
//            int dur = 0;
//            if (quarternote <= maxduration)
//                dur = quarternote;
//            else if (quarternote/2 <= maxduration)
//                dur = quarternote/2;
//            else if (quarternote/3 <= maxduration)
//                dur = quarternote/3;
//            else if (quarternote/4 <= maxduration)
//                dur = quarternote/4;
//
//
//            if (dur < note1.duration) {
//                dur = note1.duration;
//            }
//
//            /* Special case: If the previous note's duration
//             * matches this note's duration, we can make a notepair.
//             * So don't expand the duration in that case.
//             */
//            if (prevNote.startTime + prevNote.duration == note1.startTime &&
//                prevNote.duration == note1.duration) {
//
//                dur = note1.duration;
//            }
//            note1.duration = dur;
//            MidiNote *nextNote = [track.notes get:i+1];
//            if (nextNote.startTime != note1.startTime) {
//                prevNote = note1;
//            }
//        }
//    }
//}

/** Split the given track into multiple tracks, separating each
 * channel into a separate track.
 */
//+(Array*) splitChannels:(MidiTrack*) origtrack withEvents:(Array*)events {
//
//    /* Find the instrument used for each channel */
//    IntArray* channelInstruments = [IntArray new:16];
//    for (int i =0; i < 16; i++) {
//        [channelInstruments add:0];
//    }
//    for (int i = 0; i < [events count]; i++) {
//        MidiEvent *mevent = [events get:i];
//        if (mevent.eventFlag == EventProgramChange) {
//            [channelInstruments set:mevent.instrument index:mevent.channel];
//        }
//    }
//    [channelInstruments set:128 index:9]; /* Channel 9 = Percussion */
//
//    Array *result = [Array new:2];
//    for (int i = 0; i < [origtrack.notes count]; i++) {
//        MidiNote *note = [origtrack.notes get:i];
//        BOOL foundchannel = FALSE;
//        for (int tracknum = 0; tracknum < [result count]; tracknum++) {
//            MidiTrack *track = [result get:tracknum];
//			MidiNote *note2 = [track.notes get:0];
//            if (note.channel == note2.channel) {
//                foundchannel = TRUE;
//                [track addNote:note];
//            }
//        }
//        if (!foundchannel) {
//            MidiTrack* track = [[MidiTrack alloc] initWithTrack:([result count] + 1)];
//            [track addNote:note];
//            int instrument = [channelInstruments get:note.channel];
//            track.instrument = instrument;
//            [result add:track];
//         
//        }
//    }
//    if (origtrack.lyrics != nil) {
//        for (int i = 0; i < [origtrack.lyrics count]; i++) {
//            MidiEvent *lyricEvent = [origtrack.lyrics get:i];
//            for (int j = 0; j < [result count]; j++) {
//                MidiTrack *track = [result get:j];
//			    MidiNote *note = [track.notes get:0];
//                if (lyricEvent.channel == note.channel) {
//                    [track addLyric:lyricEvent];
//                }
//            }
//        }
//    }
//    return result;
//}

/** Return the last start time */
//-(int)endTime {
//    int lastStart = 0;
//    for (int i = 0; i < [tracks count]; i++) {
//        MidiTrack *track = [tracks get:i];
//        if ([track.notes count] == 0) {
//            continue;
//        }
//        int lastindex = [track.notes count] - 1;
//		MidiNote *lastnote = [track.notes get:lastindex];
//        int last = lastnote.startTime;
//        if (last > lastStart) {
//            lastStart = last;
//        }
//    }
//    return lastStart;
//}
//
///** Given a filename, like "Bach__Minuet_in_G", return
// *  the string "Bach: Minuet in G".
// */
//+(NSString*)titleName:(NSString*)filename {
//    NSString *title = filename;
//    if ([title hasSuffix:@".mid"]) {
//        title = [title substringToIndex:[title length] - 4];
//    }
//    NSArray *pieces = [title componentsSeparatedByString:@"__"];
//    title = [pieces componentsJoinedByString:@": "];
//    pieces = [title componentsSeparatedByString:@"_"];
//    title = [pieces componentsJoinedByString:@" "];
//    return title;
//}


///** Return true if this midi file has lyrics */
//-(BOOL)hasLyrics {
//    for (int i = 0; i < [tracks count]; i++) {
//        MidiTrack *track = [tracks get:i];
//        if (track.lyrics != nil) {
//            return YES;
//        }
//    }
//    return NO;
//}

//
//- (NSString*)description {
//    NSString *s = [NSString stringWithFormat:
//                     @"Midi File tracks=%d quarter=%d %@\n",
//                     [tracks count], quarternote, [time description]];
//    for (int i = 0; i < [tracks count]; i++) {
//        MidiTrack *track = [tracks get:i];
//        s = [s stringByAppendingString:[track description]];
//    }
//    return s;
//}

@end /* class MidiFile */


