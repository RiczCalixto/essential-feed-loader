//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Taqtile on 01/12/24.
//

import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }

  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url) { result in
      switch result {

      case let .success(data, httpResponse):
        if httpResponse.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) {
          completion(.success(root.items.map(\.item)))
        } else {
          completion(.failure(.invalidData))
        }

      case .failure:
        completion(.failure(.connectivity))
      }
    }
  }
}

private struct Root: Decodable {
  let items: [APIFeedItem]
}

private struct APIFeedItem: Decodable {
  let id: UUID
  let description: String?
  let location: String?
  let image: URL

  var item: FeedItem {
    return FeedItem(id: id, description: description, location: location, imageURL: image)
  }
}
