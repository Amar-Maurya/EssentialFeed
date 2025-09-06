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
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed(completion: { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        })
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        self.store.insert(feed.toLocal(), timestamp: timestamp) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        self.store.retrieve { result in
            switch result {
            case .empty:
                completion(.success([]))
            case let .found(localFeedImage, _):
                completion(.success(localFeedImage.toModel()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
    
}

private extension Array where Element == LocalFeedImage {
    
    func toModel() -> [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
    
}
