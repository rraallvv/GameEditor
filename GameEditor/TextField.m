//
//  TextField.m
//  GameEditor
//

#import "TextField.h"
#import <AppKit/AppKit.h>

#define PADDING_MARGIN 20

@interface TextFieldCell : NSTextFieldCell
@end

@implementation TextFieldCell

//Function will create rect for title
//Any padding implemented in this function will be visible in title of textfieldcell

- (NSRect)titleRectForBounds:(NSRect)theRect {

	NSRect titleRect = [super titleRectForBounds:theRect];

	//Padding on left side
	titleRect.origin.x = PADDING_MARGIN;

	//Padding on right side
	titleRect.size.width -= (2 * PADDING_MARGIN);

	//Vertically center the title
	NSAttributedString *attrString = self.attributedStringValue;

	NSRect textRect = [attrString boundingRectWithSize: titleRect.size options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin ];
	if (textRect.size.height < titleRect.size.height) {
		titleRect.origin.y = theRect.origin.y + (theRect.size.height - textRect.size.height) / 2.0;
		titleRect.size.height = textRect.size.height;
	}

	return titleRect;
}

//Any padding implemented in this function will be visible while editing text in textfieldcell
//If Padding is not done here, padding done for title will not be visible while editing

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	NSRect titleRect = [self titleRectForBounds:aRect];
	[super editWithFrame: titleRect inView: controlView editor:textObj delegate:anObject event: theEvent];
}

//Any padding implemented in this function will be visible while selecting text in textfieldcell
//If Padding is not done here, padding done for title will not be visible while selecting text

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	NSRect titleRect = [self titleRectForBounds:aRect];
	[super selectWithFrame: titleRect inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
	NSRect titleRect = [self titleRectForBounds:cellFrame];
	[[self attributedStringValue] drawInRect:titleRect];
}

@end


@implementation TextField {
	CGFloat _lastPosition;
	NSButton *_increaseButton;
	NSButton *_decreaseButton;
}

@synthesize degrees = _degrees;


+ (void)load {
	[self setCellClass:[TextFieldCell class]];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {

#if 1
		TextFieldCell *cell = [[TextFieldCell alloc] init];
		cell.selectable = YES;
		cell.scrollable = YES;
		cell.editable = YES;
		cell.drawsBackground = NO;
		cell.alignment = NSCenterTextAlignment;
		[self setCell:cell];
#endif

		self.degrees = NO;

		self.alignment = NSCenterTextAlignment;
		self.drawsBackground = NO;

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
	}
	return self;
}

- (NSRect)calculateButonRectWithImage:(NSImage *)image {
	NSSize buttonSize = image.size;
	return NSMakeRect(0, 0, buttonSize.width, buttonSize.height);
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect blackOutlineFrame = NSMakeRect(0.0, 0.0, [self bounds].size.width, [self bounds].size.height-1.0);
	NSGradient *gradient = nil;
	if ([NSApp isActive]) {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.24 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.374 alpha:1.0]];
	}
	else {
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.558 alpha:1.0]];
	}

	[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:blackOutlineFrame xRadius:10 yRadius:10] angle:90];

	[super drawRect:dirtyRect];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
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
	self.floatValue += 1;
	[self updateBindingValue];
}

- (void)decreaseButtonPressed {
	self.floatValue -= 1;
	[self updateBindingValue];
}

- (void)updateBindingValue {
	NSNumber *value = self.degrees ? @(self.floatValue*M_PI/180) : @(self.floatValue);
	NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];
	[bindingInfo[NSObservedObjectKey] setValue:value
									forKeyPath:bindingInfo[NSObservedKeyPathKey]];
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

- (void)setDegrees:(BOOL)degrees {
	if (degrees) {
		self.formatter = [[NSNumberFormatter alloc] init];
		//[self.formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[self.formatter setPositiveFormat:@"#.##º"];
		[self.formatter setNegativeFormat:@"#.##º"];
	} else {
		self.formatter = [[NSNumberFormatter alloc] init];
		[self.formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	}
	_degrees = degrees;
}

- (BOOL)degrees {
	return _degrees;
}

@end
