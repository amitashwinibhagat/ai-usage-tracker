//
//  DeepSeekAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from DeepSeek API.
//  OpenAI-compatible API.
//

import Foundation

/// Service for fetching DeepSeek usage data
@MainActor
final class DeepSeekAPIService {
    static let shared = DeepSeekAPIService()
    private let baseURL = "https://api.deepseek.com/v1"

    private init() {}

    func fetchUsage(credentials: DeepSeekCredentials) async throws -> DeepSeekUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(code: .sessionKeyNotFound, message: "DeepSeek API key not configured", isRecoverable: false)
        }

        let models = try? await fetchModels(apiKey: apiKey)
        guard models?.isEmpty == false else {
            throw AppError(code: .apiUnauthorized, message: "Invalid DeepSeek API key", isRecoverable: true)
        }

        // Try to fetch user balance
        var balance: Double?
        do {
            balance = try await fetchUserBalance(apiKey: apiKey)
        } catch {
            LoggingService.shared.log("DeepSeekAPIService: Balance fetch failed: \(error.localizedDescription)")
        }

        LoggingService.shared.log("DeepSeekAPIService: Connected. \(models?.count ?? 0) models. Balance: $\(String(describing: balance))")

        return DeepSeekUsage(
            tokensUsed: 0,
            limit: nil,
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: nil,
            lastUpdated: Date(),
            model: models?.first,
            inputTokens: nil,
            outputTokens: nil,
            balance: balance
        )
    }

    private func fetchModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw AppError(code: .urlMalformed, message: "Invalid DeepSeek URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid DeepSeek response", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid DeepSeek API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "DeepSeek API error (\(httpResponse.statusCode))", isRecoverable: true)
        }

        struct Response: Codable { struct Model: Codable { let id: String }; let data: [Model] }
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result.data.map { $0.id }
    }

    private func fetchUserBalance(apiKey: String) async throws -> Double {
        guard let url = URL(string: "https://api.deepseek.com/user/balance") else {
            throw AppError(code: .urlMalformed, message: "Invalid DeepSeek balance URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "Balance fetch failed", isRecoverable: true)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let info = json["balance_infos"] as? [[String: Any]],
           let first = info.first,
           let total = first["total_balance"] as? String {
            return Double(total) ?? 0
        }

        return 0
    }
}
