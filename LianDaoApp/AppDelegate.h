//
//  AppDelegate.h
//  smartLianYun
//
//  Created by Steve on 03/08/2017.
//  Copyright © 2017 jianbuwang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) Reachability *reachability;

@end

