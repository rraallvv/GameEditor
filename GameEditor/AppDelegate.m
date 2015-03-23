//
//  AppDelegate.m
//  GameEditor
//

#import "AppDelegate.h"
#import "GameScene.h"
#import "Utils.h"
#import "EditorView.h"

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
	IBOutlet EditorView *_editorView;
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

	/* Setup the editor view */
	_editorView.scene = scene;
	_editorView.delegate = self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"key"]) {
		return [tableView makeViewWithIdentifier:@"key" owner:self];
	} else {
		NSString *type = [[[_arrayController arrangedObjects] objectAtIndex:row] valueForKey:@"type"];
		NSView *view = [tableView makeViewWithIdentifier:type owner:self];
		if (!view)
			return [tableView makeViewWithIdentifier:@"generic property" owner:self];
		return view;
	}
}

- (IBAction)saveAction:(id)sender {
	[SKScene archiveScene:self.skView.scene toFile:@"GameScene"];
}

- (void)selectedNode:(SKNode *)node {
	/* Clear the attibutes table's array controller*/
	NSRange range = NSMakeRange(0, [[_arrayController arrangedObjects] count]);
	[_arrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];

	/* Populate the attibutes table from the selected node's properties */
	Class classType = [node class];
	do {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(classType, &count);
		for(unsigned int i = 0; i < count; i++) {
			//printf("%s::%s %s\n", [classType description].UTF8String, property_getName(properties[i]), property_getAttributes(properties[i])+1);
			NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[i])];
			NSArray *attibutes = [[NSString stringWithUTF8String:property_getAttributes(properties[i])+1] componentsSeparatedByString:@","];
			NSString *propertyType = [attibutes firstObject];
			if ([propertyName isEqualToString:@"position"]) {
				[_arrayController addObject: [Property propertyWithName:@"position" node:node type:@"point"]];
			} else if ([propertyName isEqualToString:@"zRotation"]){
				[_arrayController addObject: [Property propertyWithName:@"zRotation" node:node type:@"degrees"]];
			} else if ([propertyName isEqualToString:@"paused"]){
				[_arrayController addObject: [Property propertyWithName:@"paused" node:node type:@"bool"]];
			} else {
				[_arrayController addObject: @{
											   @"propertyName": propertyName,
											   @"propertyValue": @YES,
											   @"editable": @NO,
											   @"type": @"",
											   @"node": @""
											   }];
			}
		}
		free(properties);

		classType = [classType superclass];
	} while (classType != nil);

	[_tableView reloadData];
}

@end
