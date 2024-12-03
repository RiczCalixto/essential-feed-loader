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

    expect(sut, toCompleteWithResult: .failure(.connectivity), when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }

  func test_load_deliversInvalidDataIfNot200() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    let samples = [199, 201, 400, 500]

    for (index, code) in samples.enumerated() {
      expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
        let json = makeItemsJSON([])
        client.complete(withStatusCode: code, data: json, at: index)
      })
    }
  }

  func test_load_deliversInvalidDataIfInvalidJSON() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }

  func test_load_deliversEmptyArrayIfEmptyJSONList() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    expect(sut, toCompleteWithResult: .success([]), when: {
      let emptyListJSON = makeItemsJSON([])
      client.complete(withStatusCode: 200, data: emptyListJSON)
    })
  }

  func test_load_deliversFeedItemArrayWithJSONList() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    let item1 = makeFeedItem(
      id: UUID(),
      description: "description",
      location: "location",
      imageURL: URL(string: "http://a-url.com")!
    )

    let item2 = makeFeedItem(
      id: UUID(),
      description: nil,
      location: nil,
      imageURL: URL(string: "http://a-url.com")!
    )

    let items = [item1.model, item2.model]

    expect(sut, toCompleteWithResult: .success(items), when: {
      let json = makeItemsJSON([item1.json, item2.json])
      client.complete(withStatusCode: 200, data: json)
    })
  }

  func test_load_clientDoesNotDeliverResultIfSUTIsDeallocated() {
    let url = URL(string: "https://a-url.com")!
    let client = HTTPClientSpy()
    var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

    var capturedResults = [RemoteFeedLoader.Result]()
    sut?.load { capturedResults.append($0) }

    sut = nil
    client.complete(withStatusCode: 200, data: makeItemsJSON([]))

    XCTAssertTrue(capturedResults.isEmpty)
  }

  // MARK: Helpers

  private func makeFeedItem(
    id: UUID,
    description: String? = nil,
    location: String? = nil,
    imageURL: URL
  ) -> (model: FeedItem, json: [String: Any]) {
    let feedItem = FeedItem(
      id: id,
      description: description,
      location: location,
      imageURL: imageURL
    )

    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageURL.absoluteString
    ].compactMapValues(\.self)

    return (feedItem, json)
  }

  private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]

    return try! JSONSerialization.data(withJSONObject: json)
  }

  private func expect(
    _ sut: RemoteFeedLoader,
    toCompleteWithResult result: RemoteFeedLoader.Result,
    when action: () -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load { capturedResults.append($0) }

    action()
    XCTAssertEqual(capturedResults, [result], file: file, line: line)
  }

  private func makeSUT(url: URL) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    trackForMemoryLeaks(sut)
    trackForMemoryLeaks(client)

    return (sut, client)
  }

  private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
    }
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

    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
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
