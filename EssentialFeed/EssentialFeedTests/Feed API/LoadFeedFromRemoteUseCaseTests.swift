//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Taqtile on 30/11/24.
//

import EssentialFeed
import Foundation
import XCTest

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
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

    expect(sut, toCompleteWithResult: failure(.connectivity), when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }

  func test_load_deliversInvalidDataIfNot200() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    let samples = [199, 201, 400, 500]

    for (index, code) in samples.enumerated() {
      expect(sut, toCompleteWithResult: failure(.invalidData), when: {
        let json = makeItemsJSON([])
        client.complete(withStatusCode: code, data: json, at: index)
      })
    }
  }

  func test_load_deliversInvalidDataIfInvalidJSON() {
    let url = URL(string: "https://a-url.com")!
    let (sut, client) = makeSUT(url: url)

    expect(sut, toCompleteWithResult: failure(.invalidData), when: {
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

  private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
    return .failure(error)
  }

  private func makeFeedItem(
    id: UUID,
    description: String? = nil,
    location: String? = nil,
    imageURL: URL
  ) -> (model: FeedImage, json: [String: Any]) {
    let feedItem = FeedImage(
      id: id,
      description: description,
      location: location,
      url: imageURL
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
    toCompleteWithResult expectedResult: RemoteFeedLoader.Result,
    when action: () -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for load completion")
    sut.load { receivedResult in
      switch (receivedResult, expectedResult) {
      case let (.success(receivedItems), .success(expectedItems)):
        XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

      case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
        XCTAssertEqual(receivedError, expectedError, file: file, line: line)

      default:
        XCTFail("Expected result \(expectedResult) but got \(receivedResult)", file: file, line: line)
      }

      exp.fulfill()
    }

    action()

    wait(for: [exp], timeout: 1.0)

  }

  private func makeSUT(
    url: URL,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    trackForMemoryLeaks(sut, file: file, line: line)
    trackForMemoryLeaks(client, file: file, line: line)

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
