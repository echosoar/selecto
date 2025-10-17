//
//  SelectionMonitor.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa
import ApplicationServices

/// 选择监控器代理协议
/// Selection monitor delegate protocol
protocol SelectionMonitorDelegate: AnyObject {
    /// 检测到文本选择
    /// Text selection detected
    func didDetectTextSelection(text: String, bounds: CGRect)
    
    /// 取消文本选择
    /// Text selection cancelled
    func didCancelTextSelection()
}

/// 文本选择监控器类
/// Text selection monitor class
/// 负责监控系统级的文本选择事件
/// Responsible for monitoring system-wide text selection events
class SelectionMonitor {
    
    // MARK: - Properties
    
    /// 代理对象
    /// Delegate object
    weak var delegate: SelectionMonitorDelegate?
    
    /// 鼠标事件监听器
    /// Mouse event monitor
    private var mouseEventMonitor: Any?
    
    /// 键盘事件监听器
    /// Keyboard event monitor
    private var keyboardEventMonitor: Any?
    
    /// 当前选中的文本
    /// Currently selected text
    private var currentSelectedText: String?
    
    /// 定时器用于检查选择状态
    /// Timer for checking selection state
    private var checkTimer: Timer?
    
    // MARK: - Public Methods
    
    /// 开始监控文本选择
    /// Start monitoring text selection
    func startMonitoring() {
        // 监听鼠标事件
        // Monitor mouse events
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
        }
        
        // 监听键盘事件（例如 Cmd+C）
        // Monitor keyboard events (e.g., Cmd+C)
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyDown(event)
        }
        
        // 启动定时检查
        // Start periodic checking
        startPeriodicCheck()
    }
    
    /// 停止监控文本选择
    /// Stop monitoring text selection
    func stopMonitoring() {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
        
        if let monitor = keyboardEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitor = nil
        }
        
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Private Methods
    
    /// 处理鼠标抬起事件
    /// Handle mouse up event
    private func handleMouseUp(_ event: NSEvent) {
        // 延迟检查以确保选择已完成
        // Delay check to ensure selection is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkForTextSelection()
        }
    }
    
    /// 处理键盘按下事件
    /// Handle key down event
    private func handleKeyDown(_ event: NSEvent) {
        // 检查是否是快捷键（如 Cmd+C）
        // Check if it's a shortcut key (e.g., Cmd+C)
        if event.modifierFlags.contains(.command) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.checkForTextSelection()
            }
        }
    }
    
    /// 启动定期检查
    /// Start periodic checking
    private func startPeriodicCheck() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForTextSelection()
        }
    }
    
    /// 检查是否有文本被选中
    /// Check if text is selected
    private func checkForTextSelection() {
        // 使用辅助功能 API 获取选中的文本
        // Use Accessibility API to get selected text
        guard let (text, bounds) = getSelectedTextViaAccessibility() else {
            // 如果没有选中文本，通知代理
            // If no text is selected, notify delegate
            if currentSelectedText != nil {
                currentSelectedText = nil
                delegate?.didCancelTextSelection()
            }
            return
        }
        
        // 如果选中的文本与之前不同
        // If selected text is different from before
        if text != currentSelectedText && !text.isEmpty {
            currentSelectedText = text
            delegate?.didDetectTextSelection(text: text, bounds: bounds)
        }
    }
    
    /// 通过辅助功能 API 获取选中的文本
    /// Get selected text via Accessibility API
    /// - Returns: 返回选中的文本和边界 / Returns selected text and bounds
    private func getSelectedTextViaAccessibility() -> (String, CGRect)? {
        // 获取系统范围内的焦点元素
        // Get system-wide focused element
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            return nil
        }
        
        // 尝试获取选中的文本
        // Try to get selected text
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        guard textResult == .success, let text = selectedText as? String, !text.isEmpty else {
            return nil
        }
        
        // 获取选中文本的位置和大小
        // Get position and size of selected text
        var boundsValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextRangeAttribute as CFString, &boundsValue)
        
        // 尝试获取位置信息
        // Try to get position information
        var position: CFTypeRef?
        var size: CFTypeRef?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSizeAttribute as CFString, &size)
        
        var bounds = CGRect.zero
        if let position = position, let size = size {
            var point = CGPoint.zero
            var cgSize = CGSize.zero
            AXValueGetValue(position as! AXValue, .cgPoint, &point)
            AXValueGetValue(size as! AXValue, .cgSize, &cgSize)
            bounds = CGRect(origin: point, size: cgSize)
        } else {
            // 如果无法获取精确位置，使用鼠标当前位置
            // If precise position is unavailable, use current mouse position
            let mouseLocation = NSEvent.mouseLocation
            bounds = CGRect(x: mouseLocation.x, y: mouseLocation.y, width: 100, height: 20)
        }
        
        return (text, bounds)
    }
}
