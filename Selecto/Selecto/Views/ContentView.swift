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
    
    /// 菜单项
    /// Menu items
    private let menuItems: [(title: String, icon: String)] = [
        ("授权", "lock.shield"),
        ("动作", "slider.horizontal.3"),
        ("设置", "gearshape"),
        ("日志", "clock")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧菜单
            // Left menu
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(menuItems.indices, id: \.self) { index in
                        menuRow(index: index)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .frame(width: 200)
            .frame(maxHeight: .infinity)
            .background(Color(red: 0xf8 / 255, green: 0xf8 / 255, blue: 0xf8 / 255))
            
            Divider()
            
            // 右侧内容
            // Right content
            GeometryReader { geometry in
                ScrollView {
                    pageContent(height: geometry.size.height)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .ignoresSafeArea(.container, edges: .top)
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(.light)
    }
    
    /// 菜单行
    /// Menu row
    private func menuRow(index: Int) -> some View {
        let item = menuItems[index]
        let isSelected = selectedTab == index
        return Button(action: { selectedTab = index }) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .frame(width: 20)
                Text(item.title)
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// 右侧页面内容；自带列表的页面占满可见高度，其余页面超出时由外层滚动
    /// Page content; list-based pages fill the visible height, others scroll in the outer ScrollView
    @ViewBuilder
    private func pageContent(height: CGFloat) -> some View {
        switch selectedTab {
        case 0:
            PermissionsView().frame(minHeight: height)
        case 1:
            ActionsView().frame(height: height)
        case 2:
            PreferencesView().frame(minHeight: height)
        default:
            HistoryView().frame(height: height)
        }
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
    
    /// Modal 弹窗
    /// Modal presenter
    @Environment(\.modalPresenter) private var modalPresenter
    
    var body: some View {
        GeometryReader { geometry in
            
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    List(selection: $selectedAction) {
                        ForEach(actions) { action in
                            ActionRow(action: action)
                                .id(action.id.uuidString + "_" + action.displayName)
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
                        
                        Button(action: openAddModal) {
                            Label("添加动作", systemImage: "plus")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .listStyle(InsetListStyle())
                }
                .frame(width: 200, height: geometry.size.height)
                
                Divider()
                
                Group {
                    if let action = selectedAction {
                        ActionDetailView(
                            action: action,
                            onEdit: { selected in
                                selectedAction = selected
                                modalPresenter?.open(title: "编辑动作", data: selected) { ctx in
                                    ActionEditorView(action: ctx.data, onSave: { updatedAction in
                                        ActionManager.shared.updateAction(updatedAction)
                                        refreshActions(selecting: updatedAction.id)
                                        ctx.close()
                                    }, onCancel: { ctx.close() })
                                }
                            },
                            onDelete: { toDelete in
                                deleteAction(toDelete)
                            }
                        )
                        .id(action.id.uuidString + "_" + action.displayName + "_" + String(action.sortOrder))
                    } else {
                        Text("选择一个动作查看详情")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear(perform: ensureSelection)
        .onReceive(NotificationCenter.default.publisher(for: .actionsDidUpdate)) { _ in
            // 当动作更新时刷新列表和详情
            // Refresh list and details when actions are updated
            refreshActions(selecting: selectedAction?.id)
        }
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
    
    /// 打开添加动作弹窗
    /// Open add action modal
    private func openAddModal() {
        modalPresenter?.open(title: "添加动作", data: ()) { ctx in
            ActionEditorView(action: nil, onSave: { newAction in
                ActionManager.shared.addAction(newAction)
                refreshActions(selecting: newAction.id)
                ctx.close()
            }, onCancel: { ctx.close() })
        }
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

/// 偏好设置视图
/// Preferences view
struct PreferencesView: View {

    /// 应用偏好设置
    /// Application preferences storage
    @ObservedObject private var preferences = AppPreferences.shared
    
    /// 更新管理器
    /// Update manager
    @ObservedObject private var updateManager = UpdateManager.shared

    /// 新排除应用的 Bundle ID
    /// Bundle ID for new excluded app
    @State private var newExcludedAppBundleId: String = ""

    /// 合并默认动作的结果提示
    /// Result message of merging default actions
    @State private var mergeResultMessage: String?

    /// Modal 弹窗
    /// Modal presenter
    @Environment(\.modalPresenter) private var modalPresenter

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("偏好设置")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            .padding()
            
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 12) {
                        Label("文本选择", systemImage: "text.cursor")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                        Toggle("开启强制选词", isOn: $preferences.forceSelectionEnabled)
                            .toggleStyle(.switch)

                        Text("启用后，如果常规方式无法读取选中文本，将尝试模拟 Command+C，并读取剪贴板内容获取文本。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .padding(.vertical, 4)

                        Toggle("支持双击选择", isOn: $preferences.doubleClickSelectionEnabled)
                            .toggleStyle(.switch)

                        Text("启用后，双击选择文本时将识别选中的文本并显示工具栏。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if preferences.forceSelectionEnabled {
                            Divider()
                                .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("排除应用")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Button(action: {
                                        newExcludedAppBundleId = ""
                                        modalPresenter?.open(title: "添加排除应用", data: ()) { ctx in
                                            AddExcludedAppView(
                                                bundleId: $newExcludedAppBundleId,
                                                onAdd: {
                                                    addExcludedApp()
                                                    ctx.close()
                                                },
                                                onCancel: {
                                                    newExcludedAppBundleId = ""
                                                    ctx.close()
                                                }
                                            )
                                        }
                                    }) {
                                        Image(systemName: "plus.circle")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("添加排除应用")
                                }

                                Text("在以下应用中将不会使用强制选词功能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if preferences.forceSelectionExcludedApps.isEmpty {
                                    Text("暂无排除的应用")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(preferences.forceSelectionExcludedApps, id: \.self) { bundleId in
                                        HStack {
                                            Text(bundleId)
                                                .font(.caption)
                                                .lineLimit(1)
                                            Spacer()
                                            Button(action: {
                                                removeExcludedApp(bundleId)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.borderless)
                                            .help("删除")
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                // 网络设置
                // Network settings
                VStack(alignment: .leading, spacing: 12) {
                    Label("网络设置", systemImage: "network")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("开启 HTTP 代理", isOn: $preferences.httpProxyEnabled)
                            .toggleStyle(.switch)
                        
                        if preferences.httpProxyEnabled {
                            TextField("例如: http://127.0.0.1:7890", text: $preferences.httpProxyAddress)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Toggle("开启 HTTPS 代理", isOn: $preferences.httpsProxyEnabled)
                            .toggleStyle(.switch)
                        
                        if preferences.httpsProxyEnabled {
                            TextField("例如: http://127.0.0.1:7890", text: $preferences.httpsProxyAddress)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                // 配置管理
                // Configuration management
                VStack(alignment: .leading, spacing: 12) {
                    Label("配置", systemImage: "folder")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("打开配置文件目录以查看或备份您的设置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            updateManager.openConfigDirectory()
                        }) {
                            Label("打开配置文件目录", systemImage: "folder.badge.gear")
                        }
                        .buttonStyle(.bordered)
                        
                        Text("将内置的默认动作合并到您的动作列表中，已存在同名动作时会跳过")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                let added = ActionManager.shared.mergeDefaultActions()
                                mergeResultMessage = added > 0 ? "已合并 \(added) 个默认动作" : "没有需要合并的默认动作"
                            }) {
                                Label("合并默认动作", systemImage: "arrow.triangle.merge")
                            }
                            .buttonStyle(.bordered)
                            
                            if let mergeResultMessage {
                                Text(mergeResultMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                // 应用更新
                // App updates
                VStack(alignment: .leading, spacing: 12) {
                    Label("更新", systemImage: "arrow.down.circle")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("当前版本:")
                                .font(.subheadline)
                            Text(updateManager.currentVersion)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if let latestVersion = updateManager.latestVersion {
                            HStack {
                                Text("最新版本:")
                                    .font(.subheadline)
                                Text(latestVersion.version)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(updateManager.hasUpdate ? .green : .secondary)
                                Spacer()
                            }
                            
                            if updateManager.hasUpdate {
                                Text("发现新版本！")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            } else {
                                Text("您已是最新版本")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let releaseNotes = latestVersion.releaseNotes, !releaseNotes.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                Text("更新说明:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                ScrollView {
                                    Text(releaseNotes)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                .frame(maxHeight: 100)
                            }
                        }
                        
                        if let errorMessage = updateManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                updateManager.checkForUpdates()
                            }) {
                                if updateManager.isCheckingForUpdates {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 16, height: 16)
                                        Text("检查中...")
                                    }
                                } else {
                                    Label("检查更新", systemImage: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(updateManager.isCheckingForUpdates || updateManager.isDownloading)
                            
                            if updateManager.hasUpdate {
                                Button(action: {
                                    updateManager.downloadAndInstallUpdate()
                                }) {
                                    if updateManager.isDownloading {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .frame(width: 16, height: 16)
                                            Text("下载中...")
                                        }
                                    } else {
                                        Label("立即更新", systemImage: "arrow.down.circle.fill")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(updateManager.isDownloading)
                                
                                Button(action: {
                                    updateManager.openDownloadPage()
                                }) {
                                    Label("打开下载页面", systemImage: "safari")
                                }
                                .buttonStyle(.bordered)
                                .help("在浏览器中打开 GitHub 发布页面")
                            }
                        }
                        
                        // 显示下载进度
                        // Show download progress
                        if updateManager.isDownloading {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("下载进度:")
                                        .font(.caption)
                                    Spacer()
                                    Text(String(format: "%.0f%%", updateManager.downloadProgress * 100))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                ProgressView(value: updateManager.downloadProgress)
                            }
                        }
                        
                        Text("注意：更新时会保留您的授权和配置缓存")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func addExcludedApp() {
        let trimmedId = newExcludedAppBundleId.trimmingCharacters(in: .whitespaces)
        guard !trimmedId.isEmpty else { return }
        guard !preferences.forceSelectionExcludedApps.contains(trimmedId) else {
            newExcludedAppBundleId = ""
            return
        }
        preferences.forceSelectionExcludedApps.append(trimmedId)
        newExcludedAppBundleId = ""
    }

    private func removeExcludedApp(_ bundleId: String) {
        preferences.forceSelectionExcludedApps.removeAll { $0 == bundleId }
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
                Text("日志")
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 标题
                // Title
                Text(action.displayName)
                    .font(.title2)
                    .bold()
                
                // 基本信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("基本信息")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(label: "名称", value: action.name)
                        InfoRow(label: "类型", value: action.type.displayName)
                        InfoRow(label: "状态", value: action.isEnabled ? "启用" : "禁用")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .padding(.bottom, 24)
                
                // 匹配条件
                if let pattern = action.matchPattern, !pattern.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("匹配条件")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("正则表达式：\(pattern)")
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .padding(.bottom, 24)
                }
                
                // 参数
                if action.type == .openURL, let url = action.parameters["url"], !url.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("URL 模板")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(url)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .padding(.bottom, 24)
                } else if action.type == .executeScript, let script = action.parameters["script"], !script.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("脚本内容")
                            .font(.headline)
                        
                        ScrollView {
                            Text(script)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 120)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .padding(.bottom, 24)
                    
                    if let jsonPath = action.parameters["jsonPath"], !jsonPath.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("JSON 路径提取")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(jsonPath)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
                    }
                } else if action.type == .http {
                    if let url = action.parameters["url"], !url.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("URL")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(url)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
                    }
                    
                    if let method = action.parameters["method"], !method.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Method")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(method)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
                    }
                    
                    if let headers = action.parameters["headers"], !headers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Headers")
                                .font(.headline)
                            
                            ScrollView {
                                Text(headers)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 60)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
                    }
                    
                    if let body = action.parameters["body"], !body.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Body")
                                .font(.headline)
                            
                            ScrollView {
                                Text(body)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 80)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
                    }
                    
                    if let jsonPath = action.parameters["jsonPath"], !jsonPath.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("JSON 路径提取")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(jsonPath)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 24)
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
                        .padding(.vertical, 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var displayName: String
    @State private var iconName: String
    @State private var type: ActionType
    @State private var isEnabled: Bool
    @State private var matchPattern: String
    @State private var urlParameter: String
    @State private var scriptContent: String
    @State private var httpURL: String
    @State private var httpMethod: String
    @State private var httpHeaders: String
    @State private var httpBody: String
    @State private var jsonPath: String
    
    init(action: ActionItem?, onSave: @escaping (ActionItem) -> Void, onCancel: @escaping () -> Void) {
        self.action = action
        self.onSave = onSave
        self.onCancel = onCancel
        
        _name = State(initialValue: action?.name ?? "")
        _displayName = State(initialValue: action?.displayName ?? "")
        _iconName = State(initialValue: action?.iconName ?? "")
        _type = State(initialValue: action?.type ?? .openURL)
        _isEnabled = State(initialValue: action?.isEnabled ?? true)
        _matchPattern = State(initialValue: action?.matchPattern ?? "")
        
        // 根据动作类型初始化相应的参数
        // Initialize parameters based on action type
        let actionType = action?.type ?? .openURL
        switch actionType {
        case .openURL:
            _urlParameter = State(initialValue: action?.parameters["url"] ?? "")
            _scriptContent = State(initialValue: "")
            _jsonPath = State(initialValue: "")
        case .executeScript:
            _urlParameter = State(initialValue: "")
            _scriptContent = State(initialValue: action?.parameters["script"] ?? "")
            _jsonPath = State(initialValue: action?.parameters["jsonPath"] ?? "")
        case .http:
            _urlParameter = State(initialValue: "")
            _scriptContent = State(initialValue: "")
            _jsonPath = State(initialValue: action?.parameters["jsonPath"] ?? "")
        }
        
        // 初始化 HTTP 特定参数（仅在 HTTP 类型时从 action 读取）
        // Initialize HTTP-specific parameters (only load from action for HTTP type)
        _httpURL = State(initialValue: actionType == .http ? (action?.parameters["url"] ?? "") : "")
        _httpMethod = State(initialValue: actionType == .http ? (action?.parameters["method"] ?? "GET") : "GET")
        _httpHeaders = State(initialValue: actionType == .http ? (action?.parameters["headers"] ?? "") : "")
        _httpBody = State(initialValue: actionType == .http ? (action?.parameters["body"] ?? "") : "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 基本信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("基本信息")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("名称")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入动作名称", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("显示名称")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入显示名称", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("图标（SF 符号名称，留空则显示名称）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("例如: safari", text: $iconName)
                                .textFieldStyle(.roundedBorder)
                            if !iconName.isEmpty {
                                Image(systemName: iconName)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("类型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("类型", selection: $type) {
                            ForEach(ActionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Toggle("启用", isOn: $isEnabled)
                }
                
                // 匹配条件
                VStack(alignment: .leading, spacing: 8) {
                    Text("匹配条件")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("正则表达式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("输入正则表达式", text: $matchPattern)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Text("留空表示匹配所有文本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 参数
                VStack(alignment: .leading, spacing: 8) {
                    Text("参数")
                        .font(.headline)
                    
                    if type == .openURL {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("URL 模板")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("输入 URL", text: $urlParameter)
                                .textFieldStyle(.roundedBorder)
                        }
                        Text("使用 {text} 作为占位符")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if type == .executeScript {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("脚本内容")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Text("JSON 路径提取（可选）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("例如: data.items.0.name", text: $jsonPath)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                            Text("从 JSON 结果中提取指定路径的值，支持数组索引（如 a.0.c）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if type == .http {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("输入 URL", text: $httpURL)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text("使用 {text} 作为选中文本的占位符")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Method")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("Method", selection: $httpMethod) {
                                    Text("GET").tag("GET")
                                    Text("POST").tag("POST")
                                    Text("PUT").tag("PUT")
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Headers (JSON)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                JSONTextEditor(text: $httpHeaders)
                                    .frame(minHeight: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3))
                                    )
                            }
                            Text("例如: {\"Authorization\": \"Bearer token\", \"Content-Type\": \"application/json\"}")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if httpMethod == "POST" || httpMethod == "PUT" {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Body (JSON)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    JSONTextEditor(text: $httpBody)
                                        .frame(minHeight: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.secondary.opacity(0.3))
                                        )
                                }
                                Text("例如: {\"query\": \"{text}\"}")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("JSON 路径提取（可选）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("例如: data.items.0.name", text: $jsonPath)
                                    .font(.system(.body, design: .monospaced))
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text("从 JSON 结果中提取指定路径的值，支持数组索引（如 a.0.c）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .modalBottomActions([
            ModalActionItem(title: "取消", type: .cancel, onClick: onCancel),
            ModalActionItem(title: "保存", type: .primary, onClick: { saveAction() })
        ])
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
            if !jsonPath.isEmpty {
                parameters["jsonPath"] = jsonPath
            }
        case .http:
            if !httpURL.isEmpty {
                parameters["url"] = httpURL
            }
            parameters["method"] = httpMethod
            if !httpHeaders.isEmpty {
                parameters["headers"] = httpHeaders
            }
            if !httpBody.isEmpty {
                parameters["body"] = httpBody
            }
            if !jsonPath.isEmpty {
                parameters["jsonPath"] = jsonPath
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
            shortcut: action?.shortcut,
            iconName: iconName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : iconName.trimmingCharacters(in: .whitespaces),
            sortOrder: action?.sortOrder ?? 0
        )
        
        onSave(newAction)
        onCancel()
    }
}

private struct JSONTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.delegate = context.coordinator
        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else { return }
        textView.string = text
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

/// 添加排除应用视图
/// Add excluded app view
struct AddExcludedAppView: View {
    @Binding var bundleId: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输入应用的 Bundle ID")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("例如: com.apple.Terminal", text: $bundleId)
                .textFieldStyle(.roundedBorder)

            Text("您可以在应用包的 Info.plist 中找到 Bundle ID")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .modalBottomActions([
            ModalActionItem(title: "取消", type: .cancel, onClick: onCancel),
            ModalActionItem(title: "添加", type: .primary, onClick: onAdd, isDisabled: bundleId.trimmingCharacters(in: .whitespaces).isEmpty)
        ])
    }
}
