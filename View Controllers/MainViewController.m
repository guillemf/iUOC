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

    if ([_oal isUserAuthorised])
        [_authoriseButton setImage:[UIImage imageNamed:@"connected.png"] forState:UIControlStateNormal];
    else
        [_authoriseButton setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthorised:) name:kOAPIUserAuthorisedNotification object:_oal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissWebView {
    [_authorisationWebView removeFromSuperview];
    _authorisationWebView = nil;
}

- (void)showWebView {
    CGRect webViewFrame = self.view.bounds;
    webViewFrame.origin.y = _authoriseButton.frame.origin.y + _authoriseButton.frame.size.height;
    webViewFrame.size.height -= _authoriseButton.frame.origin.y + _authoriseButton.frame.size.height;
    _authorisationWebView = [[UIWebView alloc] initWithFrame:webViewFrame];
    [self.view addSubview:_authorisationWebView];
}

- (IBAction)switchAuthorisation:(id)sender {
    
    // Are we in the middle of an authorisation process?
    if (_authorisationWebView == nil)
    {
        if ([_oal isUserAuthorised]) {
            [_oal deauthorize];
            [_authoriseButton setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
        } else {
            [self showWebView];
            [_oal authoriseUsingWebView:_authorisationWebView];
        }
    } else {
        [self dismissWebView];  
    }
}

#pragma mark - OpenAPI

- (void)userAuthorised:(NSNotification *)notification
{
    [self dismissWebView];
}

@end
