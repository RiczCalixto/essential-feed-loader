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

  struct UnexpectedValueRepresentation: Error {}

  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url) { _, _, error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.failure(UnexpectedValueRepresentation()))
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

  func test_getFromURL_failsOnRequestError() {
    let requestError = anyError() as NSError
    let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?

    XCTAssertEqual(receivedError?.domain, requestError.domain)
    XCTAssertEqual(receivedError?.code, requestError.code)

  }

  func test_getFromURL_failtOnAllINvalidRepresentationValues() {
    let nonHTTPURLResponse = anyURLResponse()
    let anyHTTPURLResponse = anyHTTPURLResponse()
    let anyData = anyData()
    let anyError = anyError()

    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: nil))
  }

  private func resultErrorFor(
    data: Data? = nil,
    response: URLResponse? = nil,
    error: Error? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Error? {
    URLProtocolStub.stub(data: data, response: response, error: error)
    var receivedError: Error?
    let exp = expectation(description: "Wait for completion")

    makeSUT(file: file, line: line).get(from: anyURL()) { result in
      switch result {
      case let .failure(error):
        receivedError = error
      default:
        XCTFail("Expected failure, got \(result) instead", file: file, line: line)
      }

      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return receivedError
  }

  // MARK: - Helpers

  private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }

  private func anyURLResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }

  private func anyHTTPURLResponse() -> HTTPURLResponse {
    return HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }

  private func anyData() -> Data {
    return Data()
  }

  private func anyError() -> Error {
    return NSError(domain: "any error", code: 1)
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
