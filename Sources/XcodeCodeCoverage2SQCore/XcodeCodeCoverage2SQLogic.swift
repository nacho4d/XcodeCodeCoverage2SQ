
import Foundation

public struct XcodeCodeCoverage2SQLogic {

    let xcrunTool = XCRunTool()

    public init() {
    }

    func convertFile(xcarchivePath: String, filePath: String, index: Int) -> String {
        //stderr("Doing: \(index) \(filePath)")

        let lines = xcrunTool.getCoverageLines(xcarchivePath: xcarchivePath, filePath: filePath, index: index)
        let xml = lines.compactMap { line -> String? in
            if let lineCoverage = xcrunTool.parseCoverageLine(line) {
                let covered = lineCoverage.coverage > 0 ? "false" : "true"
                return "    <lineToCover lineNumber=\"\(lineCoverage.lineNum)\" covered=\"\(covered)\"/>"
            }
            return  nil
        }
        // if xml.isEmpty {
        //     return nil
        // }
        return "  <file path=\"\(filePath)\">\n\(xml.joined(separator: "\n"))\n  </file>"
    }

    /// Extract coverage for all files inside the xc result file and convert it to sonarqube generic XML format
    private func convertCoverage(xcarchivePath: String, skipSuffixes: [String]) {
        let filePaths = xcrunTool.getFilePaths(xcarchivePath: xcarchivePath)
        let suffixes = skipSuffixes.filter { !$0.isEmpty }

        stdout("<coverage version=\"1\">")

        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "xcresult-coverage-2-sq.concurrent.queue", qos: .userInitiated, attributes: .concurrent)
        let serialQueue = DispatchQueue(label: "xcresult-coverage-2-sq.serial.queue", qos: .userInitiated)

        group.enter()
        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: filePaths.count) { (fileIndex) in
                let filePath = filePaths[fileIndex]
                if filePath.isEmpty {
                    // TODO: Why this happens?
                    return
                }
                for skipSuffix in suffixes {
                    if filePath.hasSuffix(skipSuffix) {
                        return
                    }
                }
                let fileCoverage = self.convertFile(xcarchivePath: xcarchivePath, filePath: filePath, index: fileIndex)
                serialQueue.async {
                    //stderr("Finished: \(fileIndex)")
                    stdout(fileCoverage)
                }
            }
            group.leave()
        }

        group.wait()

        stdout("</coverage>")
    }

    public func genericCodeCoverage(from xcarchivePath: String, skippingSuffixes skipSuffixes: [String]) {
        stderr("Starting... \(xcarchivePath)")
        convertCoverage(xcarchivePath: xcarchivePath, skipSuffixes: skipSuffixes)
        stderr("...successfully done!")
    }
}
