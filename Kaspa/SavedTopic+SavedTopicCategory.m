//
//  SavedTopic+SavedTopicCategory.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-04.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "SavedTopic+SavedTopicCategory.h"

@implementation SavedTopic (SavedTopicCategory)

+ (SavedTopic *)addToSavedList:(NSString *)channel
                      withData:(id)data
                       andDate:(NSDate *)date
        inManagedObjectContext:(NSManagedObjectContext *)context {
    
    SavedTopic *savedTopic = nil;
   
    // Create a request on the core data DB to check if it already exists
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SavedTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"data = %@", data];
    
    // Execute the fetch requet
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    // Check if there's a match or error
    if(!matches || error) {
        // Handle error
    } else {
        // Add to DB
        savedTopic = [NSEntityDescription insertNewObjectForEntityForName:@"SavedTopic"
                                                   inManagedObjectContext:context];
        // Topic channel
        savedTopic.channel = channel;
        
        // Topic date
        savedTopic.date = [NSDate date];
        
        // Topic data
        savedTopic.data = data;
    }
    
    return savedTopic;
}

+(SavedTopic *)removeFromSavedListWithDate:(NSDate *)date
                    inManagedObjectContext:(NSManagedObjectContext *)context {

    SavedTopic *topicToDelete = nil;
    
    // Create a request on the core data DB to check if it already exists
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SavedTopic"];
    request.predicate = [NSPredicate predicateWithFormat:@"date = %@", date];
    
    // Execute the fetch requet
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];

    // Check if there's a match or error
    if(!matches || error || ([matches count] == 0)) {
        // Handle error
    } else {
        // Found object to delete
        topicToDelete = [matches firstObject];
        [context deleteObject:topicToDelete];
    }
    
    return topicToDelete;
}

@end
