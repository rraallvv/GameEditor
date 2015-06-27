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
#import "InspectorTableView.h"
#import "NSView+LayoutConstraint.h"

#pragma mark UserDataTableCellView

@interface UserDataTableCellView : InspectorTableCellView
@property (weak) IBOutlet UserDataTableView *userDataTable;
@property (weak) IBOutlet NSButton *addValue;
@property (weak) IBOutlet NSButton *removeValue;
@end

@implementation UserDataTableCellView

- (void)awakeFromNib {
	/* Register for receiving notifications when the user data table change its selection */
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(selectionDidChange:)
												 name:NSTableViewSelectionDidChangeNotification
											   object:self.userDataTable];
}

- (IBAction)didClickAddValueButton:(NSButton *)sender {
	NSDictionaryController *dictionaryController = [self.objectValue valueForKey:NSContentBinding];
	NSInteger selectedRow = [self.userDataTable selectedRow];
	id newObject = [dictionaryController newObject];
	if (selectedRow == -1) {
		/* Add a new value below the last row */
		[newObject setKey:@"key"];
		[newObject setValue:@YES];
		[dictionaryController addObject:newObject];
	} else {
		/* Add a copy of the selected value below the selected row */
		id value = [[[dictionaryController arrangedObjects] objectAtIndex:selectedRow] valueForKey:NSValueBinding];
		[newObject setKey:@"key"];
		[newObject setValue:value];
		[dictionaryController insertObject:newObject atArrangedObjectIndex:selectedRow + 1];
	}
}

- (IBAction)didClickRemoveValueButton:(NSButton *)sender {
	NSDictionaryController *dictionaryController = [self.objectValue valueForKey:NSContentBinding];
	NSInteger selectedRow = [self.userDataTable selectedRow];
	if (selectedRow != -1) {
		[dictionaryController removeObjectAtArrangedObjectIndex:selectedRow];
	}

	/* -[selectionDidChange:] is not called when a value is removed, so the button it's disabled here */
	self.removeValue.enabled = NO;
}

- (void)selectionDidChange:(NSNotification*)note {
	/* Disable the remove value button if there is no selection */
	self.removeValue.enabled = self.userDataTable.selectedRow != -1;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTableViewSelectionDidChangeNotification
												  object:self.userDataTable];
}

@end

#pragma mark UserDataTableView

@interface UserDataTableView () <NSTableViewDelegate, NSTableViewDataSource>

@end

@implementation UserDataTableView {
	__weak id _actualDelegate;
	__weak id _actualDataSource;
	NSInteger _previousSelectionRow;
	__weak NSScrollView *_scrollView;
}

- (void)awakeFromNib {
	_scrollView = self.enclosingScrollView;
}

- (void)didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	const CGFloat theHeight = self.numberOfRows * 19.0 + self.headerView.frame.size.height + 16;//9.0;

	InspectorTableRowView *tableRowView = (InspectorTableRowView *)_scrollView.superview.superview;
	CGRect frame = tableRowView.frame;
	frame.size.height = theHeight;
	tableRowView.frame = frame;

	InspectorTableView *inspectorView = (InspectorTableView *)tableRowView.superview;

	[tableRowView setConstraintConstant:theHeight - 2 forAttribute:NSLayoutAttributeHeight];
	[inspectorView setHeight:theHeight - 2 forItem:[inspectorView itemAtRow:[inspectorView rowForView:tableRowView]]];

	if (row == self.numberOfRows - 1) {
		/* Update the user data table's height when adding the last row */
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0];
		[inspectorView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[inspectorView rowForView:tableRowView]]];
		[NSAnimationContext endGrouping];
	}

	InspectorTableRowView *prevRowView = tableRowView;
	for (NSInteger i=[inspectorView rowForView:tableRowView] + 1; i<inspectorView.numberOfRows; ++i) {
		InspectorTableRowView *nextRowView = (InspectorTableRowView *)[inspectorView rowViewAtRow:i makeIfNecessary:NO];
		CGFloat newTop = NSMaxY(prevRowView.frame);
		[nextRowView setConstraintConstant:newTop forAttribute:NSLayoutAttributeTop];
		[inspectorView setTop:newTop forItem:[inspectorView itemAtRow:[inspectorView rowForView:nextRowView]]];
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
