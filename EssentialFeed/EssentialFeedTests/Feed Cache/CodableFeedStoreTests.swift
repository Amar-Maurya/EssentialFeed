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
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let decoder = JSONDecoder()
        do {
            let feedImage = try decoder.decode(Cache.self, from: data)
            completion(.found(feedImage.localFeed, feedImage.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Cache(feed: items.map(CodableFeedImage.init), timestamp: timestamp))
            try data.write(to: storeURL)
            return completion(nil)
        } catch {
            completion(error)
        }
       
    }
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletion) {
        
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }

        try! FileManager.default.removeItem(at: storeURL)
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
        expect(sut, toExpected: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), sut: sut)
        
        expect(sut, toExpected: .found(feed, timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), sut: sut)
        
        expect(sut, toRetrieveTwice: .found(feed, timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid json".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toExpected: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid json".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        let insertError = insert((feed:  uniqueImageFeed().local, timestamp: Date()), sut: sut)
        XCTAssertNil(insertError, "expected feed to inserted successfully")
        
        let latestFeed = uniqueImageFeed().local
        let timestamp = Date()
        let latestInsertError = insert((feed: latestFeed, timestamp: timestamp), sut: sut)
        XCTAssertNil(latestInsertError, "expected feed to inserted successfully")
        
        expect(sut, toExpected: .found(latestFeed, timestamp))
    }
    
    func test_insert_invalidInsertedCacheValues() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        let latestFeed = uniqueImageFeed().local
        let timestamp = Date()
        let insertError = insert((feed: latestFeed, timestamp: timestamp), sut: sut)
        
        XCTAssertNotNil(insertError, "expected feed to inserted fail")
        expect(sut, toExpected: .empty)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Deletion on empty cache")
        var expError: Error?
        sut.deleteCachedFeed { receiveResult in
            expError = receiveResult
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertNil(expError)
        
        expect(sut, toExpected: .empty)
      
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let latestFeed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertError = insert((feed: latestFeed, timestamp: timestamp), sut: sut)
        XCTAssertNil(insertError, "expected feed to inserted successfully")

        let exp = expectation(description: "Deletion on previously insertion cache")
        sut.deleteCachedFeed {receiveResult in
            XCTAssertNil(receiveResult)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        expect(sut, toExpected: .empty)
    }
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "insertion on empty cache")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toExpected: expectedResult)
        expect(sut, toExpected: expectedResult)
    }
    
    private func expect(_ sut: CodableFeedStore, toExpected retrieval: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
        let expect = expectation(description: "Retrieve cache")
        sut.retrieve { result in
            switch (result, retrieval) {
            case (.empty, .empty)
                ,(.failure, .failure):
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
