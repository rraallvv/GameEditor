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

@implementation PointTransformer

+ (NSDictionary *)transformer {
	static NSDictionary *transformer = nil;

	if (transformer) {
		return transformer;
	} else {
		return transformer = @{ NSValueTransformerBindingOption:[[PointTransformer alloc] init] };
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

@implementation DegreesTransformer

+ (NSDictionary *)transformer {
	static NSDictionary *transformer = nil;

	if (transformer) {
		return transformer;
	} else {
		return transformer = @{ NSValueTransformerBindingOption:[[DegreesTransformer alloc] init] };
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

@implementation AttibuteNameTransformer

+ (NSDictionary *)transformer {
	static NSDictionary *transformer = nil;

	if (transformer) {
		return transformer;
	} else {
		return transformer = @{ NSValueTransformerBindingOption:[[AttibuteNameTransformer alloc] init] };
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
	} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
		return @"dd";
	} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
		return @"dddd";
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
		/* Try to get a subindex from the key */
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
		NSTextCheckingResult *result = [regex firstMatchInString:key options:0 range:NSMakeRange(0, key.length)];

		NSString *name = [key substringWithRange:[result rangeAtIndex:1]];
		NSInteger subindex = [[key substringWithRange:[result rangeAtIndex:2]] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

		if ([name isEqualToString:@"label"]) {

			/* The key is a subindex of label */
			return _labels[subindex];

		} else if ([name isEqualToString:@"value"]) {

			/* The key is a subindex of value */

			if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
				CGPoint point = [_value pointValue];
				return @(((CGFloat*)&point)[subindex]);

			} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
				CGSize size = [_value sizeValue];
				return @(((CGFloat*)&size)[subindex]);

			} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
				CGRect rect = [_value rectValue];
				return @(((CGFloat*)&rect)[subindex]);
			}
		}
	}
	return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {

	if ([key isEqualToString:@"value"]) {

		/* Do nothing if the value hasn't changed */
		if ([_value isEqual:value])
			return;

		[self willChangeValueForKey:@"value"];
		_value = value;
		[self didChangeValueForKey:@"value"];

		/* Update the bound object's property value */
		[_node setValue:[self reverseTransformedValue] forKeyPath:_name];

		/* Get a pointer to the raw data if it's a compound value */
		NSInteger componentsCount = 0;
		CGFloat *components = NULL;

		if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
			componentsCount = 2;
			CGPoint point = [[self valueForKey:@"value"] pointValue];
			components = (CGFloat*)&point;

		} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
			componentsCount = 2;
			CGSize size = [[self valueForKey:@"value"] sizeValue];
			components = (CGFloat*)&size;

		} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
			componentsCount = 4;
			CGRect rect = [[self valueForKey:@"value"] rectValue];
			components = (CGFloat*)&rect;
		}

		/* Traverse the value subindexes and update each component */
		for (int index = 0; index < componentsCount; ++index) {
			NSString *valueWithSubindex = [NSString stringWithFormat:@"value%d", index + 1];
			[self willChangeValueForKey:valueWithSubindex];
			[self setValue:@(components[index]) forKey:valueWithSubindex];
			[self didChangeValueForKey:valueWithSubindex];
		}

	} else {

		/* Retrieve the subindex */
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
		NSTextCheckingResult *result = [regex firstMatchInString:key options:0 range:NSMakeRange(0, key.length)];

		NSString *name = [key substringWithRange:[result rangeAtIndex:1]];
		NSInteger subindex = [[key substringWithRange:[result rangeAtIndex:2]] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

		if ([name isEqualToString:@"value"]) {

			/* Update the value component for the given subindex */

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

			} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
				CGRect rect = [[self valueForKey:@"value"] rectValue];
				CGFloat *components = (CGFloat*)&rect;
				components[subindex] = [value floatValue];
				[self setValue:[NSValue valueWithRect:rect] forKey:@"value"];
			}

		} else {

			/* Fall back to the superclass default behavior if the key is not a value */
			[super setValue:value forKey:key];
		}
	}
}

@end
