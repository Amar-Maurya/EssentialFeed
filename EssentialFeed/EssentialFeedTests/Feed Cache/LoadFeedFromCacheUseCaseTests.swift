//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 04/09/25.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
    
    func test_load_requestsCacheRetrival() {
        let (sut, store) = makeSUT()
        sut.load{ _ in }
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_requestsCacheErrorRetrival() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        
        expect(sut: sut, toLoadWith: .failure(expectedError)) {
            store.completeRetrival(with: expectedError)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut: sut, toLoadWith: .success([])) {
            store.completeRetrivalWithEmptyCache()
        }
    }

    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let (sut, store) = makeSUT()
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let nonExpiredTimestamp = currentDate.minusFeedCaheMaxAge().adding(seconds: 1)
        expect(sut: sut, toLoadWith: .success(feedImage.model)) {
            store.completeRetrival(with: feedImage.local, timeStamp: nonExpiredTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnCacheExpiration() {
        let (sut, store) = makeSUT()
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCaheMaxAge()
        expect(sut: sut, toLoadWith: .success([])) {
            store.completeRetrival(with: feedImage.local, timeStamp: expirationTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCaheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut: sut, toLoadWith: .success([])) {
            store.completeRetrival(with: feed.local, timeStamp: expiredTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        sut.load{ _ in }
        store.completeRetrival(with: error)
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func  test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load{ _ in }
        store.completeRetrivalWithEmptyCache()
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let nonExpiredTimestamp = currentDate.minusFeedCaheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCaheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache(){
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCaheMaxAge().adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var recievedError: [LocalFeedLoader.LoadResult] = []
        
        sut?.load{ recievedError.append($0) }
        sut = nil
        
        store.completeRetrivalWithEmptyCache()
        
        XCTAssertTrue(recievedError.isEmpty)
        
    }
    
    func expect(sut: LocalFeedLoader, toLoadWith expectedResult: LocalFeedLoader.LoadResult, file: StaticString = #filePath, line: UInt = #line, action: () -> Void) {
        let exp = expectation(description: "Retrieve Cache Data")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImage), .success(expectedImage)):
                XCTAssertEqual(receivedImage, expectedImage, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)) :
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("get receivedResult \(receivedResult) expectedResult \(expectedResult) instead of error", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store,file: file, line: line)
        trackForMemoryLeaks(sut,file: file, line: line)

        return (sut, store)
    }
}
