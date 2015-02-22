//
//  AlertView.h
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertView : UIView

// properties
@property (nonatomic) UIView *view;

// init
+(instancetype)create;

// create
-(UIView *)create;

@end
