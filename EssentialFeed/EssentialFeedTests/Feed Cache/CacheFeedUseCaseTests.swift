//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 31/08/25.
//

import XCTest

class LoadFeedCache {
    var store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

class FeedStore {
    var deleteCachedForCallCount: Int = 0
}

 class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LoadFeedCache(store: store)
        XCTAssertEqual(store.deleteCachedForCallCount, 0)
    }

}
