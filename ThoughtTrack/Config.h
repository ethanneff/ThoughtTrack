//
//  Config.h
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// global constants
extern NSString *const kTitle;
extern NSString *const kNav0;
extern NSString *const kNav1;
extern NSString *const kNav2;
extern NSString *const kNav3;
extern NSString *const kNav4;

@interface Config : NSObject

// global properties (changing)
// properties (with own getters (prop) and setters (setProp))

// app
@property (nonatomic) BOOL isAppLoaded;
@property (nonatomic) BOOL isAppOpen;
@property (nonatomic) BOOL isAppActive;

// frame
@property (nonatomic) float frameHeight;
@property (nonatomic) float frameWidth;
@property (nonatomic) float statusBarHeight;
@property (nonatomic) float keyboardHeight;

// main navigation
@property (nonatomic) NSArray *navigationTitles;

// colors
@property (nonatomic) BOOL darkmode;
@property (nonatomic) UIColor *colorBackground;
@property (nonatomic) UIColor *colorBackgroundFaded;
@property (nonatomic) UIColor *colorNormal;
@property (nonatomic) UIColor *colorSelected;
@property (nonatomic) UIColor *colorOutline;
@property (nonatomic) UIColor *colorGreen;
@property (nonatomic) UIColor *colorRed;

// rows
@property (nonatomic) float rowHeight;
@property (nonatomic) float rowWidth;
@property (nonatomic) float rowHorizontalBorderHeight;
@property (nonatomic) float rowHorizontalBorderWidth;
@property (nonatomic) float rowTextSize;
@property (nonatomic) BOOL rowVerticalBorder;
@property (nonatomic) float rowVerticalBorderHeight;
@property (nonatomic) float rowVerticalBorderWidth;
@property (nonatomic) float rowTagPadding;
@property (nonatomic) float rowTagTextSize;
@property (nonatomic) float rowTagBorderWidth;
@property (nonatomic) float rowTagBorderRadius;

// cells
@property (nonatomic) float cellWidth;
@property (nonatomic) float cellPadding;
@property (nonatomic) float cellTextSizeTitle;
@property (nonatomic) float cellTextSizeDetail;

// data
@property (nonatomic) float evernoteTimer;

// singleton object
+ (Config *)sharedInstance;


@end