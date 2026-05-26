//
//  GLMAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from Zhipu AI GLM API.
//  OpenAI-compatible API.
//

import Foundation

/// Service for fetching GLM usage data
@MainActor
final class GLMAPIService {
    static let shared = GLMAPIService()
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4"

    private init() {}

    func fetchUsage(credentials: GLMCredentials) async throws -> GLMUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(code: .sessionKeyNotFound, message: "GLM API key not configured", isRecoverable: false)
        }

        let models = try? await fetchModels(apiKey: apiKey)
        guard models?.isEmpty == false else {
            throw AppError(code: .apiUnauthorized, message: "Invalid GLM API key", isRecoverable: true)
        }

        LoggingService.shared.log("GLMAPIService: Connected. \(models?.count ?? 0) models available.")

        return GLMUsage(
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

    private func fetchModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw AppError(code: .urlMalformed, message: "Invalid GLM URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid GLM response", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid GLM API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(code: .apiGenericError, message: "GLM API error (\(httpResponse.statusCode))", isRecoverable: true)
        }

        struct Response: Codable { struct Model: Codable { let id: String }; let data: [Model] }
        let result = try JSONDecoder().decode(Response.self, from: data)
        return result.data.map { $0.id }
    }
}
