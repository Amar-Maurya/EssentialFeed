//
//  RealmFeedStore.swift
//  EssentialFeed
//
//  Created by 2674143 on 20/09/25.
//

import Foundation
import RealmSwift


public final class RealmFeedStore {

    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    @objc(Cache)
    class Cache: Object {
        @Persisted var timestamp: Date
        @Persisted var feed: List<RealmFeedImage>
        
        public  var feedImages: [LocalFeedImage] {
            feed.map { $0.localFeedImage }
        }
    }
    
    @objc(RealmFeedImage)
     class RealmFeedImage: Object {
        @Persisted var id: UUID
        @Persisted var imageDescription: String?
        @Persisted var location: String?
        @Persisted var urlString: String
        
        var url: URL { URL(string: urlString)! }
        
        static func convert(localFeed: [LocalFeedImage]) -> [RealmFeedImage] {
            localFeed.map { feed in
                let realmFeed = RealmFeedImage()
                realmFeed.id = feed.id
                realmFeed.imageDescription = feed.description
                realmFeed.location = feed.location
                realmFeed.urlString = feed.url.absoluteString
                return realmFeed
            }
        }
        
        public var localFeedImage: LocalFeedImage {
            LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
        }
    }
    
    private let queue = DispatchQueue(label: "com.example.RealmFeedStore", qos: .background, attributes: .concurrent)

    public func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let realm = try Realm(configuration: Realm.Configuration(fileURL: storeURL, deleteRealmIfMigrationNeeded: true))
                
                if let cache = realm.objects(Cache.self).first {
                    completion(.found(cache.feedImages, cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        queue.async(flags: .barrier) { [storeURL] in
            do {
                let realm = try Realm(configuration: Realm.Configuration(fileURL: storeURL, deleteRealmIfMigrationNeeded: true))
                try realm.write {
                    
                    let oldCaches = realm.objects(Cache.self)
                    realm.delete(oldCaches)
                    
                    let realmCache = Cache()
                    realmCache.feed.append(objectsIn: RealmFeedImage.convert(localFeed: items))
                    realmCache.timestamp = timestamp
                    realm.add(realmCache)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

}
