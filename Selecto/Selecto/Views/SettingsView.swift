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
                            Button("编辑 (Edit)") {
                                selectedAction = action
                                showingEditAction = true
                            }
                            Button("删除 (Delete)", role: .destructive) {
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
                Text("选择一个动作查看详情\nSelect an action to view details")
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

/// 动作行视图
/// Action row view
struct ActionRow: View {
    let action: ActionItem
    
    var body: some View {
        HStack {
            Image(systemName: action.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(action.isEnabled ? .green : .secondary)
            
            VStack(alignment: .leading) {
                Text(action.displayName)
                    .font(.headline)
                Text(action.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 动作详细视图
/// Action detail view
struct ActionDetailView: View {
    let action: ActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            // Title
            Text(action.displayName)
                .font(.largeTitle)
                .bold()
            
            // 基本信息
            // Basic information
            GroupBox(label: Text("基本信息 (Basic Information)")) {
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "名称 (Name)", value: action.name)
                    InfoRow(label: "类型 (Type)", value: action.type.displayName)
                    InfoRow(label: "状态 (Status)", value: action.isEnabled ? "启用 (Enabled)" : "禁用 (Disabled)")
                }
                .padding()
            }
            
            // 匹配条件
            // Match condition
            if let pattern = action.matchPattern, !pattern.isEmpty {
                GroupBox(label: Text("匹配条件 (Match Condition)")) {
                    VStack(alignment: .leading) {
                        Text("正则表达式 (Regex): \(pattern)")
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                }
            }
            
            // 参数
            // Parameters
            if !action.parameters.isEmpty {
                GroupBox(label: Text("参数 (Parameters)")) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(action.parameters.keys.sorted()), id: \.self) { key in
                            if let value = action.parameters[key] {
                                InfoRow(label: key, value: value)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 信息行视图
/// Info row view
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
    }
}

/// 动作编辑器视图
/// Action editor view
struct ActionEditorView: View {
    let action: ActionItem?
    let onSave: (ActionItem) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var displayName: String
    @State private var type: ActionType
    @State private var isEnabled: Bool
    @State private var matchPattern: String
    @State private var urlParameter: String
    
    init(action: ActionItem?, onSave: @escaping (ActionItem) -> Void) {
        self.action = action
        self.onSave = onSave
        
        _name = State(initialValue: action?.name ?? "")
        _displayName = State(initialValue: action?.displayName ?? "")
        _type = State(initialValue: action?.type ?? .copyToClipboard)
        _isEnabled = State(initialValue: action?.isEnabled ?? true)
        _matchPattern = State(initialValue: action?.matchPattern ?? "")
        _urlParameter = State(initialValue: action?.parameters["url"] ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息 (Basic Information)")) {
                TextField("名称 (Name)", text: $name)
                TextField("显示名称 (Display Name)", text: $displayName)
                
                Picker("类型 (Type)", selection: $type) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                
                Toggle("启用 (Enabled)", isOn: $isEnabled)
            }
            
            Section(header: Text("匹配条件 (Match Condition)")) {
                TextField("正则表达式 (Regex Pattern)", text: $matchPattern)
                    .font(.system(.body, design: .monospaced))
                Text("留空表示匹配所有文本 (Leave empty to match all text)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("参数 (Parameters)")) {
                if type == .search || type == .translate || type == .openURL {
                    TextField("URL 模板 (URL Template)", text: $urlParameter)
                    Text("使用 {text} 作为占位符 (Use {text} as placeholder)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Button("取消 (Cancel)") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存 (Save)") {
                    saveAction()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    private func saveAction() {
        var parameters: [String: String] = [:]
        if !urlParameter.isEmpty {
            parameters["url"] = urlParameter
        }
        
        let newAction = ActionItem(
            id: action?.id ?? UUID(),
            name: name,
            displayName: displayName,
            type: type,
            isEnabled: isEnabled,
            matchPattern: matchPattern.isEmpty ? nil : matchPattern,
            parameters: parameters,
            sortOrder: action?.sortOrder ?? 0
        )
        
        onSave(newAction)
        dismiss()
    }
}
