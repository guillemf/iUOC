//
//  AppDelegate.m
//  iUOC
//
//  Created by Guillem Fernández González on 15/03/13.
//  Copyright (c) 2013 Guillem Fernández González. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "OpenAPI.h"
#import "UOCData.h"

@interface AppDelegate()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)initializeCoreDataStack;
- (void)contextInitialized;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeCoreDataStack];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    OpenAPI *oal = [[OpenAPI alloc] initWithParams:[NSUserDefaults standardUserDefaults]];
    UOCData *uds = [[UOCData alloc] initWithMOC:_managedObjectContext];
    
    MainViewController *mainVC = [[MainViewController alloc] initWithOrigin:oal data:uds];
    self.window.rootViewController = mainVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)contextInitialized
{
    //Finish UI initialization
}

#pragma mark - Core Data stack

- (void)initializeCoreDataStack
{
    NSURL *modelURL = nil;
    modelURL = [[NSBundle mainBundle] URLForResource:@"iUOC"
                                       withExtension:@"momd"];
    GFAssert(modelURL, @"AppDelegate", 0, @"Failed to find model URL");
    
    NSManagedObjectModel *mom = nil;
    mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    GFAssert(mom, @"AppDelegate", 0, @"Failed to initialize model");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *storeURL = [[fm URLsForDirectory:NSDocumentDirectory
                                  inDomains:NSUserDomainMask] lastObject];
    storeURL = [storeURL URLByAppendingPathComponent:@"iUOC.sqlite"];
    
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    GFAssert(psc, @"AppDelegate", 0, @"Failed to initialize persistent store coordinator");
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    
    [self setManagedObjectContext:moc];
    
    dispatch_queue_t queue = nil;
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSError *error = nil;
        NSPersistentStoreCoordinator *coordinator = nil;
        coordinator = [moc persistentStoreCoordinator];
        NSPersistentStore *store = nil;
        store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                          configuration:nil
                                                    URL:storeURL
                                                options:nil
                                                  error:&error];
        if (!store) {
            LogMessage(@"AppDelegate", 0, @"Error adding persistent store to coordinator %@\n%@",
                       [error localizedDescription], [error userInfo]);
            
            NSString *msg = nil;
            msg = [NSString stringWithFormat:NSLocalizedString(@"databaseInitError", nil), [error localizedDescription], [error userInfo]];
//            WCAlertView *alertView = [[WCAlertView alloc] initWithTitle:@"Error"
//                                                                message:msg
//                                                               delegate:self
//                                                      cancelButtonTitle:@"Quit"
//                                                      otherButtonTitles:nil];
//            [alertView show];
            return;
        }
                
        [self contextInitialized];
    });
}

@end
