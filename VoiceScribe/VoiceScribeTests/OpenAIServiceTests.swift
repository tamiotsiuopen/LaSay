import XCTest
@testable import VoiceScribe

final class OpenAIServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testPolishTextRequestFormat() {
        let expectation = expectation(description: "Receives mocked response")

        _ = KeychainHelper.shared.save(key: "openai_api_key", value: "test-key")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.httpBody)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

            XCTAssertEqual(json["model"] as? String, "gpt-5-mini")
            let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
            XCTAssertEqual(messages.first?["role"] as? String, "system")
            XCTAssertEqual(messages.last?["role"] as? String, "user")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = "{\"choices\":[{\"message\":{\"content\":\"OK\"}}]}".data(using: .utf8)!
            return (response, data)
        }

        OpenAIService.shared.polishText("Hello") { result in
            if case .success(let text) = result {
                XCTAssertEqual(text, "OK")
            } else {
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Request handler not set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
