//
//  PermissionManager.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa
import ApplicationServices

/// 权限类型枚举
/// Permission type enumeration
enum PermissionType {
    case accessibility
    case screenRecording
}

/// 权限管理器
/// Permission manager
/// 负责检查和请求必要的系统权限
/// Responsible for checking and requesting necessary system permissions
class PermissionManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = PermissionManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 检查所有必要的权限
    /// Check all necessary permissions
    func checkPermissions() {
        checkAccessibilityPermission()
        checkScreenRecordingPermission()
    }
    
    /// 检查辅助功能权限
    /// Check accessibility permission
    /// - Returns: 是否已授权 / Whether authorized
    @discardableResult
    func checkAccessibilityPermission() -> Bool {
        let accessEnabled = AXIsProcessTrusted()
        return accessEnabled
    }
    
    /// 检查屏幕录制权限
    /// Check screen recording permission
    /// - Returns: 是否已授权 / Whether authorized
    @discardableResult
    func checkScreenRecordingPermission() -> Bool {
        // 在 macOS 10.15+ 上，获取屏幕内容需要屏幕录制权限
        // On macOS 10.15+, screen content access requires screen recording permission
        if #available(macOS 10.15, *) {
            // 尝试获取屏幕内容来检测权限
            // Try to get screen content to detect permission
            let hasPermission = CGPreflightScreenCaptureAccess()
            return hasPermission
        }
        
        return true
    }
    
    /// 打开系统偏好设置
    /// Open system preferences
    /// - Parameter type: 权限类型 / Permission type
    func openSystemPreferences(for type: PermissionType) {
        let urlString: String
        
        switch type {
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
