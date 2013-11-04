//
//  JSONDocumentTests.m
//  VideoMonkey Tests
//
//  Created by Philippe on 2013-11-03.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "JSONDocument.h"

@interface JSONDocumentTests : SenTestCase

@end

@implementation JSONDocumentTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParsing
{
    NSData *testData = [@"{ \"shop\" : \"s-mart\", \"boom-stick\" : 1 }" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expected = @{ @"shop" : @"s-mart", @"boom-stick" : @1 };

    NSDictionary *result;
    NSError *error;

    STAssertNoThrow(result = [JSONDocument JSONObjectWithData:testData options:JSONReadingMutableContainers error:&error], @"");
    STAssertEqualObjects(result, expected, @"");
    STAssertNil(error, @"");
}

@end
