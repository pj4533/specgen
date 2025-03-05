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
        guard let url = URL(string: endpoint) else {
            throw OpenAIServiceError.invalidURL
        }
        
        verboseLog("Preparing request to OpenAI API", isVerbose: isVerbose)
        
        // Create the request body
        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIRequest.Message(role: "user", content: text)
            ],
            temperature: 0.7
        )
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode the request body
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            verboseLog("Failed to encode request: \(error)", isVerbose: isVerbose)
            throw OpenAIServiceError.requestFailed(error)
        }
        
        verboseLog("Sending request to OpenAI API", isVerbose: isVerbose)
        
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
                let errorResponse = try JSONDecoder().decode([String: String].self, from: data)
                if let errorMessage = errorResponse["error"] {
                    throw OpenAIServiceError.apiError(errorMessage)
                }
            } catch {
                // If we can't decode the error, just use the status code
                throw OpenAIServiceError.apiError("HTTP status code: \(httpResponse.statusCode)")
            }
            throw OpenAIServiceError.apiError("HTTP status code: \(httpResponse.statusCode)")
        }
        
        // Decode the response
        do {
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            // Extract the response text
            guard let firstChoice = decodedResponse.choices.first else {
                throw OpenAIServiceError.noChoicesReturned
            }
            
            verboseLog("Successfully processed response", isVerbose: isVerbose)
            return firstChoice.message.content
        } catch {
            verboseLog("Failed to decode response: \(error)", isVerbose: isVerbose)
            throw OpenAIServiceError.decodingError(error)
        }
    }
}