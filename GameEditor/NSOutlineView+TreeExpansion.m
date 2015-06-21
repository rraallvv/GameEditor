/*
 * NSOutlineView+TreeExpansion.m
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

#import "NSOutlineView+TreeExpansion.h"

@implementation NSOutlineView (TreeExpansion)

- (NSMutableArray *)expansionInfoWithNode:(NSTreeNode *)aNode {
	NSMutableArray *expansionInfo = [NSMutableArray array];
	[self getExpandedNodesInfo:expansionInfo forNode:aNode];
	return expansionInfo;
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

@end
