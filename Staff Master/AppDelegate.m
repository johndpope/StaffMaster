//
//  AppDelegate.m
//  Staff Master
//
//  Created by Taylor Moss on 11/13/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import "AppDelegate.h"
#import "GameScene.h"
#import "MIDIUtility.h"

@implementation SKScene (Unarchive)

+ (instancetype)unarchiveFromFile:(NSString *)file {
    /* Retrieve scene file path from the application bundle */
    NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];
    /* Unarchive the file to an SKScene object */
    NSData *data = [NSData dataWithContentsOfFile:nodePath
                                          options:NSDataReadingMappedIfSafe
                                            error:nil];
    NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    [arch setClass:self forClassName:@"SKScene"];
    SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [arch finishDecoding];
        
    return scene;
}

@end

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];

    /* Set the scale mode to scale to fit the window */
   // scene.scaleMode = SKSceneScaleModeResizeFill;
    
    scene.Size = self.skView.frame.size;

    
    [self.skView presentScene:scene];

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    self.skView.ignoresSiblingOrder = YES;
    
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    
    [MIDIUtility setupDevice];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end