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

- (NSMutableArray *)children {
	return _childrenNavigationNodes;
}

- (void)setName:(NSString *)name {
	[(SKNode *)self.node setName:name];
}

- (NSString *)name {
	if ([self.node respondsToSelector:@selector(name)]) {
		NSString *name = [self.node name];
		if (name && ![name isEqualToString:@""])
			return name;
	}
	return [NSString stringWithFormat:@"<%@>", [self.node className]];
}

- (BOOL)isLeaf {
	return [[self.node children] count] == 0;
}

- (BOOL)isEditable {
	return NO;
}

- (NSImage *)image {
	if ([self.node isKindOfClass:[SKScene class]]) {
		return [NSImage imageNamed:@"SKScene"];
	} else if ([self.node isKindOfClass:[SKShapeNode class]]) {
		return [NSImage imageNamed:@"SKShapeNode"];
	} else if ([self.node isKindOfClass:[SKSpriteNode class]]) {
		return [NSImage imageNamed:@"SKSpriteNode"];
	} else if ([self.node isKindOfClass:[SKLightNode class]]) {
		return [NSImage imageNamed:@"SKLightNode"];
	} else if ([self.node isKindOfClass:[SKEmitterNode class]]) {
		return [NSImage imageNamed:@"SKEmitterNode"];
	} else if ([self.node isKindOfClass:[SKLabelNode class]]) {
		return [NSImage imageNamed:@"SKLabelNode"];
	} else if ([self.node isKindOfClass:[SKFieldNode class]]) {
		return [NSImage imageNamed:@"SKFieldNode"];
	} else {
		return [NSImage imageNamed:@"SKNode"];
	}
}

@end
