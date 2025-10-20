//
//  ActionManager.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation

/// 动作更新通知名称
/// Action update notification name
extension Notification.Name {
    static let actionsDidUpdate = Notification.Name("com.selecto.actionsDidUpdate")
}

/// 动作管理器
/// Action manager
/// 负责管理和存储用户配置的动作
/// Responsible for managing and storing user-configured actions
class ActionManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = ActionManager()
    
    private init() {
        loadActions()
    }
    
    // MARK: - Properties
    
    /// 存储的动作列表
    /// Stored action list
    private(set) var actions: [ActionItem] = []
    
    /// 用户配置文件路径
    /// User configuration file path
    private var configFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Selecto", isDirectory: true)
        
        // 确保目录存在
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        return appFolder.appendingPathComponent("actions.json")
    }
    
    // MARK: - Public Methods
    
    /// 获取匹配文本的动作列表
    /// Get actions that match the text
    /// - Parameter text: 选中的文本 / Selected text
    /// - Returns: 匹配的动作列表 / Matching action list
    func getMatchingActions(for text: String) -> [ActionItem] {
        return actions
            .filter { $0.matches(text: text) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// 添加动作
    /// Add action
    /// - Parameter action: 要添加的动作 / Action to add
    func addAction(_ action: ActionItem) {
        actions.append(action)
        saveActions()
        postActionsUpdateNotification()
    }
    
    /// 更新动作
    /// Update action
    /// - Parameter action: 要更新的动作 / Action to update
    func updateAction(_ action: ActionItem) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
            saveActions()
            postActionsUpdateNotification()
        }
    }
    
    /// 删除动作
    /// Delete action
    /// - Parameter id: 动作 ID / Action ID
    func deleteAction(withId id: UUID) {
        actions.removeAll { $0.id == id }
        saveActions()
        postActionsUpdateNotification()
    }
    
    /// 重新排序动作
    /// Reorder actions
    /// - Parameter actions: 新的动作顺序 / New action order
    func reorderActions(_ actions: [ActionItem]) {
        self.actions = actions
        saveActions()
        postActionsUpdateNotification()
    }
    
    // MARK: - Private Methods
    
    /// 加载动作配置
    /// Load action configuration
    private func loadActions() {
        // 尝试从文件加载
        // Try to load from file
        if FileManager.default.fileExists(atPath: configFileURL.path) {
            do {
                let data = try Data(contentsOf: configFileURL)
                let decoder = JSONDecoder()
                actions = try decoder.decode([ActionItem].self, from: data)
                return
            } catch {
                print("加载动作配置失败 (Failed to load action configuration): \(error)")
            }
        }
        
        // 如果加载失败，使用默认配置
        // If loading fails, use default configuration
        actions = ActionItem.defaultActions()
        saveActions()
    }
    
    /// 保存动作配置
    /// Save action configuration
    private func saveActions() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(actions)
            try data.write(to: configFileURL)
        } catch {
            print("保存动作配置失败 (Failed to save action configuration): \(error)")
        }
    }
    
    /// 发送动作更新通知
    /// Post actions update notification
    private func postActionsUpdateNotification() {
        NotificationCenter.default.post(name: .actionsDidUpdate, object: nil)
    }
}
