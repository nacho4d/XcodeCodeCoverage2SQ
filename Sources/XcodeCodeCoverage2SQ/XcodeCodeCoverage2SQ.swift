
import Foundation

public struct XcodeCodeCoverage2SQ {

    public init() {
    }

    /// Gets file list from a xc result file
    /// xcrun xccov view --json --archive --file-list resultFileHere.xcresult
    private func getFilePathList(xcarchivePath: String) -> [String] {
        var result: (status: Int32, std: String?, err: String?)! = nil
        do {
            result = try exec("/usr/bin/xcrun", args:["xccov", "view", "--archive", "--file-list", xcarchivePath])
        } catch {
            errorExit(99, "getFilePathList exec \(error.localizedDescription)")
        }
        guard result.status == 0 else {
            errorExit(result.status, "getFilePathList " + (result.err ?? ""))
        }
        guard let std = result.std else {
            errorExit(result.status, "getFilePathList result.std " + (result.err ?? ""))
        }
        return std.components(separatedBy: "\n")
    }


    /**
        Example: Some lines that do not require coverage (comments, etc) have a star (*).
      1: *
      2: *
      3: *
      4: *
      5: *
      6: *
      7: *
      8: *
      9: *
     19: 9
     20: 9
     21: *
     22: 0
     23: 0
     */
    let regex = try! NSRegularExpression(pattern: "^\\s*(\\d+):\\s*(\\*|\\d+)")
    let regexLineGroup = 1
    let regexCoverageGroup = 2

    private func lineMatchesCoverage(_ line: String) -> (lineNum: String, coverage: Int)? {
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) else {
            return nil
        }
        let lineNumber: String
        do {
            let lNumR = match.range(at: regexLineGroup)
            lineNumber = String(line[line.index(line.startIndex, offsetBy: lNumR.location)..<line.index(line.startIndex, offsetBy: lNumR.location + lNumR.length)])
        }
        let lineCoverage: String
        do {
            let lCoverageR = match.range(at: regexCoverageGroup)
            lineCoverage = String(line[line.index(line.startIndex, offsetBy: lCoverageR.location)..<line.index(line.startIndex, offsetBy: lCoverageR.location + lCoverageR.length)])
        }
        guard let lineCoverageInt = Int(lineCoverage) else { // "Discard lines with "*" because they do not count for coverage
            return nil
        }
        return (lineNumber, lineCoverageInt)
    }

    /// Convert line coverage to sonarqube generic XML format
    /// xcrun xccov view --verbose --file  resultFileHere.xcresult /path/to/source/file.swift
    private func convertFile(xcarchivePath: String, filePath: String, index: Int) -> String {
        var result: (status: Int32, std: String?, err: String?)! = nil
        do {
            result = try exec("/usr/bin/xcrun", args:["xccov", "view", "--archive", "--file", filePath, xcarchivePath], ignoresStdErr: true)
        } catch {
            errorExit(99, "convertFile exec \(error.localizedDescription)")
        }
        guard result.status == 0 else {
            errorExit(result.status, "convertFile (retry with ignoresStdErr:false to get error)" + (result.err ?? ""))
        }
        guard let std = result.std else {
            errorExit(result.status, "convertFile result.std " + (result.err ?? ""))
        }

        //stderr("Doing: \(index) \(filePath)")

        let lines = std.components(separatedBy: "\n")
        let xml = lines.compactMap { line -> String? in
            if let lineCoverage = lineMatchesCoverage(line) {
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
        let filePaths = getFilePathList(xcarchivePath: xcarchivePath)
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
