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

- (void)testInvokeProperty {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference.testProperty = @"property_invoke";
    XCTAssertEqual(_testPreference.testProperty, @"property_invoke");
}

- (void)testPropertyWithNilValue {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference.testProperty = @"property_invoke";
    XCTAssertNotNil(_testPreference.testProperty);
    
    _testPreference.testProperty = nil;
    XCTAssertNil(_testPreference.testProperty);
}

- (void)testInvokePropertySynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference.testProperty = @"property_invoke";
    
    XCTAssertEqual(_testPreference.testProperty, @"property_invoke");
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_invoke");
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_invoke");
}

- (void)testInvokeKeyValueCoding {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [_testPreference setValue:@"property_kvc" forKey:@"testProperty"];
    
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_kvc");
}

- (void)testInvokeKeyValueCodingSynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [_testPreference setValue:@"property_kvc" forKey:@"testProperty"];
    
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_kvc");
    XCTAssertEqual(_testPreference.testProperty, @"property_kvc");
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_kvc");
}

- (void)testInvokeUndefineKeyValueCoding {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference[@"testProperty"] = @"property_undefine_kvc";
    
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_undefine_kvc");
}

- (void)testInvokeUndefineKeyValueCodingSynchronization {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    _testPreference[@"testProperty"] = @"property_undefine_kvc";
    
    XCTAssertEqual(_testPreference[@"testProperty"], @"property_undefine_kvc");
    
    XCTAssertEqual(_testPreference.testProperty, @"property_undefine_kvc");
    XCTAssertEqual([_testPreference valueForKey:@"testProperty"], @"property_undefine_kvc");
}

@end
