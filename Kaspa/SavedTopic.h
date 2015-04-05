//
//  SavedTopic.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-04.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SavedTopic : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * channel;
@property (nonatomic, retain) id data;

@end
