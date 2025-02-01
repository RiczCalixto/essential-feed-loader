//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Taqtile on 03/12/24.
//

import Foundation

enum FeedItemsMapper {
  private struct Root: Decodable {
    let items: [RemoteFeedItem]
  }

  private static let OK_200 = 200

  static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
    guard response.statusCode == OK_200,
          let root = try? JSONDecoder().decode(Root.self, from: data) else
    {
      throw RemoteFeedLoader.Error.invalidData
    }

    return root.items
  }
}
