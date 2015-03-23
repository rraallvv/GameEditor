//
//  AppDelegate.h
//  GameEditor
//

#define NSLog(FORMAT, ...) fprintf( stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>
#import "EditorView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, EditorViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
