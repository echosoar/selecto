//
//  AppState.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import SwiftUI

/// 应用主题枚举
/// Application theme enum
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

/// 应用全局状态
/// Application global state
final class AppState: ObservableObject {
    static let shared = AppState()
    
    /// 当前主题
    /// Current theme
    @Published var theme: AppTheme = .system
}
