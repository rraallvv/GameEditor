/*
 * Attribute.h
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

@interface NSString (Types)
- (BOOL)isEqualToEncodedType:(const char*)type;
@end

@interface PrecisionTransformer : NSValueTransformer
@end

@interface DegreesTransformer : NSValueTransformer
@end

@interface AttibuteNameTransformer : NSValueTransformer
@end

@interface Attribute : NSObject
+ (instancetype)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type;
+ (instancetype)attributeForColorWithName:(NSString *)name node:(SKNode* )node;
+ (instancetype)attributeForRotationAngleWithName:(NSString *)name node:(SKNode* )node;
+ (instancetype)attributeForHighPrecisionWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type;
+ (instancetype)attributeForNormalPrecisionWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type;
+ (instancetype)attributeForNormalizedValueWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type;
@property (copy) NSString *name;
@property id formatter;
@property id valueTransformer;
@property CGFloat sensitivity;
@property CGFloat increment;
@end
