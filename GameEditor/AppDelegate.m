/*
 * AppDelegate.m
 * GameEditor
 *
 * Copyright (c) 2015 Rhody Lugo.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "AppDelegate.h"
#import "GameScene.h"
#import "Attribute.h"
#import "OutlineView.h"

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
	IBOutlet EditorView *_editorView;
	IBOutlet NSTreeController *_treeController;
	IBOutlet NSOutlineView *_outlineView;
	NSMutableDictionary *_prefferedSizes;
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

	/* Prepare the editors for the outline view */
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"ValueEditors" bundle:nil];
	NSArray* objects;
	[nib instantiateWithOwner:self topLevelObjects:&objects];

	_prefferedSizes = [NSMutableDictionary dictionary];

	for (id object in objects) {
		if ([object isKindOfClass:[NSTableCellView class]]) {
			NSTableCellView *tableCelView = object;

			/* Register the identifiers for each editors */
			[_outlineView registerNib:nib forIdentifier:tableCelView.identifier];

			/* Fetch the preffered size for the editor's view */
			_prefferedSizes[tableCelView.identifier] = [NSValue valueWithSize:tableCelView.frame.size];
		}
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([self isGroupItem:item]) {
		return [outlineView makeViewWithIdentifier:@"group" owner:self];
	} else if ([[tableColumn identifier] isEqualToString:@"key"]) {
		return [outlineView makeViewWithIdentifier:@"name" owner:self];
	} else {
		NSString *type = [[item representedObject] valueForKey:@"type"];
		NSView *view = [outlineView makeViewWithIdentifier:type owner:self];
		if (!view)
			return [outlineView makeViewWithIdentifier:@"generic attribute" owner:self];
		return view;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return [self isGroupItem:item];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	NSString *type = [[item representedObject] valueForKey:@"type"];
	NSSize size = [_prefferedSizes[type] sizeValue];
	return MAX(20, size.height);
}

- (BOOL) isGroupItem:(id)item {
	return [[item indexPath] length] < 2;
}

- (IBAction)saveAction:(id)sender {
	[SKScene archiveScene:self.skView.scene toFile:@"GameScene"];
}

- (void)selectedNode:(SKNode *)node {

	/* Clear the attibutes table */
	[_treeController setContent:nil];

	/* Populate the attibutes table from the selected node's properties */
	Class classType = [node class];
	do {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(classType, &count);

		if (count) {
			NSMutableArray *children = [NSMutableArray array];

			for(unsigned int i = 0; i < count; i++) {
				//printf("%s::%s %s\n", [classType description].UTF8String, property_getName(properties[i]), property_getAttributes(properties[i])+1);
				NSString *attributeName = [NSString stringWithUTF8String:property_getName(properties[i])];
				NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])+1];
				NSArray *attibutesArray = [attributes componentsSeparatedByString:@","];
				NSString *attributeType = [attibutesArray firstObject];

				if ([attributeName rangeOfString:@"rotation" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					Attribute *attribute = [Attribute attributeWithName:attributeName node:node type:@"degrees" options:[DegreesTransformer transformer]];
					[children addObject:attribute];
				} else if ([attributeName rangeOfString:@"color" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					Attribute *attribute = [Attribute attributeWithName:attributeName node:node type:attributeType options:nil];
					[children addObject:attribute];
				} else {
					BOOL editable = [attributes rangeOfString:@",R(,|$)" options:NSRegularExpressionSearch].location == NSNotFound;
					NSCharacterSet *nonEditableTypes = [NSCharacterSet characterSetWithCharactersInString:@"^?b:#@*v"];
					editable = editable && [attributeType rangeOfCharacterFromSet:nonEditableTypes].location == NSNotFound;

					if (editable) {
						Attribute *attribute = [Attribute attributeWithName:attributeName node:node type:attributeType options:nil];
						[children addObject:attribute];
					} else {
#if 1// Show non editable properties
						NSDictionary *attribute = @{@"name": attributeName,
													@"value": @"(non-editable)",
													@"type": @"generic attribute",
													@"node": [NSNull null],
													@"description": [NSString stringWithFormat:@"%@ %@", attributeName, attributeType],
													@"isLeaf": @YES,
													@"isEditable": @NO};
						[children addObject:attribute];
#endif
					}
				}
			}
			free(properties);

			[_treeController addObject:@{@"name": [classType description],
										 @"isLeaf": @NO,
										 @"isEditable": @NO,
										 @"children":children}];
		}

		classType = [classType superclass];
	} while (classType != nil && classType != [SKNode superclass]);

	// Expand all the groups
	[_outlineView expandItem:nil expandChildren:YES];
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
}

@end
