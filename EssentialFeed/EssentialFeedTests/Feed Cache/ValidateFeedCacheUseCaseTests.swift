//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 07/09/25.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store,file: file, line: line)
        trackForMemoryLeaks(sut,file: file, line: line)

        return (sut, store)
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        sut.validateCache()
        store.completeRetrival(with: error)
        XCTAssertEqual(store.receivedMessage, [.retrival, .deleteCachedFeed])
    }
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrivalWithEmptyCache()
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_validateCache_doesNotDeleteLessThanSevenDaysOldCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let lessThenSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feedImage.local, timeStamp: lessThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_validateCache_deletesSevenDaysOldCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let greaterThenSevenDaysOldTimestamp = currentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feedImage.local, timeStamp: greaterThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesMoreThanSevenDaysOldCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let greaterThenSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feedImage.local, timeStamp: greaterThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        sut?.validateCache()
        sut = nil
        store.completeRetrival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
        
    }

}

