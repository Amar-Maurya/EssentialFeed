//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 10/09/25.
//

import XCTest
import EssentialFeed


class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map(\.local)
        }
    }
    
    private struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        let decoder = JSONDecoder()
        guard let data = try?  Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        guard let feedImage = try? decoder.decode(Cache.self, from: data) else {
            return completion(.empty)
        }
        completion(.found(feedImage.localFeed, feedImage.timestamp))
    }
    
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(Cache(feed: items.map(CodableFeedImage.init), timestamp: timestamp))
        try? data.write(to: storeURL)
        return completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let expect = expectation(description: "Retrieve empty cache")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Should not fail \(result)")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let expect = expectation(description: "Retrieve empty cache")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Should not fail \(firstResult) \(secondResult)")
                }
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let expect = expectation(description: "Retrieve empty cache")
        let uniqueImageFeed = uniqueImageFeed().local
        let insertedDate = Date()
        sut.insert(uniqueImageFeed, timestamp: insertedDate) { insertionError in
            XCTAssertNil(insertionError, "expected feed to inserted successfully")
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .found(items, date):
                    XCTAssertEqual(items, uniqueImageFeed)
                    XCTAssertEqual(date, insertedDate)
                default:
                    XCTFail("Should not fail \(retrieveResult)")
                }
                
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
}
