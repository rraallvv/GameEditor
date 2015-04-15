/*
 * AttributesView.m
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

#import "AttributesView.h"
#import "StepperTextField.h"

#pragma mark TableCellView

@interface TableCellView : NSTableCellView
@end

@implementation TableCellView {
	NSMutableArray *_textFields;
	IBOutlet NSPopover *_popover;
}

- (void)setObjectValue:(id)objectValue {
	_textFields = [NSMutableArray array];

	/* If the table cell is an attribute try to update it's text fields with the appropriate trasformer and formatter */
	if ([objectValue isKindOfClass:[AttributeNode class]]) {

		AttributeNode *attribute = (AttributeNode *)objectValue;

		/* Get all the text fields in the table cell*/
		[self listTextFields:self];

		/* Walk the text fields */
		for (NSTextField *textField in _textFields) {

			/* Get the binding information */
			NSMutableDictionary *bindingInfo = [textField infoForBinding: NSValueBinding].mutableCopy;
			NSString *observedKey = bindingInfo[NSObservedKeyPathKey];

			/* Get the keyPath relative to the attribute object */
			NSArray *results = [observedKey substringsWithRegularExpressionWithPattern:@"(?<=\\.|^)value(\\d*)$" options:0 error:NULL];

			if ([results count]) {
				NSInteger subindex = [results[0] integerValue];

				NSString *key = subindex > 0 ? [NSString stringWithFormat:@"value%ld", subindex] : @"value";

				/* Update the binding with the attribute's value transformer */
				NSMutableDictionary *options = bindingInfo[NSOptionsKey];
				id valueTransformer = attribute.valueTransformer;

				if (valueTransformer) {
					if ([valueTransformer isKindOfClass:[NSArray class]]) {
						options[NSValueTransformerBindingOption] = [valueTransformer objectAtIndex:MIN(subindex, [valueTransformer count]) - 1];
					} else {
						options[NSValueTransformerBindingOption] = valueTransformer;
					}
				} else {
					[options removeObjectForKey:NSValueTransformerBindingOption];
				}

				/* Clear and re-create the binding to update its value transformer */
				[textField unbind:NSValueBinding];
				[textField bind:NSValueBinding toObject:attribute withKeyPath:key options:options];

				/* Set the appropriate number formater */
				id formatter = attribute.formatter;
				if ([formatter isKindOfClass:[NSArray class]]) {
					textField.formatter = [formatter objectAtIndex:MIN(subindex, [formatter count]) - 1];
				} else {
					textField.formatter = attribute.formatter;
				}
			}
		}
	}

	if (_textFields.count == 0)
		_textFields = nil;

	[super setObjectValue:objectValue];
}

- (void)listTextFields:(id)view {

	/* Recursivelly retrieve all text fields in the table cell */
	for (id subview in [view subviews]) {
		if ([subview isKindOfClass:[NSTextField class]]) {
			[_textFields addObject:subview];
		}
		[self listTextFields:subview];
	}
}

- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window delegate:(id)delegate didPresentSelector:(SEL)didPresentSelector contextInfo:(void *)contextInfo {

	NSBeep();

	NSLog(@"Error: %@", error.localizedDescription);

#if 0
	if (_popover == nil) {
		_popover = [[NSPopover alloc] init];
		_popover.behavior = NSPopoverBehaviorSemitransient;
	}

	[_popover.contentViewController.view.subviews.firstObject setStringValue:error.localizedDescription];
	[_popover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMinXEdge];
#endif

}

@end

#pragma mark AttributesTableRowView

@interface AttributesTableRowView : NSTableRowView
@end

@implementation AttributesTableRowView {
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
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {

	AttributesView *outlineView = (AttributesView *)[self superview];

	NSInteger row = [outlineView rowForView:self];
	id item = [outlineView itemAtRow:row];
	NSUInteger indexPathLength = [[item indexPath] length];

	//id prevItem = [outlineView itemAtRow:row - 1];
	//NSUInteger prevIndexPathLength = [[prevItem indexPath] length];
	//BOOL prevItemIsGroup = [(id)outlineView outlineView:outlineView isGroupItem:prevItem];

	id nextItem = [outlineView itemAtRow:row + 1];
	NSUInteger nextIndexPathLength = [[nextItem indexPath] length];
	BOOL nextItemIsGroup = [(id)outlineView outlineView:outlineView isGroupItem:nextItem];

	CGFloat separatorMargin = 16;

	NSColor *rootNodeSeparatorColor = [NSColor lightGrayColor];
	NSColor *groupNodeSeparatorColor = [NSColor lightGrayColor];

	[NSBezierPath setDefaultLineWidth:1.0];
	CGFloat pixelOffset = 0.5;

	CGPoint topLeft = NSMakePoint(0,  pixelOffset);
	CGPoint topRight = NSMakePoint(NSWidth(dirtyRect), pixelOffset);
	CGPoint bottomLeft = NSMakePoint(0,  NSMaxY(dirtyRect) - 1 + pixelOffset);
	CGPoint bottomRight = NSMakePoint(NSWidth(dirtyRect), NSMaxY(dirtyRect) - 1 + pixelOffset);

	CGPoint marginBottomLeft = NSMakePoint(bottomLeft.x + separatorMargin,  bottomLeft.y);

	/* Only draw the separator for the root nodes */
	if (self.isGroupRowStyle) {

		if (indexPathLength == 1) {
			[rootNodeSeparatorColor set];

			/* Separator at the top of a root group */
			if (row > 0) {
				[NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
			}

			/* Separator at the bottom of the last root group */
			if (row == [outlineView numberOfRows] - 1) {
				[NSBezierPath strokeLineFromPoint:bottomLeft toPoint:bottomRight];
			}

			[groupNodeSeparatorColor set];

			/* Separator between a root group a non-root group node */
			if (indexPathLength < nextIndexPathLength
				&& nextItemIsGroup) {
				[NSBezierPath strokeLineFromPoint:marginBottomLeft toPoint:bottomRight];
			}

		} else {
			[groupNodeSeparatorColor set];

			/* Separator between two non-root group node */
			if (indexPathLength == nextIndexPathLength) {
				[NSBezierPath strokeLineFromPoint:marginBottomLeft toPoint:bottomRight];
			}
		}

	} else {
		[groupNodeSeparatorColor set];

		/* Separator at the bottom of a leaf node followed by a non-root group node */
		if (nextIndexPathLength > 1
			&& nextItemIsGroup) {
			[NSBezierPath strokeLineFromPoint:marginBottomLeft toPoint:bottomRight];
		}

		/* Separator at the bottom of a leaf node followed by a leaf node */
		if (nextIndexPathLength < indexPathLength
			&& !nextItemIsGroup) {
			[NSBezierPath strokeLineFromPoint:marginBottomLeft toPoint:bottomRight];
		}
	}
}

- (void)setFrame:(NSRect)frame {
	[super setFrame:frame];

	AttributesView *outlineView = (AttributesView *)[self superview];
	NSInteger row = [outlineView rowForView:self];
	NSUInteger indexPathLength = [[[outlineView itemAtRow:row] indexPath] length];

	if (self.isGroupRowStyle && indexPathLength == 1) {
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
		/*
		for (NSControl *control in self.subviews) {
			if ([control isKindOfClass:[NSTableCellView class]]) {
				NSSize size = control.frame.size;
				control.frame = NSMakeRect(frame.origin.x, frame.size.height - size.height, size.width, size.height);
			}
		}
		 */
	}
}

- (void)toggleGroupVisibility {
	AttributesView *outlineView = (AttributesView *)[self superview];
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

#pragma mark AttributesView

static const CGFloat kIndentationPerLevel = 0.0;

@interface AttributesView () <NSOutlineViewDelegate>
@end

@implementation AttributesView {
	__weak id _actualDelegate;
	NSMutableDictionary *_prefferedSizes;
	NSMutableArray *_editorIdentifiers;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		self.indentationPerLevel = kIndentationPerLevel;

		/* Prepare the editors for the outline view */
		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"ValueEditors" bundle:nil];
		NSArray* objects;
		[nib instantiateWithOwner:self topLevelObjects:&objects];

		_editorIdentifiers = [NSMutableArray array];
		_prefferedSizes = [NSMutableDictionary dictionary];

		for (id object in objects) {
			if ([object isKindOfClass:[NSTableCellView class]]) {
				NSTableCellView *tableCelView = object;

				/* Register the identifiers for each editors */
				[self registerNib:nib forIdentifier:tableCelView.identifier];

				/* Fetch the preffered size for the editor's view */
				_prefferedSizes[tableCelView.identifier] = [NSValue valueWithSize:tableCelView.frame.size];

				/* Store the available indentifiers */
				[_editorIdentifiers addObject:tableCelView.identifier];
			}
		}
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
	return [[AttributesTableRowView alloc] init];
}

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

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	NSString *type = [[item representedObject] valueForKey:@"type"];
	if (type) {
		for (NSString *identifier in _editorIdentifiers) {
			if (type.length == [type rangeOfString:identifier options:NSRegularExpressionSearch].length) {
				return [_prefferedSizes[identifier] sizeValue].height;
			}
		}
	}
	return 20;
}

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {

	id item = [self itemAtRow:row];

	if ([item indexPath].length > 1 && [self outlineView:self isGroupItem:item]) {
		NSRect rect = [super frameOfOutlineCellAtRow:row];
		rect.origin.x = 2;
		return rect;
	}

	return NSZeroRect; // Remove the disclosure triangle
}

- (void)drawRect:(NSRect)dirtyRect {
	[self.backgroundColor set];
	NSRectFill(dirtyRect);
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([(id)outlineView outlineView:outlineView isGroupItem:item]) {
		if ([item indexPath].length == 1) {
			return [outlineView makeViewWithIdentifier:@"class" owner:self];
		} else {
			return [outlineView makeViewWithIdentifier:@"expandable" owner:self];
		}
	} else if ([[tableColumn identifier] isEqualToString:@"key"]) {
		return [outlineView makeViewWithIdentifier:@"attribute" owner:self];
	} else {
		NSString *type = [[item representedObject] valueForKey:@"type"];
		for (NSString *identifier in _editorIdentifiers) {
			if (type.length == [type rangeOfString:identifier options:NSRegularExpressionSearch].length) {
				return [outlineView makeViewWithIdentifier:identifier owner:self];
			}
		}
		return [outlineView makeViewWithIdentifier:@"generic attribute" owner:self];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return ![[[item representedObject] valueForKey:@"isLeaf"] boolValue];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
	NSInteger row = [self rowForItem:notification.userInfo[@"NSObject"]];
	NSView *rowView = [self rowViewAtRow:row makeIfNecessary:NO];
	[rowView setNeedsDisplay:YES];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	NSInteger row = [self rowForItem:notification.userInfo[@"NSObject"]];
	NSView *rowView = [self rowViewAtRow:row makeIfNecessary:NO];
	[rowView setNeedsDisplay:YES];
}

@end
