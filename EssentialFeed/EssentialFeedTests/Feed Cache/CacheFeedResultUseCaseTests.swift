//
//  CacheFeedResultUseCaseTests.swift
//  EssentialFeed
//
//  Created by Taqtile on 19/01/25.
//

import EssentialFeed
import Foundation
import XCTest

class LocalFeedLoader {
  init(store _: FeedStoreSpy) {}
}

class FeedStoreSpy {
  var deleteCachedFeedCallCount = 0
}

class CacheFeedResultUseCaseTests: XCTestCase {
  func test_doesNotDeleteCacheUponCreation() {
    let store = FeedStoreSpy()
    let _ = LocalFeedLoader(store: store)

    XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
  }
}
