//
//  Utils.m
//  GameEditor
//

#import "Utils.h"

static NSDictionary *pointTransformer = nil;

@implementation PointTransformer
+ (NSDictionary *)transformer {
	if (pointTransformer) {
		return pointTransformer;
	} else {
		return pointTransformer = @{ NSValueTransformerBindingOption:[[PointTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSValue class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSValue *result = value;
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSValue *result = [NSValue valueWithPoint:NSPointFromString(value)];
	//NSLog(@"<%@", result);
	return result;
}
@end

static NSDictionary *degreesTransformer = nil;

@implementation DegreesTransformer
+ (NSDictionary *)transformer {
	if (degreesTransformer) {
		return degreesTransformer;
	} else {
		return degreesTransformer = @{ NSValueTransformerBindingOption:[[DegreesTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSValue class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSNumber *result = [NSNumber numberWithFloat:[value floatValue]/M_PI*180];
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSNumber *result = [NSNumber numberWithFloat:[value floatValue]*M_PI/180];
	//NSLog(@"<%@", result);
	return result;
}
@end

@implementation Property
@synthesize propertyName = _propertyName, propertyValue = _propertyValue, editable = _editable;
+ (Property *)propertyWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	Property *property = [[Property alloc] init];
	property.propertyName = name;
	property.node = node;
	property.type = type;

	[property bind:@"propertyValue" toObject:node withKeyPath:property.propertyName options:nil];
	[node bind:property.propertyName toObject:property withKeyPath:@"propertyValue" options:nil];

	return property;
}
- (BOOL)editable {
	return YES;
}
- (void)dealloc {
	[self unbind:@"propertyValue"];
	[self.node unbind:self.propertyName];
}
- (void)setX:(float)value {
	NSPoint point = _propertyValue.pointValue;
	point.x = value;
	self.propertyValue = [NSValue valueWithPoint:point];
}
- (float)x {
	return _propertyValue.pointValue.x;
}
@end
