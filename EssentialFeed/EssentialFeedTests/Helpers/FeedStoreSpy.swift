//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by 2674143 on 04/09/25.
//
import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
    var retrivalCompletions = [RetrivalCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    private(set) var receivedMessage = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
        case retrival
    }
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        insertions.append((items, timestamp))
        receivedMessage.append(.insert(items, timestamp))
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessage.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        retrivalCompletions.append(completion)
        receivedMessage.append(.retrival)
    }
    
    func completeRetrival(with error: Error?, at index: Int = 0) {
        retrivalCompletions[index](error)
    }
}
