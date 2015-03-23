//
//  ConfigurationTableViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-25.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "ConfigurationTableViewController.h"
#import "FromTimePickerViewController.h"
#import "ToTimePickerViewController.h"
#import <MyoKit/MyoKit.h>

@interface ConfigurationTableViewController ()
@end

@implementation ConfigurationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    if(buttonIndex == 1)
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: UIApplicationOpenSettingsURLString]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Unselect the selected row if any
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection)
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Calendar access
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if(!granted) {
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"Calendar Events state"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Calendar Access"
                                                                message:@"Enable calendar access for Kaspa in Settings."
                                                               delegate:self
                                                      cancelButtonTitle:@"Not Now"
                                                      otherButtonTitles:@"Settings", nil];
                [alert show];
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - cell selection behaviour

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if([cell.reuseIdentifier isEqualToString:@"Connect Myo"])
        [self pushMyoConnectionView];
}


#pragma mark - Navigation

- (void)prepareFromTimePickerViewController:(FromTimePickerViewController *)vc {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [timeFormat setTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Set default time for first time users
    if([userDefaults objectForKey:@"fromTime"] == nil ||
       [userDefaults objectForKey:@"fromTime"] == (id)[NSNull null]) {
        NSDate *defaultFromTime = [timeFormat dateFromString:@"22:00"];
        vc.myFromTime = defaultFromTime;
        [userDefaults setObject:defaultFromTime forKey:@"fromTime"];
        [userDefaults synchronize];
    }
    else
        vc.myFromTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"fromTime"];
}

- (void)prepareToTimePickerViewController:(ToTimePickerViewController *)vc {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [timeFormat setTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Set default time for first time users
    if([userDefaults objectForKey:@"toTime"] == nil ||
       [userDefaults objectForKey:@"toTime"] == (id)[NSNull null]) {
        NSDate *defaultToTime = [timeFormat dateFromString:@"07:00"];
        vc.myToTime = defaultToTime;
        [userDefaults setObject:defaultToTime forKey:@"toTime"];
        [userDefaults synchronize];
    }
    else
        vc.myToTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"toTime"];
}

-(void)pushMyoConnectionView {
    TLMSettingsViewController *settings = [[TLMSettingsViewController alloc] init];
    [self.navigationController pushViewController:settings animated:YES];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"Show From Time"]) {
        if([segue.destinationViewController isKindOfClass:[FromTimePickerViewController class]]) {
            [self prepareFromTimePickerViewController:segue.destinationViewController];
        }
    } else if([segue.identifier isEqualToString:@"Show To Time"]) {
        if([segue.destinationViewController isKindOfClass:[ToTimePickerViewController class]]) {
            [self prepareToTimePickerViewController:segue.destinationViewController];
        }
    }
}

@end
