/*
 * StepperTextField.m
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

#import "StepperTextField.h"
#import <AppKit/AppKit.h>

#pragma mark MarginTextFieldCell

IB_DESIGNABLE
@interface MarginTextFieldCell : NSTextFieldCell
@property IBInspectable CGFloat margin;
@property BOOL showsSelection;
@end

@implementation MarginTextFieldCell

@synthesize margin = _margin, showsSelection = _showsSelection;

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.margin = 0;
		self.showsSelection = NO;
	}
	return self;
}

- (NSRect)titleRectForBounds:(NSRect)theRect {

	NSRect titleRect = theRect;

	/* Padding on left side */
	titleRect.origin.x = self.margin;

	/* Padding on right side */
	titleRect.size.width -= (2 * self.margin);

	return titleRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	aRect = [self titleRectForBounds:aRect];
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// Editing padding
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	aRect = [self titleRectForBounds:aRect];
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self titleRectForBounds:cellFrame];
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

// Normal padding
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	//cellFrame = [self titleRectForBounds:cellFrame];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self titleRectForBounds:cellFrame];
	[super highlight:flag withFrame:cellFrame inView:controlView];
}

- (void)setShowsSelection:(BOOL)showsSelection {
	_showsSelection = showsSelection;

	NSTextField *controlView = (NSTextField *)[self controlView];
	NSTextView *fieldEditor = (NSTextView *)[controlView.window fieldEditor:YES forObject:self];

	if (_showsSelection) {
		[controlView performSelector:@selector(selectText:) withObject:controlView afterDelay:0.125];
		//fieldEditor.insertionPointColor = nil;
	} else {
		[self selectWithFrame:controlView.bounds inView:controlView editor:fieldEditor delegate:controlView start:0 length:0];
		//fieldEditor.insertionPointColor = [NSColor clearColor];
	}
}

- (BOOL)showsSelection {
	return _showsSelection;
}

@end

#pragma mark StepperTextField

typedef enum {
	ActivatedButtonNone,
	ActivatedButtonIncrease,
	ActivatedButtonDecrease
} ActivatedButton;

@implementation StepperTextField {
	BOOL _dragging;
	ActivatedButton _activatedButton;
	NSRect _increaseButtonRect;
	NSRect _decreaseButtonRect;
	NSRect _increaseClickableRect;
	NSRect _decreaseClickableRect;
	NSRect _draggableRect;
	NSTrackingArea *_trackingArea;
}

@synthesize
stepperInc = _increment,
increase = _increaseImage,
decrease = _decreaseImage,
alternateInc = _alternateIncreaseImage,
alternateDec = _alternateDecreaseImage,
draggingMult = _sensitivity;

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {

		/* Default values for inspectable properties */
		_increment = 1;
		_increaseImage = [NSImage imageNamed:NSImageNameAddTemplate];
		_decreaseImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
		_alternateIncreaseImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
		_alternateDecreaseImage = [NSImage imageNamed:NSImageNameGoLeftTemplate];
		_sensitivity = 1.0;

		/* Change the cell's class to TextFieldCell */
		NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSKeyedArchiver archivedDataWithRootObject:self.cell]];
		[arch setClass:[MarginTextFieldCell class] forClassName:@"NSTextFieldCell"];
		MarginTextFieldCell *cell = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		[arch finishDecoding];

		self.cell = cell;

		/* Update the cell's margin and buttons' bounds */
		[self updateBounds];
	}
	return self;
}

- (void)updateTrackingAreas {
	/* Add mouse pointer tacking area */
	[super updateTrackingAreas];
	if (_trackingArea == nil) {
		_trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
													 options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseMoved | NSTrackingCursorUpdate
													   owner:self
													userInfo:nil];
	}
	if (![[self trackingAreas] containsObject:_trackingArea]) {
		[self addTrackingArea:_trackingArea];
	}
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	/* Draw the stepper buttons */

	if (_activatedButton == ActivatedButtonIncrease) {
		[_alternateIncreaseImage drawInRect:_increaseButtonRect];
	} else {
		[_increaseImage drawInRect:_increaseButtonRect];
	}

	if (_activatedButton == ActivatedButtonDecrease) {
		[_alternateDecreaseImage drawInRect:_decreaseButtonRect];
	} else {
		[_decreaseImage drawInRect:_decreaseButtonRect];
	}
}

- (void)cursorUpdate:(NSEvent *)event {
	NSPoint locationInView = [self convertPoint:event.locationInWindow fromView:nil];
	[self updateCursorForLocation:locationInView];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	if (theEvent.clickCount == 2 && NSPointInRect(locationInView, _draggableRect)) {
		[self.cell setShowsSelection:YES];
	} else {
		if (NSPointInRect(locationInView, _increaseClickableRect)) {
			[self increaseButtonPressed];
		} else if (NSPointInRect(locationInView, _decreaseClickableRect)) {
			[self decreaseButtonPressed];
		}
		[self.cell setShowsSelection:NO];
	}

	_dragging = NO;
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	[self.window enableCursorRects];
	[self updateCursorForLocation:locationInView];

	/* Reset the stepper buttons to show the normal image */
	_activatedButton = ActivatedButtonNone;
	self.needsDisplay = YES;

	_dragging = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (_activatedButton == ActivatedButtonNone) {

		[[NSCursor resizeLeftRightCursor] set];

		if (!_dragging) {
			[self.window disableCursorRects];
		}
		self.floatValue += _sensitivity * theEvent.deltaX;

		[self updateBindingValue];
	}
	_dragging = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
	[self updateCursorForLocation:locationInView];
	_dragging = NO;
}

- (void)updateCursorForLocation:(NSPoint)location {
	if (NSPointInRect(location, _draggableRect)) {
		if ([self.cell showsSelection]) {
			[[NSCursor IBeamCursor] set];
		} else {
			[[NSCursor resizeLeftRightCursor] set];
		}
	} else {
		[[NSCursor arrowCursor] set];
	}
}

- (void)increaseButtonPressed {
	_activatedButton = ActivatedButtonIncrease;
	self.floatValue += _increment;
	[self updateBindingValue];
}

- (void)decreaseButtonPressed {
	_activatedButton = ActivatedButtonDecrease;
	self.floatValue -= _increment;
	[self updateBindingValue];
}

- (void)updateBindingValue {
	NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];

	NSNumber *value = @(self.floatValue);

	/* Apply the value transformer, if one has been set */
	NSDictionary *bindingOptions = bindingInfo[NSOptionsKey];
	if (bindingOptions) {
		NSValueTransformer *transformer = bindingOptions[NSValueTransformerBindingOption];
		if (transformer && (id)transformer != [NSNull null]) {
			if ([[transformer class] allowsReverseTransformation]) {
				value = [transformer reverseTransformedValue:value];
			} else {
				NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", NSValueBinding, __PRETTY_FUNCTION__);
			}
		}
	}

	[bindingInfo[NSObservedObjectKey] setValue:value forKeyPath:bindingInfo[NSObservedKeyPathKey]];
}

- (void)setFrame:(NSRect)frame {
	[super setFrame:frame];
	[self updateBounds];
}

- (void)updateBounds {
	NSRect bounds = self.bounds;

	/* Calculate the rectangle where to draw the increase button */
	NSRect increaseButtonRect = NSMakeRect(0, 0, _increaseImage.size.width, _increaseImage.size.height);
	CGFloat rightPadding = (NSHeight(bounds) - NSHeight(increaseButtonRect)) / 2;
	increaseButtonRect.origin.x = NSWidth(bounds) - NSWidth(increaseButtonRect) - rightPadding;
	increaseButtonRect.origin.y = rightPadding;
	_increaseButtonRect = increaseButtonRect;

	/* Calculate the rectangle where to draw the decrease button */
	NSRect decreaseButtonRect = NSMakeRect(0, 0, _decreaseImage.size.width, _decreaseImage.size.height);
	CGFloat leftPadding = (NSHeight(bounds) - NSHeight(decreaseButtonRect)) / 2;
	decreaseButtonRect.origin.x = leftPadding;
	decreaseButtonRect.origin.y = leftPadding;
	_decreaseButtonRect = decreaseButtonRect;

	/* Calculate the rectangle where to change the pointer for dragging the value */
	_draggableRect = bounds;
	leftPadding = (NSMinX(_decreaseButtonRect) - NSMinX(bounds)) + NSWidth(_decreaseButtonRect);
	_draggableRect.origin.x += leftPadding;
	rightPadding = (NSMaxX(bounds) - NSMaxX(_increaseButtonRect)) + NSWidth(_increaseButtonRect);
	_draggableRect.size.width -= leftPadding + rightPadding;

	/* calculate the are where the increase and decrease buttons are activated */
	_increaseClickableRect = NSMakeRect(NSMaxX(_draggableRect), NSMinY(bounds), NSMaxX(bounds)-NSMaxX(_draggableRect), NSHeight(bounds));
	_decreaseClickableRect = NSMakeRect(0, 0, NSMinX(_draggableRect), NSHeight(bounds));

	if ([self.cell isKindOfClass:[MarginTextFieldCell class]]) {
		/* Desired margin */
		CGFloat margin = (NSWidth(_increaseClickableRect) + NSWidth(_decreaseClickableRect)) / 2;

		/* Compensate for intrinsic margin of the cell */
		margin -= (NSWidth(bounds) - NSWidth([self.cell drawingRectForBounds:bounds])) / 2;
		[self.cell setMargin:margin];
	}
}

- (NSView *)hitTest:(NSPoint)aPoint {
	if (!self.isEnabled)
		return nil;
	NSView *result = [super hitTest:aPoint];
	if (result && ![self.cell showsSelection])
		result = self;
	return result;
}

@end
