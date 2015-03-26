/*
 * FloatsTableCellView.m
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

#import "FloatsTableCellView.h"

@implementation FloatsTableCellView {
	NSMutableArray *_labels;
}

- (void)setLabels:(NSArray *)labels {
	_labels = [NSMutableArray array];
	[self listLabels:self];

	NSArray *sortedLabels = [_labels sortedArrayUsingComparator:^NSComparisonResult(NSTextField *a, NSTextField *b) {
		NSRect first = a.frame;
		NSRect second = b.frame;
		if (first.origin.y < second.origin.y) {
			return NSOrderedDescending;
		} else if (first.origin.y > second.origin.y) {
			return NSOrderedAscending;
		}
		if (first.origin.x < second.origin.x) {
			return NSOrderedAscending;
		} else if (first.origin.x > second.origin.x) {
			return NSOrderedDescending;
		}
		return NSOrderedSame;
	}];

	int index = 0;

	while (index < labels.count && index < sortedLabels.count) {
		[sortedLabels[index] setStringValue:labels[index]];
		index++;
	}
}

- (void)listLabels:(id)view {

	NSArray *subviews = [view subviews];

	for (id subview in subviews) {

		if ([subview isKindOfClass:[NSTextField class]] && [[subview stringValue] caseInsensitiveCompare:@"Label"] == NSOrderedSame) {
			[_labels addObject:subview];
		}

		[self listLabels:subview];
	}
}

@end
