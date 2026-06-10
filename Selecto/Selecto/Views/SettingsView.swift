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
    
    /// Modal 弹窗
    /// Modal presenter
    @Environment(\.modalPresenter) private var modalPresenter
    
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
                                openEditModal(for: action)
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
                    Button(action: { openAddModal() }) {
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
    }
    
    // MARK: - Methods
    
    /// 打开添加动作弹窗
    /// Open add action modal
    private func openAddModal() {
        modalPresenter?.open(title: "添加动作", data: ()) { ctx in
            ActionEditorView(action: nil, onSave: { newAction in
                ActionManager.shared.addAction(newAction)
                refreshActions()
                ctx.close()
            }, onCancel: { ctx.close() })
        }
    }
    
    /// 打开编辑动作弹窗
    /// Open edit action modal
    private func openEditModal(for action: ActionItem) {
        modalPresenter?.open(title: "编辑动作", data: action) { ctx in
            ActionEditorView(action: ctx.data, onSave: { updatedAction in
                ActionManager.shared.updateAction(updatedAction)
                refreshActions()
                ctx.close()
            }, onCancel: { ctx.close() })
        }
    }
    
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
