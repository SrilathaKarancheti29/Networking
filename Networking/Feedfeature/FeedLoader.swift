//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Srilatha Karancheti on 2022-04-20.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completionHandler: @escaping (LoadFeedResult) -> Void)
}
