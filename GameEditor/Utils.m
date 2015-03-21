/*
 * StepperTextField.h
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

#import "Utils.h"

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
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSValue *result = [NSValue valueWithPoint:NSPointFromString(value)];
	//NSLog(@"<%@", result);
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
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(NSNumber *)value {
	NSNumber *result = @(value.floatValue*M_PI/180);
	//NSLog(@"<%@", result);
	return result;
}
@end

@implementation Property
@synthesize propertyName = _propertyName, propertyValue = _propertyValue, editable = _editable;
+ (Property *)propertyWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	Property *property = [[Property alloc] init];
	property.propertyName = name;
	property.node = node;
	property.type = type;

	[property bind:@"propertyValue" toObject:node withKeyPath:property.propertyName options:nil];
	[node bind:property.propertyName toObject:property withKeyPath:@"propertyValue" options:nil];

	return property;
}
- (BOOL)editable {
	return YES;
}
- (void)dealloc {
	[self unbind:@"propertyValue"];
	[self.node unbind:self.propertyName];
}
- (void)setX:(float)value {
	NSPoint point = _propertyValue.pointValue;
	if (value != point.x) {
		point.x = value;
		self.propertyValue = [NSValue valueWithPoint:point];
	}
}
- (float)x {
	return _propertyValue.pointValue.x;
}
- (void)setY:(float)value {
	NSPoint point = _propertyValue.pointValue;
	if (value != point.y) {
		point.y = value;
		self.propertyValue = [NSValue valueWithPoint:point];
	}
}
- (float)y {
	return _propertyValue.pointValue.y;
}
- (void)setPropertyValue:(NSValue *)propertyValue {
	NSPoint point = propertyValue.pointValue;
	float x = self.x;
	if (x != point.x) {
		self.x = x;
	}
	float y = self.y;
	if (y != point.y) {
		self.y = y;
	}
	_propertyValue = propertyValue;
}
- (NSValue *)propertyValue {
	return _propertyValue;
}
@end
