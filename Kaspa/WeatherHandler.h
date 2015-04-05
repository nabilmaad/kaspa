//
//  LocationFetcher.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-03-22.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface WeatherHandler : NSObject <CLLocationManagerDelegate>
-(void) getWeatherData;
@end
