//
//  ActionItem.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation

/// 动作类型枚举
/// Action type enumeration
enum ActionType: String, Codable, CaseIterable {
    /// 复制到剪贴板
    /// Copy to clipboard
    case copyToClipboard = "copy"
    
    /// 搜索
    /// Search
    case search = "search"
    
    /// 翻译
    /// Translate
    case translate = "translate"
    
    /// 打开网址
    /// Open URL
    case openURL = "openURL"
    
    /// 执行脚本
    /// Execute script
    case executeScript = "script"
    
    /// 自定义
    /// Custom
    case custom = "custom"
    
    /// 显示名称
    /// Display name
    var displayName: String {
        switch self {
        case .copyToClipboard:
            return "复制 (Copy)"
        case .search:
            return "搜索 (Search)"
        case .translate:
            return "翻译 (Translate)"
        case .openURL:
            return "打开链接 (Open URL)"
        case .executeScript:
            return "运行脚本 (Run Script)"
        case .custom:
            return "自定义 (Custom)"
        }
    }
}

/// 动作项模型
/// Action item model
/// 定义用户可以触发的动作
/// Defines actions that users can trigger
struct ActionItem: Codable, Identifiable {
    /// 唯一标识符
    /// Unique identifier
    var id: UUID
    
    /// 动作名称
    /// Action name
    var name: String
    
    /// 显示名称
    /// Display name
    var displayName: String
    
    /// 动作类型
    /// Action type
    var type: ActionType
    
    /// 是否启用
    /// Is enabled
    var isEnabled: Bool
    
    /// 匹配条件（正则表达式）
    /// Match condition (regular expression)
    var matchPattern: String?
    
    /// 动作参数（如 URL 模板、脚本路径等）
    /// Action parameters (e.g., URL template, script path, etc.)
    var parameters: [String: String]
    
    /// 快捷键
    /// Keyboard shortcut
    var shortcut: String?
    
    /// 图标名称
    /// Icon name
    var iconName: String?
    
    /// 排序顺序
    /// Sort order
    var sortOrder: Int
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        type: ActionType,
        isEnabled: Bool = true,
        matchPattern: String? = nil,
        parameters: [String: String] = [:],
        shortcut: String? = nil,
        iconName: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.type = type
        self.isEnabled = isEnabled
        self.matchPattern = matchPattern
        self.parameters = parameters
        self.shortcut = shortcut
        self.iconName = iconName
        self.sortOrder = sortOrder
    }
    
    // MARK: - Methods
    
    /// 检查文本是否匹配此动作的条件
    /// Check if text matches this action's condition
    /// - Parameter text: 要检查的文本 / Text to check
    /// - Returns: 是否匹配 / Whether it matches
    func matches(text: String) -> Bool {
        // 如果未启用，返回 false
        // If not enabled, return false
        guard isEnabled else { return false }
        
        // 如果没有匹配模式，总是返回 true
        // If no match pattern, always return true
        guard let pattern = matchPattern, !pattern.isEmpty else {
            return true
        }
        
        // 使用正则表达式匹配
        // Use regular expression matching
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            print("正则表达式错误 (Regex error): \(error)")
            return false
        }
    }
    
    /// 创建默认动作列表
    /// Create default action list
    static func defaultActions() -> [ActionItem] {
        return [
            ActionItem(
                name: "copy",
                displayName: "复制",
                type: .copyToClipboard,
                sortOrder: 0
            ),
            ActionItem(
                name: "search_google",
                displayName: "搜索",
                type: .search,
                parameters: ["url": "https://www.google.com/search?q={text}"],
                sortOrder: 1
            ),
            ActionItem(
                name: "translate",
                displayName: "翻译",
                type: .translate,
                parameters: ["url": "https://translate.google.com/?text={text}"],
                sortOrder: 2
            )
        ]
    }
}
