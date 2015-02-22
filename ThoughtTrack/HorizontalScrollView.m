//
//  HorizontalScrollView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/13/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "HorizontalScrollView.h"

@implementation HorizontalScrollView

// to allow horizontal button scrollviews
- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES;
}

@end
