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
#import "InspectorTableView.h"
#import "LibraryView.h"
#import <SceneKit/SceneKit.h>
#import "LuaContext.h"
#import "LuaExport.h"
#import "UserDataView.h"
#import "ValueTransformers.h"
#import "NSBundle+ProxyBundle.h"

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
			if ([self.firstResponder respondsToSelector:@selector(delete:)]) {
				[(id)self.firstResponder delete:self];
				return;
			}
	}

	[super keyDown:theEvent];
}

@end

#pragma mark Scene save/load

/*
 Used to workaround the error sometimes thrown when unarchiving an SCNScene contained within an SK3DNode
 TODO: check wheter this is still lurking around
 */
@interface _SCNScene : SCNScene
@end

@implementation _SCNScene

- (id)initWithCoder:(NSCoder *)aDecoder {
	return (id)[[SCNScene alloc] initWithCoder:aDecoder];
}

@end

#pragma mark - Application Delegate

@interface AppDelegate () <NSApplicationDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, EditorViewDelegate, NavigatorViewDelegate, LibraryViewDelegate>

@end

@implementation AppDelegate {
	IBOutlet EditorView *_editorView;
	IBOutlet InspectorTableView *_nodeInspectorView;
	IBOutlet InspectorTableView *_identityInspectorView;
	IBOutlet NavigatorView *_navigatorView;
	IBOutlet LibraryView *_objectLibraryCollectionView;
	IBOutlet LibraryView *_mediaLibraryCollectionView;
	IBOutlet NSTreeController *_nodeInspectorTreeController;
	IBOutlet NSTreeController *_identityInspectorTreeController;
	IBOutlet NSTreeController *_navigatorTreeController;
	IBOutlet NSArrayController *_objectLibraryArrayController;
	IBOutlet NSArrayController *_mediaLibraryArrayController;
	IBOutlet NSButton *_objectLibraryModeButton;
	IBOutlet NSButton *_mediaLibraryModeButton;
	IBOutlet NSMatrix *_libraryTabButtons;
	IBOutlet NSMatrix *_inspectorTabButtons;
	IBOutlet NSView *_saveSceneView;
	IBOutlet NSButton *_useXMLFormatButton;
	IBOutlet NSTabView *_libraryTabView;
	IBOutlet NSTabView *_inspectorTabView;
	SKNode *_selectedNode;
	NSString *_currentFilename;
	NSBundle *_sceneBundle;
	NSString *_sceneBundlePath;
	NSArray *_exportedClasses;
	LuaContext *_sharedScriptingContext;
	NSPropertyListFormat _sceneFormat;
	NSMutableArray *_objectLibraryItems;
	NSMutableArray *_mediaLibraryItems;
	NSInteger _objectSelectedLibraryItem;
	NSInteger _mediaSelectedLibraryItem;
	NSMutableArray *_objectLibraryContext;
	NSMutableArray *_mediaLibraryContext;
	NSMutableDictionary *_inspectorViewExpansionInfo;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Sprite Kit applies additional optimizations to improve rendering performance */
	self.skView.ignoresSiblingOrder = YES;

	self.skView.showsFPS = YES;
	self.skView.showsNodeCount = YES;
	self.skView.showsPhysics = YES;


	/* Default scene */
	//[self openSceneWithFilename:@"GameScene"];


	/* Setup the editor view */
	_editorView.delegate = self;

	/* Setup the navigator view */
	_navigatorView.delegate = self;
	_navigatorView.dataSource = self;

	/* Enable Drag & Drop */
	[_navigatorView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];
	[_objectLibraryCollectionView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];
	[_mediaLibraryCollectionView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];
	[_editorView registerForDraggedTypes:[NSArray arrayWithObject: @"public.binary"]];

	/* Populate the 'Open Recent' file menu from the User default settings */
	NSMutableArray *recentDocuments = [[NSUserDefaults standardUserDefaults] valueForKey:@"recentDocuments"];
	for (NSString *filename in [recentDocuments reverseObjectEnumerator]) {
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
	}

	/* Setup the attributes inspector */
	[_inspectorTabView selectTabViewItemAtIndex:_inspectorTabButtons.selectedColumn];
	_inspectorViewExpansionInfo = [NSMutableDictionary dictionary];

	/* Setup the library */
	[_libraryTabView selectTabViewItemAtIndex:_libraryTabButtons.selectedColumn];
	_objectLibraryCollectionView.delegate = self;
	_mediaLibraryCollectionView.delegate = self;
	_objectSelectedLibraryItem = NSNotFound;
	_mediaSelectedLibraryItem = NSNotFound;
	_objectLibraryCollectionView.mode = _objectLibraryModeButton.state ? LibraryViewModeIcons : LibraryViewModeList;
	_mediaLibraryCollectionView.mode = _mediaLibraryModeButton.state ? LibraryViewModeIcons : LibraryViewModeList;
	[self populateObjectLibrary];

	/* Initialize the scripting support */
	_sharedScriptingContext = [LuaContext new];

	/* Cache the exported classes */
	_exportedClasses = @[[SKColor class],
						 [SKNode class],
						 [SKScene class],
						 [SKSpriteNode class],
						 [SKLightNode class],
						 [SKEmitterNode class],
						 [SKShapeNode class],
						 [SKLabelNode class],
						 [SKFieldNode class]];
	for (Class class in _exportedClasses) {
		[self exportClass:class toContext:_sharedScriptingContext];
	}

	/* Set focus on the editor view */
	[[self window] makeFirstResponder:_editorView];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	/* Load the last edited document */
	NSString *lastDocumentFilename = [[NSUserDefaults standardUserDefaults] valueForKey:@"Last edited document"];
	if (lastDocumentFilename) {
		[self openSceneWithFilename:lastDocumentFilename];
	}
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
		NSIndexPath *insertionIndexPath = nil;

		NSIndexPath *selectionIndexPath = _navigatorTreeController.selectionIndexPath;

#if 0
		/* Insert as sibling */
		if (selectionIndexPath.length > 1) {
			/* IndexPath as a sibling of the selected node */
			NSInteger index = [selectionIndexPath indexAtPosition:selectionIndexPath.length - 1];
			insertionIndexPath = [[selectionIndexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:index + 1];
		} else {
			/* IndexPath as a child of the scene */
			NSInteger numberOfChildren = [_navigatorTreeController.selectedNodes.firstObject childNodes].count;
			insertionIndexPath = [selectionIndexPath indexPathByAddingIndex:numberOfChildren];
		}
#else
		/* Insert as child */
		insertionIndexPath = [selectionIndexPath indexPathByAddingIndex:0];
#endif

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

	/* Make the current selection to be the parent of the removed node */
	[_editorView setNode:object.node.parent];

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

	/* Save attributes view position and expansion info */
	for (id item in [[_nodeInspectorTreeController arrangedObjects] childNodes]) {
		NSString *name = [[item representedObject] valueForKey:@"name"];
		_inspectorViewExpansionInfo[name] = [NSNumber numberWithBool:[_nodeInspectorView isItemExpanded:item]];
	}
	for (id item in [[_identityInspectorTreeController arrangedObjects] childNodes]) {
		NSString *name = [[item representedObject] valueForKey:@"name"];
		_inspectorViewExpansionInfo[name] = [NSNumber numberWithBool:[_identityInspectorView isItemExpanded:item]];
	}

	/* Save the scroll position*/
	NSScrollView *nodeScrollView = _nodeInspectorView.enclosingScrollView;
	CGFloat nodeScrollPosition = nodeScrollView.documentVisibleRect.origin.y;

	_selectedNode = node;

	[_editorView setNode:node];

	// TODO: enable Grand Central Dispatch and add a custom queue to process input events
#if UPDATE_SELECTION_USING_GCD
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#endif
		/* Build the tree of attributes in the background thread */
		NSMutableArray *nodeInspectorContents = [self attributesForAllClassesWithNode:node];
		NSMutableArray *identityInspectorContents = @[@{@"name": @"Header",
														@"identifier": @"header",
														@"isLeaf": @NO,
														@"isEditable": @NO,
														@"isCollapsible": @YES,
														@"children": @[@{@"name": @"Attrinute",
																		 @"identifier": @"generic attribute",
																		 @"isLeaf": @YES,
																		 @"isEditable": @NO
																		 }.mutableCopy
																	   ].mutableCopy
														}.mutableCopy,
#if 1 // Dummy user data table
													  @{@"name": @"User Data",
														@"identifier": @"header",
														@"isLeaf": @NO,
														@"isEditable": @NO,
														@"isCollapsible": @YES,
														@"children": @[@{@"name": @"userData",
																		 @"identifier": @"@\"NSMutableDictionary\"",
																		 @"isLeaf": @NO,
																		 @"isEditable": @NO,
																		 @"content": [UserDataDictionary controllerWithNode:_selectedNode]
																		 }.mutableCopy
																	   ].mutableCopy
														}.mutableCopy,
#endif
													  @{@"name": @"Header",
														@"identifier": @"header",
														@"isLeaf": @NO,
														@"isEditable": @NO,
														@"isCollapsible": @YES,
														@"children": @[@{@"name": @"Attrinute",
																		 @"identifier": @"generic attribute",
																		 @"isLeaf": @YES,
																		 @"isEditable": @NO
																		 }.mutableCopy
																	   ].mutableCopy
														}.mutableCopy,
													  @{@"name": @"Header",
														@"identifier": @"header",
														@"isLeaf": @NO,
														@"isEditable": @NO,
														@"isCollapsible": @YES,
														@"children": @[@{@"name": @"Attrinute",
																		 @"identifier": @"generic attribute",
																		 @"isLeaf": @YES,
																		 @"isEditable": @NO
																		 }.mutableCopy,
																	   @{@"name": @"Attrinute",
																		 @"identifier": @"generic attribute",
																		 @"isLeaf": @YES,
																		 @"isEditable": @NO
																		 }.mutableCopy
																	   ].mutableCopy
														}.mutableCopy
													  ].mutableCopy;

		/* Look up for the row to be selected */
		NSInteger row = [_navigatorView rowForItem:[self navigationNodeOfObject:node inNodes:[[_navigatorTreeController arrangedObjects] childNodes]]];

#if UPDATE_SELECTION_USING_GCD
		dispatch_async(dispatch_get_main_queue(), ^{
#endif
			/* Replace the attributes table */
			[_nodeInspectorTreeController setContent:nodeInspectorContents];
			[_identityInspectorTreeController setContent:identityInspectorContents];

			/* Restore attributes view position and expansion info */
			for (id item in [[_nodeInspectorTreeController arrangedObjects] childNodes]) {
				NSString *name = [[item representedObject] valueForKey:@"name"];
				NSNumber *expansionInfo = _inspectorViewExpansionInfo[name];
				[_nodeInspectorView expandItem:item expandChildren:YES];
				if (expansionInfo && ![expansionInfo boolValue]) {
					[_nodeInspectorView collapseItem:item];
				}
			}
			for (id item in [[_identityInspectorTreeController arrangedObjects] childNodes]) {
				NSString *name = [[item representedObject] valueForKey:@"name"];
				NSNumber *expansionInfo = _inspectorViewExpansionInfo[name];
				[_identityInspectorView expandItem:item expandChildren:YES];
				if (expansionInfo && ![expansionInfo boolValue]) {
					[_identityInspectorView collapseItem:item];
				}
			}

			/* Restore the scroll position  */
			CGFloat nodeScrollContentHeight = [(NSView *)nodeScrollView.documentView frame].size.height;
			CGFloat nodeScrollHeight = nodeScrollView.documentVisibleRect.size.height;
			nodeScrollPosition = MAX(0, MIN(nodeScrollPosition, nodeScrollContentHeight - nodeScrollHeight));
			[nodeScrollView.contentView scrollToPoint:CGPointMake(0, nodeScrollPosition)];
			[nodeScrollView reflectScrolledClipView:nodeScrollView.contentView];

			/* Ask the editor view to repaint the selection */
			[_editorView setNeedsDisplay:YES];

			/* Update the selection in the navigator view */
			[_navigatorView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
#if UPDATE_SELECTION_USING_GCD
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
									  @"identifier": @"header",
									  @"isLeaf": @NO,
									  @"isEditable": @NO,
									  @"isCollapsible": @YES,
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

			/* Skip read-only attributes that are not class instances */
			BOOL isReadonlyNonClass = [propertyAttributes rangeOfString:@"^[^@]*,R(,|$)" options:NSRegularExpressionSearch].location != NSNotFound;
			if (isReadonlyNonClass)
				continue;

			NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[i])];

			BOOL isPrivateProperty = [propertyName rangeOfString:@"^_" options:NSRegularExpressionSearch].location != NSNotFound;
			if (isPrivateProperty)
				continue;

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
				[attributesArray addObject:[AttributeNode attributeForNonEditableValue:propertyName identifier:propertyType]];

			} else if ([propertyName rangeOfString:@"^z(Position|Rotation)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasZPositionRotation) {
					AttributeNode *attribute = [AttributeNode attributeWithName:@"z,zPosition,zRotation"
																		   node:node
																	 identifier:@"{dd}"
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
																	 identifier:@"{dd}"
																	  formatter:[NSNumberFormatter degreesFormatter]
															   valueTransformer:[DegreesTransformer transformer]];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasEmissionAngle = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorRed(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorRed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"red,particleColorRedSpeed,particleColorRedRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorRed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorGreen(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorGreen) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"green,particleColorGreenSpeed,particleColorGreenRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorGreen = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorBlue(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlue) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"blue,particleColorBlueSpeed,particleColorBlueRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorBlue = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorAlpha(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorAlpha) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleColorAlphaSpeed,particleColorAlphaRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorAlpha = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleSpeed(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"speed,particleSpeed,particleSpeedRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleLifetime(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasLifetime) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"lifetime,particleLifetime,particleLifetimeRange" node:node identifier:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasLifetime = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Acceleration$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYAcceleration) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"acceleration,xAcceleration,yAcceleration" node:node identifier:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYAcceleration = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Scale$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYScale) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,xScale,yScale" node:node identifier:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYScale = YES;
				}

			} else if ([propertyName rangeOfString:@"^(x|y)Rotation$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYRotation) {
					AttributeNode *attribute = [AttributeNode attributeWithName:@"rotation,xRotation,yRotation"
																		   node:node
																	 identifier:@"{dd}"
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
																						  identifier:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleZPositionRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleScale(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleScaleRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,particleScale,particleScaleRange,particleScaleSpeed"
																								node:node
																						  identifier:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleScaleRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleRotation(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleRotationRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"rotation,particleRotation,particleRotationRange,particleRotationSpeed"
																								node:node
																						  identifier:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleRotationRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleAlpha(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleAlphaRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleAlpha,particleAlphaRange,particleAlphaSpeed"
																								node:node
																						  identifier:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleAlphaRangeSpeed = YES;
				}

			} else if ([propertyName rangeOfString:@"^particleColorBlendFactor(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlendFactor) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"colorBlendFactor,particleColorBlendFactor,particleColorBlendFactorRange,particleColorBlendFactorSpeed"
																								node:node
																						  identifier:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleColorBlendFactor = YES;
				}

			} else if ([propertyName isEqualToString:@"bodyType"]) {
				/* Do nothing, the body type will be added with the SKPhysicsNode property */

			} else if ([propertyName rangeOfString:@"[bB]lendMode$" options:NSRegularExpressionSearch].location != NSNotFound) {
				[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node identifier:@"blendMode"]];

			} else if ([propertyName isEqualToString:@"scaleMode"]
					   || [propertyName isEqualToString:@"lineCap"]
					   || [propertyName isEqualToString:@"lineJoin"]
					   || [propertyName isEqualToString:@"verticalAlignmentMode"]
					   || [propertyName isEqualToString:@"horizontalAlignmentMode"]
					   || [propertyName isEqualToString:@"fontName"]) {
				[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node identifier:propertyName]];

			} else {

				Class propertyClass = [propertyType classType];

				if ([propertyType isEqualToEncodedType:@encode(NSMutableDictionary)]) {
					/* Do nothing, this will be added to the Identity inspector */

				} else if ([propertyType isEqualToEncodedType:@encode(NSString)]) {
					[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node identifier:propertyType]];

				} else if ([propertyType isEqualToEncodedType:@encode(NSColor)]) {
					[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node identifier:propertyType]];

				} else if (propertyClass == [SKTexture class]) {
					AttributeNode *attribute = [AttributeNode attributeWithName:propertyName
																		   node:node
																	 identifier:propertyType
																	  formatter:nil
															   valueTransformer:[TextureTransformer transformer]];
					[attributesArray addObject:attribute];

				} else if (propertyClass == [SKPhysicsBody class]) {
					/* Populate the SKPhysicsBody property's attributes */
					NSMutableArray *attributes = [self attributesForClass:propertyClass node:[node valueForKey:propertyName]];
					
					/* Insert the SKNode's body type property in the first row */
					[attributes insertObject:[AttributeNode attributeWithName:@"bodyType" node:node identifier:@"bodyType"] atIndex:0];

					/* Add the property's attributes */
					[attributesArray addObject:[AttributeNode attributeWithName:propertyName node:node identifier:@"expandable" children:attributes]];

				} else if (propertyClass == [SKShader class]) {
					AttributeNode *attribute = [AttributeNode attributeWithName:propertyName
																		   node:node
																	 identifier:propertyType
																	  formatter:nil
															   valueTransformer:[ShaderTransformer transformer]];
					[attributesArray addObject:attribute];

#if 1 // Dummy shader uniforms table
					[attributesArray addObject:@{@"name": @"Custom Shader Uniforms",
												 @"identifier": @"header",
												 @"isLeaf": @NO,
												 @"isEditable": @NO,
												 @"isCollapsible": @YES,
												 @"children": @[@{@"name": @"uniforms",
																  @"identifier": @"uniforms",
																  @"isLeaf": @NO,
																  @"isEditable": @NO,
																  @"content": [UserDataUniformsArray controllerWithShader:[_selectedNode valueForKey:propertyName]]
																  }.mutableCopy
																].mutableCopy
												 }.mutableCopy];
#endif


				} else if (propertyClass == [SKPhysicsWorld class]) {
					[attributesArray addObject:@{@"name": propertyName,
												 @"identifier": @"expandable",
												 @"isLeaf": @NO,
												 @"isEditable": @NO,
												 @"children":[self attributesForClass:propertyClass node:[node valueForKey:propertyName]]}];

				} else if ([propertyName rangeOfString:@"rotation" options:NSCaseInsensitiveSearch].location != NSNotFound) {
					[attributesArray addObject:[AttributeNode  attributeForRotationAngleWithName:propertyName node:node]];

				} else {
					/* Skip remaining read-only attributes */
					BOOL isReadOnly = [propertyAttributes rangeOfString:@",R(,|$)" options:NSRegularExpressionSearch].location != NSNotFound;
					if (isReadOnly)
						continue;

					NSCharacterSet *nonEditableTypes = [NSCharacterSet characterSetWithCharactersInString:@"^?b:#@*v"];
					BOOL editable = ![propertyType isEqualToString:@""] && [propertyType rangeOfCharacterFromSet:nonEditableTypes].location == NSNotFound;

					AttributeNode *attribute;

					if (editable) {
						if (![propertyName containsString:@"anchorPoint"]
							&& ![propertyName containsString:@"centerRect"]
							&& ([propertyType isEqualToEncodedType:@encode(CGPoint)]
								|| [propertyType isEqualToEncodedType:@encode(CGSize)]
								|| [propertyType isEqualToEncodedType:@encode(CGRect)])) {
							attribute = [AttributeNode attributeForNormalPrecisionValueWithName:propertyName node:node identifier:propertyType];

						} else if ([propertyName containsString:@"colorBlendFactor"]
								   || [propertyName containsString:@"alpha"]) {
							attribute = [AttributeNode attributeForNormalizedValueWithName:propertyName node:node identifier:propertyType];

						} else if ([propertyType isEqualToEncodedType:@encode(short)]
								   || [propertyType isEqualToEncodedType:@encode(int)]
								   || [propertyType isEqualToEncodedType:@encode(long)]
								   || [propertyType isEqualToEncodedType:@encode(long long)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned short)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned int)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned long)]
								   || [propertyType isEqualToEncodedType:@encode(unsigned long long)]) {
							attribute = [AttributeNode attributeForIntegerValueWithName:propertyName node:node identifier:propertyType];

						} else {
							attribute = [AttributeNode attributeForHighPrecisionValueWithName:propertyName node:node identifier:propertyType];
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
						[attributesArray addObject:[AttributeNode attributeForNonEditableValue:propertyName identifier:propertyType]];
					}
#endif
				}
			}
		}
		free(properties);
	}

	return attributesArray;
}

- (IBAction)inspectorDidSwitchTab:(NSMatrix *)buttons {
	[_inspectorTabView selectTabViewItemAtIndex:buttons.selectedColumn];
}

#pragma mark File handling

- (SKScene *)unarchiveFromFile:(NSString *)file error:(NSError * __autoreleasing *)error {
	/* Retrieve scene file path from the application bundle */
	//file = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];

	NSData *data;

	NSData *plistData = [NSData dataWithContentsOfFile:file];

	id plist = [NSPropertyListSerialization propertyListWithData:plistData
														 options:NSPropertyListImmutable
														  format:&_sceneFormat
														   error:error];

	_useXMLFormatButton.state = _sceneFormat == NSPropertyListXMLFormat_v1_0 ? 1 : 0;

	if (_sceneFormat == NSPropertyListXMLFormat_v1_0) {
		/* Convert scene data to binary before passing it to the unarchiver */
		data = [NSPropertyListSerialization dataWithPropertyList:plist
														  format:NSPropertyListBinaryFormat_v1_0
														 options:0
														   error:error];
	} else {
		data = plistData;
	}

	NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	[arch setClass:[_SCNScene class] forClassName:@"SCNScene"];
	SKScene *scene = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[arch finishDecoding];

	return scene;
}

- (BOOL)archiveScene:(SKScene *)scene toFile:(NSString *)file {
	/* Retrieve scene file path from the application bundle */
	//file = [[NSBundle mainBundle] pathForResource:file ofType:@"sks"];

	/* Archive the file to an SKScene object */
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *arch = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

	[arch setOutputFormat:_sceneFormat];

	NSRect frame = scene.frame;
	BOOL hasSingleNode = NSWidth(frame) == 1.0 && NSHeight(frame) == 1.0 && scene.children.count == 1;

	id object = hasSingleNode ? scene.children.firstObject : scene;

	[arch encodeObject:object forKey:NSKeyedArchiveRootObjectKey];
	[arch finishEncoding];

	return [data writeToFile:file atomically:YES];
}

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
		[self archiveScene:self.skView.scene toFile:_currentFilename];
	} else {
		[self saveDocumentAs:sender];
	}
}

- (IBAction)saveDocumentAs:(id)sender {
	/* Get an instance of the save file dialogue */
	NSSavePanel * savePanel = [NSSavePanel savePanel];

	/* Filter the file list showing SpriteKit files */
	[savePanel setAllowedFileTypes:@[@"sks"]];

	/* Add the custom options */
	[savePanel setAccessoryView:_saveSceneView];

	/* Preset the current scene file as the one to save */
	[savePanel setNameFieldStringValue:[_currentFilename lastPathComponent]];
	[savePanel setDirectoryURL:[NSURL fileURLWithPath:_currentFilename]];

	/* Launch the save dialogue */
	[savePanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSModalResponseOK) {
							  /* Get the selected file's URL */
							  NSURL *selection = savePanel.URL;
							  /* Store the selected file's path as a string */
							  NSString *filename = [[selection path] stringByResolvingSymlinksInPath];
							  /* Save to the selected the file */
							  [self archiveScene:self.skView.scene toFile:filename];
							  _currentFilename = filename;
						  }
					  }];
}

- (IBAction)closeScene:(id)sender {
	[self useScene:nil];
	_currentFilename = nil;
	_sceneBundle = nil;
	[self populateMediaLibrary];

	/* Clear the filename of last edited document */
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults removeObjectForKey:@"Last edited document"];
	[userDefaults synchronize];
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

- (IBAction)didChangeUseXMLFormatButton:(NSButton *)button {
	_sceneFormat = button.state ? NSPropertyListXMLFormat_v1_0 : NSPropertyListBinaryFormat_v1_0;
}

#pragma mark Library

- (IBAction)objectLibraryDidChangeMode:(NSButton *)sender {
	_objectLibraryCollectionView.mode = sender.state ? LibraryViewModeIcons : LibraryViewModeList;
}

- (IBAction)mediaLibraryDidChangeMode:(NSButton *)sender {
	_mediaLibraryCollectionView.mode = sender.state ? LibraryViewModeIcons : LibraryViewModeList;
}

- (void)populateObjectLibrary {
	if (!_objectLibraryItems) {
		_objectLibraryItems = [NSMutableArray array];
		_objectLibraryContext = [NSMutableArray array];

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
					NSString *name = info[@"CFBundleDisplayName"];
					if (!name) {
						name = @"No name";
					}
					NSArray *names = info[@"Names"];
					if (!names) {
						names = @[name];
					}

					/* Item's description */
					NSString *description = info[@"Description"];
					if (!description) {
						description = @"No description";
					}
					NSArray *descriptions = info[@"Descriptions"];
					if (!descriptions) {
						descriptions = @[description];
					}

					/* Item's image */
					NSString *iconPath = [aURL.path stringByAppendingPathComponent:info[@"CFBundleIconFile"]];
					NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
					NSImage *defaultIcon = [NSImage imageNamed:NSImageNameCaution];
					if (!iconImage) {
						iconImage = defaultIcon;
					}
					NSArray *iconPaths = info[@"CFBundleIconFiles"];
					NSMutableArray *iconImages = [NSMutableArray array];
					for (int i=0; i<iconPaths.count; ++i) {
						iconPath = [aURL.path stringByAppendingPathComponent:iconPaths[i]];
						NSImage *anImage = [[NSImage alloc] initWithContentsOfFile:iconPath];
						if (!anImage) {
							iconImages[i] = defaultIcon;
						} else {
							iconImages[i] = anImage;
						}
					}
					if (iconImages.count == 0) {
						iconImages[0] = iconImage;
					}

					/* Item's script */
					NSString *script = info[@"Script"];
					if (!script) {
						NSString *itemScriptPath = [aURL.path stringByAppendingPathComponent:info[@"Script File"]];
						script = [[NSString alloc] initWithContentsOfFile:itemScriptPath encoding:NSUTF8StringEncoding error:nil];
					}
					if (!script) {
						script = (id)[NSNull null];
					}

					[_objectLibraryContext addObject:@{@"script": script}.mutableCopy];

					/* Populate the library items with the loaded data */
					for (int i=0; i<names.count; ++i) {
						name = names[i];
						NSString *objectName = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
						NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(.*\\)"
																							   options:NSRegularExpressionCaseInsensitive
																								 error:nil];
						objectName = [regex stringByReplacingMatchesInString:objectName options:0 range:NSMakeRange(0, [objectName length]) withTemplate:@""];

						if (i < descriptions.count) {
							description = descriptions[i];
						} else {
							description = @"No description";
						}

						if (i < iconImages.count) {
							iconImage = iconImages[i];
						} else {
							iconImage = defaultIcon;
						}

						/* Item's full description */
						NSString *fullDescription = [NSString stringWithFormat:@"%@ - %@", name, description];
						NSRange nameRange = NSMakeRange(0, [name length]);
						NSRange descriptionRange = NSMakeRange(nameRange.length, fullDescription.length - nameRange.length);
						NSMutableAttributedString *fullDescriptionAttributedString = [[NSMutableAttributedString alloc] initWithString:fullDescription];
						[fullDescriptionAttributedString beginEditing];
						[fullDescriptionAttributedString addAttribute:NSFontAttributeName
																value:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]
																range:nameRange];
						[fullDescriptionAttributedString addAttribute:NSFontAttributeName
																value:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
																range:descriptionRange];
						[fullDescriptionAttributedString endEditing];

						/* Add the item to the library */
						[_objectLibraryItems addObject:@{@"name":objectName,
														@"label":fullDescriptionAttributedString,
														@"image":iconImage,
														@"showLabel":@(!_objectLibraryModeButton.state),
														@"contextData":@(_objectLibraryContext.count - 1)}.mutableCopy];
					}
				}
			}
		}
	}

	[_objectLibraryArrayController setContent:_objectLibraryItems];

	if (_objectSelectedLibraryItem == NSNotFound)
		_objectSelectedLibraryItem = 0;
	[_objectLibraryArrayController setSelectionIndex:_objectSelectedLibraryItem];
}

- (void)populateMediaLibrary {
	NSString *bundlePath = [_sceneBundle bundlePath];

	/* Check whether the loaded scene's bundle is the same */
	if (!_sceneBundlePath || ![_sceneBundlePath isEqualToString:bundlePath]) {

		/* Init the context of the media library */
		if (!_mediaLibraryContext) {
			_mediaLibraryContext = [NSMutableArray array];
			[_mediaLibraryContext addObject:@{@"script": LUA_STRING
												  (
												   function createNodeAtPosition(position, name)
												   local node = SKSpriteNode.spriteNodeWithImageNamed(name)
												   node.position = position
												   return node
												   end
												   )}.mutableCopy];
		}

		/* Clear the media library */
		_mediaLibraryItems = [NSMutableArray array];

		if (_sceneBundle) {
			/* Store the scene bundle path */
			_sceneBundlePath = bundlePath;

			/* Get a list with all the files in the scene bundle */
			NSString *mediaPath = [_sceneBundle resourcePath];
			NSURL *mediaURL = [[NSURL alloc] initFileURLWithPath:mediaPath];
			NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
			NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
												 enumeratorAtURL:mediaURL
												 includingPropertiesForKeys:keys
												 options:0
												 errorHandler:^(NSURL *url, NSError *error) {
													 [NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:NULL];
													 return NO;
												 }];

			/* Traverse all the files in the retrieved list */
			NSMutableArray *loadedFiles = [NSMutableArray array];
			for (NSURL *url in enumerator) {
				NSError *error;
				NSNumber *isDirectory = nil;
				if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
					NSString *fullPath = [url path];
					NSString *filename = [fullPath lastPathComponent];

					/* Check whether the file is an image */
					CFStringRef fileExtension = (__bridge CFStringRef)[filename pathExtension];
					CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
					BOOL isImage = UTTypeConformsTo(fileUTI, kUTTypeImage);
					CFRelease(fileUTI);

					if (!isImage)
						continue;

					/* Check whether the image was already added with a different idiom */
					NSRange range = [filename rangeOfString:@"~[^~\\.]*\\." options:NSRegularExpressionSearch];
					if (range.location != NSNotFound)
						filename = [filename stringByReplacingCharactersInRange:range withString:@"."];
					filename = [filename stringByDeletingPathExtension];
					if ([loadedFiles indexOfObject:filename] != NSNotFound)
						continue;
					[loadedFiles addObject:filename];

					/* Retrieve an image reference from the image path */
					CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:fullPath], NULL);

					if (imageSource) {

						/* Get the image properties */
						NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
												 [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
												 nil];
						CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (CFDictionaryRef)options);

						if (imageProperties) {

							/* Generate the image thumbnail */
							NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
							NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
							CFRelease(imageProperties);

							NSSize size = NSMakeSize([width floatValue], [height floatValue]);
							CGFloat scale = MIN(1.0, 48.0 / MAX(size.width, size.height));
							size.width *= scale;
							size.height *= scale;

							CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

							NSImage *imageThumbnail = [[NSImage alloc] initWithCGImage:imageRef size:size];

							CFRelease(imageRef);

							if (imageThumbnail) {

								NSRange nameRange = NSMakeRange(0, filename.length);
								NSMutableAttributedString *filenameAttributedString = [[NSMutableAttributedString alloc] initWithString:filename];
								[filenameAttributedString beginEditing];
								[filenameAttributedString addAttribute:NSFontAttributeName
																 value:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]
																 range:nameRange];
								[filenameAttributedString endEditing];

								/* Add the item to the library */
								[_mediaLibraryItems addObject:@{@"name":filename,
																	@"label":filenameAttributedString,
																	@"image":imageThumbnail,
																	@"showLabel":@(!_mediaLibraryModeButton.state),
																	@"contextData":@(0)}.mutableCopy];
							}
						}

						CFRelease(imageSource);
					}
				}
				else if (error) {
					[NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:NULL];
					break;
				}
			}
		}
	}

	[_mediaLibraryArrayController setContent:_mediaLibraryItems];

	if (_mediaSelectedLibraryItem == NSNotFound)
		_mediaSelectedLibraryItem = 0;
	[_mediaLibraryArrayController setSelectionIndex:_mediaSelectedLibraryItem];
}

- (IBAction)libraryDidSwitchTab:(NSMatrix *)buttons {
	[_libraryTabView selectTabViewItemAtIndex:buttons.selectedColumn];
}

- (void)libraryView:(LibraryView *)libraryView didSelectItemAtIndex:(NSInteger)index {
	if (_libraryTabButtons.selectedColumn) {
		_mediaSelectedLibraryItem = index;
	} else {
		_objectSelectedLibraryItem = index;
	}
}

- (NSArray *)texturesLibrary {
	return [_mediaLibraryItems valueForKey:@"name"];
}

- (NSArray *)shadersLibrary {
	NSMutableArray *result = [NSMutableArray array];
	for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh"]) {
		[result addObject:[path lastPathComponent]];
	}
	return result;
}

#pragma mark Editor Dragging Destination

- (NSDragOperation)editorView:(EditorView *)editorView draggingEntered:(id)item {
	/* Check that there is a scene loaded */
	if (!_editorView.scene) {
		return NSDragOperationNone;
	}

	return NSDragOperationCopy;
}

- (BOOL)editorView:(EditorView *)editorView performDragOperation:(id)item atLocation:(CGPoint)locationInSelection {
	/* Check that there is a valid selection */
	NSIndexPath *selectionIndexPath = [_navigatorTreeController selectionIndexPath];
	if (!selectionIndexPath) {
		selectionIndexPath = [NSIndexPath indexPathWithIndex:0];
	}

	/* Get the library item */
	NSMutableDictionary *libraryItem;
	if (_libraryTabButtons.selectedColumn) {
		libraryItem = [[_mediaLibraryArrayController arrangedObjects] objectAtIndex:[item intValue]];
	} else {
		libraryItem = [[_objectLibraryArrayController arrangedObjects] objectAtIndex:[item intValue]];
	}

	/* Retrieve a valid context from the cache for the item */
	NSNumber *itemIndex = [libraryItem objectForKey:@"contextData"];
	LuaContext *scriptContext = nil;
	NSMutableDictionary *contextData = nil;
	if (itemIndex) {
		if (_libraryTabButtons.selectedColumn) {
			contextData = [_mediaLibraryContext objectAtIndex:[itemIndex intValue]];
		} else {
			contextData = [_objectLibraryContext objectAtIndex:[itemIndex intValue]];
		}
		scriptContext = [contextData objectForKey:@"context"];
	}

	/* Create a new context if there isn't one already cached */
	NSError *error = nil;
	if (!scriptContext) {
		/* Create the context */
		scriptContext = [[LuaContext alloc] initWithVirtualMachine:_sharedScriptingContext.virtualMachine];

		/* Copy the variables from the shared context */
		for (Class class in _exportedClasses) {
			scriptContext[[class className]] = class;
		}
		scriptContext[@"scene"] = _editorView.scene;

		/* Retrieve the script */
		NSString *script = [contextData objectForKey:@"script"];

		/* Run the script */
		[scriptContext parse:script error:&error];
		if (error) {
			[NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:NULL];
			return NO;
		}

		/* Cache the scripting context if the script returned with no errors */
		[contextData setObject:scriptContext forKey:@"context"];
	}

	/* Esure the global variable scene is available in the context */
	else if (![scriptContext[@"scene"] isEqual:_editorView.scene]) {
		scriptContext[@"scene"] = _editorView.scene;
	}

	/* Create the node from the script */
	NSValue *position = [NSValue valueWithPoint:locationInSelection];
	NSString *objectName = [libraryItem objectForKey:@"name"];
	SKNode *node = [scriptContext call:@"createNodeAtPosition" with:@[position, objectName] error:&error];
	if (error) {
		[NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:NULL];
		return NO;
	}
	if (!node) {
		return NO;
	}

	/* Insert the created node into the scene hierarchy */
	[self insertObject:@[[NavigationNode navigationNodeWithNode:node], @[@YES].mutableCopy] atIndexPath:[selectionIndexPath indexPathByAddingIndex:0]];

	/* Set focus on the editor view */
	[[self window] makeFirstResponder:_editorView];

	return YES;
}

#pragma mark Scene

- (BOOL)openSceneWithFilename:(NSString *)filename {

	if ([_currentFilename isEqualToString:filename]) {
		/* The file is already open */
		return YES;
	}

	NSString *bundlePath = filename;
	NSBundle *bundle = nil;
	while (![bundlePath isEqualToString:@"/"] && [[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
		bundle = [NSBundle bundleWithPath:bundlePath];
		if ([bundle infoDictionary]) {
			break;
		} else {
			bundle = nil;
		}
		bundlePath = [bundlePath stringByDeletingLastPathComponent];
	}

	[NSBundle bpr_setMainBundleSubstitutionBundle:bundle];

	NSError *error;
	SKScene *scene = [self unarchiveFromFile:filename error:&error];

	if (error) {
		[NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:nil contextInfo:NULL];
		[NSBundle bpr_setMainBundleSubstitutionBundle:_sceneBundle];
		return NO;
	}

	_currentFilename = filename;
	_sceneBundle = bundle;

	/* Save the filename to the last edited document */
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setValue:_currentFilename forKey:@"Last edited document"];
	[userDefaults synchronize];

	[self useScene:scene];

	/* Add the file to the 'Open Recent' file menu */
	[self addRecentDocument:_currentFilename];

	[self populateMediaLibrary];

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

- (void)useScene:(SKScene *)scene {
	_objectLibraryItems = nil;

	if (!scene) {
		[_nodeInspectorTreeController setContent:nil];
		[_identityInspectorTreeController setContent:nil];
		[_navigatorTreeController setContent:nil];
		_editorView.scene = nil;
		_editorView.needsDisplay = YES;
		[self.skView presentScene:nil];

		return;
	}

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
	_sharedScriptingContext[@"scene"] = scene;

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
				[_navigatorView expandItem:node];
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
