//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Taqtile on 01/02/25.
//

import Foundation

struct RemoteFeedItem: Decodable {
  let id: UUID
  let description: String?
  let location: String?
  let image: URL
}
