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
    kUOCDErrorUnexistingClassroom,
    kUOCDErrorDownloadingMaterial
} UOCError;

/**
 Notification keys
 */
extern NSString * const kUOCDWillStartDownloadingMaterial;
extern NSString * const kUOCDDidStartDownloadingMaterial;
extern NSString * const kUOCDWillEndDownloadingMaterial;
extern NSString * const kUOCDDidEndtDownloadingMaterial;
extern NSString * const kUOCDDownloadErrror;

extern NSString * const kUOCDNewUserDataAvailable;

@interface UOCMaterialConnection : NSURLConnection

@property (strong, nonatomic) NSString *materialId;
@property (strong, nonatomic) NSString *classroomId;

- (id)initWithRequest:(NSURLRequest *)request forMaterial:(NSString *)materialId inClassroom:(NSString *)classroomId delegate:(id)delegate;

@end

@interface UOCData : NSObject <NSURLConnectionDataDelegate>

/** Data received on the current/last request */
@property (nonatomic, strong) NSMutableData *receivedData;

/**
 Default initialiser
 Creates the object and keeps the reference to a object containing the managed object context where to store all data
 @param moc NSManagedObjectContext used to save all data
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
 Get current user data. If no user data or error, nil is returned
 */
- (NSDictionary *)getUserData;
/**
 Delete user information data. If error produced, NO is returned.
 @param error Object to contain possible errors during insert
 @return BOOL indicating whether the data has been deleted or not
 */
- (BOOL)deleteUserData:(NSError **)error;
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
 Delete all events in the system
 @param error Object to contain possible errors during insert
 @return number of deleted events if done or -1 if error
 */
- (int)deleteAllEvents:(NSError **)error;
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
 Delete all classrooms in the system
 @param error Object to contain possible errors during insert
 @return number of deleted events if done or -1 if error
 */
- (int)deleteAllClassrooms:(NSError **)error;
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
 @param classroomId identifier of the classroom you want the meterial from
 @return int corresponding to the number of material stored in the system
 */
- (int)materialCountForClassroom:(NSString *)classroomId;
/**
 Get material data for a given id
 @param materialId Id of the requested Material
 @param classroomId Id of the Classroom which the material belongs to
 @param error Object to contain possible errors during request
 @return NSDictionary with the data of the material if found, otherwise nil
 */
- (NSDictionary *)getMaterialWithId:(NSString *)materialId inClassroom:(NSString *)classroomId error:(NSError **)error;
/**
 Update material with the new values
 @param materialData NSDictionary with the objects and keys correspondig to the user object
 @param error Object to contain possible errors during update
 */
- (void)updateMaterial:(NSDictionary *)materialData error:(NSError **)error;
/**
 List of Material stored in the system for a give Classroom
 @param classroomId identifier of the classroom you want the meterial from
 @return NSArray corresponding to all the material stored in the system
 */
- (NSArray *)materialListForClassroom:(NSString *)classroomId;
@end
