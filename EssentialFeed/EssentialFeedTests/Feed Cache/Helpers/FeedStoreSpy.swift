//
//  FeedStoreSpy.swift
//  EssentialFeed
//
//  Created by Taqtile on 17/02/25.
//

import EssentialFeed
import Foundation

class FeedStoreSpy: FeedStore {
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert([LocalFeedImage], Date)
    case retrieve
  }

  private(set) var receivedMessages = [ReceivedMessage]()
  private var deletionCompletions = [DeletionCompletion]()
  private var insertionCompletions = [InsertionCompletion]()
  private var retrievalCompletions = [RetrievalCompletion]()

  func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }

  func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }

  func completeInsertion(with error: Error, at index: Int = 0) {
    insertionCompletions[index](error)
  }

  func completeRetrieval(with error: Error, at index: Int = 0) {
    retrievalCompletions[index](error)
  }

  func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }

  func completeInsertionSuccessfully(at index: Int = 0) {
    insertionCompletions[index](nil)
  }

  func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
    receivedMessages.append(.insert(items, timestamp))
    insertionCompletions.append(completion)
  }

  func retrieve(completion: @escaping RetrievalCompletion) {
    receivedMessages.append(.retrieve)
    retrievalCompletions.append(completion)
  }
}
