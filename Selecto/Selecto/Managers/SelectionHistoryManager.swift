//
//  SelectionHistoryManager.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation
import CoreGraphics

/// 选择历史项
/// Selection history item
struct SelectionHistory: Identifiable, Codable {
    /// 唯一标识符
    /// Unique identifier
    let id: UUID
    
    /// 选中的文本
    /// Selected text
    let text: String
    
    /// 时间戳
    /// Timestamp
    let timestamp: Date
    
    /// 选区边界
    /// Selection bounds
    let bounds: CGRect
    
    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), bounds: CGRect) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.bounds = bounds
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case timestamp
        case bounds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        bounds = try container.decodeIfPresent(CGRect.self, forKey: .bounds) ?? .zero
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(timestamp, forKey: .timestamp)
        if bounds != .zero {
            try container.encode(bounds, forKey: .bounds)
        }
    }
}

/// 选择历史管理器
/// Selection history manager
/// 管理选择文本的历史记录
/// Manages history of selected text
class SelectionHistoryManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = SelectionHistoryManager()
    
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "SelectionHistoryEnabled") as? Bool ?? true
        loadHistory()
    }
    
    // MARK: - Properties
    
    /// 是否启用历史记录
    /// Whether history is enabled
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "SelectionHistoryEnabled")
            if !isEnabled {
                // 禁用时清空历史记录
                // Clear history when disabled
                clearHistory()
            }
        }
    }
    
    /// 历史记录列表（最多保存10条）
    /// History list (max 10 items)
    private var history: [SelectionHistory] = []
    
    /// 最大历史记录数量
    /// Maximum history count
    private let maxHistoryCount = 10
    
    /// 历史记录文件路径
    /// History file path
    private var historyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Selecto", isDirectory: true)
        
        // 确保目录存在
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent("history.json")
    }
    
    // MARK: - Public Methods
    
    /// 添加选择记录
    /// Add selection record
    /// - Parameter text: 选中的文本 / Selected text
    func addSelection(_ text: String, bounds: CGRect) {
        guard isEnabled else { return }
        
        // 过滤掉空白文本和太短的文本
        // Filter out blank text and text that is too short
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, trimmedText.count >= 2 else { return }
        
        // 检查是否与最近的记录重复
        // Check if duplicate with recent record
        if let lastHistory = history.first, lastHistory.text == trimmedText {
            if lastHistory.bounds.isApproximatelyEqual(to: bounds, tolerance: 1.0) {
                return
            }
        }
        
        // 添加新记录到开头
        // Add new record to the beginning
        let newHistory = SelectionHistory(text: trimmedText, bounds: bounds)
        history.insert(newHistory, at: 0)
        
        // 保持最多10条记录
        // Keep max 10 records
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        // 保存到文件
        // Save to file
        saveHistory()
    }
    
    /// 获取历史记录列表
    /// Get history list
    /// - Returns: 历史记录数组 / History array
    func getHistory() -> [SelectionHistory] {
        return history
    }
    
    /// 清空历史记录
    /// Clear history
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    // MARK: - Private Methods
    
    /// 加载设置
    /// Load settings
    private func loadSettings() {
        // 默认启用历史记录
        // History enabled by default
        isEnabled = UserDefaults.standard.object(forKey: "SelectionHistoryEnabled") as? Bool ?? true
    }
    
    /// 加载历史记录
    /// Load history
    private func loadHistory() {
        guard isEnabled else { return }
        
        // 尝试从文件加载
        // Try to load from file
        if FileManager.default.fileExists(atPath: historyFileURL.path) {
            do {
                let data = try Data(contentsOf: historyFileURL)
                let decoder = JSONDecoder()
                history = try decoder.decode([SelectionHistory].self, from: data)
            } catch {
                print("加载历史记录失败 (Failed to load history): \(error)")
                history = []
            }
        }
    }
    
    /// 保存历史记录
    /// Save history
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(history)
            try data.write(to: historyFileURL)
        } catch {
            print("保存历史记录失败 (Failed to save history): \(error)")
        }
    }
}

private extension CGRect {
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        abs(origin.x - other.origin.x) <= tolerance &&
        abs(origin.y - other.origin.y) <= tolerance &&
        abs(size.width - other.size.width) <= tolerance &&
        abs(size.height - other.size.height) <= tolerance
    }
}
