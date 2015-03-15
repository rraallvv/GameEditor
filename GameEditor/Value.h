//
//  Value.h
//  GameEditor
//

#import <Foundation/Foundation.h>

@interface Value : NSNumber
- (instancetype)initWithFloat:(float)value;
- (instancetype)initWithPoint:(NSPoint)value;
+ (instancetype)numberWithFloat:(float)value;
+ (instancetype)valueWithPoint:(NSPoint)value;
- (float)floatValue;
- (NSPoint)pointValue;
- (float)x;
- (void)setX:(float)value;
@end

@interface NSString (conversions)
- (NSPoint)pointValue;
@end
