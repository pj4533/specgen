import os

let subsystem = "com.example.specgen"

func verboseLog(_ message: String, isVerbose: Bool) {
    if isVerbose {
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            // New logging API
            let logger = Logger(subsystem: subsystem, category: "main")
            logger.debug("\(message)")
        } else {
            // Legacy logging API
            os_log("%{public}@", log: OSLog(subsystem: subsystem, category: "main"), type: .debug, message)
        }
    }
}