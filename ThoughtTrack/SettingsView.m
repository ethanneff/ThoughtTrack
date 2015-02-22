//
//  ContentView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "SettingsView.h"
#import "Config.h"

@implementation SettingsView

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
    
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, 40)];
    [labelTitle setFont:[UIFont boldSystemFontOfSize:22.0]];
    [labelTitle setText:@"Settings"];
    [labelTitle setTextColor:[Config sharedInstance].colorBackground];
    labelTitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:labelTitle];
    
    return self.view;
}

@end
