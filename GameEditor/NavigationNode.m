/*
 * NavigationNode.h
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

#import "NavigationNode.h"
#import <AppKit/AppKit.h>
#import <SpriteKit/SpriteKit.h>

#pragma mark NavigationNode

@implementation NavigationNode {
	NSPredicate *_filterPredicate;
}

@synthesize
node = _node,
name = _name,
children = _childrenNavigationNodes;

+ (instancetype)navigationNodeWithNode:(id)node {
	if (node) {
		NavigationNode *navigationNode = [[NavigationNode alloc] init];
		navigationNode.node = node;
		return navigationNode;
	}
	return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		_node = [aDecoder decodeObjectForKey:@"node"];
		_name = [aDecoder decodeObjectForKey:@"name"];
		_childrenNavigationNodes = [aDecoder decodeObjectForKey:@"children"];

		[_node addObserver:self forKeyPath:@"name" options:0 context:NULL];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_node forKey:@"node"];
	[aCoder encodeObject:_name forKey:@"name"];
	[aCoder encodeObject:_childrenNavigationNodes forKey:@"children"];
}

- (void)setNode:(id)node {
	_childrenNavigationNodes = [NSMutableArray array];

	for (id child in [node children]) {
		NavigationNode *childNavigationNode = [NavigationNode navigationNodeWithNode:child];
		[_childrenNavigationNodes addObject:childNavigationNode];
	}

	[_node removeObserver:self forKeyPath:@"name"];

	_node = node;

	[_node addObserver:self forKeyPath:@"name" options:0 context:NULL];
}

- (id)node {
	return _node;
}

- (void)setChildren:(NSMutableArray *)children {
	/*
	 Some times SpriteKit store the children of a node in an inmutable array.
	 This quick and dirty fix workarounds that limitation by making the private array
	 a mutable copy of the original
	 */
	id privateChildren = [_node valueForKey:@"_children"];
	if (![privateChildren isKindOfClass:[NSMutableArray class]]) {
		[_node setValue:[privateChildren mutableCopy] forKey:@"_children"];
	}

	/* Clean up all the children before adding the new ones */
	[_node removeAllChildren];

	/* Add the new children */
	for (NavigationNode *child in children) {
		[_node addChild:child.node];
		[child setFilterPredicate:_filterPredicate];
	}

	_childrenNavigationNodes = children;
}

- (NSMutableArray *)children {
	if (_filterPredicate) {
		return (NSMutableArray *)[_childrenNavigationNodes filteredArrayUsingPredicate:_filterPredicate];
	}
	return _childrenNavigationNodes;
}

- (void)setName:(NSString *)name {
	if (![_node.name isEqualToString:name]) {
		[(SKNode *)self.node setName:name];
	}
}

- (NSString *)name {
	if ([_node respondsToSelector:@selector(name)]) {
		NSString *name = [_node name];
		if (name && ![name isEqualToString:@""])
			return name;
	}
	return [NSString stringWithFormat:@"<%@>", [_node className]];
}

- (BOOL)isLeaf {
	return [_childrenNavigationNodes count] == 0;
}

- (BOOL)isEditable {
	return YES;
}

- (NSImage *)image {
	if ([_node isKindOfClass:[SKScene class]]) {
		return [NSImage imageNamed:@"SKScene"];
	} else if ([_node isKindOfClass:[SKShapeNode class]]) {
		return [NSImage imageNamed:@"SKShapeNode"];
	} else if ([_node isKindOfClass:[SKSpriteNode class]]) {
		return [NSImage imageNamed:@"SKSpriteNode"];
	} else if ([_node isKindOfClass:[SKLightNode class]]) {
		return [NSImage imageNamed:@"SKLightNode"];
	} else if ([_node isKindOfClass:[SKEmitterNode class]]) {
		return [NSImage imageNamed:@"SKEmitterNode"];
	} else if ([_node isKindOfClass:[SKLabelNode class]]) {
		return [NSImage imageNamed:@"SKLabelNode"];
	} else if ([_node isKindOfClass:[SKFieldNode class]]) {
		return [NSImage imageNamed:@"SKFieldNode"];
	} else if ([_node isKindOfClass:[SK3DNode class]]) {
		return [NSImage imageNamed:@"SK3DNode"];
	} else {
		return [NSImage imageNamed:@"SKNode"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"name"]) {
		self.name = [_node valueForKey:@"name"];
	}
}

- (void)setFilterPredicate:(NSPredicate *)newFilterPredicate {
	if (_filterPredicate != newFilterPredicate) {
		[self willChangeValueForKey:@"children"];
		_filterPredicate = newFilterPredicate;
		[self didChangeValueForKey:@"children"];
	}
}

- (NSPredicate *)filterPredicate {
	return _filterPredicate;
}

- (void)dealloc {
	[_node removeObserver:self forKeyPath:@"name"];
}

@end
