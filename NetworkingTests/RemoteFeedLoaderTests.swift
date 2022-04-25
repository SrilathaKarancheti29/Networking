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
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https:a-requestedURL")!
        let (sut, client) = makeSUT()
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https:a-requestedURL")!
        let (sut, client) = makeSUT()
        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        //Arrange
        let (sut, client) = makeSUT()
        
        //Act
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0)}

        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        //Arrange
        let (sut, client) = makeSUT()
        
        //Act
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0)}

        client.complete(withStatusCode: 400)
        
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    private func makeSUT(url: URL = URL(string: "https:a-givenURL")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let url = URL(string: "https:a-requestedURL")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        private var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let httpURLResponse = HTTPURLResponse(url: requestedURLs[index],
                                                  statusCode: code,
                                                  httpVersion: nil,
                                                  headerFields: nil)
            messages[index].completion(nil, httpURLResponse)
        }
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }
    }
    
    
}
