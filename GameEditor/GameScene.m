//
//  GameScene.m
//  GameEditor
//

#import "GameScene.h"

@implementation GameScene

- (void)didMoveToView:(SKView *)view {
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
#endif

	SKSpriteNode *spaceShip = (SKSpriteNode *)[self childNodeWithName:@"//SpaceShip"];
	[spaceShip setPaused:YES];
}

@end
