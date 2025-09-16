//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by 2674143 on 16/09/25.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    
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
}
