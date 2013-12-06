//
//  AppDelegate.h
//  StoreSearch
//
//  Created by Lienne Nguyen on 12/2/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

    @property (strong, nonatomic) UIWindow *window;
    @property (strong, nonatomic) SearchViewController *searchViewController;

@end