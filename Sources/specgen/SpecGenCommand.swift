import ArgumentParser
import Foundation

struct SpecGenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "specgen",
        abstract: "Generate detailed specifications from user ideas using OpenAI"
    )
    
    @Flag(name: .shortAndLong, help: "Show verbose logging")
    var verbose = false
    
    @Option(name: .shortAndLong, help: "Path to a file containing your idea")
    var ideaFile: String?

    func run() throws {
        // Print verbose flag status when it's enabled
        if verbose {
            print("🔊 Verbose logging enabled")
        }
        
        // Create a Task to execute our async code
        let semaphore = DispatchSemaphore(value: 0)
        var taskError: Error?
        
        Task {
            do {
                try await runAsync()
            } catch {
                taskError = error
            }
            semaphore.signal()
        }
        
        // Wait for the async task to complete
        semaphore.wait()
        
        // If there was an error, throw it
        if let error = taskError {
            throw error
        }
    }
    
    func runAsync() async throws {
        ConsoleUI.printEmoji("Welcome to SpecGen", emoji: "🚀")
        verboseLog("SpecGen started!", isVerbose: verbose)
        
        // Check for API key with a spinner
        let spinner = Spinner(message: "Checking for OpenAI API key...")
        spinner.start()
        
        // Simulate a brief delay to show the spinner
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let apiKey = getApiKey(isVerbose: verbose) else {
            spinner.fail(message: "API key not found")
            ConsoleUI.printError("OpenAI API key not found")
            ConsoleUI.printInfo("Please set the OPENAI_API_KEY environment variable or add it to a .env file.")
            throw ExitCode.failure
        }
        
        spinner.succeed(message: "API key found")
        
        verboseLog("API key found with length: \(apiKey.count)", isVerbose: verbose)
        
        // Initialize the OpenAI service with the API key
        let openAIService = OpenAIService(apiKey: apiKey)
        
        // Print welcome banner
        print("")
        ConsoleUI.printColored("Welcome to specgen! 💡💻", colorCode: ConsoleColor.cyan + ConsoleColor.bold)
        print("")
        
        // Get user's idea from file or prompt for it
        var userIdea: String
        
        if let ideaFilePath = ideaFile {
            let fileSpinner = Spinner(message: "Reading idea from file...")
            fileSpinner.start()
            
            do {
                let fileURL = URL(fileURLWithPath: ideaFilePath)
                userIdea = try String(contentsOf: fileURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if userIdea.isEmpty {
                    fileSpinner.fail(message: "Empty idea file")
                    ConsoleUI.printError("Idea file is empty. Exiting.")
                    throw ExitCode.failure
                }
                
                fileSpinner.succeed(message: "Idea loaded from file")
                verboseLog("Idea loaded from file: \(ideaFilePath)", isVerbose: verbose)
                ConsoleUI.printInfo("Using idea from file: \(ideaFilePath)")
                ConsoleUI.printColored("Idea: \(userIdea)", colorCode: ConsoleColor.cyan)
                print("")
            } catch {
                fileSpinner.fail(message: "Failed to read idea file")
                ConsoleUI.printError("Failed to read idea file: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        } else {
            // Prompt for user's idea
            ConsoleUI.printColored("Enter your idea:", colorCode: ConsoleColor.green)
            print("> ", terminator: "")
            
            guard let input = readLine(), !input.isEmpty else {
                ConsoleUI.printError("No idea provided. Exiting.")
                throw ExitCode.failure
            }
            
            userIdea = input
        }
        
        // Form the initial prompt
        let initialPrompt = """
        Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. \
        Each question should build on my previous answers, and our end goal is to have a detailed \
        specification I can hand off to a developer. Let's do this iteratively and dig into every \
        relevant detail. Remember, only one question at a time. Here's the idea: \(userIdea)
        """
        
        // Create an array to store the conversation history
        var messages: [(role: String, content: String)] = [
            (role: "user", content: initialPrompt)
        ]
        
        // Main conversation loop
        var questionCount = 0
        
        while true {
            questionCount += 1
            
            // Show a spinner while waiting for the AI response
            let questionSpinner = Spinner(message: "Thinking about question #\(questionCount)...")
            questionSpinner.start()
            
            do {
                // Call the OpenAI service
                verboseLog("Sending message to OpenAI API", isVerbose: verbose)
                
                // Convert messages array to a single prompt for simplicity in this implementation
                let prompt = formatMessagesForPrompt(messages)
                
                // Send the prompt to OpenAI API
                verboseLog("Sending conversation with \(messages.count) messages to OpenAI", isVerbose: verbose)
                let response = try await openAIService.sendMessage(prompt, isVerbose: verbose)
                
                // Add the response to the message history
                messages.append((role: "assistant", content: response))
                
                // Stop the spinner and display the question
                questionSpinner.succeed(message: "Question #\(questionCount) ready")
                print("")
                ConsoleUI.printEmoji("Question #\(questionCount):", emoji: "🤔")
                ConsoleUI.printColored(response, colorCode: ConsoleColor.yellow)
                print("")
                
                // Prompt for the user's answer
                ConsoleUI.printColored("💬 Answer (or /finish to generate spec)", colorCode: ConsoleColor.green + ConsoleColor.bold)
                print("> ", terminator: "")
                
                guard let userAnswer = readLine() else {
                    ConsoleUI.printError("Failed to read input. Exiting.")
                    throw ExitCode.failure
                }
                
                // Check if the user wants to finish
                if userAnswer.lowercased() == "/finish" {
                    verboseLog("User requested to finish the conversation", isVerbose: verbose)
                    break
                }
                
                // Add the user's answer to the message history
                messages.append((role: "user", content: userAnswer))
                
            } catch {
                questionSpinner.fail(message: "Failed to get response")
                ConsoleUI.printError("Failed to communicate with OpenAI: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }
        
        ConsoleUI.printSuccess("Generating final specification...")
        
        // Create a spinner for the final spec generation
        let finalSpecSpinner = Spinner(message: "Compiling your specification document...")
        finalSpecSpinner.start()
        
        // Add the final prompt to the conversation
        let finalPrompt = "Now that we've wrapped up the brainstorming process, can you compile our findings into a comprehensive, developer-ready specification?"
        messages.append((role: "user", content: finalPrompt))
        
        do {
            // Send the final request to generate the spec
            verboseLog("Sending final request to generate specification", isVerbose: verbose)
            let formattedPrompt = formatMessagesForPrompt(messages)
            let specContent = try await openAIService.sendMessage(formattedPrompt, isVerbose: verbose)
            
            // Generate a timestamped filename
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "spec-\(timestamp).md"
            
            // Write the specification to a file
            verboseLog("Writing specification to file: \(fileName)", isVerbose: verbose)
            let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(fileName)
            
            do {
                try specContent.write(to: fileURL, atomically: true, encoding: .utf8)
                finalSpecSpinner.succeed(message: "Specification successfully generated!")
                
                // Print success message
                print("")
                ConsoleUI.printSuccess("✨ Specification saved to: \(fileName)")
                ConsoleUI.printEmoji("Thank you for using SpecGen! Your developer-ready spec is complete.", emoji: "🚀")
            } catch {
                finalSpecSpinner.fail(message: "Failed to save specification file")
                ConsoleUI.printError("Failed to write specification to file: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        } catch {
            finalSpecSpinner.fail(message: "Failed to generate specification")
            ConsoleUI.printError("Failed to generate final specification: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
    
    /// Formats the conversation history into a single prompt string
    /// This creates a text format that our OpenAIService can parse into proper message objects
    private func formatMessagesForPrompt(_ messages: [(role: String, content: String)]) -> String {
        var formattedPrompt = ""
        
        for (index, message) in messages.enumerated() {
            let prefix = message.role == "user" ? "User: " : "Assistant: "
            formattedPrompt += prefix + message.content
            
            // Add a newline between messages, but not after the last one
            if index < messages.count - 1 {
                formattedPrompt += "\n\n"
            }
        }
        
        verboseLog("Formatted conversation has \(messages.count) messages", isVerbose: verbose)
        return formattedPrompt
    }
}