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
	self.skView.showsPhysics = YES;

	/* Setup the editor view */
	_editorView.scene = scene;
	_editorView.delegate = self;

	/* Setup the navigator view */
	_navigatorView.delegate = self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (IBAction)saveAction:(id)sender {
	[SKScene archiveScene:self.skView.scene toFile:@"GameScene"];
}

#pragma mark Selection handling

- (void)editorView:(EditorView *)editorView didSelectNode:(id)node {
	[self updateSelectionWithNode:node];
}

- (void)navigatorView:(NavigatorView *)navigatorView didSelectNode:(id)node {
	[self updateSelectionWithNode:node];
}

- (void)updateSelectionWithNode:(id)node {
	[_editorView setNode:node];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		/* Build the tree of attributes in the background thread */
		NSMutableArray *contents = [self attributesForAllClassesWithNode:node];

		/* Look up for the row to be selected */
		NSInteger row = [_navigatorView rowForItem:[self navigationNodeOfObject:node]];

		dispatch_async(dispatch_get_main_queue(), ^{
			/* Replace the attributes table */
			[_attributesTreeController setContent:contents];

			/* Expand all the root nodes in the attributes view */
			for (id item in [[_attributesTreeController arrangedObjects] childNodes])
				[_attributesView expandItem:item expandChildren:NO];

			/* Ask the editor view to repaint the selection */
			[_editorView setNeedsDisplay:YES];

			/* Update the selection in the navigator view */
			[_navigatorView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		});
	});
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
		for(unsigned int i = 0; i < count; i++) {
			//printf("%s::%s %s\n", [classType description].UTF8String, property_getName(properties[i]), property_getAttributes(properties[i])+1);
			NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[i])];
			NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])+1];
			NSString *propertyType = [[propertyAttributes componentsSeparatedByString:@","] firstObject];

			if ([propertyName rangeOfString:@"^z(Position|Rotation)$" options:NSRegularExpressionSearch].location != NSNotFound) {
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
				continue;
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
				continue;
			} else if ([propertyName rangeOfString:@"^particleColorRed(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorRed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"red,particleColorRedSpeed,particleColorRedRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorRed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleColorGreen(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorGreen) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"green,particleColorGreenSpeed,particleColorGreenRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorGreen = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleColorBlue(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlue) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"blue,particleColorBlueSpeed,particleColorBlueRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorBlue = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleColorAlpha(Speed|Range)$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorAlpha) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleColorAlphaSpeed,particleColorAlphaRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasParticleColorAlpha = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleSpeed(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"speed,particleSpeed,particleSpeedRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasSpeed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleLifetime(Range)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasLifetime) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"lifetime,particleLifetime,particleLifetimeRange" node:node type:@"{dd}"];
					attribute.labels = @[@"Start", @"Range"];
					[attributesArray addObject:attribute];
					hasLifetime = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^(x|y)Acceleration$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYAcceleration) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"acceleration,xAcceleration,yAcceleration" node:node type:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYAcceleration = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^(x|y)Scale$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasXYScale) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,xScale,yScale" node:node type:@"{dd}"];
					attribute.labels = @[@"X", @"Y"];
					[attributesArray addObject:attribute];
					hasXYScale = YES;
				}
				continue;
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
				continue;
			} else if ([propertyName rangeOfString:@"^particleZPosition(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleZPositionRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"zPosition,particleZPosition,particleZPositionRange,particleZPositionSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleZPositionRangeSpeed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleScale(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleScaleRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"scale,particleScale,particleScaleRange,particleScaleSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleScaleRangeSpeed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleRotation(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleRotationRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"rotation,particleRotation,particleRotationRange,particleRotationSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleRotationRangeSpeed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleAlpha(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleAlphaRangeSpeed) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"alpha,particleAlpha,particleAlphaRange,particleAlphaSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleAlphaRangeSpeed = YES;
				}
				continue;
			} else if ([propertyName rangeOfString:@"^particleColorBlendFactor(Range|Speed)?$" options:NSRegularExpressionSearch].location != NSNotFound) {
				if (!hasParticleColorBlendFactor) {
					AttributeNode *attribute = [AttributeNode attributeForHighPrecisionValueWithName:@"colorBlendFactor,particleColorBlendFactor,particleColorBlendFactorRange,particleColorBlendFactorSpeed"
																								node:node
																								type:@"{ddd}"];

					attribute.labels = @[@"Start", @"Range", @"Speed"];
					[attributesArray addObject:attribute];
					hasParticleColorBlendFactor = YES;
				}
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
		free(properties);
	}
	
	return attributesArray;
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
			id result = [self navigationNodeOfObject:anObject inNodes:[node childNodes]];
			if (result) {
				return result;
			}
		}
	}
	return nil;
}

@end
