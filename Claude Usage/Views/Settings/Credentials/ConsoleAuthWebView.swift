//
//  ConsoleAuthWebView.swift
//  Claude Usage
//
//  Created by Claude Code on 2026-03-01.
//

import SwiftUI
import WebKit

// MARK: - Cookie Result

struct ConsoleCookieResult {
    let sessionKey: String
    let expiryDate: Date?
}

// MARK: - WKWebView Wrapper

struct ConsoleAuthWebView: NSViewRepresentable {
    let loginURL: URL
    let cookieDomains: [String]
    let onCookieFound: (ConsoleCookieResult) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.parentWebView = webView
        context.coordinator.startObservingCookies(for: config.websiteDataStore)

        // Clear auth cookies to prevent auto-login with stale session.
        // Google cookies are preserved so SSO popup works.
        let cookieStore = config.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            let group = DispatchGroup()
            for cookie in cookies where cookie.domain.contains("claude") || cookie.domain.contains("anthropic") {
                group.enter()
                cookieStore.delete(cookie) { group.leave() }
            }
            group.notify(queue: .main) {
                webView.load(URLRequest(url: self.loginURL))
            }
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(cookieDomains: cookieDomains, onCookieFound: onCookieFound)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKHTTPCookieStoreObserver {
        let cookieDomains: [String]
        let onCookieFound: (ConsoleCookieResult) -> Void
        private var foundCookie = false
        weak var parentWebView: WKWebView?
        private var popupWindow: NSWindow?
        private var popupWebView: WKWebView?

        init(cookieDomains: [String], onCookieFound: @escaping (ConsoleCookieResult) -> Void) {
            self.cookieDomains = cookieDomains
            self.onCookieFound = onCookieFound
        }

        func startObservingCookies(for dataStore: WKWebsiteDataStore) {
            dataStore.httpCookieStore.add(self)
        }

        // WKHTTPCookieStoreObserver — fires whenever any cookie changes
        func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            guard !foundCookie else { return }
            cookieStore.getAllCookies { [weak self] cookies in
                guard let self = self, !self.foundCookie else { return }
                for cookie in cookies {
                    if self.isTargetSessionCookie(cookie) {
                        self.foundCookie = true
                        let result = ConsoleCookieResult(
                            sessionKey: cookie.value,
                            expiryDate: cookie.expiresDate
                        )
                        self.clearProviderCookies(from: cookieStore) {
                            DispatchQueue.main.async {
                                self.onCookieFound(result)
                            }
                        }
                        return
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !foundCookie else { return }
            checkForSessionCookie(in: webView)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Create a real popup WKWebView using the provided configuration
            // (preserves window.opener linkage and shared cookies for Google SSO)
            let popup = WKWebView(
                frame: CGRect(x: 0, y: 0, width: 500, height: 600),
                configuration: configuration
            )
            popup.navigationDelegate = self
            popup.uiDelegate = self

            let panel = NSPanel(
                contentRect: CGRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            panel.contentView = popup
            panel.title = "Sign In"
            panel.center()
            panel.makeKeyAndOrderFront(nil)

            self.popupWindow = panel
            self.popupWebView = popup

            return popup
        }

        // Handle window.close() from Google SSO popup after auth completes
        func webViewDidClose(_ webView: WKWebView) {
            if webView === popupWebView {
                popupWindow?.close()
                popupWindow = nil
                popupWebView = nil
            }
        }

        private func checkForSessionCookie(in webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self = self, !self.foundCookie else { return }

                for cookie in cookies {
                    if self.isTargetSessionCookie(cookie) {
                        self.foundCookie = true
                        let result = ConsoleCookieResult(
                            sessionKey: cookie.value,
                            expiryDate: cookie.expiresDate
                        )
                        self.clearProviderCookies(from: webView.configuration.websiteDataStore.httpCookieStore) {
                            DispatchQueue.main.async {
                                self.onCookieFound(result)
                            }
                        }
                        return
                    }
                }
            }
        }

        private func isTargetSessionCookie(_ cookie: HTTPCookie) -> Bool {
            cookie.name == "sessionKey" && cookieDomains.contains { cookie.domain.contains($0) }
        }

        private func clearProviderCookies(from cookieStore: WKHTTPCookieStore, completion: @escaping () -> Void) {
            cookieStore.getAllCookies { cookies in
                let group = DispatchGroup()
                for cookie in cookies where cookie.domain.contains("claude") || cookie.domain.contains("anthropic") {
                    group.enter()
                    cookieStore.delete(cookie) { group.leave() }
                }
                group.notify(queue: .main, execute: completion)
            }
        }
    }
}

// MARK: - Auth Sheet

struct ConsoleAuthSheet: View {
    let title: String
    let loginURL: URL
    let cookieDomains: [String]
    let onSuccess: (ConsoleCookieResult) -> Void
    let onCancel: () -> Void

    @State private var isLoading = true
    @State private var hasError = false

    init(
        title: String,
        loginURL: URL,
        cookieDomain: String,
        onSuccess: @escaping (ConsoleCookieResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.init(
            title: title,
            loginURL: loginURL,
            cookieDomains: [cookieDomain],
            onSuccess: onSuccess,
            onCancel: onCancel
        )
    }

    init(
        title: String,
        loginURL: URL,
        cookieDomains: [String],
        onSuccess: @escaping (ConsoleCookieResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.loginURL = loginURL
        self.cookieDomains = cookieDomains
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .font(AppTheme.Typography.smallSemibold)
                    .foregroundColor(AppTheme.Colors.success)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(AppTheme.Colors.success.opacity(0.12)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTheme.Typography.label)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Sign in in this embedded browser. The app captures the session cookie needed for local usage tracking, then clears Claude/Anthropic cookies from this browser view.")
                        .font(AppTheme.Typography.tiny)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("common.cancel".localized) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.card)

            Divider()
                .overlay(AppTheme.Colors.divider)

            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "key.fill")
                    .font(AppTheme.Typography.tinySemibold)
                    .foregroundColor(AppTheme.Colors.accentHover)

                Text("The captured credential is stored locally for the selected profile and can be removed anytime.")
                    .font(AppTheme.Typography.tiny)
                    .foregroundColor(AppTheme.Colors.textMuted)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundDeep)

            ConsoleAuthWebView(loginURL: loginURL, cookieDomains: cookieDomains) { result in
                onSuccess(result)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.Colors.background)
        .frame(width: 520, height: 680)
    }
}
