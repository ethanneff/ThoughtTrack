//
//  NoteCreate.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "NoteCreate.h"
#import "Config.h"

@implementation NoteCreate

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] init];
    }
    return self;
}

-(instancetype)initWithMenu:(UIView *)menu withController:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        [self createWithMenu:menu withController:(UIViewController *)controller];
    }
    return self;
}

+(instancetype)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    return [[self alloc] initWithMenu:menu withController:(UIViewController *)controller];
}

#pragma mark - helper methods
-(UIView *)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height))];
    [self.view setBackgroundColor:[Config sharedInstance].colorSelected];
    
    UITextField *txtTitle = [[UITextField alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, [Config sharedInstance].rowHeight)];
    [txtTitle setFont:[UIFont boldSystemFontOfSize:18.0]];
    [txtTitle setTag:71];
    [txtTitle setBackgroundColor:[Config sharedInstance].colorSelected];
    [txtTitle setTextColor:[Config sharedInstance].colorBackground];
    [txtTitle setTintColor:[Config sharedInstance].colorBackground];
    txtTitle.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Note Title..." attributes:@{NSForegroundColorAttributeName:[Config sharedInstance].colorOutline}];
    txtTitle.delegate = (id)controller;
    txtTitle.returnKeyType = UIReturnKeyNext;
    [txtTitle setInputAccessoryView:menu];
    [self.view addSubview:txtTitle];
    
    UIView *titleSpacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    [txtTitle setLeftViewMode:UITextFieldViewModeAlways];
    [txtTitle setLeftView:titleSpacer];
    
    UIView *viewSeparatorBackground = [[UIView alloc] initWithFrame:CGRectMake(0, txtTitle.frame.origin.y+txtTitle.frame.size.height, [Config sharedInstance].frameWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
    [viewSeparatorBackground setBackgroundColor:[Config sharedInstance].colorSelected];
    [self.view addSubview:viewSeparatorBackground];
    
    UIView *viewSeparator = [[UIView alloc] initWithFrame:CGRectMake(([Config sharedInstance].frameWidth-[Config sharedInstance].rowHorizontalBorderWidth)/2, txtTitle.frame.origin.y+txtTitle.frame.size.height, [Config sharedInstance].rowHorizontalBorderWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
    [viewSeparator setBackgroundColor:[Config sharedInstance].colorBackground];
    [self.view addSubview:viewSeparator];
    
    UITextView *txtBody = [[UITextView alloc] initWithFrame:CGRectMake(0, viewSeparator.frame.origin.y+viewSeparator.frame.size.height, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(viewSeparator.frame.origin.y+viewSeparator.frame.size.height))];
    [txtBody setTag:72];
    [txtBody setFont:[UIFont systemFontOfSize:18.0]]; // fix
    [txtBody setBackgroundColor:[Config sharedInstance].colorSelected];
    [txtBody setTextColor:[Config sharedInstance].colorBackground];
    [txtBody setTintColor:[Config sharedInstance].colorBackground];
    txtBody.delegate = (id)controller;
    [txtBody setInputAccessoryView:menu];
    [self.view addSubview:txtBody];

    return self.view;
}


@end
