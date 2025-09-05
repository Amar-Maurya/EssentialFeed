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
        var retriveError: Error?
        
        let exp = expectation(description: "Retrieve Cache Error")
        sut.load { result in
            switch result {
            case let .failure(error):
                retriveError = error
            default:
                XCTFail("get result \(result) instead of error")
            }
            exp.fulfill()
        }
        
        store.completeRetrival(with: expectedError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(expectedError, retriveError as? NSError)
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
