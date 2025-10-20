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
    
    /// 当前选区边界
    /// Current selection bounds
    private var currentSelectionBounds: CGRect?
    
    /// 自动隐藏定时器
    /// Auto-hide timer
    private var autoHideTimer: Timer?
    
    /// 是否禁用自动隐藏
    /// Whether auto-hide is disabled due to user interaction
    private var autoHideDisabled = false
    
    /// 记录最后一次点击是否发生在工具栏内部
    /// Track whether the last click occurred inside the toolbar window
    private var lastClickWasInsideToolbar = false
    
    /// 全局点击监视器
    /// Global click monitor
    private var globalClickMonitor: Any?
    
    /// 本地点击监视器
    /// Local click monitor
    private var localClickMonitor: Any?
    
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
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !actions.isEmpty else {
            hideToolbar(force: true)
            return
        }
        
    currentActions = actions
    selectedText = text
    currentSelectionBounds = bounds
    lastClickWasInsideToolbar = false
    autoHideDisabled = false
    stopOutsideClickMonitoring()
    startOutsideClickMonitoring()
        
        // 更新工具栏内容
        // Update toolbar content
        toolbarView?.updateActions(actions, selectedText: text)
        toolbarView?.layoutSubtreeIfNeeded()
        
        guard let frame = frameForCurrentContext(preferredSize: toolbarView?.fittingSize ?? NSSize(width: 200, height: 44)) else {
            window?.orderOut(nil)
            return
        }
        window?.setFrame(frame, display: true)
        
        // 显示窗口
        // Show window
        window?.orderFrontRegardless()
        
        // 设置自动隐藏定时器
        // Setup auto-hide timer
        setupAutoHideTimer()
    }
    
    /// 隐藏工具栏
    /// Hide toolbar
    func hideToolbar(force: Bool = false) {
        if lastClickWasInsideToolbar {
            return
        }
        lastClickWasInsideToolbar = false
        window?.orderOut(nil)
        cancelAutoHideTimer()
        stopOutsideClickMonitoring()
    }
    
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
        guard !autoHideDisabled else { return }
        cancelAutoHideTimer()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hideToolbar()
        }
    }

    /// 取消自动隐藏
    /// Cancel auto-hide timer
    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    /// 禁用自动隐藏直至下一次显示
    /// Disable auto-hide until toolbar is shown again
    private func disableAutoHide() {
        autoHideDisabled = true
        cancelAutoHideTimer()
    }
    
    /// 获取与选区匹配的屏幕
    /// Get the screen that contains the selection bounds
    private func screenForSelection(_ bounds: CGRect) -> NSScreen? {
        let selectionCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        for screen in NSScreen.screens {
            if screen.frame.contains(selectionCenter) {
                return screen
            }
        }
        return nil
    }
    
    private func frameForCurrentContext(preferredSize: NSSize) -> NSRect? {
        guard let bounds = currentSelectionBounds,
              let screen = screenForSelection(bounds) ?? NSScreen.main else {
            return nil
        }
        let contentWidth = min(max(preferredSize.width + 20, 180), 500)
        let contentHeight = max(preferredSize.height + 20, 44)
        let screenFrame = screen.visibleFrame
        let horizontalPadding: CGFloat = 10
        var xPosition = bounds.midX - contentWidth / 2
        xPosition = max(screenFrame.minX + horizontalPadding, xPosition)
        xPosition = min(screenFrame.maxX - contentWidth - horizontalPadding, xPosition)
        
        let offsetBelowSelection: CGFloat = 16
        var yPosition = bounds.minY - contentHeight - offsetBelowSelection
        yPosition = min(yPosition, bounds.minY - contentHeight)
        let maximumGap: CGFloat = 30
        let gap = bounds.minY - (yPosition + contentHeight)
        if gap > maximumGap {
            yPosition = bounds.minY - contentHeight - maximumGap
        }
        let verticalPadding: CGFloat = 10
        yPosition = max(screenFrame.minY + verticalPadding, yPosition)
        yPosition = min(screenFrame.maxY - contentHeight - verticalPadding, yPosition)
        let finalGap = bounds.minY - (yPosition + contentHeight)
        if finalGap > maximumGap {
            let adjustedY = bounds.minY - contentHeight - maximumGap
            yPosition = max(
                screenFrame.minY + verticalPadding,
                min(adjustedY, screenFrame.maxY - contentHeight - verticalPadding)
            )
        }
        return NSRect(x: xPosition, y: yPosition, width: contentWidth, height: contentHeight)
    }
    
    private func resizeWindowToFitContent() {
        guard let window = window,
              let toolbarView = toolbarView,
              let frame = frameForCurrentContext(preferredSize: toolbarView.fittingSize) else {
            return
        }
        toolbarView.layoutSubtreeIfNeeded()
        window.setFrame(frame, display: true, animate: true)
    }

    private func startOutsideClickMonitoring() {
        guard globalClickMonitor == nil, localClickMonitor == nil else { return }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            self?.handleMouseDown(event: event)
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event -> NSEvent? in
            guard let self = self else { return event }
            self.handleMouseDown(event: event)
            return event
        }
    }

    private func stopOutsideClickMonitoring() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    private func handleMouseDown(event: NSEvent) {
        guard let window = window else { return }

        let inside = isEvent(event, inside: window)
        lastClickWasInsideToolbar = inside
        if inside {
            disableAutoHide()
        } else {
            hideToolbar()
        }
    }

    private func isEvent(_ event: NSEvent, inside window: NSWindow) -> Bool {
        if let eventWindow = event.window, eventWindow == window {
            return true
        }
        let globalPoint = event.window != nil
            ? event.window!.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin
            : NSEvent.mouseLocation
        return window.frame.contains(globalPoint)
    }
}

// MARK: - ToolbarViewDelegate

extension ToolbarWindowController: ToolbarViewDelegate {
    /// 当点击动作按钮时调用
    /// Called when action button is clicked
    func didClickAction(_ action: ActionItem, selectedText: String) {
        // 执行动作
        // Execute action
        disableAutoHide()
        switch action.type {
        case .openURL:
            ActionExecutor.shared.execute(action, with: selectedText) { [weak self] result in
                self?.handleExecutionResult(result)
            }
        case .executeScript:
            toolbarView?.showLoading(message: "脚本运行中……")
            resizeWindowToFitContent()
            ActionExecutor.shared.execute(action, with: selectedText) { [weak self] result in
                guard let self = self else { return }
                self.toolbarView?.hideLoading()
                self.handleExecutionResult(result)
            }
        }
    }
    
    private func handleExecutionResult(_ result: ActionExecutionResult) {
        switch result {
        case .urlOpened:
            break
        case .scriptOutput(let lines):
            toolbarView?.showScriptOutput(lines)
            resizeWindowToFitContent()
        case .failure(let message):
            toolbarView?.showError(message)
            resizeWindowToFitContent()
        }
    }
}
