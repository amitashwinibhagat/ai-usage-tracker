//
//  KimiAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from Moonshot AI Kimi API.
//  OpenAI-compatible API.
//

import Foundation

/// Service for fetching Kimi usage data
@MainActor
final class KimiAPIService {
    static let shared = KimiAPIService()
    private let baseURL = "https://api.moonshot.cn/v1"

    private init() {}

    func fetchUsage(credentials: KimiCredentials) async throws -> KimiUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(code: .sessionKeyNotFound, message: "Kimi API key not configured", isRecoverable: false)
        }

        let models = try? await fetchModels(apiKey: apiKey)
        guard models?.isEmpty == false else {
            throw AppError(code: .apiUnauthorized, message: "Invalid Kimi API key", isRecoverable: true)
        }

        LoggingService.shared.log("KimiAPIService: Connected. \(models?.count ?? 0) models available.")

        return KimiUsage(
            tokensUsed: 0,
            limit: nil,
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: nil,
            lastUpdated: Date(),
            model: models?.first,
            inputTokens: nil,
            outputTokens: nil,
            balance: nil
        )
    }

    func fetchModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw AppError(code: .urlMalformed, message: "Invalid Kimi URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid Kimi response", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid Kimi API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "Kimi API error (\(httpResponse.statusCode))", isRecoverable: true)
        }

        struct Response: Codable { struct Model: Codable { let id: String }; let data: [Model] }
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result.data.map { $0.id }
    }
}
