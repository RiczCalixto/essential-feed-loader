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

    var capturedErrors = [RemoteFeedLoader.Error]()
    sut.load { capturedErrors.append($0) }

    let clientError = NSError(domain: "Test", code: 0)
    client.complete(with: clientError)

    XCTAssertEqual(capturedErrors, [.connectivity])
  }

  func test_load_deliversInvalidDataIfNot200() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    var capturedErrors = [RemoteFeedLoader.Error]()
    sut.load { capturedErrors.append($0) }

    client.complete(withStatusCode: 201)

    XCTAssertEqual(capturedErrors, [.invalidData])
  }

  // MARK: Helpers

  private func makeSUT(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    return (sut, client)
  }

  private class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
    var requestedURLs: [URL] {
      messages.map(\.url)
    }

    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
      messages.append((url: url, completion: completion))
    }

    func complete(with error: Error, index: Int = 0) {
      messages[index].completion(error, nil)
    }

    func complete(withStatusCode code: Int, index: Int = 0) {
      let response = HTTPURLResponse(
        url: requestedURLs[index],
        statusCode: code,
        httpVersion: nil,
        headerFields: nil
      )
      messages[index].completion(nil, response)
    }
  }
}
