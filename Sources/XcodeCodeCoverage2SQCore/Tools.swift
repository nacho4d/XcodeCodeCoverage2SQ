
import Foundation

internal struct FileHandleOutputStream: TextOutputStream {
    private let fileHandle: FileHandle
    let encoding: String.Encoding

    init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
    }

    mutating func write(_ string: String) {
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }

    static var stderr = FileHandleOutputStream(.standardError)
    static var stdout = FileHandleOutputStream(.standardOutput)
}

func stderr(_ message: String) {
    print(message, to: &FileHandleOutputStream.stderr)
}

func stdout(_ message: String) {
    print(message, to: &FileHandleOutputStream.stdout)
}

func errorExit(_ status: Int32, _ message: String) -> Never {
    print("ERROR: \(message)", to: &FileHandleOutputStream.stderr)
    exit(status)
}

func exec(_ processPath: String, args: [String], ignoresStdErr: Bool = false) throws -> (status: Int32, std: String?, err: String?) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: processPath)
    process.arguments = args

    let pipeOut = Pipe()
    process.standardOutput = pipeOut

    let pipeErr = Pipe()
    process.standardError = pipeErr

    try process.run()

    let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
    let outputOut = String(data: dataOut, encoding: .utf8)

    var outputErr: String? = nil
    if !ignoresStdErr {
        let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
        outputErr = String(data: dataErr, encoding: .utf8)
    }

    process.waitUntilExit()

    return (process.terminationStatus, outputOut, outputErr)
}
