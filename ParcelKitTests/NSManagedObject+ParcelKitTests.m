//
//  NSManagedObjectParcelKitTests.m
//  ParcelKit
//
//  Copyright (c) 2013 Overcommitted, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "PKSyncManager.h"
#import "NSManagedObject+ParcelKit.h"
#import "NSManagedObjectContext+ParcelKitTests.h"
#import "PKRecordMock.h"
#import "PKListMock.h"

@interface NSManagedObjectParcelKitTests : XCTestCase
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObject *book;
@property (strong, nonatomic) NSManagedObject *author;
@property (strong, nonatomic) NSManagedObject *publisher;
@end

@implementation NSManagedObjectParcelKitTests

- (void)setUp
{
    [super setUp];
    
    self.managedObjectContext = [NSManagedObjectContext pk_managedObjectContextWithModelName:@"Tests"];
    
    self.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:self.managedObjectContext];
    [self.book setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.book setValue:@"To Kill a Mockingbird" forKey:@"title"];
    
    self.author = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    [self.author setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.author setValue:@"Harper Lee" forKey:@"name"];
    
    self.publisher = [NSEntityDescription insertNewObjectForEntityForName:@"Publisher" inManagedObjectContext:self.managedObjectContext];
    [self.publisher setValue:@"1" forKey:PKDefaultSyncAttributeName];
    [self.publisher setValue:@"J. B. Lippincott & Co." forKey:@"name"];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testSetPropertiesWithRecordShouldIgnoreSyncAttribute
{
    PKRecordMock *record = [PKRecordMock record:@"123" withFields:@{PKDefaultSyncAttributeName: @"123"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"1", [self.book valueForKey:PKDefaultSyncAttributeName], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreTransientAttributes
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverPath": @"/tmp/cover.png"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"coverPath"], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreUnknownAttributes
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisherAddress": @"10 East 53rd Street, New York, NY 10022"}];
    XCTAssertNoThrow([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfRequiredAttributeHasNoValue
{
    [self.book setValue:nil forKey:@"title"];

    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetStringAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [self.book valueForKey:@"title"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertStringAttributeTypeIfNotString
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @(42)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"42", [self.book valueForKey:@"title"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertStringAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger16AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": @(1960)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1960), [self.book valueForKey:@"yearPublished"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger16AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": @"1960"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1960), [self.book valueForKey:@"yearPublished"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger16AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"yearPublished": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger32AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": @(296)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger32AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": @"296"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger32AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"pageCount": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetInteger64AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": @(1234567890)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1234567890), [self.book valueForKey:@"ratingsCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertInteger64AttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": @"1234567890"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1234567890), [self.book valueForKey:@"ratingsCount"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertInteger64AttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"ratingsCount": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDoubleAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": @(4.2)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(4.2), [self.book valueForKey:@"averageRating"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertDoubleAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": @"4.2"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(4.2), [self.book valueForKey:@"averageRating"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDoubleAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"averageRating": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDecimalAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": @(19.60)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(19.60), [self.book valueForKey:@"price"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertDecimalAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": @"19.60"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(19.60), [self.book valueForKey:@"price"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDecimalAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"price": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetFloatAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": @(768.0f)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(768.0f), [self.book valueForKey:@"coverHeight"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertFloatAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": @"768.0"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(768.0f), [self.book valueForKey:@"coverHeight"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertFloatAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"coverHeight": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetBooleanAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": @(1)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1), [self.book valueForKey:@"isFavorite"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertBooleanAttributeTypeIfNotNumber
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": @"1"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@(1), [self.book valueForKey:@"isFavorite"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertBooleanAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"isFavorite": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetDateAttributeType
{
    NSDate *publishedDate = [NSDate date];
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publishedDate": publishedDate}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(publishedDate, [self.book valueForKey:@"publishedDate"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfCannotConvertDateAttributeType
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publishedDate": @"1960-07-11"}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}


- (void)testSetPropertiesWithRecordShouldSetToManyRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEquals(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreMissingObjectsInToManyRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1", @"2"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEquals(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldRemoveObjectsInToManyRelationship
{
    NSManagedObject *authorToBeRemoved = [NSEntityDescription insertNewObjectForEntityForName:@"Author" inManagedObjectContext:self.managedObjectContext];
    [authorToBeRemoved setValue:@"2" forKey:PKDefaultSyncAttributeName];
    
    [self.book setValue:[NSSet setWithObjects:self.author, authorToBeRemoved, nil] forKey:@"authors"];
    XCTAssertEquals(2, (int)[[self.book valueForKey:@"authors"] count], @"");
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": [[PKListMock alloc] initWithValues:@[@"1"]]}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    
    NSSet *authors = [self.book valueForKey:@"authors"];
    XCTAssertNotNil(authors, @"");
    XCTAssertEquals(1, (int)[authors count], @"");
    
    NSManagedObject *author = [authors anyObject];
    XCTAssertEqualObjects(author, self.author, @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfToManyRelationshipIsNotAList
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"authors": @"1,2"}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetToOneRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @"1"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(self.publisher, [self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldIgnoreMissingObjectInToOneRelationship
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @"2"}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldRemoveToOneRelationship
{
    [self.book setValue:self.publisher forKey:@"publisher"];
    
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertNil([self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldConvertToOneRelationshipValueIfNotString
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": @(1)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(self.publisher, [self.book valueForKey:@"publisher"], @"");
}

- (void)testSetPropertiesWithRecordShouldRaiseExceptionIfToManyCannotConvertToOneRelationshipValue
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"publisher": [NSDate date]}];
    XCTAssertThrowsSpecificNamed([self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName], NSException, PKInvalidAttributeValueException, @"");
}

- (void)testSetPropertiesWithRecordShouldSetMultipleProperties
{
    PKRecordMock *record = [PKRecordMock record:@"1" withFields:@{@"title": @"To Kill a Mockingbird Part 2: Birdy's Revenge", @"pageCount": @(296)}];
    [self.book pk_setPropertiesWithRecord:record syncAttributeName:PKDefaultSyncAttributeName];
    XCTAssertEqualObjects(@"To Kill a Mockingbird Part 2: Birdy's Revenge", [self.book valueForKey:@"title"], @"");
    XCTAssertEqualObjects(@(296), [self.book valueForKey:@"pageCount"], @"");
}
@end
