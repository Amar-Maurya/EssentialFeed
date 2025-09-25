//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by 2674143 on 08/09/25.
//
import Foundation

 final class FeedCachePolicy {
    private init() {}
    
     static let calendar = Calendar(identifier: .gregorian)
     static var maxCacheAgeInDays: Int {
        return 7
    }
    
     static func validate( timeStamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timeStamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
