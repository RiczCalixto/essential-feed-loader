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
    session.dataTask(with: url) { _, _, _ in }.resume()
  }

}

class URLSessionHTTPClientTests: XCTestCase {
  func test_getFromURL_resumesDataTaskWithURL() {
    let url = URL(string: "https://sample.com.br")!
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()
    session.stub(url: url, task: task)

    let sut = URLSessionHTTPClient(session: session)

    sut.get(from: url)

    XCTAssertEqual(task.resumeCallCount, 1)
  }

  // MARK: Helpers

  class URLSessionSpy: URLSession {
    var receivedURLs = [URL]()
    private var stubs = [URL: URLSessionDataTask]()

    func stub(url: URL, task: URLSessionDataTask) {
      stubs[url] = task
    }

    override func dataTask(
      with url: URL,
      completionHandler _: @escaping (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
      receivedURLs.append(url)
      return stubs[url] ?? FakeURLSessionDataTask()
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
      override func resume() {}

    }
  }

  class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCallCount = 0

    override func resume() {
      resumeCallCount += 1
    }
  }
}
