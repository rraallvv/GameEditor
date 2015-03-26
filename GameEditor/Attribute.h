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

@implementation SKNode (test)
- (void)setX:(float)value {
	CGPoint point = self.position;
	point.x = value;
	self.position = point;
}
- (float)x {
	return self.position.x;
}
@end

@interface PointTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface DegreesTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface AttibuteNameTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface Attribute : NSObject
+(Attribute *)attributeWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type options:(NSDictionary *)options;
@property (copy) NSString *name;
@property (copy) NSValue *value;
@property (nonatomic, assign) BOOL editable;
@property (copy) NSString *type;
@property (weak) SKNode *node;
@property NSPoint position;
@end
