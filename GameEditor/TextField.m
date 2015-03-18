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
	NSButton *_increaseButton;
	NSButton *_decreaseButton;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {

		/* Add the increase button for the stepper */

		self.increment = 1;

		NSImage *increaseButtonImage = [NSImage imageNamed:NSImageNameAddTemplate];
		NSRect increaseButtonRect = [self calculateButonRectWithImage:increaseButtonImage];
		increaseButtonRect.origin.x = self.frame.size.width - increaseButtonRect.size.width - (self.frame.size.height - increaseButtonRect.size.height)/2;
		increaseButtonRect.origin.y = (self.frame.size.height - increaseButtonRect.size.height)/2;

		_increaseButton = [[NSButton alloc] initWithFrame:increaseButtonRect];
		_increaseButton.title = nil;
		_increaseButton.buttonType = NSMomentaryLightButton;
		_increaseButton.bezelStyle = NSRoundedBezelStyle;
		_increaseButton.imagePosition = NSImageOnly;
		_increaseButton.bordered = NO;
		_increaseButton.image = increaseButtonImage;
		_increaseButton.target = self;
		_increaseButton.action = @selector(increaseButtonPressed);
		[self addSubview: _increaseButton];

		/* Add the decrease button for the stepper */

		NSImage *decreseButtonImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
		NSRect decreaseButtonRect = [self calculateButonRectWithImage:decreseButtonImage];
		decreaseButtonRect.origin.x = (self.frame.size.height - increaseButtonRect.size.height)/2;
		decreaseButtonRect.origin.y = (self.frame.size.height - decreaseButtonRect.size.height)/2;

		_decreaseButton = [[NSButton alloc] initWithFrame:decreaseButtonRect];
		_decreaseButton.title = nil;
		_decreaseButton.buttonType = NSMomentaryLightButton;
		_decreaseButton.bezelStyle = NSRoundedBezelStyle;
		_decreaseButton.imagePosition = NSImageOnly;
		_decreaseButton.bordered = NO;
		_decreaseButton.image = decreseButtonImage;
		_decreaseButton.target = self;
		_decreaseButton.action = @selector(decreaseButtonPressed);
		[self addSubview: _decreaseButton];

		/* Change the class of the cell to TextFieldCell */

		NSTextField *oldCell = self.cell;

		NSKeyedUnarchiver *arch = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSKeyedArchiver archivedDataWithRootObject:oldCell]];
		[arch setClass:[TextFieldCell class] forClassName:@"NSTextFieldCell"];
		TextFieldCell *cell = [arch decodeObjectForKey:NSKeyedArchiveRootObjectKey];
		[arch finishDecoding];

		CGFloat defaultMargin = (self.bounds.size.width - [cell drawingRectForBounds:self.bounds].size.width) / 2.0;
		cell.margin = NSMaxX(decreaseButtonRect) + NSMinX(decreaseButtonRect) - defaultMargin;

		self.cell = cell;

		cell.drawsBackground = NO;
		self.drawsBackground = NO;
	}
	return self;
}

- (NSRect)calculateButonRectWithImage:(NSImage *)image {
	NSSize buttonSize = image.size;
	return NSMakeRect(0, 0, buttonSize.width, buttonSize.height);
}

- (void)drawRect:(NSRect)dirtyRect {
	/*
	NSRect blackOutlineFrame = NSMakeRect(0.0, 0.0, [self bounds].size.width, [self bounds].size.height-1.0);
	NSGradient *gradient = nil;
	if ([NSApp isActive]) {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.24 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.374 alpha:1.0]];
	}
	else {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]];
	}

	CGFloat radius = MIN([self bounds].size.height/2, 10);

	[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:radius yRadius:radius] angle:90];
	 */
	[super drawRect:dirtyRect];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];

	NSWindow *window = [[NSApplication sharedApplication] windows].firstObject;
	[window makeFirstResponder:self];

	if (NSPointInRect(locationInView, _increaseButton.frame)) {
		[_increaseButton mouseDown:theEvent];
	}
	if (NSPointInRect(locationInView, _decreaseButton.frame)) {
		[_decreaseButton mouseDown:theEvent];
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

- (void)mouseUp:(NSEvent *)theEvent {
	[[NSCursor arrowCursor] set];
	_lastPosition = theEvent.locationInWindow.x;
}

- (void)resetCursorRects {
	if (self.isEditable)
		[self addCursorRect:[self bounds] cursor:[NSCursor IBeamCursor]];
	else
		[self addCursorRect:[self bounds] cursor:[NSCursor resizeLeftRightCursor]];
}
*/

- (NSView *)hitTest:(NSPoint)aPoint {
	if (NSPointInRect(aPoint, _increaseButton.frame))
		return _increaseButton;
	if (NSPointInRect(aPoint, _decreaseButton.frame))
		return _decreaseButton;
	else if (NSPointInRect(aPoint, self.frame))
		return self;
	return nil;
}

- (void)increaseButtonPressed {
	self.floatValue += self.increment;
	[self updateBindingValue];
}

- (void)decreaseButtonPressed {
	self.floatValue -= self.increment;
	[self updateBindingValue];
}

- (void)updateBindingValue {
	NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];

	NSNumber *value = @(self.floatValue);

	//apply the value transformer, if one has been set
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
	NSImage *increaseButtonImage = [NSImage imageNamed:NSImageNameAddTemplate];
	NSRect increaseButtonRect = [self calculateButonRectWithImage:increaseButtonImage];
	increaseButtonRect.origin.x = self.frame.size.width - increaseButtonRect.size.width - (self.frame.size.height - increaseButtonRect.size.height)/2;
	increaseButtonRect.origin.y = (self.frame.size.height - increaseButtonRect.size.height)/2;
	[_increaseButton setFrame:increaseButtonRect];

	NSImage *decreseButtonImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
	NSRect decreaseButtonRect = [self calculateButonRectWithImage:decreseButtonImage];
	decreaseButtonRect.origin.x = (self.frame.size.height - increaseButtonRect.size.height)/2;
	decreaseButtonRect.origin.y = (self.frame.size.height - decreaseButtonRect.size.height)/2;
	[_decreaseButton setFrame:decreaseButtonRect];
}

@end
