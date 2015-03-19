//
//  HandlesView.m
//  GameEditor
//
//  Created by Rhody Lugo on 3/19/15.
//
//

#import "HandlesView.h"
#import <GLKit/GLKit.h>

@implementation HandlesView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(NSMinX([self bounds]), NSMinY([self bounds]))];
	[line lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMinY([self bounds]))];
	[line lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]))];
	[line lineToPoint:NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]))];
	[line closePath];
	[line setLineWidth:2.0];
	[[NSColor redColor] set];
	[line stroke];

	NSBezierPath *line2 = [NSBezierPath bezierPath];
	[line2 moveToPoint:NSMakePoint(NSMinX([self frame]), NSMinY([self frame]))];
	[line2 lineToPoint:NSMakePoint(NSMaxX([self frame]), NSMinY([self frame]))];
	[line2 lineToPoint:NSMakePoint(NSMaxX([self frame]), NSMaxY([self frame]))];
	[line2 lineToPoint:NSMakePoint(NSMinX([self frame]), NSMaxY([self frame]))];
	[line2 closePath];
	[line2 setLineWidth:2.0];
	[[NSColor blueColor] set];
	[line2 stroke];
}

- (void)setFrameCenter:(CGPoint)frameCenter {
	CGPoint position = [self.scene convertPointToView:frameCenter];
	NSRect frame = self.frame;
	CGFloat diaggonal = sqrt(pow(NSWidth(self.bounds), 2)+pow(NSHeight(self.bounds), 2));
	CGFloat angle = atan2(NSHeight(self.bounds), NSWidth(self.bounds)) + GLKMathDegreesToRadians(self.frameCenterRotation);
	position.x -= diaggonal / 2 * cos(angle);
	position.y -= diaggonal / 2 * sin(angle);
	frame.origin = position;
	self.frame = frame;
}

- (CGPoint)frameCenter {
	return self.frame.origin;
}

@end
