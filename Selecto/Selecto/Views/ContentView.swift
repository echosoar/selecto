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
                    Label("授权", systemImage: "lock.shield")
                }
                .tag(0)
            
            // 动作配置页
            // Actions tab
            ActionsView()
                .tabItem {
                    Label("设置", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            // 历史记录页
            // History tab
            HistoryView()
                .tabItem {
                    Label("日志", systemImage: "clock")
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
            Text("授权")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            Text("Selecto 需要以下授权才能正常工作")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // 辅助功能权限
            // Accessibility permission
            PermissionCard(
                title: "辅助功能",
                description: "允许 Selecto 监控文本选择",
                isGranted: hasAccessibilityPermission,
                icon: "hand.point.up.braille"
            ) {
                requestAccessibilityPermission()
            }
            
            // 屏幕录制权限
            // Screen recording permission
            if #available(macOS 10.15, *) {
                PermissionCard(
                    title: "屏幕录制",
                    description: "允许 Selecto 获取选中文本的位置",
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
                    
                    Text("所有必需授权已授予")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("您现在可以使用 Selecto 的所有功能")
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
                    Text("已授权")
                        .foregroundColor(.green)
                }
            } else {
                Button(action: action) {
                    Text("授权")
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
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width, 1100)
            let sidebarWidth = max(contentWidth * 0.35, 280)
            let detailWidth = max(contentWidth - sidebarWidth, 320)
            
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    sidebarHeader
                    List(selection: $selectedAction) {
                        ForEach(actions) { action in
                            ActionRow(action: action)
                                .tag(action)
                                .contextMenu {
                                    Button("上移") {
                                        moveActionUp(action)
                                    }
                                    .disabled(isFirstAction(action))
                                    Button("下移") {
                                        moveActionDown(action)
                                    }
                                    .disabled(isLastAction(action))
                                }
                        }
                    }
                    .listStyle(InsetListStyle())
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                }
                .frame(width: sidebarWidth, height: geometry.size.height)
                
                Divider()
                    .padding(.vertical, 24)
                
                Group {
                    if let action = selectedAction {
                        ActionDetailView(
                            action: action,
                            onEdit: { selected in
                                selectedAction = selected
                                showingEditAction = true
                            },
                            onDelete: { toDelete in
                                deleteAction(toDelete)
                            }
                        )
                    } else {
                        Text("选择一个动作查看详情")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: detailWidth, height: geometry.size.height, alignment: .topLeading)
                .padding(24)
            }
            .frame(width: contentWidth, height: geometry.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showingAddAction) {
            ActionEditorView(action: nil) { newAction in
                ActionManager.shared.addAction(newAction)
                refreshActions(selecting: newAction.id)
            }
        }
        .sheet(isPresented: $showingEditAction) {
            if let action = selectedAction {
                ActionEditorView(action: action) { updatedAction in
                    ActionManager.shared.updateAction(updatedAction)
                    refreshActions(selecting: updatedAction.id)
                }
            }
        }
    .onAppear(perform: ensureSelection)
    }
    
    /// 删除动作
    /// Delete action
    private func deleteAction(_ action: ActionItem) {
    ActionManager.shared.deleteAction(withId: action.id)
    refreshActions(selecting: nil)
    }
    
    /// 刷新动作列表
    /// Refresh action list
    private func refreshActions(selecting targetID: UUID? = nil) {
        let updatedActions = ActionManager.shared.actions.sorted { $0.sortOrder < $1.sortOrder }
        actions = updatedActions
        let desiredID = targetID ?? selectedAction?.id
        if let desiredID,
           let refreshedSelection = updatedActions.first(where: { $0.id == desiredID }) {
            selectedAction = refreshedSelection
        } else {
            selectedAction = updatedActions.first
        }
    }

    /// 确保存在默认选中的动作
    /// Ensure there's a default selected action when entering the view
    private func ensureSelection() {
        if selectedAction == nil {
            refreshActions(selecting: nil)
        }
    }
    
    /// 侧边栏标题区
    /// Sidebar header area
    private var sidebarHeader: some View {
        HStack(spacing: 12) {
            Text("动作列表")
                .font(.title3)
                .bold()
                .padding(.leading, 16)
            Spacer()
            Button(action: {
                if let action = selectedAction {
                    moveActionUp(action)
                }
            }) {
                Image(systemName: "arrow.up")
            }
            .controlSize(.small)
            .buttonStyle(.borderless)
            .disabled(selectedAction.map(isFirstAction) ?? true)
            
            Button(action: {
                if let action = selectedAction {
                    moveActionDown(action)
                }
            }) {
                Image(systemName: "arrow.down")
            }
            .controlSize(.small)
            .buttonStyle(.borderless)
            .disabled(selectedAction.map(isLastAction) ?? true)
            Button(action: { showingAddAction = true }) {
                Label("添加", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .controlSize(.small)
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }

    /// 将动作上移一位
    /// Move action up by one position
    private func moveActionUp(_ action: ActionItem) {
        guard let index = actions.firstIndex(where: { $0.id == action.id }), index > 0 else { return }
        actions.swapAt(index, index - 1)
        persistActionOrder()
    }
    
    /// 将动作下移一位
    /// Move action down by one position
    private func moveActionDown(_ action: ActionItem) {
        guard let index = actions.firstIndex(where: { $0.id == action.id }), index < actions.count - 1 else { return }
        actions.swapAt(index, index + 1)
        persistActionOrder()
    }
    
    /// 判断是否为第一个动作
    /// Check if action is the first in the list
    private func isFirstAction(_ action: ActionItem) -> Bool {
        guard let first = actions.first else { return false }
        return first.id == action.id
    }
    
    /// 判断是否为最后一个动作
    /// Check if action is the last in the list
    private func isLastAction(_ action: ActionItem) -> Bool {
        guard let last = actions.last else { return false }
        return last.id == action.id
    }
    
    /// 持久化更新后的动作排序
    /// Persist the updated action order to the manager
    private func persistActionOrder() {
        for (index, action) in actions.enumerated() {
            var updatedAction = action
            updatedAction.sortOrder = index
            actions[index] = updatedAction
        }
    ActionManager.shared.reorderActions(actions)
    refreshActions(selecting: selectedAction?.id)
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
                Text("选择日志")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Toggle("启用日志记录", isOn: $isHistoryEnabled)
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
                    
                    Text("日志记录已禁用")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("启用日志记录以查看最近选择的文本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if history.isEmpty {
                // 日志记录为空
                // History is empty
                VStack(spacing: 20) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("暂无日志记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("选择一些文本后，它们会显示在这里")
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
                    Label("复制", systemImage: "doc.on.doc")
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
    var onEdit: ((ActionItem) -> Void)? = nil
    var onDelete: ((ActionItem) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    // Title
                    Text(action.displayName)
                        .font(.largeTitle)
                        .bold()
                    
                    // 基本信息
                    GroupBox(label: Text("基本信息")) {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(label: "名称", value: action.name)
                            InfoRow(label: "类型", value: action.type.displayName)
                            InfoRow(label: "状态", value: action.isEnabled ? "启用" : "禁用")
                        }
                        .padding()
                    }
                    
                    // 匹配条件
                    if let pattern = action.matchPattern, !pattern.isEmpty {
                        GroupBox(label: Text("匹配条件")) {
                            VStack(alignment: .leading) {
                                Text("正则表达式：\(pattern)")
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding()
                        }
                    }
                    
                    // 参数
                    if action.type == .openURL, let url = action.parameters["url"], !url.isEmpty {
                        GroupBox(label: Text("URL 模板")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(url)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding()
                        }
                    } else if action.type == .executeScript, let script = action.parameters["script"], !script.isEmpty {
                        GroupBox(label: Text("脚本内容")) {
                            ScrollView {
                                Text(script)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 120)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }

                     if onEdit != nil || onDelete != nil {
                        Divider()
                            .padding(.vertical, 8)
                        HStack {
                            if let onEdit {
                                Button {
                                    onEdit(action)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            Spacer()
                            
                            if let onDelete {
                                Button(role: .destructive) {
                                    onDelete(action)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
    @State private var scriptContent: String
    
    init(action: ActionItem?, onSave: @escaping (ActionItem) -> Void) {
        self.action = action
        self.onSave = onSave
        
        _name = State(initialValue: action?.name ?? "")
        _displayName = State(initialValue: action?.displayName ?? "")
        _type = State(initialValue: action?.type ?? .openURL)
        _isEnabled = State(initialValue: action?.isEnabled ?? true)
        _matchPattern = State(initialValue: action?.matchPattern ?? "")
        _urlParameter = State(initialValue: action?.parameters["url"] ?? "")
        _scriptContent = State(initialValue: action?.parameters["script"] ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("名称", text: $name)
                TextField("显示名称", text: $displayName)
                
                Picker("类型", selection: $type) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                
                Toggle("启用", isOn: $isEnabled)
            }
            
            Section(header: Text("匹配条件")) {
                TextField("正则表达式", text: $matchPattern)
                    .font(.system(.body, design: .monospaced))
                Text("留空表示匹配所有文本")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("参数")) {
                if type == .openURL {
                    TextField("URL 模板", text: $urlParameter)
                    Text("使用 {text} 作为占位符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if type == .executeScript {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $scriptContent)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3))
                            )
                        Text("脚本将在 /bin/zsh 下执行，可使用 {text} 或 SELECTO_TEXT 环境变量获取选中文本")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存") {
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
        switch type {
        case .openURL:
            if !urlParameter.isEmpty {
                parameters["url"] = urlParameter
            }
        case .executeScript:
            if !scriptContent.isEmpty {
                parameters["script"] = scriptContent
            }
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
