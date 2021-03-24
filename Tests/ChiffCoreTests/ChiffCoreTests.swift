import XCTest
@testable import ChiffCore

final class ChiffCoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ChiffCore().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
