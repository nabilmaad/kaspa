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

#pragma Briefing creation
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

#pragma Play/Pause reaction
- (IBAction)playButtonPressed:(id)sender {
    if(!self.speechSynthesizer) {
        // Set up briefing
        [self createBriefing];
        
        // Set up text to speech
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;
        
        for(NSString *key in self.briefing) {
            if([key isEqualToString:@"Today"]) {
                [self speakToday];
            } else if([key isEqualToString:@"Weather"]) {
                [self speakWeather];
            }else if([key isEqualToString:@"Calendar Events"]) {
                [self speakCalendarEvents];
            }
            else {
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

#pragma Speaking utterances
- (void)speakToday {
    // Today
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:@"Today"]];
    [self setUpVoiceAndSpeak:utterance];
}

- (void)speakWeather {
    // Weather
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:@"Weather"]];
    [self setUpVoiceAndSpeak:utterance];
}


- (void)speakCalendarEvents {
    // Calendar events
    NSArray *arrayOfEvents = [self.briefing objectForKey:@"Calendar Events"];
    for(NSString *eventSentence in arrayOfEvents) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:eventSentence];
        [self setUpVoiceAndSpeak:utterance];
    }
}

- (void)setUpVoiceAndSpeak:(AVSpeechUtterance *)utterance {
    utterance.pitchMultiplier = 1.25f;
    utterance.rate = 0.15f;
    utterance.preUtteranceDelay = 0.1f;
    utterance.postUtteranceDelay = 0.1f;
    
    // Speak
    [self.speechSynthesizer speakUtterance:utterance];
}

#pragma Jumping to next topic
- (IBAction)swipedRight:(id)sender {
    if(self.speechSynthesizer.speaking)
        [self skipToNextSubject];
}

- (void)skipToNextSubject {
    // Stop speaking
    [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];

    // Find current subject
    NSString *currentSubject = self.currentLabel.text;
    
    // Speak next subject(s)
    if([currentSubject isEqualToString:@"Today"]) {
        [self speakWeather];
        [self speakCalendarEvents];
    } else if([currentSubject isEqualToString:@"Weather"]) {
        [self speakCalendarEvents];
    }
}

#pragma Saving topic
- (IBAction)swipedDown:(id)sender {
    NSLog(@"User swiped down");
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
            NSLog(@"Fist");
            break;
        case TLMPoseTypeWaveIn:
            NSLog(@"Wave in");
            if(self.speechSynthesizer.speaking && pose.myo.arm == TLMArmLeft) {
                [self skipToNextSubject];
            }
            break;
        case TLMPoseTypeWaveOut:
            NSLog(@"Wave out");
            if(self.speechSynthesizer.speaking && pose.myo.arm == TLMArmRight)
                [self skipToNextSubject];
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
