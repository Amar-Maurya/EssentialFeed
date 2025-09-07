//
//  LoadFeedCache.swift
//  EssentialFeed
//
//  Created by 2674143 on 31/08/25.
//
import Foundation

public final class LocalFeedLoader {
    var store: FeedStore
    private let currentDate: () -> Date
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    private let calendar = Calendar(identifier: .gregorian)
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
 
    
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
        self.store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        self.store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .found(localFeedImage, timestamp) where self.validate(timeStamp: timestamp) :
                completion(.success(localFeedImage.toModel()))
            case .empty:
                completion(.success([]))
            case.found :
                store.deleteCachedFeed{ _ in }
                completion(.success([]))
            case let .failure(error):
                store.deleteCachedFeed{ _ in }
                completion(.failure(error))
            }
        }
    }
    
    private func validate(timeStamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timeStamp) else {
            return false
        }
        return currentDate() < maxCacheAge
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
