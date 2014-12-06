//
//  GameScene.m
//  Staff Master
//
//  Created by Taylor Moss on 11/13/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import "GameScene.h"
#import "MidiFile.h"
#import "MidiTrack.h"
#import "MidiMeasure.h"
#import "MidiNote.h"
#import "AudioUtility.h"
#import "MIDIUtility.h"
#import <CoreAudio/CoreAudio.h>

@implementation GameScene
{
    
    SKNode *_noteLayer;
    SKNode *_staffLinesLayer;
    SKNode *_clefLayer;
    SKNode *_staffLayer;
    SKNode *_controlLayer;
    CGFloat _distanceBetweenStaffLines;
    CGRect _innerNotePadFrame;
    CGRect _outerNotePadFrame;
    BAudioController *audioController;
    NSMutableArray *_notePressedFlags;
    

}
static const CGFloat NOTE_SPEED = 200;
static const int NUMBER_OF_LINES = 34;


static GameScene *scene;
static const uint8_t noteBitmaskCategory = 0;

static inline CGVector radiansToVector(CGFloat radians)
{
    
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;

}

-(void)checkNoteHitWithNumber:(int)userKeyNumber
{
    [_notePressedFlags addObject: [NSNumber numberWithInt:userKeyNumber]];
    

    
}

-(void)didMoveToView:(SKView *)view {
   
    
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    
    scene = self;
    audioController = [[BAudioController alloc] init];
    
    
    [self initializeGraphics];
    [MIDIUtility setupDeviceWithCallBack:midiInputCallback];
    
    
    _notePressedFlags = [[NSMutableArray alloc]init];
    NSString *midiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Field_-_Nocturne_in_B-flat_major.mid"];
    
    MidiFile *midifile = [[MidiFile alloc] initWithFile:midiFilePath];
    
    SKAction *runTrebleNotes = [SKAction sequence:[self buildNoteActionSequenceFromMidiFile:midifile andTrackNumber:0 andNoteState:1]];
    SKAction *runBassNotes = [SKAction sequence:[self buildNoteActionSequenceFromMidiFile:midifile andTrackNumber:1 andNoteState:1]];
    SKAction *runMeasureBars = [SKAction sequence:[self buildMeasureBarActionSequenceFromMidiFile:midifile]];
    SKAction *killTrebleNotes = [SKAction sequence:[self buildNoteActionSequenceFromMidiFile:midifile andTrackNumber:0 andNoteState:0]];
    SKAction *killBassNotes = [SKAction sequence:[self buildNoteActionSequenceFromMidiFile:midifile andTrackNumber:1 andNoteState:0]];
    
    
    
    
    [self runAction:runBassNotes];
    [self runAction:runTrebleNotes];
    [self runAction:runMeasureBars];
    [self runAction:killBassNotes];
    [self runAction:killTrebleNotes];
}


-(NSArray*)buildMeasureBarActionSequenceFromMidiFile:(MidiFile*)midiFile
{
    MidiTrack *track = [midiFile.tracks get:1];
    NSMutableArray *actionSequence;
    actionSequence = [[NSMutableArray alloc]init];
    
    for(int i =0; i < [track.measures count]; i++)
    {
        MidiMeasure *currentMeasure = track.measures[i];
        CGFloat waitDuration = 0;
        if(i == 0)
        {
            waitDuration = currentMeasure.startTime/1000000.0;
        }
        else
        {
            waitDuration = currentMeasure.duration/1000000.0;
        }

        [actionSequence addObject:[SKAction waitForDuration:(waitDuration)]];
        [actionSequence addObject:[SKAction runBlock:^{
            [self spawnMeasureBars];
        }]];
    }
     return (NSArray*)actionSequence;
}


-(NSArray*)buildNoteActionSequenceFromMidiFile:(MidiFile*)midiFile andTrackNumber:(int)trackNumber andNoteState:(int)noteState
{
    
    MidiTrack *track = [midiFile.tracks get:trackNumber];
    NSMutableArray *spawnNoteActionSequence;
    spawnNoteActionSequence = [[NSMutableArray alloc]init];

    NSMutableArray *killNoteActionSequence;
    killNoteActionSequence = [[NSMutableArray alloc] init];
    CGFloat waitDurationBeforeKill = 0;
    
    int noteIndex = 0;
    for(int i =0; i < [track.measures count]; i++)
    {
        MidiMeasure *currentMeasure = track.measures[i];
        
        
        for(int j = 0; j < [currentMeasure.notes count] ; j++)
        {
            MidiNote *note = currentMeasure.notes[j];
            CGFloat yPosition = [self calculateYPositionFromNote:note.name andTrack:trackNumber];
            CGFloat waitDuration = 0;
            
            if(noteIndex == 0)
            {
                waitDuration = note.startTimeuS/1000000.0;
                
                
                
            }
            else
            {
                //get the previous note.  the notes duration parameter is used to set the wait time between
                //note spawns.  if this is the first note in the measure, index back through last measure until the last note is found.
                MidiNote *previousNote;
                if (j > 0)
                {
                    previousNote = currentMeasure.notes[j - 1];
                }
                else
                {
                    MidiMeasure *currmeas;
                    int measureBack = 1;
                    do{
                        
                        currmeas = track.measures[i - measureBack];;
                        measureBack--;
                    }while ([currmeas.notes count] == 0 );
                    
                    previousNote = currmeas.notes[[currmeas.notes count] - 1];
                }
                
                if(note.startTimeuS > previousNote.startTimeuS)
                {
                    waitDuration = (note.startTimeuS - previousNote.startTimeuS)/1000000.0;
                    
                    
                }
                
                
            }
            waitDurationBeforeKill = waitDuration + note.durationuS/1000000.0;
            
            [spawnNoteActionSequence addObject:[SKAction waitForDuration:(waitDuration)]];
            [killNoteActionSequence addObject:[SKAction waitForDuration:waitDurationBeforeKill]];
            
            
            NSMutableDictionary * noteData = [NSMutableDictionary
                                           dictionaryWithObjects:@[[NSString stringWithFormat: @"%d", note.number],note.name,note.normalState,[NSString stringWithFormat: @"%d", note.isAccidental],[NSString stringWithFormat: @"%d", note.ledgerLines],note.clef,[NSString stringWithFormat: @"%d", note.durationuS], [NSString stringWithFormat: @"%d", note.velocity], @"NO"]
                                           forKeys:@[@"number",@"name",@"normalState",@"isAccidental",@"ledgerLines",@"clef",@"duration",@"velocity",@"wasPlayed"]];
           
            
            [spawnNoteActionSequence addObject:[SKAction runBlock:^{
                [self spawnNoteWithYPosition:yPosition  andImageName:[self selectNoteGraphic:note.showAccidental withAccidental:note.normalState] andNoteData:noteData];
            }]];
            
            [killNoteActionSequence addObject:[SKAction runBlock:^{
                [self killNote:note.number];
            }]];
            
            
            noteIndex++;
        }
    }
    
    if (noteState == 1) {
        return (NSArray*)spawnNoteActionSequence;
    }
    else{
        return (NSArray*)killNoteActionSequence;
    }
}

-(void) killNote:(int)noteNumber
{
    [audioController noteOffFile:noteNumber];
}

-(void) spawnMeasureBars
{
    CGVector direction = radiansToVector(M_PI);
    
    SKSpriteNode *trebleMeasure = [SKSpriteNode spriteNodeWithImageNamed:@"MeasureBar"];
    trebleMeasure.size = CGSizeMake(1.0, 4*_distanceBetweenStaffLines);
    trebleMeasure.position = CGPointMake(self.size.width + trebleMeasure.size.width/2,23*(self.size.height/NUMBER_OF_LINES));
    trebleMeasure.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:trebleMeasure.frame.size];
    trebleMeasure.physicsBody.collisionBitMask = noteBitmaskCategory;
    trebleMeasure.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
    trebleMeasure.physicsBody.restitution = 1.0;
    trebleMeasure.physicsBody.linearDamping = 0.0;
    trebleMeasure.physicsBody.friction = 0.0;
    
    SKSpriteNode *bassMeasure = [SKSpriteNode spriteNodeWithImageNamed:@"MeasureBar"];
    bassMeasure.size = CGSizeMake(1.0, 4*_distanceBetweenStaffLines);
    bassMeasure.position = CGPointMake(self.size.width + trebleMeasure.size.width/2,12*(self.size.height/NUMBER_OF_LINES));
    bassMeasure.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bassMeasure.frame.size];
    bassMeasure.physicsBody.collisionBitMask = noteBitmaskCategory;
    bassMeasure.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
    bassMeasure.physicsBody.restitution = 1.0;
    bassMeasure.physicsBody.linearDamping = 0.0;
    bassMeasure.physicsBody.friction = 0.0;
    
    [_noteLayer addChild:bassMeasure];
    [_noteLayer addChild:trebleMeasure];
}


-(void) spawnNoteWithYPosition: (CGFloat)yPosition andImageName:(NSString *)imageName andNoteData:(NSMutableDictionary*)noteData
{
 
    CGVector direction = radiansToVector(M_PI);
    
    
    //Create Note Node
    SKSpriteNode *note = [SKSpriteNode spriteNodeWithImageNamed:imageName];
    note.userData = noteData;
    note.name = @"Note";
    [note setScale:_distanceBetweenStaffLines/note.size.height];
    note.position = CGPointMake(self.size.width + note.size.width/2,yPosition);
    note.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:0.5*_distanceBetweenStaffLines];
    note.physicsBody.collisionBitMask = noteBitmaskCategory;
    note.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
    note.physicsBody.restitution = 1.0;
    note.physicsBody.linearDamping = 0.0;
    note.physicsBody.friction = 0.0;

    note.color = [SKColor blackColor];
    note.colorBlendFactor = 1.0;
    
    
    int ledgerLines = [[noteData objectForKey:@"ledgerLines"] intValue];
    NSString *clef = [noteData objectForKey:@"clef"];
    int ledgerYPosition;
    int deltaLedgerYPosition = 0;
    int noteNumber = [[noteData objectForKey:@"number"] intValue];
    
    if (noteNumber >= 81 && [clef  isEqual: @"Treble"]) {
        ledgerYPosition = 26*(self.size.height/NUMBER_OF_LINES); //Position of first ledger line above F5
        for (int i = 0; i < ledgerLines; i++) {
            SKSpriteNode *ledgerLine = [SKSpriteNode spriteNodeWithImageNamed:@"LedgerLine"];
            ledgerLine.name = @"LedgerLine";
            ledgerLine.size = CGSizeMake(note.size.width + 10, 1);
            ledgerLine.position = CGPointMake(self.size.width + note.size.width/2, ledgerYPosition + deltaLedgerYPosition);
            ledgerLine.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(ledgerLine.size.width, ledgerLine.size.height)];
            ledgerLine.physicsBody.collisionBitMask = noteBitmaskCategory;
            ledgerLine.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
            ledgerLine.physicsBody.restitution = 1.0;
            ledgerLine.physicsBody.linearDamping = 0.0;
            ledgerLine.physicsBody.friction = 0.0;
            deltaLedgerYPosition = deltaLedgerYPosition + _distanceBetweenStaffLines;
            
            [_noteLayer addChild:ledgerLine];
        }
    }
    else if (noteNumber <= 60 && [clef  isEqual: @"Treble"]) {
        ledgerYPosition = 20*(self.size.height/NUMBER_OF_LINES); //Position of first ledger line below E4
        for (int i = 0; i < ledgerLines; i++) {
            SKSpriteNode *ledgerLine = [SKSpriteNode spriteNodeWithImageNamed:@"LedgerLine"];
            ledgerLine.name = @"LedgerLine";
            ledgerLine.size = CGSizeMake(note.size.width + 10, 1);
            ledgerLine.position = CGPointMake(self.size.width + note.size.width/2, ledgerYPosition - deltaLedgerYPosition);
            ledgerLine.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(ledgerLine.size.width, ledgerLine.size.height)];
            ledgerLine.physicsBody.collisionBitMask = noteBitmaskCategory;
            ledgerLine.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
            ledgerLine.physicsBody.restitution = 1.0;
            ledgerLine.physicsBody.linearDamping = 0.0;
            ledgerLine.physicsBody.friction = 0.0;
            deltaLedgerYPosition = deltaLedgerYPosition + _distanceBetweenStaffLines;
            
            [_noteLayer addChild:ledgerLine];
        }
    }
    else if (noteNumber >= 60 && [clef  isEqual: @"Bass"]) {
        ledgerYPosition = 15*(self.size.height/NUMBER_OF_LINES); //Position of first ledger line below E4
        for (int i = 0; i < ledgerLines; i++) {
            SKSpriteNode *ledgerLine = [SKSpriteNode spriteNodeWithImageNamed:@"LedgerLine"];
            ledgerLine.name = @"LedgerLine";
            ledgerLine.size = CGSizeMake(note.size.width + 10, 1);
            ledgerLine.position = CGPointMake(self.size.width + note.size.width/2, ledgerYPosition + deltaLedgerYPosition);
            ledgerLine.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(ledgerLine.size.width, ledgerLine.size.height)];
            ledgerLine.physicsBody.collisionBitMask = noteBitmaskCategory;
            ledgerLine.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
            ledgerLine.physicsBody.restitution = 1.0;
            ledgerLine.physicsBody.linearDamping = 0.0;
            ledgerLine.physicsBody.friction = 0.0;
            deltaLedgerYPosition = deltaLedgerYPosition + _distanceBetweenStaffLines;
            
            [_noteLayer addChild:ledgerLine];
        }
    }
    else if (noteNumber <= 40 && [clef  isEqual: @"Bass"]) {
        ledgerYPosition = 9*(self.size.height/NUMBER_OF_LINES); //Position of first ledger line below E4
        for (int i = 0; i < ledgerLines; i++) {
            SKSpriteNode *ledgerLine = [SKSpriteNode spriteNodeWithImageNamed:@"LedgerLine"];
            ledgerLine.name = @"LedgerLine";
            ledgerLine.size = CGSizeMake(note.size.width + 10, 1);
            ledgerLine.position = CGPointMake(self.size.width + note.size.width/2, ledgerYPosition - deltaLedgerYPosition);
            ledgerLine.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(ledgerLine.size.width, ledgerLine.size.height)];
            ledgerLine.physicsBody.collisionBitMask = noteBitmaskCategory;
            ledgerLine.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
            ledgerLine.physicsBody.restitution = 1.0;
            ledgerLine.physicsBody.linearDamping = 0.0;
            ledgerLine.physicsBody.friction = 0.0;
            deltaLedgerYPosition = deltaLedgerYPosition + _distanceBetweenStaffLines;
            
            [_noteLayer addChild:ledgerLine];
        }
    }
    
    
    
    [_noteLayer addChild:note];
    
    
    
}




-(NSString *) selectNoteGraphic: (bool)showAccidental withAccidental:(NSString *)symbol
{
    NSString *imageName;
    if (showAccidental == YES) {
        if ([symbol  isEqual: @"sharp"]) {
            imageName = @"SharpNote";
        }
        else if ([symbol  isEqual: @"flat"])
        {
            imageName = @"FlatNote";
        }
        else if([symbol  isEqual: @"natural"])
        {
            imageName = @"NaturalNote";
        }
        else
        {
            imageName = @"NormalNote";
        }
    }
    else {
        imageName = @"NormalNote";
    }
    return imageName;
}

-(CGFloat) calculateYPositionFromNote:(NSString *)noteName andTrack:(int)track
{
    CGFloat yPosition;
    
   if (track == 1) {
        if([noteName  isEqual: @"A0"])
        {
            yPosition = 3.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B0"])
        {
            yPosition = 4*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C1"])
        {
            yPosition = 4.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D1"])
        {
            yPosition = 5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E1"])
        {
            yPosition = 5.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F1"])
        {
            yPosition = 6*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G1"])
        {
            yPosition = 6.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A1"])
        {
            yPosition = 7*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B1"])
        {
            yPosition = 7.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C2"])
        {
            yPosition = 8*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D2"])
        {
            yPosition = 8.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E2"])
        {
            yPosition = 9*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F2"])
        {
            yPosition = 9.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G2"])
        {
            yPosition = 10*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A2"])
        {
            yPosition = 10.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B2"])
        {
            yPosition = 11*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C3"])
        {
            yPosition = 11.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D3"])
        {
            yPosition = 12*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E3"])
        {
            yPosition = 12.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F3"])
        {
            yPosition = 13*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G3"])
        {
            yPosition = 13.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A3"])
        {
            yPosition = 14*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B3"])
        {
            yPosition = 14.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C4"])
        {
            yPosition = 15*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D4"])
        {
            yPosition = 15.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E4"])
        {
            yPosition = 16*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F4"])
        {
            yPosition = 16.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G4"])
        {
            yPosition = 17*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A4"])
        {
            yPosition = 17.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B4"])
        {
            yPosition = 18*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C5"])
        {
            yPosition = 18.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D5"])
        {
            yPosition = 19*(self.size.height/NUMBER_OF_LINES);
        }
        else
        {
            yPosition = 0;
        }
    }
    else
    {
        if ([noteName  isEqual: @"C3"])
        {
            yPosition = 16.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D3"])
        {
            yPosition = 17*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E3"])
        {
            yPosition = 17.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F3"])
        {
            yPosition = 18*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G3"])
        {
            yPosition = 18.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A3"])
        {
            yPosition = 19*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B3"])
        {
            yPosition = 19.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C4"])
        {
            yPosition = 20*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D4"])
        {
            yPosition = 20.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E4"])
        {
            yPosition = 21*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F4"])
        {
            yPosition = 21.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G4"])
        {
            yPosition = 22*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A4"])
        {
            yPosition = 22.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B4"])
        {
            yPosition = 23*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C5"])
        {
            yPosition = 23.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D5"])
        {
            yPosition = 24*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E5"])
        {
            yPosition = 24.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F5"])
        {
            yPosition = 25*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G5"])
        {
            yPosition = 25.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A5"])
        {
            yPosition = 26*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B5"])
        {
            yPosition = 26.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C6"])
        {
            yPosition = 27*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D6"])
        {
            yPosition = 27.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E6"])
        {
            yPosition = 28*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F6"])
        {
            yPosition = 28.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G6"])
        {
            yPosition = 29*(self.size.height/NUMBER_OF_LINES);
        }else if ([noteName  isEqual: @"A6"])
        {
            yPosition = 29.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B6"])
        {
            yPosition = 30*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C7"])
        {
            yPosition = 30.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"D7"])
        {
            yPosition = 31*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"E7"])
        {
            yPosition = 31.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"F7"])
        {
            yPosition = 32*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"G7"])
        {
            yPosition = 32.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"A7"])
        {
            yPosition = 33*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"B7"])
        {
            yPosition = 33.5*(self.size.height/NUMBER_OF_LINES);
        }
        else if ([noteName  isEqual: @"C8"])
        {
            yPosition = 34*(self.size.height/NUMBER_OF_LINES);
        }
        else
        {
            yPosition = 0;
            
        }
    }

  return yPosition;
}


-(void) didSimulatePhysics
{
    
    [_noteLayer enumerateChildNodesWithName:@"Note" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + ((SKSpriteNode*)node).size.width/2 < 0.0)
        {
            [node removeFromParent];
        }
        
        if (CGRectContainsPoint(_innerNotePadFrame, node.position) && [[node.userData objectForKey:@"wasPlayed"]  isEqual: @"NO"])
        {
            int note = [[node.userData objectForKey:@"number"] intValue] ;
            int velocity = [[node.userData objectForKey:@"velocity"] intValue];
            
            [audioController noteOnFile:note withVelocity:velocity];
            [node.userData setObject:@"YES" forKey:@"wasPlayed"];
        }
        for (int i = 0; i <[_notePressedFlags count]; i++) {
            if (CGRectContainsPoint(_outerNotePadFrame, node.position) && ([_notePressedFlags[i] intValue] == [[node.userData objectForKey:@"number"] intValue])){
                
            
                SKSpriteNode *spriteNote = (SKSpriteNode*)node;
                
                spriteNote.color = [SKColor greenColor];
                spriteNote.colorBlendFactor = 1.0;
                            }
            
        }
    }];
    
    [_noteLayer enumerateChildNodesWithName:@"LedgerLine" usingBlock:^(SKNode *node, BOOL *stop){
        if (node.position.x + ((SKSpriteNode*)node).size.width/2 < 0.0)
        {
            [node removeFromParent];
        }
        
    }];
     
    [_noteLayer enumerateChildNodesWithName:@"NoteBridge" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x < 0.0)
        {
            [node removeFromParent];
        }
        
    }];
    
    [_notePressedFlags removeAllObjects];
    
}

-(void) initializeGraphics
{
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Clouds"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    
    _staffLayer = [[SKNode alloc]init];
    [self addChild:_staffLayer];
   
    _controlLayer = [[SKNode alloc]init];
    [self addChild:_controlLayer];
    
    
    //Add grand staff and ledger lines to staff layer
    //The equation for staff Y position is y = line number * (window height / 28)
    //A piano can play on a total of 26 lines (including ledger lines) but we allow room for 28
    
    _staffLinesLayer = [[SKNode alloc]init];
    [_staffLayer addChild:_staffLinesLayer];
    
    SKSpriteNode *grandStaffTrebleF;
    grandStaffTrebleF = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleF.size  = CGSizeMake(self.size.width, 1);
    grandStaffTrebleF.position = CGPointMake(0, 25*(self.size.height/NUMBER_OF_LINES));
    grandStaffTrebleF.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleF];
    
    SKSpriteNode *grandStaffTrebleD;
    grandStaffTrebleD = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleD.size  = CGSizeMake(self.size.width, 1);
    grandStaffTrebleD.position = CGPointMake(0, 24*(self.size.height/NUMBER_OF_LINES));
    grandStaffTrebleD.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleD];
    
    SKSpriteNode *grandStaffTrebleB;
    grandStaffTrebleB = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleB.size  = CGSizeMake(self.size.width, 1);
    grandStaffTrebleB.position = CGPointMake(0, 23*(self.size.height/NUMBER_OF_LINES));
    grandStaffTrebleB.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleB];
    
    SKSpriteNode *grandStaffTrebleG;
    grandStaffTrebleG = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleG.size  = CGSizeMake(self.size.width, 1);
    grandStaffTrebleG.position = CGPointMake(0, 22*(self.size.height/NUMBER_OF_LINES));
    grandStaffTrebleG.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleG];
    
    SKSpriteNode *grandStaffTrebleE;
    grandStaffTrebleE = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleE.size  = CGSizeMake(self.size.width, 1);
    grandStaffTrebleE.position = CGPointMake(0, 21*(self.size.height/NUMBER_OF_LINES));
    grandStaffTrebleE.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleE];
    
    SKSpriteNode *grandStaffBassA;
    grandStaffBassA = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassA.size  = CGSizeMake(self.size.width, 1);
    grandStaffBassA.position = CGPointMake(0, 14*(self.size.height/NUMBER_OF_LINES));
    grandStaffBassA.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassA];
    
    SKSpriteNode *grandStaffBassF;
    grandStaffBassF = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassF.size  = CGSizeMake(self.size.width, 1);
    grandStaffBassF.position = CGPointMake(0, 13*(self.size.height/NUMBER_OF_LINES));
    grandStaffBassF.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassF];
    
    SKSpriteNode *grandStaffBassD;
    grandStaffBassD = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassD.size  = CGSizeMake(self.size.width, 1);
    grandStaffBassD.position = CGPointMake(0, 12*(self.size.height/NUMBER_OF_LINES));
    grandStaffBassD.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassD];
    
    SKSpriteNode *grandStaffBassB;
    grandStaffBassB = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassB.size  = CGSizeMake(self.size.width, 1);
    grandStaffBassB.position = CGPointMake(0, 11*(self.size.height/NUMBER_OF_LINES));
    grandStaffBassB.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassB];
    
    SKSpriteNode *grandStaffBassG;
    grandStaffBassG = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassG.size  = CGSizeMake(self.size.width, 1);
    grandStaffBassG.position = CGPointMake(0, 10*(self.size.height/NUMBER_OF_LINES));
    grandStaffBassG.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassG];
    
    
    //Line 9 - E2
    //Line 8 - C2
    //Line 7 - A1
    //Line 6 - F1
    //Line 5 - D1
    //Line 4 - B0
    
    
    
    
    _distanceBetweenStaffLines =grandStaffTrebleF.position.y -grandStaffTrebleD.position.y;
    
    //Add treble and bass clefs to the staff layer
    //Size and position are calculated in relation to scene size and grand staff line positions
    
    _clefLayer = [[SKNode alloc]init];
    [_staffLayer addChild:_clefLayer];
    CGFloat trebleClefHeight = (11.0/6.0)*(grandStaffTrebleF.position.y - grandStaffTrebleE.position.y);
    CGFloat trebleClefWidth = trebleClefHeight*(0.366895);
    CGFloat trebleClefXPosition = 100.0;
    CGFloat trebleClefYPosition = grandStaffTrebleE.position.y - ((trebleClefHeight - (trebleClefHeight*6.0/11.0))/2.0);
 
    SKSpriteNode *trebleClef;
    trebleClef = [SKSpriteNode spriteNodeWithImageNamed:@"TrebleClef"];
    trebleClef.size = CGSizeMake(trebleClefWidth, trebleClefHeight);
    trebleClef.position = CGPointMake(trebleClefXPosition, trebleClefYPosition);
    trebleClef.anchorPoint = CGPointMake(0.0, 0.0);
    [_clefLayer addChild:trebleClef];
    
    CGFloat bassClefHeight = (5.0/6.0)*(grandStaffBassA.position.y - grandStaffBassG.position.y);
    CGFloat bassClefWidth = bassClefHeight*(0.84058);
    CGFloat bassClefXPosition = 100.0;
    CGFloat bassClefYPosition = grandStaffBassA.position.y - bassClefHeight;
    
    SKSpriteNode *bassClef;
    bassClef = [SKSpriteNode spriteNodeWithImageNamed:@"BassClef"];
    bassClef.size = CGSizeMake(bassClefWidth, bassClefHeight);
    bassClef.position = CGPointMake(bassClefXPosition, bassClefYPosition);
    bassClef.anchorPoint = CGPointMake(0.0, 0.0);
    [_clefLayer addChild:bassClef];
    
    // Add the "note pad"
    SKSpriteNode *notePad;
    notePad = [SKSpriteNode spriteNodeWithImageNamed:@"NotePad"];
    notePad.position = CGPointMake(self.size.width*0.5, 0.0);
    [_clefLayer addChild:notePad];
    
    SKSpriteNode *pauseButton;
    pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"Pause"];
    pauseButton.name = @"Pause";
    pauseButton.position = CGPointMake(100, 100);
    [_controlLayer addChild:pauseButton];
    
    SKSpriteNode *playButton;
    playButton = [SKSpriteNode spriteNodeWithImageNamed:@"Play"];
    playButton.name = @"Play";
    playButton.position = CGPointMake(200, 100);
    [_controlLayer addChild:playButton];
    
    _noteLayer = [[SKNode alloc]init];
    [self addChild:_noteLayer];
    
 
    _innerNotePadFrame = CGRectMake(notePad.position.x - notePad.size.width*0.25, 0.0, notePad.size.width*0.5, notePad.size.height);
    _outerNotePadFrame = notePad.frame;
    
    
    
}
-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    CGPoint location = [theEvent locationInNode:self]; //get location of touch
    SKSpriteNode *spriteTouched = (SKSpriteNode*)[self nodeAtPoint:location]; //get a node if touched at that location
   
    if ([spriteTouched.name  isEqual: @"Pause"]) {
        self.paused = true;
    }
    
    if ([spriteTouched.name  isEqual: @"Play"]) {
        self.paused = false;
    }
    if ([spriteTouched.name  isEqual: @"Note"]) {
        NSLog(@"Note Number: %@; Note Name: %@; Note Normal State: %@ Is Accidental: %@", [spriteTouched.userData objectForKey:@"number"], [spriteTouched.userData objectForKey:@"name"], [spriteTouched.userData objectForKey:@"normalState"],[spriteTouched.userData objectForKey:@"isAccidental"]);
    }
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}


void midiInputCallback (const MIDIPacketList *list,
                        void *procRef,
                        void *srcRef)
{
    
    [MIDIUtility processMessage:list];
    
    if([MIDIUtility getMessageType:list] == 0x90)
    [scene checkNoteHitWithNumber:[MIDIUtility getNoteNumber:list]];
   
    
}

@end
