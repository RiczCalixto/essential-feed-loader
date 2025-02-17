//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Taqtile on 17/02/25.
//

import EssentialFeed
import Foundation

public class FeedStoreSpy: FeedStore {
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert([LocalFeedImage], Date)
  }

  private(set) var receivedMessages = [ReceivedMessage]()
  private var deletionCompletions = [DeletionCompletion]()
  private var insertionCompletions = [InsertionCompletion]()

  public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }

  public func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }

  public func completeInsertion(with error: Error, at index: Int = 0) {
    insertionCompletions[index](error)
  }

  public func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }

  public func completeInsertionSuccessfully(at index: Int = 0) {
    insertionCompletions[index](nil)
  }

  public func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
    receivedMessages.append(.insert(items, timestamp))
    insertionCompletions.append(completion)
  }
}
