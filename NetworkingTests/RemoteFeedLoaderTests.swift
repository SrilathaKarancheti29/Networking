//
//  RemoteFeedLoaderTests.swift
//  NetworkingTests
//
//  Created by Srilatha Karancheti on 2022-04-23.
//

import XCTest
import Networking

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertNil(client.requestedURL)
        
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https:a-requestedURL")!
        let (sut, client) = makeSUT()
        sut.load()
        XCTAssertEqual(client.requestedURL, url)
    }
    
    private func makeSUT(url: URL = URL(string: "https:a-givenURL")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let url = URL(string: "https:a-requestedURL")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }
    
    
}
