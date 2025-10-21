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

    private let userDefaults: UserDefaults
    private static let forceSelectionKey = "ForceSelectionEnabled"
    private static let forceSelectionExcludedAppsKey = "ForceSelectionExcludedApps"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        forceSelectionEnabled = userDefaults.object(forKey: Self.forceSelectionKey) as? Bool ?? false
        forceSelectionExcludedApps = userDefaults.object(forKey: Self.forceSelectionExcludedAppsKey) as? [String] ?? []
    }
}
