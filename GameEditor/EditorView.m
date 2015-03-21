/*
 * EditorView.m
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
	CGPoint _viewOrigin;
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
	const CGSize size = _size;
	const CGFloat cosine = cos(_zRotation);
	const CGFloat sine = sin(_zRotation);

	NSColor *whiteColor = [NSColor whiteColor];
	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.345 green:0.337 blue:0.961 alpha:1.0];

	/* Outline rectangle*/
	const CGFloat outlineLineWidth = 1.0;

	const CGPoint point1 = CGPointMake(_position.x + size.height * _anchorPoint.y * sine - size.width * _anchorPoint.x * cosine,
									   _position.y - size.height * _anchorPoint.y * cosine - size.width * _anchorPoint.x * sine);
	const CGPoint point2 = NSMakePoint(point1.x + size.width * cosine, point1.y + size.width * sine);
	const CGPoint point3 = NSMakePoint(point2.x - size.height * sine, point2.y + size.height * cosine);
	const CGPoint point4 = NSMakePoint(point1.x - size.height * sine, point1.y + size.height * cosine);

	NSBezierPath *outlinePath = [NSBezierPath bezierPath];
	[outlinePath moveToPoint:point1];
	[outlinePath lineToPoint:point2];
	[outlinePath lineToPoint:point3];
	[outlinePath lineToPoint:point4];
	[outlinePath closePath];
	[outlinePath setLineWidth:outlineLineWidth];
	[blueColor set];
	[outlinePath stroke];

	/* Outline handles */
	const CGFloat handleLineWidth = 1.5;
	const CGFloat handleRadius = 4.5;
	NSColor *fillColor = blueColor;
	NSColor *strokeColor = whiteColor;
	[self drawCircleWithCenter:point1 radius:handleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:point2 radius:handleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:point3 radius:handleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:point4 radius:handleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Setup the shadow effect */
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:3.0];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	/* Rotation angle handle */
	const CGFloat rotationHandleDistance = 25.0;
	const CGFloat rotationLineWidth = 1.0;
	const CGFloat rotationHandleRadius = 4.0;
	const CGPoint lineEndPoint = CGPointMake(_position.x + rotationHandleDistance * cosine, _position.y + rotationHandleDistance * sine);
	[NSBezierPath strokeLineFromPoint:_position toPoint:lineEndPoint];
	[self drawCircleWithCenter:_position radius:rotationHandleDistance fillColor:nil strokeColor:strokeColor lineWidth:rotationLineWidth];
	[self drawCircleWithCenter:lineEndPoint radius:rotationHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Anchor point handle */
	const CGFloat anchorHandleRadius = 4.0;
	[self drawCircleWithCenter:_position radius:anchorHandleRadius fillColor:whiteColor strokeColor:nil lineWidth:handleLineWidth];
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
	_position = [_scene convertPointToView:position];
	[self setNeedsDisplay:YES];
}

- (CGPoint)position {
	return [_scene convertPointFromView:_position];
}

- (void)setZRotation:(CGFloat)zRotation {
	_zRotation = zRotation;
	[self setNeedsDisplay:YES];
}

- (CGFloat)zRotation {
	return _zRotation;
}

- (void)setSize:(CGSize)size {
	_size = [self convertSizeToView:size];
	[self setNeedsDisplay:YES];
}

- (CGSize)size {
	return [self convertSizeFromView:_size];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint {
	_anchorPoint = anchorPoint;
}

- (CGPoint)anchorPoint {
	return _anchorPoint;
}

- (void)setNode:(SKNode *)node {
	if (_node == node)
		return;

	/* Clear the properties bindings*/
	[self unbind:@"position"];
	[self unbind:@"zRotation"];
	[self unbind:@"size"];
	[self unbind:@"anchorPoint"];

	_node = node;
	self.scene = _node.scene;

	/* Craete the new bindings */
	[self bind:@"position" toObject:_node withKeyPath:@"position" options:nil];
	[self bind:@"zRotation" toObject:_node withKeyPath:@"zRotation" options:nil];
	[self bind:@"size" toObject:_node withKeyPath:@"size" options:nil];
	[self bind:@"anchorPoint" toObject:_node withKeyPath:@"anchorPoint" options:nil];

	/* Nofify the delegate */
	[self.delegate selectedNode:(SKNode *)node];

	/* Extract dimensions from the path if the node is a shape node */
	if ([_node isKindOfClass:[SKShapeNode class]]) {
		SKShapeNode *shapeNode = (SKShapeNode *)_node;
		CGPathRef pathRef = [shapeNode path];
		CGRect rect = CGPathGetPathBoundingBox(pathRef);
		self.size = CGSizeMake(rect.size.width + shapeNode.lineWidth, rect.size.height + shapeNode.lineWidth);
		CGPoint anchorPoint;
		if (rect.size.width == 0) {
			anchorPoint.x = 0;
		} else {
			anchorPoint.x = -rect.origin.x/rect.size.width;
		}
		if (rect.size.height == 0) {
			anchorPoint.y = 0;
		} else {
			anchorPoint.y = -rect.origin.y/rect.size.height;
		}
		self.anchorPoint = anchorPoint;
	}
}

- (SKNode *)node {
	return _node;
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint location = [theEvent locationInNode:_scene];
		NSArray *nodes = [_scene nodesAtPoint:location];
		if (nodes.count) {
			NSUInteger currentIndex = [nodes indexOfObject:_node];
			NSUInteger index = (currentIndex + 1) % nodes.count;
			self.node = [nodes objectAtIndex:index];
		} else {
			self.node = self.scene;
		}
		CGPoint nodePosition = [_node position];
		_draggedPosition = CGPointMake(location.x - nodePosition.x, location.y - nodePosition.y);
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint location = [theEvent locationInNode:_scene];
		_node.position = CGPointMake(location.x - _draggedPosition.x, location.y - _draggedPosition.y);
	}
}

- (void)setScene:(SKScene *)scene {
	if (_scene == scene)
		return;
	_scene = scene;
	_viewOrigin = [_scene convertPointFromView:self.frame.origin];
}

- (SKScene *)scene {
	return _scene;
}

- (CGSize)convertSizeFromView:(CGSize)size {
	CGPoint point = CGPointMake(size.width, size.height);
	CGPoint convertedPoint = [_scene convertPointFromView:point];
	return CGSizeMake(convertedPoint.x - _viewOrigin.x, convertedPoint.y - _viewOrigin.y);
}

- (CGSize)convertSizeToView:(CGSize)size {
	CGPoint point = CGPointMake(size.width + _viewOrigin.x, size.height + _viewOrigin.y);
	CGPoint convertedPoint = [_scene convertPointToView:point];
	return CGSizeMake(convertedPoint.x, convertedPoint.y);
}

@end
