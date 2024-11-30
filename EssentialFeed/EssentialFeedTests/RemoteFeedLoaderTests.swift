//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import Foundation
import XCTest

class HTTPClient {
  static var standard = HTTPClient()

  func get(from _: URL) {}
}

class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  override func get(from url: URL) {
    requestedURL = url
  }
}

struct RemoteFeedLoader {
  func load() {
    HTTPClient.standard.get(from: URL(string: "https://a-url.com")!)
  }
}

class RemoteFeedLoadersTests: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let client = HTTPClientSpy()
    HTTPClient.standard = client
    let _ = RemoteFeedLoader()

    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let client = HTTPClientSpy()
    HTTPClient.standard = client

    let sut = RemoteFeedLoader()
    sut.load()

    XCTAssertNotNil(client.requestedURL)
  }
}
