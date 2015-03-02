//
//  ToTimePickerViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-31.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "ToTimePickerViewController.h"

@interface ToTimePickerViewController ()
@property (weak, nonatomic) IBOutlet UILabel *toTimeLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *toTimePicker;
@end

@implementation ToTimePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateToTimeLabel:self.myToTime];
    [self.toTimePicker setDate:self.myToTime];
}

- (void)setMyToTime:(NSDate *)myToTime {
    _myToTime = myToTime;
    [self updateToTimeLabel:myToTime];
}

- (void)updateToTimeLabel:(NSDate *)time {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    self.toTimeLabel.text = [NSString stringWithFormat:@"To %@", [timeFormat stringFromDate:time]];
}

- (IBAction)toTimePickerChanged:(UIDatePicker *)sender {
    [self updateToTimeLabel:sender.date];
    
    // Save to preferences
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [timeFormat setTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[timeFormat stringFromDate:sender.date] forKey:@"toTime"];
    [userDefaults synchronize];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
