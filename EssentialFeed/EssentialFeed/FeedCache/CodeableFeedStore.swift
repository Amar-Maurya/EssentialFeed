//
//  CodeableFeedStore.swift
//  EssentialFeed
//
//  Created by 2674143 on 11/09/25.
//

import Foundation

public class CodableFeedStore: FeedStore {
    
    private let storeURL: URL
    public init(_ storeURL: URL) {
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
    
    var queue = DispatchQueue(label: "\(CodableFeedStore.self)",qos: .userInteractive, attributes: .concurrent)
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        let storeUrl = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeUrl) else {
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
    }
    
    
    public func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeUrl = self.storeURL
        queue.async(flags: .barrier) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(Cache(feed: items.map(CodableFeedImage.init), timestamp: timestamp))
                try data.write(to: storeUrl)
                return completion(nil)
            } catch {
                completion(error)
            }
        }
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeUrl = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeUrl.path) else {
                return completion(nil)
            }
            do {
                try FileManager.default.removeItem(at: storeUrl)
                return completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
