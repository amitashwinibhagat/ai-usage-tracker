//
//  QwenAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from Alibaba Qwen via DashScope.
//  OpenAI-compatible API.
//

import Foundation

/// Service for fetching Qwen usage data
@MainActor
final class QwenAPIService {
    static let shared = QwenAPIService()
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"

    private init() {}

    func fetchUsage(credentials: QwenCredentials) async throws -> QwenUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(code: .sessionKeyNotFound, message: "Qwen API key not configured", isRecoverable: false)
        }

        let models = try? await fetchModels(apiKey: apiKey)
        guard models?.isEmpty == false else {
            throw AppError(code: .apiUnauthorized, message: "Invalid Qwen API key", isRecoverable: true)
        }

        LoggingService.shared.log("QwenAPIService: Connected. \(models?.count ?? 0) models available.")

        return QwenUsage(
            tokensUsed: 0,
            limit: nil,
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: nil,
            lastUpdated: Date(),
            model: models?.first,
            inputTokens: nil,
            outputTokens: nil,
            requestsCount: nil
        )
    }

    private func fetchModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw AppError(code: .urlMalformed, message: "Invalid Qwen URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid Qwen response", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid Qwen API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "Qwen API error (\(httpResponse.statusCode))", isRecoverable: true)
        }

        struct Response: Codable { struct Model: Codable { let id: String }; let data: [Model] }
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result.data.map { $0.id }
    }
}
