//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 10/09/25.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        return completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let expect = expectation(description: "Retrieve empty cache")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Should not fail \(result)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

}
