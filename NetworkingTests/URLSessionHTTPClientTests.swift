//
//  URLSessionHTTPClientTests.swift
//  NetworkingTests
//
//  Created by Srilatha Karancheti on 2022-04-30.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createsDataTaskWithUR() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(session.receivedURLS , [url])
    }
    
    private class URLSessionSpy: URLSession {
        var receivedURLS = [URL]()
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLS.append(url)
            return FakeSessionDataTask()
        }
    }
    
    private class FakeSessionDataTask: URLSessionDataTask {}
}


