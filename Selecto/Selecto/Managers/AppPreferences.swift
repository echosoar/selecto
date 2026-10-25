//
//  AppPreferences.swift
//  Selecto
//
//  Created by GitHub Copilot on 2025/10/19.
//

import Foundation
import Combine

/// 应用偏好设置管理器
/// Application preferences manager backed by UserDefaults
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    /// 是否启用强制选词
    /// Whether forced selection fallback is enabled
    @Published var forceSelectionEnabled: Bool {
        didSet {
            if oldValue != forceSelectionEnabled {
                userDefaults.set(forceSelectionEnabled, forKey: Self.forceSelectionKey)
            }
        }
    }

    /// 强制选词排除的应用列表（Bundle ID）
    /// List of excluded applications (Bundle IDs) for forced selection
    @Published var forceSelectionExcludedApps: [String] {
        didSet {
            if oldValue != forceSelectionExcludedApps {
                userDefaults.set(forceSelectionExcludedApps, forKey: Self.forceSelectionExcludedAppsKey)
            }
        }
    }

    /// 是否启用双击选择支持
    /// Whether double-click selection support is enabled
    @Published var doubleClickSelectionEnabled: Bool {
        didSet {
            if oldValue != doubleClickSelectionEnabled {
                userDefaults.set(doubleClickSelectionEnabled, forKey: Self.doubleClickSelectionKey)
            }
        }
    }

    /// 是否启用 HTTP 代理
    /// Whether HTTP proxy is enabled
    @Published var httpProxyEnabled: Bool {
        didSet { userDefaults.set(httpProxyEnabled, forKey: Self.httpProxyEnabledKey) }
    }

    /// HTTP 代理地址
    /// HTTP proxy address
    @Published var httpProxyAddress: String {
        didSet { userDefaults.set(httpProxyAddress, forKey: Self.httpProxyAddressKey) }
    }

    /// 是否启用 HTTPS 代理
    /// Whether HTTPS proxy is enabled
    @Published var httpsProxyEnabled: Bool {
        didSet { userDefaults.set(httpsProxyEnabled, forKey: Self.httpsProxyEnabledKey) }
    }

    /// HTTPS 代理地址
    /// HTTPS proxy address
    @Published var httpsProxyAddress: String {
        didSet { userDefaults.set(httpsProxyAddress, forKey: Self.httpsProxyAddressKey) }
    }

    private let userDefaults: UserDefaults
    private static let httpProxyEnabledKey = "HTTPProxyEnabled"
    private static let httpProxyAddressKey = "HTTPProxyAddress"
    private static let httpsProxyEnabledKey = "HTTPSProxyEnabled"
    private static let httpsProxyAddressKey = "HTTPSProxyAddress"
    private static let forceSelectionKey = "ForceSelectionEnabled"
    private static let forceSelectionExcludedAppsKey = "ForceSelectionExcludedApps"
    private static let doubleClickSelectionKey = "DoubleClickSelectionEnabled"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        forceSelectionEnabled = userDefaults.object(forKey: Self.forceSelectionKey) as? Bool ?? false
        forceSelectionExcludedApps = userDefaults.object(forKey: Self.forceSelectionExcludedAppsKey) as? [String] ?? []
        doubleClickSelectionEnabled = userDefaults.object(forKey: Self.doubleClickSelectionKey) as? Bool ?? false
        httpProxyEnabled = userDefaults.bool(forKey: Self.httpProxyEnabledKey)
        httpProxyAddress = userDefaults.string(forKey: Self.httpProxyAddressKey) ?? ""
        httpsProxyEnabled = userDefaults.bool(forKey: Self.httpsProxyEnabledKey)
        httpsProxyAddress = userDefaults.string(forKey: Self.httpsProxyAddressKey) ?? ""
    }
}
