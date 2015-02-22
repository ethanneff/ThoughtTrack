//
//  LoadView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "LoadView.h"
#import "Config.h"

@implementation LoadView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] init];
    }
    return self;
}

-(instancetype)initWithMenu:(UIView *)menu
{
    self = [super init];
    if (self) {
        [self createWithMenu:menu];
    }
    return self;
}

+(instancetype)createWithMenu:(UIView *)menu {
    return [[self alloc] initWithMenu:menu];
}

#pragma mark - helper methods
-(UIView *)createWithMenu:(UIView *)menu {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height))];
    [self.view setBackgroundColor:[Config sharedInstance].colorSelected];
    
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight+125, [Config sharedInstance].frameWidth, 45)];
    [labelTitle setFont:[UIFont boldSystemFontOfSize:40.0]]; //TODO: font
    [labelTitle setText:@"Thought Tracker"];
    [labelTitle setTextColor:[Config sharedInstance].colorBackground];
    labelTitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:labelTitle];
    
    UILabel *labelSubTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, labelTitle.frame.size.height + labelTitle.frame.origin.y, [Config sharedInstance].frameWidth, 25)];
    [labelSubTitle setFont:[UIFont boldSystemFontOfSize:16.0]]; //TODO: font
    [labelSubTitle setText:@"Collect Organize Prioritize Complete"];
    [labelSubTitle setTextColor:[Config sharedInstance].colorBackground];
    labelSubTitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:labelSubTitle];

    
    return self.view;
}

@end
