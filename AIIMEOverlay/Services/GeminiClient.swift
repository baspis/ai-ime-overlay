import Foundation

struct GeminiClient {
    private let session: URLSession

    private static let systemInstruction = """
    あなたは日本語 IME です。ローマ字入力を自然な日本語（漢字かな交じり）に変換してください。\
    説明や引用符は付けず、変換結果の文字列のみを返してください。
    """

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
            throw GeminiClientError.emptyInput
        }

        let modelID = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !modelID.isEmpty else {
            throw GeminiClientError.apiError("Model name is empty.")
        }

        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelID):generateContent"
        )!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let maxTokens = min(256, max(64, trimmed.count * 4))
        let body = GenerateContentRequest(
            systemInstruction: .init(parts: [.init(text: Self.systemInstruction)]),
            contents: [
                .init(role: "user", parts: [.init(text: trimmed)]),
            ],
            generationConfig: .init(
                temperature: 0.2,
                maxOutputTokens: maxTokens,
                thinkingConfig: modelID.contains("3.1") ? .init(thinkingBudget: 0) : nil
            )
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiClientError.invalidResponse
        }

        if http.statusCode == 429 {
            throw GeminiClientError.rateLimited
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let message = parseAPIErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw GeminiClientError.apiError(message)
        }

        let decoded = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        guard let raw = decoded.candidates?.first?.content?.parts?
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty
        else {
            throw GeminiClientError.emptyResult
        }
        return stripWrappingQuotes(raw)
    }

    private func parseAPIErrorMessage(from data: Data) -> String? {
        struct APIErrorEnvelope: Decodable {
            struct APIError: Decodable {
                let message: String?
                let status: String?
            }
            let error: APIError
        }
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
            return envelope.error.message ?? envelope.error.status
        }
        return String(data: data, encoding: .utf8)
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

enum GeminiClientError: LocalizedError {
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
            return "Invalid response from Gemini."
        case .rateLimited:
            return "Rate limited. Wait a moment and try again."
        case .apiError(let message):
            return message
        case .missingAPIKey:
            return "Set your Gemini API key in Settings."
        }
    }
}

private struct GenerateContentRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String
        }
        let role: String
        let parts: [Part]
    }

    struct SystemInstruction: Encodable {
        struct Part: Encodable {
            let text: String
        }
        let parts: [Part]
    }

    struct GenerationConfig: Encodable {
        struct ThinkingConfig: Encodable {
            let thinkingBudget: Int
        }
        let temperature: Double
        let maxOutputTokens: Int
        let thinkingConfig: ThinkingConfig?
    }

    let systemInstruction: SystemInstruction
    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct GenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}
