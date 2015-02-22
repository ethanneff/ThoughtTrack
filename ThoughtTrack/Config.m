//
//  Config.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "Config.h"

NSString *const kTitle = @"title";
NSString *const kNav0 = @"Settings";
NSString *const kNav1 = @"Tasks";
NSString *const kNav2 = @"Goals";
NSString *const kNav3 = @"Notes";
NSString *const kNav4 = @"Add";

@implementation Config

// static = this file only
static Config *sharedInstance = nil;

// singleton
+ (Config *)sharedInstance {
    if (sharedInstance == nil) {
        // Thread safe allocation and initialization -> singletone object
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            sharedInstance = [[Config alloc] init];
        });
        [sharedInstance initializeProperties];
    }
    
    return sharedInstance;
}

- (void)initializeProperties {
    // main navigation
    self.navigationTitles = @[@"Settings", @"Tasks", @"Goals", @"Notes", @"Create"]; 
    
    // colors
    self.darkmode = false;
    if (!self.darkmode) {
        self.colorBackground = [UIColor whiteColor];
        self.colorBackgroundFaded = [UIColor colorWithRed:250/255.0f green:250/255.0f blue:250/255.0f alpha:1.0f];
        self.colorNormal = [UIColor blackColor];
        self.colorSelected = [UIColor colorWithRed:52/255.0f green:170/255.0f blue:220/255.0f alpha:1.0f];
    } else {
        self.colorBackground = [UIColor blackColor];
        self.colorBackgroundFaded = [UIColor colorWithRed:15/255.0f green:15/255.0f blue:15/255.0f alpha:1.0f];
        self.colorNormal = [UIColor whiteColor];
        self.colorSelected = [UIColor colorWithRed:230/255.0f green:126/255.0f blue:34/255.0f alpha:1.0f];
    }
    self.colorOutline = [UIColor colorWithRed:200/255.0f green:211/255.0f blue:223/255.0f alpha:1.0f];
    self.colorGreen = [UIColor colorWithRed:46/255.0f green:204/255.0f blue:113/255.0f alpha:1.0f];
    self.colorRed = [UIColor colorWithRed:231/255.0f green:76/255.0f blue:60/255.0f alpha:1.0f];
    

    // screen
    self.frameHeight = [UIScreen mainScreen].bounds.size.height;
    self.frameWidth = [UIScreen mainScreen].bounds.size.width;
    self.statusBarHeight = 20.0f;
    self.keyboardHeight = 0.0f;
    
    // row
    self.rowHeight = 30.0f;
    self.rowWidth = self.frameWidth;
    self.rowHorizontalBorderHeight = 1.0f;
    self.rowHorizontalBorderWidth = self.rowWidth * 0.95f ;
    self.rowTextSize = 25.0;
    self.rowVerticalBorder = false;
    self.rowVerticalBorderHeight = self.rowHeight * 0.70f;
    self.rowVerticalBorderWidth = 1.0f;
    self.rowTagPadding = self.rowHeight*0.275f-5.25f;
    self.rowTagTextSize = self.rowHeight*0.0714f+15.0f;
    self.rowTagBorderWidth = 1.0f;
    self.rowTagBorderRadius = 12.5f;
    
    // cell
    self.cellWidth = self.rowWidth * 0.90f;
    self.cellPadding = 2.0f;
    self.cellTextSizeTitle = self.rowHeight*0.0714f+15.0f;
    self.cellTextSizeDetail = 9.0f;
}

@end

