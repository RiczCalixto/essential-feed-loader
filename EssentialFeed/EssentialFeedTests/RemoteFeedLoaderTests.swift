//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import EssentialFeed
import Foundation
import XCTest

class RemoteFeedLoadersTests: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (_, client) = makeSUT(url: url)

    XCTAssertTrue(client.requestedURLs.isEmpty)
  }

  func test_load_requestsDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    sut.load()

    XCTAssertEqual(client.requestedURLs, [url])
  }

  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    sut.load()
    sut.load()

    XCTAssertEqual(client.requestedURLs, [url, url])
  }

  func test_load_deliversConnectivityError() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    client.error = NSError(domain: "Test", code: 0)
    var capturedErrors = [RemoteFeedLoader.Error]()

    sut.load { capturedErrors.append($0) }

    XCTAssertEqual(capturedErrors, [.connectivity])
  }

  // MARK: Helpers

  private func makeSUT(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    var error: Error?

    func get(from url: URL, completion: @escaping (Error) -> Void) {
      if let error {
        completion(error)
      }
      requestedURLs.append(url)
    }
  }
}
