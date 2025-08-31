//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 31/08/25.
//

import XCTest
import EssentialFeed

class LoadFeedCache {
    var store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCachedForCallCount: Int = 0
    
    func deleteCachedFeed() {
        deleteCachedForCallCount += 1
    }
}

 class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedForCallCount, 0)
    }
     
     func test_save_requestCacheDeletion() {
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT()
         
         sut.save(items)
         
         XCTAssertEqual(store.deleteCachedForCallCount, 1)
     }
     
     // helper
     
     private func makeSUT() -> (LoadFeedCache, FeedStore) {
         let store = FeedStore()
         let sut = LoadFeedCache(store: store)
         return (sut, store)
     }
     
     private func uniqueItem() -> FeedItem {
         return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
     }
     
     private func anyURL() -> URL {
         return URL(string: "http://any-url.com")!
     }

}
