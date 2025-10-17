//
//  AppDelegate.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa

/// 应用程序主代理类
/// Main application delegate class
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// 状态栏菜单项
    /// Status bar menu item
    private var statusItem: NSStatusItem?
    
    /// 文本选择监控器
    /// Text selection monitor
    private var selectionMonitor: SelectionMonitor?
    
    /// 工具栏窗口控制器
    /// Toolbar window controller
    private var toolbarController: ToolbarWindowController?
    
    /// 设置窗口控制器
    /// Settings window controller
    private var settingsWindowController: SettingsWindowController?
    
    // MARK: - Application Lifecycle
    
    /// 应用程序启动完成回调
    /// Application did finish launching callback
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 设置状态栏图标
        // Setup status bar icon
        setupStatusBar()
        
        // 检查并请求必要的权限
        // Check and request necessary permissions
        PermissionManager.shared.checkPermissions()
        
        // 初始化选择监控器
        // Initialize selection monitor
        selectionMonitor = SelectionMonitor()
        selectionMonitor?.delegate = self
        selectionMonitor?.startMonitoring()
        
        // 初始化工具栏控制器
        // Initialize toolbar controller
        toolbarController = ToolbarWindowController()
    }
    
    /// 应用程序即将终止回调
    /// Application will terminate callback
    func applicationWillTerminate(_ aNotification: Notification) {
        // 停止监控
        // Stop monitoring
        selectionMonitor?.stopMonitoring()
    }
    
    /// 应用程序支持突然终止
    /// Application supports sudden termination
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    /// 设置状态栏菜单
    /// Setup status bar menu
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // 使用系统图标或文本
            // Use system icon or text
            button.title = "📝"
        }
        
        // 创建菜单
        // Create menu
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "设置 (Settings)", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "关于 Selecto (About)", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出 (Quit)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    /// 打开设置窗口
    /// Open settings window
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 显示关于对话框
    /// Show about dialog
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Selecto",
            .applicationVersion: "1.0",
            .credits: NSAttributedString(string: "一个强大的 macOS 划词增强工具\nA powerful macOS text selection enhancement tool"),
            .copyright: "Copyright © 2024 Gao Yang"
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - SelectionMonitorDelegate

extension AppDelegate: SelectionMonitorDelegate {
    /// 当检测到文本选择时调用
    /// Called when text selection is detected
    func didDetectTextSelection(text: String, bounds: CGRect) {
        // 检查是否符合用户配置的条件
        // Check if matches user-configured conditions
        let actions = ActionManager.shared.getMatchingActions(for: text)
        
        if !actions.isEmpty {
            // 显示工具栏
            // Show toolbar
            toolbarController?.showToolbar(with: actions, at: bounds, selectedText: text)
        }
    }
    
    /// 当文本选择被取消时调用
    /// Called when text selection is cancelled
    func didCancelTextSelection() {
        // 隐藏工具栏
        // Hide toolbar
        toolbarController?.hideToolbar()
    }
}
