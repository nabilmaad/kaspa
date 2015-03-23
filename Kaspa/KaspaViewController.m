//
//  KaspaViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-23.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "KaspaViewController.h"

@interface KaspaViewController ()
@property (strong, nonatomic) NSMutableDictionary *briefing;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;
@property (weak, nonatomic) IBOutlet UIImageView *nextImage;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextLabel;
@end

@implementation KaspaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.briefing = [[NSMutableDictionary alloc] init];
//    
//    // Get today
//    NSError *error;
//    NSString *stringForToday = [[NSString alloc]
//                                initWithContentsOfURL:[NSURL URLWithString:@"http://54.84.109.235/channels/today/16March2015"]
//                                encoding:NSUTF8StringEncoding
//                                error:&error];
//    if (stringForToday == nil)
//        NSLog(@"Error reading file at %@\n%@",
//              [NSURL URLWithString:@"http://54.84.109.235/channels/today/16March2015"], [error localizedFailureReason]);
//    [self.briefing setObject:stringForToday forKey:@"today"];
//    
//    // Get weather
//    NSString *stringForWeather = [[NSString alloc]
//                                initWithContentsOfURL:[NSURL URLWithString:@"http://54.84.109.235/channels/weather/OttawaONCanada"]
//                                encoding:NSUTF8StringEncoding
//                                error:&error];
//    if (stringForWeather == nil)
//        NSLog(@"Error reading file at %@\n%@",
//              [NSURL URLWithString:@"http://54.84.109.235/channels/weather/OttawaONCanada"], [error localizedFailureReason]);
//    [self.briefing setObject:stringForWeather forKey:@"weather"];
//    
//    // Print done
//    NSLog(@"Done with");
//    for (id key in self.briefing) {
//        NSLog(@"key: %@, value: %@ \n", key, [self.briefing objectForKey:key]);
//    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playButtonPressed:(id)sender {
    // Set up text to speech
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    
    for(id key in self.briefing) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:key]];
        utterance.pitchMultiplier = 1.25f;
        utterance.rate = 0.15f;
        utterance.preUtteranceDelay = 0.1f;
        utterance.postUtteranceDelay = 0.1f;
        
        [speechSynthesizer speakUtterance:utterance];
    }
}
@end
