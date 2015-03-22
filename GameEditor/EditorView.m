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

@implementation SKScene (SizeConversion)

- (CGSize)convertSizeFromView:(CGSize)size {
	CGPoint viewOrigin = [self convertPointFromView:self.view.frame.origin];
	CGPoint point = CGPointMake(size.width, size.height);
	CGPoint convertedPoint = [self convertPointFromView:point];
	return CGSizeMake(convertedPoint.x - viewOrigin.x, convertedPoint.y - viewOrigin.y);
}

- (CGSize)convertSizeToView:(CGSize)size {
	CGPoint viewOrigin = [self convertPointFromView:self.frame.origin];
	CGPoint point = CGPointMake(size.width + viewOrigin.x, size.height + viewOrigin.y);
	CGPoint convertedPoint = [self convertPointToView:point];
	return CGSizeMake(convertedPoint.x, convertedPoint.y);
}

@end

typedef enum {
	BLHandle = 0,
	BRHandle,
	TRHandle,
	TLHandle,
	BMHandle,
	RMHandle,
	TMHandle,
	LMHandle,
	RotationHandle,
	AnchorPointHAndle,
	MaxHandle
} ManipulatedHandle;

@implementation EditorView {
	CGPoint _draggedPosition;
	BOOL _manipulatingHandle;
	ManipulatedHandle _manipulatedHandle;

	/* Outline handle points */
	CGPoint _handlePoints[MaxHandle];
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
	[outlinePath moveToPoint:_handlePoints[BLHandle]];
	[outlinePath lineToPoint:_handlePoints[BRHandle]];
	[outlinePath lineToPoint:_handlePoints[TRHandle]];
	[outlinePath lineToPoint:_handlePoints[TLHandle]];
	[outlinePath closePath];
	[outlinePath setLineWidth:outlineLineWidth];
	[blueColor set];
	[outlinePath stroke];

	/* Outline handles */
	const CGFloat handleLineWidth = 1.5;
	NSColor *fillColor = blueColor;
	NSColor *strokeColor = whiteColor;
	[self drawCircleWithCenter:_handlePoints[BLHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[BRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TLHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[BMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[RMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[LMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Setup the shadow effect */
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:3.0];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	/* Rotation angle handle */
	const CGFloat rotationLineWidth = 1.0;
	const CGFloat rotationHandleRadius = 4.0;
	[NSBezierPath strokeLineFromPoint:_handlePoints[AnchorPointHAndle] toPoint:_handlePoints[RotationHandle]];
	[self drawCircleWithCenter:_handlePoints[AnchorPointHAndle] radius:kRotationHandleDistance fillColor:nil strokeColor:strokeColor lineWidth:rotationLineWidth];
	[self drawCircleWithCenter:_handlePoints[RotationHandle] radius:rotationHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

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
	const CGSize size = CGSizeMake(_size.width, _size.height);
	const CGFloat cosine = cos(_zRotation);
	const CGFloat sine = sin(_zRotation);

	_handlePoints[BLHandle] = CGPointMake(_position.x + size.height * _anchorPoint.y * sine - size.width * _anchorPoint.x * cosine,
								 _position.y - size.height * _anchorPoint.y * cosine - size.width * _anchorPoint.x * sine);
	_handlePoints[BRHandle] = NSMakePoint(_handlePoints[BLHandle].x + size.width * cosine, _handlePoints[BLHandle].y + size.width * sine);
	_handlePoints[TRHandle] = NSMakePoint(_handlePoints[BRHandle].x - size.height * sine, _handlePoints[BRHandle].y + size.height * cosine);
	_handlePoints[TLHandle] = NSMakePoint(_handlePoints[BLHandle].x - size.height * sine, _handlePoints[BLHandle].y + size.height * cosine);

	_handlePoints[BMHandle] = CGPointMake((_handlePoints[BLHandle].x + _handlePoints[BRHandle].x) / 2, (_handlePoints[BLHandle].y + _handlePoints[BRHandle].y) / 2);
	_handlePoints[RMHandle] = CGPointMake((_handlePoints[BRHandle].x + _handlePoints[TRHandle].x) / 2, (_handlePoints[BRHandle].y + _handlePoints[TRHandle].y) / 2);
	_handlePoints[TMHandle] = CGPointMake((_handlePoints[TRHandle].x + _handlePoints[TLHandle].x) / 2, (_handlePoints[TRHandle].y + _handlePoints[TLHandle].y) / 2);
	_handlePoints[LMHandle] = CGPointMake((_handlePoints[TLHandle].x + _handlePoints[BLHandle].x) / 2, (_handlePoints[TLHandle].y + _handlePoints[BLHandle].y) / 2);

	_handlePoints[RotationHandle] = CGPointMake(_position.x + kRotationHandleDistance * cosine, _position.y + kRotationHandleDistance * sine);

	_handlePoints[AnchorPointHAndle] = _position;
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
	_size = [_scene convertSizeToView:size];
	[self setNeedsDisplay:YES];
}

- (CGSize)size {
	return [_scene convertSizeFromView:_size];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint {
	_anchorPoint = anchorPoint;
	[self setNeedsDisplay:YES];
}

- (CGPoint)anchorPoint {
	return _anchorPoint;
}

- (void)setNode:(SKNode *)node {
	if (_node == node)
		return;

	/* Clear the properties bindings*/
	[self unbind:@"position"];
	[self unbind:@"size"];
	[self unbind:@"zRotation"];
	[self unbind:@"anchorPoint"];

	_node = node;
	self.scene = _node.scene;

	/* Craete the new bindings */
	[self bind:@"position" toObject:_node withKeyPath:@"position" options:nil];
	[self bind:@"size" toObject:_node withKeyPath:@"size" options:nil];
	[self bind:@"zRotation" toObject:_node withKeyPath:@"zRotation" options:nil];
	[self bind:@"anchorPoint" toObject:_node withKeyPath:@"anchorPoint" options:nil];

	/* Nofify the delegate */
	[self.delegate selectedNode:(SKNode *)node];

	/* Extract dimensions from the path if the node is a shape node */
	if ([_node isKindOfClass:[SKShapeNode class]]) {
		SKShapeNode *shapeNode = (SKShapeNode *)_node;
		CGPathRef pathRef = [shapeNode path];
		CGRect rect = CGPathGetPathBoundingBox(pathRef);
		self.size = CGSizeMake(rect.size.width * shapeNode.xScale, rect.size.height * shapeNode.yScale);
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
		CGPoint locationInScene = [theEvent locationInNode:_scene];
		CGPoint newPosition = CGPointMake(locationInScene.x - _draggedPosition.x, locationInScene.y - _draggedPosition.y);
		if (_manipulatingHandle) {
			switch (_manipulatedHandle) {
				case AnchorPointHAndle:
					if ([_node isKindOfClass:[SKSpriteNode class]]) {
						/* Translate anchor point and node position */
						SKSpriteNode *spriteNode = (SKSpriteNode *)_node;

						CGVector distanceVector = CGVectorMake(locationInView.x - _handlePoints[BLHandle].x,
															   locationInView.y - _handlePoints[BLHandle].y);
						CGFloat distance = sqrt(distanceVector.dx * distanceVector.dx + distanceVector.dy * distanceVector.dy);
						CGFloat angle = atan2(distanceVector.dy, distanceVector.dx) - _zRotation;

						spriteNode.anchorPoint = CGPointMake(distance * cos(angle) / _size.width, distance * sin(angle) / _size.height);
						spriteNode.size = [_scene convertSizeFromView:_size]; // setting the anchorPoint make the size positive, so this put back the right size (if it have negative values)
						spriteNode.position = [_scene convertPointFromView:locationInView];

					} else if ([_node isKindOfClass:[SKShapeNode class]]) {
						SKShapeNode *shapeNode = (SKShapeNode *)_node;

						CGFloat cosine = cos(_zRotation);
						CGFloat sine = sin(_zRotation);

						/* Translate the path */
						CGVector pathDistanceVector = CGVectorMake(locationInScene.x - shapeNode.position.x,
																   locationInScene.y - shapeNode.position.y);
						CGPathRef path = shapeNode.path;
						CGAffineTransform translation = CGAffineTransformMakeTranslation((-pathDistanceVector.dx * cosine - pathDistanceVector.dy * sine) / shapeNode.xScale,
																						 (pathDistanceVector.dx * sine - pathDistanceVector.dy * cosine) / shapeNode.yScale);
						shapeNode.path = CGPathCreateCopyByTransformingPath(path, &translation);

						/* Translate anchor point and node position */
						CGVector distanceVector = CGVectorMake(locationInView.x - _handlePoints[BLHandle].x,
															   locationInView.y - _handlePoints[BLHandle].y);
						CGFloat distance = sqrt(distanceVector.dx * distanceVector.dx + distanceVector.dy * distanceVector.dy);
						CGFloat angle = atan2(distanceVector.dy, distanceVector.dx) - _zRotation;

						shapeNode.position = [_scene convertPointFromView:locationInView];
						self.anchorPoint = CGPointMake(distance * cos(angle) / _size.width, distance * sin(angle) / _size.height);

					} else {
						_node.position = newPosition;
					}
					break;
				case RotationHandle:
					_node.zRotation = atan2(locationInView.y - _handlePoints[AnchorPointHAndle].y, locationInView.x - _handlePoints[AnchorPointHAndle].x);
					break;
				case BLHandle:
					break;
				case BRHandle:
					break;
				case TRHandle:
					break;
				case TLHandle:
					break;
				case BMHandle:
					break;

				case TMHandle:
					break;

				case RMHandle:
				case LMHandle: {
					CGVector distanceVector;

					/* Distance vector between the the handle and the mouse pointer */
					if (_manipulatedHandle == RMHandle) {
						distanceVector = CGVectorMake(locationInView.x - _handlePoints[LMHandle].x,
													  locationInView.y - _handlePoints[LMHandle].y);
					} else {
						distanceVector = CGVectorMake(_handlePoints[RMHandle].x - locationInView.x,
													  _handlePoints[RMHandle].y - locationInView.y);
					}

					CGFloat distance = sqrt(distanceVector.dx * distanceVector.dx + distanceVector.dy * distanceVector.dy);
					CGFloat angle = atan2(distanceVector.dy, distanceVector.dx) - _zRotation;

					if ([_node isKindOfClass:[SKSpriteNode class]]) {
						/* Resize the node */
						SKSpriteNode *spriteNode = (SKSpriteNode *)_node;
						spriteNode.size = [_scene convertSizeFromView:CGSizeMake(distance * cos(angle), _size.height)];

					} else if ([_node isKindOfClass:[SKShapeNode class]]) {
						/* Resize the path */
						SKShapeNode *shapeNode = (SKShapeNode *)_node;

						CGFloat scale = distance * cos(angle) * shapeNode.xScale / _size.width;
						shapeNode.xScale = scale;

						CGPathRef pathRef = [shapeNode path];
						CGRect rect = CGPathGetPathBoundingBox(pathRef);
						self.size = CGSizeMake(rect.size.width * shapeNode.xScale, rect.size.height * shapeNode.yScale);
					}

					CGFloat cosine = cos(_zRotation);
					CGFloat sine = sin(_zRotation);

					/* Translate the node */
					if (_manipulatedHandle == RMHandle) {
						CGVector anchorDistance = CGVectorMake(_size.width * _anchorPoint.x, _size.height * _anchorPoint.y);
						_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BLHandle].x + anchorDistance.dx * cosine - anchorDistance.dy * sine,
																				  _handlePoints[BLHandle].y + anchorDistance.dx * sine + anchorDistance.dy * cosine)];
					} else {
						CGVector anchorDistance = CGVectorMake(_size.width * (1.0 - _anchorPoint.x), _size.height * _anchorPoint.y);
						_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BRHandle].x - anchorDistance.dx * cosine - anchorDistance.dy * sine,
																				  _handlePoints[BRHandle].y - anchorDistance.dx * sine + anchorDistance.dy * cosine)];
					}
				}
					break;

				default:
					break;
			};
		} else {
			_node.position = newPosition;
		}
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	_manipulatingHandle = NO;
}

- (BOOL)isManipulatingHandleWithPoint:(CGPoint)point {
	_manipulatedHandle = MaxHandle;
	if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[AnchorPointHAndle]])) {
		_manipulatedHandle = AnchorPointHAndle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[RotationHandle]])) {
		_manipulatedHandle = RotationHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[BLHandle]])) {
		_manipulatedHandle = BLHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[BRHandle]])) {
		_manipulatedHandle = BRHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[TRHandle]])) {
		_manipulatedHandle = TRHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[TLHandle]])) {
		_manipulatedHandle = TLHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[BMHandle]])) {
		_manipulatedHandle = BMHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[RMHandle]])) {
		_manipulatedHandle = RMHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[TMHandle]])) {
		_manipulatedHandle = TMHandle;
	} else if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[LMHandle]])) {
		_manipulatedHandle = LMHandle;
	}
	_manipulatingHandle = _manipulatedHandle != MaxHandle;
	return _manipulatingHandle;
}

- (void)setScene:(SKScene *)scene {
	if (_scene == scene)
		return;
	_scene = scene;
}

- (SKScene *)scene {
	return _scene;
}

@end
