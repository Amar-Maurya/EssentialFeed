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
    
    private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: currentDate)
        trackForMemoryLeaks(store,file: file, line: line)
        trackForMemoryLeaks(sut,file: file, line: line)

        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
