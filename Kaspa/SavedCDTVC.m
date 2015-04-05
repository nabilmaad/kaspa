//
//  SavedCDTVC.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-05.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import "SavedCDTVC.h"
#import "SavedTopic.h"
#import "SavedTopic+SavedTopicCategory.h"
#import "SavedTopicsDatabaseAvailability.h"

@interface SavedCDTVC ()
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;
@end

@implementation SavedCDTVC

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserverForName:SavedTopicsDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[SavedTopicsDatabaseAvailabilityContext];
                                                  }];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request =  [NSFetchRequest fetchRequestWithEntityName:@"SavedTopic"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

- (AVSpeechSynthesizer *)speechSynthesizer {
    if(!_speechSynthesizer) {
        self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        self.speechSynthesizer.delegate = self;
    }
    return _speechSynthesizer;
}

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Saved Topic Cell" forIndexPath:indexPath];
    
    // Fetch the saved topic at this cell
    SavedTopic *savedTopic = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell
    NSString *cellChannel = savedTopic.channel;
    
    // Cell title & icon
    UIImage *cellImage = [[UIImage alloc] init];
    if([cellChannel isEqualToString:@"Today"]) {
        // Today
        cell.textLabel.text = @"Today Information";
        cellImage = [UIImage imageNamed:@"Calendar"];
    } else if([cellChannel isEqualToString:@"Weather"]) {
        // Weather
        cell.textLabel.text = @"Weather Information";
        cellImage = [UIImage imageNamed:@"Weather"];
    } else if([cellChannel isEqualToString:@"Calendar Events"]) {
        // Calendar
        cell.textLabel.text = @"Calendar Information";
        cellImage = [UIImage imageNamed:@"Calendar"];
    }
    // Apply image with correct sizing
    cell.imageView.image = [UIImage imageWithCGImage:cellImage.CGImage
                                               scale:cellImage.size.width/40
                                         orientation:cellImage.imageOrientation];
    
    // Cell detail (date)
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMMM dd yyyy";
    cell.detailTextLabel.text = [formatter stringFromDate:[NSDate date]];
    
    // Label for duration
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 220.0, 15.0)];
    durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    durationLabel.tag = 4;
    durationLabel.font = [UIFont systemFontOfSize:15.0];
    durationLabel.textColor = [UIColor darkGrayColor];
    durationLabel.text = @"►";
    
    [cell.contentView addSubview:durationLabel];
    
    // Right label
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
    
//    cell.textLabel.text = savedTopic.channel;
//    cell.detailTextLabel.text = @"April 5 2015";
    
    return cell;
}

// Add title to section
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"PREVIOUSLY SAVED:", @"");
}

#pragma mark - cell selection behaviour

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get cell channel
    SavedTopic *savedTopic = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *cellChannel = savedTopic.channel;
    
    // Find the topic of speach
    if([cellChannel isEqualToString:@"Today"]) {
        [self speakToday:savedTopic.data];
    } else if([cellChannel isEqualToString:@"Weather"]) {
        [self speakWeather:savedTopic.data];
    } else if([cellChannel isEqualToString:@"Calendar Events"]) {
        [self speakCalendarEvents:savedTopic.data];
    }
}

#pragma mark - Speaking utterances
- (void)speakToday:(NSString *)speechString {
    // Today
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:speechString];
    [self setUpVoiceAndSpeak:utterance];
}

- (void)speakWeather:(NSString *)speechString {
    // Weather
    NSArray *weatherSentences = [speechString componentsSeparatedByString:@".."];
    for(NSString *weatherSentence in weatherSentences) {
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:weatherSentence];
        [self setUpVoiceAndSpeak:utterance];
    }
}


- (void)speakCalendarEvents:(NSArray *)speechArray {
    // Calendar events
    for(NSString *eventSentence in speechArray) {
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
 ##pragma mark - mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
