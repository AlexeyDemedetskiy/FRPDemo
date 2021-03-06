//
//  FRPSessionSearchViewController.m
//  WWDC
//
//  Created by Алексей Демедецкий on 29.11.13.
//  Copyright (c) 2013 dalog. All rights reserved.
//

#import "FRPSessionSearchViewController.h"
#import "FRPSessionSearchViewModel.h"
#import "FRPStringArrayDataSource.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Parus/Parus.h>

@interface FRPSessionSearchViewController()

@property (nonatomic, strong) FRPStringArrayDataSource* dataSource;
@property (nonatomic, strong) FRPStringArrayDataSource* suggestionsDataSource;

@end

@implementation FRPSessionSearchViewController

- (void)loadView
{
    UIView* view = [UIView new]; {
        
        UISearchBar* searchBar = [UISearchBar new]; {
            searchBar.translatesAutoresizingMaskIntoConstraints = NO;
            searchBar.showsCancelButton = YES;
            
            [view addSubview:searchBar];
        }
        UITableView* tableView = [UITableView new]; {
            tableView.translatesAutoresizingMaskIntoConstraints = NO;
            
            [view addSubview:tableView];
        }
        UIView* noDataView = [UIView new]; {
            noDataView.translatesAutoresizingMaskIntoConstraints = NO;
            
            UILabel* message = [UILabel new]; {
                message.translatesAutoresizingMaskIntoConstraints = NO;
                [noDataView addSubview:message];
            }
            
            [noDataView addConstraints:
             PVGroup(@[ PVCenterXOf(message).equalTo.centerXOf(noDataView),
                        PVCenterYOf(message).equalTo.centerYOf(noDataView)
                        ]).asArray];
            
            RAC(message, text) = [RACSignal return:@"Sorry, no data found"];
            
            [view addSubview:noDataView];
        }
        UITableView* suggestionTable = [UITableView new]; {
            suggestionTable.translatesAutoresizingMaskIntoConstraints = NO;
            
            [view addSubview:suggestionTable];
        }
        
        /* Layout UI */ {
            NSArray*(^placeUnderSearch)(UIView*) = ^(UIView* v) {
                NSDictionary* views = NSDictionaryOfVariableBindings(searchBar, v);
                return PVGroup(@[PVVFL(@"H:|[v]|"),
                                 PVVFL(@"V:[searchBar][v]|")]).withViews(views).asArray;
            };
            
            [view addConstraints:
             PVGroup(@[ PVVFL(@"H:|[searchBar]|"),
                        PVTopOf(searchBar).equalTo.topOf(view),
                        placeUnderSearch(tableView),
                        placeUnderSearch(suggestionTable),
                        placeUnderSearch(noDataView)
                        ]).withViews(NSDictionaryOfVariableBindings(searchBar)).asArray];
        }
        
        /* Setup search bar delegates */ {
            RACSignal* cancelSearch = ({
                [self rac_signalForSelector:@selector(searchBarCancelButtonClicked:)
                               fromProtocol:@protocol(UISearchBarDelegate)];
            });
            
            [cancelSearch subscribeNext:^(RACTuple* t) {
                UISearchBar* s = t.first;
                
                [s resignFirstResponder];
            }];
            
            RACSignal* textChange = ({
                [self rac_signalForSelector:@selector(searchBar:textDidChange:)];
            });
            
            RACSignal* newText = [textChange map:^NSString*(RACTuple* t) {
                return t.second;
            }];
            
            searchBar.delegate = (id<UISearchBarDelegate>)self;
            
            RAC(self, viewModel.searchTerm) = newText;
        }
        /* Setup table view callbacks */ {
            self.dataSource = [FRPStringArrayDataSource emptyDataSource];
            RAC(self.dataSource, strings) = RACObserve(self, viewModel.titles);
            [RACObserve(self, dataSource.strings) subscribeNext:^(id _) {
                [tableView reloadData];
            }];
            
            tableView.dataSource = self.dataSource;
            
            RACSignal* didSelectCell = [[self rac_signalForSelector:@selector(tableView:didSelectRowAtIndexPath:)] filter:^BOOL(RACTuple* t) {
                return t.first == tableView;
            }];
            [didSelectCell subscribeNext:^(RACTuple* t) {
                RACTupleUnpack(UITableView* tv, NSIndexPath* ip) = t;
                [tv deselectRowAtIndexPath:ip animated:YES];
            }];
            
            RACSignal* selectedIndex = [didSelectCell map:^id(RACTuple* t) { return @([t.second row]); }];
            RAC(self, selectedTitleIndex) = [selectedIndex flattenMap:^RACStream *(NSNumber* newIndex) {
                return [[RACSignal return:newIndex] concat:[RACSignal return:nil]];
            }];
            
            RAC(self, viewModel.selectedTitleIndex) = [RACObserve(self, selectedTitleIndex) ignore:nil];
            
            tableView.delegate = (id<UITableViewDelegate>)self;
        }
        
        /* Link with suggestion callbacks */ {
            self.suggestionsDataSource = [FRPStringArrayDataSource emptyDataSource];
            RAC(self, suggestionsDataSource.strings) = RACObserve(self, viewModel.suggestions);
            [RACObserve(self, suggestionsDataSource.strings) subscribeNext:^(id _) {
                [suggestionTable reloadData];
            }];
            
            suggestionTable.dataSource = self.suggestionsDataSource;
            
            RACSignal* didSelectCell = [[self rac_signalForSelector:@selector(tableView:didSelectRowAtIndexPath:)] filter:^BOOL(RACTuple* t) {
                return t.first == suggestionTable;
            }];
            [didSelectCell subscribeNext:^(RACTuple* t) {
                RACTupleUnpack(UITableView* tv, NSIndexPath* ip) = t;
                [tv deselectRowAtIndexPath:ip animated:YES];
            }];
            
            RACSignal* selectedWord = [didSelectCell map:^id(RACTuple* t) {
                return @([t.second row]);
            }];
        }
        
        /* Link data with view model */ {
            RACSignal* hasTitles = [RACObserve(self, viewModel.titles)
                                    map:^NSNumber*(NSArray* titles) {
                                        return @(titles.count > 0);
                                    }];
            
            RACSignal* hasSuggestion = [RACObserve(self, viewModel.suggestions)
                                        map:^id(NSArray* suggestions) {
                                            return @(suggestions.count > 0);
                                        }];
            
            RAC(tableView, hidden) = [hasTitles not];
            RAC(noDataView, hidden) = hasTitles;
            RAC(suggestionTable, hidden) = [hasSuggestion not];
        }
    }
    
    [view layoutIfNeeded];
    
    self.view = view;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {}

@end
