//
//  AppDelegate.h
//  GameEditor
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>
#import "Utils.h"
#import "EditorView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, EditorViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
