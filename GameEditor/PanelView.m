/*
 * PanelView.m
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

#import "PanelView.h"

@implementation PanelView {
	NSMutableArray *_customTrackingAreas;
	NSMutableArray *_customCursors;
	NSMutableArray *_customTrackingRects;
	NSPoint _draggingPoint;
	BOOL _dragging;
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect rect = [self bounds];
	[self.backgroundColor set];
	NSRectFill(rect);

	NSBezierPath *path = [NSBezierPath bezierPath];
	if (self.topBorder) {
		[path moveToPoint:CGPointMake(NSMinX(rect), NSMaxY(rect))];
		[path lineToPoint:CGPointMake(NSMaxX(rect), NSMaxY(rect))];
	}
	if (self.bottomBorder) {
		[path moveToPoint:CGPointMake(NSMinX(rect), NSMinY(rect))];
		[path lineToPoint:CGPointMake(NSMaxX(rect), NSMinY(rect))];
	}
	[[NSColor lightGrayColor] set];
	[path stroke];
}

-(void)mouseDown:(NSEvent *)event {
	if (self.draggable) {
		_draggingPoint = [self convertPoint:event.locationInWindow fromView:nil];
		_dragging = YES;
		[self.window disableCursorRects];
		[self cursorUpdate: event];
	}
}

- (void)mouseUp:(NSEvent *)event {
	if (self.draggable) {
		_dragging = NO;
		[self.window enableCursorRects];
		[self cursorUpdate: event];
	}
}

- (void)mouseDragged:(NSEvent *)event {
	if (self.draggable) {
		NSPoint locationInView = [self convertPoint:event.locationInWindow fromView:nil];

		NSSplitView *panelView = (NSSplitView *)[[self superview] superview];

		NSRect frame = [[[panelView subviews] objectAtIndex:0] frame];
		CGFloat delta = _draggingPoint.y - locationInView.y;
		CGFloat newPosition = NSMaxY(frame) + delta;

		[panelView setPosition:newPosition ofDividerAtIndex:0];

		[self cursorUpdate: event];
	}
}

- (void)cursorUpdate:(NSEvent *)event {
	if (self.draggable) {
		NSPoint locationInView = [self convertPoint:event.locationInWindow fromView:nil];
		NSCursor *cursor = _dragging ? [NSCursor resizeUpDownCursor] : nil;
		for (int i=0; i<_customTrackingRects.count; ++i) {
			NSRect rect = [_customTrackingRects[i] rectValue];
			if (NSPointInRect(locationInView, rect)) {
				cursor = _customCursors[i];
			}
		}
		[cursor set];
	}
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];

	if (self.draggable) {
		if (_customTrackingAreas == nil) {

			_customTrackingAreas = [NSMutableArray array];
			_customTrackingRects = [NSMutableArray array];
			_customCursors = [NSMutableArray array];

			NSRect rect = self.bounds;

			for (NSView *subView in [self subviews]) {
				NSRect subViewRect = subView.frame;
				[self addTrackingRect:subViewRect forCursor:[NSCursor arrowCursor]];

				NSRect trackingRect = NSMakeRect(NSMinX(rect), NSMinY(rect), NSMinX(subViewRect) - NSMinX(rect), NSHeight(rect));
				[self addTrackingRect:trackingRect forCursor:[NSCursor resizeUpDownCursor]];

				rect = NSMakeRect(NSMaxX(subViewRect), NSMinY(rect), NSMaxX(rect) - NSMaxX(subViewRect), NSHeight(rect));
			}

			[self addTrackingRect:rect forCursor:[NSCursor resizeUpDownCursor]];
		}
		for (NSTrackingArea *trackingArea in _customTrackingAreas) {
			if (![[self trackingAreas] containsObject:trackingArea]) {
				[self addTrackingArea:trackingArea];
			}
		}
	}
}

- (void)addTrackingRect:(NSRect)rect forCursor:(NSCursor *)cursor {
	[_customTrackingAreas addObject:[[NSTrackingArea alloc] initWithRect:rect
																 options:NSTrackingActiveAlways | NSTrackingCursorUpdate
																   owner:self
																userInfo:nil]];
	[_customTrackingRects addObject:[NSValue valueWithRect:rect]];
	[_customCursors addObject:cursor];
}

@end
