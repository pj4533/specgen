import ArgumentParser
import Foundation

struct SpecGenCommand: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Show verbose logging")
    var verbose = false

    func run() throws {
        print("SpecGen: OpenAI code generation tool")
        verboseLog("SpecGen started!", isVerbose: verbose)
        
        guard let apiKey = getApiKey(isVerbose: verbose) else {
            // ANSI color codes: Red text
            let redColorCode = "\u{001B}[31m"
            let resetColorCode = "\u{001B}[0m"
            let boldCode = "\u{001B}[1m"
            
            print("\(redColorCode)\(boldCode)Error: OpenAI API key not found\(resetColorCode)")
            print("Please set the OPENAI_API_KEY environment variable or add it to a .env file.")
            throw ExitCode.failure
        }
        
        verboseLog("API key found with length: \(apiKey.count)", isVerbose: verbose)
        print("API key found. Ready to generate code.")
    }
}