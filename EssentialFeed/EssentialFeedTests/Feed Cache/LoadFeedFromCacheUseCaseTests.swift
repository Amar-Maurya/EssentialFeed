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
        sut.load()
        XCTAssertEqual(store.receivedMessage, [.retrival])
    }
    
    private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: currentDate)
        trackForMemoryLeaks(store,file: file, line: line)
        trackForMemoryLeaks(sut,file: file, line: line)

        return (sut, store)
    }
}
