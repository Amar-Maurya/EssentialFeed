//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by 2674143 on 12/09/25.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toExpected: .success(.none), file: file, line: line)
    }
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .success(.none), file: file, line: line)
    }
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), sut: sut)
        expect(sut, toExpected: .success(.some((feed, timestamp))), file: file, line: line)
    }
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), sut: sut)
        expect(sut, toRetrieveTwice: .success(.some((feed, timestamp))), file: file, line: line)
    }
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert((uniqueImageFeed().local, Date()), sut: sut)
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), sut: sut)
        let insertionError = insert((uniqueImageFeed().local, Date()), sut: sut)
        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), sut: sut)
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), sut: sut)
        expect(sut, toExpected: .success(.some((latestFeed, latestTimestamp))), file: file, line: line)
    }
 
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCache(sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        deleteCache(sut)
        expect(sut, toExpected: .success(.none), file: file, line: line)
    }
 
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), sut: sut)
        let deletionError = deleteCache(sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), sut: sut)
        deleteCache(sut)
        expect(sut, toExpected: .success(.none), file: file, line: line)
    }
    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        var completedOperationsInOrder = [XCTestExpectation]()
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
    }
 
}

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
     func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), sut: FeedStore) -> Error? {
        let exp = expectation(description: "insertion on empty cache")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: FeedStore.RetrieveResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toExpected: expectedResult)
        expect(sut, toExpected: expectedResult)
    }
    
    func expect(_ sut: FeedStore, toExpected retrieval: FeedStore.RetrieveResult, file: StaticString = #file, line: UInt = #line) {
        let expect = expectation(description: "Retrieve cache")
        sut.retrieve { result in
            switch (result, retrieval) {
            case (.success(.none), .success(.none))
                ,(.failure, .failure):
                break
            case let (.success(.some((retriveFeed, retriveDate))), .success(.some((expectedFeed, expectedDate)))):
                XCTAssertEqual(retriveFeed, expectedFeed)
                XCTAssertEqual(retriveDate, expectedDate)
            default:
                XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(result) and expected \(retrieval) instead")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    @discardableResult
     func deleteCache(_ sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let expect = expectation(description: "Delete cache")
        
        var expectedError: Error?
        sut.deleteCachedFeed { receiveResult in
            expectedError = receiveResult
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 1.0)
        return expectedError
    }
}
