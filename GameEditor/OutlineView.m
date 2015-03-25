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

@implementation TableRowView
- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	[[NSColor yellowColor] set];
	NSRectFill(dirtyRect);
}
@end

@implementation OutlineView {
	id _actualDelegate;
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
- (CGFloat)indentationPerLevel {
	return 0;
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
@end
