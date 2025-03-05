import Foundation

func getApiKey(isVerbose: Bool = false) -> String? {
    // First check environment variables
    verboseLog("Checking for OPENAI_API_KEY in environment variables", isVerbose: isVerbose)
    if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        verboseLog("Found OPENAI_API_KEY in environment variables", isVerbose: isVerbose)
        return apiKey
    }
    
    // If not found in environment, look for .env file
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let envFilePath = currentPath + "/.env"
    
    verboseLog("Looking for .env file at: \(envFilePath)", isVerbose: isVerbose)
    
    if fileManager.fileExists(atPath: envFilePath) {
        verboseLog(".env file found, parsing contents", isVerbose: isVerbose)
        do {
            let contents = try String(contentsOfFile: envFilePath, encoding: .utf8)
            let lines = contents.split(separator: "\n")
            
            verboseLog("Found \(lines.count) lines in .env file", isVerbose: isVerbose)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.starts(with: "OPENAI_API_KEY=") {
                    verboseLog("Found OPENAI_API_KEY line in .env file", isVerbose: isVerbose)
                    let components = trimmedLine.split(separator: "=", maxSplits: 1)
                    if components.count > 1 {
                        let value = String(components[1])
                        // Remove surrounding quotes if present
                        let trimmedValue = value.trimmingCharacters(in: .init(charactersIn: "\"'"))
                        return trimmedValue
                    }
                }
            }
            
            verboseLog("No OPENAI_API_KEY found in .env file", isVerbose: isVerbose)
        } catch {
            // Failed to read .env file, return nil
            verboseLog("Failed to read .env file: \(error.localizedDescription)", isVerbose: isVerbose)
        }
    } else {
        verboseLog(".env file not found at path: \(envFilePath)", isVerbose: isVerbose)
    }
    
    return nil
}