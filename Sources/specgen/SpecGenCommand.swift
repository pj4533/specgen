import ArgumentParser

struct SpecGenCommand: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Show verbose logging")
    var verbose = false

    func run() throws {
        print("Argument parsing works! Verbose? \(verbose)")
        verboseLog("SpecGen started!", isVerbose: verbose)
    }
}