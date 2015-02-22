//
//  GoalsView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "GoalsView.h"
#import "Config.h"

@implementation GoalsView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] init];
    }
    return self;
}

-(instancetype)initWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self = [super init];
    if (self) {
        [self createWithMenu:menu withController:controller];
    }
    return self;
}

+(instancetype)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    return [[self alloc] initWithMenu:menu withController:controller];
}

#pragma mark - helper methods
-(UIView *)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height))];
    [self.view setBackgroundColor:[Config sharedInstance].colorSelected];
    
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, 40)];
    [labelTitle setFont:[UIFont boldSystemFontOfSize:22.0]];
    [labelTitle setText:@"Goals"];
    [labelTitle setTextColor:[Config sharedInstance].colorBackground];
    labelTitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:labelTitle];

    UITextView *txtBody = [[UITextView alloc] initWithFrame:CGRectMake(0, labelTitle.frame.origin.y+labelTitle.frame.size.height, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(labelTitle.frame.origin.y+labelTitle.frame.size.height))];
    [txtBody setTag:72];
    [txtBody setFont:[UIFont systemFontOfSize:18.0]];
    [txtBody setBackgroundColor:[UIColor clearColor]];
    [txtBody setTextColor:[Config sharedInstance].colorBackground];
    [txtBody setTintColor:[Config sharedInstance].colorBackground];
    [txtBody setInputAccessoryView:menu];
    txtBody.delegate = (id)controller;
    [self.view addSubview:txtBody];
    
    return self.view;
}


@end
