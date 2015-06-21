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

#pragma mark NSNumber

@implementation NSNumber (CreatingFromArbitraryTypes)
+ numberWithValue:(const void *)aValue objCType:(const char *)aTypeDescription {
	return [[self alloc] initWithValue:aValue objCType:aTypeDescription];
}

- (instancetype)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription {
	if ('^' == *aTypeDescription
		&& nil == aValue) {
		self = nil; // nil should stay nil, even if it's technically a (void *)
	} else {
		switch (*aTypeDescription)
		{
			case _C_CHR: // BOOL, char
				self = [self initWithChar:*(char *)aValue];
				break;
			case _C_UCHR: self = [self initWithUnsignedChar:*(unsigned char *)aValue];
				break;
			case _C_SHT: self = [self initWithShort:*(short *)aValue];
				break;
			case _C_USHT: self = [self initWithUnsignedShort:*(unsigned short *)aValue];
				break;
			case _C_INT: self = [self initWithInt:*(int *)aValue];
				break;
			case _C_UINT: self = [self initWithUnsignedInt:*(unsigned *)aValue];
				break;
			case _C_LNG: self = [self initWithLong:*(long *)aValue];
				break;
			case _C_ULNG: self = [self initWithUnsignedLong:*(unsigned long *)aValue];
				break;
			case _C_LNG_LNG: self = [self initWithLongLong:*(long long *)aValue];
				break;
			case _C_ULNG_LNG: self = [self initWithUnsignedLongLong:*(unsigned long long *)aValue];
				break;
			case _C_FLT: self = [self initWithFloat:*(float *)aValue];
				break;
			case _C_DBL: self = [self initWithDouble:*(double *)aValue];
				break;
			default:
				//NSLog(@"converting unknown format %s", aTypeDescription);
				self = [self initWithBytes:aValue objCType:aTypeDescription];
		}
	}
	return self;
}

- (void)getValue:(void *)value withObjCType:(const char *)aTypeDescription {
	switch (*aTypeDescription)
	{
		case _C_CHR: // BOOL, char
			*(char *)value  = [self charValue];
			break;
		case _C_UCHR: *(unsigned char *)value = [self unsignedCharValue];
			break;
		case _C_SHT: *(short *)value = [self shortValue];
			break;
		case _C_USHT: *(unsigned short *)value = [self unsignedShortValue];
			break;
		case _C_INT: *(int *)value = [self intValue];
			break;
		case _C_UINT: *(unsigned *)value = [self unsignedIntValue];
			break;
		case _C_LNG: *(long *)value = [self longValue];
			break;
		case _C_ULNG: *(unsigned long *)value = [self unsignedLongValue];
			break;
		case _C_LNG_LNG: *(long long *)value = [self longLongValue];
			break;
		case _C_ULNG_LNG: *(unsigned long long *)value = [self unsignedLongLongValue];
			break;
		case _C_FLT: *(float *)value = [self floatValue];
			break;
		case _C_DBL: *(double *)value = [self doubleValue];
			break;
		default:
			[self getValue:value];
	}
}

@end

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

- (BOOL)isEqualToEncodedType:(const char *)type {
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

#if 0 // return all matches
	NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
	for (NSTextCheckingResult *result in matches)
#else
	NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
#endif

	for (int i = 1; i < [result numberOfRanges]; ++i) {
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
	formatter.multiplier = @(0.1);
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
	formatter.negativeFormat = formatter.positiveFormat = @"#.###";
	formatter.minimum = @(0.0);
	formatter.maximum = @(100.0);
	formatter.multiplier = @(0.01);
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
							NSNumber *result = @(GLKMathRadiansToDegrees(value.floatValue)*10.0);
							return result;
						}
				 reverseTransformedValueBlock:^(NSNumber *value){
							NSNumber *result = @(GLKMathDegreesToRadians(value.floatValue*0.1));
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

@implementation TextureTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[SKTexture class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(SKTexture *value){
							NSString *description = [value description];
							NSRange range = [description  rangeOfString:@"(?<=\').*(?=\')" options:NSRegularExpressionSearch];
							if (range.location != NSNotFound) {
								return [[description substringWithRange:range] stringByDeletingPathExtension];
							}
							return nil;
						}
				reverseTransformedValueBlock:^id(NSString *value){
							if (value) {
								return [SKTexture textureWithImageNamed:value];
							}
							return nil;
						}];
}

@end

#pragma mark AttributeNode

@implementation AttributeNode {
	NSString *_type;
	id _value;
	BOOL _splitValue;
	BOOL _structValue;
	NSArray *_splitNames;
	NSMutableArray *_types;
	NSMutableArray *_typeSizes;
	int _typeSize;
	NSMutableData *_data;
	unsigned char *_pdata;
}

@synthesize
name = _name,
node = _node,
children = _children,
formatter = _formatter,
valueTransformer = _valueTransformer,
labels = _labels;

- (instancetype)initWithAttributeWithName:(NSString *)name
									 node:(SKNode *)node
									 type:(NSString *)type
								formatter:(id)formatter
						 valueTransformer:(id)valueTransformer
								 children:(NSMutableArray *)children
{
	if (self = [super init]) {
		_name = name;
		_node = node;
		_type = type;
		_splitValue = NO;
		_structValue = NO;
		_formatter = formatter;
		_valueTransformer = valueTransformer;
		_typeSize = 0;
		_children = children;

		/* Bind the property to the 'raw' value if there isn't an accessor */
		[self bindValues];
	}
	return self;
}

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type formatter:(id)formatter valueTransformer:(id)valueTransformer {
	return [self initWithAttributeWithName:name node:node type:type formatter:formatter valueTransformer:valueTransformer children:nil];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node children:(NSMutableArray *)children {
	return [[AttributeNode alloc] initWithAttributeWithName:name node:node type:nil formatter:nil valueTransformer:nil children:children];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type formatter:(id)formatter valueTransformer:(id)valueTransformer {
	return [[AttributeNode alloc] initWithAttributeWithName:name node:node type:type formatter:formatter valueTransformer:valueTransformer];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type {
	return [self attributeWithName:name node:node type:type formatter:nil valueTransformer:nil];
}

+ (instancetype)attributeForColorWithName:(NSString *)name node:(SKNode *)node {
	return [self attributeWithName:name node:node type:@"color"];
}

+ (instancetype)attributeForRotationAngleWithName:name node:(SKNode *)node {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:@"d"
													  formatter:[NSNumberFormatter degreesFormatter]
											   valueTransformer:[DegreesTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForHighPrecisionValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter highPrecisionFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForNormalPrecisionValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter normalPrecisionFormatter]
											   valueTransformer:nil];
	return attribute;
}

+ (instancetype)attributeForNormalizedValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node type:type
													  formatter:[NSNumberFormatter normalizedFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForIntegerValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type {
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

- (void)setNode:(id)node {
	[self unbindValues];
	_node = node;
	[self bindValues];
}

- (id)node {
	return _node;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@\n%@", _name, _type];
}

- (NSString *)type {
	return _type;
}

- (BOOL)isEditable {
	return _node != nil && [self isLeaf];
}

- (BOOL)isLeaf {
	return _children == nil;
}

- (void)bindValues {
	[self willChangeValueForKey:@"isEditable"];

	if (_node) {
		if (_children) {
			[_node addObserver:self forKeyPath:_name options:0 context:NULL];

		} else {
			/* Try to get the separate values of a split value attribute */
			_splitNames = [_name componentsSeparatedByString:@","];
			if (_splitNames.count > 1) {
				_name = _splitNames[0];
				_splitValue = YES;
				_value = [NSMutableArray array];
				/* Initialize and bind each value for the split value attribute */
				for (int i=1; i<_splitNames.count; ++i) {
					[_value addObject:[NSNull null]];
					[self bind:[NSString stringWithFormat:@"value%d", i] toObject:_node withKeyPath:_splitNames[i] options:nil];
				}

			} else {
				/* Try to get the endoced type fields of the struct */
				NSMutableArray *tempArray = [NSMutableArray array];
				NSInteger level = 0;

				_types = [NSMutableArray array];

				for (NSInteger i=0; i<_type.length; i++) {
					NSString *ch = [_type substringWithRange:NSMakeRange(i, 1)];
					if ([ch isEqualToString:@"{"]) {
						level++;
						tempArray = [NSMutableArray array];
					} else if ([ch isEqualToString:@"="]) {
						tempArray = [NSMutableArray array];
					} else if ([ch isEqualToString:@"}"]) {
						[_types addObjectsFromArray:tempArray];
						tempArray = [NSMutableArray array];
						level--;
					} else {
						[tempArray addObject:ch];
					}
				}

				if (_types.count && level == 0) {
					/* Compute the size of each field and data buffer to hold the struct fields */
					_typeSizes = [NSMutableArray array];

					for (int i = 0; i < _types.count; ++i) {
						[_typeSizes addObject:@(_typeSize)];
						NSUInteger size;
						NSGetSizeAndAlignment([_types[i] UTF8String], &size, NULL);
						_typeSize += size;
					}

					/* Allocate the data buffer to hold the struct fields */
					_data = [NSMutableData dataWithLength:_typeSize];
					_pdata = [_data mutableBytes];

					_structValue = YES;
				}

				/* Bind the struct value */
				[self bind:@"value" toObject:_node withKeyPath:_name options:nil];
			}
		}
	}
	
	[self didChangeValueForKey:@"isEditable"];
}

- (void)unbindValues {
	if (_splitValue) {
		for (int i = 1; i <= [_value count]; ++i) {
			[self unbind:[NSString stringWithFormat:@"value%d", i]];
		}
	} else {
		[self unbind:@"value"];
	}
}

- (void)dealloc {
	if (_children) {
		[_node removeObserver:self forKeyPath:_name];
	} else {
		[self unbindValues];
	}
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

	NSString *baseKey = results[0];
	NSInteger subindex = [results[1] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"value"]) {
		/* Update the value component for the given subindex */
		if (_splitValue) {
			if (![self.value[subindex] isEqual:value]) {
				self.value[subindex] = value;
				[_node setValue:value forKeyPath:_splitNames[subindex + 1]];
			}
		} else if (_structValue) {
			[self.value getValue:_pdata];
			int offset = [_typeSizes[subindex] intValue];
			const char *objCType = [_types[subindex] UTF8String];
			[(NSNumber *)value getValue:_pdata + offset withObjCType:objCType];
			self.value = [NSValue value:_pdata withObjCType:_type.UTF8String];
		}

	} else {

		/* Fall back to the superclass default behavior if the key is not a value */
		[super setValue:value forUndefinedKey:key];
	}
}

- (id)valueForUndefinedKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[0];
	NSInteger subindex = [results[1] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"label"]) {
		/* The key is a subindex of label */
		return _labels[subindex];

	} else if ([baseKey isEqualToString:@"value"]) {
		/* The key is a subindex of value */
		if (_splitValue) {
			return _value[subindex];
		} else if (_structValue) {
			[_value getValue:_pdata];
			int offset = [_typeSizes[subindex] intValue];
			const char *objCType = [_types[subindex] UTF8String];
			return [NSNumber numberWithValue:_pdata + offset objCType:objCType];
		}
	}

	if ([super respondsToSelector:@selector(key)]) {
		return [super valueForUndefinedKey:key];
	}

	return nil;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	/* Try to get the key without subindex */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
	NSString *baseKey = results[0];

	if ([baseKey isEqualToString:@"value"]) {
		keyPaths = [keyPaths setByAddingObject:@"value"];
	}

	return keyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:_name]) {
		id node = [_node valueForKey:_name];
		for (AttributeNode *child in _children) {
			if (child.node != _node) {
				child.node = node;
			}
		}
	}
}

@end
