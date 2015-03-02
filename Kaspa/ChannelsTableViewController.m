//
//  ChannelsTableViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-02-01.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "ChannelsTableViewController.h"

@interface ChannelsTableViewController ()

@end

@implementation ChannelsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/
 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        // Add a switch with correct state
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview setOn:[[NSUserDefaults standardUserDefaults] boolForKey:
                           [NSString stringWithFormat:@"channel%ld", (long)indexPath.row]]];
        cell.accessoryView = switchview;
        [switchview addTarget:self
                     action:@selector(switchIsToggled:)
           forControlEvents:UIControlEventValueChanged];
    }
    
    // Add label
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Today";
            break;
            
        case 1:
            cell.textLabel.text = @"Weather";
            break;
            
        case 2:
            cell.textLabel.text = @"Calendar Events";
            break;
        
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Switch toggles
- (void)switchIsToggled:(id)sender {
    
    // Find the row of the toggled switch
    CGPoint switchPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSInteger toggleRow = [self.tableView indexPathForRowAtPoint:switchPosition].row;
    
    // Save user preference
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:[sender isOn] forKey:[NSString stringWithFormat:@"channel%ld", (long)toggleRow]];
    [userDefaults synchronize];
}


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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
