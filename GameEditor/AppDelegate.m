//
//  AppDelegate.m
//  GameEditor
//

#import "AppDelegate.h"
#import "GameScene.h"
#import "Utils.h"
#import "HandlesView.h"

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

+ (BOOL)archiveScene:(SKScene *)scene toFile:(NSString *)file {
	/* Retrieve scene file path from the application bundle */
	NSString *nodePath = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];

	/* Unarchive the file to an SKScene object */
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:scene];

	return [data writeToFile:nodePath atomically:YES];
}

@end

@implementation AppDelegate {
	IBOutlet NSTableView *_tableView;
	IBOutlet NSArrayController *_arrayController;
	IBOutlet HandlesView *_handlesView;
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

	_handlesView.scene = scene;
	_handlesView.delegate = self;
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

- (IBAction)saveAction:(id)sender {
	[SKScene archiveScene:self.skView.scene toFile:@"GameScene"];
}

- (void)selectedNode:(SKNode *)node {
	/* Clear the attibutes table's array controller*/
	NSRange range = NSMakeRange(0, [[_arrayController arrangedObjects] count]);
	[_arrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];

	/* Add the attibutes of the selected node */
	[_arrayController addObject: [Property propertyWithName:@"position" node:node type:@"point"]];
	[_arrayController addObject: [Property propertyWithName:@"zRotation" node:node type:@"degrees"]];
	[_arrayController addObject: [Property propertyWithName:@"paused" node:node type:@"bool"]];
	[_tableView reloadData];
}

@end
