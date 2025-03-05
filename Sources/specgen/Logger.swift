import os

let subsystem = "com.example.specgen"

func verboseLog(_ message: String, isVerbose: Bool) {
    if isVerbose {
        // Print directly to stdout for now to debug verbose mode
        print("🔍 [Verbose] \(message)")
        
        // Also use the OS logging system
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