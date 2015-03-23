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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)createBriefing {
    self.briefing = [[NSMutableDictionary alloc] init];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Today
    if([userDefaults boolForKey:@"Today state"]) {
        [self.briefing setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"Today data"] forKey:@"Today"];
    }
    
    // Weather
    if([userDefaults boolForKey:@"Weather state"])
        [self.briefing setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"Weather data"] forKey:@"Weather"];
    
    // Calendar Events
    if([userDefaults boolForKey:@"Calendar Events state"])
        [self.briefing setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"Calendar Events data"] forKey:@"Calendar Events"];
}

- (IBAction)playButtonPressed:(id)sender {
    // Set up briefing
    [self createBriefing];
    
    // Set up text to speech
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    
    for(NSString *key in self.briefing) {
        if([key isEqualToString:@"Calendar Events"]) {
            NSLog(@"Speaking events?");
            
            NSArray *arrayOfEvents = [self.briefing objectForKey:key];
            for(NSString *eventSentence in arrayOfEvents) {
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:eventSentence];
                utterance.pitchMultiplier = 1.25f;
                utterance.rate = 0.15f;
                utterance.preUtteranceDelay = 0.1f;
                utterance.postUtteranceDelay = 0.1f;
                
                [speechSynthesizer speakUtterance:utterance];
            }
        }
        else {
            if([key isEqualToString:@"Today"]) {
                [self.nextImage setImage:[UIImage imageNamed:@"Weather"]];
            } else if([key isEqualToString:@"Weather"]) {
                [self.currentImage setImage:[UIImage imageNamed:@"Weather"]];
                [self.nextImage setImage:[UIImage imageNamed:@"Calendar"]];
            }
            NSLog(@"Speaking else?");
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:key]];
            utterance.pitchMultiplier = 1.25f;
            utterance.rate = 0.15f;
            utterance.preUtteranceDelay = 0.1f;
            utterance.postUtteranceDelay = 0.1f;
            
            [speechSynthesizer speakUtterance:utterance];
        }
    }
}
@end
