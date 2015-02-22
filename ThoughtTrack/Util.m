//
//  Util.m
//  testevernote
//
//  Created by Ethan Neff on 1/2/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (NSString *)getTimeStr:(int)secondsElapsed {
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed % 3600 / 60;
    int hours   = secondsElapsed / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

+ (NSInteger *)getRandomWithMin:(NSInteger *)min max:(NSInteger *)max {
    return arc4random()%(max-min) + min;
}

+ (UIImage *)getImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (NSString *)getJsonStringByDictionary:(NSDictionary *)dictionary{
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    @catch (NSException *e) {
        return [NSString stringWithFormat:@"JSON parse error: %@", e];
    }
}

+ (NSString *)getNetworkStatus {
    // determine how the user has network connection
    // returns: WiFi, Cellular, No Connection
    Reachability *networkStatus = [Reachability reachabilityWithHostname:@"www.google.com"];
    [networkStatus startNotifier];
    
    return networkStatus.currentReachabilityString;
}

+ (void)showSimpleAlertWithMessage:(NSString *)message; {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

+ (void)showSimpleAlertWithMessage:(NSString *)message andButton:(NSString *)button forSeconds:(float)seconds {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:button, nil];
    [alert show];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissWithClickedButtonIndex:-1 animated:YES];
    });
}

+ (NSString *)cleanString:(NSString *)string {
    return [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
}

+ (BOOL) isArray:(NSArray *)array1 withinArray:(NSArray *)array2 {
    if ([array1 count] == 0 || [array2 count] == 0) return false;
    for (int i = 0; i < [array1 count]; i++) {
        if ([array2 indexOfObject:array1[i]] == NSNotFound)
            return false;
    }
    return true;
}

+ (void) createDropShadowWithView:(UIView *)view zPosition:(int)zPosition down:(BOOL)down {
    float direction = (down) ? zPosition/2.5f : -zPosition/2.5f;
    view.layer.zPosition = zPosition;
    view.layer.shadowOffset = CGSizeMake(0, direction);
    view.layer.shadowColor = [[UIColor blackColor] CGColor];
    view.layer.shadowRadius = zPosition/1.5f;
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:view.layer.bounds] CGPath];
}

@end
