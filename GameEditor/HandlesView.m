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
size = _size,
anchorPoint = _anchorPoint;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	[self drawRectangleOutline];
}

- (void)drawRectangleOutline {
	CGFloat width = _size.width;
	CGFloat	height = _size.height;
	CGFloat cosine = cos(_zRotation);
	CGFloat sine = sin(_zRotation);

	CGPoint point1 = CGPointMake(_position.x + height * _anchorPoint.y * sine - width * _anchorPoint.x * cosine,
								 _position.y - height * _anchorPoint.y * cosine - width * _anchorPoint.x * sine);

	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:point1];
	CGPoint point2 = NSMakePoint(point1.x + width * cosine, point1.y + width * sine);
	[line lineToPoint:point2];
	CGPoint point3 = NSMakePoint(point2.x - height * sine, point2.y + height * cosine);
	[line lineToPoint:point3];
	CGPoint point4 = NSMakePoint(point1.x - height * sine, point1.y + height * cosine);
	[line lineToPoint:point4];
	[line closePath];
	[line setLineWidth:1.0];
	[[NSColor whiteColor] set];
	[line stroke];

	NSColor *fillColor = [NSColor blueColor];
	NSColor *strokeColor = [NSColor whiteColor];
	[self drawCircleWithCenter:point1 radius:5.0 fillColor:fillColor strokeColor:strokeColor];
	[self drawCircleWithCenter:point2 radius:5.0 fillColor:fillColor strokeColor:strokeColor];
	[self drawCircleWithCenter:point3 radius:5.0 fillColor:fillColor strokeColor:strokeColor];
	[self drawCircleWithCenter:point4 radius:5.0 fillColor:fillColor strokeColor:strokeColor];

	[self drawCircleWithCenter:_position radius:5.0 fillColor:fillColor strokeColor:strokeColor];
}

- (void)drawCircleWithCenter:(CGPoint)center radius:(CGFloat)radius fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor {
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:center radius:radius startAngle:0 endAngle:M_2_PI clockwise:YES];
	[path setLineWidth:2.0];
	if (fillColor) {
		[fillColor set];
		[path fill];
	}
	if (strokeColor) {
		[strokeColor set];
		[path stroke];
	}
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

- (void)setAnchorPoint:(CGPoint)anchorPoint {
	_anchorPoint = anchorPoint;
}

- (CGPoint)anchorPoint {
	return _anchorPoint;
}

@end
