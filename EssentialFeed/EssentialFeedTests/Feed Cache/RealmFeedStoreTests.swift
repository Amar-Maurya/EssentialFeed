//
//  RealmFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 20/09/25.
//

import XCTest
import EssentialFeed

final class RealmFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut: sut, to: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        
        let sut = makeSUT()

        expect(sut: sut, toRetrieveTwice: .empty)
        
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
    
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    // Helper
    
    private func makeSUT(_ file: StaticString = #file, line: UInt = #line) -> RealmFeedStore {
        let sut = RealmFeedStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(sut: RealmFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, to: expectedResult)
        expect(sut: sut, to: expectedResult)
    }
    
    private func expect(sut: RealmFeedStore, to expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "retrieve should complete")
        
        sut.retrieve { firstReceiveResult in
            switch (firstReceiveResult, expectedResult) {
            case (.empty, .empty):
                break
            default:
                XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(firstReceiveResult) and expected \(expectedResult) retrieval instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
    }
    
}
