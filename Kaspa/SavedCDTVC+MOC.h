//
//  SavedCDTVC+MOC.h
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-06.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "SavedCDTVC.h"

@interface SavedCDTVC (MOC)

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;

@end
