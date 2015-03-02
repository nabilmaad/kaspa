//
//  TimePickerViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-31.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "FromTimePickerViewController.h"

@interface FromTimePickerViewController ()
@property (strong, nonatomic) BackendData* backendData;
@property (weak, nonatomic) IBOutlet UILabel *fromTimeLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *fromTimePicker;
@end

@implementation FromTimePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateFromTimeLabel:self.myFromTime];
    [self.fromTimePicker setDate:self.myFromTime];
    
    // Get backend data
    self.backendData = [[BackendData alloc] init];
}

- (void)updateFromTimeLabel:(NSDate *)time {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    self.fromTimeLabel.text = [NSString stringWithFormat:@"From %@", [timeFormat stringFromDate:time]];
}

- (IBAction)fromTimePickerChanged:(UIDatePicker *)sender {
    [self updateFromTimeLabel:sender.date];
    
    // Save to preferences
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [timeFormat setTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[timeFormat stringFromDate:sender.date] forKey:@"fromTime"];
    [userDefaults synchronize];
    
#warning Won't sync without network
    // Save to cloud
    NSString *url =[NSString stringWithFormat:
                    @"%@/%@?id=%@&%@=%@",
                    [self.backendData backendUrl],
                    [self.backendData updateFromTimeScript],
                    [self.backendData deviceId],
                    [self.backendData updateFromTimeArgument],
                    [timeFormat stringFromDate:sender.date]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [connection start];
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
