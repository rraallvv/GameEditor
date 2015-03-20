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
	NSTextView *fieldEditor = (NSTextView*)[controlView.window fieldEditor:YES forObject:self];

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

typedef enum {
	ActivatedButtonNone,
	ActivatedButtonIncrease,
	ActivatedButtonDecrease
} ActivatedButton;

@implementation StepperTextField {
	NSPoint _lastMousePosition;
	BOOL _dragging;
	ActivatedButton _activatedButton;
	NSRect _increaseButtonRect;
	NSRect _decreaseButtonRect;
	NSRect _increaseClickableRect;
	NSRect _decreaseClickableRect;
	NSRect _draggableRect;
}

@synthesize
increase = _increaseImage,
decrease = _decreaseImage,
alternateInc = _alternateIncreaseImage,
alternateDec = _alternateDecreaseImage;

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {

		/* Default values for inspectable peoperties*/
		_increment = 1;
		_increaseImage = [NSImage imageNamed:NSImageNameAddTemplate];
		_decreaseImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
		_alternateIncreaseImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
		_alternateDecreaseImage = [NSImage imageNamed:NSImageNameGoLeftTemplate];
		_draggingMult = 1.0;

		/* Calculate the stepper button's rect */
		[self resizeSubviewsWithOldSize:NSZeroSize];

		/* Change the cell's class to TextFieldCell */
		NSTextField *oldCell = self.cell;

		NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSKeyedArchiver archivedDataWithRootObject:oldCell]];
		[arch setClass:[MarginTextFieldCell class] forClassName:@"NSTextFieldCell"];
		MarginTextFieldCell *cell = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		[arch finishDecoding];

		self.cell = cell;

		/* Add mouse pointer tacking area */
		NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways|NSTrackingMouseMoved owner:self userInfo:nil];
		[self addTrackingArea:area];
	}
	return self;
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
	_lastMousePosition = locationInView;
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	if (NSPointInRect(locationInView, _draggableRect)) {
		if ([self.cell showsSelection]) {
			//[[NSCursor IBeamCursor] set];
		} else {
			//[[NSCursor resizeLeftRightCursor] set];
		}
	} else {
		//[[NSCursor arrowCursor] set];
	}

	_activatedButton = ActivatedButtonNone;

	/* Reset the stepper buttons to show the normal image */
	self.needsDisplay = YES;

	_dragging = NO;
	_lastMousePosition = locationInView;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	if (_activatedButton == ActivatedButtonNone) {

		//if (!_dragging)
		//	[self.cell setShowsSelection:NO];

		//[[NSCursor resizeLeftRightCursor] set];

		CGFloat delta = locationInView.x - _lastMousePosition.x;
		self.floatValue += self.draggingMult * delta;

		[self updateBindingValue];
	}

	_dragging = YES;
	_lastMousePosition = locationInView;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	if (![self.cell showsSelection] && NSPointInRect(locationInView, _draggableRect)) {
		//[[NSCursor resizeLeftRightCursor] set];
	}

	_dragging = NO;
	_lastMousePosition = locationInView;
}

- (void)increaseButtonPressed {
	_activatedButton = ActivatedButtonIncrease;
	self.floatValue += self.increment;
	[self updateBindingValue];
}

- (void)decreaseButtonPressed {
	_activatedButton = ActivatedButtonDecrease;
	self.floatValue -= self.increment;
	[self updateBindingValue];
}

- (void)updateBindingValue {
	NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];

	NSNumber *value = @(self.floatValue);

	/* Apply the value transformer, if one has been set */
	NSDictionary* bindingOptions = bindingInfo[NSOptionsKey];
	if(bindingOptions){
		NSValueTransformer* transformer = bindingOptions[NSValueTransformerBindingOption];
		if(transformer && (id)transformer != [NSNull null]){
			if([[transformer class] allowsReverseTransformation]){
				value = [transformer reverseTransformedValue:value];
			} else {
				NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", NSValueBinding, __PRETTY_FUNCTION__);
			}
		}
	}

	[bindingInfo[NSObservedObjectKey] setValue:value forKeyPath:bindingInfo[NSObservedKeyPathKey]];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	/* Calulate the rectangle where to draw the increase button */
	NSRect increaseButtonRect = NSMakeRect(0, 0, _increaseImage.size.width, _increaseImage.size.height);
	CGFloat rightPadding = (NSHeight(self.bounds) - NSHeight(increaseButtonRect)) / 2;
	increaseButtonRect.origin.x = NSWidth(self.bounds) - NSWidth(increaseButtonRect) - rightPadding;
	increaseButtonRect.origin.y = rightPadding;
	_increaseButtonRect = increaseButtonRect;

	/* Calulate the rectangle where to draw the decrease button */
	NSRect decreaseButtonRect = NSMakeRect(0, 0, _decreaseImage.size.width, _decreaseImage.size.height);
	CGFloat leftPadding = (NSHeight(self.bounds) - NSHeight(decreaseButtonRect)) / 2;
	decreaseButtonRect.origin.x = leftPadding;
	decreaseButtonRect.origin.y = leftPadding;
	_decreaseButtonRect = decreaseButtonRect;

	/* Calculate the recangle where to change the pointer for dragging the value */
	_draggableRect = self.bounds;
	leftPadding = (NSMinX(_decreaseButtonRect) - NSMinX(self.bounds)) + NSWidth(_decreaseButtonRect);
	_draggableRect.origin.x += leftPadding;
	rightPadding = (NSMaxX(self.bounds) - NSMaxX(_increaseButtonRect)) + NSWidth(_increaseButtonRect);
	_draggableRect.size.width -= leftPadding + rightPadding;

	/* calculate the are where the increase and decrease buttons are activated */
	_increaseClickableRect = NSMakeRect(NSMaxX(_draggableRect), NSMinY(self.bounds), NSMaxX(self.bounds)-NSMaxX(_draggableRect), NSHeight(self.bounds));
	_decreaseClickableRect = NSMakeRect(0, 0, NSMinX(_draggableRect), NSHeight(self.bounds));

	if ([self.cell isKindOfClass:[MarginTextFieldCell class]]) {
		/* Desired margin */
		CGFloat margin = (NSWidth(_increaseClickableRect) + NSWidth(_decreaseClickableRect)) / 2;

		/* Compensate for intrinsic margin of the cell */
		margin -= (self.bounds.size.width - [self.cell drawingRectForBounds:self.bounds].size.width) / 2;
		[self.cell setMargin:margin];
	}
}

- (NSView *)hitTest:(NSPoint)aPoint {
	NSView *result = [super hitTest:aPoint];
	if (result && ![self.cell showsSelection])
		result = self;
	return result;
}

@end
