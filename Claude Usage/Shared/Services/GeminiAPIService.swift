//
//  GeminiAPIService.swift
//  Claude Usage
//
//  Service for fetching usage from Google Gemini / AI Studio / Cloud.
//

import Foundation

/// Response from Google AI Studio models endpoint
struct GeminiModelsResponse: Codable {
    let models: [GeminiModel]
}

struct GeminiModel: Codable {
    let name: String
    let version: String?
    let displayName: String?
    let description: String?
    let inputTokenLimit: Int?
    let outputTokenLimit: Int?

    enum CodingKeys: String, CodingKey {
        case name, version, description
        case displayName = "display_name"
        case inputTokenLimit = "input_token_limit"
        case outputTokenLimit = "output_token_limit"
    }
}

/// Response from Google Cloud Monitoring time series
struct CloudMonitoringResponse: Codable {
    let timeSeries: [TimeSeries]?

    enum CodingKeys: String, CodingKey {
        case timeSeries = "timeSeries"
    }
}

struct TimeSeries: Codable {
    let metric: Metric?
    let points: [DataPoint]?
}

struct Metric: Codable {
    let type: String?
    let labels: [String: String]?
}

struct DataPoint: Codable {
    let interval: MonitoringTimeInterval?
    let value: MetricValue?
}

struct MonitoringTimeInterval: Codable {
    let startTime: String?
    let endTime: String?

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct MetricValue: Codable {
    let int64Value: String?
    let doubleValue: Double?

    enum CodingKeys: String, CodingKey {
        case int64Value = "int64_value"
        case doubleValue = "double_value"
    }
}

/// Service for fetching Google Gemini usage data
@MainActor
final class GeminiAPIService {
    static let shared = GeminiAPIService()

    private let geminiBaseURL = "https://generativelanguage.googleapis.com"
    private let monitoringBaseURL = "https://monitoring.googleapis.com"

    private init() {}

    // MARK: - Public API

    /// Fetches usage data from Google Gemini API
    func fetchUsage(credentials: GeminiCredentials) async throws -> GeminiUsage {
        guard credentials.isValid else {
            throw AppError(
                code: .sessionKeyNotFound,
                message: "Gemini credentials not configured",
                isRecoverable: false
            )
        }

        // Determine auth method: OAuth token takes priority for Cloud Monitoring
        let effectiveToken = credentials.oauthAccessToken ?? credentials.apiKey
        let isOAuth = credentials.oauthAccessToken != nil

        // Step 1: Validate by fetching models (requires API key; OAuth doesn't work for AI Studio models endpoint)
        var models: [GeminiModel]?
        if let apiKey = credentials.apiKey {
            models = try? await fetchModels(apiKey: apiKey)
        }

        // Step 2: If project ID provided or OAuth connected, try Cloud Monitoring for usage metrics
        var requestCount: Int?
        var tokenCount: Int?

        if let projectId = credentials.projectId {
            if isOAuth, let oauthToken = credentials.oauthAccessToken {
                do {
                    let metrics = try await fetchCloudMonitoringMetricsOAuth(token: oauthToken, projectId: projectId)
                    requestCount = metrics.requestCount
                    tokenCount = metrics.tokenCount
                    LoggingService.shared.log("GeminiAPIService: Cloud metrics fetched via OAuth: \(requestCount ?? 0) requests, \(tokenCount ?? 0) tokens")
                } catch {
                    LoggingService.shared.log("GeminiAPIService: Cloud Monitoring OAuth unavailable: \(error.localizedDescription)")
                }
            } else if let apiKey = credentials.apiKey {
                do {
                    let metrics = try await fetchCloudMonitoringMetrics(apiKey: apiKey, projectId: projectId)
                    requestCount = metrics.requestCount
                    tokenCount = metrics.tokenCount
                    LoggingService.shared.log("GeminiAPIService: Cloud metrics fetched via API key: \(requestCount ?? 0) requests, \(tokenCount ?? 0) tokens")
                } catch {
                    LoggingService.shared.log("GeminiAPIService: Cloud Monitoring unavailable: \(error.localizedDescription)")
                }
            }
        }

        // Step 3: Estimate if on free tier (generous free tier is common)
        let isFreeTier = requestCount == nil || (requestCount ?? 0) < 1500 // ~1500 requests/day on free tier

        return GeminiUsage(
            tokensUsed: tokenCount ?? 0,
            limit: isFreeTier ? nil : nil, // No hard limit on paid tier
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: nil, // Would need Cloud Billing API
            lastUpdated: Date(),
            requestsCount: requestCount,
            inputTokens: nil,
            outputTokens: nil,
            model: models?.first?.displayName ?? models?.first?.name,
            freeTierRemaining: isFreeTier ? max(1500 - (requestCount ?? 0), 0) : nil,
            isFreeTier: isFreeTier
        )
    }

    /// Validates a Gemini API key
    func validateKey(_ apiKey: String) async -> Bool {
        do {
            let models = try await fetchModels(apiKey: apiKey)
            return !models.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Private API Calls

    /// Fetches available models from AI Studio
    func fetchModels(apiKey: String) async throws -> [GeminiModel] {
        guard let url = URL(string: "\(geminiBaseURL)/v1beta/models?key=\(apiKey)") else {
            throw AppError(code: .urlMalformed, message: "Invalid Gemini API URL", isRecoverable: false)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid Gemini response", isRecoverable: true)
        }

        if httpResponse.statusCode == 400 {
            throw AppError(code: .apiUnauthorized, message: "Invalid Gemini API key", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "Gemini API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        let result = try JSONDecoder().decode(GeminiModelsResponse.self, from: data)
        return result.models
    }

    /// Fetches usage metrics from Google Cloud Monitoring
    private func fetchCloudMonitoringMetrics(apiKey: String, projectId: String) async throws -> (requestCount: Int, tokenCount: Int) {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let startTime = formatter.string(from: yesterday)
        let endTime = formatter.string(from: now)

        // Try to fetch prediction request count
        let requestFilter = "metric.type=%22aiplatform.googleapis.com%2Fprediction%2Fonline%2Frequests%22"
        let requestURL = "\(monitoringBaseURL)/v3/projects/\(projectId)/timeSeries?filter=\(requestFilter)&interval.start_time=\(startTime)&interval.end_time=\(endTime)&key=\(apiKey)"

        let requestCount = await fetchMetricCount(from: requestURL)

        // Try to fetch token count
        let tokenFilter = "metric.type=%22aiplatform.googleapis.com%2Fprediction%2Fonline%2Fcharacters%22"
        let tokenURLString = "\(monitoringBaseURL)/v3/projects/\(projectId)/timeSeries?filter=\(tokenFilter)&interval.start_time=\(startTime)&interval.end_time=\(endTime)&key=\(apiKey)"
        let tokenCount = await fetchMetricCount(from: tokenURLString)

        return (requestCount, tokenCount)
    }

    /// Fetches usage metrics from Google Cloud Monitoring using OAuth Bearer token
    private func fetchCloudMonitoringMetricsOAuth(token: String, projectId: String) async throws -> (requestCount: Int, tokenCount: Int) {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let startTime = formatter.string(from: yesterday)
        let endTime = formatter.string(from: now)

        let requestFilter = "metric.type=%22aiplatform.googleapis.com%2Fprediction%2Fonline%2Frequests%22"
        let requestURL = "\(monitoringBaseURL)/v3/projects/\(projectId)/timeSeries?filter=\(requestFilter)&interval.start_time=\(startTime)&interval.end_time=\(endTime)"

        let requestCount = await fetchMetricCountOAuth(from: requestURL, token: token)

        let tokenFilter = "metric.type=%22aiplatform.googleapis.com%2Fprediction%2Fonline%2Fcharacters%22"
        let tokenURLString = "\(monitoringBaseURL)/v3/projects/\(projectId)/timeSeries?filter=\(tokenFilter)&interval.start_time=\(startTime)&interval.end_time=\(endTime)"
        let tokenCount = await fetchMetricCountOAuth(from: tokenURLString, token: token)

        return (requestCount, tokenCount)
    }

    private func fetchMetricCountOAuth(from urlString: String, token: String) async -> Int {
        guard let url = URL(string: urlString) else { return 0 }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return 0
            }
            let result = try JSONDecoder().decode(CloudMonitoringResponse.self, from: data)
            return sumMetrics(from: result)
        } catch {
            LoggingService.shared.log("GeminiAPIService: Cloud Monitoring OAuth metric failed: \(error.localizedDescription)")
            return 0
        }
    }

    private func fetchMetricCount(from urlString: String) async -> Int {
        guard let url = URL(string: urlString) else { return 0 }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return 0
            }
            let result = try JSONDecoder().decode(CloudMonitoringResponse.self, from: data)
            return sumMetrics(from: result)
        } catch {
            LoggingService.shared.log("GeminiAPIService: Cloud Monitoring metric failed: \(error.localizedDescription)")
            return 0
        }
    }

    private func sumMetrics(from response: CloudMonitoringResponse) -> Int {
        guard let series = response.timeSeries else { return 0 }
        var total = 0
        for s in series {
            guard let points = s.points else { continue }
            for point in points {
                let value = Int(point.value?.int64Value ?? "0") ?? 0
                total += value
            }
        }
        return total
    }
}
