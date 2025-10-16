//
//  EssentialFeedIOS.swift
//  EssentialFeedIOS
//
//  Created by 2674143 on 16/10/25.
//

import XCTest
import UIKit

final class FeedViewController: UIViewController {
    
    private var loader: FeedViewControllerTests.LoaderSpy? = nil
    
    convenience init(loader: FeedViewControllerTests.LoaderSpy) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load()
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
        
        func load() {
            loadCallCount += 1
        }
    }
    
    func test_load_viewDidLoad_LoadFeed() {
        
        let loader = LoaderSpy()
        
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
}
