//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 08/12/24.
//

import Foundation
import XCTest

class URLSessionHTTPClient {
  private let session: URLSession

  init(session: URLSession) {
    self.session = session
  }

  func get(from url: URL) {
    session.dataTask(with: url) { _, _, _ in }
  }

}

class URLSessionHTTPClientTests: XCTestCase {
  func test_getFromURL_createsDataTaskWithURL() {
    let url = URL(string: "https://sample.com.br")!
    let session = URLSessionSpy()
    let sut = URLSessionHTTPClient(session: session)

    sut.get(from: url)

    XCTAssertEqual(session.receivedURLs, [url])
  }

  // MARK: Helpers

  class URLSessionSpy: URLSession {
    var receivedURLs = [URL]()

    override func dataTask(
      with url: URL,
      completionHandler _: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
      receivedURLs.append(url)
      return FakeURLSessionDataTask()
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}
  }
}
