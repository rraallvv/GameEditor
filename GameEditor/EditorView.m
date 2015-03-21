/*
 * StepperTextField.h
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

#import "EditorView.h"
#import <GLKit/GLKit.h>

@implementation EditorView {
	CGPoint _draggedPosition;
}

@synthesize
node = _node,
scene = _scene,
position = _position,
zRotation = _zRotation,
size = _size,
anchorPoint = _anchorPoint;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	[self drawRectangleOutline];
}

- (void)drawRectangleOutline {
	CGSize size = _size;
	CGFloat cosine = cos(_zRotation);
	CGFloat sine = sin(_zRotation);

	/* Outline rectangle*/
	CGPoint point1 = CGPointMake(_position.x + size.height * _anchorPoint.y * sine - size.width * _anchorPoint.x * cosine,
								 _position.y - size.height * _anchorPoint.y * cosine - size.width * _anchorPoint.x * sine);

	const CGFloat outlineLineWidth = 1.5;

	NSBezierPath *outlinePath = [NSBezierPath bezierPath];
	[outlinePath moveToPoint:point1];
	CGPoint point2 = NSMakePoint(point1.x + size.width * cosine, point1.y + size.width * sine);
	[outlinePath lineToPoint:point2];
	CGPoint point3 = NSMakePoint(point2.x - size.height * sine, point2.y + size.height * cosine);
	[outlinePath lineToPoint:point3];
	CGPoint point4 = NSMakePoint(point1.x - size.height * sine, point1.y + size.height * cosine);
	[outlinePath lineToPoint:point4];
	[outlinePath closePath];
	[outlinePath setLineWidth:outlineLineWidth];
	[[NSColor whiteColor] set];
	[outlinePath stroke];

	const CGFloat circleLineWidth = 1.5;

	/* Corner handles */
	NSColor *fillColor = [NSColor blueColor];
	NSColor *strokeColor = [NSColor whiteColor];
	[self drawCircleWithCenter:point1 radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];
	[self drawCircleWithCenter:point2 radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];
	[self drawCircleWithCenter:point3 radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];
	[self drawCircleWithCenter:point4 radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];

	/* Rotation angle handle */
	const CGFloat lineDistance = 40;
	CGPoint lineEndPoint = CGPointMake(_position.x + lineDistance * cosine, _position.y + lineDistance * sine);
	[NSBezierPath strokeLineFromPoint:_position toPoint:lineEndPoint];
	[self drawCircleWithCenter:_position radius:20.0 fillColor:nil strokeColor:strokeColor lineWidth:circleLineWidth];
	[self drawCircleWithCenter:lineEndPoint radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];

	/* Anchor point handle */
	[self drawCircleWithCenter:_position radius:5.0 fillColor:fillColor strokeColor:strokeColor lineWidth:circleLineWidth];
}

- (void)drawCircleWithCenter:(CGPoint)center radius:(CGFloat)radius fillColor:(NSColor *)fillColor strokeColor:(NSColor *)strokeColor lineWidth:(CGFloat)lineWidth{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:center radius:radius startAngle:0 endAngle:M_2_PI clockwise:YES];
	[path setLineWidth:lineWidth];
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

- (void)setNode:(SKNode *)node {
	[self unbind:@"position"];
	[self unbind:@"zRotation"];
	[self unbind:@"size"];
	[self unbind:@"anchorPoint"];
	_node = node;
	self.scene = [_node scene];
	[self bind:@"position" toObject:_node withKeyPath:@"position" options:nil];
	[self bind:@"zRotation" toObject:_node withKeyPath:@"zRotation" options:nil];
	[self bind:@"size" toObject:_node withKeyPath:@"size" options:nil];
	[self bind:@"anchorPoint" toObject:_node withKeyPath:@"anchorPoint" options:nil];

	[self.delegate selectedNode:(SKNode *)node];
}

- (SKNode *)node {
	return _node;
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint location = [theEvent locationInNode:_scene];
		self.node = [self.scene nodeAtPoint:location];
		CGPoint nodePosition = [self.node position];
		_draggedPosition = CGPointMake(location.x - nodePosition.x, location.y - nodePosition.y);
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint location = [theEvent locationInNode:_scene];
		self.node.position = CGPointMake(location.x - _draggedPosition.x, location.y - _draggedPosition.y);
	}
}

@end
