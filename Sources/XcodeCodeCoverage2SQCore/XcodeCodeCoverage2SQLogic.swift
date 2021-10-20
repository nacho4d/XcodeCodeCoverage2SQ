
import Foundation

public struct XcodeCodeCoverage2SQLogic {

    let xcrunTool = XCRunTool()

    public init() {
    }


    func getFilePaths(xcarchivePath: String, skippingSufixes: [String]) -> [String] {

        let suffixes = skippingSufixes.filter { !$0.isEmpty }

        let filePaths = xcrunTool.getFilePaths(xcarchivePath: xcarchivePath).filter { filePath in
            if filePath.isEmpty {
                // Usually the last filePath is empty
                return false
            }
            for skipSuffix in suffixes {
                if filePath.hasSuffix(skipSuffix) {
                    // File must be skipped
                    return false
                }
            }
            return true
        }
        return filePaths
    }

    func convertFile(xcarchivePath: String, filePath: String, index: Int) -> String {
        //stderr("Doing: \(index) \(filePath)")
        let lines = xcrunTool.getCoverageLines(xcarchivePath: xcarchivePath, filePath: filePath, index: index)
        let linesAsXml = lines.compactMap { line -> String? in
            guard let lineInfo = xcrunTool.parseCoverageLine(line) else {
                return nil
            }
            let covered = lineInfo.coverage > 0 ? "false" : "true"
            return "    <lineToCover lineNumber=\"\(lineInfo.lineNum)\" covered=\"\(covered)\"/>"
        }
        return "  <file path=\"\(filePath)\">\n\(linesAsXml.joined(separator: "\n"))\n  </file>"
    }

    /// Extract coverage for all files inside the xc result file and convert it to sonarqube generic XML format
    private func convertCoverage(xcarchivePath: String, skipSuffixes: [String]) {
        let filePaths = getFilePaths(xcarchivePath: xcarchivePath, skippingSufixes: skipSuffixes)

        stdout("<coverage version=\"1\">")

        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "xcresult-coverage-2-sq.concurrent.queue", qos: .userInitiated, attributes: .concurrent)
        let serialQueue = DispatchQueue(label: "xcresult-coverage-2-sq.serial.queue", qos: .userInitiated)

        group.enter()
        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: filePaths.count) { (fileIndex) in
                let filePath = filePaths[fileIndex]
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
