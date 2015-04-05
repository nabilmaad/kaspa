//
//  AppDelegate+MOC.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-05.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (MOC)

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;

@end
