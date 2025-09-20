//
//  RealmFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 20/09/25.
//

import XCTest
import EssentialFeed

private class RealmFeedStore {
    
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        completion(.empty)
    }
}

final class RealmFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "retrieve should complete")
        
        sut.retrieve { receiveResult in
            switch receiveResult {
            case .empty :
                break
            default:
                XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(receiveResult) and expected retrieval instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        
        let sut = makeSUT()
        
        let exp = expectation(description: "retrieve should complete")
        
        sut.retrieve { firstReceiveResult in
            sut.retrieve { secondReceiveResult in
                
                switch (firstReceiveResult, secondReceiveResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(firstReceiveResult) and expected \(secondReceiveResult) retrieval instead")
                }
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
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
    
    private func makeSUT() -> RealmFeedStore {
        let sut = RealmFeedStore()
        trackForMemoryLeaks(sut)
        return sut
    }    
    
}
