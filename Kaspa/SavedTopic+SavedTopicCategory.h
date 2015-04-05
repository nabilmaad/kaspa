//
//  SavedTopic+SavedTopicCategory.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-04.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "SavedTopic.h"

@interface SavedTopic (SavedTopicCategory)

+ (SavedTopic *)addToSavedList:(NSString *)channel
                      withData:(id)data
                       andDate:(NSDate *)date
        inManagedObjectContext:(NSManagedObjectContext *)context;

@end
