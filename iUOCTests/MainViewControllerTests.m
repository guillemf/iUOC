//
//  MainViewControllerTests.m
//  iUOC
//
//  Created by Guillem Fernández González on 15/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

// Class under test
#import "MainViewController.h"

// Collaborators
#import "OpenAPI.h"
#import "UOCData.h"

// Test support
#import <SenTestingKit/SenTestingKit.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

@interface MainViewControllerTests : SenTestCase
@end

@implementation MainViewControllerTests
{
	MainViewController *sut;
    OpenAPI *oal;
    UOCData *uds;
}

- (void)setUp
{
    [super setUp];
    oal = mock([OpenAPI class]);
    sut = [[MainViewController alloc] initWithOrigin:oal data:uds];
}

- (void)tearDown
{
    oal = nil;
    sut = nil;
    [super tearDown];
}

- (void)testWhenInitedAuthorisationIsCheched
{
    // given
    
    // when
    [sut view];
    
    // then
    [verify(oal) isUserAuthorised];
}

- (void)testAuthoriseButtonShouldBeConnected
{
    // given
    [sut view];
    
    // then
    assertThat([sut authoriseButton], is(notNilValue()));
}

- (void)testAuthoriseButtonCallsSwithcAuthorisation
{
    // when
    [sut view];
    
    // then
    UIButton *button = [sut authoriseButton];
    assertThat([button actionsForTarget:sut forControlEvent:UIControlEventTouchUpInside],
               contains(@"switchAuthorisation:", nil));
}

- (void)testWhenSwitchButtonIsPessedAuthorisationIsChecked
{
    // given
    [sut view];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verifyCount(oal, atLeastOnce()) isUserAuthorised];
}

- (void)testWhenUserIsAuthorisedSwitchAuthorisationCallsDeauthorise
{
    // given
    [given([oal isUserAuthorised]) willReturnBool:YES];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(oal) deauthorize];
}

- (void)testWhenUserIsAuthorisedSwitchAuthorisationWillChangeButtonImageToDeauthorised
{
    // given
    [sut view];
    [given([oal isUserAuthorised]) willReturnBool:YES];
    UIButton *testAuthoriseButton = mock([UIButton class]);
    [sut setAuthoriseButton:testAuthoriseButton];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(testAuthoriseButton) setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
}

- (void)testWhenUserIsNotAuthorisedSwitchAuthorisationCallsAuthorise
{
    // given
    [given([oal isUserAuthorised]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(oal) authoriseUsingWebView:(id)instanceOf([UIWebView class])];
}

// Web View Tests

- (void)testWhenSwitchAuthorisationCallsAuthoriseWebViewIsCreated
{
    // given
    [given([oal isUserAuthorised]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat([sut authorisationWebView], is(notNilValue()));
}

- (void)testWhenOALStartsAuthorisationItUsesSUTWebView
{
    // given
    [given([oal isUserAuthorised]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(oal) authoriseUsingWebView:sut.authorisationWebView];
}

- (void)testWhenSwitchAuthorisationCallsAuthoriseWebViewIsShown
{
    // given
    [given([oal isUserAuthorised]) willReturnBool:NO];
    [sut view];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat(sut.authorisationWebView.superview, is(equalTo(sut.view)));
}

- (void)testWhenAuthorisationIsDoneWebViewIsDismissed
{
    // given
    [sut view];
    
    // when
    [sut switchAuthorisation:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorisedNotification object:oal];
    
    // then
    assertThat(sut.authorisationWebView.superview, is(nilValue()));
}

- (void)testWhenAuthorisationIsDoneWebViewIsDestroyed
{
    // given
    [sut view];
    
    // when
    [sut switchAuthorisation:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorisedNotification object:oal];
    
    // then
    assertThat([sut authorisationWebView], is(nilValue()));
}

- (void)testWhenSwitchAuthorisationCallsAuthoriseDuringAuthorisationProcessWebViewIsDismissed
{
    // given
    [sut view];
    sut.authorisationWebView = mock([UIWebView class]);
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat(sut.authorisationWebView.superview, is(nilValue()));
}

- (void)testWhenSwitchAuthorisationCallsAuthoriseDuringAuthorisationProcessWebViewIsDestroyed
{
    // given
    [sut view];
    sut.authorisationWebView = mock([UIWebView class]);
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat([sut authorisationWebView], is(nilValue()));
}

// Initial status

- (void)testWhenThereIsNoDataAuthoriseIsCalled
{
    // given
    [sut view];
    
    // when
    
    // then
}
@end
