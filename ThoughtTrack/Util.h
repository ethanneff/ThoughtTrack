//
//  Util.h
//  testevernote
//
//  Created by Ethan Neff on 1/2/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface Util : NSObject

// class methods (works on all classes) simpilar to convenience constructors vs individual instance methods
+ (NSString *) getTimeStr:(int)secondsElapsed;
+ (NSInteger *) getRandomWithMin:(NSInteger *)min max:(NSInteger *)max;
+ (UIImage *) getImageWithColor:(UIColor *)color;
+ (NSString *) getJsonStringByDictionary:(NSDictionary *)dictionary;
+ (NSString *) getNetworkStatus;
+ (void) showSimpleAlertWithMessage:(NSString *)message;
+ (void) showSimpleAlertWithMessage:(NSString *)message andButton:(NSString *)button forSeconds:(float)seconds;
+ (NSString *) cleanString:(NSString *)string;
+ (BOOL) isArray:(NSArray *)array1 withinArray:(NSArray *)array2;
+ (void) createDropShadowWithView:(UIView *)view zPosition:(int)zPosition down:(BOOL)down;

@end
