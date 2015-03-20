//
//  HandlesView.h
//  GameEditor
//
//  Created by Rhody Lugo on 3/19/15.
//
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>

@protocol HandlesViewDelegate
- (void)selectedNode:(SKNode *)node;
@end

@interface HandlesView : NSView
@property (weak) SKNode *node;
@property (weak) SKScene *scene;
@property CGPoint position;
@property CGFloat zRotation;
@property CGSize size;
@property CGPoint anchorPoint;
@property (weak) id delegate;
@end
