//
//  RealmFeedStore.swift
//  EssentialFeed
//
//  Created by 2674143 on 20/09/25.
//

import Foundation
import RealmSwift


public final class RealmFeedStore {
    
    public init() {}
    
    public func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        completion(.empty)
    }
}
