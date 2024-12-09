//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 08/12/24.
//

import EssentialFeed
import Foundation
import XCTest

class URLSessionHTTPClient {
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { _, _, error in
      if let error {
        completion(.failure(error))
      }
    }.resume()
  }
}

class URLSessionHTTPClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequests()
  }

  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequests()
  }

  func test_getFromURL_failsOnRequestError() {
    let url = anyURL()
    let error = NSError(domain: "any error", code: 1)
    URLProtocolStub.stub(data: nil, response: nil, error: error)

    let sut = makeSUT()

    let exp = expectation(description: "Wait for completion")
    sut.get(from: url) { result in
      switch result {
      case let .failure(receivedError as NSError):
        XCTAssertEqual(receivedError.domain, error.domain)
        XCTAssertEqual(receivedError.code, error.code)
      default:
        XCTFail("Expected failure with error \(error), got \(result) instead")
      }

      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
  }

  func test_getFromURL_performsGetRequestWithURL() {
    let url = anyURL()

    let exp = expectation(description: "Wait for completion")
    URLProtocolStub.observeRequest { request in
      XCTAssertEqual(request.url, url)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }

    makeSUT().get(from: url, completion: { _ in })

    wait(for: [exp], timeout: 1.0)
  }

  // MARK: - Helpers

  private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }

  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }

  private class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stub = Stub(data: data, response: response, error: error)
    }

    static func observeRequest(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
      requestObserver = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
      requestObserver?(request)
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      if let data = URLProtocolStub.stub?.data {
        client?.urlProtocol(self, didLoad: data)
      }

      if let response = URLProtocolStub.stub?.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }

      if let error = URLProtocolStub.stub?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }

      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }

}
