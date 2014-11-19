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
#import "MidiNote.h"
@implementation GameScene
{
    
    SKNode *_noteLayer;
    SKNode *_staffLinesLayer;
    SKNode *_clefLayer;
    SKNode *_staffLayer;
    CGFloat _distanceBetweenStaffLines;

}
static const CGFloat NOTE_SPEED = 200;
static inline CGVector radiansToVector(CGFloat radians)
{
    
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}
-(void)didMoveToView:(SKView *)view {
   
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Clouds"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    
    _staffLayer = [[SKNode alloc]init];
    [self addChild:_staffLayer];
    
    
    //Add grand staff and ledger lines to staff layer
    //The equation for staff Y position is y = line number * (window height / 28)
    //A piano can play on a total of 26 lines (including ledger lines) but we allow room for 28
    
    _staffLinesLayer = [[SKNode alloc]init];
    [_staffLayer addChild:_staffLinesLayer];
    
    SKSpriteNode *grandStaffBassG;
    grandStaffBassG = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassG.position = CGPointMake(0, 7*(self.size.height/28.0));
    grandStaffBassG.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassG];
    
    SKSpriteNode *grandStaffBassB;
    grandStaffBassB = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassB.position = CGPointMake(0, 8*(self.size.height/28.0));
    grandStaffBassB.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassB];
    
    SKSpriteNode *grandStaffBassD;
    grandStaffBassD = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassD.position = CGPointMake(0, 9*(self.size.height/28.0));
    grandStaffBassD.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassD];
    
    SKSpriteNode *grandStaffBassF;
    grandStaffBassF = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassF.position = CGPointMake(0, 10*(self.size.height/28.0));
    grandStaffBassF.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassF];
    
    SKSpriteNode *grandStaffBassA;
    grandStaffBassA = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffBassA.position = CGPointMake(0, 11*(self.size.height/28.0));
    grandStaffBassA.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffBassA];
    
    SKSpriteNode *grandStaffTrebleE;
    grandStaffTrebleE = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleE.position = CGPointMake(0, 13*(self.size.height/28.0));
    grandStaffTrebleE.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleE];
    
    SKSpriteNode *grandStaffTrebleG;
    grandStaffTrebleG = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleG.position = CGPointMake(0, 14*(self.size.height/28.0));
    grandStaffTrebleG.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleG];
    
    SKSpriteNode *grandStaffTrebleB;
    grandStaffTrebleB = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleB.position = CGPointMake(0, 15*(self.size.height/28.0));
    grandStaffTrebleB.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleB];
    
    SKSpriteNode *grandStaffTrebleD;
    grandStaffTrebleD = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleD.position = CGPointMake(0, 16*(self.size.height/28.0));
    grandStaffTrebleD.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleD];
    
    SKSpriteNode *grandStaffTrebleF;
    grandStaffTrebleF = [SKSpriteNode spriteNodeWithImageNamed:@"GrandStaffLine"];
    grandStaffTrebleF.position = CGPointMake(0, 17*(self.size.height/28.0));
    grandStaffTrebleF.anchorPoint = CGPointMake(0.0, 0.0);
    [_staffLinesLayer addChild:grandStaffTrebleF];
    
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
    
    
    
    
    _noteLayer = [[SKNode alloc]init];
    [self addChild:_noteLayer];
    
    
    NSString *midiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"MidiFile.mid"];
    
    
    
    MidiFile *midifile = [[MidiFile alloc] initWithFile:midiFilePath];
    SKAction *runNotes = [SKAction sequence:[self buildActionSequenceFromMidiFile:midifile]];
    [self runAction:runNotes];
    
}


-(NSArray*)buildActionSequenceFromMidiFile:(MidiFile*)midiFile
{
     MidiTrack *track = [midiFile.tracks get:0];
    NSMutableArray *actionSequence;
    actionSequence = [[NSMutableArray alloc]init];
    CGSize noteSize = CGSizeMake(_distanceBetweenStaffLines/2, _distanceBetweenStaffLines/2);
    
    for(int i =0; i < [track.notes count]; i++)
    {
        //SKAction *action;
        MidiNote *note =[track.notes get:i];
        CGFloat yPosition = [self calculateYPositionFromNote:note.number];
        CGFloat waitDuration = 0;
        
        if(i==0)
        {
            [actionSequence addObject:[SKAction waitForDuration:(5)]];
            waitDuration = 0;
        }
        else
        {
            MidiNote *noteLast = [track.notes get:i-1];
            if(note.startTimeuS > noteLast.startTimeuS)
            {
            waitDuration = (note.startTimeuS - noteLast.startTimeuS)/1000000.0;
            [actionSequence addObject:[SKAction waitForDuration:(waitDuration)]];
            }
        }
        
        
        
        [actionSequence addObject:[SKAction runBlock:^{
            [self spawnNoteWithYPosition:yPosition andSize:(noteSize)];
        }]];
        
        
    }
    
    return (NSArray*)actionSequence;
}



-(void) spawnNoteWithYPosition: (CGFloat)yPosition andSize: (CGSize)size
{
    //Create Note Node
    SKSpriteNode *note = [SKSpriteNode spriteNodeWithImageNamed:@"Note"];
    note.size = size;
    note.position = CGPointMake(self.size.width + note.size.width/2,yPosition);
    note.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:9];
    CGVector direction = radiansToVector(M_PI);
    note.physicsBody.velocity = CGVectorMake(direction.dx * NOTE_SPEED, 0);
    note.physicsBody.restitution = 1.0;
    note.physicsBody.linearDamping = 0.0;
    note.physicsBody.friction = 0.0;
    [_noteLayer addChild:note];
    
}

-(void) didSimulatePhysics
{
  
    [_noteLayer enumerateChildNodesWithName:@"Note" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position))
        {
            [node removeFromParent];
        }
    }];
    
    
}
-(CGFloat) calculateYPositionFromNote:(int)note
{
    CGFloat yPosition;
   // yPosition = (0.5*(note - 56.0))*(self.size.height/28.0);
    
    switch (note) {
     default:
            yPosition = 12*(self.size.height/28.0);
            break;
    }
   return yPosition;
}

-(void)mouseDown:(NSEvent *)theEvent {
     /* Called when a mouse click occurs */
    
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
