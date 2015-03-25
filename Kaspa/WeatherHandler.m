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
    NSNumber *weatherConditionCode = [[weather firstObject] objectForKey:@"id"];
    
    NSString *weatherString = [NSString stringWithFormat:
                               @"Let's check today's weather. It looks like you'll be seeing some %@. "
                               "There will be a low of %d and a high of %d degrees celcius.",
                               [[WeatherHandler weatherCodeDescription] objectForKey:weatherConditionCode],
                                [minTemp intValue], [maxTemp intValue]];
    
    // Save Weather data
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:weatherString forKey:@"Weather data"];
    [userDefaults synchronize];
}

+(NSDictionary *)weatherCodeDescription {
    // It looks like today, you'll be seeing some
    return @{
             // Thunderstorm
             @200:@"thunderstorm with light rain",
             @201:@"thunderstorm with rain",
             @202:@"thunderstorm with heavy rain",
             @210:@"light thunderstorm",
             @211:@"thunderstorm",
             @212:@"heavy thunderstorm",
             @221:@"ragged thunderstorm",
             @230:@"thunderstorm with light drizzle",
             @231:@"thunderstorm with drizzle",
             @232:@"thunderstorm with heavy drizzle",
             // Drizzle
             @300:@"light intensity drizzle",
             @301:@"drizzle",
             @302:@"heavy intensity drizzle",
             @310:@"light intensity drizzle rain",
             @311:@"drizzle rain",
             @312:@"heavy intensity drizzle rain",
             @313:@"shower rain and drizzle",
             @314:@"heavy shower rain and drizzle",
             @321:@"shower drizzle",
             // Rain
             @500:@"light rain",
             @501:@"moderate rain",
             @502:@"heavy intensity rain",
             @503:@"very heavy rain",
             @504:@"extreme rain",
             @511:@"freezing rain",
             @520:@"light intensity shower rain",
             @521:@"shower rain",
             @522:@"heavy intensity shower rain",
             @531:@"ragged shower rain",
             // Snow
             @600:@"light snow",
             @601:@"snow",
             @602:@"heavy snow",
             @611:@"sleet",
             @612:@"shower sleet",
             @615:@"light rain and snow",
             @616:@"rain and snow",
             @620:@"light shower snow",
             @621:@"shower snow",
             @622:@"heavy shower snow",
             // Atmosphere
             @701:@"mist",
             @711:@"smoke",
             @721:@"haze",
             @731:@"sand and dust whirls",
             @741:@"fog",
             @751:@"sand",
             @761:@"dust",
             @762:@"volcanic ash",
             @771:@"squalls",
             @781:@"tornado",
             // Clouds
             @800:@"clear sky",
             @801:@"few clouds",
             @802:@"scattered clouds",
             @803:@"broken clouds",
             @804:@"overcast clouds",
             // Extreme
             @900:@"tornado",
             @901:@"tropical storm",
             @902:@"hurricane",
             @903:@"cold weather",
             @904:@"hot weather",
             @905:@"windy conditions",
             @906:@"hail",
             // Additional
             @951:@"calm conditions",
             @952:@"light breeze",
             @953:@"gentle breeze",
             @954:@"moderate breeze",
             @955:@"fresh breeze",
             @956:@"strong breeze",
             @957:@"high wind, near gale conditions",
             @958:@"gale",
             @959:@"severe gale",
             @960:@"storm",
             @961:@"violent storm",
             @962:@"hurricane"
             };
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
