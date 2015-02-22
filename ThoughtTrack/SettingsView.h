//
//  ContentView.h
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsView : UIView

// properties
@property (nonatomic) UIView *view;

// init
-(instancetype)initWithMenu:(UIView *)menu;
+(instancetype)createWithMenu:(UIView *)menu;

// create
-(UIView *)createWithMenu:(UIView *)menu;

@end
