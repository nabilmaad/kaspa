//
//  LocationFetcher.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-03-22.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "WeatherHandler.h"
#import "Backend.h"

@interface WeatherHandler()
@property (nonatomic, strong) CLLocationManager *locationManager;
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

    // Call Forecast IO API
    NSString *urlString = [NSString stringWithFormat:
                           @"%@%f,%f,%d", WeatherChannelUrl, latitude, longitude, (int)[[NSDate date] timeIntervalSince1970]];

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
                    NSLog(@"Weather error: %@", error.description);
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
    
    // Get daily data dictionary
    NSDictionary *daily = [parsedJSONData objectForKey:@"daily"];
    NSDictionary *dailyData = [[daily objectForKey:@"data"] firstObject];

    // Get min and max temperature, and feels like min temperature
    NSString *minTempFahrenheit = [dailyData objectForKey:@"temperatureMin"];
    NSString *minApparentTempFahrenheit = [dailyData objectForKey:@"apparentTemperatureMin"];
    NSString *maxTempFahrenheit = [dailyData objectForKey:@"temperatureMax"];

    int minTempCelcius = ([minTempFahrenheit intValue] - 32) / 1.8;
    int minApparentTempCelcius = ([minApparentTempFahrenheit intValue] - 32) / 1.8;
    int maxTempCelcius = ([maxTempFahrenheit intValue] - 32) / 1.8;

    // Get weather condition
    NSString *weatherCondition = [dailyData objectForKey:@"summary"];

    // Build weather string including ".." for longer pauses
    NSString *weatherString = [NSString stringWithFormat:
                               @"Let's check today's weather.. It looks like you'll be seeing some %@. "
                               "The daily temperature will range between %d and %d degrees celcius..",
                               weatherCondition, minTempCelcius, maxTempCelcius];

    // Add minimum "feels like" temperature if necessary
    if(minApparentTempCelcius < minTempCelcius) {
        weatherString = [NSString stringWithFormat:@"%@ Due to windchill, the low temperature will "
                          "feel like %d degrees celcius..", weatherString, minApparentTempCelcius];
    }
    
    // Save Weather data
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:weatherString forKey:@"Weather data"];
    
    // Log success
    [userDefaults setBool:YES forKey:@"Weather Fetch Successful"];
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
