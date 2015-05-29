/*
 * EditorView.h
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

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>

@interface EditorView : NSView

@property (weak) SKNode *node;
@property (weak) SKScene *scene;

@property CGPoint position;
@property CGFloat zRotation;
@property CGSize size;
@property CGPoint anchorPoint;

@property (weak) id delegate;

- (void)updateVisibleRect;

@end

@protocol EditorViewDelegate
- (void)editorView:(EditorView *)editorView didSelectNode:(id)node;
- (NSDragOperation)editorView:(EditorView *)editorView draggingEntered:(id)item;
- (BOOL)editorView:(EditorView *)editorView performDragOperation:(id)item atLocation:(CGPoint)locationInScene;
@end
