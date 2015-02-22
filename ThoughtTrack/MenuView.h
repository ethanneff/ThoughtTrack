//
//  NavigationView.h
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(int16_t, SelectionType) {  // make strings into constants (global variables)
    SelectionTypeTagSingle = 0,
    SelectionTypeTagMultiple = 1,
    SelectionTypeNotebookSingle = 2
};

typedef NS_ENUM(int16_t, SearchLocation) {  // make strings into constants (global variables)
    SearchLocationMenu = 0,
    SearchLocationInput = 1
};

@interface MenuView : UIView

// properties
@property (nonatomic) UIView *view;
@property (nonatomic) NSInteger numOfRows;

// init
+(instancetype)createContainer;

// create
-(UIView *)createContainer;

// insert
-(void)insertRowWithSize:(NSInteger)size withSeparator:(BOOL)separator;

// fill
-(void)updateRow:(NSInteger)row withFilters:(NSArray *)filters withSelectionType:(SelectionType)type withController:(UIViewController *)controller; // 0 = single tag, 1 = multiple tag, 2 = notebook
-(void)updateRow:(NSInteger)row withNavigation:(UIViewController *)controller;
-(void)updateRow:(NSInteger)row withSettings:(UIViewController *)controller;
-(void)updateRow:(NSInteger)row withSearch:(SearchLocation)searchLocation withController:(UIViewController *)controller;
-(void)updateRow:(NSInteger)row withCreate:(UIViewController *)controller;

@end
