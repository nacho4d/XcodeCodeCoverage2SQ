import XCTest
@testable import XcodeCodeCoverage2SQ

final class XcodeCodeCoverage2SQTests: XCTestCase {
    func testExample() throws {
        let path = ""
        try XCTSkipIf(path.isEmpty, "Skipping because path is empty. A relatively large project thousands of files is desirable")

        let converter = XcodeCodeCoverage2SQ()
        converter.genericCodeCoverage(from: path, skippingSuffixes: [".m", ".mm"])
    }
}
