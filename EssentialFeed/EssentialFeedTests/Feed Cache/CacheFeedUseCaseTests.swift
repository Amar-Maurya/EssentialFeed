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
    var timestamp: Date
    init(store: FeedStore, timestamp: Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed(completion: { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: timestamp)
            }
        })
    }
}

class FeedStore {
    typealias DeletionCompletion =  (Error?) -> Void
    var deleteCachedForCallCount: Int = 0
    var deletionCompletions = [DeletionCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertions.append((items, timestamp))
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion){
        deleteCachedForCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
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
     
     func test_save_doesNotRequestCacheInsertionOnDeletionError() {
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT()
         let deletionError = anyNSError()
         
         sut.save(items)
         store.completeDeletion(with: deletionError)
         
         XCTAssertEqual(store.insertions.count, 0)
     }
     
     func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
         let timestamp = Date()
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT(currentDate: timestamp)
         
         sut.save(items)
         store.completeDeletionSuccessfully()
         
         XCTAssertEqual(store.insertions.count, 1)
         XCTAssertEqual(store.insertions.first?.items, items)
         XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
     }
     
     // helper
     
     private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (LoadFeedCache, FeedStore) {
         let store = FeedStore()
         let sut = LoadFeedCache(store: store, timestamp: currentDate)
         trackForMemoryLeaks(store,file: file, line: line)
         trackForMemoryLeaks(sut,file: file, line: line)
    
         return (sut, store)
     }
     
     private func uniqueItem() -> FeedItem {
         return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
     }
     
     private func anyURL() -> URL {
         return URL(string: "http://any-url.com")!
     }
     
     private func anyNSError() -> NSError {
         return NSError(domain: "any error", code: 0)
     }

}
