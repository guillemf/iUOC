//
//  UOCData.h
//  iUOC
//
//  Created by Guillem Fernández González on 18/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 Library to access to local data storage of the data obtained from OpenAPI.
 */

/**
 Error constants definitions.
 */
extern NSString * const kUOCDErrorDomain;
enum {
    kUOCDErrorKeyNotInEntity,
    kUOCDErrorUnexistingClassroom
} UOCError;

/**
 Notification keys
 */
extern NSString * const kUOCDWillStartDownloadingMaterial;
extern NSString * const kUOCDDidStartDownloadingMaterial;
extern NSString * const kUOCDWillEndDownloadingMaterial;
extern NSString * const kUOCDDidEndtDownloadingMaterial;


@interface UOCData : NSObject <NSURLConnectionDataDelegate>

/** Data received on the current/last request */
@property (nonatomic, strong) NSMutableData *receivedData;

/**
 Default initialiser
 Creates the object and keeps the reference to a object containing the managed object context where to store all data
 @param parameters List of the user parameters
 */
- (id)initWithMOC:(NSManagedObjectContext *)moc;
/** 
 Check whether the storage has user data 
 @return BOOL indicating whether there is user data or not
 */
- (BOOL)hasUserData;
/** 
 Sets the user data for the storage linked to the object
 @param userData NSDictionary with the objects and keys corresponding to the user object
 @param error Object to contain possible errors during insert
 */
- (void)setUserData:(NSDictionary *)userData error:(NSError **)error;

/**
 EVENTS Methods
 */

/**
 Adds an event to the list of events
 @param eventData NSDictionary with the objects and keys correspondig to the event object
 @param error Object to contain possible errors during insert
 */
- (void)addEvent:(NSDictionary *)eventData error:(NSError **)error;
/** 
 Number of events stored in the system 
 @return int corresponding to the number of events stored in the system
 */
- (int)eventsCount;
/**
 List of events stored in the system
 @return NSArray corresponding to all the events stored in the system
 */
- (NSArray *)eventsList;
/**
 Get event data for a given id
 @param eventId Id of the event requested
 @param error Object to contain possible errors during request
 @return NSDictionary with the data of the event if found, otherwise nil
 */
- (NSDictionary *)getEventWithId:(NSString *)eventId error:(NSError **)error;
/**
 Update event with the new values
 @param eventData NSDictionary with the objects and keys correspondig to the user object
 @param error Object to contain possible errors during update
 */
- (void)updateEvent:(NSDictionary *)eventData error:(NSError **)error;

/**
 CLASSROOM Methods
 */

/**
 Adds an classroom to the list of classrooms
 @param classroomData NSDictionary with the objects and keys correspondig to the classroom object
 @param error Object to contain possible errors during insert
 */
- (void)addClassroom:(NSDictionary *)classroomData error:(NSError *__autoreleasing *)error;
/**
 Number of classroom stored in the system
 @return int corresponding to the number of classroom stored in the system
 */
- (int)classroomCount;
/**
 List of Classrooms stored in the system
 @return NSArray corresponding to all the classrroms stored in the system
 */
- (NSArray *)classroomList;
/**
 Get classroom data for a given id
 @param classroomId Id of the requested Classroom
 @param error Object to contain possible errors during request
 @return NSDictionary with the data of the classroom if found, otherwise nil
 */
- (NSDictionary *)getClassroomWithId:(NSString *)classroomId error:(NSError **)error;
/**
 Update classroom with the new values
 @param classroomData NSDictionary with the objects and keys correspondig to the user object
 @param error Object to contain possible errors during update
 */
- (void)updateClassroom:(NSDictionary *)classroomData error:(NSError **)error;
/**
 MATERIAL Methods
 */

/**
 Adds an Material to the list of Material
 @param materialData NSDictionary with the objects and keys correspondig to the Material object
 @param error Object to contain possible errors during insert
 */
- (void)addMaterial:(NSDictionary *)materialData error:(NSError *__autoreleasing *)error;
/**
 Number of material stored for a given classroom in the system
 @return int corresponding to the number of material stored in the system
 */
- (int)materialCountForClassroom:(NSString *)classroomId;
@end
