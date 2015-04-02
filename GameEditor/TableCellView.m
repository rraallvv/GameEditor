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
#import "AttributeNode.h"
#import "StepperTextField.h"

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
			NSRange range = [observedKey rangeOfString:@"(?<=\\.|^)value\\d*$" options:NSRegularExpressionSearch];
			NSString *key = range.location != NSNotFound ? [observedKey substringWithRange:range] : nil;

			if (key) {
				/* Update the binding with the attribute's value transformer */
				NSMutableDictionary *options = bindingInfo[NSOptionsKey];
				NSValueTransformer *valueTransformer = attribute.valueTransformer;

				if (valueTransformer) {
					options[NSValueTransformerBindingOption] = valueTransformer;
				} else {
					[options removeObjectForKey:NSValueTransformerBindingOption];
				}

				/* Clear and re-create the binding to update its value transformer */
				[textField unbind:NSValueBinding];
				[textField bind:NSValueBinding toObject:attribute withKeyPath:key options:options];

				/* Set the appropriate number formater */
				textField.formatter = attribute.formatter;

				/* Set the parameters for the stepper text field */
				if ([textField isKindOfClass:[StepperTextField class]]) {
					StepperTextField *stepper = (StepperTextField *)textField;
					stepper.stepperInc = attribute.increment;
					stepper.draggingMult = attribute.sensitivity;
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
