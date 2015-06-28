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

#pragma mark UserDataDictionary

@implementation UserDataDictionary {
	__weak SKNode *_node;
}

- (NSUInteger)count {
	return _node.userData.count;
}

-(id)objectForKey:(id)aKey {
	return _node.userData[aKey];
}

-(NSEnumerator *)keyEnumerator {
	return [_node.userData keyEnumerator];
}

- (instancetype)initWithNode:(SKNode *)node {
	if (self = [super init]) {
		_node = node;
		if (_node.userData.count == 0) {
			_node.userData = nil;
		}
	}
	return self;
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
	if (!_node.userData) {
		_node.userData = [NSMutableDictionary dictionary];
	}
	_node.userData[aKey] = anObject;
}

-(void)removeObjectForKey:(id)aKey {
	[_node.userData removeObjectForKey:aKey];
	if (_node.userData.count == 0) {
		_node.userData = nil;
	}
}

@end

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
	NSIndexSet *selectedRows = [self.userDataTable selectedRowIndexes];
	if (selectedRows) {
		[dictionaryController removeObjectsAtArrangedObjectIndexes:selectedRows];
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
	__weak NSScrollView *_scrollView;
}

- (void)awakeFromNib {
	_scrollView = self.enclosingScrollView;
}

- (void)didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	[super didAddRowView:rowView forRow:row];
	[self updateTableHeight];
}

- (void)didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
	[super didRemoveRowView:rowView forRow:row];
	[self updateTableHeight];
}

- (void)updateTableHeight {
	InspectorTableRowView *inspectorTableRowView = (InspectorTableRowView *)_scrollView.superview.superview;

	const CGFloat newHeight = MAX([self heightForRows:3], [self heightForRows:self.numberOfRows]);

	CGRect frame = inspectorTableRowView.frame;
	frame.size.height = newHeight;
	inspectorTableRowView.frame = frame;

	InspectorTableView *inspectorTableView = (InspectorTableView *)inspectorTableRowView.superview;

	[inspectorTableRowView setConstraintConstant:newHeight - 2 forAttribute:NSLayoutAttributeHeight];
	[inspectorTableView setHeight:newHeight - 2 forItem:[inspectorTableView itemAtRow:[inspectorTableView rowForView:inspectorTableRowView]]];

	/* Update the user data table's row height */
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0];
	[inspectorTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[inspectorTableView rowForView:inspectorTableRowView]]];
	[NSAnimationContext endGrouping];

	InspectorTableRowView *prevRowView = inspectorTableRowView;
	for (NSInteger i=[inspectorTableView rowForView:inspectorTableRowView] + 1; i<inspectorTableView.numberOfRows; ++i) {
		InspectorTableRowView *nextRowView = (InspectorTableRowView *)[inspectorTableView rowViewAtRow:i makeIfNecessary:NO];
		CGFloat newTop = NSMaxY(prevRowView.frame);
		[nextRowView setConstraintConstant:newTop forAttribute:NSLayoutAttributeTop];
		[inspectorTableView setTop:newTop forItem:[inspectorTableView itemAtRow:[inspectorTableView rowForView:nextRowView]]];
		prevRowView = nextRowView;
	}
}

- (CGFloat)heightForRows:(NSInteger)rows {
	return rows * (self.rowHeight + 2) + self.headerView.frame.size.height + 20;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle atRow:(NSInteger)row {
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

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
	for (int row = 0; row < self.numberOfRows; ++row) {
		[self setBackgroundStyle: row == self.selectedRow ? NSBackgroundStyleDark : NSBackgroundStyleLight atRow:row];
	}
}

// TODO: Add basic editing cababilities for the values in the table

- (IBAction)copy:(id)sender {
	NSLog(@">>>copy");
}

- (IBAction)paste:(id)sender {
	NSLog(@">>>paste");
}

- (IBAction)delete:(id)sender {
	NSLog(@">>>delete");
}

- (IBAction)cut:(id)sender {
	NSLog(@">>>cut");
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
