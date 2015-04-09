//
//  BackendConnectivity.m
//  Kaspa
//
//  Created by Nabil Maadarani on 2015-04-09.
//  Copyright (c) 2015 Nabil Maadarani. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Backend.h"

@interface BackendConnectivity : XCTestCase

@end

@implementation BackendConnectivity

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

// Test if we are able to connect to the AWS backend
- (void)testConnectionToAwsBackend {
    NSString *awsBackendIndexPage = [NSString stringWithFormat:@"%@%@", BackendUrl, IndexFile];
    [self testConnectionTo:awsBackendIndexPage withHttpContentType:@"text/html"];
}

// Test if we are able to connect to the Today channel
- (void)testConnectionToToday {
    // Get today's date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"ddMMMMyyyy";
    NSString *todayDate = [formatter stringFromDate:[NSDate date]];
    
    // Create today URL
    NSString *todayUrl = [NSString stringWithFormat:@"%@%@", TodayChannelUrl, todayDate];
    
    [self testConnectionTo:todayUrl withHttpContentType:@"text/plain"];
}

// Test if we are able to connect to the Top News channel
- (void)testConnectionToTopNews {
    NSString *topNewsPage = [NSString stringWithFormat:@"%@%@", TopNewsChannelUrl, TopNewsFile];
    [self testConnectionTo:topNewsPage withHttpContentType:@"text/plain"];
}

// HTTP test function
- (void)testConnectionTo:(NSString *)url withHttpContentType:(NSString *)httpContentType {
    // Specify URL to test
    NSURL *URL = [NSURL URLWithString:url];
    NSString *description = [NSString stringWithFormat:@"GET %@", URL];

    // Specify weak expectation to avoid exception if request times out
    __weak XCTestExpectation *expectation = [self expectationWithDescription:description];
    
    // Create URL session and attempt to connect
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:URL
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                      XCTAssertNotNil(data, "data should not be nil"); // Must have data
                                      XCTAssertNil(error, "error should be nil"); // Must not have an error
                                      
                                      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                          // Code must be 200 (HTTP OK)
                                          XCTAssertEqual(httpResponse.statusCode, 200, @"HTTP response status code should be 200");
                                          // HTTP response must be equal to original URL
                                          XCTAssertEqualObjects(httpResponse.URL.absoluteString, URL.absoluteString, @"HTTP response URL should be equal to original URL");
                                          // HTTP must be text/html
                                          XCTAssertEqualObjects(httpResponse.MIMEType, httpContentType, @"HTTP response content type is wrong");
                                      } else {
                                          XCTFail(@"Response was not NSHTTPURLResponse");
                                      }
                                      
                                      [expectation fulfill];
                                  }];
    
    [task resume];

    // Allow 5 seconds timeout
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        [task cancel];
    }];
}

@end
