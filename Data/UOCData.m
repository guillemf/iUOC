//
//  UOCData.m
//  iUOC
//
//  Created by Guillem Fernández González on 18/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import "UOCData.h"
#import <CoreData/CoreData.h>

NSString * const kUOCDErrorDomain = @"UOCData";
NSString * const kUOCDWillStartDownloadingMaterial = @"UOCDWillStartDownloadingMaterial";
NSString * const kUOCDDidStartDownloadingMaterial = @"UOCDDidStartDownloadingMaterial";
NSString * const kUOCDWillEndDownloadingMaterial = @"UOCDWillEndDownloadingMaterial";
NSString * const kUOCDDidEndtDownloadingMaterial = @"UOCDDidEndDownloadingMaterial";

@interface UOCData() 
{
    NSManagedObjectContext *_moc;

}

@end

@implementation UOCData

- (id)initWithMOC:(NSManagedObjectContext *)moc
{
    self = [super init];
    
    if (self) {
        _moc = moc;
    }
    
    return self;
}

#pragma mark - User methods

- (BOOL)hasUserData
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    NSError *error = nil;
    
    NSInteger count = [_moc countForFetchRequest:request error:&error];
    
    return (count == 0)?NO:YES;
}

- (void)setUserData:(NSDictionary *)userData error:(NSError **)error
{
    __block NSManagedObject *defaultUser = [NSEntityDescription insertNewObjectForEntityForName:@"User"  inManagedObjectContext:_moc];
    
    __block NSError *inError;

    [userData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop)
     {
         @try {
             [defaultUser setValue:obj forKey:key];
         }
         @catch (NSException *exception) {
             inError = [NSError errorWithDomain:kUOCDErrorDomain
                                           code:kUOCDErrorKeyNotInEntity
                                       userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in USer" forKey:NSLocalizedDescriptionKey]];
             *stop = YES;
         }
         @finally {
             
         }
         
     }];
    
    if (inError) {
        [_moc rollback];
        *error = inError;
        return;
    }
    
    [_moc save:error];

}

#pragma mark - Event methods

- (NSArray *)fetchEventWithId:(NSString *)eventId error:(NSError **)error
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:_moc]];
    NSPredicate *findPredicate = [NSPredicate predicateWithFormat:@"id == %@", eventId];
    [request setPredicate:findPredicate];
    
    NSArray *results = [_moc executeFetchRequest:request error:error];
    return results;
}

- (void)addEvent:(NSDictionary *)eventData error:(NSError *__autoreleasing *)error
{
    
    NSArray *results;
    results = [self fetchEventWithId:[eventData objectForKey:@"id"] error:error];

    if (*error) return;
    
    if ([results count] != 0) {
        *error =[NSError errorWithDomain:kUOCDErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in Event" forKey:NSLocalizedDescriptionKey]];
        return;
    }
    
    __block NSManagedObject *newEvent= [NSEntityDescription insertNewObjectForEntityForName:@"Event"  inManagedObjectContext:_moc];

    __block NSError *inError;
    
    [eventData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop)
     {
         @try {
             [newEvent setValue:obj forKey:key];
         }
         @catch (NSException *exception) {
             inError =[NSError errorWithDomain:kUOCDErrorDomain
                                          code:kUOCDErrorKeyNotInEntity
                                      userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in Event" forKey:NSLocalizedDescriptionKey]];
             *stop = YES;
         }
         @finally {
         }
         
     }];
    
    if (inError) {
        [_moc rollback];
        *error = inError;
        return;
    }
    
    [_moc save:error];

    
}

- (NSArray *)eventsList
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:_moc]];
    
    NSError *error;
    return [_moc executeFetchRequest:request error:&error];
}


- (int)eventsCount
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    NSError *error = nil;
    
    NSInteger count = [_moc countForFetchRequest:request error:&error];
    
    if (!error)
        return count;
    else
        return 0;

}

- (NSDictionary *)getEventWithId:(NSString *)eventId error:(NSError **)error
{
    NSArray *results;
    results = [self fetchEventWithId:eventId error:error];
    
    if (*error) return nil;
    
    if ([results count] == 0) return nil;
    
    NSManagedObject *existingEvent = [results objectAtIndex:0];
    
    NSArray *eventProperties = [[[existingEvent entity] attributesByName] allKeys];
    
    return [existingEvent dictionaryWithValuesForKeys:eventProperties];
}

- (void)updateEvent:(NSDictionary *)eventData error:(NSError **)error
{
    NSArray *results;
    results = [self fetchEventWithId:[eventData objectForKey:@"id"] error:error];
    
    if (*error) return;
    
    if ([results count] == 0) return;
    
    NSManagedObject *updateEvent = [results objectAtIndex:0];
    
    NSArray *eventProperties = [[[updateEvent entity] attributesByName] allKeys];

    [eventProperties enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop){
        if (![key isEqualToString:@"id"]) {
            [updateEvent setValue:[eventData objectForKey:key] forKey:key];
        }
    }];
    
    [_moc save:error];

}

#pragma mark - Classroom methods

- (NSArray *)fetchClassroomWithId:(NSString *)classroomId error:(NSError **)error
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Classroom" inManagedObjectContext:_moc]];
    NSPredicate *findPredicate = [NSPredicate predicateWithFormat:@"id == %@", classroomId];
    [request setPredicate:findPredicate];
    
    NSArray *results = [_moc executeFetchRequest:request error:error];
    return results;
}

- (void)addClassroom:(NSDictionary *)classroomData error:(NSError *__autoreleasing *)error
{
    
    NSArray *results;
    results = [self fetchClassroomWithId:[classroomData objectForKey:@"id"] error:error];
    
    if (*error) return;
    
    if ([results count] != 0) {
        *error =[NSError errorWithDomain:kUOCDErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in Classroom" forKey:NSLocalizedDescriptionKey]];
        return;
    }
    
    __block NSManagedObject *newClassroom= [NSEntityDescription insertNewObjectForEntityForName:@"Classroom"  inManagedObjectContext:_moc];
    
    __block NSError *inError;
    
    [classroomData enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop)
     {
         @try {
             if ([key isEqualToString:@"assignments"]) {
                 __block NSMutableString *assignmentsList = [[NSMutableString alloc] initWithString:@""];
                 [obj enumerateObjectsUsingBlock:^(NSString *singAssig, NSUInteger idx, BOOL *stopList)
                  {
                      [assignmentsList appendString:[NSString stringWithFormat:@"%@,", singAssig]];
                  }];
                 
                 if ([assignmentsList length]>0)
                     [assignmentsList deleteCharactersInRange:NSMakeRange([assignmentsList length]-1, 1)];
                 
                 [newClassroom setValue:assignmentsList forKey:key];
             } else
                 [newClassroom setValue:obj forKey:key];
         }
         @catch (NSException *exception) {
             inError =[NSError errorWithDomain:kUOCDErrorDomain
                                          code:kUOCDErrorKeyNotInEntity
                                      userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in Classroom" forKey:NSLocalizedDescriptionKey]];
             *stop = YES;
         }
         @finally {
         }
         
     }];
    
    if (inError) {
        [_moc rollback];
        *error = inError;
        return;
    }
    
    [_moc save:error];
    
    
}

- (NSArray *)classroomList
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Classroom" inManagedObjectContext:_moc]];
    
    NSError *error;
    return [_moc executeFetchRequest:request error:&error];
}

- (int)classroomCount
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Classroom"];
    NSError *error = nil;
    
    NSInteger count = [_moc countForFetchRequest:request error:&error];
    
    if (!error)
        return count;
    else
        return 0;
    
}

- (NSDictionary *)getClassroomWithId:(NSString *)classroomId error:(NSError **)error
{
    NSArray *results;
    results = [self fetchClassroomWithId:classroomId error:error];
    
    if (*error) return nil;
    
    if ([results count] == 0) return nil;
    
    NSManagedObject *existingEvent = [results objectAtIndex:0];
    
    NSArray *eventProperties = [[[existingEvent entity] attributesByName] allKeys];
    
    return [existingEvent dictionaryWithValuesForKeys:eventProperties];
}

- (void)updateClassroom:(NSDictionary *)classroomData error:(NSError **)error
{
    NSArray *results;
    results = [self fetchClassroomWithId:[classroomData objectForKey:@"id"] error:error];
    
    if (*error) return;
    
    if ([results count] == 0) return;
    
    NSManagedObject *updateClassroom = [results objectAtIndex:0];
    
    NSArray *classroomProperties = [[[updateClassroom entity] attributesByName] allKeys];
    
    [classroomProperties enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop){
        if ([key isEqualToString:@"assignments"]) {
            __block NSMutableString *assignmentsList = [[NSMutableString alloc] initWithString:@""];
            [[classroomData objectForKey:key] enumerateObjectsUsingBlock:^(NSString *singAssig, NSUInteger idx, BOOL *stopList)
             {
                 [assignmentsList appendString:[NSString stringWithFormat:@"%@,", singAssig]];
             }];
            
            if ([assignmentsList length]>0)
                [assignmentsList deleteCharactersInRange:NSMakeRange([assignmentsList length]-1, 1)];
            
            [updateClassroom setValue:assignmentsList forKey:key];

        }
        else if (![key isEqualToString:@"id"]) {
            [updateClassroom setValue:[classroomData objectForKey:key] forKey:key];
        }
    }];
    
    [_moc save:error];
    
}

#pragma mark - Material methods

- (NSArray *)fetchMaterialWithId:(NSString *)materialId inclassroom:(NSString *)classroomId error:(NSError **)error
{
    NSArray *classrooms = [self fetchClassroomWithId:classroomId error:error];
    
    if (*error) return nil;
    
    if ([classrooms count] < 1) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Event" inManagedObjectContext:_moc]];
    NSPredicate *findPredicate = [NSPredicate predicateWithFormat:@"(id == %@) AND (classroom == %@)", materialId, [classrooms objectAtIndex:0]];
    [request setPredicate:findPredicate];
    
    NSArray *results = [_moc executeFetchRequest:request error:error];
    return results;
}

- (void)addMaterial:(NSDictionary *)materialData error:(NSError *__autoreleasing *)error
{
    
    NSArray *results;
    results = [self fetchMaterialWithId:[materialData objectForKey:@"id"] inclassroom:[materialData objectForKey:@"classroom"] error:error];
    
    if (*error) return;
    
    if ([results count] != 0) {
        *error =[NSError errorWithDomain:kUOCDErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert duplicated material" forKey:NSLocalizedDescriptionKey]];
        return;
    }
    
    __block NSManagedObject *newEvent= [NSEntityDescription insertNewObjectForEntityForName:@"Material"  inManagedObjectContext:_moc];
    
    __block NSError *inError;
    
    [materialData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop)
     {
         @try {
             if ([key isEqualToString:@"classroom"]) {
                 NSArray *classrooms = [self fetchClassroomWithId:[materialData objectForKey:@"classroom"] error:&inError];
                 if (inError) {
                     *stop = YES;
                 }
                 else
                 {
                     if ([classrooms count]<1) {
                         inError =[NSError errorWithDomain:kUOCDErrorDomain
                                                      code:kUOCDErrorUnexistingClassroom
                                                  userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert Material in unexisting classroom" forKey:NSLocalizedDescriptionKey]];
                         *stop = YES;

                     } else
                         [newEvent setValue:[classrooms objectAtIndex:0] forKey:@"classroom"];
                 }
             } else
                 [newEvent setValue:obj forKey:key];
         }
         @catch (NSException *exception) {
             inError =[NSError errorWithDomain:kUOCDErrorDomain
                                          code:kUOCDErrorKeyNotInEntity
                                      userInfo:[NSDictionary dictionaryWithObject:@"Trying to insert unexisting key in Material" forKey:NSLocalizedDescriptionKey]];
             *stop = YES;
         }
         @finally {
         }
         
     }];
    
    if (inError) {
        [_moc rollback];
        *error = inError;
        return;
    }
    
    [_moc save:error];
    
    if (!(*error)) {
        NSURLRequest *materialRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[materialData objectForKey:@"url"]]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUOCDWillStartDownloadingMaterial object:self];
        NSURLConnection __attribute__((unused)) *connection = [[NSURLConnection alloc] initWithRequest:materialRequest delegate:self];
    }
}

- (int)materialCountForClassroom:(NSString *)classroomId
{
    NSError *error;
    
    NSArray *classrooms = [self fetchClassroomWithId:classroomId error:&error];
    
    if (error) return 0;
    
    if ([classrooms count] < 1) return 0;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Material"];
    NSPredicate *findPredicate = [NSPredicate predicateWithFormat:@"(classroom == %@)", [classrooms objectAtIndex:0]];
    [request setPredicate:findPredicate];
    
    NSInteger count = [_moc countForFetchRequest:request error:&error];
    
    if (!error)
        return count;
    else
        return 0;
    
}

#pragma mark - Material URL Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUOCDDidStartDownloadingMaterial object:self];
    self.receivedData = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_receivedData == nil)
        _receivedData = [[NSMutableData alloc] initWithData:data];
    else
        [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionaryWithObject:error forKey:@"error"];
    
//    if (error.code == 1009) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIOfflineErrorNotification object:self userInfo:errorInfo];
//    } else {
//        OpenAPIURLConnection *currrentConnection = (OpenAPIURLConnection *)connection;
//        
//        switch (currrentConnection.requestType) {
//            case OAPIConnectionRequestType:
//                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionRequestType ] forKey:@"connection_type"];
//                break;
//            case OAPIConnectionTokenRenewType:
//                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionTokenRenewType ] forKey:@"connection_type"];
//                break;
//            case OAPIConnectionTokenExchangeType:
//                [errorInfo setObject:[NSNumber numberWithInt:OAPIConnectionTokenExchangeType ] forKey:@"connection_type"];
//                break;
//            default:
//                break;
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIErrorNotification object:self userInfo:errorInfo];
//    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
//    NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:_receivedData options:NSJSONReadingMutableContainers error:&error];
    
//    if (error != nil) {
//        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIErrorNotification object:self userInfo:errorInfo];
//    }
//    
//    if ([[jsonArray objectForKey:@"error"] isEqualToString:@"invalid_token"]) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIInvalidTokenNotification object:self];
//        return;
//    }
//    
//    NSMutableDictionary *responseData = [jsonArray mutableCopy];
//    OpenAPIURLConnection *currrentConnection = (OpenAPIURLConnection *)connection;
//    
//    switch (currrentConnection.requestType) {
//        case OAPIConnectionRequestType:
//            if (currrentConnection.rId == nil)
//                [responseData setObject:@"" forKey:@"requesterid"];
//            else
//                [responseData setObject:currrentConnection.rId forKey:@"requesterid"];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIDataReceivedNotification object:self userInfo:responseData];
//            break;
//        case OAPIConnectionTokenExchangeType:
//        case OAPIConnectionTokenRenewType:
//        {
//            [jsonArray enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
//             {
//                 [_params setObject:obj forKey:key];
//             }];
//            [_params synchronize];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kOAPIUserAuthorisedNotification object:self userInfo:responseData];
//        }
//            break;
//        default:
//            break;
//    }
}

@end
