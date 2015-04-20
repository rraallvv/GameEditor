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

@implementation NavigationNode

@synthesize
node = _node,
name = _name,
children = _childrenNavigationNodes;

+ (instancetype)navigationNodeWithNode:(id)node {
	NavigationNode *navigationNode = [[NavigationNode alloc] init];
	navigationNode.node = node;
	return navigationNode;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		_node = [aDecoder decodeObjectForKey:@"node"];
		_name = [aDecoder decodeObjectForKey:@"name"];
		_childrenNavigationNodes = [aDecoder decodeObjectForKey:@"children"];
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
	NSMutableArray *childNodes = [NSMutableArray array];

	/* Parent the children that have different parent */
	for (NavigationNode *child in children) {
		SKNode *node = [child node];

		[childNodes addObject:node];

		if (node.parent != _node) {
			[node removeFromParent];

#if 0//reposition the child nodes
			CGPoint position = node.position;
			CGFloat zRotation = node.zRotation;

			if (node.parent == node.scene) {
				position = [_node.scene convertPoint:position toNode:_node];
				SKNode *parent = _node;
				while (parent) {
					zRotation -= parent.zRotation;
					parent = parent.parent;
				}
			} else if (_node == _node.scene) {
				position = [_node.scene convertPoint:[_node.scene convertPoint:CGPointZero fromNode:node] toNode:_node];
				SKNode *parent = node.parent;
				while (parent) {
					zRotation += parent.zRotation;
					parent = parent.parent;
				}
			}

			node.position = position;
			node.zRotation = zRotation;
#endif

			[_node addChild:node];
		}
	}

	/* Remove the remaining children, i.e. children without a parent */
	for (SKNode *child in _node.children) {
		if ([childNodes indexOfObject:child] == NSNotFound) {
			[child removeFromParent];
		}
	}

	_childrenNavigationNodes = children;
}

- (NSMutableArray *)children {
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
	} else {
		return [NSImage imageNamed:@"SKNode"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"name"]) {
		self.name = [_node valueForKey:@"name"];
	}
}

- (void)dealloc {
	[_node removeObserver:self forKeyPath:@"name"];
}

@end
