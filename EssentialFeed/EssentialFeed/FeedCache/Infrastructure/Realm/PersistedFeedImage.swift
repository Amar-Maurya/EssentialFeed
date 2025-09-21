//
//  Untitled.swift
//  EssentialFeed
//
//  Created by 2674143 on 21/09/25.
//

import RealmSwift
import Foundation

@objc(PersistedFeedImage)
 class PersistedFeedImage: Object {
    @Persisted var id: UUID
    @Persisted var imageDescription: String?
    @Persisted var location: String?
    @Persisted var urlString: String
    
    var url: URL { URL(string: urlString)! }
    
    static func convert(localFeed: [LocalFeedImage]) -> [PersistedFeedImage] {
        localFeed.map { feed in
            let realmFeed = PersistedFeedImage()
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
