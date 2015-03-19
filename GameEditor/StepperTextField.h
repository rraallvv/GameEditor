//
//  TextField.h
//  GameEditor
//

#import <Cocoa/Cocoa.h>

IB_DESIGNABLE
@interface StepperTextField : NSTextField
@property (nonatomic) IBInspectable CGFloat increment;
@property (nonatomic, strong) IBInspectable NSImage *increase;
@property (nonatomic, strong) IBInspectable NSImage *alternateInc;
@property (nonatomic, strong) IBInspectable NSImage *decrease;
@property (nonatomic, strong) IBInspectable NSImage *alternateDec;
@property (nonatomic) IBInspectable CGFloat draggingMult;
@end
