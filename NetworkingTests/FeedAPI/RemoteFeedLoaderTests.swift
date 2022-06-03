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
            
        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        //Arrange
        let (sut, client) = makeSUT()

        //Act
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(.invalidData), when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidData() {
        //Arrange
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data:invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)

        })
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
                    id: UUID(),
                    imageURL: URL(string: "http://myURL.com")!)
        
        let item2 = makeItem(
                    id: UUID(),
                    description: "a description",
                    location: "a location",
                    imageURL: URL(string: "http://myURL1.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items), when: {
            let jsonData = makeItemsJSON(items: [item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        })

    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
                    id: id,
                    description: description,
                    location: location,
                    imageURL: imageURL)
        let json = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ].compactMapValues { $0 }

        return(item, json)
    }
    
    private func makeItemsJSON(items: [[String: Any]]) -> Data {
        let json = ["items" : items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeSUT(url: URL = URL(string: "https:a-givenURL")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let url = URL(string: "https:a-requestedURL")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load{ capturedResults.append ($0)}
        
        action()
        
        XCTAssertEqual([result], capturedResults, file: file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let httpURLResponse = HTTPURLResponse(url: requestedURLs[index],
                                                  statusCode: code,
                                                  httpVersion: nil,
                                                  headerFields: nil)!
            messages[index].completion(.success(data, httpURLResponse))
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
    }
    
    
}
