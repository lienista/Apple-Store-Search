//
//  SearchResult.m
//  StoreSearch
//
//  Created by Lien Nguyen on 12/3/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import "SearchResult.h"

@implementation SearchResult

- (NSComparisonResult)compareName:(SearchResult *)other {
    return [self.name localizedStandardCompare:other.name];
}

@end
