//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Srilatha Karancheti on 2022-04-20.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
