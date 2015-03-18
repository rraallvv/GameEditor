//
//  TextField.m
//  GameEditor
//

#import "TextField.h"
#import <AppKit/AppKit.h>

IB_DESIGNABLE
@interface TextFieldCell : NSTextFieldCell
@property (nonatomic) IBInspectable CGFloat margin;
@end

@implementation TextFieldCell

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.margin = 0;
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
#if 0
	//Vertically center the title
	NSRect textRect = [[self attributedStringValue] boundingRectWithSize: titleRect.size options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin ];
	if (textRect.size.height < titleRect.size.height) {
		titleRect.origin.y = titleRect.origin.y + (titleRect.size.height - textRect.size.height) / 2.0;
		titleRect.size.height = textRect.size.height;
	}
#endif
	return titleRect;
}

//Any padding implemented in this function will be visible while editing text in textfieldcell
//If Padding is not done here, padding done for title will not be visible while editing
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
	//cellFrame= [self titleRectForBounds:cellFrame];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self titleRectForBounds:cellFrame];
	[super highlight:flag withFrame:cellFrame inView:controlView];
}

@end


@implementation TextField {
	CGFloat _lastPosition;
	NSRect _increaseButtonRect;
	NSRect _decreaseButtonRect;
	int _active;
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

	if (_active == 1) {
		[_alternateIncreaseImage drawInRect:_increaseButtonRect];
	} else {
		[_increaseImage drawInRect:_increaseButtonRect];
	}

	if (_active == 2) {
		[_alternateDecreaseImage drawInRect:_decreaseButtonRect];
	} else {
		[_decreaseImage drawInRect:_decreaseButtonRect];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	if (NSPointInRect(locationInView, _increaseButtonRect)) {
		[self increaseButtonPressed];
	} else if (NSPointInRect(locationInView, _decreaseButtonRect)) {
		[self decreaseButtonPressed];
	}
	return;

	if (theEvent.clickCount == 2) {
		[self selectText:self];
	}
	[self setHighlighted:YES];
	[self selectText:nil];

	id app = [[NSApplication sharedApplication] delegate];
	[[app window] makeFirstResponder:self];

	_lastPosition = theEvent.locationInWindow.x;
}

- (void)mouseUp:(NSEvent *)theEvent {
	_active = 0;
	self.needsDisplay = YES;
	return;
	[[NSCursor arrowCursor] set];
	_lastPosition = theEvent.locationInWindow.x;
}

/*
- (void)mouseDragged:(NSEvent *)theEvent {

	NSColor *insertionPointColor = [NSColor clearColor];
	NSTextView *fieldEditor = (NSTextView*)[self.window fieldEditor:YES forObject:self];
	fieldEditor.insertionPointColor = insertionPointColor;

	[[NSCursor resizeLeftRightCursor] set];

	CGFloat position = theEvent.locationInWindow.x;
	CGFloat delta = position - _lastPosition;
	self.floatValue += delta;
	_lastPosition = position;
}


- (void)resetCursorRects {
	if (self.isEditable)
		[self addCursorRect:[self bounds] cursor:[NSCursor IBeamCursor]];
	else
		[self addCursorRect:[self bounds] cursor:[NSCursor resizeLeftRightCursor]];
}
*/

- (void)increaseButtonPressed {
	_active = 1;
	self.floatValue += self.increment;
	[self updateBindingValue];
}

- (void)decreaseButtonPressed {
	_active = 2;
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
	NSRect increaseButtonRect = [self calculateButonRectWithImage:_increaseImage];
	increaseButtonRect.origin.x = self.frame.size.width - increaseButtonRect.size.width - (self.frame.size.height - increaseButtonRect.size.height)/2;
	increaseButtonRect.origin.y = (self.frame.size.height - increaseButtonRect.size.height)/2;
	_increaseButtonRect = increaseButtonRect;

	NSRect decreaseButtonRect = [self calculateButonRectWithImage:_decreaseImage];
	decreaseButtonRect.origin.x = (self.frame.size.height - increaseButtonRect.size.height)/2;
	decreaseButtonRect.origin.y = (self.frame.size.height - decreaseButtonRect.size.height)/2;
	_decreaseButtonRect = decreaseButtonRect;
}

@end
