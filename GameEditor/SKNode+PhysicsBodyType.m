/*
 * SKNode+PhysicsBodyType.m
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

#import "SKNode+PhysicsBodyType.h"

@implementation SKNode (PhysicsBodyType)

- (void)setBodyType:(NSUInteger)bodyType {
	switch (bodyType) {
			/* None */
		case 1:
			self.physicsBody = nil;
			break;

			/* Bounding Rectangle */
		case 2:
			if ([self respondsToSelector:@selector(size)]) {
				CGSize size = [(id)self size];
				if ([self respondsToSelector:@selector(anchorPoint)]) {
					CGPoint anchorPoint = [(id)self anchorPoint];
					CGPoint center = CGPointMake(size.width * (0.5 - anchorPoint.x), size.height * (0.5 - anchorPoint.y));
					self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size center:center];
				} else {
					self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:[(id)self size]];
				}
			} else {
				self.physicsBody = nil;
			}
			self.physicsBody.dynamic = NO;
			break;

			/* Bounding Circle */
		case 3:
			if ([self respondsToSelector:@selector(size)]) {
				CGSize size = [(id)self size];

				/* Find the a minimum radius that resembles the one shown on Xcode */
				CGFloat minDimension = MIN(size.width, size.height);
				CGFloat maxDimension = MAX(size.width, size.height);
				CGFloat radius = 0.5 * MAX(minDimension, M_SQRT1_2 * maxDimension);

				if ([self respondsToSelector:@selector(anchorPoint)]) {
					CGPoint anchorPoint = [(id)self anchorPoint];
					CGPoint center = CGPointMake(size.width * (0.5 - anchorPoint.x), size.height * (0.5 - anchorPoint.y));
					self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius center:center];
				} else {
					self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius];
				}
			} else {
				self.physicsBody = nil;
			}
			self.physicsBody.dynamic = NO;
			break;

			/* Alpha mask */
		case 4:
			if ([self respondsToSelector:@selector(texture)] && [self respondsToSelector:@selector(size)]) {
				self.physicsBody = [SKPhysicsBody bodyWithTexture:(SKTexture *)[(id)self texture] size:[(id)self size]];
			} else {
				self.physicsBody = nil;
			}
			self.physicsBody.dynamic = NO;
			break;

			/* Path */
		case 5:
			if ([self respondsToSelector:@selector(path)]) {
				self.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:[(SKShapeNode *)self path]];
			}
			self.physicsBody.dynamic = NO;
			break;

			/* Edges */
		case 6:
			if ([self respondsToSelector:@selector(path)]) {
				self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromPath:[(SKShapeNode *)self path]];
			} else {
				self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
			}
			break;

			/* Custom */
		default:
			break;
	};
}

- (NSUInteger)bodyType {
	return self.physicsBody == nil ? 1 : 0;
}

@end
