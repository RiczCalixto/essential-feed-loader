//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import EssentialFeed
import Foundation
import XCTest

class RemoteFeedLoadersTests: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (_, client) = makeSUT(url: url)

    XCTAssertTrue(client.requestedURLs.isEmpty)
  }

  func test_load_requestsDataFromURL() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    sut.load { _ in }

    XCTAssertEqual(client.requestedURLs, [url])
  }

  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    sut.load { _ in }
    sut.load { _ in }

    XCTAssertEqual(client.requestedURLs, [url, url])
  }

  func test_load_deliversConnectivityError() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    expect(sut, toCompleteWithError: .connectivity, when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }

  func test_load_deliversInvalidDataIfNot200() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    let samples = [199, 201, 400, 500]

    for (index, code) in samples.enumerated() {
      expect(sut, toCompleteWithError: .invalidData, when: {
        client.complete(withStatusCode: code, at: index)
      })
    }
  }

  func test_load_deliversInvalidDataIfInvalidJSON() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    expect(sut, toCompleteWithError: .invalidData, when: {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }

  // MARK: Helpers

  private func expect(
    _ sut: RemoteFeedLoader,
    toCompleteWithError error: RemoteFeedLoader.Error,
    when action: () -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    var capturedErrors = [RemoteFeedLoader.Error]()
    sut.load { capturedErrors.append($0) }

    action()
    XCTAssertEqual(capturedErrors, [error], file: file, line: line)
  }

  private func makeSUT(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    var requestedURLs: [URL] {
      messages.map(\.url)
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
      messages.append((url: url, completion: completion))
    }

    func complete(with error: Error, data _: Data = Data(), at index: Int = 0) {
      messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
      let response = HTTPURLResponse(
        url: requestedURLs[index],
        statusCode: code,
        httpVersion: nil,
        headerFields: nil
      )!
      messages[index].completion(.success(data, response))
    }
  }
}
