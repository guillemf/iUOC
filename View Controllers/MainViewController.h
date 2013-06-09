//
//  MainViewController.h
//  iUOC
//
//  Created by Guillem Fernández González on 15/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kOAPIBaseURLForUser;
extern NSString * const kOAPIBaseURLForEvents;
extern NSString * const kOAPIBaseURLForClassrooms;

// Internal notifications
extern NSString * const kiUOCMainViewShowError;

@class OpenAPI;
@class UOCData;

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *authorizeButton;
@property (strong, nonatomic) UIWebView *authorisationWebView;

@property (weak, nonatomic) IBOutlet UILabel *currentUserFullName;

- (IBAction)switchAuthorisation:(id)sender;

- (id)initWithOrigin:(OpenAPI *)oal data:(UOCData *)uds;

@end
