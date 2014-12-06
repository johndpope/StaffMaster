//
//  GameScene.h
//  Staff Master
//

//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene

@property (nonatomic, retain) GameScene * objCClassPtr;

-(void)checkNoteHitWithNumber:(int)userKeyNumber;
@end
