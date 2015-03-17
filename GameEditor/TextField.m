//
//  TextField.m
//  GameEditor
//

#import "TextField.h"
#import <AppKit/AppKit.h>

@implementation TextField {
	CGFloat _lastPosition;
	NSButton *_increaseButton;
	NSButton *_decreaseButton;
}

@synthesize degrees = _degrees;

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
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
    [super drawRect:dirtyRect];
    
    // Drawing code here.
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
