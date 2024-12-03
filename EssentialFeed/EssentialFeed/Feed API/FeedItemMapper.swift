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

  static let OK_200 = 200

  static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
    guard response.statusCode == OK_200 else {
      throw RemoteFeedLoader.Error.invalidData
    }

    return try JSONDecoder().decode(Root.self, from: data).items.map(\.item)
  }
}
