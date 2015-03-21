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

const CGFloat kRotationHandleDistance = 25.0;
const CGFloat kHandleRadius = 4.5;

@implementation EditorView {
	CGPoint _draggedPosition;
	CGPoint _viewOrigin;
	BOOL _manipulatingHandle;

	/* Outline handle points */
	CGPoint _BLHandlePoint;
	CGPoint _BRHandlePoint;
	CGPoint _TRHandlePoint;
	CGPoint _TLHandlePoint;
	CGPoint _BMHandlePoint;
	CGPoint _RMHandlePoint;
	CGPoint _TMHandlePoint;
	CGPoint _LMHandlePoint;
	CGPoint _rotationHandlePoint;
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
	[self updateHandles];

	NSColor *whiteColor = [NSColor whiteColor];
	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.345 green:0.337 blue:0.961 alpha:1.0];

	/* Outline rectangle*/
	const CGFloat outlineLineWidth = 1.0;

	NSBezierPath *outlinePath = [NSBezierPath bezierPath];
	[outlinePath moveToPoint:_BLHandlePoint];
	[outlinePath lineToPoint:_BRHandlePoint];
	[outlinePath lineToPoint:_TRHandlePoint];
	[outlinePath lineToPoint:_TLHandlePoint];
	[outlinePath closePath];
	[outlinePath setLineWidth:outlineLineWidth];
	[blueColor set];
	[outlinePath stroke];

	/* Outline handles */
	const CGFloat handleLineWidth = 1.5;
	NSColor *fillColor = blueColor;
	NSColor *strokeColor = whiteColor;
	[self drawCircleWithCenter:_BLHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_BRHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_TRHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_TLHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_BMHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_RMHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_TMHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_LMHandlePoint radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Setup the shadow effect */
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:3.0];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	/* Rotation angle handle */
	const CGFloat rotationLineWidth = 1.0;
	const CGFloat rotationHandleRadius = 4.0;
	[NSBezierPath strokeLineFromPoint:_position toPoint:_rotationHandlePoint];
	[self drawCircleWithCenter:_position radius:kRotationHandleDistance fillColor:nil strokeColor:strokeColor lineWidth:rotationLineWidth];
	[self drawCircleWithCenter:_rotationHandlePoint radius:rotationHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

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

- (void)updateHandles {
	const CGSize size = _size;
	const CGFloat cosine = cos(_zRotation);
	const CGFloat sine = sin(_zRotation);

	_BLHandlePoint = CGPointMake(_position.x + size.height * _anchorPoint.y * sine - size.width * _anchorPoint.x * cosine,
								 _position.y - size.height * _anchorPoint.y * cosine - size.width * _anchorPoint.x * sine);
	_BRHandlePoint = NSMakePoint(_BLHandlePoint.x + size.width * cosine, _BLHandlePoint.y + size.width * sine);
	_TRHandlePoint = NSMakePoint(_BRHandlePoint.x - size.height * sine, _BRHandlePoint.y + size.height * cosine);
	_TLHandlePoint = NSMakePoint(_BLHandlePoint.x - size.height * sine, _BLHandlePoint.y + size.height * cosine);

	_BMHandlePoint = CGPointMake((_BLHandlePoint.x + _BRHandlePoint.x) / 2, (_BLHandlePoint.y + _BRHandlePoint.y) / 2);
	_RMHandlePoint = CGPointMake((_BRHandlePoint.x + _TRHandlePoint.x) / 2, (_BRHandlePoint.y + _TRHandlePoint.y) / 2);
	_TMHandlePoint = CGPointMake((_TRHandlePoint.x + _TLHandlePoint.x) / 2, (_TRHandlePoint.y + _TLHandlePoint.y) / 2);
	_LMHandlePoint = CGPointMake((_TLHandlePoint.x + _BLHandlePoint.x) / 2, (_TLHandlePoint.y + _BLHandlePoint.y) / 2);

	_rotationHandlePoint = CGPointMake(_position.x + kRotationHandleDistance * cosine, _position.y + kRotationHandleDistance * sine);
}

- (CGRect)handleRectFromPoint:(CGPoint)point {
	CGFloat dimension = kHandleRadius * 2.0;
	return CGRectMake(point.x - kHandleRadius, point.y - kHandleRadius, dimension, dimension);
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
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
		CGPoint locationInScene = [theEvent locationInNode:_scene];
		if (!(_node && [self isManipulatingHandleWithPoint:locationInView])) {
			NSArray *nodes = [_scene nodesAtPoint:locationInScene];
			if (nodes.count) {
				NSUInteger currentIndex = [nodes indexOfObject:_node];
				NSUInteger index = (currentIndex + 1) % nodes.count;
				self.node = [nodes objectAtIndex:index];
			} else {
				self.node = self.scene;
			}
		}
		CGPoint nodePosition = _node.position;
		_draggedPosition = CGPointMake(locationInScene.x - nodePosition.x, locationInScene.y - nodePosition.y);
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
		if (_manipulatingHandle) {
			printf(".");
		} else {
			CGPoint location = [theEvent locationInNode:_scene];
			_node.position = CGPointMake(location.x - _draggedPosition.x, location.y - _draggedPosition.y);
		}
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	_manipulatingHandle = NO;
}

- (BOOL)isManipulatingHandleWithPoint:(CGPoint)point {
	_manipulatingHandle
	= NSPointInRect(point, [self handleRectFromPoint:_position])
	|| NSPointInRect(point, [self handleRectFromPoint:_rotationHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_BLHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_BRHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_TRHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_TLHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_BMHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_RMHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_TMHandlePoint])
	|| NSPointInRect(point, [self handleRectFromPoint:_LMHandlePoint]);
	return _manipulatingHandle;
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
