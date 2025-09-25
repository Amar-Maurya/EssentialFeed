//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by 2674143 on 06/09/25.
//
import Foundation

 struct RemoteFeedItem: Decodable {
     let id: UUID
     let description: String?
     let location: String?
     let image: URL
}
