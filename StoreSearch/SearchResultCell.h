//
//  SearchResultCell.h
//  StoreSearch
//
//  Created by Lien Nguyen on 12/3/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *artworkImageView;

@end
