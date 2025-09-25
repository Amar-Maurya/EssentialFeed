//
//  EssentialFeedCacheRealmIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by 2674143 on 24/09/25.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheRealmIntegrationTests: XCTestCase {
    
    override func tearDown() {
        undoStoreSideEffects()
    }
    
    override func setUp() {
        setupEmptyStoreState()
    }
    
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, expectedResult: [])
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        
        let feedItem = uniqueImageFeed().model
        
        save(feedItem, with: sutToPerformSave)
        
        expect(sutToPerformLoad, expectedResult: feedItem)
        
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformLatestSave = makeSUT()
        let sutToPerformLoad = makeSUT()
    
        let firstFeed = uniqueImageFeed().model
        let latestFeed = uniqueImageFeed().model
        
        save(firstFeed, with: sutToPerformFirstSave)
        save(latestFeed, with: sutToPerformLatestSave)
       
        expect(sutToPerformLoad, expectedResult: latestFeed)
    }
    
    // MARKS :- Helper
    
    private func makeSUT() -> LocalFeedLoader {
        let storeURL = testSpecificStoreURL()
        let realmFeedStore = RealmFeedStore(storeURL: storeURL)
        let sut = LocalFeedLoader(store: realmFeedStore, currentDate: Date.init)
        trackForMemoryLeaks(realmFeedStore)
        trackForMemoryLeaks(sut)
        return sut
    }
    
    private func expect(_ sut: LocalFeedLoader, expectedResult: [FeedImage], file: StaticString = #file, line: UInt = #line) {
       
        let exp = expectation(description: "wait to load the cache data")
        sut.load { result in
            switch result {
            case let .success(feed):
                XCTAssertEqual(feed, expectedResult)
            case let .failure(error):
                XCTFail("Test deliver no item on Empty cache got the error :\(error)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
    }
    
    private func save(_ feed: [FeedImage], with loader: LocalFeedLoader, file: StaticString = #file, line: UInt = #line) {
        let saveExp = expectation(description: "Wait for save completion")
        
        loader.save(feed) { _ in
            saveExp.fulfill()
        }
        
        wait(for: [saveExp], timeout: 1.0)
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
