//
//  Utils.h
//  GameEditor
//

#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <SpriteKit/SpriteKit.h>

#define NSLog(FORMAT, ...) fprintf( stderr, "%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])

@interface PointTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface DegreesTransformer : NSValueTransformer
+ (NSDictionary *)transformer;
@end

@interface Property : NSObject
+(Property *)propertyWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type;
@property (copy) NSString *propertyName;
@property (copy) NSValue *propertyValue;
@property (nonatomic, assign) BOOL editable;
@property (copy) NSString *type;
@property (weak) SKNode *node;
@end
