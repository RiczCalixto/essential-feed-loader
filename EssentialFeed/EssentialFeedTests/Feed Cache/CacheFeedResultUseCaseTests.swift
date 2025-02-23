//
//  CacheFeedResultUseCaseTests.swift
//  EssentialFeed
//
//  Created by Taqtile on 19/01/25.
//

import EssentialFeed
import Foundation
import XCTest

class CacheFeedResultUseCaseTests: XCTestCase {
  func test_init_doesNotMessageStoreUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.receivedMessages, [])
  }

  func test_requestCacheDeletion() {
    let (sut, store) = makeSUT()

    sut.save(uniqueImageFeed().model) { _ in }

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }

  func test_save_doesNotRequestCacheInsertionOnDeletionError() {
    let (sut, store) = makeSUT()
    let deletionError = anyNSError()

    sut.save(uniqueImageFeed().model) { _ in }
    store.completeDeletion(with: deletionError)

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }

  func test_save_doesRequestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
    let timestamp = Date()
    let (sut, store) = makeSUT { timestamp }
    let (model, local) = uniqueImageFeed()
    sut.save(model) { _ in }
    store.completeDeletionSuccessfully()

    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(local, timestamp)])
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
    var receivedResults = [LocalFeedLoader.SaveResult]()

    sut?.save([uniqueImage()]) { receivedResults.append($0) }

    sut = nil
    store.completeDeletion(with: anyNSError())

    XCTAssertTrue(receivedResults.isEmpty)
  }

  func test_save_doesNotDeliverInsertionErrorIfSUTDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    var receivedResults = [LocalFeedLoader.SaveResult]()

    sut?.save([uniqueImage()]) { receivedResults.append($0) }
    store.completeDeletionSuccessfully()

    sut = nil
    store.completeInsertion(with: anyNSError())

    XCTAssertTrue(receivedResults.isEmpty)
  }

  // MARK: Helpers

  private func uniqueImage() -> FeedImage {
    return FeedImage(
      id: UUID(),
      description: "Description",
      location: nil,
      url: anyURL()
    )
  }

  private func uniqueImageFeed() -> (model: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(
      id: $0.id,
      description: $0.description,
      location: $0.location,
      url: $0.url
    ) }
    return (models, local)
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
    sut.save([uniqueImage()]) { error in
      receivedError = error
      exp.fulfill()
    }

    action()
    wait(for: [exp], timeout: 1.0)

    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }
}
