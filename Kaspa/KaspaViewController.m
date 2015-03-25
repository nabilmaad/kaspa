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
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;
@property (weak, nonatomic) IBOutlet UIImageView *nextImage;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextLabel;
@end

@implementation KaspaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Posted when a new pose is available from a TLMMyo.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
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
    if(!self.speechSynthesizer) {
        // Set up briefing
        [self createBriefing];
        
        // Set up text to speech
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;
        
        for(NSString *key in self.briefing) {
            if([key isEqualToString:@"Calendar Events"]) {
                NSArray *arrayOfEvents = [self.briefing objectForKey:key];
                for(NSString *eventSentence in arrayOfEvents) {
                    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:eventSentence];
                    utterance.pitchMultiplier = 1.25f;
                    utterance.rate = 0.15f;
                    utterance.preUtteranceDelay = 0.1f;
                    utterance.postUtteranceDelay = 0.1f;
                    // Speak
                    [self.speechSynthesizer speakUtterance:utterance];
                }
            }
            else {
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:key]];
                utterance.pitchMultiplier = 1.25f;
                utterance.rate = 0.15f;
                utterance.preUtteranceDelay = 0.1f;
                utterance.postUtteranceDelay = 0.1f;
                // Speak
                [self.speechSynthesizer speakUtterance:utterance];
            }
        }
    } else if(self.speechSynthesizer.speaking && !self.speechSynthesizer.paused) {
        // Pause briefing
        [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
    } else {
        // Resume briefing
        [self.speechSynthesizer continueSpeaking];
    }
}

- (IBAction)swipedRight:(id)sender {
    NSLog(@"User swiped right");
}

- (IBAction)swipedDown:(id)sender {
    NSLog(@"User swiped right");
}

#pragma Myo
- (void)didReceivePoseChange:(NSNotification *)notification {
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    
    // Handle the cases of the TLMPoseType enumeration
    switch (pose.type) {
        case TLMPoseTypeUnknown:
        case TLMPoseTypeRest:
        case TLMPoseTypeDoubleTap:
            NSLog(@"Double tap");
            break;
        case TLMPoseTypeFist:
            NSLog(@"First");
            break;
        case TLMPoseTypeWaveIn:
            NSLog(@"Wave in");
            break;
        case TLMPoseTypeWaveOut:
            NSLog(@"Wave out");
            break;
        case TLMPoseTypeFingersSpread:
            NSLog(@"Fingers spread");
            break;
    }
}

#pragma SpeechUtterance delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    if([utterance.speechString hasPrefix:@"Today is"]) {
        // Today image and label
        self.currentLabel.text = @"Today";
        self.nextLabel.text = @"Weather";
        [self.nextImage setImage:[UIImage imageNamed:@"Weather"]];
    } else if([utterance.speechString hasPrefix:@"Let's check today's weather"]) {
        // Weather image and label
        self.currentLabel.text = @"Weather";
        self.nextLabel.text = @"Calendar Events";
        [self.currentImage setImage:[UIImage imageNamed:@"Weather"]];
        [self.nextImage setImage:[UIImage imageNamed:@"Calendar"]];
    } else if([utterance.speechString hasPrefix:@"Let's take a look at your calendar for today"]) {
        // Calendar image and label
        self.currentLabel.text = @"Calendar Events";
        self.nextLabel.text = @"";
        [self.currentImage setImage:[UIImage imageNamed:@"Calendar"]];
    }
}

@end
