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
@synthesize
name = _name,
value = _value,
editable = _editable;

+ (Attribute *)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type options:(NSDictionary *)options {
	Attribute *attribute = [[Attribute alloc] init];
	attribute.name = name;
	attribute.node = node;
	attribute.type = type;

	NSString *setterStr = [NSString stringWithFormat:@"set%@%@:",
						   [[attribute.name substringToIndex:1] capitalizedString],
						   [attribute.name substringFromIndex:1]];

	if ([attribute respondsToSelector:NSSelectorFromString(attribute.name)]
		&& [attribute respondsToSelector:NSSelectorFromString(setterStr)]) {
		[attribute bind:attribute.name toObject:node withKeyPath:attribute.name options:options];
		//[node bind:attribute.name toObject:attribute withKeyPath:attribute.name options:nil];
	} else {
		[attribute bind:@"value" toObject:node withKeyPath:attribute.name options:options];
		//[node bind:attribute.name toObject:attribute withKeyPath:@"value" options:nil];
	}

	return attribute;
}
- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", _name, _type];
}
- (BOOL)isEditable {
	return YES;
}
- (BOOL)isLeaf {
	return YES;
}
- (void)dealloc {
	[self unbind:@"value"];
	//[self.node unbind:self.name];
}

#pragma mark position accessors

- (void)setX:(float)x {
	NSPoint position = self.position;
	if (x != position.x) {
		position.x = x;
		self.position = position;
	}
}
- (float)x {
	return self.position.x;
}
- (void)setY:(float)y {
	NSPoint position = self.position;
	if (y != position.y) {
		position.y = y;
		self.position = position;
	}
}
- (float)y {
	return self.position.y;
}
- (void)setPosition:(NSPoint)position {
	float x = self.x;
	if (x != position.x) {
		self.x = x;
	}
	float y = self.y;
	if (y != position.y) {
		self.y = y;
	}
	self.value = [NSValue valueWithPoint:position];
}
- (NSPoint)position {
	return [self.value pointValue];
}

#pragma mark size accessors

- (void)setWidth:(float)width {
	NSSize size = self.size;
	if (width != size.width) {
		size.width = width;
		self.size = size;
	}
}
- (float)width {
	return self.size.width;
}
- (void)setHeight:(float)height {
	NSSize size = self.size;
	if (height != size.height) {
		size.height = height;
		self.size = size;
	}
}
- (float)height {
	return self.size.height;
}
- (void)setSize:(NSSize)size {
	float width = self.width;
	if (width != size.width) {
		self.width = width;
	}
	float height = self.height;
	if (height != size.height) {
		self.height = height;
	}
	self.value = [NSValue valueWithSize:size];
}
- (NSSize)size {
	return [self.value sizeValue];
}

#pragma mark rect accessors

- (void)setRectX:(float)x {
	NSRect rect = self.rect;
	if (x != rect.origin.x) {
		rect.origin.x = x;
		self.rect = rect;
	}
}
- (float)rectX {
	return self.rect.origin.x;
}
- (void)setRectY:(float)y {
	NSRect rect = self.rect;
	if (y != rect.origin.y) {
		rect.origin.y = y;
		self.rect = rect;
	}
}
- (float)rectY {
	return self.rect.origin.y;
}
- (void)setRectWidth:(float)width {
	NSRect rect = self.rect;
	if (width != rect.size.width) {
		rect.size.width = width;
		self.rect = rect;
	}
}
- (float)rectWidth {
	return self.rect.size.width;
}
- (void)setRectHeight:(float)height {
	NSRect rect = self.rect;
	if (height != rect.size.height) {
		rect.size.height = height;
		self.rect = rect;
	}
}
- (float)rectHeight {
	return self.rect.size.height;
}
- (void)setRect:(NSRect)rect {
	float x = self.rect.origin.x;
	if (x != rect.origin.x) {
		self.rectX = x;
	}
	float y = self.rect.origin.y;
	if (y != rect.origin.y) {
		self.rectHeight = y;
	}
	float width = self.rect.size.width;
	if (width != rect.size.width) {
		self.rectWidth = width;
	}
	float height = self.rect.size.height;
	if (height != rect.size.height) {
		self.rectHeight = height;
	}
	self.value = [NSValue valueWithRect:rect];
}
- (NSRect)rect {
	return [self.value rectValue];
}

#pragma mark value

- (void)setValue:(NSValue *)value {
	_value = value;
	[_node setValue:[self reverseTransformedValue] forKeyPath:_name];
}
- (NSValue *)value {
	return _value;
}
- (NSValue *)reverseTransformedValue {
	NSDictionary *bindingInfo = [self infoForBinding: NSValueBinding];

	/* Apply the value transformer, if one has been set */
	NSDictionary* bindingOptions = bindingInfo[NSOptionsKey];
	if(bindingOptions){
		NSValueTransformer* transformer = bindingOptions[NSValueTransformerBindingOption];
		if(transformer && (id)transformer != [NSNull null]){
			if([[transformer class] allowsReverseTransformation]){
				return [transformer reverseTransformedValue:_value];
			}
		}
	}

	return _value;
}

@end
