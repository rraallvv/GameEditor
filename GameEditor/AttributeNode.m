/*
 * AttributeNode.m
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

#import "AttributeNode.h"
#import "ValueTransformers.h"
#import <objc/runtime.h>

#pragma mark AttributeNode

@implementation AttributeNode {
	NSString *_identifier;
	id _value;
	BOOL _splitValue;
	BOOL _structValue;
	NSArray *_splitNames;
	NSMutableArray *_types;
	NSMutableArray *_typeSizes;
	int _typeSize;
	NSMutableData *_data;
	unsigned char *_pdata;
}

@synthesize
name = _name,
node = _node,
children = _children,
formatter = _formatter,
valueTransformer = _valueTransformer,
labels = _labels;

- (instancetype)initWithAttributeWithName:(NSString *)name
									 node:(SKNode *)node
									 identifier:(NSString *)identifier
								formatter:(id)formatter
						 valueTransformer:(id)valueTransformer
								 children:(NSMutableArray *)children
{
	if (self = [super init]) {
		_name = name;
		_node = node;
		_identifier = identifier;
		_splitValue = NO;
		_structValue = NO;
		_formatter = formatter;
		_valueTransformer = valueTransformer;
		_typeSize = 0;
		_children = children;

		/* Bind the property to the 'raw' value if there isn't an accessor */
		[self bindValues];
	}
	return self;
}

- (instancetype)initWithAttributeWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier formatter:(id)formatter valueTransformer:(id)valueTransformer {
	return [self initWithAttributeWithName:name node:node identifier:identifier formatter:formatter valueTransformer:valueTransformer children:nil];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier children:(NSMutableArray *)children {
	return [[AttributeNode alloc] initWithAttributeWithName:name node:node identifier:identifier formatter:nil valueTransformer:nil children:children];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier formatter:(id)formatter valueTransformer:(id)valueTransformer {
	return [[AttributeNode alloc] initWithAttributeWithName:name node:node identifier:identifier formatter:formatter valueTransformer:valueTransformer];
}

+ (instancetype)attributeWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier {
	return [self attributeWithName:name node:node identifier:identifier formatter:nil valueTransformer:nil];
}

+ (instancetype)attributeForColorWithName:(NSString *)name node:(SKNode *)node {
	return [self attributeWithName:name node:node identifier:@"color"];
}

+ (instancetype)attributeForRotationAngleWithName:name node:(SKNode *)node {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node identifier:@"d"
													  formatter:[NSNumberFormatter degreesFormatter]
											   valueTransformer:[DegreesTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForHighPrecisionValueWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node identifier:identifier
													  formatter:[NSNumberFormatter highPrecisionFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForNormalPrecisionValueWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node identifier:identifier
													  formatter:[NSNumberFormatter normalPrecisionFormatter]
											   valueTransformer:nil];
	return attribute;
}

+ (instancetype)attributeForNormalizedValueWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node identifier:identifier
													  formatter:[NSNumberFormatter normalizedFormatter]
											   valueTransformer:[PrecisionTransformer transformer]];
	return attribute;
}

+ (instancetype)attributeForIntegerValueWithName:(NSString *)name node:(SKNode *)node identifier:(NSString *)identifier {
	AttributeNode *attribute = [AttributeNode attributeWithName:name node:node identifier:identifier
													  formatter:[NSNumberFormatter integerFormatter]
											   valueTransformer:nil];
	return attribute;
}

+ (NSDictionary *)attributeForNonEditableValue:(NSString *)name identifier:(NSString *)identifier {
	return @{@"name": name,
			 @"value": @"(non-editable)",
			 @"identifier": @"generic attribute",
			 @"node": [NSNull null],
			 @"description": [NSString stringWithFormat:@"%@\n%@", name, identifier],
			 @"isLeaf": @YES,
			 @"isEditable": @NO};
}

- (void)setNode:(id)node {
	[self unbindValues];
	_node = node;
	[self bindValues];
}

- (id)node {
	return _node;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@\n%@", _name, _identifier];
}

- (NSString *)identifier {
	return _identifier;
}

- (BOOL)isEditable {
	return _node != nil && [self isLeaf];
}

- (BOOL)isLeaf {
	return _children == nil;
}

- (void)bindValues {
	[self willChangeValueForKey:@"isEditable"];

	if (_node) {
		if (_children) {
			[_node addObserver:self forKeyPath:_name options:0 context:NULL];

		} else {
			/* Try to get the separate values of a split value attribute */
			_splitNames = [_name componentsSeparatedByString:@","];
			if (_splitNames.count > 1) {
				_name = _splitNames[0];
				_splitValue = YES;
				_value = [NSMutableArray array];
				/* Initialize and bind each value for the split value attribute */
				for (int i=1; i<_splitNames.count; ++i) {
					[_value addObject:[NSNull null]];
					[self bind:[NSString stringWithFormat:@"value%d", i] toObject:_node withKeyPath:_splitNames[i] options:nil];
				}

			} else {
				/* Try to get the endoced type fields of the struct */
				NSMutableArray *tempArray = [NSMutableArray array];
				NSInteger level = 0;

				_types = [NSMutableArray array];

				for (NSInteger i=0; i<_identifier.length; i++) {
					NSString *ch = [_identifier substringWithRange:NSMakeRange(i, 1)];
					if ([ch isEqualToString:@"{"]) {
						level++;
						tempArray = [NSMutableArray array];
					} else if ([ch isEqualToString:@"="]) {
						tempArray = [NSMutableArray array];
					} else if ([ch isEqualToString:@"}"]) {
						[_types addObjectsFromArray:tempArray];
						tempArray = [NSMutableArray array];
						level--;
					} else {
						[tempArray addObject:ch];
					}
				}

				if (_types.count && level == 0) {
					/* Compute the size of each field and data buffer to hold the struct fields */
					_typeSizes = [NSMutableArray array];

					for (int i = 0; i < _types.count; ++i) {
						[_typeSizes addObject:@(_typeSize)];
						NSUInteger size;
						NSGetSizeAndAlignment([_types[i] UTF8String], &size, NULL);
						_typeSize += size;
					}

					/* Allocate the data buffer to hold the struct fields */
					_data = [NSMutableData dataWithLength:_typeSize];
					_pdata = [_data mutableBytes];

					_structValue = YES;
				}

				/* Bind the struct value */
				[self bind:@"value" toObject:_node withKeyPath:_name options:nil];
			}
		}
	}
	
	[self didChangeValueForKey:@"isEditable"];
}

- (void)unbindValues {
	if (_splitValue) {
		for (int i = 1; i <= [_value count]; ++i) {
			[self unbind:[NSString stringWithFormat:@"value%d", i]];
		}
	} else {
		[self unbind:@"value"];
	}
}

- (void)dealloc {
	if (_children) {
		[_node removeObserver:self forKeyPath:_name];
	} else {
		[self unbindValues];
	}
}

#pragma mark Value

- (id)valueWithCopiedUserData:(id)value {
	/* Copy the custom shader uniforms */
	if ([value isKindOfClass:[SKShader class]]) {
		NSArray *uniforms = [_value uniforms];
		if (uniforms) {
			[value setUniforms:uniforms];
		}
	}
	return value;
}

- (void)setValue:(id)value {
	/* Do nothing if the value hasn't changed */
	if ([_value isEqual:value])
		return;

	NSAssert(!_splitValue, @"A split value is not replaced, but its subindexes are updated in setValue:forUndefinedKey:");

	_value = [self valueWithCopiedUserData:value];

	/* Update the bound object's property value */
	@try {
		[_node setValue:_value forKeyPath:_name];
	}
	@catch (NSException *exception) {
		NSLog(@"Couldn't change property '%@' in %@", _name, _node);
	}
}

- (id)value {
	return _value;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[0];
	NSInteger subindex = [results[1] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"value"]) {
		/* Update the value component for the given subindex */
		if (_splitValue) {
			if (![self.value[subindex] isEqual:value]) {
				self.value[subindex] = value;
				[_node setValue:value forKeyPath:_splitNames[subindex + 1]];
			}
		} else if (_structValue) {
			[self.value getValue:_pdata];
			int offset = [_typeSizes[subindex] intValue];
			const char *objCType = [_types[subindex] UTF8String];
			[(NSNumber *)value getValue:_pdata + offset withObjCType:objCType];
			self.value = [NSValue value:_pdata withObjCType:_identifier.UTF8String];
		}

	} else {

		/* Fall back to the superclass default behavior if the key is not a value */
		[super setValue:value forUndefinedKey:key];
	}
}

- (id)valueForUndefinedKey:(NSString *)key {
	/* Try to get a subindex from the key */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];

	NSString *baseKey = results[0];
	NSInteger subindex = [results[1] integerValue] - 1; // 1-based subindex (label1, value1, etc.)

	if ([baseKey isEqualToString:@"label"]) {
		/* The key is a subindex of label */
		return _labels[subindex];

	} else if ([baseKey isEqualToString:@"value"]) {
		/* The key is a subindex of value */
		if (_splitValue) {
			return _value[subindex];
		} else if (_structValue) {
			[_value getValue:_pdata];
			int offset = [_typeSizes[subindex] intValue];
			const char *objCType = [_types[subindex] UTF8String];
			return [NSNumber numberWithValue:_pdata + offset objCType:objCType];
		}
	}

	if ([super respondsToSelector:@selector(key)]) {
		return [super valueForUndefinedKey:key];
	}

	return nil;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	/* Try to get the key without subindex */
	NSArray *results = [key substringsWithRegularExpressionWithPattern:@"([\\D]+)([\\d]+)" options:0 error:NULL];
	NSString *baseKey = results[0];

	if ([baseKey isEqualToString:@"value"]) {
		keyPaths = [keyPaths setByAddingObject:@"value"];
	}

	return keyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:_name]) {
		id node = [_node valueForKey:_name];
		for (AttributeNode *child in _children) {
			if (child.node != _node) {
				child.node = node;
			}
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
