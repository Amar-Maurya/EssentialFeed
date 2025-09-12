//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by 2674143 on 12/09/25.
//

import XCTest
import EssentialFeed

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
    
     func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toExpected: expectedResult)
        expect(sut, toExpected: expectedResult)
    }
    
     func expect(_ sut: FeedStore, toExpected retrieval: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        let expect = expectation(description: "Retrieve cache")
        sut.retrieve { result in
            switch (result, retrieval) {
            case (.empty, .empty)
                ,(.failure, .failure):
                break
            case let (.found(retriveFeed, retriveDate), .found(expectedFeed, expectedDate)):
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
