//
//  Value.m
//  GameEditor
//

#import "Value.h"

@implementation Value {
	NSNumber *_realValue;
}

- (instancetype)initWithValue:(id)value {
	if (self = [super init]) {
		_realValue = value;
	}
	return self;
}

- (instancetype)initWithFloat:(float)value {
	return [self initWithValue:[NSNumber numberWithFloat:value]];
}

- (instancetype)initWithPoint:(NSPoint)value {
	return [self initWithValue:[NSNumber valueWithPoint:value]];
}

+ (instancetype)numberWithFloat:(float)value {
	return [[Value alloc] initWithFloat:value];
}

+ (instancetype)valueWithPoint:(NSPoint)value {
	return [[Value alloc] initWithPoint:value];
}

- (float)floatValue {
	return _realValue.floatValue;
}

- (NSPoint)pointValue {
	return _realValue.pointValue;
}

- (float)x {
	return _realValue.pointValue.x;
}

- (void)setX:(float)value {
	NSPoint point = _realValue.pointValue;
	point.x = value;
	_realValue = (NSNumber *)[NSValue valueWithPoint:point];
}

/*
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _realValue;
}
 */

- (void)getValue:(void *)value {
	[_realValue getValue:value];
}

- (const char *)objCType {
	return [_realValue objCType];
}

@end

@implementation NSString (conversions)
- (NSPoint)pointValue {
	return NSPointFromString(self);
}
@end
