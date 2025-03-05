import Foundation

enum ConsoleColor {
    static let black = "\u{001B}[30m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
    static let white = "\u{001B}[37m"
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let underline = "\u{001B}[4m"
}

enum ConsoleUI {
    /// Prints a message with the specified ANSI color code
    static func printColored(_ message: String, colorCode: String) {
        print("\(colorCode)\(message)\(ConsoleColor.reset)")
    }
    
    /// Prints a message with an emoji prefix
    static func printEmoji(_ message: String, emoji: String) {
        print("\(emoji)  \(message)")
    }
    
    /// Prints a success message (green with checkmark)
    static func printSuccess(_ message: String) {
        printColored("✅ \(message)", colorCode: ConsoleColor.green)
    }
    
    /// Prints an error message (red with X)
    static func printError(_ message: String) {
        printColored("❌ \(message)", colorCode: ConsoleColor.red)
    }
    
    /// Prints a warning message (yellow with warning sign)
    static func printWarning(_ message: String) {
        printColored("⚠️ \(message)", colorCode: ConsoleColor.yellow)
    }
    
    /// Prints an info message (blue with info sign)
    static func printInfo(_ message: String) {
        printColored("ℹ️ \(message)", colorCode: ConsoleColor.blue)
    }
}

/// A simple spinner that shows progress in the console
class Spinner {
    private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private var currentFrame = 0
    private var isRunning = false
    private var message: String
    private var timer: Timer?
    private var runLoop: RunLoop?
    private let lock = NSLock()
    
    init(message: String) {
        self.message = message
    }
    
    /// Starts the spinner with the given message
    func start() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isRunning else { return }
        isRunning = true
        
        // Create and start the timer on a background thread
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            self.runLoop = RunLoop.current
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateFrame()
            }
            
            // Keep the run loop running
            self.runLoop?.run()
        }
    }
    
    /// Updates the spinner frame
    private func updateFrame() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isRunning else { return }
        
        // Clear the current line and print the next frame
        print("\r\(frames[currentFrame]) \(message)", terminator: "")
        fflush(stdout)
        
        // Update the frame index
        currentFrame = (currentFrame + 1) % frames.count
    }
    
    /// Stops the spinner and prints the final message
    func stop(finalMessage: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        guard isRunning else { return }
        isRunning = false
        
        // Invalidate the timer
        timer?.invalidate()
        timer = nil
        
        // Clear the current line
        print("\r\u{001B}[K", terminator: "")
        
        // Print the final message if provided
        if let finalMessage = finalMessage {
            print(finalMessage)
        }
        
        // Signal the run loop to exit
        CFRunLoopStop(runLoop?.getCFRunLoop())
    }
    
    /// Stops the spinner with a success message
    func succeed(message: String? = nil) {
        let finalMessage = message ?? "Completed successfully!"
        stop(finalMessage: "\(ConsoleColor.green)✅ \(finalMessage)\(ConsoleColor.reset)")
    }
    
    /// Stops the spinner with an error message
    func fail(message: String? = nil) {
        let finalMessage = message ?? "Failed!"
        stop(finalMessage: "\(ConsoleColor.red)❌ \(finalMessage)\(ConsoleColor.reset)")
    }
    
    /// Stops the spinner with a warning message
    func warn(message: String? = nil) {
        let finalMessage = message ?? "Warning!"
        stop(finalMessage: "\(ConsoleColor.yellow)⚠️ \(finalMessage)\(ConsoleColor.reset)")
    }
}

// Example usage:
//
// let spinner = Spinner(message: "Loading...")
// spinner.start()
// 
// // Do some work...
// // sleep(2)
// 
// spinner.succeed(message: "Loaded successfully!")
//
// // Or for manual control:
// // spinner.stop(finalMessage: "Done!")