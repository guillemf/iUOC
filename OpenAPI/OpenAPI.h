//
//  OpenAPI.h
//  iUOC
//
//  Created by Guillem Fernández González on 08/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

/**
 Library to access to OpenAPI rest service published by UOC.
 This service conforms to OAuth 2 authentication protocol.
 The Library provides access to authorisation, access to token renew and access to GET and POST requests.
 */
#import <Foundation/Foundation.h>

/**
 Library specific key constants to access configuration parameters.
 */
extern NSString * const kOAPIUserToken;
extern NSString * const kOAuthClientID;

/**
 Library specific error codes and constants.
 */
extern NSString * const kOAPIErrorDomain;

#define EUNOAU      1       /* User not authorised */
#define ENOTEC      2       /* No token exchange code */

/**
 Library specific notification keys
 */
extern NSString * const kOAPIOfflineErrorNotification;
extern NSString * const kOAPIAuthorisationErrorNotification;
extern NSString * const kOAPIErrorNotification;

extern NSString * const kOAPIDataReceivedNotification;
extern NSString * const kOAPIInvalidTokenNotification;
extern NSString * const kOAPIUserAuthorisedNotification;

/**
 OAuth 2 constants. 
 Have to be replaced with production values when released
 */

#define kOAuthAuthorizationURL @"http://denver.uoc.es:8080/webapps/uocapi/oauth/authorize"
#define kOAuthTokenURL @"http://denver.uoc.es:8080/webapps/uocapi/oauth/token"
#define kOAuthRedirectURL @"uoc://oauthresponse"

@interface OpenAPI : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIWebViewDelegate>

/** Data received on the current/last request */
@property (nonatomic, strong) NSMutableData *receivedData;

/**
 Default initialiser
 Creates the object and keeps the reference to a object containing the user specific configuration
 @param parameters List of the user parameters
 */
- (id)initWithParams:(NSUserDefaults *)parameters;
/** Check whether the user is authorised by the OpenAPI or not*/
- (BOOL)isUserAuthorised;
/** Starts the authorisation process */
- (void)authoriseUsingWebView:(UIWebView *)view;
/** Starts the deauthorisation process */
- (void)deauthorize;
/**
 Method to perform the different requests to the service
 @param url Complete url in REST format starting from the root of the service
 @param withParameters List of parameters to send on the header of the connection
 @param forId Identification of the object the call was made for, it is only a reference that will be returned as is on the results to be able of identify the call.
 @param notificationKey Notification to be fired when the data is received
 @param error Error object to detect before the call is made
 */
- (void)performGETRequest:(NSString *)url withParameters:(NSDictionary *)parameters forId:(NSString *)rId notifyOnCompletion:(NSString *)notificationKey error:(NSError **)error;

- (void)accessTokenExchange:(NSString *)code;
@end

typedef NS_ENUM(NSInteger, OAPIConnectionType) {
    OAPIConnectionRequestType,
    OAPIConnectionTokenExchangeType,
    OAPIConnectionTokenRenewType
};

@interface OpenAPIURLConnection : NSURLConnection

@property (strong, nonatomic) NSString *rId;
@property (assign, nonatomic) OAPIConnectionType requestType;

@end
