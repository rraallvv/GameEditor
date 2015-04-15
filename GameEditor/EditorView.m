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

#pragma mark NSBezierPath

@implementation NSBezierPath (Additions)

- (void)appendBezierPathWithCircleWithCenter:(NSPoint)center radius:(CGFloat)radius {
	[self moveToPoint:CGPointMake(center.x + radius, center.y)];
	[self appendBezierPathWithArcWithCenter:center radius:radius startAngle:0 endAngle:M_2_PI clockwise:YES];
}

@end

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
	CGPoint _handleOffset;
	BOOL _manipulatingHandle;
	ManipulatedHandle _manipulatedHandle;
	NSMutableSet *_boundAttributes;
	NSString *_prevObservedKeyPath;
	__weak id _prevObservedObject;
	CGPoint _viewOrigin;
	CGFloat _viewScale;

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

	if (!_scene)
		return;

	/* Draw the scene frame */
	[[NSColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1.0] set];

	CGRect rect;
	rect.origin = CGPointMake(_viewOrigin.x, _viewOrigin.y);
	rect.size = CGSizeMake(_scene.size.width / _viewScale, _scene.size.height / _viewScale);

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];
	[path appendBezierPathWithRect:rect];

	[path stroke];

	[self drawSelectionInNode:_scene];

	if (_node && _node != _scene)
		[self drawHandles];
}

- (void)drawSelectionInNode:(SKNode *)aNode {

	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(ctx);

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:2.0];

	CGPoint center = [_scene convertPoint:CGPointZero fromNode:aNode];
	center.x /= _viewScale;
	center.y /= _viewScale;
	center.x += _viewOrigin.x;
	center.y += _viewOrigin.y;

	NSColor *color = nil;

	if ([aNode isMemberOfClass:[SKNode class]]) {

		const CGFloat halfWidth = 11;
		const CGFloat dashSize = 8;

		const CGFloat leftEdge = center.x - halfWidth;
		const CGFloat rightEdge = center.x + halfWidth;
		const CGFloat topEdge = center.y + halfWidth;
		const CGFloat bottomEdge = center.y - halfWidth;

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

		color = [NSColor magentaColor];

	} else if ([aNode isKindOfClass:[SKEmitterNode class]]) {

		const CGFloat distance = 8.0;

		CGFloat angles[] = {
			GLKMathDegreesToRadians(30),
			GLKMathDegreesToRadians(150),
			GLKMathDegreesToRadians(270)
		};

		for (int i = 0; i < 3; ++i) {
			[path appendBezierPathWithCircleWithCenter:CGPointMake(center.x + distance * cos(angles[i]), center.y + distance * sin(angles[i]))
												radius:kHandleRadius];
		}

		color = [NSColor magentaColor];

	} else if ([aNode isKindOfClass:[SKLightNode class]]) {

		const CGFloat distance1 = 8.0;
		const CGFloat distance2 = 16.0;

		[path appendBezierPathWithCircleWithCenter:center radius:distance1];

		CGFloat angles[] = {
			GLKMathDegreesToRadians(45),
			GLKMathDegreesToRadians(135),
			GLKMathDegreesToRadians(225),
			GLKMathDegreesToRadians(315)
		};

		for (int i = 0; i < 4; ++i) {
			CGFloat cosine = cos(angles[i]);
			CGFloat sine = sin(angles[i]);
			[path moveToPoint:CGPointMake(center.x + distance1 * cosine, center.y + distance1 * sine)];
			[path lineToPoint:CGPointMake(center.x + distance2 * cosine, center.y + distance2 * sine)];
		}

		color = [NSColor yellowColor];

	} else if ([aNode isKindOfClass:[SKFieldNode class]]) {

		const CGFloat distance1 = 4.25;
		const CGFloat distance2 = 11.25;

		[path appendBezierPathWithCircleWithCenter:center radius:distance1];
		[path appendBezierPathWithCircleWithCenter:center radius:distance2];

		color = [NSColor cyanColor];

	}

	if (_node == aNode) {
		[[NSColor colorWithRed:0.4 green:0.5 blue:1.0 alpha:1.0] setStroke];

		/* Set the glow effect */
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[NSColor whiteColor]];
		[shadow set];

		// TODO: Avoid drawing multiple times to get the glow effect
		for (int i = 0; i < 8; ++i) {
			[path stroke];
		}
	} else {
		[color setStroke];
		[path stroke];
	}

	CGContextRestoreGState(ctx);

	for (SKNode *node in aNode.children) {
		[self drawSelectionInNode:node];
	}
}

- (void)drawHandles {

	[self updateHandles];

	NSColor *whiteColor = [NSColor whiteColor];
	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.345 green:0.337 blue:0.961 alpha:1.0];
	NSColor *orangeColor = [NSColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1.0];

	const CGFloat handleLineWidth = 1.5;
	NSColor *fillColor = blueColor;
	NSColor *strokeColor = whiteColor;

	if ([_node respondsToSelector:@selector(size)]) {
		/* Draw outline */
		NSBezierPath *outlinePath = [NSBezierPath bezierPath];
		[blueColor setStroke];
		[outlinePath appendBezierPathWithPoints:&_handlePoints[BLHandle] count:4];
		[outlinePath closePath];
		[outlinePath setLineWidth:1.0];
		[outlinePath stroke];

		/* Draw size handles */
		NSBezierPath *path = [NSBezierPath bezierPath];
		[fillColor setFill];
		[strokeColor setStroke];
		[path setLineWidth:handleLineWidth];
		for (int i = BLHandle; i <= LMHandle; ++i) {
			[path appendBezierPathWithCircleWithCenter:_handlePoints[i] radius:kHandleRadius];
		}
		[path fill];
		[path stroke];
	}

	[strokeColor set];

	/* Draw a line connecting the node to it's parent */
	if (_node.parent && _node.parent != _scene) {
		NSBezierPath *parentConnectionPath = [NSBezierPath bezierPath];
		[parentConnectionPath moveToPoint:_handlePoints[AnchorPointHandle]];
		CGPoint parentPosition = [_scene convertPoint:CGPointZero fromNode:_node.parent];
		parentPosition.x /= _viewScale;
		parentPosition.y /= _viewScale;
		parentPosition.x += _viewOrigin.x;
		parentPosition.y += _viewOrigin.y;
		[parentConnectionPath lineToPoint:parentPosition];
		[orangeColor setStroke];
		[parentConnectionPath stroke];
	}

	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(ctx);

	/* Setup the shadow effect */
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:3.0];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow set];

	/* Rotation handle */
	[whiteColor setStroke];
	const CGFloat rotationLineWidth = 1.0;
	const CGFloat rotationHandleRadius = 4.0;
	[NSBezierPath strokeLineFromPoint:_handlePoints[AnchorPointHandle] toPoint:_handlePoints[RotationHandle]];
	[self drawCircleWithCenter:_handlePoints[AnchorPointHandle] radius:kRotationHandleDistance fillColor:nil strokeColor:strokeColor lineWidth:rotationLineWidth];
	[self drawCircleWithCenter:_handlePoints[RotationHandle] radius:rotationHandleRadius fillColor:fillColor strokeColor:nil lineWidth:handleLineWidth];

	/* Anchor point handle */
	const CGFloat anchorHandleRadius = 4.0;
	[self drawCircleWithCenter:_handlePoints[AnchorPointHandle] radius:anchorHandleRadius fillColor:whiteColor strokeColor:nil lineWidth:handleLineWidth];

	CGContextRestoreGState(ctx);

	/* Fill the rotation handle without the shadow effect */
	[self drawCircleWithCenter:_handlePoints[RotationHandle] radius:rotationHandleRadius fillColor:nil strokeColor:strokeColor lineWidth:handleLineWidth];
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
	CGPoint position = [_scene convertPoint:CGPointZero fromNode:node];

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
	points[BLHandle] = [_scene convertPoint:CGPointMake(-size.width * anchorPoint.x, -size.height * anchorPoint.y) fromNode:node];
	points[BRHandle] = [_scene convertPoint:CGPointMake(size.width * (1.0 - anchorPoint.x), -size.height * anchorPoint.y) fromNode:node];
	points[TRHandle] = [_scene convertPoint:CGPointMake(size.width * (1.0 - anchorPoint.x), size.height * (1.0 - anchorPoint.y)) fromNode:node];
	points[TLHandle] = [_scene convertPoint:CGPointMake(-size.width * anchorPoint.x, size.height * (1.0 - anchorPoint.y)) fromNode:node];

	for (int i = AnchorPointHandle; i <= TLHandle; ++i) {
		points[i].x /= _viewScale;
		points[i].y /= _viewScale;
		points[i].x += _viewOrigin.x;
		points[i].y += _viewOrigin.y;
	}
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
	CGFloat dimension = kHandleRadius * 2.5;
	return CGRectMake(point.x - kHandleRadius, point.y - kHandleRadius, dimension, dimension);
}

- (void)setPosition:(CGPoint)position {
	if (_node != _scene)
		_position = [_scene convertPoint:position fromNode:_node.parent];
}

- (CGPoint)position {
	return [_scene convertPoint:_position toNode:_node.parent];
}

- (void)setZRotation:(CGFloat)zRotation {
	_zRotation = [_scene convertZRotationToView:zRotation fromNode:_node];
}

- (CGFloat)zRotation {
	return [_scene convertZRotationFromView:_zRotation toNode:_node];
}

- (void)setSize:(CGSize)size {
	_size = size;
}

- (CGSize)size {
	return _size;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint {
	_anchorPoint = anchorPoint;
}

- (CGPoint)anchorPoint {
	return _anchorPoint;
}

- (void)setScene:(SKScene *)scene {
	if (_scene == scene)
		return;

	_scene = scene;

	/* Set the view scale to the default value */
	_viewScale = 1.0;

	/* Center the scene in the editor's view */
	CGSize viewSize = self.bounds.size;
	CGSize sceneSize = _scene.size;
	_viewOrigin = CGPointMake(0.5 * (viewSize.width - sceneSize.width),
							  0.5 * (viewSize.height - sceneSize.height));
}

- (SKScene *)scene {
	return _scene;
}

- (void)setNode:(SKNode *)node {
	if (_node == node)
		return;

	/* Ask for Core Animation backed layer */
	if (!self.wantsLayer) {
		self.wantsLayer = YES;
	}

	/* Clear the properties bindings*/
	[self unbindFromSelectedNode];

	_node = node;

	//self.scene = _node.scene;

	/* Craete the new bindings */
	[self bindToSelectedNode];

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
			CGPoint center = [_scene convertPoint:CGPointZero fromNode:child];
			center.x /= _viewScale;
			center.y /= _viewScale;
			center.x += _viewOrigin.x;
			center.y += _viewOrigin.y;
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

#pragma mark Mouse event handling

- (void)mouseDown:(NSEvent *)theEvent {
	[[self window] makeFirstResponder:self];
	if (_scene) {
		CGPoint locationInScene = [self convertPoint:theEvent.locationInWindow fromView:nil];
		if (!(_node && [self shouldManipulateHandleWithPoint:locationInScene])) {
			NSArray *nodes = [self nodesInArray:_scene.children containingPoint:locationInScene];
			if (nodes.count) {
				NSUInteger index = ([nodes indexOfObject:_node] + 1) % nodes.count;
				self.node = [nodes objectAtIndex:index];
			} else {
				self.node = _scene;
			}
		}

		if (_node == _scene) {
			/* Get the position being dragged relative to the editor's view */
			_draggedPosition = CGPointMake(locationInScene.x - _viewOrigin.x, locationInScene.y - _viewOrigin.y);

			[[NSCursor pointingHandCursor] set];

		} else {
			/* Save the offset between the mouse pointer and the handle */
			if (_manipulatingHandle) {
				_handleOffset.x = locationInScene.x - _handlePoints[_manipulatedHandle].x;
				_handleOffset.y = locationInScene.y - _handlePoints[_manipulatedHandle].y;
			}

			/* Get the position being dragged relative to the node's position */
			CGPoint nodePositionInScene = [_scene convertPoint:CGPointZero fromNode:_node];
			nodePositionInScene.x /= _viewScale;
			nodePositionInScene.y /= _viewScale;
			_draggedPosition = CGPointMake(locationInScene.x - nodePositionInScene.x, locationInScene.y - nodePositionInScene.y);
		}

		//[self updateSelectionWithLocationInScene:locationInScene];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint locationInScene = [self convertPoint:theEvent.locationInWindow fromView:nil];
		[self updateSelectionWithLocationInScene:locationInScene];

		if (_node == _scene) {
			[[NSCursor pointingHandCursor] set];
		}
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	_manipulatingHandle = NO;

	if (_node == _scene) {
		[[NSCursor arrowCursor] set];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent {
	if (_scene) {
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

		CGPoint locationInScene = CGPointMake(_viewScale * (locationInView.x - _viewOrigin.x), _viewScale * (locationInView.y - _viewOrigin.y));

		_viewScale = MIN(MAX(_viewScale * (1.0 - theEvent.deltaY / 30), 0.25), 40.0);

		_viewOrigin = CGPointMake(locationInView.x - locationInScene.x / _viewScale, locationInView.y - locationInScene.y / _viewScale);

		[self updateVisibleRect];
		[self setNeedsDisplay:YES];
	}
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

- (void)updateSelectionWithLocationInScene:(CGPoint)locationInScene {
	if (_node == _scene) {
		CGPoint nodePositionInScene = CGPointMake(locationInScene.x - _draggedPosition.x, locationInScene.y - _draggedPosition.y);
		_viewOrigin.x = nodePositionInScene.x;
		_viewOrigin.y = nodePositionInScene.y;
		[self updateVisibleRect];

	} else {

		/* Remove the offset between the mouse pointer and the handle */
		if (_manipulatingHandle) {
			locationInScene.x -= _handleOffset.x;
			locationInScene.y -= _handleOffset.y;
		}

		CGPoint nodePositionInScene = CGPointMake(locationInScene.x - _draggedPosition.x, locationInScene.y - _draggedPosition.y);
		nodePositionInScene.x *= _viewScale;
		nodePositionInScene.y *= _viewScale;
		CGPoint nodePosition = [_scene convertPoint:nodePositionInScene toNode:_node.parent];

		if (_manipulatingHandle) {
			if (_manipulatedHandle == AnchorPointHandle) {
				if ([_node respondsToSelector:@selector(anchorPoint)]) {
					/* Translate anchor point and node position */
					CGFloat Vx = _handlePoints[BRHandle].x - _handlePoints[BLHandle].x;
					CGFloat Vy = _handlePoints[BRHandle].y - _handlePoints[BLHandle].y;

					CGFloat Wx = _handlePoints[TLHandle].x - _handlePoints[BLHandle].x;
					CGFloat Wy = _handlePoints[TLHandle].y - _handlePoints[BLHandle].y;

					CGFloat dx = locationInScene.x - _handlePoints[BLHandle].x;
					CGFloat dy = locationInScene.y - _handlePoints[BLHandle].y;

					CGFloat Rx = (dx * Wy - dy * Wx) / (Vx * Wy - Vy * Wx);
					CGFloat Ry = (dx * Vy - dy * Vx) / (Vy * Wx - Vx * Wy);

					CGSize size = _size; // save the current size

					[(id)_node setAnchorPoint:CGPointMake(Rx, Ry)];

					[(id)_node setSize:size]; // restore the size; this is needed if the current size has a negative value

					nodePosition = CGPointMake(locationInScene.x - _viewOrigin.x,
											   locationInScene.y - _viewOrigin.y);
					nodePosition.x *= _viewScale;
					nodePosition.y *= _viewScale;
					_node.position = [_scene convertPoint:nodePosition
												   toNode:_node.parent];
				} else {
					_node.position = nodePosition;
				}
			} else if (_manipulatedHandle == RotationHandle) {
				_node.zRotation = [_scene convertZRotationFromView:atan2(locationInScene.y - _handlePoints[AnchorPointHandle].y,
																		 locationInScene.x - _handlePoints[AnchorPointHandle].x)
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
					dx = locationInScene.x - _handlePoints[BLHandle].x;
					dy = locationInScene.y - _handlePoints[BLHandle].y;

				} else if (_manipulatedHandle == BLHandle
						   || _manipulatedHandle == BMHandle
						   || _manipulatedHandle == LMHandle) {
					dx = _handlePoints[TRHandle].x - locationInScene.x;
					dy = _handlePoints[TRHandle].y - locationInScene.y;

				} else if (_manipulatedHandle == BRHandle) {
					dx = locationInScene.x - _handlePoints[TLHandle].x;
					dy = locationInScene.y - _handlePoints[TLHandle].y;

				} else {
					dx = _handlePoints[BRHandle].x - locationInScene.x;
					dy = _handlePoints[BRHandle].y - locationInScene.y;

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

					[(id)_node setSize:CGSizeMake(_size.width * Rx, _size.height * Ry)];
				}

				/* Translate the node to keep it anchored to the corner/size opposite to the handle */
				if (_manipulatedHandle == TMHandle
					|| _manipulatedHandle == RMHandle
					|| _manipulatedHandle == TRHandle) {
					CGVector anchorDistance = CGVectorMake(Vx * _anchorPoint.x * Rx + Wx * _anchorPoint.y * Ry,
														   Vy * _anchorPoint.x * Rx + Wy * _anchorPoint.y * Ry);
					nodePosition = CGPointMake(_handlePoints[BLHandle].x + anchorDistance.dx - _viewOrigin.x,
											   _handlePoints[BLHandle].y + anchorDistance.dy - _viewOrigin.y);
					nodePosition.x *= _viewScale;
					nodePosition.y *= _viewScale;
					_node.position = [_scene convertPoint:nodePosition
												   toNode:_node.parent];
				} else if (_manipulatedHandle == BLHandle
						   || _manipulatedHandle == BMHandle
						   || _manipulatedHandle == LMHandle) {
					CGVector anchorDistance = CGVectorMake(Vx * (1.0 - _anchorPoint.x) * Rx + Wx * (1.0 - _anchorPoint.y) * Ry,
														   Vy * (1.0 - _anchorPoint.x) * Rx + Wy * (1.0 - _anchorPoint.y) * Ry);
					nodePosition = CGPointMake(_handlePoints[TRHandle].x - anchorDistance.dx - _viewOrigin.x,
											   _handlePoints[TRHandle].y - anchorDistance.dy - _viewOrigin.y);
					nodePosition.x *= _viewScale;
					nodePosition.y *= _viewScale;
					_node.position = [_scene convertPoint:nodePosition
												   toNode:_node.parent];
				} else if (_manipulatedHandle == BRHandle) {
					CGVector anchorDistance = CGVectorMake(Vx * _anchorPoint.x * Rx - Wx * (1.0 - _anchorPoint.y) * Ry,
														   Vy * _anchorPoint.x * Rx - Wy * (1.0 - _anchorPoint.y) * Ry);
					nodePosition = CGPointMake(_handlePoints[TLHandle].x + anchorDistance.dx - _viewOrigin.x,
											   _handlePoints[TLHandle].y + anchorDistance.dy - _viewOrigin.y);
					nodePosition.x *= _viewScale;
					nodePosition.y *= _viewScale;
					_node.position = [_scene convertPoint:nodePosition
												   toNode:_node.parent];
				} else { //_manipulatedHandle == TLHandle
					CGVector anchorDistance = CGVectorMake(Vx * (1.0 - _anchorPoint.x) * Rx - Wx * _anchorPoint.y * Ry,
														   Vy * (1.0 - _anchorPoint.x) * Rx - Wy * _anchorPoint.y * Ry);
					nodePosition = CGPointMake(_handlePoints[BRHandle].x - anchorDistance.dx - _viewOrigin.x,
											   _handlePoints[BRHandle].y - anchorDistance.dy - _viewOrigin.y);
					nodePosition.x *= _viewScale;
					nodePosition.y *= _viewScale;
					_node.position = [_scene convertPoint:nodePosition
												   toNode:_node.parent];
				}
			}
		} else {
			_node.position = nodePosition;
		}
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

- (void)bindToSelectedNode {
	/* Start observing all properties in the selected node */
	_boundAttributes = [NSMutableSet set];
	Class classType = [_node class];
	do {
		unsigned int count;
		objc_property_t *properties = class_copyPropertyList(classType, &count);

		if (count) {
			for(unsigned int i = 0; i < count; i++) {
				NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
				[_node addObserver:self forKeyPath:key options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
			}
			free(properties);
		}

		classType = [classType superclass];
	} while (classType != nil && classType != [SKNode superclass]);
}

- (void)unbindFromSelectedNode {
	/* Stop observing the bound properties in the selected node */
	for (NSString *key in _boundAttributes) {
		[_node removeObserver:self forKeyPath:key];
	}
	_boundAttributes = nil;
}

- (void)updateVisibleRect {
	if (_scene) {
		CGRect oldVisibleRect = [[_scene valueForKey:@"visibleRect"] rectValue];
		CGRect visibleRect;
		visibleRect.origin = CGPointMake(-_viewOrigin.x, -_viewOrigin.y);
		visibleRect.origin.x *= _viewScale;
		visibleRect.origin.y *= _viewScale;
		visibleRect.size = self.bounds.size;
		visibleRect.size.width *= _viewScale;
		visibleRect.size.height *= _viewScale;
		if (!CGRectEqualToRect(visibleRect, oldVisibleRect)) {
			[_scene setValue:[NSValue valueWithRect:visibleRect] forKey:@"visibleRect"];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == _node) {

		/* Try to register an undo operation for the observed change */
		if ([_boundAttributes containsObject:keyPath]) {
			if (![keyPath isEqualToString:@"visibleRect"]) {
				if (![[change objectForKey:NSKeyValueChangeOldKey] isEqual:[change objectForKey:NSKeyValueChangeNewKey]]) {
					if (![_prevObservedKeyPath isEqualToString:keyPath] || ![_prevObservedObject isEqual:object]) {

						//[[self.undoManager prepareWithInvocationTarget:_node] setValue:[_node valueForKey:keyPath] forKey:keyPath];
						//[self.undoManager setActionName:keyPath];

						NSLog(@"\nRegister undo operation for node:%p keyPath:%@ value:%@ %@\n", _node, keyPath, [change objectForKey:NSKeyValueChangeOldKey], [change objectForKey:NSKeyValueChangeNewKey]);
						_prevObservedKeyPath = keyPath;
						_prevObservedObject = _node;
					}
				}
			}
		} else {
			[_boundAttributes addObject:keyPath];
		}

		/* Update the current selection and editor view's visible rect */
		if (object != _scene) {
			[self setValue:[_node valueForKey:@"position"] forKey:@"position"];
			[self setValue:[_node valueForKey:@"size"] forKey:@"size"];
			[self setValue:[_node valueForKey:@"zRotation"] forKey:@"zRotation"];
			[self setValue:[_node valueForKey:@"anchorPoint"] forKey:@"anchorPoint"];
		} else {
			[self updateVisibleRect];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			[self setNeedsDisplay:YES];
		});
	}
}

- (void)setFrame:(NSRect)frame {
	[super setFrame:frame];
	[self updateVisibleRect];
}

- (void)dealloc {
	[self unbindFromSelectedNode];
}

@end
