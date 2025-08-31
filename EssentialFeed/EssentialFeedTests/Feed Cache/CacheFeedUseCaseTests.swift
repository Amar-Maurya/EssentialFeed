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
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed(completion: { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        })
    }
    
    func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        self.store.insert(items, timestamp: timestamp) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

private class FeedStoreSpy: FeedStore {
    
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    private(set) var receivedMessage = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        insertions.append((items, timestamp))
        receivedMessage.append(.insert(items, timestamp))
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessage.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
}

 class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
     
     func test_save_requestCacheDeletion() {
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT()
         
         sut.save(items) { _ in }
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
     }
     
     func test_save_doesNotRequestCacheInsertionOnDeletionError() {
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT()
         let deletionError = anyNSError()
         
         sut.save(items) { _ in }
         store.completeDeletion(with: deletionError)
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
     }
     
     func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
         let timestamp = Date()
         let items = [uniqueItem(), uniqueItem()]
         let (sut, store) = makeSUT(currentDate: timestamp)
         
         sut.save(items) { _ in }
         store.completeDeletionSuccessfully()
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed, .insert(items, timestamp)])
     }
     
     func test_save_failsOnDeletionError() {
         let (sut, store) = makeSUT()
         let deletionError = anyNSError()
         
         execute(sut: sut,toCompleteWithError: deletionError, when: {
             store.completeDeletionSuccessfully()
             store.completeInsertion(with: deletionError)
         })
     }
     
     func test_save_failsOnInsertionError() {
         let (sut, store) = makeSUT()
         let insertionError = anyNSError()
         
         execute(sut: sut,toCompleteWithError: insertionError, when: {
             store.completeDeletionSuccessfully()
             store.completeInsertion(with: insertionError)
         })
     }
     
     func test_save_succeedsOnSuccessfulCacheInsertion() {
         let (sut, store) = makeSUT()
         
         execute(sut: sut,toCompleteWithError: nil, when: {
             store.completeDeletionSuccessfully()
             store.completeInsertionSuccessfully()
         })
     }
     
     func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
         let store: FeedStoreSpy = FeedStoreSpy()
         var sut: LoadFeedCache? = LoadFeedCache(store: store, timestamp: Date.init())
         var receivedError = [Error?]()
         
         sut?.save([uniqueItem()]){ receivedError.append($0) }
         
         sut = nil
         store.completeDeletion(with: anyNSError())
         
         XCTAssertTrue(receivedError.isEmpty)
     }
     
     func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
         let store: FeedStoreSpy = FeedStoreSpy()
         var sut: LoadFeedCache? = LoadFeedCache(store: store, timestamp: Date.init())
         var receivedError = [Error?]()
         
         sut?.save([uniqueItem()]){ receivedError.append($0) }
         store.completeDeletionSuccessfully()
         sut = nil
         
         store.completeInsertion(with: anyNSError())
         XCTAssertTrue(receivedError.isEmpty)
     }
     
     // helper
     func execute(sut: LoadFeedCache, file: StaticString = #filePath, line: UInt = #line, toCompleteWithError: NSError?, when onAction: () -> ()) {
         let exp = self.expectation(description: "wait for save completion")
         var receivedError: Error?
         sut.save([uniqueItem()]) { error in
             receivedError = error
             exp.fulfill()
         }
         onAction()
         wait(for: [exp], timeout: 1.0)
         XCTAssertEqual(receivedError as NSError?, toCompleteWithError)
     }
    
     private func makeSUT(currentDate: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> (LoadFeedCache, FeedStoreSpy) {
         let store = FeedStoreSpy()
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
