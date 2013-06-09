//
//  MainViewController.m
//  iUOC
//
//  Created by Guillem Fernández González on 15/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import "MainViewController.h"
#import "OpenAPI.h"
#import "UOCData.h"

NSString * const kOAPIBaseURLForUser = @"/user";
NSString * const kOAPIBaseURLForEvents = @"/calendar/events";
NSString * const kOAPIBaseURLForClassrooms = @"/calendar/classrooms";

NSString * const kiUOCMainViewShowError = @"kiUOCMainViewShowError";

@interface MainViewController ()
{
    OpenAPI *_oal;
    UOCData *_uds;
}
@end

@implementation MainViewController

- (id)initWithOrigin:(OpenAPI *)oal data:(UOCData *)uds
{
    self = [super init];
    
    if (self) {
        _oal = oal;
        _uds = uds;
    }
    
    return  self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set initial authorisation button status
    if ([_oal isUserAuthorized])
        [_authorizeButton setImage:[UIImage imageNamed:@"connected.png"] forState:UIControlStateNormal];
    else
    {
        [_authorizeButton setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
        [self switchAuthorisation:nil];
    }
    
    // Subscribe to notifications 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthorized:) name:kOAPIUserAuthorizedNotification object:_oal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUnAuthorized:) name:kOAPIUserUnAutorizedNotification object:_oal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataFromUOC:) name:kOAPIDataReceivedNotification object:_oal];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newUser:) name:kUOCDNewUserDataAvailable object:_uds];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissWebView {
    [_authorisationWebView removeFromSuperview];

    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _authorisationWebView = nil;
}

- (void)showWebView {
    CGRect webViewFrame = self.view.bounds;
    webViewFrame.origin.y = _authorizeButton.frame.origin.y + _authorizeButton.frame.size.height;
    webViewFrame.size.height -= _authorizeButton.frame.origin.y + _authorizeButton.frame.size.height;
    _authorisationWebView = [[UIWebView alloc] initWithFrame:webViewFrame];
    [self.view addSubview:_authorisationWebView];
}

- (IBAction)switchAuthorisation:(id)sender {
    
    // Are we in the middle of an authorisation process?
    if (_authorisationWebView == nil)
    {
        if ([_oal isUserAuthorized]) {
            [_oal deauthorize];
            [_authorizeButton setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
        } else {
            [self showWebView];
            [_oal authorizeUsingWebView:_authorisationWebView];
        }
    } else {
        [self dismissWebView];  
    }
}

#pragma mark - OpenAPI

- (void)userAuthorized:(NSNotification *)notification
{
    [self dismissWebView];
    NSError *error;
    
    [_oal performGETRequest:kOAPIBaseURLForUser withParameters:nil forId:@"user" notifyOnCompletion:nil error:&error];
    
}

- (void)userUnAuthorized:(NSNotification *)notification
{
    NSError *error;
    if ([_uds deleteUserData:&error]) {
        if ([_uds deleteAllEvents:&error] < 0) {
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"002", @"code",
                                       error, @"original_error",
                                       nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kiUOCMainViewShowError object:self userInfo:errorInfo];
        } else {
            if ([_uds deleteAllClassrooms:&error] < 0) {
                NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"code",
                                           error, @"original_error",
                                           nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kiUOCMainViewShowError object:self userInfo:errorInfo];
            }
            [_authorizeButton setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
            [_currentUserFullName setText:@""];
            [self showWebView];
            [_oal authorizeUsingWebView:_authorisationWebView];
        }
    } else {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"code",
                                   error, @"original_error",
                                   nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kiUOCMainViewShowError object:self userInfo:errorInfo];
    }
}

- (void)newDataFromUOC:(NSNotification *)notification
{
    NSString *dataType = [[notification userInfo] objectForKey:@"requesterid"];
    
    if ([dataType isEqualToString:@"user"]) {
        NSError *error;
        if ([_uds deleteUserData:&error])
            [_uds setUserData:[[notification userInfo] objectForKey:@"data"] error:&error];        
    }
}

#pragma mark - UOCData

- (void)newUser:(NSNotification *)notification
{
    NSDictionary *userData = [_uds getUserData];
    _currentUserFullName.text = [userData objectForKey:@"fullName"];
    [_authorizeButton setImage:[UIImage imageNamed:@"connected.png"] forState:UIControlStateNormal];
}

@end
