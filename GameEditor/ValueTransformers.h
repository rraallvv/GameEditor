/*
 * ValueTransformers.h
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

#import <Foundation/Foundation.h>

@interface NSNumber (NumberFromType)
+ numberWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
- (instancetype)initWithValue:(const void *)aValue objCType:(const char *)aTypeDescription;
- (void)getValue:(void *)value withObjCType:(const char *)aTypeDescription;
@end

@interface NSNumberFormatter (CustomFormatters)
+ (instancetype)degreesFormatter;
+ (instancetype)highPrecisionFormatter;
+ (instancetype)normalPrecisionFormatter;
+ (instancetype)normalizedFormatter;
+ (instancetype)integerFormatter;
@end

@interface NSValueTransformer (Blocks)
+ (void)initializeWithTransformedValueClass:(Class)class
allowsReverseTransformation:(BOOL)allowsReverseTransformation
transformedValueBlock:(id (^)(id value))transformedValueBlock
reverseTransformedValueBlock:(id (^)(id value))reverseTransformedValueBlock;
+ (instancetype) transformer;
@end

@interface PrecisionTransformer : NSValueTransformer
@end

@interface DegreesTransformer : NSValueTransformer
@end

@interface AttributeNameTransformer : NSValueTransformer
@end

@interface TextureTransformer : NSValueTransformer
@end

@interface ShaderTransformer : NSValueTransformer
@end

@interface BooleanValidationTransformer : NSValueTransformer
@end

@interface NumberValidationTransformer : NSValueTransformer
@end

@interface StringValidationTransformer : NSValueTransformer
@end

@interface PointValidationTransformer : NSValueTransformer
@end

@interface SizeValidationTransformer : NSValueTransformer
@end

@interface RectValidationTransformer : NSValueTransformer
@end

@interface RangeValidationTransformer : NSValueTransformer
@end

@interface ColorValidationTransformer : NSValueTransformer
@end

@interface ImageValidationTransformer : NSValueTransformer
@end

@interface UserDataTypeTransformer : NSValueTransformer
@end

