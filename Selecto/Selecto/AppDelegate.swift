//
//  SelectoApp.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import SwiftUI

/// Selecto 主应用程序
/// Selecto main application
@main
struct SelectoApp: App {
    
    /// 应用代理
    /// App delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 Selecto (About)") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "Selecto",
                        .applicationVersion: "1.0",
                        .credits: NSAttributedString(string: "一个强大的 macOS 划词增强工具\nA powerful macOS text selection enhancement tool"),
                        .copyright: "Copyright © 2024 Gao Yang"
                    ])
                }
            }
        }
    }
}

/// 应用代理类
/// App delegate class
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
    
    // MARK: - Application Lifecycle
    
    /// 应用程序启动完成回调
    /// Application did finish launching callback
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 设置状态栏图标
        // Setup status bar icon
        setupStatusBar()
        
        // 初始化选择监控器
        // Initialize selection monitor
        selectionMonitor = SelectionMonitor()
        selectionMonitor?.delegate = self
        
        // 只有在权限授予后才启动监控
        // Only start monitoring after permissions are granted
        if PermissionManager.shared.checkAccessibilityPermission() {
            selectionMonitor?.startMonitoring()
        }
        
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
    
    // MARK: - Public Methods
    
    /// 启动文本选择监控
    /// Start text selection monitoring
    func startMonitoring() {
        selectionMonitor?.startMonitoring()
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
        
        menu.addItem(NSMenuItem(title: "显示设置 (Show Settings)", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出 (Quit)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    /// 显示设置窗口
    /// Show settings window
    @objc private func showSettings() {
        // 激活应用并显示主窗口
        // Activate app and show main window
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.contentViewController != nil {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

// MARK: - SelectionMonitorDelegate

extension AppDelegate: SelectionMonitorDelegate {
    /// 当检测到文本选择时调用
    /// Called when text selection is detected
    func didDetectTextSelection(text: String, bounds: CGRect) {
        // 记录选择的文本
        // Log selected text
        SelectionHistoryManager.shared.addSelection(text)
        
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
