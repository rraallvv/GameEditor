/*
 * NavigatorView.m
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

#import "NavigatorView.h"

#pragma mark NavigatorView

@interface NavigatorView () <NSOutlineViewDelegate, NSOutlineViewDataSource>

@end

@implementation NavigatorView {
	__weak id _actualDelegate;
	__weak id _actualDataSource;
	NSIndexPath *_fromIndexPath;
	NSIndexPath *_toIndexPath;
	__weak NSTreeController *_treeController;
}

- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
	[super bind:binding toObject:observable withKeyPath:keyPath options:options];
	if ([binding isEqualToString:NSContentBinding]
		&& [observable isKindOfClass:[NSTreeController class]]) {
		_treeController = observable;
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	id selectedObject = [[_treeController selectedObjects] firstObject];
	[_actualDelegate navigatorView:self didSelectObject:selectedObject];
}

- (void)setDelegate:(id<NSOutlineViewDelegate>)anObject {
	[super setDelegate:nil];
	_actualDelegate = anObject;
	[super setDelegate:self];
}

- (id)delegate {
	return self;
}

- (void)setDataSource:(id<NSOutlineViewDataSource>)aSource {
	[super setDataSource:nil];
	_actualDataSource = aSource;
	[super setDataSource:self];
}

- (id<NSOutlineViewDataSource>)dataSource {
	return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
	if ([_actualDelegate respondsToSelector:aSelector]) { return _actualDelegate; }
	return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return [super respondsToSelector:aSelector] || [_actualDelegate respondsToSelector:aSelector];
}

#pragma mark Drag & Drop

- (void)getExpandedNodesInfo:(NSMutableArray *)array forNode:(NSTreeNode *)aNode {
	[array addObject:[NSNumber numberWithBool:[self isItemExpanded:aNode]]];
	for (NSTreeNode *node in aNode.childNodes) {
		[self getExpandedNodesInfo:array forNode:node];
	}
}

- (void)expandNode:(NSTreeNode *)aNode withInfo:(NSMutableArray *)array {
	if ([[array firstObject] boolValue]) {
		[self expandItem:aNode];
	}
	[array removeObjectAtIndex:0];
	for (NSTreeNode *node in aNode.childNodes) {
		[self expandNode:node withInfo:array];
	}
}

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
	NSPasteboardItem *pboardItem = [[NSPasteboardItem alloc] init];
	NSData *pboardData = [NSKeyedArchiver archivedDataWithRootObject:[item indexPath]];
	[pboardItem setData:pboardData forType:@"public.binary"];
	return pboardItem;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	if (item) {
		NSPasteboard *pasteBoard = [info draggingPasteboard];
		_fromIndexPath = [NSKeyedUnarchiver unarchiveObjectWithData:[pasteBoard dataForType:@"public.binary"]];
		_toIndexPath = [[item indexPath] indexPathByAddingIndex:MAX(0, index)];

		if (_fromIndexPath.length < _toIndexPath.length) {
			/* Can't drop the item on itself nor one of its children */
			for (NSUInteger position = 0; position < _fromIndexPath.length; ++position) {
				if ([_fromIndexPath indexAtPosition:position] != [_toIndexPath indexAtPosition:position]) {
					return NSDragOperationMove;
				}
			}
			return NSDragOperationNone;
		}

		return NSDragOperationMove;
	} else {
		return NSDragOperationNone;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	if ([self outlineView:outlineView validateDrop:info proposedItem:item proposedChildIndex:index] == NSDragOperationMove) {
		[self moveNodeFromIndexPath:_fromIndexPath toIndexPath:_toIndexPath];
		return YES;
	}
	return NO;
}

- (void)moveNodeFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {

	/* Register undo operation */
	[[self.undoManager prepareWithInvocationTarget:self] moveNodeFromIndexPath:toIndexPath toIndexPath:fromIndexPath];

	/* Move the node to its new location */
	NSTreeNode *rootNode = [_treeController arrangedObjects];
	NSTreeNode *selectedNode = [rootNode descendantNodeAtIndexPath:fromIndexPath];

	/* Save the state of node to be moved */
	NSMutableArray *savedExpadedNodesInfo = [NSMutableArray array];
	[self getExpandedNodesInfo:savedExpadedNodesInfo forNode:selectedNode];

	/* Move the node to its new location */
#if 0// remove and insert instead of moving the node
	[_treeController removeObjectAtArrangedObjectIndexPath:fromIndexPath];
	NSIndexPath *indexPath = [[NSIndexPath alloc] init];
	for (NSInteger position = 0; position < toIndexPath.length; ++position) {
		NSInteger fromIndex = [fromIndexPath indexAtPosition:position];
		NSInteger toIndex = [toIndexPath indexAtPosition:position];
		if (fromIndex == toIndex) {
			indexPath = [indexPath indexPathByAddingIndex:fromIndex];
		} else if (fromIndexPath.length - 1 == position && fromIndex < toIndex) {
			indexPath = [indexPath indexPathByAddingIndex:toIndex - 1];
		} else {
			indexPath = [indexPath indexPathByAddingIndex:toIndex];
		}
	}
	[_treeController insertObject:[selectedNode representedObject] atArrangedObjectIndexPath:indexPath];
#else
	[_treeController moveNode:selectedNode toIndexPath:toIndexPath];
#endif

	/* Retrieve the selected node at its new location */
	selectedNode = [rootNode descendantNodeAtIndexPath:toIndexPath];

	/* Expand the new parent node */
	[self expandItem:selectedNode.parentNode];

	/* Expand the moved node */
	[self expandNode:selectedNode withInfo:savedExpadedNodesInfo];

	/* Select the node at it's new location */
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:[self rowForItem:selectedNode]] byExtendingSelection:NO];
}

@end
