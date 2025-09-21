//
//  RealmFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 20/09/25.
//

import XCTest
import EssentialFeed

final class RealmFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut: sut, to: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut: sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        let uniqueFeedImage = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(sut: sut, cache: (uniqueFeedImage, timestamp))
        
        expect(sut: sut, to: .found(uniqueFeedImage, timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        let uniqueFeedImage = uniqueImageFeed().local
        let timestamp = Date()
      
        insert(sut: sut, cache: (uniqueFeedImage, timestamp))
        
        expect(sut: sut, toRetrieveTwice: .found(uniqueFeedImage, timestamp))
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let uniqueFeedImage = uniqueImageFeed().local
        let timestamp = Date()
      
        insert(sut: sut, cache: (uniqueFeedImage, timestamp))
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        insert(sut: sut, cache: (uniqueImageFeed().local, Date()))
        
        let uniqueFeedImage = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(sut: sut, cache: (uniqueFeedImage, timestamp))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        insert(sut: sut, cache: (uniqueImageFeed().local, Date()))
        
        let latestFeedImages = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(sut: sut, cache: (latestFeedImages, timestamp))
        
        expect(sut: sut, to: .found(latestFeedImages, timestamp))
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Deletion Wait")
        
        sut.deleteCachedFeed { deletionError in
            XCTAssertNil(deletionError)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Deletion Wait")
        
        sut.deleteCachedFeed { deletionError in
            XCTAssertNil(deletionError)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        expect(sut: sut, toRetrieveTwice: .empty)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        
        let sut = makeSUT()
        
        insert(sut: sut, cache: (uniqueImageFeed().local, Date()))
        
        let exp = expectation(description: "Deletion Wait")
        
        sut.deleteCachedFeed { deletionError in
            XCTAssertNil(deletionError)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    // Helper
    
    private func makeSUT(_ file: StaticString = #file, line: UInt = #line) -> RealmFeedStore {
         let sut = RealmFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(sut: RealmFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, to: expectedResult)
        expect(sut: sut, to: expectedResult)
    }
    
    @discardableResult
    private func insert(sut: RealmFeedStore, cache: (feed: [LocalFeedImage], timeStamp: Date), file: StaticString = #file, line: UInt = #line) -> Error? {
        
       let exp  = expectation(description: "Insert wating")
        
        var insertionError: Error?
        
        sut.insert(cache.feed, timestamp: cache.timeStamp) { insertionExpError in
            XCTAssertNil(insertionExpError)
            insertionError = insertionExpError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
       return insertionError
    }
    
    private func expect(sut: RealmFeedStore, to expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "retrieve should complete")
        
        sut.retrieve { firstReceiveResult in
            switch (firstReceiveResult, expectedResult) {
            case (.empty, .empty):
                break
                
            case let (.found(receiveFeedImages, receiveTimestamp), .found(expectedFeedImages, expectedTimeStamp)) :
                XCTAssertEqual(receiveFeedImages, expectedFeedImages, file: file, line: line)
                XCTAssertEqual(receiveTimestamp, expectedTimeStamp, file: file, line: line)
                
            default:
                XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(firstReceiveResult) and expected \(expectedResult) retrieval instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
    }
    
    private func testSpecificStoreURL() -> URL {
        let filename = "\(type(of:self)).store"
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        return tempDir.appendingPathComponent(filename)
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
}
