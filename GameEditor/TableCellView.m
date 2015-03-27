/*
 * TableCellView.m
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

#import "TableCellView.h"
#import "Attribute.h"

@implementation TableCellView {
	NSMutableArray *_textFields;
}

- (void)setObjectValue:(id)objectValue {
	[super setObjectValue:objectValue];

	_textFields = [NSMutableArray array];

	if ([objectValue isKindOfClass:[Attribute class]]) {
		[self listTextFields:self];
		for (NSTextField *textField in _textFields) {
			textField.formatter = [objectValue formatter];
		}
	}

	if (_textFields.count == 0)
		_textFields = nil;
}

- (void)listTextFields:(id)view {
	for (id subview in [view subviews]) {
		if ([subview isKindOfClass:[NSTextField class]]) {
			NSString *observedKey = [self observedKeyForObject:subview];
			if (observedKey && [observedKey rangeOfString:@"(\\.|^)value\\d*$" options:NSRegularExpressionSearch].location != NSNotFound) {
				[_textFields addObject:subview];
			}
		}
		[self listTextFields:subview];
	}
}

- (NSString *)observedKeyForObject:(id)object {
	NSDictionary *bindingInfo = [object infoForBinding: NSValueBinding];
	return bindingInfo[NSObservedKeyPathKey];
}

@end
