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

@implementation Attribute {
	NSValueTransformer *_valueTransformer;
	NSArray *_labels;
	NSString *_type;
}

@synthesize
name = _name,
value = _value;

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type options:(NSDictionary *)options {
	if (self = [super init]) {
		_name = name;
		_node = node;
		_type = type;

		/* Prepare the labels and identifier for the editor */
		if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
			_labels = @[@"X", @"Y"];
			//_type = @"dd";
		} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
			_labels = @[@"W", @"H"];
			//_type = @"dd";
		} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
			_labels = @[@"X", @"Y", @"W", @"H"];
			//_type = @"dddd";
		}

		/* Cache the value transformer */
		if(options) {
			_valueTransformer = options[NSValueTransformerBindingOption];
			if((id)_valueTransformer == [NSNull null])
				_valueTransformer = nil;
		}

		/* The property setter method's name */
		NSString *setterStr = [NSString stringWithFormat:@"set%@%@:",
							   [[_name substringToIndex:1] capitalizedString],
							   [_name substringFromIndex:1]];

		/* Bind the property to available accessors */
		if ([self respondsToSelector:NSSelectorFromString(_name)]
			&& [self respondsToSelector:NSSelectorFromString(setterStr)]) {
			[self bind:_name toObject:node withKeyPath:_name options:options];
		} else {
			/* Bind the property to the 'raw' value if there isn't an accessor */
			[self bind:@"value" toObject:node withKeyPath:_name options:options];
		}
	}
	return self;
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type options:(NSDictionary *)options {
	return [[Attribute alloc] initWithAttributeWithName:name node:node type:type options:options];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %@", _name, _type];
}

- (NSString *)type {
	return _type;
}

- (BOOL)isEditable {
	return YES;
}

- (BOOL)isLeaf {
	return YES;
}

- (id)valueForUndefinedKey:(NSString *)key {
	if ([key isEqualToString:@"label1"]) {
		return _labels[0];
	} else if ([key isEqualToString:@"label2"]) {
		return _labels[1];
	} else if ([key isEqualToString:@"label3"]) {
		return _labels[2];
	} else if ([key isEqualToString:@"label4"]) {
		return _labels[3];
	}
	return [super valueForUndefinedKey:key];
}

- (void)dealloc {
	[self unbind:@"value"];
}

/* Accessors and Mutators */

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

	/* Apply the value transformer, if one has been set */
	if(_valueTransformer && [[_valueTransformer class] allowsReverseTransformation]) {
		return [_valueTransformer reverseTransformedValue:_value];
	}

	/* Fallback to the untransformed value */
	return _value;
}

@end
