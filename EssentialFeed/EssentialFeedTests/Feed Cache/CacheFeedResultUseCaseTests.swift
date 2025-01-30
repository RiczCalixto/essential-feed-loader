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
  private let currentDate: () -> Date

  init(store: FeedStoreSpy, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }

  func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
    store.deleteCachedFeed { [unowned self] error in
      if error == nil {
        store.insert(items, timestamp: currentDate()) { error in
          if let error {
            completion(error)
          }
        }
      } else {
        completion(error)
      }
    }
  }
}

class FeedStoreSpy {
  typealias DeletionCompletion = (Error?) -> Void
  typealias InsertionCompletion = (Error?) -> Void

  var insertions = [(items: [FeedItem], timestamp: Date)]()

  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert([FeedItem], Date)
  }

  private(set) var receivedMessages = [ReceivedMessage]()
  private var deletionCompletions = [DeletionCompletion]()
  private var insertionCompletions = [InsertionCompletion]()

  func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }

  func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }

  func completeInsertion(with error: Error, at index: Int = 0) {
    insertionCompletions[index](error)
  }

  func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }

  func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
    insertions.append((items, timestamp))
    receivedMessages.append(.insert(items, timestamp))
    insertionCompletions.append(completion)
  }
}

class CacheFeedResultUseCaseTests: XCTestCase {
  func test_doesNotMessageStoreUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.receivedMessages, [])
  }

  func test_requestCacheDeletion() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]

    sut.save(items) { _ in }

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }

  func test_save_doesNotRequestCacheInsertionOnDeletionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let deletionError = anyNSError()

    sut.save(items) { _ in }
    store.completeDeletion(with: deletionError)

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }

  func test_save_doesRequestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
    let timestamp = Date()
    let (sut, store) = makeSUT { timestamp }
    let items = [uniqueItem(), uniqueItem()]

    sut.save(items) { _ in }
    store.completeDeletionSuccessfully()

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
  }

  func test_save_failsOnDeletionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let deletionError = anyNSError()
    let exp = expectation(description: "Wait for save completion")

    var receivedError: Error?

    sut.save(items) { error in
      receivedError = error
      exp.fulfill()
    }

    store.completeDeletion(with: deletionError)
    wait(for: [exp], timeout: 1.0)

    XCTAssertEqual(receivedError as NSError?, deletionError)
  }

  func test_save_failsOnInsertionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let insertionError = anyNSError()
    let exp = expectation(description: "Wait for save completion")

    var receivedError: Error?

    sut.save(items) { error in
      receivedError = error
      exp.fulfill()
    }

    store.completeDeletionSuccessfully()
    store.completeInsertion(with: insertionError)
    wait(for: [exp], timeout: 1.0)

    XCTAssertEqual(receivedError as NSError?, insertionError)
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
    currentDate: @escaping () -> Date = Date.init,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)

    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)

    return (sut, store)
  }

  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
  }
}
