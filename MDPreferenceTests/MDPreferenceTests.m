//
//  MDPreferenceTests.m
//  MDPreferenceTests
//
//  Created by xulinfeng on 2018/3/21.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MDPreference.h"

@protocol MDTestPreference <NSObject>

@property (nonatomic, copy) NSString *testProperty;

@end

@interface MDPreferenceTests : XCTestCase

@property (nonatomic, strong, readonly) MDPreference<MDTestPreference> *testPreference;

@end

@implementation MDPreferenceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _testPreference = [[MDPreference<MDTestPreference> alloc] initWithProtocol:@protocol(MDTestPreference)];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInvockProperty {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference.testProperty = @"property_invoke";
    XCTAssertEqual(_testPreference.testProperty, @"property_invoke");
}

- (void)testInvockPropertySynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference.testProperty = @"property_invoke";
    
    XCTAssertEqual(_testPreference.testProperty, @"property_invoke");
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_invoke");
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_invoke");
}

- (void)testInvockKeyValueCoding {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [_testPreference setValue:@"property_kvc" forKey:@"testProperty"];
    
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_kvc");
}

- (void)testInvockKeyValueCodingSynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [_testPreference setValue:@"property_kvc" forKey:@"testProperty"];
    
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_kvc");
    XCTAssertEqual(_testPreference.testProperty, @"property_kvc");
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_kvc");
}

- (void)testInvockUndefineKeyValueCoding {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference[@"testProperty"] = @"property_undefine_kvc";
    
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_undefine_kvc");
}

- (void)testInvockUndefineKeyValueCodingSynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference[@"testProperty"] = @"property_undefine_kvc";
    
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_undefine_kvc");
    
    XCTAssertEqual(_testPreference.testProperty, @"property_undefine_kvc");
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_undefine_kvc");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
