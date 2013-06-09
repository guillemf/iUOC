//
//  OpenAPI.m
//  iUOC
//
//  Created by Guillem Fernández González on 08/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import "OpenAPI.h"

NSString * const kOAPIUserToken = @"access_token";
NSString * const kOAuthClientID = @"kOAuthClientID";
NSString * const kOAPIErrorDomain = @"com.bytespotion.openapi";
NSString * const kOAPIErrorNotification = @"kOAPIErrorNotification";
NSString * const kOAPIOfflineErrorNotification = @"kOAPIOfflineErrorNotification";
NSString * const kOAPIAuthorisationErrorNotification = @"kOAPIAuthorisationErrorNotification";
NSString * const kOAPIDataReceivedNotification = @"kOAPIDataReceivedNotification";
NSString * const kOAPIInvalidTokenNotification = @"kOAPIInvalidTokenNotification";
NSString * const kOAPIUserAuthorizedNotification = @"kOAPIUserAuthorizedNotification";
NSString * const kOAPIUserUnAutorizedNotification = @"kOAPIUserUnAutorizedNotification";

// OAuth 2 registration dependent parameters
#define kOAuthClientID @"WzdW03gp0jYkiwqG0tt3gCewL3oTKwWn7ljyLWzsnfhDdV5RSz8xjvVOITIcafos4dq5mcyXaijc2a94IT1F1nSHcNuIvwmNHrelfHtbIhisH5V5ZAy0sAHfK6xNgXdr"
#define kOAuthSecret @"kS81KJ79nBOyFzR3MmxvG5NFp39ZvSyuYmimFFXu0kuBAGqoBlRweVHLPkJ7LxH6P2tkKGQ1MLmLikatQwz81B6UJvR0NEU0xmRsIjmWmozEFX5Rfuk5640Ew6TpAA95"

@implementation OpenAPIURLConnection

@end


@interface OpenAPI()
{
    NSUserDefaults *_params;
}

@end

@implementation OpenAPI

- (id)initWithParams:(NSUserDefaults *)parameters
{
    self = [super init];
    
    if (self) {
        _params = parameters;
    }
    
    return self;
}

- (BOOL)isUserAuthorized
{
    NSString *token = [_params objectForKey:kOAPIUserToken];
    return ( token != nil);
}

- (void)authorizeUsingWebView:(UIWebView *)view
{
    // A web is needed to access the initial authorisation
    NSString *urlAuthorisation = [NSString stringWithFormat:@"%@?response_type=code" \
                                  "&scope=READ" \
                                  "&redirect_uri=%@" \
                                  "&client_id=%@",
                                  kOAuthAuthorizationURL,
                                  kOAuthRedirectURL,
                                  kOAuthClientID];
    NSURLRequest *authRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlAuthorisation]];
    
    view.delegate = self;
    
    [view loadRequest:authRequest];
    
}

- (void)deauthorize
{
    NSLog(@"Deauthorize");
    [_params removeObjectForKey:kOAPIUserToken];
    [_params synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserUnAutorizedNotification object:self];
}

- (void)performGETRequest:(NSString *)url withParameters:(NSDictionary *)parameters forId:(NSString *)rId notifyOnCompletion:(NSString *)notificationKey error:(NSError **)error
{
    if (![self isUserAuthorized]) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"User not authorized, please call authorize" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:kOAPIErrorDomain code:EUNOAU userInfo:details];
        return;
    }
    
    NSMutableString *parametersString = [NSMutableString stringWithFormat:@"%@%@", kOAuthAPIBaseURL, url];
    
    if (parameters) [parametersString appendString:@"?"];
    
    for (NSString* key in parameters)
        [parametersString appendString:[NSString stringWithFormat:@"%@=%@&", key, [parameters objectForKey:key]]];
    
    NSMutableURLRequest *openAPIRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:parametersString]];
    
    NSString *requestParams = [NSString stringWithFormat:@"Bearer %@", [_params objectForKey:@"access_token"]];
    
    [openAPIRequest setValue:requestParams forHTTPHeaderField:@"Authorization"];

    OpenAPIURLConnection *requestConnection = [[OpenAPIURLConnection alloc] initWithRequest:openAPIRequest delegate:self];
    requestConnection.requestType = OAPIConnectionRequestType;
    requestConnection.notification = notificationKey;
    requestConnection.rId = rId;

}

- (void)refreshToken
{
    NSString *postString = [NSString stringWithFormat:@"client_id=%@" \
                            "&client_secret=%@" \
                            "&grant_type=refresh_token" \
                            "&refresh_token=%@",
                            kOAuthClientID, kOAuthSecret, [_params objectForKey:@"refresh_token"]];
    
    NSMutableURLRequest *tokenRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kOAuthTokenURL]
                                                                     cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                 timeoutInterval:10];
    [tokenRequest setHTTPMethod:@"POST"];
    [tokenRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    OpenAPIURLConnection *accessTokenExchangeConnection = [[OpenAPIURLConnection alloc] initWithRequest:tokenRequest delegate:self];
    accessTokenExchangeConnection.requestType = OAPIConnectionTokenRenewType;

}

#pragma mark - Private methods

- (void)accessTokenExchange:(NSString *)code
{
    NSString *postString = [NSString stringWithFormat:@"client_id=%@" \
                            "&client_secret=%@" \
                            "&grant_type=authorization_code" \
                            "&code=%@" \
                            "&redirect_uri=%@",
                            kOAuthClientID, kOAuthSecret, code, kOAuthRedirectURL];
    
    NSMutableURLRequest *tokenRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kOAuthTokenURL]];
    
    [tokenRequest setHTTPMethod:@"POST"];
    [tokenRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    OpenAPIURLConnection *accessTokenExchangeConnection = [[OpenAPIURLConnection alloc] initWithRequest:tokenRequest delegate:self];
    accessTokenExchangeConnection.requestType = OAPIConnectionTokenExchangeType;

}

#pragma mark - UIWebView Delegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([error code] != NSURLErrorCancelled) {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIAuthorisationErrorNotification object:self userInfo:errorInfo];
        [webView stopLoading];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlRequest = [[request URL] absoluteString];
    
    if ([urlRequest rangeOfString:kOAuthRedirectURL].location != 0)
        return YES;
    else {
        if ([urlRequest rangeOfString:@"?code="].location == NSNotFound) {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"No token request code provided after redirection from OAuth provider" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:kOAPIErrorDomain code:ENOTEC userInfo:details];
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIErrorNotification object:self userInfo:errorInfo];
            return NO;
        }
        NSString *tokenRequestCode = [urlRequest substringFromIndex:[urlRequest rangeOfString:@"?code="].location+6];

        [self accessTokenExchange:tokenRequestCode];
        
        return NO;
    }
    return NO;
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(OpenAPIURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.receivedData = nil;
}

- (void)connection:(OpenAPIURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_receivedData == nil)
        _receivedData = [[NSMutableData alloc] initWithData:data];
    else
        [_receivedData appendData:data];
}

- (void)connection:(OpenAPIURLConnection *)connection didFailWithError:(NSError *)error
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionaryWithObject:error forKey:@"error"];
    
    if (error.code == 1009) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIOfflineErrorNotification object:self userInfo:errorInfo];
    } else {
        OpenAPIURLConnection *currrentConnection = (OpenAPIURLConnection *)connection;
        
        switch (currrentConnection.requestType) {
            case OAPIConnectionRequestType:
                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionRequestType ] forKey:@"connection_type"];
                break;
            case OAPIConnectionTokenRenewType:
                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionTokenRenewType ] forKey:@"connection_type"];
                break;
            case OAPIConnectionTokenExchangeType:
                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionTokenExchangeType ] forKey:@"connection_type"];
                break;
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIErrorNotification object:self userInfo:errorInfo];
    }
}

- (void) connectionDidFinishLoading:(OpenAPIURLConnection *)connection
{
    NSError *error;
    NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:_receivedData options:NSJSONReadingMutableContainers error:&error];
        
    if (error != nil) {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIErrorNotification object:self userInfo:errorInfo];
    }
    
    if ([[jsonArray objectForKey:@"error"] isEqualToString:@"invalid_token"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIInvalidTokenNotification object:self];
        return;
    }
    
    NSMutableDictionary *responseData = [jsonArray mutableCopy];

    switch (connection.requestType) {
        case OAPIConnectionRequestType:
        {            
            NSDictionary *notificationData = [NSDictionary dictionaryWithObjectsAndKeys:responseData, @"data"
                                              , connection.rId==nil?@"":connection.rId, @"requesterid"
                                              , nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:self userInfo:notificationData];
            
            if (connection.notification != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:connection.notification object:self userInfo:responseData];
            }
        }
            break;
        case OAPIConnectionTokenExchangeType:
        case OAPIConnectionTokenRenewType:
        {
            [jsonArray enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
             {
                 [_params setObject:obj forKey:key];
             }];
            [_params synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorizedNotification object:self userInfo:responseData];
        }
            break;
        default:
            break;
    }
}

@end
