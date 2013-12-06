//
//  SearchResultCell.m
//  StoreSearch
//
//  Created by Lienne Nguyen on 12/3/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import "SearchResultCell.h"
#import "SearchResult.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:CGRectZero];
    selectedView.backgroundColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:0.5f];
    self.selectedBackgroundView = selectedView;
}

- (void)configureForSearchResult:(SearchResult *)searchResult
{
    self.nameLabel.text = searchResult.name;
    NSString *artistName = searchResult.artistName;
    if (artistName == nil) {
        artistName = @"Unknown";
    }
    NSString *kind = [searchResult kindForDisplay];
    //Before, when kind was inside this class: NSString *kind = [self kindForDisplay:searchResult.kind];
    self.artistNameLabel.text = [NSString stringWithFormat: @"%@ (%@)", artistName, kind];
    
    [self.artworkImageView setImageWithURL:[NSURL URLWithString:searchResult.artworkURL60]
                          placeholderImage:[UIImage imageNamed:@"Placeholder"]];

}



- (void)prepareForReuse {
    [super prepareForReuse];
    [self.artworkImageView cancelImageRequestOperation]; self.nameLabel.text = nil;
    self.artistNameLabel.text = nil;
    NSLog(@"Prepare for Reuse");
}

@end
