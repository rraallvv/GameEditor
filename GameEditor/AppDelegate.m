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
#import "AttributesView.h"
#import "NavigationNode.h"

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
	IBOutlet NSTreeController *_attributesTreeController;
	IBOutlet NSTreeController *_navigatorTreeController;
	IBOutlet AttributesView *_attributesView;
	IBOutlet NSOutlineView *_navigatorView;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	/* Main window appearance */
	self.window.styleMask = self.window.styleMask;
	self.window.titleVisibility = NSWindowTitleHidden;

	/* Pick the scene */
    GameScene *scene = [GameScene unarchiveFromFile:@"GameScene"];
	[_navigatorTreeController setContent:[NavigationNode navigationNodeWithNode:scene]];
	[_navigatorView expandItem:nil expandChildren:YES];

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

- (IBAction)saveAction:(id)sender {
	[SKScene archiveScene:self.skView.scene toFile:@"GameScene"];
}

- (void)selectedNode:(id)node {
	/* Replace the attributes table */
	[_attributesTreeController setContent:[self attributesForAllClassesWithNode:node]];

	/* Expand all the root nodes in the attributes view */
	for (id item in [[_attributesTreeController arrangedObjects] childNodes])
		[_attributesView expandItem:item expandChildren:NO];

	/* Update the selection in the navigator view */
	[_navigatorView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_navigatorView rowForItem:[self navigationNodeOfObject:node]]]
				byExtendingSelection:NO];
}

- (id)navigationNodeOfObject:(id)anObject {
	return [self navigationNodeOfObject:anObject inNodes:[[_navigatorTreeController arrangedObjects] childNodes]];
}

- (id)navigationNodeOfObject:(id)anObject inNodes:(NSArray*)nodes {
	for(NSTreeNode* node in nodes) {
		if([[[node representedObject] node] isEqual:anObject]) {
			return node;
		}
		if([[node childNodes] count]) {
			return [self navigationNodeOfObject:anObject inNodes:[node childNodes]];
		}
	}
	return nil;
}

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

	NSMutableArray *propertiesArray = [NSMutableArray array];

	if (count) {
		for(unsigned int i = 0; i < count; i++) {
			//printf("%s::%s %s\n", [classType description].UTF8String, property_getName(properties[i]), property_getAttributes(properties[i])+1);
			NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[i])];
			NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])+1];
			NSString *propertyType = [[propertyAttributes componentsSeparatedByString:@","] firstObject];

			NSMutableDictionary *property = [NSMutableDictionary dictionary];
			property[@"Name"] = propertyName;
			property[@"Attributes"] = propertyAttributes;
			property[@"Type"] = propertyType;
			property[@"NameComponents"] = [propertyName componentsSeparatedInWords];
			[propertiesArray addObject:property];
		}
		free(properties);
	}

	BOOL hasZ = NO;

	for (NSMutableDictionary *property in propertiesArray) {
		NSString *propertyName = property[@"Name"];
		NSString *propertyAttributes = property[@"Attributes"];
		NSString *propertyType  = property[@"Type"];
		NSMutableArray *propertyNameComponents = property[@"NameComponents"];

		if ([propertyNameComponents[0] isEqualToString:@"z"]) {
			if (!hasZ) {
				[attributesArray addObject:[AttributeNode attributeWithName:@"zPosition,zRotation"
																	   node:node
																	   type:propertyType
																  formatter:@[[NSNumberFormatter integerFormatter],
																			  [NSNumberFormatter degreesFormatter]]
														   valueTransformer:@[[NSNull null],
																			  [NSValueTransformer valueTransformerForName:NSStringFromClass([DegreesTransformer class])]]]];
			}
			hasZ = YES;
			continue;
		}

		Class propertyClass = [propertyType classType];

		if ([propertyType isEqualToEncodedType:@encode(NSColor)]) {
			[attributesArray addObject:[AttributeNode attributeForColorWithName:propertyName node:node]];

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
			BOOL editable = [propertyAttributes rangeOfString:@",R(,|$)" options:NSRegularExpressionSearch].location == NSNotFound;
			NSCharacterSet *nonEditableTypes = [NSCharacterSet characterSetWithCharactersInString:@"^?b:#@*v"];
			editable = editable && ![propertyType isEqualToString:@""] && [propertyType rangeOfCharacterFromSet:nonEditableTypes].location == NSNotFound;

			if (editable) {

				if (![propertyName containsString:@"anchorPoint"]
					&& ![propertyName containsString:@"centerRect"]
					&& ([propertyType isEqualToEncodedType:@encode(CGPoint)]
						|| [propertyType isEqualToEncodedType:@encode(CGSize)]
						|| [propertyType isEqualToEncodedType:@encode(CGRect)])) {
						[attributesArray addObject:[AttributeNode attributeForNormalPrecisionValueWithName:propertyName node:node type:propertyType]];
					} else if ([propertyName containsString:@"colorBlendFactor"]
							   || [propertyName containsString:@"alpha"]) {
						[attributesArray addObject:[AttributeNode attributeForNormalizedValueWithName:propertyName node:node type:propertyType]];
					} else if ([propertyType isEqualToEncodedType:@encode(short)]
							   || [propertyType isEqualToEncodedType:@encode(int)]
							   || [propertyType isEqualToEncodedType:@encode(long)]
							   || [propertyType isEqualToEncodedType:@encode(long long)]
							   || [propertyType isEqualToEncodedType:@encode(unsigned short)]
							   || [propertyType isEqualToEncodedType:@encode(unsigned int)]
							   || [propertyType isEqualToEncodedType:@encode(unsigned long)]
							   || [propertyType isEqualToEncodedType:@encode(unsigned long long)]) {
						[attributesArray addObject:[AttributeNode attributeForIntegerValueWithName:propertyName node:node type:propertyType]];
					} else {
						[attributesArray addObject:[AttributeNode attributeForHighPrecisionValueWithName:propertyName node:node type:propertyType]];
					}

			}
#if 1// Show a dummy attribute for non-editable properties
			else {
				[attributesArray addObject:@{@"name": propertyName,
											 @"value": @"(non-editable)",
											 @"type": @"generic attribute",
											 @"node": [NSNull null],
											 @"description": [NSString stringWithFormat:@"%@\n%@", propertyName, propertyType],
											 @"isLeaf": @YES,
											 @"isEditable": @NO}];
			}
#endif
		}
	}

	return attributesArray;
}

- (IBAction)rowSelected:(id)sender {
	NSInteger selectedRow = [_navigatorView selectedRow];
	if (selectedRow != -1) {
		[_editorView setNode:[[[_navigatorView itemAtRow:selectedRow] representedObject] node]];
		//NSLog(@"%@ selected", [[[_navigatorView itemAtRow:selectedRow] representedObject] valueForKey:@"name"]);
	}
	else {
		// No row was selected
	}
}

@end
