//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Taqtile on 03/12/24.
//

import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
