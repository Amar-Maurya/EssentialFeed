//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by 2674143 on 08/09/25.
//
import Foundation

internal final class FeedCachePolicy {
    private init() {}
    
    internal static let calendar = Calendar(identifier: .gregorian)
    internal static var maxCacheAgeInDays: Int {
        return 7
    }
    
    internal static func validate( timeStamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timeStamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
