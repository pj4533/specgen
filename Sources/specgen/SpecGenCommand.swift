import ArgumentParser
import Foundation

struct SpecGenCommand: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Show verbose logging")
    var verbose = false

    func run() throws {
        ConsoleUI.printEmoji("Welcome to SpecGen", emoji: "🚀")
        verboseLog("SpecGen started!", isVerbose: verbose)
        
        // Check for API key with a spinner
        let spinner = Spinner(message: "Checking for OpenAI API key...")
        spinner.start()
        
        // Simulate a brief delay to show the spinner
        Thread.sleep(forTimeInterval: 0.5)
        
        guard let apiKey = getApiKey(isVerbose: verbose) else {
            spinner.fail(message: "API key not found")
            ConsoleUI.printError("OpenAI API key not found")
            ConsoleUI.printInfo("Please set the OPENAI_API_KEY environment variable or add it to a .env file.")
            throw ExitCode.failure
        }
        
        spinner.succeed(message: "API key found")
        
        verboseLog("API key found with length: \(apiKey.count)", isVerbose: verbose)
        ConsoleUI.printInfo("Ready to generate code")
        
        // Example of different UI elements
        if verbose {
            ConsoleUI.printSuccess("Verbose mode enabled")
            ConsoleUI.printWarning("This is a warning example")
            ConsoleUI.printColored("This is cyan text", colorCode: ConsoleColor.cyan)
            ConsoleUI.printColored("This is bold magenta text", colorCode: ConsoleColor.bold + ConsoleColor.magenta)
        }
    }
}