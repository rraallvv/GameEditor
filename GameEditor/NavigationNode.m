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
	NSMutableArray *_childrenNavigationNodes;
}

@synthesize node = _node;

+ (instancetype)navigationNodeWithNode:(id)node {
	NavigationNode *navigationNode = [[NavigationNode alloc] init];
	navigationNode.node = node;
	return navigationNode;
}

- (void)setNode:(id)node {
	_childrenNavigationNodes = [NSMutableArray array];

	for (id child in [node children]) {
		NavigationNode *childNavigationNode = [NavigationNode navigationNodeWithNode:child];
		[_childrenNavigationNodes addObject:childNavigationNode];
	}

	_node = node;
}

- (id)node {
	return _node;
}

- (void)setChildren:(NSMutableArray *)children {
	_childrenNavigationNodes = children;
}

- (NSMutableArray *)children {
	return _childrenNavigationNodes;
}

- (void)setName:(NSString *)name {
	[(SKNode *)self.node setName:name];
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
	return [[_node children] count] == 0;
}

- (BOOL)isEditable {
	return NO;
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

@end
