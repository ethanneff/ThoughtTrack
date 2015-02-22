//
//  AlertView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "AlertView.h"
#import "Config.h"
#import "Util.h"

@implementation AlertView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        [self create];
    }
    return self;
}


+(instancetype)create {
    return [[self alloc] init];
}

#pragma mark - helper methods
-(UIView *)create {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, 40)];
    [self.view setBackgroundColor:[Config sharedInstance].colorRed];
    self.view.layer.zPosition = 1000;
    [Util createDropShadowWithView:self.view zPosition:4 down:YES];
    
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, 20)];
    [message setFont:[UIFont boldSystemFontOfSize:12.0]]; // TODO: fix font
    [message setText:@"Warning on all cases of the wrong issue problem..."];
    [message setTextColor:[Config sharedInstance].colorBackground];
    message.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:message];
    
    return self.view;
}

// show alert with color and time

@end
