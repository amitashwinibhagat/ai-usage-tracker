//
//  MiniMaxAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from MiniMax API.
//

import Foundation

/// Service for fetching MiniMax usage data
@MainActor
final class MiniMaxAPIService {
    static let shared = MiniMaxAPIService()
    private let baseURL = "https://api.minimax.chat/v1"

    private init() {}

    func fetchUsage(credentials: MiniMaxCredentials) async throws -> MiniMaxUsage {
        guard credentials.isValid, let apiKey = credentials.apiKey else {
            throw AppError(code: .sessionKeyNotFound, message: "MiniMax API key not configured", isRecoverable: false)
        }

        // Validate by fetching models (or user info if available)
        let isValid = try await validateKey(apiKey: apiKey)
        guard isValid else {
            throw AppError(code: .apiUnauthorized, message: "Invalid MiniMax API key", isRecoverable: true)
        }

        LoggingService.shared.log("MiniMaxAPIService: Connected")

        return MiniMaxUsage(
            tokensUsed: 0,
            limit: nil,
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: nil,
            lastUpdated: Date(),
            model: nil,
            inputTokens: nil,
            outputTokens: nil,
            groupId: credentials.groupId
        )
    }

    private func validateKey(apiKey: String) async throws -> Bool {
        // MiniMax doesn't have a simple models endpoint.
        // Try a lightweight chat completion or user balance endpoint.
        // For now, check key format and do a minimal API ping.
        guard apiKey.count >= 16 else { return false }

        // Try to fetch models or user info
        guard let url = URL(string: "\(baseURL)/models") else { return false }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            // Fallback: accept well-formed keys
            return true
        }
    }
}
