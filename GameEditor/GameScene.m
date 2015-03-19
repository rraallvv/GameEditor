//
//  GameScene.m
//  GameEditor
//

#import "GameScene.h"

@implementation GameScene {
	SKNode *_draggedNode;
	CGPoint _draggedPoint;
	CGPoint _draggedAnchor;
}

-(void)didMoveToView:(SKView *)view {
	_draggedNode = nil;
}

-(void)mouseDown:(NSEvent *)theEvent {
	_draggedPoint = [theEvent locationInNode:self];
	_draggedNode = [self nodeAtPoint:_draggedPoint];

	if (_draggedNode == self)
		_draggedNode = nil;

	if (_draggedNode)
		_draggedAnchor = CGPointMake(_draggedPoint.x - _draggedNode.position.x, _draggedPoint.y - _draggedNode.position.y);
}

-(void)mouseDragged:(NSEvent *)theEvent {
	_draggedPoint = [theEvent locationInNode:self];
}

-(void)mouseUp:(NSEvent *)theEvent {
	_draggedPoint = [theEvent locationInNode:self];
	_draggedNode = nil;
}

-(void)update:(CFTimeInterval)currentTime {
	if (_draggedNode)
		_draggedNode.position = CGPointMake(_draggedPoint.x - _draggedAnchor.x, _draggedPoint.y - _draggedAnchor.y);
}

@end
