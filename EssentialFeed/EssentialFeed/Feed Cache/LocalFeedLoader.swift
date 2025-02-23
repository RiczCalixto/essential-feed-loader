//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Taqtile on 01/02/25.
//

import Foundation

public class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date

  public typealias SaveResult = Error?
  public typealias LoadResult = LoadFeedResult

  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }

  public func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
    store.deleteCachedFeed { [weak self] error in
      guard let self else { return }

      if let cacheDeletionError = error {
        completion(cacheDeletionError)
      } else {
        cache(items, completion: completion)
      }
    }
  }

  public func load(completion: @escaping (LoadResult) -> Void) {
    store.retrieve { error in
      if let error {
        completion(.failure(error))
      }
    }
  }

  private func cache(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
    store.insert(items.toLocalFeedItem(), timestamp: currentDate()) { [weak self] error in
      guard self != nil else { return }
      completion(error)
    }
  }
}

private extension [FeedImage] {
  func toLocalFeedItem() -> [LocalFeedImage] {
    return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
  }
}
