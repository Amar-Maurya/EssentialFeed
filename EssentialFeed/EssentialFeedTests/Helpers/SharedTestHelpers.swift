//
//  SharedTestHelpers.swift
//  EssentialFeed
//
//  Created by 2674143 on 07/09/25.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}


func anyURL() -> URL {
   return URL(string: "http://any-url.com")!
}
