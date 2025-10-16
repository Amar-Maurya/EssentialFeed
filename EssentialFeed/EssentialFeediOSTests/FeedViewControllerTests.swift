//
//  FeedViewControllerTests.swift
//  EssentialFeedTests
//
//  Created by 2674143 on 16/10/25.
//

import XCTest

final class FeedViewController {
    
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeeds() {
        let loader = LoaderSpy()
        
        let _ = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    
    }
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
    
}
