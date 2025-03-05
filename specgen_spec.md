# Specification for `specgen` CLI Application

## Overview
`specgen` is an interactive command-line application designed to iteratively generate detailed, developer-ready specifications by interacting with OpenAI's GPT-4o LLM. The tool emphasizes a friendly, visually appealing user experience with extensive use of ANSI colors and emojis.

## Technical Requirements

### Development Environment
- Language: Swift
- Build System: Swift Package Manager (SPM)
- Dependency Limitations: Minimal third-party dependencies
- Networking: Direct URLSession calls using async/await
- Logging: OSLog with support for verbose logging (`--verbose`)
- CLI argument parsing should use ArgumentParser as a SPM dependency

### OpenAI Integration
- Model: GPT-4o
- API Key Management:
  - Environment variable (`OPENAI_API_KEY`)
  - `.env` file in current working directory (minimal/no dependencies for parsing)

## Application Workflow

### Launch and Prompt
- Display introductory message with ANSI colors and emojis:
  ```ansi
  Welcome to specgen! 💡💻
  ```
- Immediately prompt user:
  ```ansi
  Enter your idea:
  >
  ```

### Interaction Loop
- Send initial prompt to OpenAI API to begin iterative question cycle:
  ```
  "Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question should build on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer. Let’s do this iteratively and dig into every relevant detail. Remember, only one question at a time. Here's the idea: <User Idea>"
  ```

- Display questions from LLM with clear formatting:
  ```ansi
  🤖 [1;34mQuestion:[0m <LLM-generated question>
  ```

- User prompt after each question:
  ```ansi
  💬 [1;32mAnswer (or /finish to generate spec)[0m
  >
  ```

### Spinner/Loading Indicator
- Display spinner on separate line:
  ```ansi
  ⣾ 🤖 Thinking...
  ```
- Spinner should overwrite and clear when completed.

### Completion Command `/finish`
- Upon entering `/finish`, send summarizing prompt:
  ```
  "Now that we’ve wrapped up the brainstorming process, can you compile our findings into a comprehensive, developer-ready specification? Include all relevant requirements, architecture choices, data handling details, error handling strategies, and a testing plan so a developer can immediately begin implementation."
  ```
- Display unique spinner during final spec generation:
  ```ansi
  ⣾ 🚀 Generating spec...
  ```

### Spec File Generation
- Filename: `spec-<YYYYMMDD-HHMMSS>.md` (timestamped)
- Save spec file and display success message:
  ```ansi
  ✅ 🎉 Specification generated successfully! Saved to spec-<YYYYMMDD-HHMMSS>.md
  ```
- Application exits gracefully after displaying message.

## Error Handling

### General Errors
- Display friendly, colorful, emoji-enhanced messages matching app aesthetic.

### Network/API Errors
- Clearly display error message and API response details.
- Allow retry by pre-populating the prompt with previous user input (user simply hits return to retry).

### Missing API Key
- Gracefully exit with clear error:
  ```ansi
  ❌ 🔑 Error: Missing OpenAI API key. Please set the OPENAI_API_KEY environment variable or provide a .env file.
  ```

## Verbose Logging
- Activated via `--verbose` flag:
  ```
  specgen --verbose
  ```
- Includes detailed logs:
  - Network requests and responses (including sensitive info)
  - Internal function logs

## Implementation Notes
- No third-party dependency unless strictly required (attempt `.env` parsing manually first).
- ANSI escape codes used directly for all colors and formatting.

This specification provides a clear roadmap for immediate developer implementation.

