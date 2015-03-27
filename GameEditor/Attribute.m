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
	id _value;
}

@synthesize
name = _name;

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type options:(NSDictionary *)options {
	if (self = [super init]) {
		_name = name;
		_node = node;
		_type = type;

		/* Prepare the labels and identifier for the editor */
		if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
			_labels = @[@"X", @"Y"];
		} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
			_labels = @[@"W", @"H"];
		} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
			_labels = @[@"X", @"Y", @"W", @"H"];
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
			[self bind:@"value" toObject:node withKeyPath:_name options:options];
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

- (NSString *)editor {
	if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
		return @"dd";
	} else 	if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
		return @"dd";
	}
	return _type;
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

- (void)dealloc {
	[self unbind:@"value"];
}

/* Accessors and Mutators */

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
	[self setValue:[NSValue valueWithRect:rect] forKey:@"value"];
}

- (NSRect)rect {
	return [[self valueForKey:@"value"] rectValue];
}

#pragma mark value

- (NSValue *)reverseTransformedValue {

	/* Apply the value transformer, if one has been set */
	if(_valueTransformer && [[_valueTransformer class] allowsReverseTransformation]) {
		return [_valueTransformer reverseTransformedValue:_value];
	}

	/* Fallback to the untransformed value */
	return _value;
}

- (id)valueForKey:(NSString *)key {
	if ([key isEqualToString:@"value"]) {
		return _value;
	} else {
		/* Retrieve the subindex */
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
		NSTextCheckingResult *result = [regex firstMatchInString:key options:0 range:NSMakeRange(0, key.length)];

		NSString *name = [key substringWithRange:[result rangeAtIndex:1]];
		NSInteger subindex = [[key substringWithRange:[result rangeAtIndex:2]] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

		if ([name isEqualToString:@"label"]) {
			return _labels[subindex];
		} else if ([name isEqualToString:@"value"]) {
			if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
				CGPoint point = [_value pointValue];
				return @(((CGFloat*)&point)[subindex]);
			} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
				CGSize size = [_value sizeValue];
				return @(((CGFloat*)&size)[subindex]);
			} else {
				return [super valueForKey:key];
			}
		} else {
			return [super valueForKey:key];
		}
	}
	return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
	if ([key isEqualToString:@"value"]) {
		if ([_value isEqualToValue:value])
			return;
		_value = value;
		[_node setValue:[self reverseTransformedValue] forKeyPath:_name];

		if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
			CGPoint point = [[self valueForKey:@"value"] pointValue];

			[self willChangeValueForKey:@"value1"];
			[self setValue:@(point.x) forKey:@"value1"];
			[self didChangeValueForKey:@"value1"];

			[self willChangeValueForKey:@"value2"];
			[self setValue:@(point.y) forKey:@"value2"];
			[self didChangeValueForKey:@"value2"];
		} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
			CGSize size = [[self valueForKey:@"value"] sizeValue];

			[self willChangeValueForKey:@"value1"];
			[self setValue:@(size.width) forKey:@"value1"];
			[self didChangeValueForKey:@"value1"];

			[self willChangeValueForKey:@"value2"];
			[self setValue:@(size.height) forKey:@"value2"];
			[self didChangeValueForKey:@"value2"];
		}

	} else {
		/* Retrieve the subindex */
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
		NSTextCheckingResult *result = [regex firstMatchInString:key options:0 range:NSMakeRange(0, key.length)];

		NSString *name = [key substringWithRange:[result rangeAtIndex:1]];
		NSInteger subindex = [[key substringWithRange:[result rangeAtIndex:2]] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

		if ([name isEqualToString:@"value"]) {
			if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
				CGPoint point = [[self valueForKey:@"value"] pointValue];
				CGFloat *components = (CGFloat*)&point;
				components[subindex] = [value floatValue];
				[self setValue:[NSValue valueWithPoint:point] forKey:@"value"];
			} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
				CGSize size = [[self valueForKey:@"value"] sizeValue];
				CGFloat *components = (CGFloat*)&size;
				components[subindex] = [value floatValue];
				[self setValue:[NSValue valueWithSize:size] forKey:@"value"];
			}
		} else {
			[super setValue:value forKey:key];
		}
	}
}

@end
