//
//  TextField.m
//  GameEditor
//

#import "TextField.h"
#import <AppKit/AppKit.h>

IB_DESIGNABLE
@interface TextFieldCell : NSTextFieldCell
@property IBInspectable CGFloat margin;
@property BOOL showsSelection;
@end

@implementation TextFieldCell

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.margin = 0;
		self.showsSelection = NO;
	}
	return self;
}

//Function will create rect for title
//Any padding implemented in this function will be visible in title of textfieldcell
- (NSRect)titleRectForBounds:(NSRect)theRect {

	NSRect titleRect = theRect;

	//Padding on left side
	titleRect.origin.x = self.margin;

	//Padding on right side
	titleRect.size.width -= (2 * self.margin);

	return titleRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	aRect = [self titleRectForBounds:aRect];
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// Editing padding
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	if (!self.showsSelection)
		return;
	aRect = [self titleRectForBounds:aRect];
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self titleRectForBounds:cellFrame];
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

// Normal padding
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	//cellFrame= [self titleRectForBounds:cellFrame];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self titleRectForBounds:cellFrame];
	[super highlight:flag withFrame:cellFrame inView:controlView];
}

@end

typedef enum {
	ActivatedButtonNone,
	ActivatedButtonIncrease,
	ActivatedButtonDecrease
} ActivatedButton;

@implementation TextField {
	CGFloat _lastPosition;
	ActivatedButton _activatedButton;
	NSRect _increaseButtonRect;
	NSRect _decreaseButtonRect;
	NSRect _increaseClickableRect;
	NSRect _decreaseClickableRect;
	NSRect _draggableBounds;
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
		[arch setClass:[TextFieldCell class] forClassName:@"NSTextFieldCell"];
		TextFieldCell *cell = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		[arch finishDecoding];

		self.cell = cell;

		/* Fix the margin for the rounded rect button */
		CGFloat defaultMargin = (self.bounds.size.width - [cell drawingRectForBounds:self.bounds].size.width) / 2.0;
		cell.margin = NSMaxX(_decreaseButtonRect) + NSMinX(_decreaseButtonRect) - defaultMargin;
	}
	return self;
}

- (NSRect)calculateButonRectWithImage:(NSImage *)image {
	NSSize buttonSize = image.size;
	return NSMakeRect(0, 0, buttonSize.width, buttonSize.height);
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

	if (NSPointInRect(locationInView, _increaseClickableRect)) {
		[self increaseButtonPressed];
	} else if (NSPointInRect(locationInView, _decreaseClickableRect)) {
		[self decreaseButtonPressed];
	} else if (theEvent.clickCount == 2) {
		[self selectText:self];
	}

	_lastPosition = theEvent.locationInWindow.x;
}

- (void)mouseUp:(NSEvent *)theEvent {
	_activatedButton = ActivatedButtonNone;

	/* show the normal image for the stepper button */
	self.needsDisplay = YES;

	[self.window invalidateCursorRectsForView:self];

	_lastPosition = theEvent.locationInWindow.x;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	CGFloat position = theEvent.locationInWindow.x;

	if (_activatedButton == ActivatedButtonNone) {
		NSColor *insertionPointColor = [NSColor clearColor];
		NSTextView *fieldEditor = (NSTextView*)[self.window fieldEditor:YES forObject:self];
		fieldEditor.insertionPointColor = insertionPointColor;

		[[NSCursor resizeLeftRightCursor] set];

		CGFloat delta = position - _lastPosition;
		self.floatValue += self.draggingMult * delta;

		[self updateBindingValue];
	}

	_lastPosition = position;
}

- (void)resetCursorRects {
	if ([self.cell showsSelection])
		[self addCursorRect:[self bounds] cursor:[NSCursor IBeamCursor]];
	else {
		[self addCursorRect:_draggableBounds cursor:[NSCursor resizeLeftRightCursor]];
	}
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
	// calulate the rectangle where to draw the increase button
	NSRect increaseButtonRect = [self calculateButonRectWithImage:_increaseImage];
	CGFloat rightPadding = (NSHeight(self.bounds) - NSHeight(increaseButtonRect)) / 2;
	increaseButtonRect.origin.x = NSWidth(self.bounds) - NSWidth(increaseButtonRect) - rightPadding;
	increaseButtonRect.origin.y = rightPadding;
	_increaseButtonRect = increaseButtonRect;

	// calulate the rectangle where to draw the decrease button
	NSRect decreaseButtonRect = [self calculateButonRectWithImage:_decreaseImage];
	CGFloat leftPadding = (NSHeight(self.bounds) - NSHeight(decreaseButtonRect)) / 2;
	decreaseButtonRect.origin.x = leftPadding;
	decreaseButtonRect.origin.y = leftPadding;
	_decreaseButtonRect = decreaseButtonRect;

	// calculate the recangle where to change the pointer for dragging the value
	_draggableBounds = self.bounds;
	leftPadding = 1.5 * (NSMinX(_decreaseButtonRect) - NSMinX(self.bounds)) + NSWidth(_decreaseButtonRect);
	_draggableBounds.origin.x += leftPadding;
	rightPadding = 1.5 * (NSMaxX(self.bounds) - NSMaxX(_increaseButtonRect)) + NSWidth(_increaseButtonRect);
	_draggableBounds.size.width -= leftPadding + rightPadding;

	// calculate the are where the increase and decrease buttons are activated
	_increaseClickableRect = NSMakeRect(NSMaxX(_draggableBounds), NSMinY(self.bounds), NSMaxX(self.bounds)-NSMaxX(_draggableBounds), NSHeight(self.bounds));
	_decreaseClickableRect = NSMakeRect(0, 0, NSMinX(_draggableBounds), NSHeight(self.bounds));
}

@end
