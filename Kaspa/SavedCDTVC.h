//
//  SavedCDTVC.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-05.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SavedCDTVC : CoreDataTableViewController <AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
