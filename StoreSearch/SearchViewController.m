//
//  SearchViewController.m
//  StoreSearch
//
//  Created by Lienne Nguyen on 12/2/13.
//  Copyright (c) 2013 Lienne Nguyen. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchResult.h"
#import "SearchResultCell.h"
#import <AFNetworking/AFNetworking.h>
#import "DetailViewController.h"

static NSString * const SearchResultCellIdentifier = @"SearchResultCell";
static NSString * const NothingFoundCellIdentifier = @"NothingFoundCell";
static NSString * const LoadingCellIdentifier = @"LoadingCell";

@interface SearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
    @property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
    @property (nonatomic, weak) IBOutlet UITableView *tableView;
    @property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation SearchViewController
{
    NSMutableArray *_searchResults;
    BOOL _isLoading;
    NSOperationQueue *_queue;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    UINib *cellNib = [UINib nibWithNibName:SearchResultCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:SearchResultCellIdentifier];
    self.tableView.rowHeight = 80;
    
    cellNib = [UINib nibWithNibName:NothingFoundCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:NothingFoundCellIdentifier];
    [self.searchBar becomeFirstResponder];
    
    cellNib = [UINib nibWithNibName:LoadingCellIdentifier bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:LoadingCellIdentifier];
    
    self.tableView.contentInset = UIEdgeInsetsMake(108, 0, 0, 0);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isLoading) {
        return 1;
    } else if (_searchResults == nil) {
        return 0;
    } else if ([_searchResults count] == 0) {
        return 1;
    } else {
        return [_searchResults count];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self performSearch];
}

- (void)performSearch
{
    if ([self.searchBar.text length] > 0) {
        [self.searchBar resignFirstResponder];
        
        [_queue cancelAllOperations];
        
        _isLoading = YES;
        [self.tableView reloadData];
        
        _searchResults = [NSMutableArray arrayWithCapacity:10];
        NSURL *url = [self urlWithSearchText:self.searchBar.text category:self.segmentedControl.selectedSegmentIndex];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [self parseDictionary:responseObject];
            [_searchResults sortUsingSelector:@selector(compareName:)];
            _isLoading = NO;
            [self.tableView reloadData];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (operation.isCancelled) {
                return;
            }
            
            [self showNetworkError];
            _isLoading = NO;
            [self.tableView reloadData];
        }];
        
        [_queue addOperation:operation];
    }
}
- (NSString *)performStoreRequestWithURL:(NSURL *)url {
    
    NSError *error;
    NSString *resultString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if (resultString == nil) {
        NSLog(@"Download Error: %@", error);
        return nil;
    }
    return resultString;
}

- (NSURL *)urlWithSearchText:(NSString *)searchText {
    
    NSString *escapedSearchText = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat: @"http://itunes.apple.com/search?term=%@", escapedSearchText];
    
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

- (NSDictionary *)parseJSON:(NSString *)jsonString {
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id resultObject = [NSJSONSerialization JSONObjectWithData:data
                                                      options:kNilOptions error:&error];
    if (![resultObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"JSON Error: Expected dictionary");
        return nil;
    }
    return resultObject;
}

- (void)parseDictionary:(NSDictionary *)dictionary {
    NSArray *array = dictionary[@"results"];
    
    if (array == nil) {
        NSLog(@"Expected 'results' array");
        return;
    }
    
    for (NSDictionary *resultDict in array) {
        SearchResult *searchResult;
        NSString *kind = resultDict[@"kind"];
        NSString *wrapperType = resultDict[@"wrapperType"];
        
        if ([wrapperType isEqualToString:@"track"]) {
            searchResult = [self parseTrack:resultDict];
        } else if ([wrapperType isEqualToString:@"audiobook"]) {
            searchResult = [self parseAudioBook:resultDict];
        } else if ([wrapperType isEqualToString:@"software"]) {
            searchResult = [self parseSoftware:resultDict];
        } else if ([kind isEqualToString:@"ebook"]) {
            searchResult = [self parseEBook:resultDict];
        }
        if (searchResult != nil) {
            [_searchResults addObject:searchResult];
        }
    }
}

- (SearchResult *)parseTrack:(NSDictionary *)dictionary {
    SearchResult *searchResult = [[SearchResult alloc] init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"trackPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    return searchResult;
}

- (SearchResult *)parseAudioBook:(NSDictionary *)dictionary {
    
    SearchResult *searchResult = [[SearchResult alloc] init];
    searchResult.name = dictionary[@"collectionName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"collectionViewUrl"];
    searchResult.kind = @"audiobook";
    searchResult.price = dictionary[@"collectionPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    return searchResult;
}
- (SearchResult *)parseSoftware:(NSDictionary *)dictionary {
    SearchResult *searchResult = [[SearchResult alloc] init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    return searchResult;
}

- (SearchResult *)parseEBook:(NSDictionary *)dictionary {
    SearchResult *searchResult = [[SearchResult alloc] init];
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = [(NSArray *)dictionary[@"genres"] componentsJoinedByString:@", "];
    return searchResult;
}

- (void)showNetworkError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Whoops..."
                                                        message:@"There was an error reading from the iTunes Store. Please try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_isLoading) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:100];
        
        [spinner startAnimating];
        return cell;
        
    } else if ([_searchResults count] == 0) {
        return [tableView dequeueReusableCellWithIdentifier: NothingFoundCellIdentifier forIndexPath:indexPath];
    } else {
        SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier: SearchResultCellIdentifier forIndexPath:indexPath];
        
        SearchResult *searchResult = _searchResults[indexPath.row];
    
        [cell configureForSearchResult:searchResult];
        return cell;
    }
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     DetailViewController *controller = [[DetailViewController alloc] initWithNibName:
                                         @"DetailViewController" bundle:nil];
    
    SearchResult *searchResult = _searchResults[indexPath.row];
    controller.searchResult = searchResult;
    controller.view.frame = self.view.frame;
    
    [self.view addSubview:controller.view];
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_searchResults count] == 0 || _isLoading) {
        return nil;
    } else {
        return indexPath;
    }
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    if (_searchResults != nil) {
        [self performSearch];
    }
}

- (NSURL *)urlWithSearchText:(NSString *)searchText category:(NSInteger)category
{
    NSString *categoryName; switch (category) {
        case 0: categoryName = @"";
            break;
        case 1: categoryName = @"musicTrack";
            break;
        case 2: categoryName = @"software";
            break;
        case 3: categoryName = @"ebook";
            break;
    }
    NSString *escapedSearchText = [searchText stringByAddingPercentEscapesUsingEncoding:
                                   NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat: @"http://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, categoryName];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

@end