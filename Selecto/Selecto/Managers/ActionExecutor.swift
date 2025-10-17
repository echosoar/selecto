//
//  ActionExecutor.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa

/// 动作执行器
/// Action executor
/// 负责执行各种类型的动作
/// Responsible for executing various types of actions
class ActionExecutor {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = ActionExecutor()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 执行动作
    /// Execute action
    /// - Parameters:
    ///   - action: 要执行的动作 / Action to execute
    ///   - text: 选中的文本 / Selected text
    func execute(_ action: ActionItem, with text: String) {
        switch action.type {
        case .copyToClipboard:
            copyToClipboard(text)
            
        case .search:
            performSearch(text, parameters: action.parameters)
            
        case .translate:
            performTranslate(text, parameters: action.parameters)
            
        case .openURL:
            openURL(text, parameters: action.parameters)
            
        case .executeScript:
            executeScript(text, parameters: action.parameters)
            
        case .custom:
            performCustomAction(text, parameters: action.parameters)
        }
    }
    
    // MARK: - Private Methods
    
    /// 复制到剪贴板
    /// Copy to clipboard
    /// - Parameter text: 要复制的文本 / Text to copy
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 显示通知
        // Show notification
        showNotification(title: "已复制 (Copied)", message: text)
    }
    
    /// 执行搜索
    /// Perform search
    /// - Parameters:
    ///   - text: 搜索文本 / Search text
    ///   - parameters: 参数 / Parameters
    private func performSearch(_ text: String, parameters: [String: String]) {
        guard let urlTemplate = parameters["url"] else { return }
        
        // 替换模板中的占位符
        // Replace placeholders in template
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: encodedText)
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 执行翻译
    /// Perform translation
    /// - Parameters:
    ///   - text: 要翻译的文本 / Text to translate
    ///   - parameters: 参数 / Parameters
    private func performTranslate(_ text: String, parameters: [String: String]) {
        guard let urlTemplate = parameters["url"] else { return }
        
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: encodedText)
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 打开 URL
    /// Open URL
    /// - Parameters:
    ///   - text: 文本 / Text
    ///   - parameters: 参数 / Parameters
    private func openURL(_ text: String, parameters: [String: String]) {
        // 如果文本本身是 URL，直接打开
        // If text itself is a URL, open it directly
        if let url = URL(string: text), url.scheme != nil {
            NSWorkspace.shared.open(url)
            return
        }
        
        // 否则使用模板
        // Otherwise use template
        if let urlTemplate = parameters["url"] {
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
            let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: encodedText)
            
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// 执行脚本
    /// Execute script
    /// - Parameters:
    ///   - text: 输入文本 / Input text
    ///   - parameters: 参数 / Parameters
    private func executeScript(_ text: String, parameters: [String: String]) {
        guard let scriptPath = parameters["path"] else { return }
        
        // 创建进程执行脚本
        // Create process to execute script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: scriptPath)
        process.arguments = [text]
        
        do {
            try process.run()
        } catch {
            print("执行脚本失败 (Failed to execute script): \(error)")
            showNotification(title: "错误 (Error)", message: "无法执行脚本 (Cannot execute script)")
        }
    }
    
    /// 执行自定义动作
    /// Perform custom action
    /// - Parameters:
    ///   - text: 输入文本 / Input text
    ///   - parameters: 参数 / Parameters
    private func performCustomAction(_ text: String, parameters: [String: String]) {
        // 自定义动作的实现可以根据需要扩展
        // Custom action implementation can be extended as needed
        print("执行自定义动作 (Executing custom action) with text: \(text)")
    }
    
    /// 显示通知
    /// Show notification
    /// - Parameters:
    ///   - title: 标题 / Title
    ///   - message: 消息 / Message
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}
