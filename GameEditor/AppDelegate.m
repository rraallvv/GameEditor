//
//  AppDelegate.m
//  GameEditor
//

#import "AppDelegate.h"
#import "GameScene.h"
#import "Utils.h"

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

@implementation AppDelegate {
	IBOutlet NSTextField *_positionTextField;
	IBOutlet NSTextField *_rotationTextField;
	IBOutlet NSButton *_pausedButton;
	IBOutlet NSTableView *_tableView;
	IBOutlet NSArrayController *_arrayController;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	/* Main window appearance */
	self.window.styleMask = self.window.styleMask | NSFullSizeContentViewWindowMask;
	self.window.titleVisibility = NSWindowTitleHidden;
	self.window.titlebarAppearsTransparent = YES;

    GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];

    /* Set the scale mode to scale to fit the window */
    scene.scaleMode = SKSceneScaleModeAspectFit;

    [self.skView presentScene:scene];

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    self.skView.ignoresSiblingOrder = YES;
    
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;

	SKSpriteNode *sprite = (SKSpriteNode *)[scene childNodeWithName:@"//Spaceship"];

	/* Bindings */
	[_arrayController addObject: [Property propertyWithName:@"position" node:sprite type:@"point"]];
	[_arrayController addObject: [Property propertyWithName:@"zRotation" node:sprite type:@"degrees"]];
	[_arrayController addObject: [Property propertyWithName:@"paused" node:sprite type:@"bool"]];

	/* Property views */
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"PointTableCellView" bundle:nil];
	NSArray *topLevelObjects;
	[nib instantiateWithOwner:self topLevelObjects:&topLevelObjects];

	[_tableView registerNib:nib forIdentifier:@"point"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"key"]) {
		return [tableView makeViewWithIdentifier:@"key" owner:self];
	} else {
		NSString *type = [[[_arrayController arrangedObjects] objectAtIndex:row] valueForKey:@"type"];
		return [tableView makeViewWithIdentifier:type owner:self];
	}
}

@end
