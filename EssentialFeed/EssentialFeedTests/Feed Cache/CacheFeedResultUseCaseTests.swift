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
  private let store: FeedStoreSpy

  init(store: FeedStoreSpy) {
    self.store = store
  }

  func save(items _: [FeedItem]) {
    store.deleteCachedFeed()
  }
}

class FeedStoreSpy {
  var deleteCachedFeedCallCount = 0

  func deleteCachedFeed() {
    deleteCachedFeedCallCount += 1
  }
}

class CacheFeedResultUseCaseTests: XCTestCase {
  func test_doesNotDeleteCacheUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
  }

  func test_requestCacheDeletion() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]

    sut.save(items: items)

    XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
  }

  // MARK: Helpers

  private func uniqueItem() -> FeedItem {
    return FeedItem(
      id: UUID(),
      description: "Description",
      location: nil,
      imageURL: anyURL()
    )
  }

  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }

  private func makeSUT(
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store)

    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)

    return (sut, store)
  }
}
