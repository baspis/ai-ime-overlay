import Foundation

struct OpenAIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func convertRomaji(
        _ romaji: String,
        apiKey: String,
        model: String
    ) async throws -> String {
        let trimmed = romaji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OpenAIClientError.emptyInput
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let maxTokens = min(256, max(64, trimmed.count * 4))
        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(
                    role: "system",
                    content: """
                    あなたは日本語 IME です。ローマ字入力を自然な日本語（漢字かな交じり）に変換してください。\
                    説明や引用符は付けず、変換結果の文字列のみを返してください。
                    """
                ),
                .init(role: "user", content: trimmed),
            ],
            temperature: 0.2,
            max_tokens: maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }

        if http.statusCode == 429 {
            throw OpenAIClientError.rateLimited
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let message = parseAPIErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw OpenAIClientError.apiError(message)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !content.isEmpty
        else {
            throw OpenAIClientError.emptyResult
        }
        return stripWrappingQuotes(content)
    }

    private func parseAPIErrorMessage(from data: Data) -> String? {
        struct APIErrorEnvelope: Decodable {
            struct APIError: Decodable {
                let message: String
            }
            let error: APIError
        }
        return (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data))?.error.message
    }

    private func stripWrappingQuotes(_ text: String) -> String {
        var result = text
        let pairs: [(Character, Character)] = [("\"", "\""), ("「", "」"), ("『", "』")]
        for (open, close) in pairs {
            if result.count >= 2, result.first == open, result.last == close {
                result = String(result.dropFirst().dropLast())
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum OpenAIClientError: LocalizedError {
    case emptyInput
    case emptyResult
    case invalidResponse
    case rateLimited
    case apiError(String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter romaji before converting."
        case .emptyResult:
            return "The model returned an empty result."
        case .invalidResponse:
            return "Invalid response from OpenAI."
        case .rateLimited:
            return "Rate limited. Wait a moment and try again."
        case .apiError(let message):
            return message
        case .missingAPIKey:
            return "Set your OpenAI API key in Settings."
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}
