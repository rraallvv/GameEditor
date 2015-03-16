//
//  AppDelegate.h
//  GameEditor
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>
#import "Utils.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> 

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
