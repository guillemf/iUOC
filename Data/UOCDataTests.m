//
//  UOCDataTests.m
//  iUOC
//
//  Created by Guillem Fernández González on 18/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

// Class under test
#import "UOCData.h"

// Test support
#import <SenTestingKit/SenTestingKit.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>


@interface UOCDataTests : SenTestCase
@end

@implementation UOCDataTests
{
	NSManagedObjectContext *moc;
    UOCData *sut;
    
    BOOL userDataAvailable;
    NSMutableData *testData;
    BOOL materialDownloading;
    
    int _downloadErrors;
    NSString *materialWithDocument;
    NSData *materialData;

}

- (void)setUp
{
    [super setUp];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"iUOC"
                                              withExtension:@"momd"];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSError* error = nil;
    
    [psc addPersistentStoreWithType:NSInMemoryStoreType
                      configuration:nil
                                URL:nil
                            options:nil
                              error:&error];
    
    moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    
    sut = [[UOCData alloc] initWithMOC:moc];
    
    testData = [[@"Hello" dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    sut.receivedData = testData;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadingMaterial:) name:kUOCDWillStartDownloadingMaterial object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadingMaterial:) name:kUOCDDidStartDownloadingMaterial object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kUOCDDownloadErrror object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadingMaterial:) name:kUOCDWillEndDownloadingMaterial object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMaterial:) name:kUOCDDidEndtDownloadingMaterial object:sut];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newUserData:) name:kUOCDNewUserDataAvailable object:sut];
    
    materialDownloading = NO;

}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    testData = nil;
    moc = nil;
    sut = nil;
    [super tearDown];
}

#pragma mark - user

- (void)testThatWhenThereIsNoDataTheSystemWillReturnNoDataIsThere
{
    assertThatBool([sut hasUserData], is(equalToBool(NO)));
}

- (void)testWhenThereIsUserDataTheSystemWillReturnUserHasData
{
    // given
//    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
//                                    ,@"xaracil", @"username"
//                                    ,@"Xavi", @"name"
//                                    ,@"411603", @"number"
//                                    ,@"Xavi Aracil Diaz", @"fullName"
//                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
//                                    ,@"ca", @"language", nil];
    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"666666", @"id"
                                    ,@"user6", @"username"
                                    ,@"Harriet", @"name"
                                    ,@"666666", @"number"
                                    ,@"Harriet Upp", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/desconegut.png", @"photoUrl"
                                    ,@"ca", @"language"
                                    ,@"user6@uoc.edu", @"email"
                                    ,@"023bc66ce4a45c76a2ca81bfb9dfe2128e8fccd2305b158c86d847f1f9fc5d208d182aa6ed7068a433b6d072fef56279670d0f2048defcb3db232a81105c4bb2", @"sessionId",
                                    nil];
    // when
    NSError *error;
    [sut setUserData:userDictionary error:&error];
    
    // then
    assertThatBool([sut hasUserData], is(equalToBool(YES)));
}

- (void)testWhenUserDataIsAddedUserDataShouldBeAvailable
{
    // given
    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                    ,@"xaracil", @"username"
                                    ,@"Xavi", @"name"
                                    ,@"411603", @"number"
                                    ,@"Xavi Aracil Diaz", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                    ,@"ca", @"language", nil];
    
    // when
    NSError *error;
    [sut setUserData:userDictionary error:&error];
    
    // then
    assertThat([[sut getUserData] objectForKey:@"name"], is(equalTo(@"Xavi")));
}
- (void)testWrongUserInfoProducesError
{
    // given
    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                    ,@"xaracil", @"username"
                                    ,@"Xavi", @"realname"
                                    ,@"411603", @"number"
                                    ,@"Xavi Aracil Diaz", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                    ,@"ca", @"language", nil];
    
    // when
    NSError *error;
    [sut setUserData:userDictionary error:&error];
    
    // then
    assertThat(error, is(notNilValue()));
}

- (void)newUserData:(NSNotification *)notification
{
    userDataAvailable = YES;
}

- (void)testWhenNewUserDataIsSavedShouldSendNotification
{
    // given
    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                    ,@"xaracil", @"username"
                                    ,@"Xavi", @"name"
                                    ,@"411603", @"number"
                                    ,@"Xavi Aracil Diaz", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                    ,@"ca", @"language", nil];
    
    // when
    NSError *error;
    [sut setUserData:userDictionary error:&error];

    // then
    assertThatBool(userDataAvailable, is(equalToBool(YES)));
}

- (void)testDeletingUserDataShouldReturnNoUserData
{
    // given
    NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                    ,@"xaracil", @"username"
                                    ,@"Xavi", @"name"
                                    ,@"411603", @"number"
                                    ,@"Xavi Aracil Diaz", @"fullName"
                                    ,@"http://cv.uoc.edu/UOC/mc-icons/fotos/xaracil.jpg", @"photoUrl"
                                    ,@"ca", @"language", nil];
    
    NSError *error;
    [sut setUserData:userDictionary error:&error];

    // when
    [sut deleteUserData:&error];
    
    // then
    assertThatBool([sut hasUserData], is(equalToBool(NO)));
}

#pragma mark - Event tests

- (void)testWhenEventIsAddedEventCountIsOne
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    // when
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    
    // then
    assertThatInteger([sut eventsCount], is(equalToInteger(1)));
}

- (void)testWhentwoEventsAreAddedEventCountIsTwo
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    NSDictionary *defaultEvent2 = [NSDictionary dictionaryWithObjectsAndKeys:@"130361", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];

    // when
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    [sut addEvent:defaultEvent2 error:&error];
    
    // then
    assertThatInteger([sut eventsCount], is(equalToInteger(2)));
}

- (void)testWhenAddingTwiceTheSameEventShouldBeAddedOnce
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    // when
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    [sut addEvent:defaultEvent error:&error];
    
    // then
    assertThatInteger([sut eventsCount], is(equalToInteger(1)));
}

- (void)testWrongKeyInEventShoudlProduceError
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"information"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    // when
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    
    // then
    assertThat(error, is(notNilValue()));
}

- (void)testRequestEventDataShouldReturnTheEvent
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    
    // when
    NSDictionary *event = [sut getEventWithId:@"130360" error:&error];
    
    // then
    assertThat([event objectForKey:@"url"], is(equalTo(@"http://www.uoc.edu")));
}

- (void)testUnexistingEventIdShouldReturnNil
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    
    // when
    NSDictionary *event = [sut getEventWithId:@"130361" error:&error];
    
    // then
    assertThat(event, is(equalTo(nil)));
}

- (void)testUpdateEventShouldReturnUpdatedValues
{
    // given
    NSMutableDictionary *defaultEvent = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                         ,@"http://www.uoc.edu", @"url"
                                         ,@"Text for the event", @"summary"
                                         ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                         ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                         , nil];
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    [defaultEvent setValue:@"Modify text of the event" forKey:@"summary"];
    
    // when
    [sut updateEvent:defaultEvent error:&error];
    
    NSDictionary *event = [sut getEventWithId:@"130360" error:&error];
    
    // then
    assertThat([event objectForKey:@"summary"], is(equalTo(@"Modify text of the event")));
}

- (void)testDeleteAllEventsShouldReturnZeroEventCount
{
    // given
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    NSError *error;
    [sut addEvent:defaultEvent error:&error];

    // when
    [sut deleteAllEvents:&error];
    
    // then
    assertThatInteger([sut eventsCount], is(equalToInteger(0)));
}

- (void)testDeleteAllEventsShouldReturnNumberOfEventsDeleted
{
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    NSDictionary *defaultEvent2 = [NSDictionary dictionaryWithObjectsAndKeys:@"130361", @"id"
                                   ,@"http://www.uoc.edu", @"url"
                                   ,@"Text for the event", @"summary"
                                   ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                   ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                   , nil];
    
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    [sut addEvent:defaultEvent2 error:&error];
    
    // then
    assertThatInteger([sut deleteAllEvents:&error], is(equalToInteger(2)));
}

- (void)testEventListShouldReturnAListOfEvents
{
    NSDictionary *defaultEvent = [NSDictionary dictionaryWithObjectsAndKeys:@"130360", @"id"
                                  ,@"http://www.uoc.edu", @"url"
                                  ,@"Text for the event", @"summary"
                                  ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                  ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                  , nil];
    
    NSDictionary *defaultEvent2 = [NSDictionary dictionaryWithObjectsAndKeys:@"130361", @"id"
                                   ,@"http://www.uoc.edu", @"url"
                                   ,@"Text for the event", @"summary"
                                   ,[NSDate dateWithTimeIntervalSinceNow:86400], @"start"
                                   ,[NSDate dateWithTimeIntervalSinceNow:172800], @"end"
                                   , nil];
    
    // when
    NSError *error;
    [sut addEvent:defaultEvent error:&error];
    [sut addEvent:defaultEvent2 error:&error];
    
    // then
    assertThatInteger([[sut eventsList] count], is(equalToInteger(2)));
}

#pragma mark - Classroom tests

- (void)testWhenClassroomIsAddedClassroomCountIsOne
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // then
    assertThatInteger([sut classroomCount], is(equalToInteger(1)));
}

- (void)testWhentwoClassroomsAreAddedClassroomCountIsTwo
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    NSDictionary *defaultClassroob = [NSDictionary dictionaryWithObjectsAndKeys:@"308962", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addClassroom:defaultClassroob error:&error];
    
    // then
    assertThatInteger([sut classroomCount], is(equalToInteger(2)));
}

- (void)testWhenAddingTwiceTheSameClassroomShouldBeAddedOnce
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addClassroom:defaultClassroom error:&error];
    
    // then
    assertThatInteger([sut classroomCount], is(equalToInteger(1)));
}

- (void)testWrongKeyInClassroomShoudlProduceError
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"titleB"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // then
    assertThat(error, is(notNilValue()));
}

- (void)testRequestClassroomDataShouldReturnTheClassroom
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];

    // when
    NSDictionary *classroom = [sut getClassroomWithId:@"308961" error:&error];
    
    // then
    assertThat([classroom objectForKey:@"color"], is(equalTo(@"#308961")));
}

- (void)testUnexistingClassrroomIdShouldReturnNil
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    NSDictionary *classroom = [sut getClassroomWithId:@"308962" error:&error];
    
    // then
    assertThat(classroom, is(equalTo(nil)));
}

- (void)testUpdateClassroomShouldReturnUpdatedValues
{
    // given
    NSMutableDictionary *defaultClassroom = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                             ,@"Proves TE aula 3", @"title"
                                             ,@"#308961", @"color"
                                             ,@"308958", @"fatherId"
                                             ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                             , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [defaultClassroom setValue:@"Modify text of the title" forKey:@"title"];
    [defaultClassroom setValue:[NSArray arrayWithObjects:@"CREADOR2", @"RESPONSABLE2", nil] forKey:@"assignments"];
    
    // when
    [sut updateClassroom:defaultClassroom error:&error];
    
    NSDictionary *classroom = [sut getClassroomWithId:@"308961" error:&error];
    
    // then
    assertThat([classroom objectForKey:@"title"], is(equalTo(@"Modify text of the title")));
    assertThat([classroom objectForKey:@"assignments"], containsString(@"CREADOR2"));
}

- (void)testDeletingAllClassromsShouldReturnZeroInClassroomCount
{
    // given
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut deleteAllClassrooms:&error];
    
    // then
    assertThatInteger([sut classroomCount], is(equalToInteger(0)));
}

- (void)testDeletingAllClassromsShouldReturnZeroInMaterialCount
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addMaterial:defaultMaterial error:&error];
    
    // when
    [sut deleteAllClassrooms:&error];
    
    // then
    assertThatInteger([sut materialCountForClassroom:@"308961"], is(equalToInteger(0)));
}

- (void)testClassromListShouldReturnAListOfClassrooms
{
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    NSDictionary *defaultClassroob = [NSDictionary dictionaryWithObjectsAndKeys:@"308962", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addClassroom:defaultClassroob error:&error];
    
    // then
    assertThatInteger([[sut classroomList] count], is(equalToInteger(2)));
}

#pragma mark - Material tests

- (void)testWhenMaterialIsAddedToUnexistingClassErrorIsRaised
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    // when
    NSError *error;
    [sut addMaterial:defaultMaterial error:&error];
    
    // then
    assertThatInt(error.code, is(equalToInt(kUOCDErrorUnexistingClassroom)));
}

- (void)testWhenMaterialIsAddedMaterialCountIsOne
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];
    
    // then
    assertThatInteger([sut materialCountForClassroom:@"308961"], is(equalToInteger(1)));
}

- (void)testWhenTwoMaterialAreAddedMaterialCountIsTwo
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    NSDictionary *defaultMateriab = [NSDictionary dictionaryWithObjectsAndKeys:@"002", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];
    [sut addMaterial:defaultMateriab error:&error];
    
    // then
    assertThatInteger([sut materialCountForClassroom:@"308961"], is(equalToInteger(2)));
}

- (void)testNewMaterialShouldBeAvailable
{
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];

    // then
    NSDictionary *availableMaterial = [sut getMaterialWithId:@"001" inClassroom:@"308961" error:&error];
    assertThat([availableMaterial objectForKey:@"title"], is(equalTo(@"Material 1")));
}

- (void)downloadingMaterial:(NSNotification *)notification
{
    materialDownloading = YES;
}

- (void)testWhenMaterialIsAddedNotificationWillStartDownloadingMaterialIsSent
{
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];
    
    // then
    assertThatBool(materialDownloading, is(equalToBool(YES)));
}

- (void)testWhenURLConnectionResponseIsReceivedNotificationDidStartDownloadingIsSent
{
    // when
    [sut connection:nil didReceiveResponse:nil];
    
    // then
    assertThatBool(materialDownloading, is(equalToBool(YES)));    
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
    ++_downloadErrors;
}

- (void)testNotificationIsSentWhenConnectionHasError
{
    // given
    NSError *error = [[NSError alloc] initWithDomain:kUOCDErrorDomain code:1009 userInfo:nil];
    
    // when
    [sut connection:nil didFailWithError:error];
    
    // then
    assertThatInt(_downloadErrors, is(equalTo(@1)));
    
}

- (void)testNotificationIsSentWhenNewMaterialDidFinishedDownloading
{
    // when
    [sut connectionDidFinishLoading:nil];
    
    // then
    assertThatBool(materialDownloading, is(equalToBool(YES)));
}

- (void)newMaterial:(NSNotification *)notification
{
    materialWithDocument = [[notification userInfo] objectForKey:@"materialId"];
    NSString *resourceDocPath = [[NSString alloc] initWithString:[[[[NSBundle mainBundle]  resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Documents"]];
    NSString *documentName = [NSString stringWithFormat:@"%@_%@.pdf", [[notification userInfo] objectForKey:@"classroomId"], [[notification userInfo] objectForKey:@"materialId"]];
    NSString *filePath = [resourceDocPath stringByAppendingPathComponent:documentName];

    materialData = [NSData dataWithContentsOfFile:filePath];
}


- (void)testNotificationIsSentWhenNewMaterialAfterMaterialIsArchived
{
    // given
    UOCMaterialConnection *connection = mock([UOCMaterialConnection class]);
    [given([connection materialId]) willReturn:@"12345"];
    
    // when
    [sut connectionDidFinishLoading:connection];
    
    // then
    assertThat(materialWithDocument, is(equalTo(@"12345")));
}

- (void)testNotificationIsSentWhenNewMaterialIsReadyAfterDownloading
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addMaterial:defaultMaterial error:&error];

    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testMaterial" ofType:@"pdf"];
    NSMutableData *testMaterialData = [NSData dataWithContentsOfFile:dataPath];
    
    sut.receivedData = testMaterialData;
    
    UOCMaterialConnection *connection = mock([UOCMaterialConnection class]);
    [given([connection materialId]) willReturn:@"001"];
    [given([connection classroomId]) willReturn:@"308961"];
    
    // when
    [sut connectionDidFinishLoading:connection];
    
    // then
    assertThat(materialData, is(equalTo(testMaterialData)));
}

- (void)testWhenAddingTwiceTheSameMaterialShouldBeAddedOnce
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];
    [sut addMaterial:defaultMaterial error:&error];
    
    // then
    assertThatInteger([sut materialCountForClassroom:@"308961"], is(equalToInteger(1)));
}

- (void)testWrongKeyInMaterialShoudlProduceError
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"typeX"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    
    // when
    [sut addMaterial:defaultMaterial error:&error];

    // then
    assertThat(error, is(notNilValue()));
}

- (void)testUnexistingMaterialIdShouldReturnNil
{
    // given
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addMaterial:defaultMaterial error:&error];
    
    // when
    NSDictionary *availableMaterial = [sut getMaterialWithId:@"002" inClassroom:@"308961" error:&error];

    // then
    assertThat(availableMaterial, is(equalTo(nil)));
}

- (void)testUpdateMaterialShouldReturnUpdatedValues
{
    // given
    NSMutableDictionary *defaultMaterial = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                            ,@"PDF", @"type"
                                            ,@"Material 1", @"title"
                                            ,@"http://www.material.com", @"url"
                                            ,@"308961", @"classroom"
                                            , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addMaterial:defaultMaterial error:&error];

    [defaultMaterial setValue:@"Modify title of the material" forKey:@"title"];
    
    // when
    [sut updateMaterial:defaultMaterial error:&error];
    
    NSDictionary *availableMaterial = [sut getMaterialWithId:@"001" inClassroom:@"308961" error:&error];
    
    // then
    assertThat([availableMaterial objectForKey:@"title"], is(equalTo(@"Modify title of the material")));
}

- (void)testMaterialListShouldReturnAListOfMaterial
{
    NSDictionary *defaultMaterial = [NSDictionary dictionaryWithObjectsAndKeys:@"001", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    NSDictionary *defaultMateria2 = [NSDictionary dictionaryWithObjectsAndKeys:@"002", @"id"
                                     ,@"PDF", @"type"
                                     ,@"Material 1", @"title"
                                     ,@"http://www.material.com", @"url"
                                     ,@"308961", @"classroom"
                                     , nil];
    
    NSDictionary *defaultClassroom = [NSDictionary dictionaryWithObjectsAndKeys:@"308961", @"id"
                                      ,@"Proves TE aula 3", @"title"
                                      ,@"#308961", @"color"
                                      ,@"308958", @"fatherId"
                                      ,[NSArray arrayWithObjects:@"CREADOR", @"RESPONSABLE", nil], @"assignments"
                                      , nil];
    // when
    NSError *error;
    [sut addClassroom:defaultClassroom error:&error];
    [sut addMaterial:defaultMaterial error:&error];
    [sut addMaterial:defaultMateria2 error:&error];
    
    // then
    assertThatInteger([[sut materialListForClassroom:@"308961"] count], is(equalToInteger(2)));
}

@end
