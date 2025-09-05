//
//  LoadFeedCache.swift
//  EssentialFeed
//
//  Created by 2674143 on 31/08/25.
//
import Foundation

public final class LocalFeedLoader {
    var store: FeedStore
    var timestamp: Date
    public init(store: FeedStore, timestamp: Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed(completion: { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        })
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        self.store.insert(items, timestamp: timestamp) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        self.store.retrieve { error in
            if let error = error  {
                completion(.failure(error))
            } else {
                completion(.success([]))
            }
        }
       
    }
}
