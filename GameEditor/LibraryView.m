/*
 * LibraryView.m
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

#import "LibraryView.h"

#pragma mark VerticallyCenteredTextField

@interface VerticallyCenteredTextFieldCell : NSTextFieldCell
@end

@implementation VerticallyCenteredTextFieldCell

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSAttributedString *attrString = self.attributedStringValue;

	/* if your values can be attributed strings, make them white when selected */
	if (self.isHighlighted && self.backgroundStyle==NSBackgroundStyleDark) {
		NSMutableAttributedString *whiteString = attrString.mutableCopy;
		[whiteString addAttribute: NSForegroundColorAttributeName
							value: [NSColor whiteColor]
							range: NSMakeRange(0, whiteString.length) ];
		attrString = whiteString;
	}

	[attrString drawWithRect: [self titleRectForBounds:cellFrame]
					 options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];
}

- (NSRect)titleRectForBounds:(NSRect)theRect {
	/* get the standard text content rectangle */
	NSRect titleFrame = [super titleRectForBounds:theRect];

	/* find out how big the rendered text will be */
	NSAttributedString *attrString = self.attributedStringValue;
	NSRect textRect = [attrString boundingRectWithSize: titleFrame.size
											   options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin ];

	/* If the height of the rendered text is less then the available height,
	 * we modify the titleRect to center the text vertically */
	if (textRect.size.height < titleFrame.size.height) {
		titleFrame.origin.y = theRect.origin.y + (theRect.size.height - textRect.size.height) / 2.0;
		titleFrame.size.height = textRect.size.height;
	}
	return titleFrame;
}

@end

#pragma mark - LibraryPanelView

IB_DESIGNABLE
@interface LibraryPanelView : NSView
@property (assign) IBInspectable BOOL topBorder;
@property (assign) IBInspectable BOOL bottomBorder;
@property (assign) IBInspectable BOOL draggable;
@end

@implementation LibraryPanelView {
	NSMutableArray *_customTrackingAreas;
	NSMutableArray *_customCursors;
	NSMutableArray *_customTrackingRects;
	NSPoint _draggingPoint;
	BOOL _dragging;
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect rect = [self bounds];
	[[NSColor whiteColor] set];
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

#pragma mark - LibraryItem

@interface LibraryView () <NSCollectionViewDelegate>
- (CGSize)itemSize;
@end

@interface LibraryItemView : NSBox
@property (weak) LibraryView *libraryView;
@end

@implementation LibraryItemView

- (void)drawRect:(NSRect)dirtyRect {
	CGSize size = self.libraryView.itemSize;

	NSBezierPath *borderPath = [NSBezierPath bezierPath];
	if (self.libraryView.mode == LibraryViewModeIcons) {
		[borderPath moveToPoint:CGPointMake(0.5, 0.5)];
		[borderPath lineToPoint:CGPointMake(size.width - 0.5, 0.5)];
		[borderPath lineToPoint:CGPointMake(size.width - 0.5, size.height + 0.5)];
	} else {
		[borderPath moveToPoint:CGPointMake(3.0, 0.5)];
		[borderPath lineToPoint:CGPointMake(size.width - 4.0, 0.5)];
	}

	[[NSColor gridColor] set];
	[borderPath stroke];

	if (!self.transparent) {
		CGRect rect;
		CGFloat border;
		if (self.libraryView.mode == LibraryViewModeIcons) {
			border = 2.0;
		} else {
			border = 1.0;
		}

		rect.origin = CGPointMake(border, border + 1.0);
		rect.size = CGSizeMake(size.width - 2.0 * border - 1.0, size.height - 2.0 * border - 1.0);

		NSBezierPath *selectionPath = [NSBezierPath bezierPath];
		if (self.libraryView.mode == LibraryViewModeIcons) {
			[selectionPath moveToPoint:CGPointMake(NSMinX(rect) - 0.5, NSMinY(rect) - 0.5)];
			[selectionPath lineToPoint:CGPointMake(NSMaxX(rect) + 0.5, NSMinY(rect) - 0.5)];
			[selectionPath lineToPoint:CGPointMake(NSMaxX(rect) + 0.5, NSMaxY(rect) + 0.5)];
			[selectionPath lineToPoint:CGPointMake(NSMinX(rect) - 0.5, NSMaxY(rect) + 0.5)];
			[selectionPath closePath];
		} else {
			[selectionPath moveToPoint:CGPointMake(-1.0, NSMinY(rect) - 0.5)];
			[selectionPath lineToPoint:CGPointMake(size.width + 1.0, NSMinY(rect) - 0.5)];
			[selectionPath lineToPoint:CGPointMake(size.width + 1.0, NSMaxY(rect) + 0.5)];
			[selectionPath lineToPoint:CGPointMake(-1.0, NSMaxY(rect) + 0.5)];
			[selectionPath closePath];
		}

		if (self.libraryView.firstResponder) {
			[[NSColor alternateSelectedControlColor] setStroke];
			[[NSColor selectedControlColor] setFill];
		} else {
			[[NSColor gridColor] setStroke];
			[[NSColor controlColor] setFill];
		}

		[selectionPath fill];
		[selectionPath stroke];
	}
}

@end

#pragma mark - LibraryView

@implementation LibraryView {
	__weak id _actualDelegate;
	CGSize _itemSize;
	BOOL _firstResponder;
}

@synthesize mode = _mode;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)setFrame:(NSRect)frame {
	CGFloat width = self.superview.frame.size.width;
	if (_mode == LibraryViewModeIcons) {
		self.maxNumberOfRows = 0;
		self.maxNumberOfColumns = 0;
		width -= 1.0;
		width = width / (int)(width / 64.0);
	} else {
		self.maxNumberOfRows = 0;
		self.maxNumberOfColumns = 1;
	}
	_itemSize = CGSizeMake(width, 64);
	self.minItemSize = self.maxItemSize = _itemSize;
}

- (CGSize)itemSize {
	return _itemSize;
}

- (void)setMode:(LibraryViewMode)mode {
	_mode = mode;

	NSUInteger numberOfItems = [[self content] count];
	for (NSUInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
		NSCollectionViewItem *item = [self itemAtIndex:itemIndex];
		[item.representedObject setValue:@(mode == LibraryViewModeList) forKey:@"showLabel"];
	}

	/* Force re-layout of subviews */
	self.frame = self.frame;
}

- (LibraryViewMode)mode {
	return _mode;
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
	NSCollectionViewItem *item = [super newItemForRepresentedObject:object];
	LibraryItemView *itemView = (LibraryItemView *)item.view;
	itemView.libraryView = self;
	return item;
}

/*
 Overriding isFirstResponder and keeping track of wheter the view has become
 first responder or not seems to work better, otherwise the collection view's
 selection is not grayed out properly when it resigns first responder
 */

- (BOOL)isFirstResponder {
	return _firstResponder;
}

- (BOOL)becomeFirstResponder {
	_firstResponder = YES;
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)resignFirstResponder {
	_firstResponder = NO;
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)mouseDown:(NSEvent *)event {
	if (_actualDelegate && [_actualDelegate respondsToSelector:@selector(libraryView:didSelectItemAtIndex:)]) {
		CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
		for (NSInteger index = 0; index < self.subviews.count; ++index) {
			LibraryItemView *libraryView = self.subviews[index];
			if (CGRectContainsPoint(libraryView.frame, point)) {
				[_actualDelegate libraryView:self didSelectItemAtIndex:index];
				break;
			}
		}
	}
	[super mouseDown:event];
}

#pragma mark Drag & Drop

- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
	id itemInfo = [[collectionView itemAtIndex:indexes.firstIndex] representedObject];
	return [itemInfo valueForKey:@"image"];
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSData *pboardData = [NSKeyedArchiver archivedDataWithRootObject:@(indexes.firstIndex)];
	[pasteboard setData:pboardData forType:@"public.binary"];
	return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {
	return YES;
}

#pragma mark Delegate methods interception

- (void)setDelegate:(id)newDelegate {
	[super setDelegate:nil];
	_actualDelegate = newDelegate;
	[super setDelegate:self];
}

- (id)delegate {
	return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
	if ([_actualDelegate respondsToSelector:aSelector]) { return _actualDelegate; }
	return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [super respondsToSelector:aSelector] || [_actualDelegate respondsToSelector:aSelector];
}

@end
