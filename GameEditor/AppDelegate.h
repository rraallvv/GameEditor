//
//  AppDelegate.h
//  GameEditor
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>
#import "Utils.h"
#import "HandlesView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, HandlesViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
