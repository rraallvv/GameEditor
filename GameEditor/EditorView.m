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
#import <objc/runtime.h>

#pragma mark SKScene

const CGFloat kRotationHandleDistance = 25.0;
const CGFloat kHandleRadius = 4.5;

@implementation SKScene (SizeConversion)

- (CGSize)convertSizeFromView:(CGSize)size {
	CGPoint viewOrigin = [self convertPointFromView:self.frame.origin];

	CGPoint point = CGPointMake(size.width, size.height);
	CGPoint convertedPoint = [self convertPointFromView:point];
	size = CGSizeMake(convertedPoint.x - viewOrigin.x, convertedPoint.y - viewOrigin.y);

	return size;
}

- (CGSize)convertSizeToView:(CGSize)size {
	CGPoint viewOrigin = [self convertPointFromView:self.frame.origin];

	CGPoint point = CGPointMake(size.width + viewOrigin.x, size.height + viewOrigin.y);
	CGPoint convertedPoint = [self convertPointToView:point];
	size = CGSizeMake(convertedPoint.x, convertedPoint.y);

	return size;
}

- (CGPoint)convertPointFromView:(CGPoint)point toNode:(SKNode *)node {
	point = [self convertPointFromView:point];
	if (node) {
		point = [self convertPoint:point toNode:node];
	}
	return point;
}

- (CGPoint)convertPointToView:(CGPoint)point fromNode:(SKNode *)node {
	if (node) {
		point = [self convertPoint:point fromNode:node];
	}
	return [self convertPointToView:point];
}

- (CGFloat)convertZRotationFromView:(CGFloat)zRotation toNode:(SKNode *)node {
	SKNode *parentNode = node.parent;
	while (parentNode) {
		zRotation -= parentNode.zRotation;
		parentNode = parentNode.parent;
	}
	return zRotation;
}

- (CGFloat)convertZRotationToView:(CGFloat)zRotation fromNode:(SKNode *)node {
	SKNode *parentNode = node.parent;
	while (parentNode) {
		zRotation += parentNode.zRotation;
		parentNode = parentNode.parent;
	}
	return zRotation;
}

@end

#pragma mark SKShapeNode

@interface SKShapeNode (SizeAndAnchorPoint)
@property (nonatomic) CGSize size;
@property (nonatomic) CGPoint anchorPoint;
@end

@implementation SKShapeNode (SizeAndAnchorPoint)

- (void)setWidthSign:(CGFloat)sign {
	objc_setAssociatedObject(self, @selector(widthSign), [NSNumber numberWithFloat:sign], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)widthSign {
	CGFloat sign = [objc_getAssociatedObject(self, @selector(widthSign)) floatValue];
	if (sign == 0) {
		sign = 1.0;
		[self setWidthSign:sign];
	}
	return sign;
}

- (void)setHeightSign:(CGFloat)sign {
	objc_setAssociatedObject(self, @selector(heightSign), [NSNumber numberWithFloat:sign], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)heightSign {
	CGFloat sign = [objc_getAssociatedObject(self, @selector(heightSign)) floatValue];
	if (sign == 0) {
		sign = 1.0;
		[self setHeightSign:sign];
	}
	return sign;
}

- (void)setSize:(CGSize)size {
	CGSize oldSize = self.size;

	if (CGSizeEqualToSize(size, oldSize))
		return;

	CGPathRef path = self.path;
	CGAffineTransform scale = CGAffineTransformMakeScale(size.width / oldSize.width, size.height / oldSize.height);
	self.path = CGPathCreateCopyByTransformingPath(path, &scale);

	self.widthSign = copysign(1.0, size.width);
	self.heightSign = copysign(1.0, size.height);
}

- (CGSize)size {
	CGPathRef path = [self path];
	CGRect rect = CGPathGetPathBoundingBox(path);
	CGSize size = CGSizeMake(self.widthSign * rect.size.width * self.xScale, self.heightSign * rect.size.height * self.yScale);
	return size;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint {
	CGPoint oldAnchorPoint = self.anchorPoint;

	if (CGPointEqualToPoint(anchorPoint, oldAnchorPoint))
		return;

	CGSize size = self.size;

	CGPathRef path = self.path;
	CGAffineTransform translation = CGAffineTransformMakeTranslation((oldAnchorPoint.x - anchorPoint.x) * size.width / self.xScale,
																	 (oldAnchorPoint.y - anchorPoint.y) * size.height / self.yScale);
	self.path = CGPathCreateCopyByTransformingPath(path, &translation);
}

- (CGPoint)anchorPoint {
	CGPoint anchorPoint;

	CGPathRef path = self.path;
	CGRect rect = CGPathGetPathBoundingBox(path);

	if (rect.size.width == 0) {
		anchorPoint.x = 0;
	} else {
		if (self.widthSign > 0) {
			anchorPoint.x = -rect.origin.x / rect.size.width;
		} else {
			anchorPoint.x = (1.0 + rect.origin.x / rect.size.width);
		}
	}
	if (rect.size.height == 0) {
		anchorPoint.y = 0;
	} else {
		if (self.heightSign > 0) {
			anchorPoint.y = -rect.origin.y / rect.size.height;
		} else {
			anchorPoint.y = (1.0 + rect.origin.y / rect.size.height);
		}
	}

	return anchorPoint;
}

@end

#pragma mark EditorView

typedef enum {
	AnchorPointHandle = 0,
	BLHandle,
	BRHandle,
	TRHandle,
	TLHandle,
	BMHandle,
	RMHandle,
	TMHandle,
	LMHandle,
	RotationHandle,
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
	if (_scene) {
		[self drawNode:_scene];
	}
	if (_node) {
		[self drawSelectionOutline];
	}
}

- (void)drawNode:(SKNode *)aNode {
	if ([aNode isMemberOfClass:[SKNode class]]) {

		const CGFloat halfWidth = 11;
		const CGFloat dashSize = 8;

		CGPoint center = [_scene convertPointToView:CGPointZero fromNode:aNode];

		const CGFloat leftEdge = center.x - halfWidth;
		const CGFloat rightEdge = center.x + halfWidth;
		const CGFloat topEdge = center.y + halfWidth;
		const CGFloat bottomEdge = center.y - halfWidth;

		NSBezierPath *path = [NSBezierPath bezierPath];

		[path moveToPoint:CGPointMake(leftEdge, bottomEdge + dashSize)];
		[path lineToPoint:CGPointMake(leftEdge, bottomEdge)];
		[path lineToPoint:CGPointMake(leftEdge + dashSize, bottomEdge)];

		[path moveToPoint:CGPointMake(rightEdge - dashSize, bottomEdge)];
		[path lineToPoint:CGPointMake(rightEdge, bottomEdge)];
		[path lineToPoint:CGPointMake(rightEdge, bottomEdge + dashSize)];

		[path moveToPoint:CGPointMake(rightEdge, topEdge - dashSize)];
		[path lineToPoint:CGPointMake(rightEdge, topEdge)];
		[path lineToPoint:CGPointMake(rightEdge - dashSize, topEdge)];

		[path moveToPoint:CGPointMake(leftEdge + dashSize, topEdge)];
		[path lineToPoint:CGPointMake(leftEdge, topEdge)];
		[path lineToPoint:CGPointMake(leftEdge, topEdge - dashSize)];

		[path setLineWidth:2.0];

		[[NSColor blueColor] set];

		CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(ctx);

		/* Draw the glow effect */
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowBlurRadius:2.5];
		[shadow setShadowColor:[NSColor whiteColor]];
		[shadow set];

		for (int i = 0; i < 10; ++i) {
			[path stroke];
		}

		CGContextRestoreGState(ctx);
	}
	for (SKNode *node in aNode.children) {
		[self drawNode:node];
	}
}

- (void)drawSelectionOutline {
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
	[self drawCircleWithCenter:_handlePoints[BMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[BRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[LMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[RMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TLHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Draw a line connecting the node to it's parent */
	if (_node.parent && _node.parent != _scene) {
		NSBezierPath *parentConnectionPath = [NSBezierPath bezierPath];
		[parentConnectionPath moveToPoint:_handlePoints[AnchorPointHandle]];
		[parentConnectionPath lineToPoint:[_scene convertPointToView:CGPointZero fromNode:_node.parent]];
		[[NSColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1.0] setStroke];
		[parentConnectionPath stroke];
		[whiteColor setStroke];
	}

	/* Setup the shadow effect */
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:3.0];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	/* Rotation angle handle */
	const CGFloat rotationLineWidth = 1.0;
	const CGFloat rotationHandleRadius = 4.0;
	[NSBezierPath strokeLineFromPoint:_handlePoints[AnchorPointHandle] toPoint:_handlePoints[RotationHandle]];
	[self drawCircleWithCenter:_handlePoints[AnchorPointHandle] radius:kRotationHandleDistance fillColor:nil strokeColor:strokeColor lineWidth:rotationLineWidth];
	[self drawCircleWithCenter:_handlePoints[RotationHandle] radius:rotationHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

	/* Anchor point handle */
	const CGFloat anchorHandleRadius = 4.0;
	[self drawCircleWithCenter:_handlePoints[AnchorPointHandle] radius:anchorHandleRadius fillColor:whiteColor strokeColor:nil lineWidth:handleLineWidth];
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

- (void)getFramePoints:(CGPoint *)points forNode:(SKNode *)node {
	CGPoint position = [_scene convertPointToView:CGPointZero fromNode:node];

	CGPoint anchorPoint = CGPointZero;
	if ([node respondsToSelector:@selector(anchorPoint)]) {
		anchorPoint = [(id)node anchorPoint];
	}

	CGFloat xScale = node.xScale;
	CGFloat yScale = node.yScale;

	CGSize size = CGSizeZero;
	if ([node respondsToSelector:@selector(size)]) {
		size = [(id)node size];
		size.width /= xScale;
		size.height /= yScale;
	}

	points[AnchorPointHandle] = position;
	points[BLHandle] = [_scene convertPointToView:CGPointMake(-size.width * anchorPoint.x, -size.height * anchorPoint.y) fromNode:node];
	points[BRHandle] = [_scene convertPointToView:CGPointMake(size.width * (1.0 - anchorPoint.x), -size.height * anchorPoint.y) fromNode:node];
	points[TRHandle] = [_scene convertPointToView:CGPointMake(size.width * (1.0 - anchorPoint.x), size.height * (1.0 - anchorPoint.y)) fromNode:node];
	points[TLHandle] = [_scene convertPointToView:CGPointMake(-size.width * anchorPoint.x, size.height * (1.0 - anchorPoint.y)) fromNode:node];
}

- (void)updateHandles {

	CGPoint points[5];

	[self getFramePoints:points forNode:_node];

	_handlePoints[AnchorPointHandle] = points[AnchorPointHandle];

	_handlePoints[BLHandle] = points[BLHandle];
	_handlePoints[BRHandle] = points[BRHandle];
	_handlePoints[TRHandle] = points[TRHandle];
	_handlePoints[TLHandle] = points[TLHandle];

	_handlePoints[RotationHandle] = CGPointMake(_handlePoints[AnchorPointHandle].x + kRotationHandleDistance * cos(_zRotation),
												_handlePoints[AnchorPointHandle].y + kRotationHandleDistance * sin(_zRotation));

	_handlePoints[BMHandle] = CGPointMake((_handlePoints[BLHandle].x + _handlePoints[BRHandle].x) / 2,
										  (_handlePoints[BLHandle].y + _handlePoints[BRHandle].y) / 2);
	_handlePoints[RMHandle] = CGPointMake((_handlePoints[BRHandle].x + _handlePoints[TRHandle].x) / 2,
										  (_handlePoints[BRHandle].y + _handlePoints[TRHandle].y) / 2);
	_handlePoints[TMHandle] = CGPointMake((_handlePoints[TRHandle].x + _handlePoints[TLHandle].x) / 2,
										  (_handlePoints[TRHandle].y + _handlePoints[TLHandle].y) / 2);
	_handlePoints[LMHandle] = CGPointMake((_handlePoints[TLHandle].x + _handlePoints[BLHandle].x) / 2,
										  (_handlePoints[TLHandle].y + _handlePoints[BLHandle].y) / 2);
}

- (CGRect)handleRectFromPoint:(CGPoint)point {
	CGFloat dimension = kHandleRadius * 2.0;
	return CGRectMake(point.x - kHandleRadius, point.y - kHandleRadius, dimension, dimension);
}

- (void)setPosition:(CGPoint)position {
	_position = [_scene convertPointToView:position fromNode:_node.parent];
}

- (CGPoint)position {
	return [_scene convertPointFromView:_position toNode:_node.parent];
}

- (void)setZRotation:(CGFloat)zRotation {
	_zRotation = [_scene convertZRotationToView:zRotation fromNode:_node];
}

- (CGFloat)zRotation {
	return [_scene convertZRotationFromView:_zRotation toNode:_node];
}

- (void)setSize:(CGSize)size {
	_size = [_scene convertSizeToView:size];
}

- (CGSize)size {
	return [_scene convertSizeFromView:_size];
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

	/* Ask for Core Animation backed layer */
	if (!self.wantsLayer) {
		self.wantsLayer = YES;
	}

	/* Clear the properties bindings*/
	[self unbindToNode:_node];

	_node = node;
	self.scene = _node.scene;

	/* Craete the new bindings */
	[self bindToNode:_node];

	/* Nofify the delegate */
	[self.delegate editorView:self didSelectNode:(SKNode *)node];
}

- (SKNode *)node {
	return _node;
}

- (NSArray *)nodesInArray:(NSArray *)nodes containingPoint:(CGPoint)point {
	NSMutableArray *array = [NSMutableArray array];
	for (SKNode *child in nodes) {

		CGMutablePathRef path = CGPathCreateMutable();

		/* Construct the path using the transformed frame */
		if ([child respondsToSelector:@selector(size)]) {
			CGPoint points[5];
			[self getFramePoints:points forNode:child];
			CGPathAddLines(path, NULL, &points[1], 4);

		/* Construct the path using a rectangle of arbitrary size centered at the node's position*/
		} else {
			CGPoint center = [_scene convertPointToView:CGPointZero fromNode:child];
			CGPoint points[4] = {
				{center.x - kRotationHandleDistance, center.y - kRotationHandleDistance},
				{center.x + kRotationHandleDistance, center.y - kRotationHandleDistance},
				{center.x + kRotationHandleDistance, center.y + kRotationHandleDistance},
				{center.x - kRotationHandleDistance, center.y + kRotationHandleDistance}
			};
			CGPathAddLines(path, NULL, &points[0], 4);
		}

		CGPathCloseSubpath(path);

		if (CGPathContainsPoint(path, NULL, point, NO)) {
			[array addObject:child];
		}
		if (child.children.count) {
			[array addObjectsFromArray:[self nodesInArray:child.children containingPoint:point]];
		}

		CGPathRelease(path);
	}
	return array;
};

- (void)mouseDown:(NSEvent *)theEvent {
	[[self window] makeFirstResponder:self];
	if (_scene) {
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
		CGPoint locationInScene = [_scene convertPointFromView:locationInView];
		if (!(_node && [self shouldManipulateHandleWithPoint:locationInView])) {
			NSArray *nodes = [self nodesInArray:_scene.children containingPoint:locationInView];
			if (nodes.count) {
				NSUInteger index = ([nodes indexOfObject:_node] + 1) % nodes.count;
				self.node = [nodes objectAtIndex:index];
			} else {
				self.node = _scene;
			}
		}

		CGPoint nodePositionInScene = [_scene convertPoint:CGPointZero fromNode:_node];
		_draggedPosition = CGPointMake(locationInScene.x - nodePositionInScene.x, locationInScene.y - nodePositionInScene.y);
		[self updateSelectionWithLocationInView:locationInView];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
		[self updateSelectionWithLocationInView:locationInView];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	_manipulatingHandle = NO;
}

/*
 Formula to decompose the distance vector from the handle in the oposite side/corner
 to the mouse pointer into the vectors aligned with the outline edges

 dx,dy mouse distance
 Vx,Vy edge at the bottom/top
 Wx,Wy edge at the left/right
 Rx,Ry the components

 Rx = (dx*Wy - dy*Wx)/(Vx*Wy - Vy*Wx)
 Ry = (dx*Vy - dy*Vx)/(Vy*Wx - Vx*Wy)
 */

- (void)updateSelectionWithLocationInView:(CGPoint)locationInView {
	CGPoint locationInScene = [_scene convertPointFromView:locationInView];
	CGPoint nodePositionInScene = CGPointMake(locationInScene.x - _draggedPosition.x, locationInScene.y - _draggedPosition.y);
	CGPoint newPosition;
	if (_node != _scene) {
		newPosition = [_scene convertPoint:nodePositionInScene toNode:_node.parent];
	} else {
		newPosition = nodePositionInScene;
	}
	if (_manipulatingHandle) {
		if (_manipulatedHandle == AnchorPointHandle) {
			if ([_node respondsToSelector:@selector(anchorPoint)]) {
				/* Translate anchor point and node position */
				CGFloat Vx = _handlePoints[BRHandle].x - _handlePoints[BLHandle].x;
				CGFloat Vy = _handlePoints[BRHandle].y - _handlePoints[BLHandle].y;

				CGFloat Wx = _handlePoints[TLHandle].x - _handlePoints[BLHandle].x;
				CGFloat Wy = _handlePoints[TLHandle].y - _handlePoints[BLHandle].y;

				CGFloat dx = locationInView.x - _handlePoints[BLHandle].x;
				CGFloat dy = locationInView.y - _handlePoints[BLHandle].y;

				CGFloat Rx = (dx * Wy - dy * Wx) / (Vx * Wy - Vy * Wx);
				CGFloat Ry = (dx * Vy - dy * Vx) / (Vy * Wx - Vx * Wy);

				[(id)_node setAnchorPoint:CGPointMake(Rx, Ry)];
				[(id)_node setSize:[_scene convertSizeFromView:_size]]; // setting the anchorPoint make the size positive, so this put back the right size (if it have negative values)

				if (_node != _scene) {
					_node.position = [_scene convertPoint:locationInScene toNode:_node.parent];
				}
			} else {
				_node.position = newPosition;
			}
		} else if (_manipulatedHandle == RotationHandle) {
			_node.zRotation = [_scene convertZRotationFromView:atan2(locationInView.y - _handlePoints[AnchorPointHandle].y,
																	 locationInView.x - _handlePoints[AnchorPointHandle].x)
														toNode:_node];
		} else {

			/* Vectors parallel to the outline edged with magnituds equal to width and height */
			CGFloat Vx = _handlePoints[BRHandle].x - _handlePoints[BLHandle].x;
			CGFloat Vy = _handlePoints[BRHandle].y - _handlePoints[BLHandle].y;

			CGFloat Wx = _handlePoints[TLHandle].x - _handlePoints[BLHandle].x;
			CGFloat Wy = _handlePoints[TLHandle].y - _handlePoints[BLHandle].y;

			/* Distance vector between the the handle and the mouse pointer */
			CGFloat dx, dy;
			if (_manipulatedHandle == TMHandle
				|| _manipulatedHandle == RMHandle
				|| _manipulatedHandle == TRHandle) {
				dx = locationInView.x - _handlePoints[BLHandle].x;
				dy = locationInView.y - _handlePoints[BLHandle].y;

			} else if (_manipulatedHandle == BLHandle
					   || _manipulatedHandle == BMHandle
					   || _manipulatedHandle == LMHandle) {
				dx = _handlePoints[TRHandle].x - locationInView.x;
				dy = _handlePoints[TRHandle].y - locationInView.y;

			} else if (_manipulatedHandle == BRHandle) {
				dx = locationInView.x - _handlePoints[TLHandle].x;
				dy = locationInView.y - _handlePoints[TLHandle].y;

			} else {
				dx = _handlePoints[BRHandle].x - locationInView.x;
				dy = _handlePoints[BRHandle].y - locationInView.y;

			}

			/* Distance vector components */
			CGFloat Rx, Ry;
			Rx = (dx * Wy - dy * Wx) / (Vx * Wy - Vy * Wx);
			Ry = (dx * Vy - dy * Vx) / (Vy * Wx - Vx * Wy);


			/* Resize the node */
			if ([_node respondsToSelector:@selector(size)]) {
				if (_manipulatedHandle == TMHandle || _manipulatedHandle == BMHandle) {
					Rx = 1.0;
				} else if (_manipulatedHandle == RMHandle || _manipulatedHandle == LMHandle) {
					Ry = 1.0;
				} else if (_manipulatedHandle == TRHandle || _manipulatedHandle == BLHandle) {

				} else {// _manipulatedHandle == BRHandle || _manipulatedHandle == TLHandle
					Ry = -Ry;
				}

				[(id)_node setSize:[_scene convertSizeFromView:CGSizeMake(_size.width * Rx, _size.height * Ry)]];
			}

			/* Translate the node to keep it anchored to the corner/size opposite to the handle */
			if (_manipulatedHandle == TMHandle
				|| _manipulatedHandle == RMHandle
				|| _manipulatedHandle == TRHandle) {
				CGVector anchorDistance = CGVectorMake(Vx * _anchorPoint.x * Rx + Wx * _anchorPoint.y * Ry,
													   Vy * _anchorPoint.x * Rx + Wy * _anchorPoint.y * Ry);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BLHandle].x + anchorDistance.dx,
																		  _handlePoints[BLHandle].y + anchorDistance.dy)
													   toNode:_node.parent];
			} else if (_manipulatedHandle == BLHandle
					   || _manipulatedHandle == BMHandle
					   || _manipulatedHandle == LMHandle) {
				CGVector anchorDistance = CGVectorMake(Vx * (1.0 - _anchorPoint.x) * Rx + Wx * (1.0 - _anchorPoint.y) * Ry,
													   Vy * (1.0 - _anchorPoint.x) * Rx + Wy * (1.0 - _anchorPoint.y) * Ry);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[TRHandle].x - anchorDistance.dx,
																		  _handlePoints[TRHandle].y - anchorDistance.dy)
													   toNode:_node.parent];
			} else if (_manipulatedHandle == BRHandle) {
				CGVector anchorDistance = CGVectorMake(Vx * _anchorPoint.x * Rx - Wx * (1.0 - _anchorPoint.y) * Ry,
													   Vy * _anchorPoint.x * Rx - Wy * (1.0 - _anchorPoint.y) * Ry);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[TLHandle].x + anchorDistance.dx,
																		  _handlePoints[TLHandle].y + anchorDistance.dy)
													   toNode:_node.parent];
			} else { //_manipulatedHandle == TLHandle
				CGVector anchorDistance = CGVectorMake(Vx * (1.0 - _anchorPoint.x) * Rx - Wx * _anchorPoint.y * Ry,
													   Vy * (1.0 - _anchorPoint.x) * Rx - Wy * _anchorPoint.y * Ry);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BRHandle].x - anchorDistance.dx,
																		  _handlePoints[BRHandle].y - anchorDistance.dy)
													   toNode:_node.parent];
			}
		}
	} else {
		_node.position = newPosition;
	}

	[self setNeedsDisplay:YES];
}

- (BOOL)shouldManipulateHandleWithPoint:(CGPoint)point {
	_manipulatedHandle = MaxHandle;
	if (NSPointInRect(point, [self handleRectFromPoint:_handlePoints[AnchorPointHandle]])) {
		_manipulatedHandle = AnchorPointHandle;
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

- (void)bindToNode:(SKNode *)node {
	/* Populate the attributes table from the selected node's properties */
	Class classType = [node class];
	do {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(classType, &count);

		if (count) {
			for(unsigned int i = 0; i < count; i++) {
				NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
				[node addObserver:self forKeyPath:key options:0 context:nil];
			}
			free(properties);
		}

		classType = [classType superclass];
	} while (classType != nil && classType != [SKNode superclass]);
}

- (void)unbindToNode:(SKNode *)node {
	/* Populate the attributes table from the selected node's properties */
	Class classType = [node class];
	do {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(classType, &count);

		if (count) {
			for(unsigned int i = 0; i < count; i++) {
				NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
				[node removeObserver:self forKeyPath:key];
			}
			free(properties);
		}

		classType = [classType superclass];
	} while (classType != nil && classType != [SKNode superclass]);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == _node) {
		[self setValue:[_node valueForKey:@"position"] forKey:@"position"];
		[self setValue:[_node valueForKey:@"size"] forKey:@"size"];
		[self setValue:[_node valueForKey:@"zRotation"] forKey:@"zRotation"];
		[self setValue:[_node valueForKey:@"anchorPoint"] forKey:@"anchorPoint"];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self setNeedsDisplay:YES];
		});
	}
}

- (void)dealloc {
	[self unbindToNode:_node];
}

@end
