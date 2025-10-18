//
//  ContentView.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import SwiftUI
import AppKit

/// 主内容视图
/// Main content view
struct ContentView: View {
    
    /// 选中的标签页
    /// Selected tab
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 权限设置页
            // Permissions tab
            PermissionsView()
                .tabItem {
                    Label("权限 (Permissions)", systemImage: "lock.shield")
                }
                .tag(0)
            
            // 动作配置页
            // Actions tab
            ActionsView()
                .tabItem {
                    Label("动作 (Actions)", systemImage: "list.bullet")
                }
                .tag(1)
            
            // 历史记录页
            // History tab
            HistoryView()
                .tabItem {
                    Label("历史 (History)", systemImage: "clock")
                }
                .tag(2)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

/// 权限视图
/// Permissions view
struct PermissionsView: View {
    
    /// 辅助功能权限状态
    /// Accessibility permission status
    @State private var hasAccessibilityPermission = false
    
    /// 屏幕录制权限状态
    /// Screen recording permission status
    @State private var hasScreenRecordingPermission = false
    
    /// 定时器用于刷新权限状态
    /// Timer to refresh permission status
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("权限设置 (Permission Settings)")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Selecto 需要以下权限才能正常工作 (Selecto requires the following permissions to work properly)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // 辅助功能权限
            // Accessibility permission
            PermissionCard(
                title: "辅助功能 (Accessibility)",
                description: "允许 Selecto 监控文本选择 (Allow Selecto to monitor text selection)",
                isGranted: hasAccessibilityPermission,
                icon: "hand.point.up.braille"
            ) {
                requestAccessibilityPermission()
            }
            
            // 屏幕录制权限
            // Screen recording permission
            if #available(macOS 10.15, *) {
                PermissionCard(
                    title: "屏幕录制 (Screen Recording)",
                    description: "允许 Selecto 获取选中文本的位置 (Allow Selecto to get the position of selected text)",
                    isGranted: hasScreenRecordingPermission,
                    icon: "rectangle.on.rectangle"
                ) {
                    requestScreenRecordingPermission()
                }
            }
            
            Spacer()
            
            if hasAccessibilityPermission {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("所有必需权限已授予 (All required permissions granted)")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("您现在可以使用 Selecto 的所有功能 (You can now use all features of Selecto)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkPermissions()
        }
        .onReceive(timer) { _ in
            checkPermissions()
        }
    }
    
    /// 检查权限状态
    /// Check permission status
    private func checkPermissions() {
        hasAccessibilityPermission = PermissionManager.shared.checkAccessibilityPermission()
        if #available(macOS 10.15, *) {
            hasScreenRecordingPermission = PermissionManager.shared.checkScreenRecordingPermission()
        }
        
        // 如果权限已授予，启动监控
        // Start monitoring if permission is granted
        if hasAccessibilityPermission {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.startMonitoring()
            }
        }
    }
    
    /// 请求辅助功能权限
    /// Request accessibility permission
    private func requestAccessibilityPermission() {
        PermissionManager.shared.openSystemPreferences(for: .accessibility)
    }
    
    /// 请求屏幕录制权限
    /// Request screen recording permission
    private func requestScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            PermissionManager.shared.openSystemPreferences(for: .screenRecording)
        }
    }
}

/// 权限卡片视图
/// Permission card view
struct PermissionCard: View {
    let title: String
    let description: String
    let isGranted: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 图标
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态和按钮
            // Status and button
            if isGranted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已授权 (Granted)")
                        .foregroundColor(.green)
                }
            } else {
                Button(action: action) {
                    Text("授权 (Authorize)")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(.horizontal, 40)
    }
}

/// 动作配置视图
/// Actions configuration view
struct ActionsView: View {
    
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

/// 历史记录视图
/// History view
struct HistoryView: View {
    
    /// 是否启用历史记录
    /// Whether history is enabled
    @State private var isHistoryEnabled = SelectionHistoryManager.shared.isEnabled
    
    /// 历史记录列表
    /// History list
    @State private var history: [SelectionHistory] = SelectionHistoryManager.shared.getHistory()
    
    /// 定时器用于刷新历史记录
    /// Timer to refresh history
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            // Header
            HStack {
                Text("选择历史 (Selection History)")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Toggle("启用历史记录 (Enable History)", isOn: $isHistoryEnabled)
                    .onChange(of: isHistoryEnabled) { newValue in
                        SelectionHistoryManager.shared.isEnabled = newValue
                    }
            }
            .padding()
            
            Divider()
            
            if !isHistoryEnabled {
                // 历史记录已禁用
                // History disabled
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("历史记录已禁用 (History is disabled)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("启用历史记录以查看最近选择的文本 (Enable history to see recently selected text)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if history.isEmpty {
                // 历史记录为空
                // History is empty
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("暂无历史记录 (No history yet)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("选择一些文本后，它们会显示在这里 (Selected text will appear here)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 历史记录列表
                // History list
                List {
                    ForEach(history) { item in
                        HistoryRow(history: item)
                    }
                }
                .listStyle(.inset)
            }
        }
        .onReceive(timer) { _ in
            if isHistoryEnabled {
                history = SelectionHistoryManager.shared.getHistory()
            }
        }
    }
}

/// 历史记录行视图
/// History row view
struct HistoryRow: View {
    let history: SelectionHistory
    
    var body: some View {
        let bounds = history.bounds
        let hasBounds = !bounds.isEmpty
        let topLeft = topLeftPoint(for: bounds)
        VStack(alignment: .leading, spacing: 8) {
            // 文本内容
            // Text content
            Text(history.text)
                .font(.body)
                .lineLimit(3)
            
            // 时间戳
            // Timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(formatDate(history.timestamp))
                    .font(.caption)
                
                Spacer()
                
                // 复制按钮
                // Copy button
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(history.text, forType: .string)
                }) {
                    Label("复制 (Copy)", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .foregroundColor(.secondary)
            
            if hasBounds {
                HStack(spacing: 16) {
                    Label {
                        Text("x: \(format(topLeft.x))  y: \(format(topLeft.y))")
                    } icon: {
                        Image(systemName: "location.north.west")
                    }
                    
                    Label {
                        Text("w: \(format(bounds.width))  h: \(format(bounds.height))")
                    } icon: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// 格式化日期
    /// Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private extension HistoryRow {
    func topLeftPoint(for rect: CGRect) -> CGPoint {
        guard !rect.isEmpty else { return .zero }
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(rect.origin) }) {
            let screenTop = screen.frame.maxY
            let topLeftY = screenTop - (rect.origin.y + rect.height)
            return CGPoint(x: rect.minX, y: topLeftY)
        }
        return CGPoint(x: rect.minX, y: rect.maxY)
    }
    
    func format(_ value: CGFloat) -> String {
        String(format: "%.0f", value)
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
