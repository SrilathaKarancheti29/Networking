//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Srilatha Karancheti on 2022-04-20.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult: Equatable where Error : Equatable {}

protocol FeedLoader {
    associatedtype Error: Swift.Error

    func load(completionHandler: @escaping (LoadFeedResult<Error>) -> Void)
}
