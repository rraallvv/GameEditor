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
#import "AttributesView.h"
#import "LibraryView.h"

#import <SceneKit/SceneKit.h>

#import "LuaContext.h"
#import "LuaExport.h"

#pragma mark Main Window

@interface AppDelegate ()
- (IBAction)delete:(id)sender;
@end

@interface Window : NSWindow
@end

@implementation Window

- (void)keyDown:(NSEvent *)theEvent {
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];

	switch (key) {
		case NSDeleteCharacter:
		case NSBackTabCharacter:
			/* Forward Del and Backspace to the delete action */
			[(AppDelegate *)[NSApp delegate] delete:self];
			return;
	}

	[super keyDown:theEvent];
}

@end

#pragma mark Scene save/load

/* _SCNScene workarounds the error sometimes thrown when unarchiving an SCNScene contained within an SK3DNode */
@interface _SCNScene : SCNScene
@end

@implementation _SCNScene

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	return (id)[[SCNScene alloc] initWithCoder:aDecoder];
}

@end

@implementation SKScene (Archiving)

+ (instancetype)unarchiveFromFile:(NSString *)file {
	/* Retrieve scene file path from the application bundle */
	//file = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];

	/* Unarchive the file to an SKScene object */
#if 0// convert scene data to binary before passing it to the unarchiver
	NSData *plistData = [NSData dataWithContentsOfFile:file];
	NSPropertyListFormat format;
	NSError *error;

	id plist = [NSPropertyListSerialization propertyListWithData:plistData
														 options:NSPropertyListImmutable
														  format:&format
														   error:&error];

	NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist
															  format:NSPropertyListBinaryFormat_v1_0
															 options:0
															   error:&error];
#else
	NSData *data = [NSData dataWithContentsOfFile:file
										  options:NSDataReadingMappedIfSafe
											error:nil];
#endif

	NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	[arch setClass:[_SCNScene class] forClassName:@"SCNScene"];
	SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[arch finishDecoding];

	return scene;
}

+ (BOOL)archiveScene:(SKScene *)scene toFile:(NSString *)file {
	/* Retrieve scene file path from the application bundle */
	//file = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];

	/* Archive the file to an SKScene object */
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *arch = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

#if 0// Save to XML plist format
	[arch setOutputFormat:NSPropertyListXMLFormat_v1_0];
#else
	[arch setOutputFormat:NSPropertyListBinaryFormat_v1_0];
#endif

	id object = scene.hasSingleNode ? scene.children.firstObject : scene;

	[arch encodeObject:object forKey:NSKeyedArchiveRootObjectKey];
	[arch finishEncoding];

	return [data writeToFile:file atomically:YES];
}

- (BOOL)hasSingleNode {
	NSRect frame = self.frame;
	return NSWidth(frame) == 1.0 && NSHeight(frame) == 1.0 && self.children.count == 1;
}

@end

#pragma mark - Application Delegate

@implementation AppDelegate {
	IBOutlet EditorView *_editorView;
	IBOutlet AttributesView *_attributesView;
	IBOutlet NavigatorView *_navigatorView;
	IBOutlet LibraryView *_libraryCollectionView;
	IBOutlet NSTreeController *_attributesTreeController;
	IBOutlet NSTreeController *_navigatorTreeController;
	IBOutlet NSArrayController *_libraryArrayController;
	SKNode *_selectedNode;
	NSString *_currentFilename;
	LuaContext *_sharedLuaContext;
	NSArray *_exportedClasses;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Main window appearance */
	self.window.styleMask = self.window.styleMask;
	self.window.titleVisibility = NSWindowTitleHidden;

	/* Sprite Kit applies additional optimizations to improve rendering performance */
	self.skView.ignoresSiblingOrder = YES;

	self.skView.showsFPS = YES;
	self.skView.showsNodeCount = YES;
	//self.skView.showsPhysics = YES;


	/* Default scene */
	//[self openSceneWithFilename:@"GameScene"];


	/* Setup the editor view */
	_editorView.delegate = self;

	/* Setup the navigator view */
	_navigatorView.delegate = self;
	_navigatorView.dataSource = self;

	/* Enable Drag & Drop */
	[_navigatorView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];
	[_libraryCollectionView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];
	[_editorView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];

	/* Populate the 'Open Recent' file menu from the User default settings */
	NSMutableArray *recentDocuments = [[NSUserDefaults standardUserDefaults] valueForKey:@"recentDocuments"];
	for (NSString *filename in [recentDocuments reverseObjectEnumerator]) {
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	}

	/* Populate the library */
	[self populateLibrary];

	/* Initialize the scripting support */
	_sharedLuaContext = [LuaContext new];
	_exportedClasses = @[[SKNode class], [SKScene class], [SKSpriteNode class], [NSColor class]];
	for (Class class in _exportedClasses) {
		[self exportClass:class toContext:_sharedLuaContext];
	}

	/* Set focus on the editor view */
	[[self window] makeFirstResponder:_editorView];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

#pragma mark Editing

- (IBAction)copy:(id)sender {
	NavigationNode *selection = _navigatorTreeController.selectedObjects.firstObject;
	if (selection && selection.node.parent) {

		NSMutableArray *expansionInfo = [_navigatorView expansionInfoWithNode:_navigatorTreeController.selectedNodes.firstObject];

		NSData *clipData = [NSKeyedArchiver archivedDataWithRootObject:@[selection, expansionInfo]];
		NSPasteboard *cb = [NSPasteboard generalPasteboard];

		[cb declareTypes:[NSArray arrayWithObjects:@"public.binary", nil] owner:self];
		[cb setData:clipData forType:@"public.binary"];
	}
}

- (IBAction)paste:(id)sender {
	NSPasteboard *cb = [NSPasteboard generalPasteboard];
	NSString *type = [cb availableTypeFromArray:[NSArray arrayWithObjects:@"public.binary", nil]];

	if (type) {
		NSData *clipData = [cb dataForType:type];
		id object = [NSKeyedUnarchiver unarchiveObjectWithData:clipData];

		NSIndexPath *selectionIndexPath = _navigatorTreeController.selectionIndexPath;
		NSInteger numberOfChildren = [_navigatorTreeController.selectedNodes.firstObject childNodes].count;

		NSIndexPath *insertionIndexPath = nil;

		if (selectionIndexPath.length > 1) {
			/* IndexPath as a sibling of the selected node */
			NSInteger index = [selectionIndexPath indexAtPosition:selectionIndexPath.length - 1];
			insertionIndexPath = [[selectionIndexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:index + 1];
		} else {
			/* IndexPath as a child of the scene */
			insertionIndexPath = [selectionIndexPath indexPathByAddingIndex:numberOfChildren];
		}

		[self insertObject:object atIndexPath:insertionIndexPath];
	}
}

- (IBAction)delete:(id)sender {
	NavigationNode *selection = _navigatorTreeController.selectedObjects.firstObject;
	if (selection && selection.node.parent) {
		[self removeObjectAtIndexPath:_navigatorTreeController.selectionIndexPath];
	}
}

- (IBAction)cut:(id)sender {
	[self copy:sender];
	[self delete:sender];
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
	[[self.window.undoManager prepareWithInvocationTarget:self] removeObjectAtIndexPath:indexPath];
	[_navigatorTreeController insertObject:object[0] atArrangedObjectIndexPath:indexPath];

	[_navigatorView expandNode:[_navigatorTreeController.arrangedObjects descendantNodeAtIndexPath:indexPath] withInfo:object[1]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath {
	NavigationNode *object = [[_navigatorTreeController.arrangedObjects descendantNodeAtIndexPath:indexPath] representedObject];

	NSMutableArray *expansionInfo = [_navigatorView expansionInfoWithNode:[_navigatorTreeController.arrangedObjects descendantNodeAtIndexPath:indexPath]];

	[[self.window.undoManager prepareWithInvocationTarget:self] insertObject:@[object, expansionInfo] atIndexPath:indexPath];
	[_navigatorTreeController removeObjectAtArrangedObjectIndexPath:indexPath];
}

#pragma mark Selection handling

- (void)editorView:(EditorView *)editorView didSelectNode:(id)node {
	[self updateSelectionWithNode:node];
}

- (void)navigatorView:(NavigatorView *)navigatorView didSelectObject:(id)object {
	[self updateSelectionWithNode:[object node]];
}

- (void)updateSelectionWithNode:(id)node {
	if (_selectedNode == node)
		return;

	_selectedNode = node;

	[_editorView setNode:node];

	// TODO: enable Grand Central Dispatch and add a custom queue to process input events
#define USE_GCD	0
#if USE_GCD
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#endif
		/* Build the tree of attributes in the background thread */
		NSMutableArray *contents = [self attributesForAllClassesWithNode:node];

		/* Look up for the row to be selected */
		NSInteger row = [_navigatorView rowForItem:[self navigationNodeOfObject:node inNodes:[[_navigatorTreeController arrangedObjects] childNodes]]];

#if USE_GCD
		dispatch_async(dispatch_get_main_queue(), ^{
#endif
			/* Replace the attributes table */
			[_attributesTreeController setContent:contents];

			/* Expand all the root nodes in the attributes view */
			for (id item in [[_attributesTreeController arrangedObjects] childNodes])
				[_attributesView expandItem:item expandChildren:NO];

			/* Ask the editor view to repaint the selection */
			[_editorView setNeedsDisplay:YES];

			/* Update the selection in the navigator view */
			[_navigatorView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
#if USE_GCD
		});
	});
#endif
}

#pragma mark Attributes creation

- (NSMutableArray *)attributesForAllClassesWithNode:(id)node {

	NSMutableArray *classesArray = [NSMutableArray array];

	Class classType = [node class];

	do {
		NSMutableArray *attributesArray = [self attributesForClass:classType node:node];

		if (attributesArray.count > 0) {
			[classesArray addObject:@{@"name": [classType description],
									  @"isLeaf": @NO,
									  @"isEditable": @NO,
									  @"children":attributesArray}];
		}

		classType = [classType superclass];

	} while (classType != nil
			 && classType != [SKNode superclass]
			 && classType != [NSObject class]);

	return classesArray;
}

- (NSMutableArray *)attributesForClass:(Class)classType node:(id)node {
	unsigned int count;
	objc_property_t *properties = class_copyPropertyList(classType, &count);

	NSMutableArray *attributesArray = [NSMutableArray array];

	BOOL hasZPositionRotation = NO;
	BOOL hasSpeed = NO;
	BOOL hasEmissionAngle = NO;
	BOOL hasLifetime = NO;
	BOOL hasXYAcceleration = NO;
	BOOL hasXYScale = NO;
	BOOL hasXYRotation = NO;
	BOOL hasParticleZPositionRangeSpeed = NO;
	BOOL hasParticleScaleRangeSpeed = NO;
	BOOL hasParticleRotationRangeSpeed = NO;
	BOOL hasParticleAlphaRangeSpeed = NO;
	BOOL hasParticleColorBlendFactor = NO;
	BOOL hasParticleColorRed = NO;
	BOOL hasParticleColorGreen = NO;
	BOOL hasParticleColorBlue = NO;
	BOOL hasParticleColorAlpha = NO;

	if (count) {
		for (unsigned int i = 0; i < count; i++) {
			//printf("%s::%s %s\n", [classType description].UTF8String, property_getName(properties[i]), property_getAttributes(properties[i])+1);
			NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])+1];

			BOOL editable = [propertyAttributes rangeOfString:@",R(,|$)" options:NSRegularExpressionSearch].location == NSNotFound;

			if (!editable)
				continue;

			NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[i])];
			NSString *propertyType = [[propertyAttributes componentsSeparatedByString:@","] firstObject];

			if ([node isKindOfClass:[SKScene class]]
				&& ([propertyName isEqualToString:@"position"]
					|| [propertyName isEqualToString:@"zPosition"]
					|| [propertyName isEqualToString:@"zRotation"]
					|| [propertyName isEqualToString:@"xScale"]
					|| [propertyName isEqualToString:@"yScale"]
					|| [propertyName isEqualToString:@"visibleRect"]
					|| [propertyName isEqualToString:@"visibleRectCenter"]
					|| [propertyName isEqualToString:@"visibleRectSize"])) {
				[attributesArray addObject:[AttributeNode attributeForNonEditableValue:propertyName type:propertyType]];

			} else if ([propertyName rangeOfString:@"^z(Position|Rotation)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasZPositionRotation) {
					AttributeNode *attribute = [AttributeNode attributeWithName:@"z,zPosition,zRotation"
																		   node:node
																		   type:@"{dd}"
																	  formatter:@[[NSNumberFormatter integerFormatter],
																				  [NSNumberFormatter degreesFormatter]]
															   valueTransformer:@[[NSNull null],
																				  [DegreesTransformer transformer]]];
					attribute.labels = @[@"Position", @"Rotation"];
					[attributesArray addObject:attribute];
					hasZPositionRotation = YES;
				}

			} else if ([propertyName rangeOfString:@"^emissionAngle(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasEmissionAngle) {
					AttributeNode *attribute = [AttributeNode attributeWithName:@"emissionAngle,emissionAngle,emissionAngleRange"
																		   node:node
																		   type:@"{dd}"
																	  formatter:[NSNumberFormatter degreesFormatter]
															   valueTransformer:[DegreesTransformer transformer]];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasEmissionAngle = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorRed(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorRed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"red,particleColorRedSpeed,particleColorRedRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorRed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorGreen(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorGreen) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"green,particleColorGreenSpeed,particleColorGreenRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorGreen = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorBlue(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlue) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"blue,particleColorBlueSpeed,particleColorBlueRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorBlue = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorAlpha(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorAlpha) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleColorAlphaSpeed,particleColorAlphaRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorAlpha = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleSpeed(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"speed,particleSpeed,particleSpeedRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleLifetime(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasLifetime) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"lifetime,particleLifetime,particleLifetimeRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasLifetime = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Acceleration$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYAcceleration) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"acceleration,xAcceleration,yAcceleration" node:node type:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYAcceleration = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Scale$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYScale) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,xScale,yScale" node:node type:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYScale = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Rotation$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYRotation) {
					AttributeNode *attribute = [AttributeNode attributeWithName:@"rotation,xRotation,yRotation"
																		   node:node
																		   type:@"{dd}"
																	  formatter:[NSNumberFormatter degreesFormatter]
															   valueTransformer:[DegreesTransformer transformer]];

					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYRotation = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleZPosition(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleZPositionRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"zPosition,particleZPosition,particleZPositionRange,particleZPositionSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleZPositionRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleScale(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleScaleRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,particleScale,particleScaleRange,particleScaleSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleScaleRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleRotation(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleRotationRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"rotation,particleRotation,particleRotationRange,particleRotationSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleRotationRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleAlpha(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleAlphaRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleAlpha,particleAlphaRange,particleAlphaSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleAlphaRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorBlendFactor(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlendFactor) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"colorBlendFactor,particleColorBlendFactor,particleColorBlendFactorRange,particleColorBlendFactorSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleColorBlendFactor = YES;
				}

			} else {

				Class propertyClass = [propertyType classType];

				if ([propertyType isEqualToEncodedType:@encode(NSString)]) {
					[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node type:propertyType]];

				} else if ([propertyType isEqualToEncodedType:@encode(NSColor)]) {
					[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node type:propertyType]];

				} else if (propertyClass == [SKTexture class]
						   || propertyClass == [SKShader class]
						   || propertyClass == [SKPhysicsBody class]
						   || propertyClass == [SKPhysicsWorld class]) {
					[attributesArray addObject:@{@"name": propertyName,
												 @"isLeaf": @NO,
												 @"isEditable": @NO,
												 @"children":[self attributesForClass:propertyClass node:[node valueForKey:propertyName]]}];

				} else if ([propertyName rangeOfString:@"rotation" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					[attributesArray addObject:[AttributeNode  attributeForRotationAngleWithName:propertyName node:node]];

				} else {
					NSCharacterSet *nonEditableTypes = [NSCharacterSet characterSetWithCharactersInString:@"^?b:#@*v"];
					editable = ![propertyType isEqualToString:@""] && [propertyType rangeOfCharacterFromSet:nonEditableTypes].location == NSNotFound;

					AttributeNode *attribute;

					if (editable) {
						if (![propertyName containsString:@"anchorPoint"]
							&& ![propertyName containsString:@"centerRect"]
							&& ([propertyType isEqualToEncodedType:@encode(CGPoint)]
								|| [propertyType isEqualToEncodedType:@encode(CGSize)]
								|| [propertyType isEqualToEncodedType:@encode(CGRect)])) {
							attribute = [AttributeNode attributeForNormalPrecisionValueWithName:propertyName node:node type:propertyType];

						} else if ([propertyName containsString:@"colorBlendFactor"]
								   || [propertyName containsString:@"alpha"]) {
							attribute = [AttributeNode attributeForNormalizedValueWithName:propertyName node:node type:propertyType];

						} else if ([propertyType isEqualToEncodedType:@encode(short)]
								   || [propertyType isEqualToEncodedType:@encode(int)]
								   || [propertyType isEqualToEncodedType:@encode(long)]
								   || [propertyType isEqualToEncodedType:@encode(long long)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned short)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned int)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned long)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned long long)]) {
							attribute = [AttributeNode attributeForIntegerValueWithName:propertyName node:node type:propertyType];

						} else {
							attribute = [AttributeNode attributeForHighPrecisionValueWithName:propertyName node:node type:propertyType];
						}

						if ([propertyType isEqualToEncodedType:@encode(CGPoint)]
							|| [propertyType isEqualToEncodedType:@encode(CGVector)]) {
							attribute.labels = @[@"X", @"Y"];
						} else if ([propertyType isEqualToEncodedType:@encode(CGSize)]) {
							attribute.labels = @[@"W", @"H"];
						} else if ([propertyType isEqualToEncodedType:@encode(CGRect)]) {
							attribute.labels = @[@"X", @"Y", @"W", @"H"];
						}

						[attributesArray addObject:attribute];
					}
#if 1// Show a dummy attribute for non-editable properties
					else {
						[attributesArray addObject:[AttributeNode attributeForNonEditableValue:propertyName type:propertyType]];
					}
#endif
				}
			}
		}
		free(properties);
	}

	return attributesArray;
}

#pragma mark File handling

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	return [self openSceneWithFilename:filename];
}

- (IBAction)newDocument:(id)sender {
	/* Create a new scene with the default size */
	SKScene *scene = [SKScene sceneWithSize:CGSizeMake(1024.0, 768.0)];
	[self useScene:scene];
	_currentFilename = nil;
}

- (IBAction)openDocument:(id)sender {
	/* Get an instance of the open file dialogue */
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];

	/* Filter the file list showing SpriteKit files */
	openPanel.allowedFileTypes = @[@"sks"];

	/* Launch the open dialogue */
	[openPanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSModalResponseOK) {
							  /* Get the selected file's URL */
							  NSURL *selection = openPanel.URLs.firstObject;
							  /* Store the selected file's path as a string */
							  NSString *filename = [[selection path] stringByResolvingSymlinksInPath];
							  /* Try to open the file */
							  [self openSceneWithFilename:filename];
						  }
						  
					  }];
}

- (IBAction)saveDocument:(id)sender {
	if (_currentFilename) {
		[SKScene archiveScene:self.skView.scene toFile:_currentFilename];
	} else {
		[self saveDocumentAs:sender];
	}
}

- (IBAction)saveDocumentAs:(id)sender {
	/* Get an instance of the save file dialogue */
	NSSavePanel * savePanel = [NSSavePanel savePanel];

	/* Filter the file list showing SpriteKit files */
	[savePanel setAllowedFileTypes:@[@"sks"]];

	/* Launch the save dialogue */
	[savePanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSModalResponseOK) {
							  /* Get the selected file's URL */
							  NSURL *selection = savePanel.URL;
							  /* Store the selected file's path as a string */
							  NSString *filename = [[selection path] stringByResolvingSymlinksInPath];
							  /* Save to the selected the file */
							  [SKScene archiveScene:self.skView.scene toFile:filename];
							  _currentFilename = filename;
						  }
					  }];
}

- (IBAction)performClose:(id)sender {
	[self removeScene];
	_currentFilename = nil;
}

- (void)addRecentDocument:(NSString *)filename {
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *recentDocuments = [[userDefaults valueForKey:@"recentDocuments"] mutableCopy];
	if (!recentDocuments) {
		recentDocuments = [NSMutableArray array];
	} else if ([recentDocuments indexOfObject:filename] != NSNotFound) {
		return;
	}
	[recentDocuments addObject:filename];
	[userDefaults setObject:recentDocuments forKey:@"recentDocuments"];
	[userDefaults synchronize];
}

#pragma mark Library

- (IBAction)libraryModeAction:(NSButton *)sender {
	_libraryCollectionView.mode = sender.state ? LibraryViewModeIcons : LibraryViewModeList;
}

- (void)populateLibrary {
	NSURL *plugInsURL = [[NSBundle mainBundle] builtInPlugInsURL];

	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:plugInsURL
																	  includingPropertiesForKeys:@[ NSURLNameKey, NSURLIsDirectoryKey ]
																						 options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
																					errorHandler:nil];

	NSPredicate *filter = [NSPredicate predicateWithFormat: @"pathExtension = 'geextension'"];

	NSArray *directoryEntries = [directoryEnumerator.allObjects filteredArrayUsingPredicate: filter];

	directoryEntries = [directoryEntries sortedArrayUsingComparator:^(NSURL* a, NSURL* b) {
		return [[a lastPathComponent] compare:[b lastPathComponent] options:NSNumericSearch];
	}];

	for (NSURL *aURL in directoryEntries) {
		NSNumber *isDirectory;
		[aURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];

		if (isDirectory) {
			NSBundle *bundle = [NSBundle bundleWithURL:aURL];
			NSDictionary *info = [bundle infoDictionary];

			if (info) {
				/* Item's name */
				NSString *itemName = info[@"CFBundleDisplayName"];
				if (!itemName) {
					itemName = @"No name";
				}

				/* Item's description */
				NSString *itemDescription = info[@"Description"];
				if (!itemDescription) {
					itemDescription = @"No description";
				}

				/* Item's image */
				NSString *itemIconPath = [aURL.path stringByAppendingPathComponent:info[@"CFBundleIconFile"]];
				NSImage *itemIconImage = [[NSImage alloc] initWithContentsOfFile:itemIconPath];
				if (!itemIconImage) {
					itemIconImage = [NSImage imageNamed:NSImageNameInfo];
				}

				/* Item's full description */
				NSString *fullDescription = [NSString stringWithFormat:@"%@ - %@", itemName, itemDescription];
				NSRange itemNameRange = NSMakeRange(0, [itemName length]);
				NSRange itemDescriptionRange = NSMakeRange(itemNameRange.length, fullDescription.length - itemNameRange.length);
				NSMutableAttributedString *fullDescriptionAttributedString = [[NSMutableAttributedString alloc] initWithString:fullDescription];
				[fullDescriptionAttributedString beginEditing];
				[fullDescriptionAttributedString addAttribute:NSFontAttributeName
														value:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]
														range:itemNameRange];
				[fullDescriptionAttributedString addAttribute:NSFontAttributeName
														value:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
														range:itemDescriptionRange];
				[fullDescriptionAttributedString endEditing];

				/* Item's script */
				NSString *itemScript = info[@"Script"];
				if (!itemScript) {
					NSString *itemScriptPath = [aURL.path stringByAppendingPathComponent:info[@"Script File"]];
					itemScript = [[NSString alloc] initWithContentsOfFile:itemScriptPath encoding:NSUTF8StringEncoding error:nil];
				}
				if (!itemScript) {
					itemScript = (id)[NSNull null];
				}

				/* Add the item to the library */
				[_libraryArrayController addObject:@{@"label":fullDescriptionAttributedString,
													 @"image":itemIconImage,
													 @"showLabel":@YES,
													 @"script":itemScript}.mutableCopy];
			}
		}
	}

	[_libraryArrayController setSelectionIndex:0];
}

#pragma mark Editor Dragging Destination

- (NSDragOperation)editorView:(EditorView *)editorView draggingEntered:(id)item {
	return NSDragOperationCopy;
}

- (BOOL)editorView:(EditorView *)editorView performDragOperation:(id)item atLocation:(CGPoint)locationInScene {
	if (!_editorView.scene) {
		return NO;
	}

	LuaContext *itemLuaContext = [[LuaContext alloc] initWithVirtualMachine:_sharedLuaContext.virtualMachine];
	itemLuaContext[@"scene"] = _editorView.scene;

	for (Class class in _exportedClasses) {
		itemLuaContext[[class className]] = class;
	}

	NSString *script = [item objectForKey:@"script"];
	if ([script isEqual:[NSNull null]])
		script = nil;
	NSError *error = nil;
	[itemLuaContext parse:script error:&error];

	if (error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}

	SKNode *node = [itemLuaContext call:@"createNodeAtPosition" with:@[[NSValue valueWithPoint:locationInScene]] error:&error];

	if (error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return NO;
	}

	if (node) {
		NSIndexPath *selectionIndexPath = [_navigatorTreeController selectionIndexPath];
		if (selectionIndexPath) {
			[_navigatorTreeController insertObject:[NavigationNode navigationNodeWithNode:node]
						 atArrangedObjectIndexPath:[selectionIndexPath indexPathByAddingIndex:0]];
		}
	}

	return YES;
}

#pragma mark Scene

- (BOOL)openSceneWithFilename:(NSString *)filename {

	if ([_currentFilename isEqualToString:filename]) {
		/* The file is already open */
		return YES;
	}

	SKScene *scene = [SKScene unarchiveFromFile:filename];

	if (!scene) {
		NSLog(@"Couldn't open file: '%@'", filename);
		return NO;
	}

	[self useScene:scene];

	/* Add the file to the 'Open Recent' file menu */
	[self addRecentDocument:filename];

	_currentFilename = filename;

	return YES;
}

- (void)prepareScene:(SKScene *)scene {
#if 0
	/* Create test shape from points */

	CGPoint points[] = {{0,0}, {-40, -40}, {80, 0}, {0, 120}, {0,0}};
	SKShapeNode *shapeNode1 = [SKShapeNode shapeNodeWithPoints:points count:5];
	shapeNode1.strokeColor = [SKColor blueColor];
	shapeNode1.lineWidth = 5.0;
	shapeNode1.position = CGPointMake(200, 100);
	shapeNode1.zRotation = -M_PI_4;
	[self addChild:shapeNode1];

	/* Create shape from path */

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, nil, 0, 0);
	CGPathAddLineToPoint(path, nil, 80, -50);
	CGPathAddLineToPoint(path, nil, 0, 100);
	CGPathAddLineToPoint(path, nil, -80, -50);
	CGPathCloseSubpath(path);
	SKShapeNode *shapeNode2 = [SKShapeNode shapeNodeWithPath:path];
	CGPathRelease(path);
	shapeNode2.strokeColor = [SKColor yellowColor];
	shapeNode2.fillColor = [SKColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.5];
	shapeNode2.lineWidth = 5.0;
	shapeNode2.position = CGPointMake(400, 100);
	shapeNode2.zRotation = M_PI_4;
	[self addChild:shapeNode2];

	/* Add a particles emitter */

	NSString *particlesPath = [[NSBundle mainBundle] pathForResource:@"Particles" ofType:@"sks"];
	SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:particlesPath];
	emitter.position = CGPointMake(self.size.width/2, self.size.height/2);
	[self addChild:emitter];

	/* Add the scene physics body */

	SKPhysicsBody *borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
	self.physicsBody = borderBody;

	/* Add a SceneKit scene */

	CGPoint center = CGPointMake(CGRectGetMidX(scene.frame),CGRectGetMidY(scene.frame));
	SCNScene *spaceShip = [SCNScene sceneNamed:@"art.scnassets/ship.dae"];
	SK3DNode *spaceShipNode = [SK3DNode nodeWithViewportSize:CGSizeMake(200, 200)];
	spaceShipNode.scnScene = spaceShip;
	spaceShipNode.position = center;
	[scene addChild:spaceShipNode];
#endif

	[self advanceEmittersInNode:self];

	[scene setPaused:YES];
}

- (void)removeScene {
	[_attributesTreeController setContent:nil];
	[_navigatorTreeController setContent:nil];
	_editorView.scene = nil;
	_editorView.needsDisplay = YES;
	[self.skView presentScene:nil];
}

- (void)useScene:(SKScene *)scene {
	[_navigatorTreeController setContent:[NavigationNode navigationNodeWithNode:scene]];
	[_navigatorView expandItem:nil expandChildren:YES];

	/* Set the scale mode to scale to fit the window */
	if (![scene isKindOfClass:[SKScene class]]) {
		id node = scene;
		scene = [[SKScene alloc] init];
		[scene addChild:node];
	}

	scene.scaleMode = SKSceneScaleModeAspectFit;

	[self.skView presentScene:scene];

	_editorView.scene = scene;
	_sharedLuaContext[@"scene"] = scene;

	[_editorView updateVisibleRect];

	[self performSelector:@selector(updateSelectionWithNode:) withObject:scene afterDelay:0.5];
}

#pragma mark Helper methods

- (id)navigationNodeOfObject:(id)anObject inNodes:(NSArray *)nodes {
	for (int i = 0; i < nodes.count; ++i) {
		NSTreeNode *node = nodes[i];
		if ([[[node representedObject] node] isEqual:anObject]) {
			return node;
		}
		if ([[node childNodes] count]) {
			id result = [self navigationNodeOfObject:anObject inNodes:[node childNodes]];
			if (result) {
				return result;
			}
		}
	}
	return nil;
}

- (void)advanceEmittersInNode:(id)node {
	if ([node isKindOfClass:[SKEmitterNode class]]) {
		SKEmitterNode *emitter = node;
		[emitter advanceSimulationTime:0.41 * emitter.particleLifetime];
	}
	for (id child in [node children]) {
		[self advanceEmittersInNode:child];
	}
}

- (void)exportClass:(Class)class toContext:(LuaContext *)context {
	// Create a protocol that inherits from LuaContext and with all the public methods and properties of the class
	const char *protocolName = [NSString stringWithFormat:@"%sLuaExports", class_getName(class)].UTF8String;
	Protocol *protocol = objc_getProtocol(protocolName);
	if (!protocol) {
		protocol = objc_allocateProtocol(protocolName);

		protocol_addProtocol(protocol, @protocol(LuaExport));

		// Add the public methods of the class to the protocol
		unsigned int methodCount, classMethodCount, propertyCount;
		Method *methods, *classMethods;
		objc_property_t *properties;

		methods = class_copyMethodList(class, &methodCount);
		for (NSUInteger methodIndex = 0; methodIndex < methodCount; ++methodIndex) {
			Method method = methods[methodIndex];
			protocol_addMethodDescription(protocol, method_getName(method), method_getTypeEncoding(method), YES, YES);
		}

		classMethods = class_copyMethodList(object_getClass(class), &classMethodCount);
		for (NSUInteger methodIndex = 0; methodIndex < classMethodCount; ++methodIndex) {
			Method method = classMethods[methodIndex];
			protocol_addMethodDescription(protocol, method_getName(method), method_getTypeEncoding(method), YES, NO);
		}

		properties = class_copyPropertyList(class, &propertyCount);
		for (NSUInteger propertyIndex = 0; propertyIndex < propertyCount; ++propertyIndex) {
			objc_property_t property = properties[propertyIndex];

			unsigned int attributeCount;
			objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);
			protocol_addProperty(protocol, property_getName(property), attributes, attributeCount, YES, YES);
			free(attributes);
		}

		free(methods);
		free(classMethods);
		free(properties);

		// Add the new protocol to the class
		objc_registerProtocol(protocol);
	}
	class_addProtocol(class, protocol);

	NSString *className = [NSString stringWithCString:class_getName(class) encoding:NSUTF8StringEncoding];
	context[className] = class;
}

@end
