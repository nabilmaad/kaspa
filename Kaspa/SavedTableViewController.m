//
//  SavedTableViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-30.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "SavedTableViewController.h"

@interface SavedTableViewController ()

@end

@implementation SavedTableViewController

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Saved Track Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    // Title & Date
    cell.textLabel.text = @"Weather Today";
    cell.detailTextLabel.text = @"Jan. 30 2015";
    
    // Label for duration
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 220.0, 15.0)];
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    durationLabel.tag = 4;
    durationLabel.font = [UIFont systemFontOfSize:15.0];
    durationLabel.textColor = [UIColor darkGrayColor];
    durationLabel.text = @"0:25";
    
    [cell.contentView addSubview:durationLabel];
    
    // Position label on the right
    NSDictionary *labelDictionary = @{@"labelView":durationLabel};
    NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[labelView]-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:labelDictionary];
    NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[labelView]"
                                                                        options:NSLayoutFormatAlignAllCenterY
                                                                        metrics:nil
                                                                          views:labelDictionary];
    [cell.contentView addConstraints:constraint_POS_V];
    [cell.contentView addConstraints:constraint_POS_H];
    
    return cell;
}

// Add title to section
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return NSLocalizedString(@"PREVIOUSLY SAVED:", @"");
}

#pragma mark - Play all tracks
- (IBAction)PlayAllButtonPressed:(id)sender {
    NSLog(@"Playing All");
}

#pragma mark - Extra stuff
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
