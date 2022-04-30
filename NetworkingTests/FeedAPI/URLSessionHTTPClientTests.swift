//
//  URLSessionHTTPClientTests.swift
//  NetworkingTests
//
//  Created by Srilatha Karancheti on 2022-04-30.
//

import XCTest
import Networking

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentationError: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, data.count > 0, let response = response as? HTTPURLResponse{
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValuesRepresentationError()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()

    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let exp = expectation(description: "Wait for request")
        let url = anyURL
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            
            exp.fulfill()
        }
        
        makeSUT().get(from: anyURL) { _ in}
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let receivedError = resultErrorFor(data: nil, response: nil, error: anyNSError) as NSError?
        
        XCTAssertEqual(anyNSError.domain, receivedError?.domain)
        XCTAssertEqual(anyNSError.code, receivedError?.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyURLResponse, error: nil))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData
        let response = anyHTTPURLResponse
        
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let exp = expectation(description: "Wait for completion")

        makeSUT().get(from: anyURL) { result in
            switch result {
            case let .success(receivedData, receivedResponse):
                XCTAssertEqual(data, receivedData)
                XCTAssertEqual(response?.url, receivedResponse.url)
                XCTAssertEqual(response?.statusCode, receivedResponse.statusCode)

            case .failure:
                XCTFail("Expected success got \(result) instead")
                
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        
        var receivedError: Error?

        sut.get(from: anyURL) { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Expected failure got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return receivedError
    }
    
    private var anyURL: URL {
        URL(string: "http://any-url.com")!
    }
    
    private var anyData: Data {
        return Data("anyData".utf8)
    }
    
    private var anyHTTPURLResponse: HTTPURLResponse? {
        return HTTPURLResponse(url: anyURL, statusCode: 200, httpVersion: nil, headerFields: nil)
    }
    
    private var anyURLResponse: URLResponse {
       return URLResponse(url: anyURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private var anyNSError: NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private class URLProtocolStub: URLProtocol {
        
        private static var stub: Stub?
        private static var requestObserver:((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    
    }

}


