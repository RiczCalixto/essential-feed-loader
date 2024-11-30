//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import Foundation
import XCTest

protocol HTTPClient {
  func get(from url: URL)
}

class RemoteFeedLoader {
  let url: URL
  let client: HTTPClient
  init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  func load() {
    client.get(from: url)
  }
}

class RemoteFeedLoadersTests: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (_, client) = makeSUT(url: url)

    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    sut.load()

    XCTAssertEqual(client.requestedURL, url)
  }

  // MARK: Helpers

  private func makeSUT(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    func get(from url: URL) {
      requestedURL = url
    }
  }
}
