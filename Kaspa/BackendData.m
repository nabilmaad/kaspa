//
//  BackendData.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-03-02.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "BackendData.h"

@interface BackendData()
@end

@implementation BackendData

- (id)init
{
    if( self = [super init] )
    {
        self.backendUrl = @"http://54.84.109.235/";
        self.channelsUrl = [NSString stringWithFormat:@"%@channels/", self.backendUrl];
        self.todayChannelUrl = [NSString stringWithFormat:@"%@today/", self.channelsUrl];
        self.weatherChannelUrl = [NSString stringWithFormat:@"https://api.forecast.io/forecast/462d3f7b5db0918a83c79352db4b0b7f/"];
    }
    
    return self;
}

@end
