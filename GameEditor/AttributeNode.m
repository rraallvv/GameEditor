/*
 * AttributeNode.m
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

#import "AttributeNode.h"
#import <objc/runtime.h>

#pragma mark NSString

@implementation NSString (Types)
- (NSString *)extractClassName {
	/* Try to get a class name from the type */
	NSRange range = [self rangeOfString:@"(?<=@\")(\\w*)(?=\")" options:NSRegularExpressionSearch];
	return range.location != NSNotFound ? [self substringWithRange:range] : nil;
}
- (Class)classType {
	NSString *className = [self extractClassName];
	if (className) {
		return NSClassFromString(className);
	}
	return nil;
}
- (BOOL)isEqualToEncodedType:(const char*)type {
	NSString *className = [self extractClassName];
	if (className) {
		return [[NSString stringWithFormat:@"{%@=#}", className] isEqualToString:[NSString stringWithUTF8String:type]];
	} else {
		return [self isEqualToString:[NSString stringWithUTF8String:type]];
	}
}
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

@implementation NSString (AttributeName)
- (NSArray *)componentsSeparatedInWords {
	NSMutableArray *substrings = [NSMutableArray array];
	NSMutableString *tempStr = [NSMutableString string];

	for (NSInteger i=0; i<self.length; i++) {
		NSString *ch = [self substringWithRange:NSMakeRange(i, 1)];
		if ([ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound) {
			[substrings addObject:tempStr];
			tempStr = [NSMutableString string];
		} else if ([ch isEqualToString:@"_"]) {
			if (i == 0) {
				continue;
			}
			else {
				[substrings addObject:tempStr];
				tempStr = [NSMutableString string];
			}
		} else if ([ch isEqualToString:@"-"]) {
			[substrings addObject:tempStr];
			tempStr = [NSMutableString string];
		}
		[tempStr appendString:ch];
	}
	if ([tempStr length]) {
		[substrings addObject:tempStr];
	}

	return substrings;
}
@end

#pragma mark NSNumberFormatter

@implementation NSNumberFormatter (CustomFormatters)
+ (instancetype) degreesFormatter {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.negativeFormat = formatter.positiveFormat = @"#.###º";
	return formatter;
}
+ (instancetype)highPrecisionFormatter {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.negativeFormat = formatter.positiveFormat = @"#.###";
	formatter.multiplier = @(0.01);
	return formatter;
}
+ (instancetype)normalPrecisionFormatter {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.negativeFormat = formatter.positiveFormat = @"#.###";
	return formatter;
}
+ (instancetype)normalizedFormatter {
	NSNumberFormatter *formatter = [self highPrecisionFormatter];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.minimum = @(0.0);
	formatter.maximum = @(100.0);
	return formatter;
}
+ (instancetype)integerFormatter {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.roundingIncrement = @(1.0);
	formatter.usesGroupingSeparator = NO;
	return formatter;
}
@end

#pragma mark Value transformers

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

+ (instancetype) transformer {
	return [self valueTransformerForName:NSStringFromClass(self)];
}

@end

@implementation PrecisionTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSNumber class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(value.floatValue*100.0);
							return result;
						}
				 reverseTransformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(value.floatValue*0.01);
							return result;
						}];
}

@end

@implementation DegreesTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSNumber class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(GLKMathRadiansToDegrees(value.floatValue));
							return result;
						}
				 reverseTransformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(GLKMathDegreesToRadians(value.floatValue));
							return result;
						}];
}

@end

@implementation AttributeNameTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSString class]
				  allowsReverseTransformation:NO
						transformedValueBlock:^(id value){
							NSString *string = value;
							NSString * result = [[string componentsSeparatedInWords] componentsJoinedByString:@" "].capitalizedString;
							return result;
						}
				 reverseTransformedValueBlock:nil];
}

@end

#pragma mark AttributeNode

@implementation AttributeNode {
	NSString *_type;
	id _value;
	SKNode *_node;
	BOOL _splitValue;
	NSArray *_splitNames;
}

@synthesize
name = _name,
sensitivity = _sensitivity,
increment = _increment,
formatter = _formatter,
valueTransformer = _valueTransformer,
labels = _labels;

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type formatter:(id)formatter valueTransformer:(id)valueTransformer {
	if (self = [super init]) {
		_name = name;
		_node = node;
		_type = type;
		_sensitivity = 1.0;
		_increment = 1.0;
		_splitValue = NO;
		_formatter = formatter;
		_valueTransformer = valueTransformer;

		/* Prepare the labels and identifier for the editor */
		if ([_type isEqualToEncodedType:@encode(CGPoint)]
			|| [_type isEqualToEncodedType:@encode(CGVector)]) {
			_labels = @[@"X", @"Y"];
		} else if ([_type isEqualToEncodedType:@encode(CGSize)]) {
			_labels = @[@"W", @"H"];
		} else if ([_type isEqualToEncodedType:@encode(CGRect)]) {
			_labels = @[@"X", @"Y", @"W", @"H"];
		}

		/* Bind the property to the 'raw' value if there isn't an accessor */
		if (node) {
			_splitNames = [name componentsSeparatedByString:@","];
			if (_splitNames.count > 1) {
				_name = _splitNames[0];
				_splitValue = YES;
				_value = [NSMutableArray array];
				for (int i=1; i<_splitNames.count; ++i) {
					[_value addObject:[NSNull null]];
					[self bind:[NSString stringWithFormat:@"value%d", i] toObject:node withKeyPath:_splitNames[i] options:nil];
				}

			} else {
				[self bind:@"value" toObject:node withKeyPath:_name options:nil];
			}
		}
	}
	return self;
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type formatter:(id)formatter valueTransformer:(id)valueTransformer {
	return [[AttributeNode alloc] initWithAttributeWithName:name node:node type:type formatter:formatter valueTransformer:valueTransformer];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	return [self attributeWithName:name node:node type:type formatter:nil valueTransformer:nil];
}

+ (instancetype)attributeForColorWithName:(NSString *)name node:(SKNode* )node {
	return [self attributeWithName:name node:node type:@"color"];
}

+ (instancetype)attributeForRotationAngleWithName:name node:(SKNode* )node {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:@"d"
													  formatter:[NSNumberFormatter degreesFormatter]
											   valueTransformer:[DegreesTransformer transformer]];
	attribute.sensitivity = GLKMathRadiansToDegrees(0.001);
	return attribute;
}

+ (instancetype)attributeForHighPrecisionValueWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter highPrecisionFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	attribute.increment = 10.0;
	return attribute;
}

+ (instancetype)attributeForNormalPrecisionValueWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter normalPrecisionFormatter]
											   valueTransformer:nil];
	return attribute;
}

+ (instancetype)attributeForNormalizedValueWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter normalizedFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	attribute.increment = 10.0;
	return attribute;
}

+ (instancetype)attributeForIntegerValueWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter integerFormatter]
											   valueTransformer:nil];
	return attribute;
}

+ (NSDictionary *)attributeForNonEditableValue:(NSString *)name type:(NSString *)type {
	return @{@"name": name,
			 @"value": @"(non-editable)",
			 @"type": @"generic attribute",
			 @"node": [NSNull null],
			 @"description": [NSString stringWithFormat:@"%@\n%@", name, type],
			 @"isLeaf": @YES,
			 @"isEditable": @NO};
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@\n%@", _name, _type];
}

- (NSString *)type {
	return _type;
}

- (BOOL)isEditable {
	return _node != nil;
}

- (BOOL)isLeaf {
	return YES;
}

- (void)dealloc {
	[self unbind:@"value"];
}

#pragma mark Value

- (void)setValue:(id)value {
	/* Do nothing if the value hasn't changed */
	if ([_value isEqual:value])
		return;

	NSAssert(!_splitValue, @"A split value is not replaced, but its subindexes are updated in setValue:forUndefinedKey:");

	_value = value;

	/* Update the bound object's property value */
	[_node setValue:_value forKeyPath:_name];
}

- (id)value {
	return _value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[1];
	NSInteger subindex = [results[2] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"value"]) {

		/* Update the value component for the given subindex */

		if (_splitValue) {
			[_node setValue:value forKeyPath:_splitNames[subindex + 1]];
			self.value[subindex] = value;
		} else {
			if ([_type isEqualToEncodedType:@encode(CGPoint)]
				|| [_type isEqualToEncodedType:@encode(CGSize)]
				|| [_type isEqualToEncodedType:@encode(CGVector)]) {
				CGFloat data[2];
				[self.value getValue:&data];
				data[subindex] = [value floatValue];
				self.value = [NSValue value:&data withObjCType:_type.UTF8String];

			} else if ([_type isEqualToEncodedType:@encode(CGRect)]) {
				CGFloat data[4];
				[self.value getValue:&data];
				data[subindex] = [value floatValue];
				self.value = [NSValue value:&data withObjCType:_type.UTF8String];
			}
		}

	} else {

		/* Fall back to the superclass default behavior if the key is not a value */
		[super setValue:value forUndefinedKey:key];
	}
}

- (id)valueForUndefinedKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[1];
	NSInteger subindex = [results[2] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"label"]) {

		/* The key is a subindex of label */
		return _labels[subindex];

	} else if ([baseKey isEqualToString:@"value"]) {

		/* The key is a subindex of value */

		if (_splitValue) {
			return _value[subindex];
		} else {
			if ([_type isEqualToEncodedType:@encode(CGPoint)]
				|| [_type isEqualToEncodedType:@encode(CGSize)]
				|| [_type isEqualToEncodedType:@encode(CGVector)]) {
				CGFloat data[2];
				[_value getValue:&data];
				return @(data[subindex]);

			} else if ([_type isEqualToEncodedType:@encode(CGRect)]) {
				CGFloat data[4];
				[_value getValue:&data];
				return @(data[subindex]);
			}
		}
	}

	return [super valueForUndefinedKey:key];
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
