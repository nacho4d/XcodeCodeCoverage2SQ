
import Foundation
import XcodeCodeCoverage2SQCore
import ArgumentParser

struct Command: ParsableCommand {

    @Option(name: .shortAndLong, parsing: .upToNextOption, help: "xcresult bundles that contains code coverage (Currently only one xcresult file is supported)")
    var xcresults: [String]

    @Option(name: .shortAndLong, help: "A comma separated list of prefixes (file extensions). For example --skip-prefixes='.m,.mm'")
    var skipPrefixes: String

    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "xccodecoverage2sonar",
            abstract: "xccodecoverage2sonar converts code coverage from xcresult files into generic XML format specially for sonarqube",
            discussion: "",
            version: "0.0.1")
    }

    mutating func run() throws {
        let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        // TODO: handle file list. not only one file
        let url = URL(fileURLWithPath: xcresults.first!, relativeTo: pwd)
        let suffixes = skipPrefixes.components(separatedBy: ",")
        let converter = XcodeCodeCoverage2SQLogic()
        converter.genericCodeCoverage(from: url.absoluteString, skippingSuffixes: suffixes)
    }
}

Command.main()
