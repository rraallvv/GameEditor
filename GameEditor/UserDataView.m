/*
 * UserDataView.m
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

#import "UserDataView.h"
#import "InspectorView.h"
#import "NSView+LayoutConstraint.h"

#pragma mark UserDataTableView

@interface UserDataTableView () <NSTableViewDelegate, NSTableViewDataSource>

@end

@implementation UserDataTableView {
	__weak id _actualDelegate;
	__weak id _actualDataSource;
	NSInteger _previousSelectionRow;
	CGFloat _minimumHeight;
	__weak NSScrollView *_scrollView;
}

- (void)setConstraintConstantHeight:(CGFloat)tableHeight {
	NSLayoutConstraint *constraint = [_scrollView constraintForAttribute:NSLayoutAttributeHeight];
	NSLog(@"%f", constraint.constant);
	if (tableHeight == constraint.constant)
		return;
	[constraint setConstant:tableHeight];
}

- (void)didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	const CGFloat theHeight = [self numberOfRows] * 19.0 + self.headerView.frame.size.height + 16;//9.0;

	_scrollView = self.enclosingScrollView;
	NSLayoutConstraint *constraint = [_scrollView constraintForAttribute:NSLayoutAttributeHeight];
	_minimumHeight = constraint.constant;
	[self setConstraintConstantHeight:theHeight];

	InspectorTableRowView *tableRowView = (InspectorTableRowView *)_scrollView.superview.superview;
	constraint = [tableRowView constraintForAttribute:NSLayoutAttributeHeight];
	[tableRowView setConstraintConstantHeight:theHeight];
	CGRect frame = tableRowView.frame;
	frame.size.height = theHeight;
	tableRowView.frame = frame;

	InspectorView *tableView = (InspectorView *)tableRowView.superview;
	InspectorTableRowView *prevRowView = tableRowView;
	for (NSInteger i=[tableView rowForView:tableRowView] + 1; i<[tableView numberOfRows]; ++i) {
		InspectorTableRowView *nextRowView = (InspectorTableRowView *)[tableView rowViewAtRow:i makeIfNecessary:NO];
		frame = nextRowView.frame;
		frame.origin.y = NSMaxY(prevRowView.frame);
		nextRowView.frame = frame;
		prevRowView = nextRowView;
	}
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle row:(NSInteger)row {
	NSTableCellView *tableCellView = [self viewAtColumn:2 row:row makeIfNecessary:NO];
	NSTabView *tabView = tableCellView.subviews.firstObject;
	for (NSTabViewItem *item in [tabView tabViewItems]) {
		id control = [[item view] subviews].firstObject;
		if ([control isKindOfClass:[NSTextField class]]) {
			NSTextField *textField = control;
			NSTextFieldCell *cell = textField.cell;
			cell.backgroundStyle = backgroundStyle;
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	[self setBackgroundStyle:NSBackgroundStyleDark row:row];
	[self setBackgroundStyle:NSBackgroundStyleLight row:_previousSelectionRow];
	_previousSelectionRow = row;
	return YES;
}

#pragma mark Delegate methods interception

- (void)setDelegate:(id<NSTableViewDelegate>)anObject {
	[super setDelegate:nil];
	_actualDelegate = anObject;
	[super setDelegate:self];
}

- (id)delegate {
	return self;
}

- (void)setDataSource:(id<NSTableViewDataSource>)aSource {
	[super setDataSource:nil];
	_actualDataSource = aSource;
	[super setDataSource:self];
}

- (id<NSTableViewDataSource>)dataSource {
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
