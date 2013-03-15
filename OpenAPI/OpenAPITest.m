//
//  OpenAPITest.m
//  iUOC
//
//  Created by Guillem Fernández González on 08/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

// Class under test
#import "OpenAPI.h"
// Test support
#import <SenTestingKit/SenTestingKit.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#define kTestTEC @"testTokenExchangeCalledNotification"

@implementation OpenAPI(test)

- (void)accessTokenExchange:(NSString *)code
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kTestTEC object:self];
}

@end

@interface OpenAPITest : SenTestCase
@end

@implementation OpenAPITest
{
	OpenAPI *sut;
    NSUserDefaults *usDef;
    NSMutableData *testData;
    int openAPIErrors;
    NSDictionary *jsonArray;
    BOOL bInvalidToken;
    BOOL tokenNotificationCalled;
}

- (void)setUp
{
    [super setUp];
    usDef = mock([NSUserDefaults class]);
    sut = [[OpenAPI alloc] initWithParams:usDef];
    testData = [[@"Hello" dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    sut.receivedData = testData;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kOAPIOfflineErrorNotification object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kOAPIAuthorisationErrorNotification object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kOAPIErrorNotification object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataReceived:) name:kOAPIDataReceivedNotification object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidToken:) name:kOAPIInvalidTokenNotification object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenNotificationCalled:) name:kTestTEC object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenNotificationCalled:) name:kOAPIUserAuthorisedNotification object:sut];
    
}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    usDef = nil;
    sut = nil;
    [super tearDown];
}

- (void)testWhenAskedForUserAuthorisedTokenIsRequested
{
    // when
    [sut isUserAuthorised];
    // then
    [verify(usDef) objectForKey:kOAPIUserToken];
}

- (void)testWhenTokenDoesntExistsIsUserAuthorisedReturnsNO
{
    // given
    [given([usDef objectForKey:kOAPIUserToken]) willReturn:nil];
    
    // then
    assertThatBool([sut isUserAuthorised], equalToBool(NO));
}

- (void)testWhenTokenExistsIsUserAuthorisedReturnsYES
{
    // given
    [given([usDef objectForKey:kOAPIUserToken]) willReturn:notNilValue()];
    
    // then
    assertThatBool([sut isUserAuthorised], equalToBool(YES));
}

- (void)testWhenUserIsNotAuthorisedRequestWillReturnError
{
    // given
    [given([usDef objectForKey:kOAPIUserToken]) willReturn:nil];
    NSError *error;
    
    // when
    [sut performGETRequest:nil withParameters:nil forId:nil notifyOnCompletion:nil error:&error];
    
    // then
    assertThat(error, notNilValue());

}

- (void)testWhenAuthorisationWithWebViewIsStartedLoadRequestIsCalled
{
    // given
    UIWebView *webView = mock([UIWebView class]);
    
    // when
    [sut authoriseUsingWebView:webView];
    
    // then
    [verify(webView) loadRequest:(id)instanceOf([NSURLRequest class])];
}

- (void)testErrorOnWebViewForAuthorisationSendsNotification
{
    // given
    UIWebView *testWV = mock([UIWebView class]);
    NSError *error = [[NSError alloc] initWithDomain:kOAPIErrorDomain code:0 userInfo:nil];
    
    // when
    [sut webView:testWV didFailLoadWithError:error];
    
    // then
    assertThatInt(openAPIErrors, is(equalTo(@1)));
}

- (void)testNavigationToURLAreAllowedWhenURLIsNotRedirectURL
{
    // given
    UIWebView *testWV = mock([UIWebView class]);
    NSURLRequest *newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"www.google.com"]];

    // then
    assertThatBool([sut webView:testWV shouldStartLoadWithRequest:newRequest navigationType:1], is(equalToBool(YES)));
}

- (void)testNavigationToURLIsNotAllowedWhenURLIsRedirectURL
{
    // given
    UIWebView *testWV = mock([UIWebView class]);
    NSURLRequest *newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:kOAuthRedirectURL]];
    
    // then
    assertThatBool([sut webView:testWV shouldStartLoadWithRequest:newRequest navigationType:1], is(equalToBool(NO)));
}

- (void)testWhenNoRequestCodeIsReceivedWithRedirectionURLNotificationErrorIsSent
{
    // given
    UIWebView *testWV = mock([UIWebView class]);
    NSURLRequest *newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:kOAuthRedirectURL]];
    
    // when
    [sut webView:testWV shouldStartLoadWithRequest:newRequest navigationType:1];
    
    // then
    assertThatInt(openAPIErrors, is(equalTo(@1)));    
}

- (void)tokenNotificationCalled:(NSNotification *)notification
{
    tokenNotificationCalled = YES;
}

- (void)testRequestCodeInRedirectionURLCallsAccessTokenExchange
{
    // given
    UIWebView *testWV = mock([UIWebView class]);
    NSURLRequest *newRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?code=12345",kOAuthRedirectURL]]];

    // when
    [sut webView:testWV shouldStartLoadWithRequest:newRequest navigationType:1];

    // then
    assertThatBool(tokenNotificationCalled, is(equalToBool(YES)));
    
}

- (void)testReceivedDataRemovedWhenANewResponseIsReceived
{
    // when
    [sut connection:nil didReceiveResponse:nil];
    // then
    assertThat  (sut.receivedData, equalTo(nil));
}

- (void)testDataFromConnectionGetsAppendedToReceivedData
{
    // given
    NSData *extraData = [@" world!" dataUsingEncoding: NSUTF8StringEncoding];
    
    // when
    [sut connection: nil didReceiveData: extraData];
    NSString *completeText = [[NSString alloc] initWithBytes: [sut.receivedData bytes]
                                                      length: [sut.receivedData length]
                                                    encoding: NSUTF8StringEncoding];
    
    // then
    assertThat(completeText, equalTo(@"Hello world!"));
}

- (void)errorNotification:(NSNotification *)notification
{
    ++openAPIErrors;
}

- (void)testNotificationIsSentWhenConnectionIsOffline
{
    // given
    NSError *error = [[NSError alloc] initWithDomain:kOAPIErrorDomain code:1009 userInfo:nil];
    
    // when
    [sut connection:nil didFailWithError:error];
    
    // then
    assertThatInt(openAPIErrors, is(equalTo(@1)));
    
}

- (void)newDataReceived:(NSNotification *)notification
{
    jsonArray = notification.userInfo;
}

- (void)testDataIsParsedWhenConnectionFinishedReceivingData
{
    // given
    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"jsontest" ofType:@"json"];
    NSMutableData *jsonData = [NSData dataWithContentsOfFile:dataPath];
    NSError *error;
    NSMutableDictionary *testJsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    [testJsonArray setObject:@"" forKey:@"requesterid"];

    sut.receivedData = jsonData;
    // when
    [sut connectionDidFinishLoading:nil];
    
    // then
    assertThat(jsonArray, is(equalTo(testJsonArray)));
    
}

- (void)testErrorNotificationIsRaisedWhenParsingDataProducesError
{
    // given
    NSMutableData *errorData = [NSMutableData dataWithData:[@"Error" dataUsingEncoding:NSUTF8StringEncoding]];
    sut.receivedData = errorData;
    
    // when
    [sut connectionDidFinishLoading:nil];
    
    // then
    assertThatInt(openAPIErrors, is(equalTo(@1)));

}

- (void)invalidToken:(NSNotification *)notification
{
    bInvalidToken = YES;
}

- (void)testWhenResponseIsInvalidTokenNotificationIsSent
{
    // given
    NSMutableData *errorData = [NSMutableData dataWithData:[@"{\"error\": \"invalid_token\"}" dataUsingEncoding:NSUTF8StringEncoding]];
    sut.receivedData = errorData;
    
    // when
    [sut connectionDidFinishLoading:nil];
    
    // then
    assertThatBool(bInvalidToken, is(equalToBool(YES)));
}

- (void)testAccessTokenExchangeDataReceivedParamsAreStored
{
    // given
    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"jsontest" ofType:@"json"];
    NSMutableData *jsonData = [NSData dataWithContentsOfFile:dataPath];
    sut.receivedData = jsonData;
    
    OpenAPIURLConnection *connection = [[OpenAPIURLConnection alloc] init];
    connection.requestType = OAPIConnectionTokenExchangeType;
    
    // when
    [sut connectionDidFinishLoading:connection];
    
    // then
    [verify(usDef) setObject:@"96165eb6-963c-4e38-a9e7-4f67d841139b" forKey:@"access_token"];
}

- (void)testWhenTokenObtainedNotificationIsSent
{
    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"jsontest" ofType:@"json"];
    NSMutableData *jsonData = [NSData dataWithContentsOfFile:dataPath];
    sut.receivedData = jsonData;
    
    OpenAPIURLConnection *connection = [[OpenAPIURLConnection alloc] init];
    connection.requestType = OAPIConnectionTokenExchangeType;
    
    // when
    [sut connectionDidFinishLoading:connection];
    
    // then
    assertThatBool(tokenNotificationCalled, is(equalToBool(YES)));
}

- (void)testRenewTokenExchangeDataReceivedParamsAreUpdated
{
    // given
    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"jsontest" ofType:@"json"];
    NSMutableData *jsonData = [NSData dataWithContentsOfFile:dataPath];
    sut.receivedData = jsonData;
    
    OpenAPIURLConnection *connection = [[OpenAPIURLConnection alloc] init];
    connection.requestType = OAPIConnectionTokenRenewType;
    
    // when
    [sut connectionDidFinishLoading:connection];
    
    // then
    [verify(usDef) setObject:@"96165eb6-963c-4e38-a9e7-4f67d841139b" forKey:@"access_token"];
}


@end
