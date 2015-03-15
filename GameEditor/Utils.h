//
//  Utils.h
//  GameEditor
//

#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <SpriteKit/SpriteKit.h>
#import "Value.h"

#define NSLog(FORMAT, ...) fprintf( stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])

@interface PointToStringTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface StringToPointTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface DegreesToStringTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface StringToDegreesTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface Property : NSObject
+(Property *)propertyWithKey:(NSString *)key node:(SKNode* )node type:(NSString *)type;
@property (copy) NSString *key;
@property (copy) Value *propertyValue;
@property (nonatomic, assign) BOOL editable;
@property (copy) NSString *type;
@end
