//
//  Utils.m
//  GameEditor
//

#import "Utils.h"

static NSDictionary *pointToStringTransformer = nil;

@implementation PointToStringTransformer
+ (NSDictionary *)transformer {
	if (pointToStringTransformer) {
		return pointToStringTransformer;
	} else {
		return pointToStringTransformer = @{ NSValueTransformerBindingOption:[[PointToStringTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSString *result = NSStringFromPoint([value pointValue]);
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSValue *result = [NSValue valueWithPoint:NSPointFromString(value)];
	//NSLog(@"<%@", result);
	return result;
}
@end

static NSDictionary *stringToPointTransformer = nil;

@implementation StringToPointTransformer
+ (NSDictionary *)transformer {
	if (stringToPointTransformer) {
		return stringToPointTransformer;
	} else {
		return stringToPointTransformer = @{ NSValueTransformerBindingOption:[[StringToPointTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSValue class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSValue *result = [NSValue valueWithPoint:NSPointFromString(value)];
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSString *result = NSStringFromPoint([value pointValue]);
	//NSLog(@"<%@", result);
	return result;
}
@end

static NSDictionary *stringToDegreesTransformer = nil;

@implementation DegreesTransformer
+ (NSDictionary *)transformer {
	if (stringToDegreesTransformer) {
		return stringToDegreesTransformer;
	} else {
		return stringToDegreesTransformer = @{ NSValueTransformerBindingOption:[[DegreesTransformer alloc] init] };
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
@synthesize propertyName, propertyValue, editable;
+(Property *)propertyWithName:(NSString *)name node:(SKNode* )node type:(NSString *)type {
	Property *property = [[Property alloc] init];
	property.propertyName = name;
	property.node = node;
	property.type = type;

	if ([type isEqualToString:@"point"]) {
		[property bind:@"propertyValue" toObject:node withKeyPath:property.propertyName options:[PointToStringTransformer transformer]];
		[node bind:property.propertyName toObject:property withKeyPath:@"propertyValue" options:[StringToPointTransformer transformer]];
	} else {
		[property bind:@"propertyValue" toObject:node withKeyPath:property.propertyName options:nil];
		[node bind:property.propertyName toObject:property withKeyPath:@"propertyValue" options:nil];
	}

	return property;
}
- (BOOL)editable {
	return YES;
}
- (void)dealloc {
	[self unbind:@"propertyValue"];
	[self.node unbind:self.propertyName];
}
@end
