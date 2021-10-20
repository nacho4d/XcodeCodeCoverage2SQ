import XCTest
@testable import XcodeCodeCoverage2SQCore

final class XcodeCodeCoverage2SQLogicTests: XCTestCase {
    func testExample() throws {
        let path = ""
        try XCTSkipIf(path.isEmpty, "Skipping because path is empty. A relatively large project thousands of files is desirable")

        let converter = XcodeCodeCoverage2SQLogic()
        converter.genericCodeCoverage(from: path, skippingSuffixes: [".m", ".mm"])
    }
}
