/*
 * AttributeNode.h
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

#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <SpriteKit/SpriteKit.h>

@interface NSBundle (ResourcesPath)
- (NSArray *) pathsForResourcesOfType:(NSString *)ext;
@end

@interface NSString (Types)
- (NSString *)extractClassName;
- (Class)classType;
- (BOOL)isEqualToEncodedType:(const char *)type;
@end

@interface NSString (Regex)
- (NSArray *)substringsWithRegularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError **)error;
@end

@interface NSString (AttributeName)
- (NSArray *)componentsSeparatedInWords;
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

@interface AttributeNode : NSObject
+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type children:(NSMutableArray *)children;
+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type formatter:(id)formatter valueTransformer:(id)valueTransformer;
+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type;
+ (instancetype)attributeForColorWithName:(NSString *)name node:(SKNode *)node;
+ (instancetype)attributeForRotationAngleWithName:(NSString *)name node:(SKNode *)node;
+ (instancetype)attributeForHighPrecisionValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type;
+ (instancetype)attributeForNormalPrecisionValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type;
+ (instancetype)attributeForNormalizedValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type;
+ (instancetype)attributeForIntegerValueWithName:(NSString *)name node:(SKNode *)node type:(NSString *)type;
+ (NSDictionary *)attributeForNonEditableValue:(NSString *)name type:(NSString *)type;
@property (copy) NSString *name;
@property id node;
@property (readonly) NSMutableArray *children;
@property id formatter;
@property id valueTransformer;
@property NSArray *labels;
@end
