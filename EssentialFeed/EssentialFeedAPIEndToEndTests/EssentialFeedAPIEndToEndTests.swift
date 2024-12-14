//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Taqtile on 14/12/24.
//

import EssentialFeed
import XCTest

final class EssentialFeedAPIEndToEndTests: XCTestCase {
  func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
    let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
    let client = URLSessionHTTPClient()
    let loader = RemoteFeedLoader(url: testServerURL, client: client)

    let exp = expectation(description: "Wait for completion")
    var capturedResult: RemoteFeedLoader.Result?
    loader.load(completion: { result in
      capturedResult = result
      exp.fulfill()
    })
    wait(for: [exp], timeout: 5.0)

    switch capturedResult {
    case let .success(items)?:
      XCTAssertEqual(items.count, 8, "Expected 8 items in the test account feed")
    case let .failure(error)?:
      XCTFail("Expected successful feed result, but got error \(error)")
    default:
      XCTFail("Expected successful feed result, got no result instead")
    }
  }
}
