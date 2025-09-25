//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeed
//
//  Created by 2674143 on 13/09/25.
//

import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert((uniqueImageFeed().local, Date()), sut: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImageFeed().local, Date()), sut: sut)
        
        expect(sut, toExpected: .success(.none), file: file, line: line)
    }
}
