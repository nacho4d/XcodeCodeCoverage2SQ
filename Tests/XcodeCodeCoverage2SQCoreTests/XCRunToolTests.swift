
import XCTest
@testable import XcodeCodeCoverage2SQCore

final class XCRunToolTests: XCTestCase {
    func testLineParse() throws {

        let example =
        """
          1: *
          9: *
         19: 9
         20: 200
         21: *
         22: 0
         23: 0
        """.components(separatedBy: "\n")

        let xcrun = XCRunTool()

        var r: (lineNum: String, coverage: Int)? = nil

        r = xcrun.parseCoverageLine(example[0])
        XCTAssertNil(r)
        r = xcrun.parseCoverageLine(example[1])
        XCTAssertNil(r)

        r = xcrun.parseCoverageLine(example[2])
        XCTAssertEqual(r?.lineNum, "19")
        XCTAssertEqual(r?.coverage, 9)
        r = xcrun.parseCoverageLine(example[3])
        XCTAssertEqual(r?.lineNum, "20")
        XCTAssertEqual(r?.coverage, 200)

        r = xcrun.parseCoverageLine(example[4])
        XCTAssertNil(r)

        r = xcrun.parseCoverageLine(example[5])
        XCTAssertEqual(r?.lineNum, "22")
        XCTAssertEqual(r?.coverage, 0)
        r = xcrun.parseCoverageLine(example[6])
        XCTAssertEqual(r?.lineNum, "23")
        XCTAssertEqual(r?.coverage, 0)
    }
}
