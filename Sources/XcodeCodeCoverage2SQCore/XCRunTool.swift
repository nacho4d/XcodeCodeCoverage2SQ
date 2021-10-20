//
//  File.swift
//  
//
//  Created by Guillermo Ignacio Enriquez Gutierrez on 2021/10/20.
//

import Foundation

struct XCRunTool {
    
    /// Gets file list from a xc result file
    /// xcrun xccov view --json --archive --file-list resultFileHere.xcresult
    func getFilePaths(xcarchivePath: String) -> [String] {
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

    /// Convert line coverage to sonarqube generic XML format
    /// xcrun xccov view --verbose --file  resultFileHere.xcresult /path/to/source/file.swift
    func getCoverageLines(xcarchivePath: String, filePath: String, index: Int) -> [String] {
        var result: (status: Int32, std: String?, err: String?)! = nil
        do {
            result = try exec("/usr/bin/xcrun", args:["xccov", "view", "--archive", "--file", filePath, xcarchivePath], ignoresStdErr: true)
        } catch {
            errorExit(98, "convertFile exec \(error.localizedDescription)")
        }
        guard result.status == 0 else {
            errorExit(result.status, "convertFile (retry with ignoresStdErr:false to get error)" + (result.err ?? ""))
        }
        guard let std = result.std else {
            errorExit(result.status, "convertFile result.std " + (result.err ?? ""))
        }

        return std.components(separatedBy: "\n")
    }

    let regex = try! NSRegularExpression(pattern: "^\\s*(\\d+):\\s*(\\*|\\d+)")
    let regexLineGroup = 1
    let regexCoverageGroup = 2

    func parseCoverageLine(_ line: String) -> (lineNum: String, coverage: Int)? {
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
}
