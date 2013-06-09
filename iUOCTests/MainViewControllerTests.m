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
    
    NSInteger errorsShown;
}

- (void)setUp
{
    [super setUp];
    oal = mock([OpenAPI class]);
    uds = mock([UOCData class]);
    sut = [[MainViewController alloc] initWithOrigin:oal data:uds];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showError:) name:kiUOCMainViewShowError object:sut];
}

- (void)tearDown
{
    oal = nil;
    uds = nil;
    sut = nil;
    [super tearDown];
}

#pragma mark - Authorisation/Deauthorisation

- (void)testWhenInitedAuthorisationIsCheched
{
    // given
    
    // when
    [sut view];
    
    // then
    [verifyCount(oal, atLeastOnce()) isUserAuthorized];
}

- (void)testAuthorizeButtonShouldBeConnected
{
    // given
    [sut view];
    
    // then
    assertThat([sut authorizeButton], is(notNilValue()));
}

- (void)testAuthorizeButtonCallsSwithcAuthorisation
{
    // when
    [sut view];
    
    // then
    UIButton *button = [sut authorizeButton];
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
    [verifyCount(oal, atLeastOnce()) isUserAuthorized];
}

- (void)testWhenUserIsAuthorizedSwitchAuthorisationCallsDeauthorize
{
    // given
    [given([oal isUserAuthorized]) willReturnBool:YES];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(oal) deauthorize];
}

- (void)testWhenUserIsAuthorizedSwitchAuthorisationWillChangeButtonImageToUnauthorized
{
    // given
//    [sut view];
    [given([oal isUserAuthorized]) willReturnBool:YES];
    UIButton *testAuthorizeButton = mock([UIButton class]);
    [sut setAuthorizeButton:testAuthorizeButton];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(testAuthorizeButton) setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
}

- (void)testWhenUserIsNotAuthorizedSwitchAuthorisationCallsAuthorize
{
    // given
    [given([oal isUserAuthorized]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verifyCount(oal, atLeastOnce()) authorizeUsingWebView:(id)instanceOf([UIWebView class])];
}

- (void)testWhenUserIsDeathorisedUserDataIsDeleted
{
    // given
    [sut view];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    NSError *error;
    [verify(uds) deleteUserData:&error];
}

- (void)testWhenErrorDeletingUserAfterDeutorizationShouldNotCallDeleteEvents
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:NO];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    [verifyCount(uds, never()) deleteAllEvents:&error];
}

- (void)testOnceUserDeteledAfterDeauthoriztionShouldCallDeleteEvents
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    [verifyCount(uds, atLeastOnce()) deleteAllEvents:&error];
    
}

- (void)showError:(NSNotification *)notification
{
    ++errorsShown;
}

- (void)testWhenErrorDeletingUserAfterDeutorizationShouldSendErrorNotification
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:NO];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    assertThatInteger(errorsShown, is(equalToInteger(1)));
}

- (void)testWhenErrorDeletingEventsAfterDeutorizationShouldNotCallDeleteClassrooms
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    [given([uds deleteAllEvents:&error]) willReturnInteger:-1];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    [verifyCount(uds, never()) deleteAllClassrooms:&error];
}

- (void)testOnceEventsDeteledAfterDeauthoriztionShouldCallDeleteClassrooms
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    [given([uds deleteAllEvents:&error]) willReturnInteger:1];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    [verifyCount(uds, atLeastOnce()) deleteAllClassrooms:&error];
    
}

- (void)testWhenErrorDeletingEventsAfterDeutorizationShouldSendErrorNotification
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    [given([uds deleteAllEvents:&error]) willReturnInt:-1];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    assertThatInteger(errorsShown, is(equalToInteger(1)));
}

- (void)testWhenErrorDeletingClassroomsAfterDeutorizationShouldSendErrorNotification
{
    // given
    [sut view];
    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    [given([uds deleteAllEvents:&error]) willReturnInt:1];
    [given([uds deleteAllClassrooms:&error]) willReturnInt:-1];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];
    
    // then
    assertThatInteger(errorsShown, is(equalToInteger(1)));
}

- (void)testDeauthorisationDoneShouldUpdateUIandCallAuthorizeUsingWebView
{
    // given
    [sut view];
    UIButton *testAuthorizeButton = mock([UIButton class]);
    UILabel *testUserNameLabel = mock([UILabel class]);
    [sut setAuthorizeButton:testAuthorizeButton];
    [sut setCurrentUserFullName:testUserNameLabel];
    NSError *error;
    
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    [given([uds deleteAllEvents:&error]) willReturnInteger:1];
    [given([uds deleteAllClassrooms:&error]) willReturnInteger:1];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:oal];

    // then - Twice because the first one is called un viewDidLoad
    [verifyCount((oal), atLeast(2)) authorizeUsingWebView:(id)instanceOf([UIWebView class])];
    
    [verify(testAuthorizeButton) setImage:[UIImage imageNamed:@"disconnected.png"] forState:UIControlStateNormal];
    
    [verify(testUserNameLabel) setText:@""];

    
}

#pragma mark - Web View

- (void)testWhenSwitchAuthorisationCallsAuthorizeWebViewIsCreated
{
    // given
    [given([oal isUserAuthorized]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat([sut authorisationWebView], is(notNilValue()));
}

- (void)testWhenOALStartsAuthorisationItUsesSUTWebView
{
    // given
    [given([oal isUserAuthorized]) willReturnBool:NO];
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    [verify(oal) authorizeUsingWebView:sut.authorisationWebView];
}

- (void)testWhenSwitchAuthorisationCallsAuthorizeWebViewIsShown
{
    // given
    [given([oal isUserAuthorized]) willReturnBool:NO];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:oal];
    
    // then
    assertThat(sut.authorisationWebView.superview, is(nilValue()));
}

- (void)testWhenAuthorisationIsDoneWebViewIsDestroyed
{
    // given
    [sut view];
    
    // when
    [sut switchAuthorisation:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:oal];
    
    // then
    assertThat([sut authorisationWebView], is(nilValue()));
}

- (void)testWhenSwitchAuthorisationCallsAuthorizeDuringAuthorisationProcessWebViewIsDismissed
{
    // given
    [sut view];
    sut.authorisationWebView = mock([UIWebView class]);
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat(sut.authorisationWebView.superview, is(nilValue()));
}

- (void)testWhenSwitchAuthorisationCallsAuthorizeDuringAuthorisationProcessWebViewIsDestroyed
{
    // given
    [sut view];
    sut.authorisationWebView = mock([UIWebView class]);
    
    // when
    [sut switchAuthorisation:nil];
    
    // then
    assertThat([sut authorisationWebView], is(nilValue()));
}

#pragma mark - Initial Status

- (void)testWhenThereIsNoDataAuthorizeIsCalled
{
    // given
    [given([uds hasUserData]) willReturn:NO];
    
    // when
    [sut view];
    
    // then
    [verify(oal) authorizeUsingWebView:sut.authorisationWebView];
}

- (void)testWhenAuthorisationProcessIsDoneShouldAskForUserData
{
    // given
    [sut view];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:oal];
    NSError __autoreleasing *error = nil;
    
    // then
    [verify(oal) performGETRequest:kOAPIBaseURLForUser withParameters:(id)nilValue() forId:@"user" notifyOnCompletion:(id)nilValue() error:&error];
}

- (void)testWhenUserDataIsReceivedShouldDeletePreviousUserData  
{
    // given
    [sut view];
    NSDictionary *responseData = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"xaracil", @"username"
                                  ,@"Xavi", @"name"
                                  ,@"411603", @"number"
                                  ,@"Xavi Aracil Diaz", @"fullName"
                                  ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                  ,@"ca", @"language"
                                  , nil];
    NSDictionary *notificationData = [NSDictionary dictionaryWithObjectsAndKeys:@"user", @"requesterid"
                                      , responseData, @"data"
                                      , nil];
    NSError *error;
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:oal userInfo:notificationData];

    // then
    [verify(uds) deleteUserData:&error];
}

- (void)testWhenUserDeleteFailedOnUserUpdatingShouldStopAllUpdateOperationsPending
{
    // given
    [sut view];
    NSDictionary *responseData = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"xaracil", @"username"
                                  ,@"Xavi", @"name"
                                  ,@"411603", @"number"
                                  ,@"Xavi Aracil Diaz", @"fullName"
                                  ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                  ,@"ca", @"language"
                                  , nil];
    NSDictionary *notificationData = [NSDictionary dictionaryWithObjectsAndKeys:@"user", @"requesterid"
                                      , responseData, @"data"
                                      , nil];
    NSError *error;
    
    [given([uds deleteUserData:&error]) willReturnBool:NO];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:oal userInfo:notificationData];
    
    // then
    [verifyCount(uds, never()) setUserData:(id)instanceOf([NSDictionary class]) error:&error];
}

- (void)testWhenUserDataIsReceivedShouldBeStored
{
    // given
    [sut view];
    NSDictionary *responseData = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                    ,@"xaracil", @"username"
                                    ,@"Xavi", @"name"
                                    ,@"411603", @"number"
                                    ,@"Xavi Aracil Diaz", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                    ,@"ca", @"language"
                                    , nil];
    NSDictionary *notificationData = [NSDictionary dictionaryWithObjectsAndKeys:@"user", @"requesterid"
                                      , responseData, @"data"
                                      , nil];

    NSError *error;
    [given([uds deleteUserData:&error]) willReturnBool:YES];
    
    // when
     [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:oal userInfo:notificationData];
    
    // then
    [verify(uds) setUserData:(id)instanceOf([NSDictionary class]) error:&error];
}

- (void)testUserNameLabelShouldBeConnected
{
    // given
    [sut view];
    
    // then
    assertThat([sut currentUserFullName], is(notNilValue()));
}


- (void)testWhenNewUserDataIsStoredUIIsUpdated
{
    // given
    [sut view];
    NSDictionary *responseData = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"xaracil", @"username"
                                  ,@"Xavi", @"name"
                                  ,@"411603", @"number"
                                  ,@"Xavi Aracil Diaz", @"fullName"
                                  ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                  ,@"ca", @"language"
                                  , nil];
    
    [given([uds getUserData]) willReturn:responseData];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:kUOCDNewUserDataAvailable object:uds];
    
    // then
    assertThat([[sut currentUserFullName] text], is(equalTo(@"Xavi Aracil Diaz")));
}

//- (void)testWhenAuthorisationPocessIsDoneShouldAskForEvents
//{
//    // given
//    [sut view];
//    
//    // when
//    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:oal];
//    
//    NSError __autoreleasing *error = nil;
//    
//    // then
//    [verify(oal) performGETRequest:kOAPIBaseURLForEvents withParameters:(id)nilValue() forId:@"events" notifyOnCompletion:(id)nilValue() error:&error];
//}
//
//- (void)testWhenAuthorisationPocessIsDoneShouldAskForClassrooms
//{
//    // given
//    [sut view];
//    
//    // when
//    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:oal];
//    
//    NSError __autoreleasing *error = nil;
//    
//    // then
//    [verify(oal) performGETRequest:kOAPIBaseURLForClassrooms withParameters:(id)nilValue() forId:@"classrooms" notifyOnCompletion:(id)nilValue() error:&error];
//}
//
//- (void)testWhenNewEventsDataIsReceivedShouldBeStored
//{
//    // given
//    [sut view];
//    
//    NSDictionary *responseData = [NSDictionary dictionaryWithObjectsAndKeys:@"requestID", @"events", nil];
//    // when
//     [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:oal userInfo:responseData];
//    
//    // then
//    [verifyCount(uds, atLeastOnce()) isUserAuthorized];
//
//}
@end
