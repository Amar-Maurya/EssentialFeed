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

    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let expectedDate = currentDate.adding(days: -7).adding(seconds: 1)
        expect(sut: sut, toLoadWith: .success(feedImage.model)) {
            store.completeRetrival(with: feedImage.local, timeStamp: expectedDate)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let (sut, store) = makeSUT()
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let expectedDate = currentDate.adding(days: -7)
        expect(sut: sut, toLoadWith: .success([])) {
            store.completeRetrival(with: feedImage.local, timeStamp: expectedDate)
        }
    }
    
    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut: sut, toLoadWith: .success([])) {
            store.completeRetrival(with: feed.local, timeStamp: moreThanSevenDaysOldTimestamp)
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
    
    func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let lessThenSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: lessThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    func test_load_deletesCacheOnSevenDaysOldCache() {
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let greaterThenSevenDaysOldTimestamp = currentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: greaterThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival, .deleteCachedFeed])
    }
    
    func test_load_deletesCacheOnMoreThanSevenDaysOldCache(){
        let feedImage = uniqueImageFeed()
        let currentDate = Date()
        let greaterThenSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feedImage.local, timeStamp: greaterThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessage, [.retrival, .deleteCachedFeed])
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
        let items = [uniqueImage(), uniqueImage()]
        let locals: [LocalFeedImage] = items.map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        return (model: items, local: locals)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
