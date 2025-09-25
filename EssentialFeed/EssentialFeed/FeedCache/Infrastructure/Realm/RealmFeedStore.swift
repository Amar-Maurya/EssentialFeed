//
//  RealmFeedStore.swift
//  EssentialFeed
//
//  Created by 2674143 on 20/09/25.
//

import Foundation
import RealmSwift


public final class RealmFeedStore: FeedStore {

    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    private let queue = DispatchQueue(label: "com.RealmFeedStore", qos: .userInteractive, attributes: .concurrent)

    public func retrieve(completion: @escaping RetrivalCompletion) {
        queue.async { [storeURL] in
            do {
                let realm = try Realm(configuration: Realm.Configuration(fileURL: storeURL, deleteRealmIfMigrationNeeded: true))
                
                if let cache = realm.objects(PersistedCache.self).first {
                    completion(.success(.some((cache.feedImages, cache.timestamp))))
                } else {
                    completion(.success(.none))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let realm = try Realm(configuration: Realm.Configuration(fileURL: storeURL, deleteRealmIfMigrationNeeded: true))
                try realm.write {
                    
                    let oldCaches = realm.objects(PersistedCache.self)
                    realm.delete(oldCaches)
                    
                    let realmCache = PersistedCache()
                    realmCache.feed.append(objectsIn: PersistedFeedImage.convert(localFeed: items))
                    realmCache.timestamp = timestamp
                    realm.add(realmCache)
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let realm = try Realm(configuration: Realm.Configuration(fileURL: storeURL, deleteRealmIfMigrationNeeded: true))
                
                let oldCaches = realm.objects(PersistedCache.self)
                if oldCaches.count > 0 {
                    try realm.write {
                        realm.delete(oldCaches)
                    }
                }
                
                completion(.success(()))
                
            } catch {
                completion(.failure(error))
            }
        }
    }

}
