import Foundation

enum OpenAIServiceError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)
    case noChoicesReturned
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for OpenAI API"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noChoicesReturned:
            return "No choices returned from the API"
        }
    }
}

// Models for decoding OpenAI API responses
struct OpenAIResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Decodable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Decodable {
        let role: String
        let content: String
    }
    
    struct Usage: Decodable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// Models for encoding OpenAI API requests
struct OpenAIRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int?
    
    struct Message: Encodable {
        let role: String
        let content: String
    }
}

struct OpenAIService {
    let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o"
    
    func sendMessage(_ text: String, isVerbose: Bool = false) async throws -> String {
        // Parse the conversation history from the text
        let messages = parseConversationToMessages(text)
        return try await sendMessageWithHistory(messages, isVerbose: isVerbose)
    }
    
    private func parseConversationToMessages(_ text: String) -> [OpenAIRequest.Message] {
        // Split the conversation by User: and Assistant: prefixes
        let lines = text.split(separator: "\n\n")
        var messages: [OpenAIRequest.Message] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.starts(with: "User: ") {
                let content = String(trimmedLine.dropFirst(6))
                messages.append(OpenAIRequest.Message(role: "user", content: content))
            } else if trimmedLine.starts(with: "Assistant: ") {
                let content = String(trimmedLine.dropFirst(11))
                messages.append(OpenAIRequest.Message(role: "assistant", content: content))
            }
        }
        
        return messages
    }
    
    func sendMessageWithHistory(_ messages: [OpenAIRequest.Message], isVerbose: Bool = false) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw OpenAIServiceError.invalidURL
        }
        
        verboseLog("Preparing request to OpenAI API", isVerbose: isVerbose)
        
        if isVerbose {
            verboseLog("Sending to OpenAI API endpoint: \(endpoint)", isVerbose: true)
            verboseLog("Using model: \(model)", isVerbose: true)
            verboseLog("Message count: \(messages.count)", isVerbose: true)
            for (index, message) in messages.enumerated() {
                let roleEmoji = message.role == "user" ? "👤" : "🤖"
                verboseLog("\(roleEmoji) Message [\(index)] \(message.role): \(message.content.prefix(50))...", isVerbose: true)
            }
        }
        
        // Create the request body
        let requestBody = OpenAIRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            max_tokens: 1000
        )
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode the request body
        do {
            let encoder = JSONEncoder()
            if isVerbose {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            }
            
            let requestData = try encoder.encode(requestBody)
            request.httpBody = requestData
            
            if isVerbose {
                if let requestJson = String(data: requestData, encoding: .utf8) {
                    verboseLog("Request JSON (first 500 chars):\n\(requestJson.prefix(500))...", isVerbose: true)
                }
            }
        } catch {
            verboseLog("Failed to encode request: \(error)", isVerbose: isVerbose)
            throw OpenAIServiceError.requestFailed(error)
        }
        
        verboseLog("Sending request to OpenAI API endpoint", isVerbose: isVerbose)
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        verboseLog("Received response with status code: \(httpResponse.statusCode)", isVerbose: isVerbose)
        
        // Check for successful status code
        guard 200...299 ~= httpResponse.statusCode else {
            // Try to extract error message from response
            do {
                // Debug output the error response
                if isVerbose {
                    if let errorString = String(data: data, encoding: .utf8) {
                        verboseLog("Error response: \(errorString)", isVerbose: true)
                    }
                }
                
                // Try to decode as OpenAI error format
                struct OpenAIError: Decodable {
                    let error: ErrorDetail
                    
                    struct ErrorDetail: Decodable {
                        let message: String
                        let type: String?
                        let code: String?
                    }
                }
                
                let errorResponse = try JSONDecoder().decode(OpenAIError.self, from: data)
                throw OpenAIServiceError.apiError("\(errorResponse.error.message) (Type: \(errorResponse.error.type ?? "unknown"))")
            } catch let decodingError as OpenAIServiceError {
                // If we already created a proper error, rethrow it
                throw decodingError
            } catch {
                // If we can't decode the error, just use the status code and raw data
                if let errorString = String(data: data, encoding: .utf8)?.prefix(100) {
                    throw OpenAIServiceError.apiError("HTTP status \(httpResponse.statusCode): \(errorString)...")
                } else {
                    throw OpenAIServiceError.apiError("HTTP status code: \(httpResponse.statusCode)")
                }
            }
        }
        
        // Decode the response
        do {
            // Log the raw response for debugging in verbose mode
            if isVerbose {
                if let responseString = String(data: data, encoding: .utf8) {
                    verboseLog("Raw response: \(responseString.prefix(200))...", isVerbose: true)
                }
            }
            
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            // Extract the response text
            guard let firstChoice = decodedResponse.choices.first else {
                throw OpenAIServiceError.noChoicesReturned
            }
            
            verboseLog("Successfully processed response", isVerbose: isVerbose)
            verboseLog("Token usage - Prompt: \(decodedResponse.usage.promptTokens), Completion: \(decodedResponse.usage.completionTokens), Total: \(decodedResponse.usage.totalTokens)", isVerbose: isVerbose)
            
            return firstChoice.message.content
        } catch {
            verboseLog("Failed to decode response: \(error)", isVerbose: isVerbose)
            
            // Try to provide more context about the error
            if let responseString = String(data: data, encoding: .utf8) {
                verboseLog("Response that failed to decode: \(responseString.prefix(200))...", isVerbose: isVerbose)
            }
            
            throw OpenAIServiceError.decodingError(error)
        }
    }
}