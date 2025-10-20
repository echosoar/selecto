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
    
    /// 鼠标按下事件监听器
    /// Mouse down event monitor
    private var mouseDownMonitor: Any?
    
    /// 鼠标抬起事件监听器
    /// Mouse up event monitor
    private var mouseUpMonitor: Any?
    
    /// 键盘事件监听器
    /// Keyboard event monitor
    private var keyboardEventMonitor: Any?
    
    /// 当前选中的文本
    /// Currently selected text
    private var currentSelectedText: String?
    
    /// 当前选区的边界
    /// Bounds of the current selection
    private var currentSelectionBounds: CGRect?
    
    /// 标记当前是否处于鼠标拖拽选择中
    /// Indicates whether a mouse-driven selection is in progress
    private var isMouseSelecting = false
    
    /// 上一次鼠标按下时间
    /// Timestamp of last mouse down event
    private var lastMouseDownDate: Date?
    
    /// 鼠标按下时的位置
    /// Mouse location on mouse down
    private var lastMouseDownLocation: CGPoint?

    /// 鼠标抬起时的位置
    /// Mouse location on mouse up
    private var lastMouseUpLocation: CGPoint?

    /// 拖拽是否满足展示阈值
    /// Whether the drag movement meets the display threshold
    private var didMeetMovementThreshold = false

    /// 鼠标拖拽最小展示阈值
    /// Minimum movement threshold to display selection
    private let movementThreshold: CGFloat = 10

    /// 是否忽略接下来的短时选择
    /// Flag to ignore next short-lived selection
    private var shouldIgnoreNextSelection = false
    
    // MARK: - Public Methods
    
    /// 开始监控文本选择
    /// Start monitoring text selection
    func startMonitoring() {
        // 监听鼠标事件
        // Monitor mouse events
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.handleMouseDown(event)
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
        }
        
        // 监听键盘事件（例如 Cmd+C）
        // Monitor keyboard events (e.g., Cmd+C)
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyDown(event)
        }
        
    }
    
    /// 停止监控文本选择
    /// Stop monitoring text selection
    func stopMonitoring() {
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDownMonitor = nil
        }
        
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
        
        if let monitor = keyboardEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitor = nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 处理鼠标按下事件
    /// Handle mouse down event
    private func handleMouseDown(_ event: NSEvent) {
        isMouseSelecting = true
        lastMouseDownDate = Date()
        lastMouseDownLocation = event.locationInWindow
        lastMouseUpLocation = nil
        didMeetMovementThreshold = false
        if currentSelectedText != nil {
            currentSelectedText = nil
            currentSelectionBounds = nil
            delegate?.didCancelTextSelection()
        }
    }
    
    /// 处理鼠标抬起事件
    /// Handle mouse up event
    private func handleMouseUp(_ event: NSEvent) {
        isMouseSelecting = false
        lastMouseUpLocation = event.locationInWindow
        if let downLocation = lastMouseDownLocation {
            let deltaX = abs(downLocation.x - event.locationInWindow.x)
            let deltaY = abs(downLocation.y - event.locationInWindow.y)
            didMeetMovementThreshold = deltaX > movementThreshold || deltaY > movementThreshold
        } else {
            didMeetMovementThreshold = false
        }
        if let downDate = lastMouseDownDate {
            let interval = Date().timeIntervalSince(downDate)
            if interval < 0.3 {
                shouldIgnoreNextSelection = true
            } else {
                shouldIgnoreNextSelection = false
            }
        }
        // 延迟检查以确保选择已完成
        // Delay check to ensure selection is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkForTextSelection()
        }
    }
    
    /// 处理键盘按下事件
    /// Handle key down event
    private func handleKeyDown(_ event: NSEvent) {
        // // 检查是否是快捷键（如 Cmd+C）
        // // Check if it's a shortcut key (e.g., Cmd+C)
        // if event.modifierFlags.contains(.command) {
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        //         self?.checkForTextSelection()
        //     }
        // }
    }
    
    /// 检查是否有文本被选中
    /// Check if text is selected
    private func checkForTextSelection() {
        // 在鼠标拖拽过程中不触发显示
        // Skip updates while mouse selection is in progress
        if isMouseSelecting {
            return
        }

        if shouldIgnoreNextSelection {
            shouldIgnoreNextSelection = false
            if currentSelectedText != nil {
                currentSelectedText = nil
                currentSelectionBounds = nil
                delegate?.didCancelTextSelection()
            }
            return
        }

        if let _ = lastMouseDownLocation,
           let _ = lastMouseUpLocation,
           !didMeetMovementThreshold {
            if currentSelectedText != nil {
                currentSelectedText = nil
                currentSelectionBounds = nil
                delegate?.didCancelTextSelection()
            }
            return
        }

        guard let (text, rawBounds, coordinateSpace) = currentSelectionSnapshot() else {
            if currentSelectedText != nil {
                currentSelectedText = nil
                currentSelectionBounds = nil
                delegate?.didCancelTextSelection()
            }
            return
        }

        // 过滤空白字符的选区
        // Ignore selections that contain only whitespace characters
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.isEmpty {
            if currentSelectedText != nil {
                currentSelectedText = nil
                currentSelectionBounds = nil
                delegate?.didCancelTextSelection()
            }
            return
        }

        let bounds = normalizeBounds(rawBounds, from: coordinateSpace)

        // 如果选中的文本与之前不同
        // If selected text is different from before
        let shouldNotify: Bool
        if let previousText = currentSelectedText,
           let previousBounds = currentSelectionBounds {
            shouldNotify = (previousText != text) || !previousBounds.isApproximatelyEqual(to: bounds, tolerance: 2.0)
        } else {
            shouldNotify = true
        }

        if shouldNotify {
            currentSelectedText = text
            currentSelectionBounds = bounds
            delegate?.didDetectTextSelection(text: text, bounds: bounds)
        }
    }

    /// 获取当前选区快照
    /// Retrieve the current selection snapshot from available sources
    private func currentSelectionSnapshot() -> (String, CGRect, SelectionCoordinateSpace)? {
        if let selection = getSelectedTextViaAccessibility() {
            return selection
        }
        if let chromeSelection = getSelectedTextFromChrome() {
            return chromeSelection
        }
        if let forcedSelection = getSelectedTextViaForcedCopy() {
            return forcedSelection
        }
        return nil
    }
    
    /// 通过辅助功能 API 获取选中的文本
    /// Get selected text via Accessibility API
    /// - Returns: 返回选中的文本和边界 / Returns selected text and bounds
    private func getSelectedTextViaAccessibility() -> (String, CGRect, SelectionCoordinateSpace)? {
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
        
        let axElement = element as! AXUIElement
        var bounds = CGRect.zero
        var coordinateSpace: SelectionCoordinateSpace = .accessibility
        if let rangeValue = boundsValue {
            let axRangeValue = rangeValue as! AXValue
            if AXValueGetType(axRangeValue) == .cfRange,
               let preciseBounds = boundsForRange(axRangeValue, in: axElement) {
                bounds = preciseBounds
            } else if let position = position, let size = size {
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
                coordinateSpace = .appKit
            }
        } else if let position = position, let size = size {
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
            coordinateSpace = .appKit
        }
        // 如果 text 是空，返回 nil
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        return (text, bounds, coordinateSpace)
    }

    /// 使用 AppleScript 从 Chrome 获取选中的文本
    /// Retrieve selected text from Google Chrome via AppleScript when AX fails
    private func getSelectedTextFromChrome() -> (String, CGRect, SelectionCoordinateSpace)? {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        let supportedBundleIdentifiers: Set<String> = [
            "com.google.Chrome",
            "com.google.Chrome.beta",
            "com.google.Chrome.dev",
            "com.google.Chrome.canary"
        ]
        guard supportedBundleIdentifiers.contains(bundleIdentifier) else {
            return nil
        }

        let scriptSource = """
        tell application id "\(bundleIdentifier)"
            tell active tab of front window
                set selection_text to execute javascript "window.getSelection().toString();"
            end tell
        end tell
        """

        guard let script = NSAppleScript(source: scriptSource) else {
            return nil
        }
        var result: String = ""
        var errorDict: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorDict)
        if let errorDict = errorDict {
            // result = errorDict[NSAppleScript.errorMessage] as? String ?? "AppleScript error"
            print("AppleScript error: \(errorDict)")
        }

        if descriptor.stringValue != nil {
            result = descriptor.stringValue ?? ""
        }

        let trimmed = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "undefined" || trimmed == "null" {
            return nil
        }
         // rawText + bundleIdentifier
        let newRawText = trimmed
        let mouseLocation = NSEvent.mouseLocation
        let fallbackBounds = CGRect(x: mouseLocation.x - 60, y: mouseLocation.y - 20, width: 160, height: 32)
        return (newRawText, fallbackBounds, .appKit)
    }

    /// 通过模拟复制获取选中文本
    /// Retrieve selected text by simulating Command+C when forced selection is enabled
    private func getSelectedTextViaForcedCopy() -> (String, CGRect, SelectionCoordinateSpace)? {
        guard AppPreferences.shared.forceSelectionEnabled else {
            return nil
        }

        let scriptSource = """
        set previousClipboard to (the clipboard as record)
        tell application "System Events"
            keystroke "c" using {command down}
        end tell
        delay 0.05
        set selectedText to the (the clipboard as text)
        set the clipboard to previousClipboard
        return selectedText
        """

        guard let script = NSAppleScript(source: scriptSource) else {
            return nil
        }

        var errorDict: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorDict)

        if let errorDict {
            print("Forced copy AppleScript error: \(errorDict)")
            return nil
        }

        guard let textValue = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !textValue.isEmpty,
              textValue.lowercased() != "undefined",
              textValue.lowercased() != "null" else {
            return nil
        }

        let mouseLocation = NSEvent.mouseLocation
        let fallbackBounds = CGRect(x: mouseLocation.x - 60, y: mouseLocation.y - 20, width: 160, height: 32)
        return (textValue, fallbackBounds, .appKit)
    }
    
    /// 获取选区的精确边界
    /// Retrieve the precise bounds for the selected range when available
    private func boundsForRange(_ rangeValue: AXValue, in element: AXUIElement) -> CGRect? {
        var range = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &range) else {
            return nil
        }
        var mutableRange = range
        guard let rangeParameter = AXValueCreate(.cfRange, &mutableRange) else {
            return nil
        }
        var result: CFTypeRef?
        let status = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeParameter,
            &result
        )
        guard status == .success,
              let rectAny = result else {
            return nil
        }
        let rectValue = rectAny as! AXValue
        guard AXValueGetType(rectValue) == .cgRect else {
            return nil
        }
        var rect = CGRect.zero
        AXValueGetValue(rectValue, .cgRect, &rect)
        return rect
    }
}

// MARK: - CGRect Helpers

private enum SelectionCoordinateSpace {
    case accessibility
    case appKit
}

private extension CGRect {
    /// 判断两个 CGRect 是否在给定误差范围内相等
    /// Check if two CGRect values are approximately equal within a tolerance
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        return abs(origin.x - other.origin.x) <= tolerance &&
            abs(origin.y - other.origin.y) <= tolerance &&
            abs(size.width - other.size.width) <= tolerance &&
            abs(size.height - other.size.height) <= tolerance
    }
}

private extension SelectionMonitor {
    func normalizeBounds(_ bounds: CGRect, from coordinateSpace: SelectionCoordinateSpace) -> CGRect {
        // 如果 bounds 的宽或高是 0，直接使用鼠标位置
        // If bounds width or height is 0, use mouse position directly
        if bounds.width == 0 || bounds.height == 0 {
            let mouseLocation = NSEvent.mouseLocation
            return CGRect(x: mouseLocation.x - 60, y: mouseLocation.y - 20, width: 160, height: 32)
        }
        
        switch coordinateSpace {
        case .appKit:
            return bounds
        case .accessibility:
            // 辅助功能 API 坐标转换为 AppKit 坐标
            // Convert Accessibility API coordinates to AppKit coordinates
            guard let screen = screenContaining(bounds) else {
                return bounds
            }
            let convertedY = screen.frame.maxY - (bounds.origin.y + bounds.height)
            return CGRect(x: bounds.origin.x, y: convertedY, width: bounds.width, height: bounds.height)
        }
    }
    
    func screenContaining(_ rect: CGRect) -> NSScreen? {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for screen in NSScreen.screens {
            if screen.frame.contains(center) {
                return screen
            }
        }
        return NSScreen.main
    }
}
