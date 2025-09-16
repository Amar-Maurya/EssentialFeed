//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by 2674143 on 16/09/25.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    
    override func tearDown() {
        undoStoreSideEffects()
    }
    
    override func setUp() {
        setupEmptyStoreState()
    }
    
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait to load the cache data")
        sut.load { result in
            switch result {
            case let .success(feed):
                XCTAssertEqual(feed, [])
            case let .failure(error):
                XCTFail("Test deliver no item on Empty cache got the error :\(error)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
       
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        
        let feedItem = uniqueImageFeed().model
        
        let exp = expectation(description: "wait to save to data into cache")
        
        sutToPerformSave.save(feedItem) { insertError in
            XCTAssertNil(insertError)
            exp.fulfill()
            
        }
        
        wait(for: [exp], timeout: 1.0)
        
        let expLoad = expectation(description: "wait to load the cache data")
        sutToPerformLoad.load { result in
            switch result {
            case let .success(feed):
                XCTAssertEqual(feed, feedItem)
            case let .failure(error):
                XCTFail("Test deliver no item on Empty cache got the error :\(error)")
            }
            
            expLoad.fulfill()
        }
        
        wait(for: [expLoad], timeout: 1.0)
        
    }
    
    // MARKS :- Helper
    
    private func makeSUT() -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificURL()
        let coreDataFeed = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: coreDataFeed, currentDate: Date.init)
        trackForMemoryLeaks(coreDataFeed)
        trackForMemoryLeaks(sut)
        return sut
    }
    
    private func testSpecificURL() -> URL {
        cacheDirectory().appendingPathExtension("\(type(of: self)).store")
    }
    
    private func cacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
    deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
    deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificURL())
    }
}
