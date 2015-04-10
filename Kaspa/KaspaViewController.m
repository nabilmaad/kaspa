//
//  KaspaViewController.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-01-23.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "KaspaViewController.h"
#import "KaspaViewController+MOC.h"
#import "SavedTopic+SavedTopicCategory.h"
#import "SavedTopicsDatabaseAvailability.h"

@interface KaspaViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *playButton;
@property (strong, nonatomic) NSMutableDictionary *briefing;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;
@property (weak, nonatomic) IBOutlet UIImageView *nextImage;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextLabel;
@property (strong, nonatomic) NSMutableArray *topNews;
@property int indexOfCurrentlySpokenItemInTopNews;
@property (nonatomic, strong) NSManagedObjectContext *savedTopicDatabaseContext;
@end

@implementation KaspaViewController

// Lazy instantiation of the top news array
-(NSMutableArray *)topNews {
    if(!_topNews) {
        _topNews = [[NSMutableArray alloc] init];
    }
    return _topNews;
}

// Post notification when context is set
- (void)setSavedTopicDatabaseContext:(NSManagedObjectContext *)savedTopicDatabaseContext {
    _savedTopicDatabaseContext = savedTopicDatabaseContext;
    
    NSDictionary *userInfo = self.savedTopicDatabaseContext ? @{ SavedTopicsDatabaseAvailabilityContext : self.savedTopicDatabaseContext } : nil;
    
    // Post notification to tell the saved table list there's new data
    [[NSNotificationCenter defaultCenter] postNotificationName:SavedTopicsDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add tap recognizer to play image
    [self.playButton setImage:[UIImage imageNamed:@"Play"]];
    [self.playButton setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playButtonTapped:)];
    [singleTap setNumberOfTapsRequired:1];
    [self.playButton addGestureRecognizer:singleTap];
    
    // Posted when a new pose is available from a TLMMyo.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
}

- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Briefing creation
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
    
    // Top News
    if([userDefaults boolForKey:@"Top News state"])
        [self.briefing setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"Top News data"] forKey:@"Top News"];
}



#pragma mark Play/Pause reaction
-(void)playButtonTapped:(UIGestureRecognizer *)recognizer
{
    if([self image:self.playButton.image isEqualTo:[UIImage imageNamed:@"Play"]])
        [self.playButton setImage:[UIImage imageNamed:@"Pause"]];
    else
        [self.playButton setImage:[UIImage imageNamed:@"Play"]];
    [self playButtonPressed:nil];
}

- (void)playButtonPressed:(id)sender {
    if(!self.speechSynthesizer) {
        // Clear notification if it's there
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        // Set up briefing
        [self createBriefing];
        
        // Set up text to speech
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;

        // Speak topics if they exist
        if([self.briefing objectForKey:@"Today"])
            [self speakToday];
        if([self.briefing objectForKey:@"Weather"])
            [self speakWeather];
        if([self.briefing objectForKey:@"Calendar Events"])
            [self speakCalendarEvents];
        if([self.briefing objectForKey:@"Top News"])
            [self speakTopNews];

    } else if(self.speechSynthesizer.speaking && !self.speechSynthesizer.paused) {
        // Pause briefing
        [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryWord];
    } else {
        // Resume briefing
        [self.speechSynthesizer continueSpeaking];
    }
}

#pragma mark - Speaking utterances
- (void)speakToday {
    // Today
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[self.briefing objectForKey:@"Today"]];
    [self setUpVoiceAndSpeak:utterance];
}

- (void)speakWeather {
    // Weather
    NSString *weatherData = [self.briefing objectForKey:@"Weather"];
    NSArray *weatherSentences = [weatherData componentsSeparatedByString:@".."];
    for(NSString *weatherSentence in weatherSentences) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:weatherSentence];
        [self setUpVoiceAndSpeak:utterance];
    }
}


- (void)speakCalendarEvents {
    // Calendar events
    NSArray *arrayOfEvents = [self.briefing objectForKey:@"Calendar Events"];
    for(NSString *eventSentence in arrayOfEvents) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:eventSentence];
        [self setUpVoiceAndSpeak:utterance];
    }
}

- (void)speakGoodbye {
    NSString *goodBye = @"This concludes your briefing. Have a wonderful day!";
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:goodBye];
    [self setUpVoiceAndSpeak:utterance];
}

- (void)speakTopNews {
    // Top news
    NSString *topNewsIntroduction = @"Here are the current headlines. Remember that I can tell you more details if you ask me to.]";
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:topNewsIntroduction];
    [self setUpVoiceAndSpeak:utterance];
    
    // Only add the top news utterances to the array if they're not there yet
    if(!self.topNews || [self.topNews count] == 0) {
        for(NSString *key in [self.briefing objectForKey:@"Top News"]) {
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[NSString stringWithFormat:@"%@]",key]];
            [self.topNews addObject:utterance];
        }
    }
    
    // This is used to correctly start at index 0 when the next utterance starts
    self.indexOfCurrentlySpokenItemInTopNews = -1;
}

- (void)setUpVoiceAndSpeak:(AVSpeechUtterance *)utterance {
    utterance.pitchMultiplier = 1.25f;
    utterance.rate = 0.15f;
    utterance.preUtteranceDelay = 0.1f;
    utterance.postUtteranceDelay = 0.1f;
    
    // Speak
    [self.speechSynthesizer speakUtterance:utterance];
}

#pragma mark - Jumping to next topic
- (IBAction)swipedRight:(id)sender {
    if(self.speechSynthesizer.speaking) {
        // Stop speaking
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        
        // Say "Skipping"
        [self saySkipping];
        
        // Skip
        [self skipToNextSubject];
    }
}

- (void)skipToNextSubject {
    // Find current subject
    NSString *currentSubject = self.currentLabel.text;
    
    // Speak next subject(s)
    if([currentSubject isEqualToString:@"Today"]) {
        [self speakWeather];
        [self speakCalendarEvents];
        [self speakTopNews];
    } else if([currentSubject isEqualToString:@"Weather"]) {
        [self speakCalendarEvents];
        [self speakTopNews];
    } else if([currentSubject isEqualToString:@"Calendar Events"]) {
        [self speakTopNews];
    }  else if([currentSubject isEqualToString:@"Top News"]) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
    }
}

- (void)saySkipping {
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Skipping."];
    [self setUpVoiceAndSpeak:utterance];
}

#pragma mark - Saving topic
- (IBAction)swipedDown:(id)sender {
    if(self.speechSynthesizer.speaking) {
        // Stop speaking
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
        
        // Say "Saving"
        [self saySaving];
        
        // Save
        [self saveCurrentTopic];
        
        // Skip
        [self skipToNextSubject];
    }
}

- (void)saveCurrentTopic {
    // Find current topic channel
    NSString *currentTopicChannel = self.currentLabel.text;
    
    // Save currently spoken topic to saved list tab
    self.savedTopicDatabaseContext = [self createMainQueueManagedObjectContext];
    NSManagedObjectContext *context = self.savedTopicDatabaseContext;
    [context performBlock:^{
        [SavedTopic addToSavedList:currentTopicChannel
                          withData:[self.briefing objectForKey:currentTopicChannel]
                           andDate:[NSDate date]
            inManagedObjectContext:self.savedTopicDatabaseContext];
        [context save:NULL];
    }];
}

- (void)saySaving {
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Saving."];
    [self setUpVoiceAndSpeak:utterance];
}

#pragma mark - Going in news details
- (IBAction)doubleTapped:(id)sender {
    // Get headline being spoken at the moment
    NSString *modifiedHeadlineBeingSpoken = ((AVSpeechUtterance *)[self.topNews objectAtIndex:self.indexOfCurrentlySpokenItemInTopNews]).speechString;
    // Removing the bracket from the end
    NSString *headlineBeingSpoken = [modifiedHeadlineBeingSpoken substringToIndex:[modifiedHeadlineBeingSpoken length] - 1];
    // Get its matching detailed description
    NSString *detailedArticleToBeAdded = [[self.briefing objectForKey:@"Top News"] objectForKey:headlineBeingSpoken];
    // Create the utterances for it
    NSMutableArray *detailedArticleSentences = [[detailedArticleToBeAdded componentsSeparatedByString:@"."] mutableCopy];
    [detailedArticleSentences removeLastObject]; // It's an empty string
    int index = 0; // Used to correctly place sentences one after another in the array
    for(NSString *sentence in detailedArticleSentences) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[NSString stringWithFormat:@"%@]", sentence]];
        // Add the description to the array of top news right after
        [self.topNews insertObject:utterance atIndex:(self.indexOfCurrentlySpokenItemInTopNews+1+index)];
        index++;
    }
    // Mention that we're moving to the next headline
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[NSString stringWithFormat:@"Moving to the next headline.]"]];
    [self.topNews insertObject:utterance atIndex:(self.indexOfCurrentlySpokenItemInTopNews+1+index)];
}


#pragma mark - Myo
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
            if(self.speechSynthesizer.speaking) {
                [self swipedDown:nil];
            }
            break;
        case TLMPoseTypeWaveIn:
            NSLog(@"Wave in");
            if(self.speechSynthesizer.speaking) {
                [self swipedRight:nil];
            }
            break;
        case TLMPoseTypeWaveOut:
            NSLog(@"Wave out");
            if(self.speechSynthesizer.speaking)
                [self swipedRight:nil];
            break;
        case TLMPoseTypeFingersSpread:
            NSLog(@"Fingers spread");
            [self playButtonPressed:nil];
            break;
            
    }
}

#pragma mark - SpeechSynthesizer delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    if([utterance.speechString hasPrefix:@"Today is"]) {
        // Today image and label
        self.currentLabel.text = @"Today";
        self.nextLabel.text = @"Weather";
        [self.currentImage setImage:[UIImage imageNamed:@"Today"]];
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
        self.nextLabel.text = @"Top News";
        [self.currentImage setImage:[UIImage imageNamed:@"Calendar"]];
        [self.nextImage setImage:[UIImage imageNamed:@"News"]];
    } else if([utterance.speechString hasPrefix:@"Here are the current headlines"]) {
        // Calendar image and label
        self.currentLabel.text = @"Top News";
        self.nextLabel.text = @"Done!";
        [self.currentImage setImage:[UIImage imageNamed:@"News"]];
        [self.nextImage setImage:[UIImage imageNamed:@"Done"]];
    } else if([utterance.speechString hasPrefix:@"This concludes your briefing."]) {
        // Calendar image and label
        self.currentLabel.text = @"Done!";
        self.nextLabel.text = @"";
        [self.currentImage setImage:[UIImage imageNamed:@"Done"]];
        [self.nextImage setImage:nil];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    // Detect if it's a top news utterance and that there's a next one to speak
    if([utterance.speechString hasSuffix:@"]"]) {
        if(self.indexOfCurrentlySpokenItemInTopNews < (int)([self.topNews count]-1)) {
            self.indexOfCurrentlySpokenItemInTopNews++;
            [self setUpVoiceAndSpeak:[self.topNews objectAtIndex:self.indexOfCurrentlySpokenItemInTopNews]];
        } else if(self.indexOfCurrentlySpokenItemInTopNews == [self.topNews count]-1) {
            // Say goodbye
            [self speakGoodbye];
        }
    }
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    if([utterance.speechString hasSuffix:@"]"]) {
        // Say goodbye
        [self speakGoodbye];
    }
}

@end
