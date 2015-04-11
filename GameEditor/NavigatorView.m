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
	id _actualDelegate;
	id _actualDataSource;
	NSIndexPath *_fromIndexPath;
	NSIndexPath *_toIndexPath;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [self selectedRow];
	if (selectedRow != -1) {
		[_actualDelegate navigatorView:self didSelectNode:[[[self itemAtRow:selectedRow] representedObject] node]];
	}
}

- (void)setDelegate:(id<NSOutlineViewDelegate>)anObject {
	[super setDelegate:nil];
	_actualDelegate = anObject;
	[super setDelegate:(id)self];
}

- (id)delegate {
	return self;
}

- (void)setDataSource:(id<NSOutlineViewDataSource>)aSource {
	[super setDataSource:nil];
	_actualDataSource = aSource;
	[super setDataSource:(id)self];
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

- (NSTreeNode *)nodeWithIndexPath:(NSIndexPath *)indexPath inNodes:(NSArray *)nodes {
	for(NSTreeNode *node in nodes) {
		if ([[node indexPath] compare:indexPath] == NSOrderedSame)
			return node;
		if ([[node childNodes] count]) {
			NSTreeNode *result = [self nodeWithIndexPath:indexPath inNodes:[node childNodes]];
			if (result) {
				return result;
			}
		}
	}
	return nil;
}

- (NSIndexPath *)indexPathForNode:(NSTreeNode *)aNode inNodes:(NSArray *)nodes {
	for(NSTreeNode *node in nodes) {
		if ([node isEqual:aNode])
			return [node indexPath];
		if ([[node childNodes] count]) {
			NSIndexPath *result = [self indexPathForNode:aNode inNodes:[node childNodes]];
			if (result) {
				return result;
			}
		}
	}
	return nil;
}

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
		NSPasteboard *p = [info draggingPasteboard];
		_fromIndexPath = [NSKeyedUnarchiver unarchiveObjectWithData:[p dataForType:@"public.binary"]];
		NSTreeNode *rootNode = [[[self infoForBinding:NSContentBinding] valueForKey:NSObservedObjectKey] arrangedObjects];

		NSTreeNode *sourceNode = [self nodeWithIndexPath:_fromIndexPath inNodes:rootNode.childNodes];

		if(!sourceNode) {
			// Not found
			return NSDragOperationNone;
		}

		_toIndexPath = [[item indexPath] indexPathByAddingIndex:MAX(0, index)];

		if (_fromIndexPath.length < _toIndexPath.length) {
			NSUInteger position = 0;
			while (position < _fromIndexPath.length) {
				if ([_fromIndexPath indexAtPosition:position] != [_toIndexPath indexAtPosition:position])
					return NSDragOperationMove;
				position++;
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

		/* Move the node to its new location */
		NSTreeController *treeController = [[self infoForBinding:NSContentBinding] valueForKey:NSObservedObjectKey];
		NSTreeNode *rootNode = [treeController arrangedObjects];
		NSTreeNode *selectedNode = [self nodeWithIndexPath:_fromIndexPath inNodes:rootNode.childNodes];

		NSMutableArray *savedExpadedNodesInfo = [NSMutableArray array];
		[self getExpandedNodesInfo:savedExpadedNodesInfo forNode:selectedNode];

		/* Move the node to its new location */
		[treeController moveNode:selectedNode toIndexPath:_toIndexPath];

		/* Retrieve the selected node if it's being dropped on an item */
		if (index == NSOutlineViewDropOnItemIndex) {
			selectedNode = [self nodeWithIndexPath:[[self indexPathForNode:item inNodes:rootNode.childNodes] indexPathByAddingIndex:0] inNodes:rootNode.childNodes];
		}

		/* Expand the nodes */
		[self expandItem:item];
		[self expandNode:selectedNode withInfo:savedExpadedNodesInfo];

		/* Select the node at it's new location */
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:[self rowForItem:selectedNode]] byExtendingSelection:NO];

		return YES;
	} else {
		return NO;
	}
}

@end
