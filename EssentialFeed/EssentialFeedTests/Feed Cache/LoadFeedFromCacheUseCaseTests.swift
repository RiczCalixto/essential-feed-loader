//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeed
//
//  Created by Taqtile on 17/02/25.
//

import EssentialFeed
import Foundation
import XCTest

class LoadFeedFromCacheUseCaseTests: XCTestCase {
  func test_init_doesNotMessageStoreUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.receivedMessages, [])
  }

  func test_load_requestCacheRetrieval() {
    let (sut, store) = makeSUT()

    sut.load { _ in }

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func test_load_failsOnRetrievalError() {
    let (sut, store) = makeSUT()
    let retrievalError = anyNSError()
    let exp = expectation(description: "Wait for load completion")

    var capturedError: Error?

    sut.load { result in
      switch result {
      case let .failure(error):
        capturedError = error
      default:
        XCTFail("Expected failure, got \(result) instead")
      }
      exp.fulfill()
    }

    store.completeRetrieval(with: retrievalError)
    wait(for: [exp], timeout: 1.0)

    XCTAssertEqual(capturedError as NSError?, retrievalError)
  }

  // MARK: Helpers

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
