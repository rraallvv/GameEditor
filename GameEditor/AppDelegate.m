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
    GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];

    /* Set the scale mode to scale to fit the window */
    scene.scaleMode = SKSceneScaleModeAspectFit;

    [self.skView presentScene:scene];

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    self.skView.ignoresSiblingOrder = YES;
    
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;

	// The bindings
	SKSpriteNode *sprite = (SKSpriteNode *)[scene childNodeWithName:@"//Spaceship"];
	Property *positionProperty = [Property propertyWithName:@"position" node:sprite type:@"point"];

	// Bind the individual controls on the left side of the window
	[_positionTextField bind:@"value" toObject:positionProperty withKeyPath:@"x" options:nil];
	[_rotationTextField bind:@"value" toObject:sprite withKeyPath:@"zRotation" options:[DegreesTransformer transformer]];
	[_pausedButton bind:@"value" toObject:sprite withKeyPath:@"paused" options:nil];

	// Bind the table on the right side of the window
	[_arrayController addObject: positionProperty];
	[_arrayController addObject: [Property propertyWithName:@"zRotation" node:sprite type:@"degrees"]];
	[_arrayController addObject: [Property propertyWithName:@"paused" node:sprite type:@"bool"]];
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
