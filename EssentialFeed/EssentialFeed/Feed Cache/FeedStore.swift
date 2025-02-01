//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Taqtile on 01/02/25.
//

import Foundation

public protocol FeedStore {
  typealias InsertionCompletion = (Error?) -> Void
  typealias DeletionCompletion = (Error?) -> Void

  func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
}

public struct LocalFeedItem: Equatable {
  public let id: UUID
  public let description: String?
  public let location: String?
  public let imageURL: URL

  public init(id: UUID, description: String?, location: String?, imageURL: URL) {
    self.id = id
    self.description = description
    self.location = location
    self.imageURL = imageURL
  }
}
