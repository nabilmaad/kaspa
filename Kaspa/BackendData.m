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
        self.backendUrl = @"http://54.84.109.235";
        
        // Update From Time
        self.updateFromTimeScript = @"updateFromTime.php";
        self.updateFromTimeArgument = @"newFromTime";
        
        // Update To Time
        self.updateToTimeScript = @"updateToTime.php";
        self.updateToTimeArgument = @"newToTime";
        
        // Device ID
        self.deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    
    return self;
}

@end
