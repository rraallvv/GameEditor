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
	Value *result = [Value valueWithPoint:NSPointFromString(value)];
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
	return [Value class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	Value *result = [Value valueWithPoint:NSPointFromString(value)];
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSString *result = NSStringFromPoint([value pointValue]);
	//NSLog(@"<%@", result);
	return result;
}
@end

static NSDictionary *degreesTostringTransformer = nil;

@implementation DegreesToStringTransformer
+ (NSDictionary *)transformer {
	if (degreesTostringTransformer) {
		return degreesTostringTransformer;
	} else {
		return degreesTostringTransformer = @{ NSValueTransformerBindingOption:[[DegreesToStringTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	NSString *result = [[Value numberWithFloat:[value floatValue]*180/M_PI] stringValue];
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	Value *result = [Value numberWithFloat:[value floatValue]*M_PI/180];
	//NSLog(@"<%@", result);
	return result;
}
@end

static NSDictionary *stringToDegreesTransformer = nil;

@implementation StringToDegreesTransformer
+ (NSDictionary *)transformer {
	if (stringToDegreesTransformer) {
		return stringToDegreesTransformer;
	} else {
		return stringToDegreesTransformer = @{ NSValueTransformerBindingOption:[[StringToDegreesTransformer alloc] init] };
	}
}
+ (Class)transformedValueClass {
	return [Value class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}
- (id)transformedValue:(id)value {
	Value *result = [Value numberWithFloat:[value floatValue]*M_PI/180];
	//NSLog(@">%@", result);
	return result;
}
- (id)reverseTransformedValue:(id)value {
	NSString *result = [[Value numberWithFloat:[value floatValue]/M_PI*180] stringValue];
	//NSLog(@"<%@", result);
	return result;
}
@end

@implementation Property
@synthesize key, propertyValue, editable;
+(Property *)propertyWithKey:(NSString *)key node:(SKNode* )node type:(NSString *)type {
	Property *property = [[Property alloc] init];
	property.key = key;
	property.type = type;

	if ([type isEqualToString:@"point"]) {
		[property bind:@"propertyValue" toObject:node withKeyPath:property.key options:[PointToStringTransformer transformer]];
		[node bind:property.key toObject:property withKeyPath:@"propertyValue" options:[StringToPointTransformer transformer]];
	} else if ([type isEqualToString:@"degrees"]) {
		[property bind:@"propertyValue" toObject:node withKeyPath:property.key options:[DegreesToStringTransformer transformer]];
		[node bind:property.key toObject:property withKeyPath:@"propertyValue" options:[StringToDegreesTransformer transformer]];
	} else {
		[property bind:@"propertyValue" toObject:node withKeyPath:property.key options:nil];
		[node bind:property.key toObject:property withKeyPath:@"propertyValue" options:nil];
	}

	return property;
}
- (BOOL)editable {
	return YES;
}
@end
