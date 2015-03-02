//
//  BackendData.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-03-02.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BackendData : NSObject
@property (nonatomic, weak) NSString *backendUrl;
@property (nonatomic, weak) NSString *updateFromTimeScript;
@property (nonatomic, weak) NSString *updateFromTimeArgument;
@property (nonatomic, weak) NSString *updateToTimeScript;
@property (nonatomic, weak) NSString *updateToTimeArgument;
@property (nonatomic, strong) NSString *deviceId;
@end
