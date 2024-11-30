//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import Foundation
import XCTest

class HTTPClient {
  var requestedURL: URL?
}

struct RemoteFeedLoader {}

class RemoteFeedLoadersTests: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let client = HTTPClient()
    let _ = RemoteFeedLoader()

    XCTAssertNil(client.requestedURL)
  }
}
