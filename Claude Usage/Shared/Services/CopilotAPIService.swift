//
//  CopilotAPIService.swift
//  Claude Usage
//
//  Service for fetching GitHub Copilot usage and billing data.
//

import Foundation

/// GitHub user info response
struct GitHubUser: Codable {
    let login: String
    let name: String?
    let email: String?
    let plan: GitHubPlan?
}

struct GitHubPlan: Codable {
    let name: String?
}

/// GitHub org response
struct GitHubOrg: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarUrl = "avatar_url"
    }
}

/// GitHub Copilot billing response
struct CopilotBillingResponse: Codable {
    let seatBreakdown: CopilotSeatBreakdown?
    let publicCodeSuggestions: String?
    let ideChat: String?
    let platformChat: String?

    enum CodingKeys: String, CodingKey {
        case seatBreakdown = "seat_breakdown"
        case publicCodeSuggestions = "public_code_suggestions"
        case ideChat = "ide_chat"
        case platformChat = "platform_chat"
    }
}

struct CopilotSeatBreakdown: Codable {
    let total: Int?
    let addedThisCycle: Int?
    let pendingInvitation: Int?
    let pendingCancellation: Int?

    enum CodingKeys: String, CodingKey {
        case total
        case addedThisCycle = "added_this_cycle"
        case pendingInvitation = "pending_invitation"
        case pendingCancellation = "pending_cancellation"
    }
}

/// GitHub Copilot usage response
struct CopilotUsageResponse: Codable {
    let usage: [CopilotUsageBreakdown]?
}

struct CopilotUsageBreakdown: Codable {
    let day: String?
    let totalSuggestionsCount: Int?
    let totalAcceptancesCount: Int?
    let totalLinesSuggested: Int?
    let totalLinesAccepted: Int?
    let totalActiveUsers: Int?
    let breakdown: [CopilotLanguageBreakdown]?

    enum CodingKeys: String, CodingKey {
        case day, breakdown
        case totalSuggestionsCount = "total_suggestions_count"
        case totalAcceptancesCount = "total_acceptances_count"
        case totalLinesSuggested = "total_lines_suggested"
        case totalLinesAccepted = "total_lines_accepted"
        case totalActiveUsers = "total_active_users"
    }
}

struct CopilotLanguageBreakdown: Codable {
    let language: String?
    let editor: String?
    let suggestionsCount: Int?
    let acceptancesCount: Int?

    enum CodingKeys: String, CodingKey {
        case language, editor
        case suggestionsCount = "suggestions_count"
        case acceptancesCount = "acceptances_count"
    }
}

/// Service for fetching GitHub Copilot usage data
@MainActor
final class CopilotAPIService {
    static let shared = CopilotAPIService()

    private let baseURL = "https://api.github.com"

    private init() {}

    // MARK: - Public API

    /// Fetches usage data from GitHub Copilot API
    func fetchUsage(credentials: CopilotCredentials) async throws -> CopilotUsage {
        guard credentials.isValid, let token = credentials.accessToken else {
            throw AppError(
                code: .sessionKeyNotFound,
                message: "GitHub access token not configured",
                isRecoverable: false
            )
        }

        // Step 1: Validate token and get user info
        let user = try await fetchUser(token: token)
        LoggingService.shared.log("CopilotAPIService: Authenticated as \(user.login)")

        // Step 2: Fetch user's orgs
        let orgs = try? await fetchOrgs(token: token)

        // Step 3: Try org-level Copilot data
        var totalSuggestions: Int?
        var totalAcceptances: Int?
        var seatCount: Int?
        var planType: CopilotPlanType = .individual

        if let orgs = orgs, let firstOrg = orgs.first {
            do {
                let billing = try await fetchOrgBilling(token: token, org: firstOrg.login)
                seatCount = billing.seatBreakdown?.total
                if (seatCount ?? 0) > 1 {
                    planType = .business
                }
                LoggingService.shared.log("CopilotAPIService: Org '\(firstOrg.login)' has \(seatCount ?? 0) seats")
            } catch {
                LoggingService.shared.log("CopilotAPIService: Org billing unavailable (not admin): \(error.localizedDescription)")
            }

            // Try usage endpoint
            do {
                let usage = try await fetchOrgUsage(token: token, org: firstOrg.login)
                totalSuggestions = usage.usage?.reduce(0) { $0 + ($1.totalSuggestionsCount ?? 0) }
                totalAcceptances = usage.usage?.reduce(0) { $0 + ($1.totalAcceptancesCount ?? 0) }
                LoggingService.shared.log("CopilotAPIService: Usage fetched: \(totalSuggestions ?? 0) suggestions, \(totalAcceptances ?? 0) acceptances")
            } catch {
                LoggingService.shared.log("CopilotAPIService: Org usage unavailable: \(error.localizedDescription)")
            }
        }

        // Step 4: Determine plan from user info
        if let planName = user.plan?.name?.lowercased() {
            if planName.contains("enterprise") {
                planType = .enterprise
            } else if planName.contains("business") || planName.contains("team") {
                planType = .business
            } else if planName.contains("free") {
                planType = .free
            }
        }

        return CopilotUsage(
            tokensUsed: totalSuggestions ?? 0,
            limit: nil,
            usagePercentage: 0,
            resetTime: nil,
            estimatedCost: planType.monthlyCost * Double(seatCount ?? 1),
            lastUpdated: Date(),
            suggestionsAccepted: totalAcceptances,
            suggestionsShown: totalSuggestions,
            linesGenerated: nil,
            activeUsers: seatCount,
            seatCount: seatCount ?? 1,
            planType: planType
        )
    }

    /// Validates a GitHub access token
    func validateToken(_ token: String) async -> Bool {
        do {
            _ = try await fetchUser(token: token)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private API Calls

    /// Fetches authenticated user info
    private func fetchUser(token: String) async throws -> GitHubUser {
        guard let url = URL(string: "\(baseURL)/user") else {
            throw AppError(code: .urlMalformed, message: "Invalid GitHub API URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid GitHub response", isRecoverable: true)
        }

        if httpResponse.statusCode == 401 {
            throw AppError(code: .apiUnauthorized, message: "Invalid GitHub token", isRecoverable: true)
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "GitHub API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    /// Fetches user's organizations
    private func fetchOrgs(token: String) async throws -> [GitHubOrg] {
        guard let url = URL(string: "\(baseURL)/user/orgs?per_page=100") else {
            throw AppError(code: .urlMalformed, message: "Invalid GitHub orgs URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        return try JSONDecoder().decode([GitHubOrg].self, from: data)
    }

    /// Fetches Copilot billing for an organization
    private func fetchOrgBilling(token: String, org: String) async throws -> CopilotBillingResponse {
        guard let url = URL(string: "\(baseURL)/orgs/\(org)/copilot/billing") else {
            throw AppError(code: .urlMalformed, message: "Invalid Copilot billing URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid Copilot billing response", isRecoverable: true)
        }

        if httpResponse.statusCode == 403 || httpResponse.statusCode == 404 {
            throw AppError(
                code: .apiForbidden,
                message: "Copilot billing requires org admin access",
                isRecoverable: true
            )
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "Copilot billing API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        return try JSONDecoder().decode(CopilotBillingResponse.self, from: data)
    }

    /// Fetches Copilot usage for an organization
    private func fetchOrgUsage(token: String, org: String) async throws -> CopilotUsageResponse {
        let now = Date()
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 86400)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let since = formatter.string(from: thirtyDaysAgo)
        let until = formatter.string(from: now)

        guard let url = URL(string: "\(baseURL)/orgs/\(org)/copilot/usage?since=\(since)&until=\(until)") else {
            throw AppError(code: .urlMalformed, message: "Invalid Copilot usage URL", isRecoverable: false)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError(code: .apiInvalidResponse, message: "Invalid Copilot usage response", isRecoverable: true)
        }

        if httpResponse.statusCode == 403 || httpResponse.statusCode == 404 {
            throw AppError(
                code: .apiForbidden,
                message: "Copilot usage requires org admin access",
                isRecoverable: true
            )
        }

        guard httpResponse.statusCode == 200 else {
            throw AppError(
                code: .apiGenericError,
                message: "Copilot usage API error (\(httpResponse.statusCode))",
                isRecoverable: true
            )
        }

        return try JSONDecoder().decode(CopilotUsageResponse.self, from: data)
    }
}
