/*
 * ValueTransformers.m
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

#import "ValueTransformers.h"
#import <SpriteKit/SpriteKit.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

#pragma mark NSBundle

@implementation NSBundle (ResourcesPath)

- (NSArray *) pathsForResourcesOfType:(NSString *)ext {
	NSMutableArray *result = [NSMutableArray array];
	NSString *mainbundleResourcesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/"];
	for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh" inDirectory:nil]) {
		if (![path hasPrefix:mainbundleResourcesPath]) {
			[result addObject:path];
		}
	}
	return result;
}

@end

#pragma mark NSObject

@implementation NSObject (DictionaryControllerType)

- (void)setType:(UserDataType)type {
	id result;
	switch (type) {
		case UserDataTypeBoolean:
			result = @NO;
			break;

		case UserDataTypeNumber:
			result = @0;
			break;

		case UserDataTypeString:
		case UserDataTypeLocalizedString:
			result = @"";
			break;

		case UserDataTypePoint:
			result = [NSValue valueWithPoint:NSZeroPoint];
			break;

		case UserDataTypeSize:
			result = [NSValue valueWithSize:NSZeroSize];
			break;

		case UserDataTypeRect:
			result = [NSValue valueWithRect:NSZeroRect];
			break;

		case UserDataTypeRange:
			result = [NSValue valueWithRange:NSMakeRange(0, 0)];
			break;

		case UserDataTypeColor:
			result = [NSColor blueColor];
			break;

		case UserDataTypeImage:
			result = [NSImage imageNamed:NSImageNameInfo];
			break;

		default:
			result = [NSNull null];
			break;
	}
	[(id)self setValue:nil];
	if (result) {
		[(id)self setValue:result];
	}
}

static BOOL isNumber(id value) {
	if (strcmp([value objCType], @encode(int)) == 0
		|| strcmp([value objCType], @encode(double)) == 0) {
		return YES;
	}
	return NO;
}

- (UserDataType)type {
	id value = [(id)self value];

	if ([value isKindOfClass:[NSNumber class]]) {
		if (isNumber(value)) {
			return UserDataTypeNumber;
		}
		return UserDataTypeBoolean;

	} else if ([value isKindOfClass:[NSString class]]) {
		return UserDataTypeString;

	} else if ([value isKindOfClass:[NSValue class]]) {
		const char *type = [value objCType];
		if (strcmp(type, @encode(NSPoint)) == 0) {
			return UserDataTypePoint;

		} else if (strcmp(type, @encode(NSSize)) == 0) {
			return UserDataTypeSize;

		} else if (strcmp(type, @encode(NSRect)) == 0) {
			return UserDataTypeRect;

		} else if (strcmp(type, @encode(NSRange)) == 0) {
			return UserDataTypeRange;
		}

	} else if ([value isKindOfClass:[NSColor class]]) {
		return UserDataTypeColor;

	} else if ([value isKindOfClass:[NSImage class]]) {
		return UserDataTypeImage;
	}
	
	return UserDataTypeNil;
}

@end

#pragma mark NSNumber

@implementation NSNumber (NumberFromType)
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

- (NSString *)stringByReplacingOccurrencesOfRegularExpresion:(NSString *)expresion withString:(NSString *)replacement {
	NSRange range = [self rangeOfString:expresion options:NSRegularExpressionSearch];
	if (range.location != NSNotFound) {
		return [self stringByReplacingCharactersInRange:range withString:replacement];
	}
	return self;
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

@implementation ShaderTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[SKShader class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(SKShader *value){
							for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh"]) {
								NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
								if ([[value source] hash] == [source hash]) {
									return path.lastPathComponent;
								}
							}
							return nil;
						}
				 reverseTransformedValueBlock:^id(NSString *value){
					 if (value) {
						 for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh"]) {
							 if ([[path lastPathComponent] isEqualToString:value]) {
								 NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
								 return [SKShader shaderWithSource:source];
							 }
						 }
						 return nil;
					 }
					 return nil;
				 }];
}

@end

@implementation BooleanValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSNumber class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSNumber class]] && !isNumber(value)) {
								return value;
							}
							return @NO;
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSNumber class]] && !isNumber(value)) {
								return value;
							}
							return @NO;
						}];
}

@end

@implementation NumberValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSNumber class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSNumber class]] && isNumber(value)) {
								return value;
							}
							return @0;
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
								formatter.numberStyle = NSNumberFormatterDecimalStyle;
								NSNumber *result = [formatter numberFromString:value];
								if (result) {
									return result;
								}
							}
							return @0;
						}];
}

@end

@implementation StringValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSString class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return value;
							}
							return @"";
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return value;
							}
							return @"";
						}];
}

@end

@implementation PointValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSValue class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSValue class]] && strcmp([value objCType], @encode(CGPoint)) == 0) {
								return NSStringFromPoint([value pointValue]);
							}
							return @"{0, 0}";
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return [NSValue valueWithPoint:NSPointFromString(value)];
							}
							return [NSValue valueWithPoint:CGPointZero];
						}];
}

@end

@implementation SizeValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSValue class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSValue class]] && strcmp([value objCType], @encode(CGSize)) == 0) {
								return NSStringFromSize([value sizeValue]);
							}
							return @"{0, 0}";
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return [NSValue valueWithSize:NSSizeFromString(value)];
							}
							return [NSValue valueWithSize:CGSizeZero];
						}];
}

@end

@implementation RectValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSValue class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSValue class]] && strcmp([value objCType], @encode(CGRect)) == 0) {
								return NSStringFromRect([value rectValue]);
							}
							return @"{0, 0, 0, 0}";
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return [NSValue valueWithRect:NSRectFromString(value)];
							}
							return [NSValue valueWithRect:CGRectZero];
						}];
}

@end

@implementation RangeValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSValue class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSValue class]] && strcmp([value objCType], @encode(NSRange)) == 0) {
								return NSStringFromRange([value rangeValue]);
							}
							return @"{0, 0}";
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return [NSValue valueWithRange:NSRangeFromString(value)];
							}
							return [NSValue valueWithRange:NSMakeRange(0, 0)];
						}];
}

@end

@implementation ColorValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSColor class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSColor class]]) {
								return value;
							}
							return [NSColor blueColor];
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSColor class]]) {
								return value;
							}
							return [NSColor blueColor];
						}];
}

@end

@implementation ImageValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSImage class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSImage class]]) {
								return value;
							}
							return NSImageNameInfo;
						}
				 reverseTransformedValueBlock:^id(id value){
							if ([value isKindOfClass:[NSString class]]) {
								return [NSImage imageNamed:value];
							}
							return [NSImage imageNamed:NSImageNameInfo];
						}];
}

@end

@implementation NilValidationTransformer

+ (void)initialize {
	[self initializeWithTransformedValueClass:[NSImage class]
				  allowsReverseTransformation:YES
						transformedValueBlock:^id(id value){
							return [NSNull null];
						}
				 reverseTransformedValueBlock:^id(id value){
							return [NSNull null];
						}];
}

@end
