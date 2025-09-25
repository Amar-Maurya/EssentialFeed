//
//  PersistedCache.swift
//  EssentialFeed
//
//  Created by 2674143 on 21/09/25.
//

import RealmSwift
import Foundation

 @objc(PersistedCache)
class PersistedCache: Object {
    @Persisted var timestamp: Date
    @Persisted var feed: List<PersistedFeedImage>
    
    public  var feedImages: [LocalFeedImage] {
        feed.map { $0.localFeedImage }
    }
}
