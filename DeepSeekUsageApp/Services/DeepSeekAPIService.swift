import Foundation

// MARK: - Response Models

struct ModelUsageItem {
    let model: String
    let usage: [UsageTypeEntry]
}

struct UsageTypeEntry {
    let type: String
    let amount: String
}

// MARK: - Per-model breakdown

struct ModelUsageBreakdown: Codable {
    let model: String
    let promptTokens: Int
    let completionTokens: Int
    let requests: Int
    let cost: Double
}

// MARK: - Balance

struct BalanceInfo {
    let normalBalance: Double
    let bonusBalance: Double
    let totalTokensEstimation: Int
    let monthlyCost: Double
}

// MARK: - Daily data

struct DailyUsagePoint {
    let date: String       // "2026-06-01"
    let tokens: Int
    let requests: Int
    let cost: Double

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return date }
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: d)
    }
}

// MARK: - Aggregated Usage

struct UsageData {
    let promptTokens: Int
    let completionTokens: Int
    let totalRequests: Int
    let totalCost: Double
    let modelBreakdown: [ModelUsageBreakdown]
    let balance: BalanceInfo?
    let dailyPoints: [DailyUsagePoint]

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
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36",
            "Accept-Language": "zh-CN,zh;q=0.9",
        ]
        self.session = URLSession(configuration: config)
    }

    /// Fetch combined usage data for a given month/year.
    func fetchUsage(month: Int, year: Int) async throws -> UsageData {
        async let amountTask = fetchAmountWithDays(month: month, year: year)
        async let costTask = fetchCostWithDays(month: month, year: year)
        async let balanceTask = fetchUserSummary()

        let (models, amountDays) = try await amountTask
        let (costs, costDays) = try await costTask
        let balance = try? await balanceTask

        // Build model breakdown by merging amount and cost data
        var breakdowns: [ModelUsageBreakdown] = []
        var totalPrompt = 0
        var totalCompletion = 0
        var totalRequests = 0
        var totalCost = 0.0

        for modelUsage in models {
            let model = modelUsage.model
            var prompt = 0
            var completion = 0
            var requests = 0

            for entry in modelUsage.usage {
                switch entry.type {
                case "PROMPT_TOKEN", "PROMPT_CACHE_HIT_TOKEN", "PROMPT_CACHE_MISS_TOKEN":
                    prompt += Int(entry.amount) ?? 0
                case "RESPONSE_TOKEN":
                    completion += Int(entry.amount) ?? 0
                case "REQUEST":
                    requests += Int(entry.amount) ?? 0
                default:
                    break
                }
            }

            let cost = costs.first(where: { $0.model == model })?.cost ?? 0

            breakdowns.append(ModelUsageBreakdown(
                model: model,
                promptTokens: prompt,
                completionTokens: completion,
                requests: requests,
                cost: cost
            ))

            totalPrompt += prompt
            totalCompletion += completion
            totalRequests += requests
            totalCost += cost
        }

        // Merge daily data from amount and cost APIs
        var dailyMap: [String: DailyUsagePoint] = [:]
        for dayEntry in amountDays {
            let date = dayEntry.date
            var tokens = 0
            var requests = 0
            for modelUsage in dayEntry.data {
                for entry in modelUsage.usage {
                    switch entry.type {
                    case "PROMPT_TOKEN", "PROMPT_CACHE_HIT_TOKEN", "PROMPT_CACHE_MISS_TOKEN", "RESPONSE_TOKEN":
                        tokens += Int(entry.amount) ?? 0
                    case "REQUEST":
                        requests += Int(entry.amount) ?? 0
                    default: break
                    }
                }
            }
            dailyMap[date] = DailyUsagePoint(date: date, tokens: tokens, requests: requests, cost: 0)
        }
        for dayEntry in costDays {
            let date = dayEntry.date
            var cost = 0.0
            for modelUsage in dayEntry.data {
                for entry in modelUsage.usage {
                    if entry.type != "REQUEST", let amount = Double(entry.amount) {
                        cost += amount
                    }
                }
            }
            if var existing = dailyMap[date] {
                existing = DailyUsagePoint(date: date, tokens: existing.tokens, requests: existing.requests, cost: cost)
                dailyMap[date] = existing
            } else {
                dailyMap[date] = DailyUsagePoint(date: date, tokens: 0, requests: 0, cost: cost)
            }
        }
        let dailyPoints = dailyMap.values.sorted { $0.date < $1.date }

        return UsageData(
            promptTokens: totalPrompt,
            completionTokens: totalCompletion,
            totalRequests: totalRequests,
            totalCost: totalCost,
            modelBreakdown: breakdowns,
            balance: balance,
            dailyPoints: dailyPoints
        )
    }

    /// Fetch user summary including balance.
    func fetchUserSummary() async throws -> BalanceInfo {
        let url = URL(string: "\(baseURL)/users/get_user_summary")!
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json,
                  let code = json["code"] as? Int else {
                throw APIError.invalidResponse
            }
            if code != 0 {
                let msg = json["msg"] as? String ?? "Unknown error"
                throw APIError.serverMessage(msg)
            }
            guard let dataDict = json["data"] as? [String: Any],
                  let bizData = dataDict["biz_data"] as? [String: Any] else {
                throw APIError.invalidResponse
            }

            let normalWallets = bizData["normal_wallets"] as? [[String: Any]] ?? []
            let bonusWallets = bizData["bonus_wallets"] as? [[String: Any]] ?? []
            let monthlyCosts = bizData["monthly_costs"] as? [[String: Any]] ?? []
            let tokenEstimation = Int(bizData["total_available_token_estimation"] as? String ?? "0") ?? 0

            let normalBalance = normalWallets.first.flatMap { Double($0["balance"] as? String ?? "") } ?? 0
            let bonusBalance = bonusWallets.first.flatMap { Double($0["balance"] as? String ?? "") } ?? 0
            let monthlyCost = monthlyCosts.first.flatMap { Double($0["amount"] as? String ?? "") } ?? 0

            return BalanceInfo(
                normalBalance: normalBalance,
                bonusBalance: bonusBalance,
                totalTokensEstimation: tokenEstimation,
                monthlyCost: monthlyCost
            )
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
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

    private struct ModelCost {
        let model: String
        let cost: Double
    }

    private struct DayUsageData {
        let date: String
        let data: [ModelUsageItem]
    }

    private func fetchAmountWithDays(month: Int, year: Int) async throws -> ([ModelUsageItem], [DayUsageData]) {
        let url = URL(string: "\(baseURL)/usage/amount?month=\(month)&year=\(year)")!
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json,
                  let code = json["code"] as? Int else {
                throw APIError.invalidResponse
            }
            if code != 0 {
                let msg = json["msg"] as? String ?? "Unknown error"
                throw APIError.serverMessage(msg)
            }
            guard let dataDict = json["data"] as? [String: Any],
                  let bizData = dataDict["biz_data"] as? [String: Any],
                  let total = bizData["total"] as? [[String: Any]] else {
                return ([], [])
            }

            // Parse total
            var items: [ModelUsageItem] = []
            for modelEntry in total {
                guard let model = modelEntry["model"] as? String,
                      let usageArr = modelEntry["usage"] as? [[String: Any]] else { continue }
                let entries = usageArr.compactMap { entry -> UsageTypeEntry? in
                    guard let type = entry["type"] as? String,
                          let amount = entry["amount"] as? String else { return nil }
                    return UsageTypeEntry(type: type, amount: amount)
                }
                items.append(ModelUsageItem(model: model, usage: entries))
            }

            // Parse days
            var days: [DayUsageData] = []
            if let daysArr = bizData["days"] as? [[String: Any]] {
                for dayEntry in daysArr {
                    guard let date = dayEntry["date"] as? String,
                          let dataArr = dayEntry["data"] as? [[String: Any]] else { continue }
                    var dayModels: [ModelUsageItem] = []
                    for modelEntry in dataArr {
                        guard let model = modelEntry["model"] as? String,
                              let usageArr = modelEntry["usage"] as? [[String: Any]] else { continue }
                        let entries = usageArr.compactMap { entry -> UsageTypeEntry? in
                            guard let type = entry["type"] as? String,
                                  let amount = entry["amount"] as? String else { return nil }
                            return UsageTypeEntry(type: type, amount: amount)
                        }
                        dayModels.append(ModelUsageItem(model: model, usage: entries))
                    }
                    days.append(DayUsageData(date: date, data: dayModels))
                }
            }

            return (items, days)
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func fetchCostWithDays(month: Int, year: Int) async throws -> ([ModelCost], [DayUsageData]) {
        let url = URL(string: "\(baseURL)/usage/cost?month=\(month)&year=\(year)")!
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json,
                  let code = json["code"] as? Int else {
                throw APIError.invalidResponse
            }
            if code != 0 {
                let msg = json["msg"] as? String ?? "Unknown error"
                throw APIError.serverMessage(msg)
            }
            guard let dataDict = json["data"] as? [String: Any],
                  let bizData = dataDict["biz_data"] as? [[String: Any]] else {
                return ([], [])
            }

            var costs: [ModelCost] = []
            var days: [DayUsageData] = []

            for group in bizData {
                // Parse total
                if let total = group["total"] as? [[String: Any]] {
                    for modelEntry in total {
                        guard let model = modelEntry["model"] as? String,
                              let usageArr = modelEntry["usage"] as? [[String: Any]] else { continue }
                        var modelCost = 0.0
                        for entry in usageArr {
                            if let type = entry["type"] as? String,
                               type != "REQUEST",
                               let amountStr = entry["amount"] as? String,
                               let amount = Double(amountStr) {
                                modelCost += amount
                            }
                        }
                        costs.append(ModelCost(model: model, cost: modelCost))
                    }
                }

                // Parse days
                if let daysArr = group["days"] as? [[String: Any]] {
                    for dayEntry in daysArr {
                        guard let date = dayEntry["date"] as? String,
                              let dataArr = dayEntry["data"] as? [[String: Any]] else { continue }
                        var dayModels: [ModelUsageItem] = []
                        for modelEntry in dataArr {
                            guard let model = modelEntry["model"] as? String,
                                  let usageArr = modelEntry["usage"] as? [[String: Any]] else { continue }
                            let entries = usageArr.compactMap { entry -> UsageTypeEntry? in
                                guard let type = entry["type"] as? String,
                                      let amount = entry["amount"] as? String else { return nil }
                                return UsageTypeEntry(type: type, amount: amount)
                            }
                            dayModels.append(ModelUsageItem(model: model, usage: entries))
                        }
                        days.append(DayUsageData(date: date, data: dayModels))
                    }
                }
            }
            return (costs, days)
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func fetchAmount(month: Int, year: Int) async throws -> [ModelUsageItem] {
        let (result, _) = try await fetchAmountWithDays(month: month, year: year)
        return result
    }

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("1.0.0", forHTTPHeaderField: "x-app-version")
        request.setValue("https://platform.deepseek.com/usage", forHTTPHeaderField: "Referer")
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
