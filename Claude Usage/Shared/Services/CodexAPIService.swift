//
//  CodexAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from OpenAI API.
//  Supports billing usage, credit grants, and model list validation.
//

import Foundation

/// Response from OpenAI billing usage endpoint
struct OpenAIBillingUsage: Codable {
    let object: String
    let dailyCosts: [OpenAIDailyCost]?
    let totalUsage: Double? // in cents

    enum CodingKeys: String, CodingKey {
        case object
        case dailyCosts = "daily_costs"
        case totalUsage = "total_usage"
    }
}

struct OpenAIDailyCost: Codable {
    let timestamp: TimeInterval
    let lineItems: [OpenAILineItem]?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case lineItems = "line_items"
    }
}

struct OpenAILineItem: Codable {
    let name: String
    let cost: Double // in cents
}

/// Response from OpenAI credit grants endpoint
struct OpenAICreditGrants: Codable {
    let object: String
    let totalAvailable: Double?
    let totalUsed: Double?
    let grants: OpenAIGrantData?

    enum CodingKeys: String, CodingKey {
        case object
        case totalAvailable = "total_available"
        case totalUsed = "total_used"
        case grants
    }
}

struct OpenAIGrantData: Codable {
    let object: String
    let data: [OpenAIGrantItem]?
}

struct OpenAIGrantItem: Codable {
    let object: String
    let id: String
    let amount: Double
    let usedAmount: Double?

    enum CodingKeys: String, CodingKey {
        case object, id, amount
        case usedAmount = "used_amount"
    }
}

/// Service for fetching OpenAI Codex/API usage data
@MainActor
final class CodexAPIService {
    static let shared = CodexAPIService()

    private let baseURL = "https://api.openai.com"

    private init() {}

    // MARK: - Public API

    /// Fetches usage data from OpenAI API
    func fetchUsage(credentials: CodexCredentials) async throws -> CodexUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(
                code: .sessionKeyNotFound,
                message: "OpenAI API key not configured",
                isRecoverable: false
            )
        }

        // Step 1: Validate key by fetching models
        let models = try? await fetchModels(apiKey: apiKey)
        guard models?.isEmpty == false else {
            throw AppError(
                code: .apiUnauthorized,
                message: "Invalid OpenAI API key",
                isRecoverable: true
            )
        }

        // Step 2: Try to fetch billing usage for current month
        var totalUsageCents: Double?

        do {
            let billing = try await fetchBillingUsage(apiKey: apiKey)
            totalUsageCents = billing.totalUsage
            LoggingService.shared.log("CodexAPIService: Billing usage fetched: $\(String(format: "%.2f", (totalUsageCents ?? 0) / 100))")
        } catch {
            LoggingService.shared.log("CodexAPIService: Billing usage unavailable (expected for non-admin keys): \(error.localizedDescription)")
        }

        // Step 3: Try to fetch credit grants
        var totalCredits: Double?
        do {
            let credits = try? await fetchCreditGrants(apiKey: apiKey)
            totalCredits = credits?.totalAvailable
        }

        // Step 4: Try to fetch organization usage (requires org admin)
        var orgUsageTokens: Int?
        do {
            let orgUsage = try? await fetchOrganizationUsage(apiKey: apiKey)
            orgUsageTokens = orgUsage
        }

        // Build usage response from available data
        let estimatedCost = totalUsageCents.map { $0 / 100.0 }
        let tokensUsed = orgUsageTokens ?? 0

        return CodexUsage(
            tokensUsed: tokensUsed,
            limit: totalCredits.map { Int($0) },
            usagePercentage: 0, // Can't calculate without hard limit
            resetTime: nil,
            estimatedCost: estimatedCost,
            lastUpdated: Date(),
            sessionsCount: nil,
            completionsAccepted: nil,
            completionsSuggested: nil,
            inputTokens: nil,
            outputTokens: nil,
            model: models?.first
        )
    }

    /// Validates an OpenAI API key
    func validateKey(_ apiKey: String) async -> Bool {
        do {
            let models = try await fetchModels(apiKey: apiKey)
            return !models.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Private API Calls

    /// Fetches available models (validates key)
    func fetchModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/v1/models") else {
            throw AppError(code: .urlMalformed, message: "Invalid OpenAI API URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid response from OpenAI", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid OpenAI API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "OpenAI API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        let decoder = JSONDecoder()
        struct ModelsResponse: Codable {
            struct Model: Codable { let id: String }
            let data: [Model]
        }

        let result = try decoder.decode(ModelsResponse.self, from: data)
        return result.data.map { $0.id }
    }

    /// Fetches billing usage for current month
    private func fetchBillingUsage(apiKey: String) async throws -> OpenAIBillingUsage {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.string(from: startOfMonth)
        let endDate = formatter.string(from: now)

        guard let url = URL(string: "\(baseURL)/v1/dashboard/billing/usage?start_date=\(startDate)&end_date=\(endDate)") else {
            throw AppError(code: .urlMalformed, message: "Invalid billing URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid billing response", isRecoverable: true)
        }

        if httpResponse.statusCode == 403 {
            throw AppError(
                code: .apiForbidden,
                message: "Billing access denied. Requires Organization Admin role.",
                isRecoverable: true,
                recoverySuggestion: "Use an admin API key or request billing access from your org owner."
            )
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "Billing API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        return try JSONDecoder().decode(OpenAIBillingUsage.self, from: data)
    }

    /// Fetches credit grants
    private func fetchCreditGrants(apiKey: String) async throws -> OpenAICreditGrants {
        guard let url = URL(string: "\(baseURL)/v1/dashboard/billing/credit_grants") else {
            throw AppError(code: .urlMalformed, message: "Invalid credit grants URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "Credit grants unavailable", isRecoverable: true)
        }

        return try JSONDecoder().decode(OpenAICreditGrants.self, from: data)
    }

    /// Fetches organization-level usage (requires org admin)
    private func fetchOrganizationUsage(apiKey: String) async throws -> Int {
        // Try the organization usage endpoint
        guard let url = URL(string: "\(baseURL)/v1/organization/usage/completions?start_time=\(Int(Date().addingTimeInterval(-86400).timeIntervalSince1970))&end_time=\(Int(Date().timeIntervalSince1970))&bucket_width=1d") else {
            throw AppError(code: .urlMalformed, message: "Invalid org usage URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid org usage response", isRecoverable: true)
        }

        if httpResponse.statusCode == 403 || httpResponse.statusCode == 404 {
            throw AppError(
                code: .apiForbidden,
                message: "Organization usage requires admin access",
                isRecoverable: true
            )
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "Org usage API error", isRecoverable: true)
        }

        // Parse total tokens from response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let buckets = json["data"] as? [[String: Any]] {
            let totalTokens = buckets.compactMap { $0["input_tokens"] as? Int }.reduce(0, +)
            return totalTokens
        }

        return 0
    }
}
