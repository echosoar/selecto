//
//  ToolbarWindowController.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa

/// 工具栏窗口控制器
/// Toolbar window controller
/// 负责显示和管理浮动工具栏窗口
/// Responsible for displaying and managing floating toolbar window
class ToolbarWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// 当前显示的动作列表
    /// Currently displayed actions
    private var currentActions: [ActionItem] = []
    
    /// 当前选中的文本
    /// Currently selected text
    private var selectedText: String = ""
    
    /// 工具栏视图
    /// Toolbar view
    private var toolbarView: ToolbarView?
    
    // MARK: - Initialization
    
    init() {
        // 创建一个浮动窗口
        // Create a floating window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 50),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口属性
        // Configure window properties
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        
        super.init(window: window)
        
        // 设置工具栏视图
        // Setup toolbar view
        setupToolbarView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    /// 显示工具栏
    /// Show toolbar
    /// - Parameters:
    ///   - actions: 要显示的动作列表 / Actions to display
    ///   - bounds: 选中文本的边界 / Bounds of selected text
    ///   - text: 选中的文本 / Selected text
    func showToolbar(with actions: [ActionItem], at bounds: CGRect, selectedText text: String) {
        currentActions = actions
        selectedText = text
        
        // 更新工具栏内容
        // Update toolbar content
        toolbarView?.updateActions(actions, selectedText: text)
        
        // 计算工具栏位置（在选中文本上方）
        // Calculate toolbar position (above selected text)
        let toolbarHeight: CGFloat = 50
        let toolbarWidth: CGFloat = CGFloat(min(actions.count * 60 + 20, 400))
        
        // 屏幕坐标转换（macOS 坐标系统原点在左下角）
        // Screen coordinate conversion (macOS coordinate system origin is bottom-left)
        let screenFrame = NSScreen.main?.frame ?? .zero
        let xPosition = max(10, min(bounds.midX - toolbarWidth / 2, screenFrame.width - toolbarWidth - 10))
        let yPosition = screenFrame.height - bounds.minY + 10
        
        window?.setFrame(
            NSRect(x: xPosition, y: yPosition, width: toolbarWidth, height: toolbarHeight),
            display: true
        )
        
        // 显示窗口
        // Show window
        window?.orderFrontRegardless()
        
        // 设置自动隐藏定时器
        // Setup auto-hide timer
        setupAutoHideTimer()
    }
    
    /// 隐藏工具栏
    /// Hide toolbar
    func hideToolbar() {
        window?.orderOut(nil)
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    // MARK: - Private Properties
    
    /// 自动隐藏定时器
    /// Auto-hide timer
    private var autoHideTimer: Timer?
    
    // MARK: - Private Methods
    
    /// 设置工具栏视图
    /// Setup toolbar view
    private func setupToolbarView() {
        toolbarView = ToolbarView()
        toolbarView?.delegate = self
        window?.contentView = toolbarView
    }
    
    /// 设置自动隐藏定时器
    /// Setup auto-hide timer
    private func setupAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.hideToolbar()
        }
    }
}

// MARK: - ToolbarViewDelegate

extension ToolbarWindowController: ToolbarViewDelegate {
    /// 当点击动作按钮时调用
    /// Called when action button is clicked
    func didClickAction(_ action: ActionItem, selectedText: String) {
        // 执行动作
        // Execute action
        ActionExecutor.shared.execute(action, with: selectedText)
        
        // 隐藏工具栏
        // Hide toolbar
        hideToolbar()
    }
}
