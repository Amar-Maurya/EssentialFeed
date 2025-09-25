//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 31/08/25.
//

import XCTest
import EssentialFeed

 class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessage, [])
    }
     
     func test_save_requestCacheDeletion() {
         let items = uniqueImageFeed().model
         let (sut, store) = makeSUT()
         
         sut.save(items) { _ in }
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
     }
     
     func test_save_doesNotRequestCacheInsertionOnDeletionError() {
         let items = uniqueImageFeed().model
         let (sut, store) = makeSUT()
         let deletionError = anyNSError()
         
         sut.save(items) { _ in }
         store.completeDeletion(with: deletionError)
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed])
     }
     
     func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
         let timestamp = Date()
         let feed = uniqueImageFeed()
         let (sut, store) = makeSUT(currentDate: { timestamp })
         sut.save(feed.model) { _ in }
         store.completeDeletionSuccessfully()
         
         XCTAssertEqual(store.receivedMessage, [.deleteCachedFeed, .insert(feed.local, timestamp)])
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
         var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
         var receivedError = [LocalFeedLoader.SaveResult]()
         
         sut?.save([uniqueImage()]){ receivedError.append($0) }
         
         sut = nil
         store.completeDeletion(with: anyNSError())
         
         XCTAssertTrue(receivedError.isEmpty)
     }
     
     func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
         let store: FeedStoreSpy = FeedStoreSpy()
         var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
         var receivedError = [LocalFeedLoader.SaveResult]()
         
         sut?.save(uniqueImageFeed().model){ receivedError.append($0) }
         store.completeDeletionSuccessfully()
         sut = nil
         
         store.completeInsertion(with: anyNSError())
         XCTAssertTrue(receivedError.isEmpty)
     }
     
     // helper
     func execute(sut: LocalFeedLoader, file: StaticString = #filePath, line: UInt = #line, toCompleteWithError: NSError?, when onAction: () -> ()) {
         let exp = self.expectation(description: "wait for save completion")
         var receivedError: Error?
         sut.save([uniqueImage()]) { result in
             if case let Result.failure(error) = result { receivedError = error }
             exp.fulfill()
         }
         onAction()
         wait(for: [exp], timeout: 1.0)
         XCTAssertEqual(receivedError as NSError?, toCompleteWithError)
     }
    
     private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
         let store = FeedStoreSpy()
         let sut = LocalFeedLoader(store: store, currentDate: currentDate)
         trackForMemoryLeaks(store,file: file, line: line)
         trackForMemoryLeaks(sut,file: file, line: line)
    
         return (sut, store)
     }
  
}
