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

- (CGSize)convertSizeFromView:(CGSize)size toNode:(SKNode *)node {
	CGPoint viewOrigin = [self convertPointFromView:self.frame.origin];

	CGPoint point = CGPointMake(size.width, size.height);
	CGPoint convertedPoint = [self convertPointFromView:point];
	size = CGSizeMake(convertedPoint.x - viewOrigin.x, convertedPoint.y - viewOrigin.y);

	SKNode *parentNode = node.parent;
	if (parentNode) {
/*
		size.width = size.width;
		size.height = size.height;

		node = parentNode;
		parentNode = parentNode.parent;
*/
	}
	return size;
}

- (CGSize)convertSizeToView:(CGSize)size fromNode:(SKNode *)node {
	CGPoint viewOrigin = [self convertPointFromView:self.frame.origin];

	CGPoint point = CGPointMake(size.width + viewOrigin.x, size.height + viewOrigin.y);
	CGPoint convertedPoint = [self convertPointToView:point];
	size = CGSizeMake(convertedPoint.x, convertedPoint.y);

	SKNode *parentNode = node.parent;
	if (parentNode) {
/*
		CGFloat zRotation = node.zRotation;
		CGFloat cosine = fabs(cos(zRotation));
		CGFloat sine = fabs(sin(zRotation));

		CGPoint rotatedUpperRight;
		rotatedUpperRight.x = (size.width * cosine - size.height *sine) * parentNode.xScale;
		rotatedUpperRight.y = (size.width * sine + size.height * cosine) * parentNode.yScale;

		CGFloat angle = atan2(rotatedUpperRight.y, rotatedUpperRight.x) - acos(cosine);
		CGFloat distance = sqrt(rotatedUpperRight.x * rotatedUpperRight.x + rotatedUpperRight.y * rotatedUpperRight.y);

		size.width = distance * cos(angle);
		size.height = distance * sin(angle);

		node = parentNode;
		parentNode = parentNode.parent;
*/
	}
	return size;
}

- (CGPoint)convertPointFromView:(CGPoint)point toNode:(SKNode *)node {
	point = [self convertPointFromView:point];
	if (node.parent) {
		point = [self convertPoint:point toNode:node.parent];
	}
	return point;
}

- (CGPoint)convertPointToView:(CGPoint)point fromNode:(SKNode *)node {
	if (node.parent) {
		point = [self convertPoint:point fromNode:node.parent];
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

@interface SKShapeNode (Size)
@property (nonatomic) CGSize size;
@property (nonatomic) CGPoint anchorPoint;
@end

@implementation SKShapeNode (Size)

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
	if (_node) {
		[self drawRectangleOutline];
	}
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
	[self drawCircleWithCenter:_handlePoints[BMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[BRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[LMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[RMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TLHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TMHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];
	[self drawCircleWithCenter:_handlePoints[TRHandle] radius:kHandleRadius fillColor:fillColor strokeColor:strokeColor lineWidth:handleLineWidth];

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

	CGFloat xScale = 1.0;
	CGFloat yScale = 1.0;
	SKNode *parentNode = _node.parent;

	while (parentNode) {
		xScale *= parentNode.xScale;
		yScale *= parentNode.yScale;
		parentNode = parentNode.parent;
	}

	_handlePoints[BLHandle] = CGPointMake(_position.x + _anchorPoint.y * xScale * size.height * sine - _anchorPoint.x * xScale * size.width * cosine,
										  _position.y - _anchorPoint.y * yScale * size.height * cosine - _anchorPoint.x * yScale * size.width * sine);
	_handlePoints[BRHandle] = NSMakePoint(_handlePoints[BLHandle].x + xScale * size.width * cosine, _handlePoints[BLHandle].y + yScale * size.width * sine);
	_handlePoints[TRHandle] = NSMakePoint(_handlePoints[BRHandle].x - xScale * size.height * sine, _handlePoints[BRHandle].y + yScale * size.height * cosine);
	_handlePoints[TLHandle] = NSMakePoint(_handlePoints[BLHandle].x - xScale * size.height * sine, _handlePoints[BLHandle].y + yScale * size.height * cosine);

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
	_position = [_scene convertPointToView:position fromNode:_node];
	[self setNeedsDisplay:YES];
}

- (CGPoint)position {
	return [_scene convertPointFromView:_position toNode:_node];
}

- (void)setZRotation:(CGFloat)zRotation {
	_zRotation = [_scene convertZRotationToView:zRotation fromNode:_node];
	[self setNeedsDisplay:YES];
}

- (CGFloat)zRotation {
	return [_scene convertZRotationFromView:_zRotation toNode:_node];
}

- (void)setSize:(CGSize)size {
	_size = [_scene convertSizeToView:size fromNode:_node];
	[self setNeedsDisplay:YES];
}

- (CGSize)size {
	return [_scene convertSizeFromView:_size toNode:_node];
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

- (void)mouseDown:(NSEvent *)theEvent {
	[[self window] makeFirstResponder:self];
	if (_scene) {
		CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
		CGPoint locationInScene = [_scene convertPointFromView:locationInView toNode:_node];
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

- (void)updateSelectionWithLocationInView:(CGPoint)locationInView {
	CGPoint locationInScene = [_scene convertPointFromView:locationInView toNode:_node];
	CGPoint newPosition = CGPointMake(locationInScene.x - _draggedPosition.x, locationInScene.y - _draggedPosition.y);
	if (_manipulatingHandle) {
		if (_manipulatedHandle == AnchorPointHAndle) {
			if ([_node respondsToSelector:@selector(anchorPoint)]) {
				/* Translate anchor point and node position */
				CGVector distanceVector = CGVectorMake(locationInView.x - _handlePoints[BLHandle].x,
													   locationInView.y - _handlePoints[BLHandle].y);
				CGFloat distance = sqrt(distanceVector.dx * distanceVector.dx + distanceVector.dy * distanceVector.dy);
				CGFloat angle = atan2(distanceVector.dy, distanceVector.dx) - _zRotation;

				[(id)_node setAnchorPoint:CGPointMake(distance * cos(angle) / _size.width, distance * sin(angle) / _size.height)];
				[(id)_node setSize:[_scene convertSizeFromView:_size toNode:_node]]; // setting the anchorPoint make the size positive, so this put back the right size (if it have negative values)
				_node.position = locationInScene;
			} else {
				_node.position = newPosition;
			}
		} else if (_manipulatedHandle == RotationHandle) {
			_node.zRotation = [_scene convertZRotationFromView:atan2(locationInView.y - _handlePoints[AnchorPointHAndle].y,
																	 locationInView.x - _handlePoints[AnchorPointHAndle].x)
														toNode:_node];
		} else {
			CGVector distanceVector;

			/* Distance vector between the the handle and the mouse pointer */
			if (_manipulatedHandle == TMHandle
				|| _manipulatedHandle == RMHandle
				|| _manipulatedHandle == TRHandle) {
				distanceVector = CGVectorMake(locationInView.x - _handlePoints[BLHandle].x,
											  locationInView.y - _handlePoints[BLHandle].y);
			} else if (_manipulatedHandle == BLHandle
					   || _manipulatedHandle == BMHandle
					   || _manipulatedHandle == LMHandle) {
				distanceVector = CGVectorMake(_handlePoints[TRHandle].x - locationInView.x,
											  _handlePoints[TRHandle].y - locationInView.y);
			} else if (_manipulatedHandle == BRHandle) {
				distanceVector = CGVectorMake(locationInView.x - _handlePoints[TLHandle].x,
											  locationInView.y - _handlePoints[TLHandle].y);
			} else {
				distanceVector = CGVectorMake(_handlePoints[BRHandle].x - locationInView.x,
											  _handlePoints[BRHandle].y - locationInView.y);
			}

			CGFloat distance = sqrt(distanceVector.dx * distanceVector.dx + distanceVector.dy * distanceVector.dy);
			CGFloat angle = atan2(distanceVector.dy, distanceVector.dx) - _zRotation;

			if ([_node respondsToSelector:@selector(size)]) {
				/* Resize the node */
				if (_manipulatedHandle == TMHandle
					|| _manipulatedHandle == BMHandle) {
					[(id)_node setSize:[_scene convertSizeFromView:CGSizeMake(_size.width, distance * sin(angle)) toNode:_node]];
				} else if (_manipulatedHandle == RMHandle
						   || _manipulatedHandle == LMHandle) {
					[(id)_node setSize:[_scene convertSizeFromView:CGSizeMake(distance * cos(angle), _size.height) toNode:_node]];
				} else if (_manipulatedHandle == TRHandle
						   || _manipulatedHandle == BLHandle) {
					[(id)_node setSize:[_scene convertSizeFromView:CGSizeMake(distance * cos(angle), distance * sin(angle)) toNode:_node]];
				} else {
					[(id)_node setSize:[_scene convertSizeFromView:CGSizeMake(distance * cos(angle), -distance * sin(angle)) toNode:_node]];
				}
			}

			CGFloat cosine = cos(_zRotation);
			CGFloat sine = sin(_zRotation);

			/* Translate the node */
			if (_manipulatedHandle == TMHandle
				|| _manipulatedHandle == RMHandle
				|| _manipulatedHandle == TRHandle) {
				CGVector anchorDistance = CGVectorMake(_size.width * _anchorPoint.x, _size.height * _anchorPoint.y);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BLHandle].x + anchorDistance.dx * cosine - anchorDistance.dy * sine,
																		  _handlePoints[BLHandle].y + anchorDistance.dx * sine + anchorDistance.dy * cosine)
													   toNode:_node];
			} else if (_manipulatedHandle == BLHandle
					   || _manipulatedHandle == BMHandle
					   || _manipulatedHandle == LMHandle) {
				CGVector anchorDistance = CGVectorMake(_size.width * (1.0 - _anchorPoint.x), _size.height * (1.0 - _anchorPoint.y));
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[TRHandle].x - anchorDistance.dx * cosine + anchorDistance.dy * sine,
																		  _handlePoints[TRHandle].y - anchorDistance.dx * sine - anchorDistance.dy * cosine)
													   toNode:_node];
			} else if (_manipulatedHandle == BRHandle) {
				CGVector anchorDistance = CGVectorMake(_size.width * _anchorPoint.x, _size.height * (1.0 - _anchorPoint.y));
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[TLHandle].x + anchorDistance.dx * cosine + anchorDistance.dy * sine,
																		  _handlePoints[TLHandle].y + anchorDistance.dx * sine - anchorDistance.dy * cosine)
													   toNode:_node];
			} else {
				CGVector anchorDistance = CGVectorMake(_size.width * (1.0 - _anchorPoint.x), _size.height * _anchorPoint.y);
				_node.position = [_scene convertPointFromView:CGPointMake(_handlePoints[BRHandle].x - anchorDistance.dx * cosine - anchorDistance.dy * sine,
																		  _handlePoints[BRHandle].y - anchorDistance.dx * sine + anchorDistance.dy * cosine)
													   toNode:_node];
			}
		}
	} else {
		_node.position = newPosition;
	}
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
	}
}

@end
