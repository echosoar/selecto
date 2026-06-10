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
    
    /// 应用全局状态
    /// Application global state
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withModal(appState: appState)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 Selecto (About)") {
                    let credits = NSMutableAttributedString(string: "一个强大的 macOS 划词增强工具\nA powerful macOS text selection enhancement tool")
                    credits.append(NSAttributedString(string: "\n\n© 2024 Gao Yang"))
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "Selecto",
                        .applicationVersion: "1.0",
                        .credits: credits
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
    
    /// 当前选中的文本
    /// Current selected text
    private var currentSelectedText: String?
    
    /// 当前选区的边界
    /// Current selection bounds
    private var currentSelectionBounds: CGRect?
    
    // MARK: - Application Lifecycle
    
    /// 应用程序启动完成回调
    /// Application did finish launching callback
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 隐藏主窗口（在启动时不显示）
        // Hide main window on launch
        NSApp.setActivationPolicy(.accessory)
        
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
        
        // 监听动作更新通知
        // Listen for action update notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(actionsDidUpdate),
            name: .actionsDidUpdate,
            object: nil
        )
    }
    
    /// 应用程序即将终止回调
    /// Application will terminate callback
    func applicationWillTerminate(_ aNotification: Notification) {
        // 停止监控
        // Stop monitoring
        selectionMonitor?.stopMonitoring()
        
        // 移除通知观察者
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
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
        
        let controlPanelItem = NSMenuItem(title: "显示控制面板", action: #selector(showControlPanel), keyEquivalent: ",")
        controlPanelItem.target = self
        menu.addItem(controlPanelItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    /// 显示控制面板
    /// Show control panel window
    @objc private func showControlPanel() {
        // 切换激活策略以显示应用程序
        // Switch activation policy to show application
        NSApp.setActivationPolicy(.regular)
        
        // 激活主应用程序
        // Activate main application
        NSApp.activate(ignoringOtherApps: true)
        
        // 查找并显示主窗口（WindowGroup 创建的窗口）
        // Find and show main window (created by WindowGroup)
        if let mainWindow = NSApp.windows.first(where: { $0.contentViewController is NSHostingController<ContentView> }) {
            // 设置窗口代理以监听关闭事件
            // Set window delegate to listen for close events
            mainWindow.delegate = self
            mainWindow.makeKeyAndOrderFront(nil)
        } else if let anyWindow = NSApp.windows.first {
            // 如果没有找到 ContentView 窗口，显示第一个窗口
            // If ContentView window not found, show first window
            anyWindow.delegate = self
            anyWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    /// 处理动作更新通知
    /// Handle actions update notification
    @objc private func actionsDidUpdate() {
        // 如果当前有选中的文本，重新评估并刷新工具栏
        // If there's currently selected text, re-evaluate and refresh the toolbar
        guard let text = currentSelectedText,
              let bounds = currentSelectionBounds else {
            return
        }
        
        let actions = ActionManager.shared.getMatchingActions(for: text)
        
        if !actions.isEmpty {
            // 刷新工具栏显示的动作
            // Refresh the toolbar with updated actions
            toolbarController?.showToolbar(with: actions, at: bounds, selectedText: text)
        } else {
            // 如果没有匹配的动作了，隐藏工具栏
            // If no matching actions anymore, hide the toolbar
            toolbarController?.hideToolbar(force: true)
            currentSelectedText = nil
            currentSelectionBounds = nil
        }
    }
}

// MARK: - SelectionMonitorDelegate

extension AppDelegate: SelectionMonitorDelegate {
    /// 当检测到文本选择时调用
    /// Called when text selection is detected
    func didDetectTextSelection(text: String, bounds: CGRect) {
        if isSelectionInsideApp() {
            return
        }
        // 记录选择的文本
        // Log selected text
        SelectionHistoryManager.shared.addSelection(text, bounds: bounds)
        
        // 保存当前选择状态
        // Save current selection state
        currentSelectedText = text
        currentSelectionBounds = bounds
        
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
        // 清除选择状态
        // Clear selection state
        currentSelectedText = nil
        currentSelectionBounds = nil
        
        // 隐藏工具栏
        // Hide toolbar
        toolbarController?.hideToolbar(force: true)
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    /// 窗口即将关闭时调用
    /// Called when window is about to close
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 隐藏窗口而不是关闭
        // Hide window instead of closing
        sender.orderOut(nil)

        // 切换回 accessory 模式，从 Dock 中隐藏
        // Switch back to accessory mode to hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // 返回 false 以阻止窗口实际关闭
        // Return false to prevent actual window closure
        return false
    }
}

private extension AppDelegate {
    func isSelectionInsideApp() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = Bundle.main.bundleIdentifier else {
            return false
        }
        return frontApp.bundleIdentifier == bundleID
    }
}
