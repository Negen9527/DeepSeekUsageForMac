import Foundation

final class DeepSeekAPIService {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func fetchBalance() async throws -> BalanceInfo {
        let url = URL(string: "https://api.deepseek.com/user/balance")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let balanceResponse = try decoder.decode(BalanceResponse.self, from: data)
            return BalanceInfo(from: balanceResponse)
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    /// Validate the API key by making a test request
    func validateAPIKey() async throws -> Bool {
        _ = try await fetchBalance()
        return true
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Invalid API key. Please check and re-enter."
        case .rateLimited: return "Too many requests. Please try again later."
        case .serverError(let code): return "Server error (status: \(code))"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}
