import XCTest
@testable import VoiceScribe

final class KeychainHelperTests: XCTestCase {
    func testSaveGetDelete() {
        let helper = KeychainHelper.shared
        let key = "test_key"
        let value = "secret"

        XCTAssertTrue(helper.save(key: key, value: value))
        XCTAssertEqual(helper.get(key: key), value)
        XCTAssertTrue(helper.delete(key: key))
        XCTAssertNil(helper.get(key: key))
    }
}
