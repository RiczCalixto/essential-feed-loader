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

class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  func get(from url: URL) {
    requestedURL = url
  }
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
    let client = HTTPClientSpy()
    let _ = RemoteFeedLoader(url: url, client: client)

    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let client = HTTPClientSpy()

    let sut = RemoteFeedLoader(url: url, client: client)
    sut.load()

    XCTAssertNotNil(client.requestedURL)
  }
}
