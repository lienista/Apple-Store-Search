//
//  DetailViewController.h
//  StoreSearch
//
//  Created by Lienne Nguyen on 12/5/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchResult;

@interface DetailViewController : UIViewController

    @property (nonatomic, strong) SearchResult *searchResult;

@end
