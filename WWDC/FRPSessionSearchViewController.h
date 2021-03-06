//
//  FRPSessionSearchViewController.h
//  WWDC
//
//  Created by Алексей Демедецкий on 29.11.13.
//  Copyright (c) 2013 dalog. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FRPSessionSearchViewModel;

@interface FRPSessionSearchViewController : UIViewController

@property (nonatomic, strong) FRPSessionSearchViewModel* viewModel;

@property (nonatomic, readonly) NSNumber* selectedTitleIndex;

@end
