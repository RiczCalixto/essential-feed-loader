//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Taqtile on 03/12/24.
//

import Foundation

enum FeedItemsMapper {
  private struct Root: Decodable {
    let items: [APIFeedItem]
    var feed: [FeedItem] {
      return items.map(\.item)
    }
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

  private static let OK_200 = 200

  static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
    guard response.statusCode == OK_200,
          let root = try? JSONDecoder().decode(Root.self, from: data) else
    {
      return .failure(RemoteFeedLoader.Error.invalidData)
    }

    return .success(root.feed)
  }
}
