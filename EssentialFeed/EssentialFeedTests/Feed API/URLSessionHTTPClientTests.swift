//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 08/12/24.
//

import EssentialFeed
import Foundation
import XCTest

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
    let requestError = anyNSError()
    let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as NSError?

    XCTAssertEqual(receivedError?.domain, requestError.domain)
    XCTAssertEqual(receivedError?.code, requestError.code)

  }

  func test_getFromURL_faillOnAllINvalidRepresentationValues() {
    XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyURLResponse(), error: nil))
  }

  func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
    let data = anyData()
    let response = anyHTTPURLResponse()
    let receivedValues = resultValuesFor(data: data, response: response, error: nil)

    XCTAssertEqual(data, receivedValues?.data)
    XCTAssertEqual(response.statusCode, receivedValues?.response.statusCode)
    XCTAssertEqual(response.url, receivedValues?.response.url)
  }

  func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
    let response = anyHTTPURLResponse()

    let receivedValues = resultValuesFor(data: nil, response: response, error: nil)

    let emptyData = Data()
    XCTAssertEqual(receivedValues?.data, emptyData)
    XCTAssertEqual(receivedValues?.response.url, response.url)
    XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
  }

  // MARK: - Helpers

  private func resultValuesFor(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    file: StaticString = #file,
    line: UInt = #line
  ) -> (data: Data, response: HTTPURLResponse)? {
    let result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .success(data, response):
      return (data, response)
    default:
      XCTFail("Expected success, got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func resultErrorFor(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Error? {
    let result = resultFor(data: data, response: response, error: error, file: file, line: line)

    switch result {
    case let .failure(error):
      return error
    default:
      XCTFail("Expected failure, got \(result) instead", file: file, line: line)
      return nil
    }
  }

  private func resultFor(
    data: Data?,
    response: URLResponse?,
    error: Error?,
    file: StaticString = #file,
    line: UInt = #line
  ) -> HTTPClientResult {
    URLProtocolStub.stub(data: data, response: response, error: error)
    let sut = makeSUT(file: file, line: line)
    let exp = expectation(description: "Wait for completion")

    var receivedResult: HTTPClientResult!
    sut.get(from: anyURL()) { result in
      receivedResult = result
      exp.fulfill()
    }

    wait(for: [exp], timeout: 1.0)
    return receivedResult
  }

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
    return Data("any data".utf8)
  }

  private func anyNSError() -> NSError {
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

    override class func canInit(with _: URLRequest) -> Bool {
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      if let requestObserver = URLProtocolStub.requestObserver {
        client?.urlProtocolDidFinishLoading(self)
        return requestObserver(request)
      }

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
