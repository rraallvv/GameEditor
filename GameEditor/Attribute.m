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

@interface NSString (Regex)
- (NSArray *)substringsWithRegularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError **)error;
@end

@implementation NSString (Regex)
- (NSArray *)substringsWithRegularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError **)error {
	NSMutableArray *results = [NSMutableArray array];

	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:error];
	NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];

	for (int i = 0; i < [result numberOfRanges]; ++i) {
		[results addObject:[self substringWithRange:[result rangeAtIndex:i]]];
	}

	if (results.count == 0)
		return nil;

	return results;
}
@end

@interface NSValueTransformer (Blocks)
+ (void)initializeWithTransformedValueClass:(Class)class
				allowsReverseTransformation:(BOOL)allowsReverseTransformation
					  transformedValueBlock:(id (^)(id value))transformedValueBlock
			   reverseTransformedValueBlock:(id (^)(id value))reverseTransformedValueBlock;
@end

@implementation NSValueTransformer (Blocks)

+ (void)initializeWithTransformedValueClass:(Class)class
				allowsReverseTransformation:(BOOL)allowsReverseTransformation
					  transformedValueBlock:(id (^)(id value))transformedValueBlock
			   reverseTransformedValueBlock:(id (^)(id value))reverseTransformedValueBlock
{
	if (self != [NSValueTransformer class]) {
		Class metaClass = objc_getMetaClass(class_getName(self));

		SEL selector1 = @selector(transformedValueClass);
		class_addMethod(metaClass,
						selector1,
						imp_implementationWithBlock(^Class {
							return class;
						}),
						method_getTypeEncoding(class_getClassMethod(metaClass, selector1)));


		SEL selector2 = @selector(allowsReverseTransformation);
		class_addMethod(metaClass,
						selector2,
						imp_implementationWithBlock(^BOOL {
							return allowsReverseTransformation;
						}),
						method_getTypeEncoding(class_getClassMethod(metaClass, selector2)));

		SEL selector3 = @selector(transformedValue:);
		class_addMethod(self,
						selector3,
						imp_implementationWithBlock(^id (id __unused _self, id _value){
							return transformedValueBlock(_value);
						}),
						method_getTypeEncoding(class_getInstanceMethod(self, selector3)));

		SEL selector4 = @selector(reverseTransformedValue:);
		class_addMethod(self,
						selector4,
						imp_implementationWithBlock(^id (id __unused _self, id _value){
							return reverseTransformedValueBlock(_value);
						}),
						method_getTypeEncoding(class_getInstanceMethod(self, selector4)));

		[self setValueTransformer:[[self alloc] init] forName:NSStringFromClass(self)];
	}
}

@end

@implementation PointTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSValue class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^(id value){
							return value;
						}
				 reverseTransformedValueBlock:^(id value){
							return [NSValue valueWithPoint:NSPointFromString(value)];
						}];
}

@end

@implementation DegreesTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSNumber class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(value.floatValue*180/M_PI);
							return result;
						}
				 reverseTransformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(value.floatValue*M_PI/180);
							return result;
						}];
}

@end

@implementation AttibuteNameTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSString class]
				  allowsReverseTransformation:NO
						transformedValueBlock:^(id value){
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
				 reverseTransformedValueBlock:nil];
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

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type bindingOptions:(NSDictionary *)bindingOptions {
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
		if(bindingOptions) {
			_valueTransformer = bindingOptions[NSValueTransformerBindingOption];
			if((id)_valueTransformer == [NSNull null])
				_valueTransformer = nil;
		}

		/* Bind the property to the 'raw' value if there isn't an accessor */
		[self bind:@"value" toObject:node withKeyPath:_name options:bindingOptions];
	}
	return self;
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type bindingOptions:(NSDictionary *)bindingOptions {
	return [[Attribute alloc] initWithAttributeWithName:name node:node type:type bindingOptions:bindingOptions];
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

- (void)setValue:(id)value {
	/* Do nothing if the value hasn't changed */
	if ([_value isEqual:value])
		return;

	_value = value;

	/* Update the bound object's property value */
	[_node setValue:[self reverseTransformedValue] forKeyPath:_name];
}

- (id)value {
	return _value;
}

#pragma mark value with subindex

- (void)setValue:(id)value forKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[1];
	NSInteger subindex = [results[2] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"value"]) {

		/* Update the value component for the given subindex */

		if (strcmp(_type.UTF8String, @encode(CGPoint)) == 0) {
			CGPoint point = [self.value pointValue];
			CGFloat *components = (CGFloat*)&point;
			components[subindex] = [value floatValue];
			self.value = [NSValue valueWithPoint:point];

		} else if (strcmp(_type.UTF8String, @encode(CGSize)) == 0) {
			CGSize size = [self.value sizeValue];
			CGFloat *components = (CGFloat*)&size;
			components[subindex] = [value floatValue];
			self.value = [NSValue valueWithSize:size];

		} else if (strcmp(_type.UTF8String, @encode(CGRect)) == 0) {
			CGRect rect = [self.value rectValue];
			CGFloat *components = (CGFloat*)&rect;
			components[subindex] = [value floatValue];
			self.value = [NSValue valueWithRect:rect];
		}

	} else {

		/* Fall back to the superclass default behavior if the key is not a value */
		[super setValue:value forKey:key];
	}
}

- (id)valueForKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[1];
	NSInteger subindex = [results[2] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"label"]) {

		/* The key is a subindex of label */
		return _labels[subindex];

	} else if ([baseKey isEqualToString:@"value"]) {

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

	return [super valueForKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	/* Try to get the key without subindex */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
	NSString *baseKey = results[1];

	if ([baseKey isEqualToString:@"value"]) {
		keyPaths = [keyPaths setByAddingObject:@"value"];
	}

	return keyPaths;
}

@end
