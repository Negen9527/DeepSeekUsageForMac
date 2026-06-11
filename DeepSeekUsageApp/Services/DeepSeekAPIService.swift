import Foundation

// MARK: - Response Models

/// Response from GET /api/v0/usage/amount
struct UsageAmountResponse: Codable {
    let data: UsageAmountData?
    let error: String?

    struct UsageAmountData: Codable {
        let totalTokens: Int?
        let promptTokens: Int?
        let completionTokens: Int?
        let totalRequests: Int?

        enum CodingKeys: String, CodingKey {
            case totalTokens = "total_tokens"
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalRequests = "total_requests"
        }
    }
}

/// Response from GET /api/v0/usage/cost
struct UsageCostResponse: Codable {
    let data: UsageCostData?
    let error: String?

    struct UsageCostData: Codable {
        let totalCost: Double?

        enum CodingKeys: String, CodingKey {
            case totalCost = "total_cost"
        }
    }
}

// MARK: - Aggregated Usage

struct UsageData {
    let promptTokens: Int
    let completionTokens: Int
    let totalRequests: Int
    let totalCost: Double

    var totalTokens: Int { promptTokens + completionTokens }
}

// MARK: - API Service

final class DeepSeekAPIService {
    private let session: URLSession
    private let token: String
    private let baseURL = "https://platform.deepseek.com/api/v0"

    init(token: String) {
        self.token = token
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// Fetch combined usage data for a given month/year.
    func fetchUsage(month: Int, year: Int) async throws -> UsageData {
        async let amountTask = fetchAmount(month: month, year: year)
        async let costTask = fetchCost(month: month, year: year)

        let (prompt, completion, requests) = try await amountTask
        let cost = try await costTask

        return UsageData(
            promptTokens: prompt,
            completionTokens: completion,
            totalRequests: requests,
            totalCost: cost
        )
    }

    /// Validate the token by making a test request to the current month.
    func validateToken() async throws -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        _ = try await fetchAmount(month: month, year: year)
        return true
    }

    // MARK: - Private

    private func fetchAmount(month: Int, year: Int) async throws -> (Int, Int, Int) {
        let url = URL(string: "\(baseURL)/usage/amount?month=\(month)&year=\(year)")!
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(UsageAmountResponse.self, from: data)
            if let error = decoded.error, !error.isEmpty {
                throw APIError.serverMessage(error)
            }
            return (
                decoded.data?.promptTokens ?? 0,
                decoded.data?.completionTokens ?? 0,
                decoded.data?.totalRequests ?? 0
            )
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func fetchCost(month: Int, year: Int) async throws -> Double {
        let url = URL(string: "\(baseURL)/usage/cost?month=\(month)&year=\(year)")!
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(UsageCostResponse.self, from: data)
            if let error = decoded.error, !error.isEmpty {
                throw APIError.serverMessage(error)
            }
            return decoded.data?.totalCost ?? 0
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await session.data(for: request)
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(statusCode: Int)
    case serverMessage(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Token 无效，请检查后重新输入"
        case .rateLimited: return "请求过于频繁，请稍后再试"
        case .serverError(let code): return "服务器错误 (status: \(code))"
        case .serverMessage(let msg): return msg
        case .networkError(let error): return "网络错误: \(error.localizedDescription)"
        }
    }
}
