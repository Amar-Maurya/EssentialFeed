//
//  EssentialFeedIOS.swift
//  EssentialFeedIOS
//
//  Created by 2674143 on 16/10/25.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UIViewController {
    
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load { _ in
            
        }
    }
    
}

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeeds() {
        let (_, loader) = makeSut()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    
    }
    
    class LoaderSpy: FeedLoader {
        private(set) var loadCallCount = 0
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            loadCallCount += 1
        }
    }
    
    func test_load_viewDidLoad_LoadFeed() {
        let (sut, loader) = makeSut()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    private func makeSut(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
       
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        return (sut, loader)
        
    }
    
}
