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

  func save(_ items: [FeedItem]) {
    store.deleteCachedFeed { [unowned self] error in
      if error == nil {
        store.insert(items)
      }
    }
  }
}

class FeedStoreSpy {
  typealias DeletionCompletion = (Error?) -> Void

  var deleteCachedFeedCallCount = 0
  var inserCallCount = 0

  private var deletionCompletions = [DeletionCompletion]()

  func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deleteCachedFeedCallCount += 1
    deletionCompletions.append(completion)
  }

  func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }

  func completeSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }

  func insert(_: [FeedItem]) {
    inserCallCount += 1
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

    sut.save(items)

    XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
  }

  func test_save_doesNotRequestCacheInsertionOnDeletionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let deletionError = anyNSError()

    sut.save(items)
    store.completeDeletion(with: deletionError)

    XCTAssertEqual(store.inserCallCount, 0)
  }

  func test_save_doesRequestNewCacheInsertionOnSuccessfulDeletion() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]

    sut.save(items)
    store.completeSuccessfully()

    XCTAssertEqual(store.inserCallCount, 1)
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

  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
  }
}
