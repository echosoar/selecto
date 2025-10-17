//
//  PermissionManager.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa
import ApplicationServices

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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showAccessibilityAlert()
            }
        }
        
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
            
            if !hasPermission {
                // 请求权限
                // Request permission
                CGRequestScreenCaptureAccess()
            }
            
            return hasPermission
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// 显示辅助功能权限提示
    /// Show accessibility permission alert
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限 (Accessibility Permission Required)"
        alert.informativeText = """
        Selecto 需要辅助功能权限才能监控文本选择。
        
        请前往：
        系统偏好设置 -> 安全性与隐私 -> 隐私 -> 辅助功能
        
        然后勾选 Selecto。
        
        ---
        
        Selecto requires accessibility permission to monitor text selection.
        
        Please go to:
        System Preferences -> Security & Privacy -> Privacy -> Accessibility
        
        Then check Selecto.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统偏好设置 (Open System Preferences)")
        alert.addButton(withTitle: "稍后 (Later)")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }
    
    /// 打开系统偏好设置
    /// Open system preferences
    private func openSystemPreferences() {
        // 打开辅助功能设置页面
        // Open accessibility settings page
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
