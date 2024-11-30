//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import Foundation
import XCTest

class HTTPClient {
  static let standard = HTTPClient()
  var requestedURL: URL?
  private init() {}
}

struct RemoteFeedLoader {
  func load() {
    HTTPClient.standard.requestedURL = URL(string: "https://a-url.com")
  }
}

class RemoteFeedLoadersTests: XCTestCase {
  override class func tearDown() {
    HTTPClient.standard.requestedURL = nil
  }

  func test_doesNotRequestDataFromURL() {
    let client = HTTPClient.standard
    let _ = RemoteFeedLoader()

    XCTAssertNil(client.requestedURL)
  }

  func test_load_requestDataFromURL() {
    let client = HTTPClient.standard
    let sut = RemoteFeedLoader()
    sut.load()

    XCTAssertNotNil(client.requestedURL)
  }
}
