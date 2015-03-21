//
//  GameScene.m
//  GameEditor
//

#import "GameScene.h"

@implementation GameScene

- (void)didMoveToView:(SKView *)view {
	/* Create test shape from points */
	/*
	CGPoint points[] = {{0,0}, {-40, -40}, {80, 0}, {0, 120}, {0,0}};
	SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPoints:points count:5];
	shapeNode.strokeColor = [SKColor blueColor];
	shapeNode.lineWidth = 5.0;
	shapeNode.position = CGPointMake(100, 100);
	[self addChild:shapeNode];
	 */

	/* Create shape from path */
	/*
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, nil, 0, 0);
	CGPathAddLineToPoint(path, nil, 80, -50);
	CGPathAddLineToPoint(path, nil, 0, 100);
	CGPathAddLineToPoint(path, nil, -80, -50);
	CGPathCloseSubpath(path);
	SKShapeNode *shapeNode = [SKShapeNode shapeNodeWithPath:path];
	CGPathRelease(path);
	shapeNode.strokeColor = [SKColor yellowColor];
	shapeNode.fillColor = [SKColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.5];
	shapeNode.lineWidth = 5.0;
	shapeNode.position = CGPointMake(300, 100);
	[self addChild:shapeNode];
	 */
}

@end
