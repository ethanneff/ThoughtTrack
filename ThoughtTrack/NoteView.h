//
//  NoteView.h
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteView : UIView

// properties
@property (nonatomic) UIView *view;

// init
-(instancetype)initWithMenu:(UIView *)menu withController:(UIViewController *)controller;
+(instancetype)createWithMenu:(UIView *)menu withController:(UIViewController *)controller;

// create
-(UIView *)createWithMenu:(UIView *)menu withController:(UIViewController *)controller;

// helper methods
-(NSString *)getNoteContent;
@end
