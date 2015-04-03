//
//  AppDelegate.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-23.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "AppDelegate.h"
#import <MyoKit/MyoKit.h>

@interface AppDelegate ()
@property (nonatomic, strong) BackendData *backend;
@property bool dataFetchSuccessful;
@property bool todayFailed;
@property bool weatherFailed;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Instantiate the hub using the singleton accessor, and set the applicationIdentifier of our application.
    [[TLMHub sharedHub] setApplicationIdentifier:@"com.Nabil.Kaspa"];
    return YES;
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSLog(@"Background fetch started...");
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
    
    if(testingFetch || (minutesTillWakeUp <= 30 && minutesTillWakeUp > 0)) {
        NSLog(@"It is time. See if data fetch was successful");
        if(!self.dataFetchSuccessful || testingFetch) {
            NSLog(@"Data fetch unsucessful, so gonna get data");
            //Download data set on by user
            self.backend = [[BackendData alloc] init];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            // Today
            if([userDefaults boolForKey:@"Today state"])
                [self getTodayData];
            
            // Weather
            if([userDefaults boolForKey:@"Weather state"])
                [self getWeatherData];
            
            // Calendar Events
            if([userDefaults boolForKey:@"Calendar Events state"])
                [self getCalendarEventsData];
            
            if(!self.todayFailed && !self.weatherFailed)
                self.dataFetchSuccessful = YES;
        }
    }
    else if(minutesSinceSleep > 0 && minutesTillWakeUp > 0 &&  self.dataFetchSuccessful) {
        NSLog(@"It is not time anymore. Gonna disable dataFetchSuccessful");
        self.dataFetchSuccessful = false;
    }
    NSLog(@"%d", (int)self.dataFetchSuccessful);
    completionHandler(UIBackgroundFetchResultNewData);
    NSLog(@"Background fetch completed...");
}

- (void)getTodayData {
    // Get today's date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"ddMMMMyyyy";
    NSString *todayDate = [formatter stringFromDate:[NSDate date]];
    
    // Create today URL
    NSString *todayUrl = [NSString stringWithFormat:@"%@%@", self.backend.todayChannelUrl, todayDate];
    
    // Fetch today data
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:todayUrl]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (!error && httpResp.statusCode == 200) {
                    //---print out the result obtained---
                    NSString *result = [[NSString alloc] initWithBytes:[data bytes]
                                                                length:[data length]
                                                              encoding:NSUTF8StringEncoding];
                    // Save today data
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setObject:result forKey:@"Today data"];
                    [userDefaults synchronize];
                } else {
                    self.todayFailed = YES; // Too late
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
        // Create the end date components
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *oneDayFromNowComponents = [[NSDateComponents alloc] init];
        oneDayFromNowComponents.day = 1;
        NSDate *oneDayFromNow = [calendar dateByAddingComponents:oneDayFromNowComponents
                                                           toDate:[NSDate date]
                                                          options:0];
        
        // Create the predicate from the event store's instance method
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:[NSDate date]
                                                                     endDate:oneDayFromNow
                                                                   calendars:nil];
        
        // Fetch all events that match the predicate
        NSArray *events = [eventStore eventsMatchingPredicate:predicate];
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
