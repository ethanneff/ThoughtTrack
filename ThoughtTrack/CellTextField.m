//
//  CellTextField.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/18/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "CellTextField.h"

@implementation CellTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x, bounds.origin.y - 6,
                      bounds.size.width, bounds.size.height);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

@end
