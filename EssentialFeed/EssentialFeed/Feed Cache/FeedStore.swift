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

  func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
}
