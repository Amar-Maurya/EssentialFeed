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
        
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
    
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
    
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_storeSideEffects_runSerially() {
        var operationExp: [XCTestExpectation] = []
        
        let sut = makeSUT()
        
        let op1 = expectation(description: "Insertion wait")
        
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            op1.fulfill()
            operationExp.append(op1)
        }
  
        let op2 = expectation(description: "deletion wait")
        
        sut.deleteCachedFeed { deletionError in
            op2.fulfill()
            operationExp.append(op2)
        }
        
        let op3 = expectation(description: "retrieve wait")
        
        sut.retrieve { retrieveResult in
            op3.fulfill()
            operationExp.append(op3)
        }
        
        wait(for: [op1, op2, op3], timeout: 5.0)
        
        XCTAssertEqual(operationExp,  [op1, op2, op3])
    }
    
    // Helper
    
    private func makeSUT(_ file: StaticString = #file, line: UInt = #line) -> FeedStore {
         let sut = RealmFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, to: expectedResult)
        expect(sut: sut, to: expectedResult)
    }
    
    @discardableResult
    private func delete(sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = expectation(description: "Deletion Wait")
        
        var expError: Error? = nil
        
        sut.deleteCachedFeed { deletionError in
            XCTAssertNil(deletionError)
            expError = deletionError
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return expError
    }
     
    @discardableResult
    private func insert(sut: FeedStore, cache: (feed: [LocalFeedImage], timeStamp: Date), file: StaticString = #file, line: UInt = #line) -> Error? {
        
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
    
    private func expect(sut: FeedStore, to expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        
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
