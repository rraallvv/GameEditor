/*
 * Attribute.m
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

#import "Attribute.h"

static NSDictionary *pointTransformer = nil;

@implementation PointTransformer
+ (NSDictionary *)transformer {
	if (pointTransformer) {
		return pointTransformer;
	} else {
		return pointTransformer = @{ NSValueTransformerBindingOption:[[PointTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSValue class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSValue *result = value;
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSValue *result = [NSValue valueWithPoint:NSPointFromString(value)];
	return result;
}
@end

static NSDictionary *degreesTransformer = nil;

@implementation DegreesTransformer
+ (NSDictionary *)transformer {
	if (degreesTransformer) {
		return degreesTransformer;
	} else {
		return degreesTransformer = @{ NSValueTransformerBindingOption:[[DegreesTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(NSNumber *)value {
	NSNumber *result = @(value.floatValue*180/M_PI);
	return result;
}
- (id)reverseTransformedValue:(NSNumber *)value {
	NSNumber *result = @(value.floatValue*M_PI/180);
	return result;
}
@end

static NSDictionary *attibuteNameTransformer = nil;

@implementation AttibuteNameTransformer
+ (NSDictionary *)transformer {
	if (attibuteNameTransformer) {
		return attibuteNameTransformer;
	} else {
		return attibuteNameTransformer = @{ NSValueTransformerBindingOption:[[AttibuteNameTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
	return NO;
}
- (id)transformedValue:(id)value {
	NSString *str = value;
	NSMutableString *str2 = [NSMutableString string];

	for (NSInteger i=0; i<str.length; i++){
		NSString *ch = [str substringWithRange:NSMakeRange(i, 1)];
		if ([ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound) {
			[str2 appendString:@" "];
		} else if ([ch isEqualToString:@"_"]) {
			if (i == 0)
				continue;
			else
				[str2 appendString:@" "];
		} else if ([ch isEqualToString:@"-"]) {
			[str2 appendString:@" "];
		}
		[str2 appendString:ch];
	}

	NSString * result = str2.capitalizedString;

	return result;
}
@end

@implementation Attribute
@synthesize name = _name, value = _value, editable = _editable;
+ (Attribute *)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	Attribute *attribute = [[Attribute alloc] init];
	attribute.name = name;
	attribute.node = node;
	attribute.type = type;

	[attribute bind:@"value" toObject:node withKeyPath:attribute.name options:nil];
	[node bind:attribute.name toObject:attribute withKeyPath:@"value" options:nil];

	return attribute;
}
- (BOOL)isEditable {
	return YES;
}
- (BOOL)isLeaf {
	return YES;
}
- (void)dealloc {
	[self unbind:@"value"];
	[self.node unbind:self.name];
}
- (void)setX:(float)value {
	NSPoint point = _value.pointValue;
	if (value != point.x) {
		point.x = value;
		self.value = [NSValue valueWithPoint:point];
	}
}
- (float)x {
	return _value.pointValue.x;
}
- (void)setY:(float)value {
	NSPoint point = _value.pointValue;
	if (value != point.y) {
		point.y = value;
		self.value = [NSValue valueWithPoint:point];
	}
}
- (float)y {
	return _value.pointValue.y;
}
- (void)setValue:(NSValue *)value {
	NSPoint point = value.pointValue;
	float x = self.x;
	if (x != point.x) {
		self.x = x;
	}
	float y = self.y;
	if (y != point.y) {
		self.y = y;
	}
	_value = value;
}
- (NSValue *)value {
	return _value;
}
@end
