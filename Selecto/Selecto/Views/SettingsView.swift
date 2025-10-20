//
//  SettingsView.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import SwiftUI

/// 设置视图
/// Settings view
/// SwiftUI 视图，用于显示和编辑应用设置
/// SwiftUI view for displaying and editing app settings
struct SettingsView: View {
    
    // MARK: - State
    
    /// 动作列表
    /// Action list
    @State private var actions: [ActionItem] = ActionManager.shared.actions
    
    /// 选中的动作
    /// Selected action
    @State private var selectedAction: ActionItem?
    
    /// 是否显示添加动作表单
    /// Whether to show add action sheet
    @State private var showingAddAction = false
    
    /// 是否显示编辑动作表单
    /// Whether to show edit action sheet
    @State private var showingEditAction = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            // 侧边栏：动作列表
            // Sidebar: Action list
            List(selection: $selectedAction) {
                ForEach(actions) { action in
                    ActionRow(action: action)
                        .tag(action)
                        .contextMenu {
                            Button("编辑") {
                                selectedAction = action
                                showingEditAction = true
                            }
                            Button("删除", role: .destructive) {
                                deleteAction(action)
                            }
                        }
                }
                .onMove(perform: moveActions)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 250)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddAction = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            
            // 详细视图
            // Detail view
            if let action = selectedAction {
                ActionDetailView(action: action)
            } else {
                Text("选择一个动作查看详情")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingAddAction) {
            ActionEditorView(action: nil) { newAction in
                ActionManager.shared.addAction(newAction)
                refreshActions()
            }
        }
        .sheet(isPresented: $showingEditAction) {
            if let action = selectedAction {
                ActionEditorView(action: action) { updatedAction in
                    ActionManager.shared.updateAction(updatedAction)
                    refreshActions()
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// 删除动作
    /// Delete action
    private func deleteAction(_ action: ActionItem) {
        ActionManager.shared.deleteAction(withId: action.id)
        refreshActions()
    }
    
    /// 移动动作
    /// Move actions
    private func moveActions(from source: IndexSet, to destination: Int) {
        actions.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序
        // Update sort order
        for (index, action) in actions.enumerated() {
            var updatedAction = action
            updatedAction.sortOrder = index
            actions[index] = updatedAction
        }
        
        ActionManager.shared.reorderActions(actions)
    }
    
    /// 刷新动作列表
    /// Refresh action list
    private func refreshActions() {
        actions = ActionManager.shared.actions
    }
}
