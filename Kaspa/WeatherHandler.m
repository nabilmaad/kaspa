//
//  LocationFetcher.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-03-22.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "WeatherHandler.h"

@interface WeatherHandler()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) BackendData *backend;
@end

@implementation WeatherHandler

-(id)init {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = YES;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    NSUInteger code = [CLLocationManager authorizationStatus];
    if (code == kCLAuthorizationStatusNotDetermined && ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    return self;
}

-(void)getWeatherData {
    // Increase precision
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // Get location
    CLLocation *currentLocation = [self.locationManager location];
    // Extract coordinates
    float latitude = currentLocation.coordinate.latitude;
    float longitude = currentLocation.coordinate.longitude;

    // Call Open Weather Map API
    self.backend = [[BackendData alloc] init];
    NSString *urlString = [NSString stringWithFormat:
                           @"%@lat=%f&lon=%f%@", self.backend.weatherChannelUrl, latitude, longitude, self.backend.weatherParameters];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:urlString]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (!error && httpResp.statusCode == 200) {
                    // Parse JSON and save weather data
                    [self parseJSONData:data];
                } else {
                    NSLog(@"%@", error.description);
                }
            }
      ] resume
     ];
    
}

- (void)parseJSONData:(NSData *)data {
    NSError *error;
    NSDictionary *parsedJSONData =
    [NSJSONSerialization JSONObjectWithData:data
                                    options:kNilOptions
                                      error:&error];
    NSArray *list = [parsedJSONData objectForKey:@"list"];
    
    // Get min and max temperature
    NSDictionary *temp = [[list firstObject] objectForKey:@"temp"];
    NSString *minTemp = [temp objectForKey:@"min"];
    NSString *maxTemp = [temp objectForKey:@"max"];
    
    // Get weather condition
    NSArray *weather = [[list firstObject] objectForKey:@"weather"];
    NSString *weatherConditionCode = [[weather firstObject] objectForKey:@"id"];
    
    // Create weather dictionary data
    NSMutableDictionary *weatherData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        weatherConditionCode, @"Weather Condition Code",
                                        minTemp, @"Minimum Temperature",
                                        maxTemp, @"Maximum Temperature", nil];
    
    // Save Weather data
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:weatherData forKey:@"Weather data"];
    [userDefaults synchronize];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
}

@end
