//
//  HandlesView.m
//  GameEditor
//
//  Created by Rhody Lugo on 3/19/15.
//
//

#import "HandlesView.h"

@implementation HandlesView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(NSMinX([self bounds]), NSMinY([self bounds]))];
	[line lineToPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]))];
	[line moveToPoint:NSMakePoint(NSMaxX([self bounds]), NSMinY([self bounds]))];
	[line lineToPoint:NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]))];
	[line setLineWidth:5.0]; /// Make it easy to see
	[line stroke];
}

- (void)setPosition:(CGPoint)position {
	NSRect frame = self.frame;
	frame.origin = position;
	self.frame = frame;
}

- (CGPoint)position {
	return self.frame.origin;
}

@end
