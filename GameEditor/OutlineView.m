/*
 * OutlineView.m
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

#import "OutlineView.h"

@interface TableRowView : NSTableRowView
@end

@implementation TableRowView {
	NSAttributedString *_showAttributedString;
	NSAttributedString *_hideAttributedString;
	NSAttributedString *_showAlternateAttributedString;
	NSAttributedString *_hideAlternateAttributedString;
	NSButton *_hideGroupButton;
	NSTrackingArea *_trackingArea;
}
- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	[self.backgroundColor set];
	NSRectFill(dirtyRect);

	OutlineView *outlineView = (OutlineView *)[self superview];

	NSInteger row = [outlineView rowForView:self];
	
	[[NSColor lightGrayColor] set];

	if (self.isGroupRowStyle && row > 0) {
		NSRectFill(NSMakeRect(0, 0, NSWidth(dirtyRect), 1));
	}

	if (row == [outlineView numberOfRows] - 1) {
		NSRectFill(NSMakeRect(0, NSMaxY(dirtyRect) - 1, NSWidth(dirtyRect), 1));
	}
}
- (void)setFrame:(NSRect)frame {
	[super setFrame:frame];
	if (self.isGroupRowStyle) {
		if (!_hideGroupButton) {

			NSBundle *bundle = [NSBundle bundleForClass:[NSApplication class]];

			NSColor *color = [NSColor colorForControlTint:NSGraphiteControlTint];
			NSDictionary *attributes = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]],
										 NSForegroundColorAttributeName: color};

			NSColor *alternateColor = [NSColor colorForControlTint:NSBlueControlTint];
			NSDictionary *alternateAttributes = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]],
										 NSForegroundColorAttributeName: alternateColor};

			NSString *showString = @"Show";
			NSString *showLocalizedString = bundle ? [bundle localizedStringForKey:showString value:showString table:nil] : showString;

			_showAttributedString = [[NSAttributedString alloc] initWithString:showLocalizedString attributes: attributes];
			_showAlternateAttributedString = [[NSAttributedString alloc] initWithString:showLocalizedString attributes: alternateAttributes];

			NSString *hideString = @"Hide";
			NSString *hideLocalizedString = bundle ? [bundle localizedStringForKey:hideString value:hideString table:nil] : hideString;

			_hideAttributedString = [[NSAttributedString alloc] initWithString:hideLocalizedString attributes: attributes];
			_hideAlternateAttributedString = [[NSAttributedString alloc] initWithString:hideLocalizedString attributes: alternateAttributes];

			_hideGroupButton = [[NSButton alloc] init];
			_hideGroupButton.bezelStyle = NSRecessedBezelStyle;
			_hideGroupButton.buttonType = NSMomentaryChangeButton;
			_hideGroupButton.bordered = NO;
			_hideGroupButton.alignment = NSCenterTextAlignment;
			_hideGroupButton.attributedTitle = _hideAttributedString;
			_hideGroupButton.attributedAlternateTitle = _hideAlternateAttributedString;
			_hideGroupButton.target = self;
			_hideGroupButton.action = @selector(toggleGroupVisibility);
			_hideGroupButton.hidden = YES;
			[self addSubview:_hideGroupButton];
		}
		[_hideGroupButton sizeToFit];
		NSSize size = _hideGroupButton.frame.size;
		_hideGroupButton.frame = NSMakeRect(NSMaxX(frame) - size.width, frame.size.height - size.height, size.width, size.height);
		for (NSControl *control in self.subviews) {
			if ([control isKindOfClass:[NSTableCellView class]]) {
				NSSize size = control.frame.size;
				control.frame = NSMakeRect(6, frame.size.height - size.height, size.width, size.height);
			}
		}
	}
}
- (void)toggleGroupVisibility {
	OutlineView *outlineView = (OutlineView *)[self superview];
	id item = [outlineView itemAtRow:[outlineView rowForView:self]];
	if ([outlineView isItemExpanded:item]) {
		_hideGroupButton.attributedTitle = _showAttributedString;
		_hideGroupButton.attributedAlternateTitle = _showAlternateAttributedString;
		[outlineView collapseItem:item];
	} else {
		_hideGroupButton.attributedTitle = _hideAttributedString;
		_hideGroupButton.attributedAlternateTitle = _hideAlternateAttributedString;
		[outlineView expandItem:item];
	}
}
- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	if (_trackingArea == nil) {
		_trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
													 options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited
													   owner:self
													userInfo:nil];
	}
	if (![[self trackingAreas] containsObject:_trackingArea]) {
		[self addTrackingArea:_trackingArea];
	}
}
- (void)mouseEntered:(NSEvent *)theEvent {
	_hideGroupButton.hidden = NO;
}
- (void)mouseExited:(NSEvent *)theEvent {
	_hideGroupButton.hidden = YES;
}
@end

static const CGFloat kIndentationPerLevel = 0.0;

@implementation OutlineView {
	id _actualDelegate;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		self.indentationPerLevel = kIndentationPerLevel;
	}
	return self;
}
- (void) expandItem:(id)item expandChildren:(BOOL)expandChildren {
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.0];
	[super expandItem:item expandChildren:expandChildren];
	[NSAnimationContext endGrouping];
}
- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.0];
	[super collapseItem:item collapseChildren:collapseChildren];
	[NSAnimationContext endGrouping];
}
- (NSTableViewSelectionHighlightStyle)selectionHighlightStyle {
	return NSTableViewSelectionHighlightStyleNone;
}
- (void)setIndentationPerLevel:(CGFloat)indentationPerLevel {
	[super setIndentationPerLevel:kIndentationPerLevel];
}
- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
	return [[TableRowView alloc] init];
}
- (void)setDelegate:(id)newDelegate {
	[super setDelegate:nil];
	_actualDelegate = newDelegate;
	[super setDelegate:(id)self];
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
- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	if ([[item indexPath] length] < 2) {
		return [[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]] boundingRectForFont].size.height - 1;
	}
	return [_actualDelegate outlineView:outlineView heightOfRowByItem:item];
}
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {
	return NSZeroRect; // Remove the disclosure triangle
}
@end
