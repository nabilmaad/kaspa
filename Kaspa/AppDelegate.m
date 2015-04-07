//
//  AppDelegate.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-23.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+MOC.h"
#import "SavedTopic+SavedTopicCategory.h"
#import "SavedTopicsDatabaseAvailability.h"
#import "Backend.h"
#import <MyoKit/MyoKit.h>

@interface AppDelegate ()
@property bool dataFetchForTodaySuccessful;
@property (nonatomic, strong) NSManagedObjectContext *savedTopicDatabaseContext;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set middle tab as default
    UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
    tabBar.selectedIndex = 1;
    
    // Set minimum fetching interval
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Instantiate the Myo hub using the singleton accessor, and set the applicationIdentifier of our application.
    [[TLMHub sharedHub] setApplicationIdentifier:@"com.Nabil.Kaspa"];
    
    // Set the managed object context to trigger a notification to show the saved list
    self.savedTopicDatabaseContext = [self createMainQueueManagedObjectContext];
    
    // Ask user to allow notifications if it's the first launch
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        // app already launched
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // This is the first launch ever - register notifications
        UIUserNotificationType types = UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        
        UIUserNotificationSettings *mySettings =
        [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    
    return YES;
}

#pragma mark - Radio antenna setup
- (void)setSavedTopicDatabaseContext:(NSManagedObjectContext *)savedTopicDatabaseContext {
    _savedTopicDatabaseContext = savedTopicDatabaseContext;
    
    NSDictionary *userInfo = self.savedTopicDatabaseContext ? @{ SavedTopicsDatabaseAvailabilityContext : self.savedTopicDatabaseContext } : nil;
    
    // Post notification that will be received by the saved list table view
    [[NSNotificationCenter defaultCenter] postNotificationName:SavedTopicsDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - Background Fetching
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSLog(@"Background fetch started...");
    // Log background fetch on server
    NSString *url = @"http://54.84.109.235/backgroundFetchScript.php";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [connection start];
    
    // Check if it's time to download briefing (15 minutes)
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [timeFormat setTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]];
   
    NSDate *now = [timeFormat dateFromString:[timeFormat stringFromDate:[NSDate date]]];
    NSDate *wakeUpTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"toTime"];
    int minutesTillWakeUp = [wakeUpTime timeIntervalSinceDate:now]/60;
    
    NSDate *sleepTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"fromTime"];
    int minutesSinceSleep = [now timeIntervalSinceDate:sleepTime]/60;
    
#warning Remove later on
    bool testingFetch = YES;
    
    if(testingFetch || (minutesTillWakeUp <= 100 && minutesTillWakeUp > 0)) {
        NSLog(@"It is time. See if data fetch was successful");
        // Get app's internal data
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        self.dataFetchForTodaySuccessful = [userDefaults boolForKey:@"Today Fetch Successful"] &&
                                    [userDefaults boolForKey:@"Weather Fetch Successful"];
        
        if(!self.dataFetchForTodaySuccessful || testingFetch) {
            NSLog(@"Data fetch unsucessful, so gonna get data");
            // Today
            if([userDefaults boolForKey:@"Today state"])
                [self getTodayData];
            
            // Weather
            if([userDefaults boolForKey:@"Weather state"])
                [self getWeatherData];
            
            // Calendar Events
            if([userDefaults boolForKey:@"Calendar Events state"])
                [self getCalendarEventsData];
            
            completionHandler(UIBackgroundFetchResultNewData);
        } else
            completionHandler(UIBackgroundFetchResultNoData);
    }
    else if(self.dataFetchForTodaySuccessful && minutesSinceSleep > 0 && minutesTillWakeUp > 0) {
        // Falsify all success flags to allow new fetch
        NSLog(@"It is not time anymore. Gonna disable dataFetchSuccessful");
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:NO forKey:@"Today Fetch Successful"];
        [userDefaults setBool:NO forKey:@"Weather Fetch Successful"];
        [userDefaults setBool:NO forKey:@"HasSentNotification"];
        self.dataFetchForTodaySuccessful = NO;
        completionHandler(UIBackgroundFetchResultNoData);
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
    
    // Check if data has been successfully fetched, and we still didn't fire the notification
    if(self.dataFetchForTodaySuccessful &&
       ![[NSUserDefaults standardUserDefaults] boolForKey:@"HasSentNotification"]) {
        [self fireBriefingReadyNotification];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasSentNotification"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSLog(@"Background fetch completed...");
}

- (void)getTodayData {
    // Get today's date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"ddMMMMyyyy";
    NSString *todayDate = [formatter stringFromDate:[NSDate date]];
    
    // Create today URL
    NSString *todayUrl = [NSString stringWithFormat:@"%@%@", TodayChannelUrl, todayDate];
    
    // Fetch today data
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:todayUrl]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (!error && httpResp.statusCode == 200) {
                    NSString *result = [[NSString alloc] initWithBytes:[data bytes]
                                                                length:[data length]
                                                              encoding:NSUTF8StringEncoding];
                    // Save today data
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setObject:result forKey:@"Today data"];
                    
                    // Log success
                    [userDefaults setBool:YES forKey:@"Today Fetch Successful"];
                    [userDefaults synchronize];
                } else {
                    NSLog(@"Today error: %@", error.description);
                }
            }
      ] resume
     ];
}

- (void)getWeatherData {
    // Get the weather data from the handler
    WeatherHandler *loc = [[WeatherHandler alloc] init];
    [loc getWeatherData];
}

- (void)getCalendarEventsData {
    // Get event list for today
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        // Create the date components of the beginning of the day
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *beginningOfTodayComponents = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |
                                                                          NSCalendarUnitDay | NSCalendarUnitHour |
                                                                          NSCalendarUnitMinute | NSCalendarUnitSecond )
                                                                fromDate:[NSDate date]];
        beginningOfTodayComponents.hour = 0;
        beginningOfTodayComponents.minute = 0;
        beginningOfTodayComponents.second = 0;
        NSDate *beginningOfToday = [calendar dateFromComponents:beginningOfTodayComponents];
        
        // Create the date components of the end of the day
        NSDateComponents *endOfTodayComponents = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |
                                                                          NSCalendarUnitDay | NSCalendarUnitHour |
                                                                          NSCalendarUnitMinute | NSCalendarUnitSecond )
                                                                fromDate:[NSDate date]];
        endOfTodayComponents.hour = 23;
        endOfTodayComponents.minute = 59;
        endOfTodayComponents.second = 59;
        NSDate *endOfToday = [calendar dateFromComponents:endOfTodayComponents];
        
        // Create the predicate from the event store's instance method
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:beginningOfToday
                                                                     endDate:endOfToday
                                                                   calendars:nil];
        
        // Fetch all events that match the predicate
        NSArray *events = [eventStore eventsMatchingPredicate:predicate];
        
        // Remove any event that started before today and has an end date today
        for(EKEvent *event in events) {
            if([event.startDate compare:beginningOfToday] == NSOrderedAscending) {
                NSMutableArray *tempArray = [events mutableCopy];
                [tempArray removeObject:event];
                events = [tempArray copy];
            }
        }
        
        // Save events as strings
        NSMutableArray *eventsText = [[NSMutableArray alloc] initWithObjects:@"Let's take a look at your calendar for today.", nil];
        
        switch([events count]) {
            case 0:
                // No events
                [eventsText addObject:@"It looks like you have nothing planned for the day!"];
            case 1: {
                // 1 events
                [eventsText addObject:@"You only have the following event planned."];
                EKEvent *onlyEvent = (EKEvent *)[events objectAtIndex:0];
                
                // Set date formatter
                NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]; // Make sure it's 12-hour
                [dateFormatter setDateFormat:@"hh:mm a"];
                
                NSString *eventTime = [dateFormatter stringFromDate:onlyEvent.startDate];
                [eventsText addObject:[NSString stringWithFormat:
                                       @"%@, at %@.", onlyEvent.title, eventTime]];
            }
            default:
            {
                // 2+ events
                [eventsText addObject:@"Here are the events you have planned."];
                for(EKEvent *event in events) {
                    // Set date formatter
                    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]; // Make sure it's 12-hour
                    [dateFormatter setDateFormat:@"hh:mm a"];
                    
                    NSString *eventTime = [dateFormatter stringFromDate:event.startDate];
                    [eventsText addObject:[NSString stringWithFormat:
                                              @"%@, at %@.", event.title, eventTime]];
                }
            }
        }
        
        // Save calendar event data
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:eventsText forKey:@"Calendar Events data"];
        [userDefaults synchronize];
    }];
}

# pragma mark - Local notification
- (void)fireBriefingReadyNotification {
    // Create notification
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
    
    // Fire notification ASAP (1 second from now)
//    localNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
//    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    // Set notification text
    localNotif.alertBody = @"You can listen to your daily briefing."; // Message
    localNotif.alertAction = @"Listen"; // Action button title
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.2)
        localNotif.alertTitle = @"Briefing Ready"; // Apple Watch short look text
    
    // Add badge & notification sound
    localNotif.applicationIconBadgeNumber = 1;
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
