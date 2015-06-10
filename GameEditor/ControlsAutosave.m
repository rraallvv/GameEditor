/*
 * ControlsAutosave.m
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

#import "ControlsAutosave.h"

#pragma mark Matrix

@implementation Matrix

- (void)awakeFromNib {
	if (self.autosaveName) {
		NSInteger selectedCol = [[[NSUserDefaults standardUserDefaults] valueForKey:self.autosaveKey] integerValue];
		[self selectCellAtRow:0 column:selectedCol];
	}
}

- (NSString *)autosaveKey {
	return [NSString stringWithFormat:@"%@ Selected Button %@", self.class, self.autosaveName];
}

- (NSInteger)selectedColumn {
	NSInteger selectedCol = [super selectedColumn];
	if (self.autosaveName) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:@(selectedCol) forKey:self.autosaveKey];
		[userDefaults synchronize];
	}
	return selectedCol;
}

@end

#pragma mark Button

@implementation Button

- (void)awakeFromNib {
	if (self.autosaveName) {
		NSInteger state = [[[NSUserDefaults standardUserDefaults] valueForKey:self.autosaveKey] integerValue];
		[self setState:state];
	}
}

- (NSString *)autosaveKey {
	return [NSString stringWithFormat:@"%@ Button State %@", self.class, self.autosaveName];
}

- (NSInteger)state {
	NSInteger state = [super state];
	if (self.autosaveName) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:@(state) forKey:self.autosaveKey];
		[userDefaults synchronize];
	}
	return state;
}

@end
