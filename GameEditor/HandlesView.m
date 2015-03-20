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

@synthesize
position = _position,
zRotation = _zRotation,
size = _size;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

	CGFloat width = _size.width;
	CGFloat	height = _size.height;
	CGFloat cosine = cos(_zRotation);
	CGFloat sine = sin(_zRotation);

	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:_position];
	CGPoint point1 = NSMakePoint(_position.x + width * cosine, _position.y + width * sine);
	[line lineToPoint:point1];
	CGPoint point2 = NSMakePoint(point1.x - height * sine, point1.y + height * cosine);
	[line lineToPoint:point2];
	CGPoint point3 = NSMakePoint(_position.x - height * sine, _position.y + height * cosine);
	[line lineToPoint:point3];
	[line closePath];
	[line setLineWidth:2.0];
	[[NSColor whiteColor] set];
	[line stroke];
}

- (void)setPosition:(CGPoint)position {
	_position = [self.node.scene convertPointToView:position];
	[self setNeedsDisplay:YES];
}

- (CGPoint)position {
	return [self.node.scene convertPointFromView:_position];
}

- (void)setZRotation:(CGFloat)zRotation {
	_zRotation = zRotation;
	[self setNeedsDisplay:YES];
}

- (CGFloat)zRotation {
	return _zRotation;
}

- (void)setSize:(CGSize)size {
	CGPoint point = [self.node.scene convertPointToView:CGPointMake(size.width, size.height)];
	_size = CGSizeMake(point.x, point.y);
	[self setNeedsDisplay:YES];
}

- (CGSize)size {
	CGPoint point = [self.node.scene convertPointFromView:CGPointMake(_size.width, _size.height)];
	return CGSizeMake(point.x, point.y);
}

@end
