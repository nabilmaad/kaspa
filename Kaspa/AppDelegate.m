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
@property (nonatomic, strong) NSString *temperature;
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
    int minutes = [wakeUpTime timeIntervalSinceDate:now]/60;
    
    if(minutes <= 15 && minutes > 0) {
        //Download data
#warning Implement data download
        NSLog(@"It is time");
    }
    completionHandler(UIBackgroundFetchResultNewData);
    NSLog(@"Background fetch completed...");
    
//    NSString *urlString = [NSString stringWithFormat:
//                           @"http://api.openweathermap.org/data/2.5/weather?q=%@",
//                           @"Ottawa"];
//    
//    NSURLSession *session = [NSURLSession sharedSession];
//    [[session dataTaskWithURL:[NSURL URLWithString:urlString]
//            completionHandler:^(NSData *data,
//                                NSURLResponse *response,
//                                NSError *error) {
//                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
//                if (!error && httpResp.statusCode == 200) {
//                    //---print out the result obtained---
//                    NSString *result = [[NSString alloc] initWithBytes:[data bytes]
//                                                                length:[data length]
//                                                              encoding:NSUTF8StringEncoding];
//         //           NSLog(@"%@", result);
//                    
//                    //---parse the JSON result---
//                    [self parseJSONData:data];
//                    
//                    //---log temperature---
//      //              NSLog(@"Calculated: %@", self.temperature);
//                    
//                    completionHandler(UIBackgroundFetchResultNewData);
//                    NSLog(@"Background fetch completed...");
//                } else {
//                    NSLog(@"%@", error.description);
//                    completionHandler(UIBackgroundFetchResultFailed);
//                    NSLog(@"Background fetch Failed...");
//                }
//            }
//      ] resume
//     ];
}

- (void)parseJSONData:(NSData *)data {
    NSError *error;
    NSDictionary *parsedJSONData =
    [NSJSONSerialization JSONObjectWithData:data
                                    options:kNilOptions
                                      error:&error];
    NSDictionary *main = [parsedJSONData objectForKey:@"main"];
    
    //---temperature in Kelvin---
    NSString *temp = [main valueForKey:@"temp"];
    
    //---convert temperature to Celcius---
    float temperature = [temp floatValue] - 273;
    
    //---get current time---
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString = [formatter stringFromDate:date];
    
    self.temperature = [NSString stringWithFormat:
                        @"%f degrees Celsius, fetched at %@",
                        temperature, timeString];
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
