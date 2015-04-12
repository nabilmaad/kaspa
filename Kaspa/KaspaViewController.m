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
@property (weak, nonatomic) IBOutlet UIImageView *centerImage;
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextLabel;
@property (weak, nonatomic) IBOutlet UILabel *centerLabel;
@property (strong, nonatomic) NSMutableArray *topNews;
@property int indexOfCurrentlySpokenItemInTopNews;
@property (strong, nonatomic) NSString *topNewsStringBeingSpoken;
@property (nonatomic, strong) NSManagedObjectContext *savedTopicDatabaseContext;
@end

@implementation KaspaViewController

// Lazy instantiation of topNewsStringBeingSpoken
- (NSString *)topNtopNewsStringBeingSpokenews {
    if(!_topNewsStringBeingSpoken) {
        _topNewsStringBeingSpoken = [[NSString alloc] init];
    }
    return _topNewsStringBeingSpoken;
}


// Lazy instantiation of the top news array
- (NSMutableArray *)topNews {
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
    
    // Display briefing is ready
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        [self.centerImage setImage:[UIImage imageNamed:@"Ready"]];
        self.centerLabel.text = @"Briefing is ready";
    } else {
        [self.centerImage setImage:[UIImage imageNamed:@"Kaspa_Logo"]];
        self.centerLabel.text = @"Welcome!";
    }
    
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        // app already launched
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // This is the first launch ever
        
        // Create dummy saved topic
        self.savedTopicDatabaseContext = [self createMainQueueManagedObjectContext];
        NSManagedObjectContext *context = self.savedTopicDatabaseContext;
        [context performBlock:^{
            [SavedTopic addToSavedList:@"Today"
                              withData:@"This is only a test"
                               andDate:[NSDate dateWithTimeIntervalSince1970:1]
                inManagedObjectContext:self.savedTopicDatabaseContext];
            [context save:NULL];
        }];

        // Play tutorial
        [self playTutorial];
    }
}

#pragma mark - Tutorial
- (void)playTutorial {
    // Initialize speech synthesizer
    self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    self.speechSynthesizer.delegate = self;

    // Grey out tab bar
    self.tabBarController.tabBar.barTintColor = [self colorwithHexString:@"#EFEFEF" alpha:.9];
    self.tabBarController.tabBar.tintColor = [UIColor redColor];
    
    // Intro
    NSString *tutorialSpeech = @"Hello there. My name is Kaspa, and I will be delivering your personalized briefing every morning.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    tutorialSpeech = @"But before doing that, let me take you through a quick tutorial on using this app.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Preferences
    tutorialSpeech = @"The first thing you need to do is set up your preferences.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    tutorialSpeech = @"This is done in the configuration tab.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Switch to preferences tab
    // From - To
    tutorialSpeech = @"The first two settings on this screen are there to tell me when is the best time to collect my data.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"They also help me determine when I should send you an alert that your briefing is ready.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"You typically want to use them to tell me what time you go to bed, and when you are likely to wake up.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Channels
    tutorialSpeech = @"The third setting is used to select the channels to be included in your briefing.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Use it to toggle your channels on or off.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Myo
    tutorialSpeech = @"The last item helps you connect a Myo armband that you can use to control your briefing.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Simply scan for available devices, and select yours from the list.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Kaspa
    tutorialSpeech = @"Let's head back to the main tab where you will be interacting with your briefing.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Switch to main tab
    // Play
    tutorialSpeech = @"This is what you will see when your briefing is ready to be played.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Hit the play button to initiate it.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"If you are using the Myo armband, spreading your fingers will also play or pause your briefing.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Icons and labels
    tutorialSpeech = @"While your briefing is being played, you will see the current topic at the top, as well as the next one in the bottom.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Skipping
    tutorialSpeech = @"To skip to the next topic, simply swipe right on this screen.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Waving right while wearing your Myo armband will have the same effect.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Saving
    tutorialSpeech = @"In some cases, you might want to save to current topic and listen to it later.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"To do that, swipe down on this screen.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"With a Myo armband, make a fist to save a topic. You can think of it as grabbing what you are currently hearing "\
                      "so you can listen to it later.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // News details
    tutorialSpeech = @"With the top news channel enabled, I will only tell you the headlines by default.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"If you would like to know more about something you're hearing, double tap the touch screen and I will give you more details.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Making the fist gesture twice in a row using Myo will also trigger the details.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Saved tab
    tutorialSpeech = @"Let's head over to the last tab.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    // Switch to tab
    tutorialSpeech = @"This is where you can review the topics you previously saved.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Tapping on a saved topic will play or pause it, and the icon on the right will show you its status.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    
    // Done
    tutorialSpeech = @"You are now ready to use the application.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
    tutorialSpeech = @"Head over to the configuration tab, and set up your preferences.";
    [self setUpVoiceAndSpeakTutorial:[[AVSpeechUtterance alloc] initWithString:tutorialSpeech]];
}

- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

#pragma mark - Getting color from HEX
- (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
{
    //-----------------------------------------
    // Convert hex string to an integer
    //-----------------------------------------
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    //-----------------------------------------
    // Create color object, specifying alpha
    //-----------------------------------------
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
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
        self.tabBarItem.badgeValue = nil;
        
        // Set up briefing
        [self createBriefing];
        
        // Set up text to speech
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;

        // Remove briefing ready view
        [self.centerImage setImage:nil];
        self.centerLabel.text = @"";
        
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

- (void)setUpVoiceAndSpeakTutorial:(AVSpeechUtterance *)utterance {
    utterance.pitchMultiplier = 1.25f;
    utterance.rate = 0.12f;
    utterance.preUtteranceDelay = 0.05f;
    utterance.postUtteranceDelay = 0.05f;
    
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
        NSDictionary *topNewsOfBriefing = [self.briefing objectForKey:@"Top News"];
        // Skip from headline to next
        if([topNewsOfBriefing objectForKey:self.topNewsStringBeingSpoken]) {
            // Do nothing as the next utterance will be triggered in the delegate
        } else {
            // A headline is being spoken
            
            // Check if there's a headline coming up, and speak it
            bool foundHeadline = false;
            for(int i=self.indexOfCurrentlySpokenItemInTopNews; i<[self.topNews count]; i++) {
                // Without ending "]"
                NSString *itemInTopNewsArray = [((AVSpeechUtterance *)self.topNews[i]).speechString
                                                substringToIndex:[((AVSpeechUtterance *)self.topNews[i]).speechString length] - 1];
                if([topNewsOfBriefing objectForKey:itemInTopNewsArray]) {
                    foundHeadline = true;
                    self.indexOfCurrentlySpokenItemInTopNews = i-1;
                    break;
                }
            }
            
            // Didn't find headline => Say good bye
            if(!foundHeadline) {
                [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
            }
        }
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
            [self playButtonTapped:nil];
            break;
    }
}

#pragma mark - SpeechSynthesizer delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    // Save top news sentence spoken
    if([self.currentLabel.text isEqual:@"Top News"])
        self.topNewsStringBeingSpoken = [utterance.speechString substringToIndex:[utterance.speechString length] - 1];
    
    // Change icons and text labels
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
        self.currentLabel.text = @"";
        self.nextLabel.text = @"";
        self.centerLabel.text = @"Done!";
        [self.currentImage setImage:nil];
        [self.nextImage setImage:nil];
        [self.centerImage setImage:[UIImage imageNamed:@"Done"]];
    }
    
    // Tutorial related actions
    else if([utterance.speechString isEqual:@"Let's head back to the main tab where you will be interacting with your briefing."]) {
        [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:@"⬇︎"];
        [self.centerImage setImage:[UIImage imageNamed:@"Ready"]];
        self.centerLabel.text = @"Briefing is ready";
    } else if([utterance.speechString isEqual:@"If you are using the Myo armband, spreading your fingers will also play or pause your briefing."]) {
        // Spread fingers image
        self.centerLabel.text = @"";
        [self.centerImage setImage:[UIImage imageNamed:@"MyoSpreadFingers"]];
    } else if([utterance.speechString isEqual:@"While your briefing is being played, you will see the current topic at the top, as well as the next one in the bottom."]) {
        // Remove old image
        [self.centerImage setImage:nil];
        
        // Set example content
        self.currentLabel.text = @"Weather";
        self.nextLabel.text = @"Calendar Events";
        [self.currentImage setImage:[UIImage imageNamed:@"Weather"]];
        [self.nextImage setImage:[UIImage imageNamed:@"Calendar"]];
        [self.playButton setImage:[UIImage imageNamed:@"Pause"]];
    } else if([utterance.speechString isEqual:@"To skip to the next topic, simply swipe right on this screen."]) {
        // Remove old content
        self.currentLabel.text = @"";
        self.nextLabel.text = @"";
        [self.currentImage setImage:nil];
        [self.nextImage setImage:nil];
        
        // Swipe right image
        [self.centerImage setImage:[UIImage imageNamed:@"SwipeRight"]];
    } else if([utterance.speechString isEqual:@"Waving right while wearing your Myo armband will have the same effect."]) {
        // Wave right image
        [self.centerImage setImage:[UIImage imageNamed:@"MyoWaveRight"]];
    } else if([utterance.speechString hasPrefix:@"In some cases, you might want to save to current topic and listen to it later."]) {
        // Save image
        [self.centerImage setImage:[UIImage imageNamed:@"SaveInTutorial"]];
    } else if([utterance.speechString isEqual:@"To do that, swipe down on this screen."]) {
        // Swipe down
        [self.centerImage setImage:[UIImage imageNamed:@"SwipeDown"]];
    } else if([utterance.speechString hasPrefix:@"With a Myo armband, make a fist to save a topic."]) {
        // Myo Fist
        [self.centerImage setImage:[UIImage imageNamed:@"MyoFist"]];
    } else if([utterance.speechString isEqual:@"With the top news channel enabled, I will only tell you the headlines by default."]) {
        // News
        [self.centerImage setImage:[UIImage imageNamed:@"News"]];
        self.centerLabel.text = @"Top News";
    } else if([utterance.speechString isEqual:@"If you would like to know more about something you're hearing, double tap the touch screen and I will give you more details."]) {
        // Double tap
        [self.centerImage setImage:[UIImage imageNamed:@"DoubleTap"]];
        self.centerLabel.text = @"";
    } else if([utterance.speechString isEqual:@"Making the fist gesture twice in a row using Myo will also trigger the details."]) {
        // First twice
        [self.centerImage setImage:[UIImage imageNamed:@"MyoFistTwice"]];
    } else if([utterance.speechString isEqual:@"Let's head over to the last tab."]) {
        // Tab arrow
        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:@"⬇︎"];
        [self.playButton setImage:[UIImage imageNamed:@"Play"]];
    } else if([utterance.speechString isEqual:@"This is where you can review the topics you previously saved."]) {
        // Swich to tab
        self.tabBarController.selectedIndex = 2;
        [[self.tabBarController.tabBar.items objectAtIndex:2] setBadgeValue:nil];
    } else if([utterance.speechString isEqual:@"Head over to the configuration tab, and set up your preferences."]) {
        // Restore white tab bar
        self.tabBarController.tabBar.barTintColor = [UIColor whiteColor];
        self.tabBarController.tabBar.tintColor = [self colorwithHexString:@"#1D62F0" alpha:.9];
        
        // Restore briefing ready image
        [self.centerImage setImage:[UIImage imageNamed:@"Ready"]];
        self.centerLabel.text = @"Briefing is ready";
        
        // Make the speechsynthesizer null to be able to speak the briefing
        self.speechSynthesizer = nil;
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
    } else if([utterance.speechString hasSuffix:@"Have a wonderful day!"]) {
        // End of briefing
        [self.playButton setImage:[UIImage imageNamed:@"Play"]];
    }
    
    // Tutorial related actions
    else if([utterance.speechString isEqual:@"The first thing you need to do is set up your preferences."]) {
        [[self.tabBarController.tabBar.items objectAtIndex:0] setBadgeValue:@"⬇︎"];
    } else if([utterance.speechString isEqual:@"This is done in the configuration tab."]) {
        self.tabBarController.selectedIndex = 0;
        [[self.tabBarController.tabBar.items objectAtIndex:0] setBadgeValue:nil];
        // Clear welcome image
        [self.centerImage setImage:nil];
        self.centerLabel.text = @"";
    } else if([utterance.speechString isEqual:@"Let's head back to the main tab where you will be interacting with your briefing."]) {
        self.tabBarController.selectedIndex = 1;
        [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
    }
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    if([utterance.speechString hasSuffix:@"]"]) {
        // Say goodbye
        [self speakGoodbye];
    }
}

@end
