//
//  CacheFeedResultUseCaseTests.swift
//  EssentialFeed
//
//  Created by Taqtile on 19/01/25.
//

import EssentialFeed
import Foundation
import XCTest

protocol FeedStore {
  typealias InsertionCompletion = (Error?) -> Void
  typealias DeletionCompletion = (Error?) -> Void

  func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
}

class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date

  init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }

  func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
    store.deleteCachedFeed { [weak self] error in
      guard let self else { return }

      if error == nil {
        store.insert(items, timestamp: currentDate(), completion: completion)
      } else {
        completion(error)
      }
    }
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
    let deletionError = anyNSError()

    expect(sut, toCompleteWithError: deletionError, when: {
      store.completeDeletion(with: deletionError)
    })
  }

  func test_save_failsOnInsertionError() {
    let (sut, store) = makeSUT()
    let insertionError = anyNSError()

    expect(sut, toCompleteWithError: insertionError, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertion(with: insertionError)
    })
  }

  func test_save_successfullyOnCacheInsertion() {
    let (sut, store) = makeSUT()

    expect(sut, toCompleteWithError: nil, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertionSuccessfully()
    })
  }

  func test_save_doesNotDeliverDeletionErrorIfSUTDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    let deletionError = anyNSError()
    var receivedResults = [Error?]()

    sut?.save([uniqueItem()]) { receivedResults.append($0) }

    sut = nil
    store.completeDeletion(with: deletionError)

    XCTAssertTrue(receivedResults.isEmpty)
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

  private func expect(
    _ sut: LocalFeedLoader,
    toCompleteWithError expectedError: NSError?,
    when action: () -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for save completion")

    var receivedError: Error?
    sut.save([uniqueItem()]) { error in
      receivedError = error
      exp.fulfill()
    }

    action()
    wait(for: [exp], timeout: 1.0)

    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }

  private class FeedStoreSpy: FeedStore {
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

    func completeInsertionSuccessfully(at index: Int = 0) {
      insertionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
      receivedMessages.append(.insert(items, timestamp))
      insertionCompletions.append(completion)
    }
  }

}
