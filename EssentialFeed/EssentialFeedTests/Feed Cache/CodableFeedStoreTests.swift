//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 10/09/25.
//

import XCTest
import EssentialFeed


class CodableFeedStore {
    
    private let storeURL: URL
    init(_ storeURL: URL) {
        self.storeURL = storeURL
    }

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
        undoStoreSideEffects()
    }
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut: sut, toExpected: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), sut: sut)
        
        expect(sut: sut, toExpected: .found(feed, timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), sut: sut)
        
        expect(sut, toRetrieveTwice: .found(feed, timestamp))
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), sut: CodableFeedStore) {
        let exp = expectation(description: "Retrieve twice empty cache")
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "expected feed to inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, toExpected: expectedResult)
        expect(sut: sut, toExpected: expectedResult)
    }
    
    private func expect(sut: CodableFeedStore, toExpected retrieval: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        let expect = expectation(description: "Retrieve cache")
        sut.retrieve { result in
            switch (result, retrieval) {
            case (.empty, .empty):
                break
            case let (.found(retriveFeed, retriveDate), .found(expectedFeed, expectedDate)):
                XCTAssertEqual(retriveFeed, expectedFeed)
                XCTAssertEqual(retriveDate, expectedDate)
            default:
                XCTFail("Expected retrieving from non empty cache to deliver same found result, got \(result) and expected \(retrieval) instead")
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of:self)).store")
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
