//
//  UpdateManager.swift
//  Selecto
//
//  Created by GitHub Copilot on 2025/10/24.
//

import Foundation
import AppKit

/// 更新信息
/// Update information
struct UpdateInfo: Codable {
    let version: String
    let downloadURL: String
    let releaseNotes: String?
    let assets: [ReleaseAsset]
    
    enum CodingKeys: String, CodingKey {
        case version = "tag_name"
        case downloadURL = "html_url"
        case releaseNotes = "body"
        case assets
    }
}

/// 发布资源
/// Release asset
struct ReleaseAsset: Codable {
    let name: String
    let browserDownloadURL: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}

/// 更新管理器
/// Update manager
/// 负责检查和下载应用更新
/// Responsible for checking and downloading app updates
class UpdateManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = UpdateManager()
    
    private init() {}
    
    // MARK: - Published Properties
    
    /// 是否正在检查更新
    /// Whether checking for updates
    @Published var isCheckingForUpdates = false
    
    /// 最新版本信息
    /// Latest version information
    @Published var latestVersion: UpdateInfo?
    
    /// 错误信息
    /// Error message
    @Published var errorMessage: String?
    
    /// 是否正在下载
    /// Whether downloading
    @Published var isDownloading = false
    
    /// 下载进度 (0.0 到 1.0)
    /// Download progress (0.0 to 1.0)
    @Published var downloadProgress: Double = 0.0
    
    /// 是否有可用更新
    /// Whether update is available
    var hasUpdate: Bool {
        guard let latestVersion = latestVersion else { return false }
        return isNewerVersion(latestVersion.version, than: currentVersion)
    }
    
    // MARK: - Properties
    
    /// GitHub 仓库信息
    /// GitHub repository information
    private let repoOwner = "echosoar"
    private let repoName = "selecto"
    
    /// 当前应用版本
    /// Current app version
    var currentVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "0.0.0"
    }
    
    // MARK: - Public Methods
    
    /// 检查更新
    /// Check for updates
    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        errorMessage = nil
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的 URL / Invalid URL"
            isCheckingForUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isCheckingForUpdates = false
                
                if let error = error {
                    self?.errorMessage = "检查更新失败 / Check failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "未收到数据 / No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let updateInfo = try decoder.decode(UpdateInfo.self, from: data)
                    self?.latestVersion = updateInfo
                    self?.errorMessage = nil
                } catch {
                    self?.errorMessage = "解析更新信息失败 / Parse failed: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    /// 打开下载页面
    /// Open download page
    func openDownloadPage() {
        guard let latestVersion = latestVersion else { return }
        
        if let url = URL(string: latestVersion.downloadURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// 下载并安装更新
    /// Download and install update
    func downloadAndInstallUpdate() {
        guard let latestVersion = latestVersion else { return }
        guard !isDownloading else { return }
        
        // 获取合适的 DMG 资源
        // Get appropriate DMG asset
        guard let dmgAsset = selectAppropriateAsset(from: latestVersion.assets) else {
            errorMessage = "未找到合适的安装包 / No suitable installer found"
            return
        }
        
        guard let downloadURL = URL(string: dmgAsset.browserDownloadURL) else {
            errorMessage = "无效的下载链接 / Invalid download URL"
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        errorMessage = nil
        
        // 下载到临时目录
        // Download to temporary directory
        let downloadTask = URLSession.shared.downloadTask(with: downloadURL) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    self?.errorMessage = "下载失败 / Download failed: \(error.localizedDescription)"
                    return
                }
                
                guard let localURL = localURL else {
                    self?.errorMessage = "下载文件未找到 / Downloaded file not found"
                    return
                }
                
                // 将文件移动到下载目录
                // Move file to Downloads directory
                let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                let destinationURL = downloadsURL.appendingPathComponent(dmgAsset.name)
                
                do {
                    // 删除已存在的文件
                    // Remove existing file if any
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // 移动文件
                    // Move file
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    
                    // 打开 DMG 文件
                    // Open DMG file
                    NSWorkspace.shared.open(destinationURL)
                    
                    // 显示成功消息
                    // Show success message
                    self?.showDownloadCompleteAlert(fileName: dmgAsset.name)
                    
                } catch {
                    self?.errorMessage = "保存文件失败 / Failed to save file: \(error.localizedDescription)"
                }
            }
        }
        
        // 监控下载进度
        // Monitor download progress
        let observation = downloadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
            }
        }
        
        downloadTask.resume()
        
        // 保持观察者直到下载完成
        // Keep observer until download completes
        objc_setAssociatedObject(downloadTask, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }
    
    /// 选择合适的安装包资源
    /// Select appropriate installer asset
    private func selectAppropriateAsset(from assets: [ReleaseAsset]) -> ReleaseAsset? {
        // 检测当前系统架构
        // Detect current system architecture
        #if arch(arm64)
        // Apple Silicon - 优先选择 ARM64 或 Universal
        // Apple Silicon - prefer ARM64 or Universal
        if let arm64Asset = assets.first(where: { $0.name.lowercased().contains("arm64") && $0.name.hasSuffix(".dmg") }) {
            return arm64Asset
        }
        if let universalAsset = assets.first(where: { $0.name.lowercased().contains("universal") && $0.name.hasSuffix(".dmg") }) {
            return universalAsset
        }
        #elseif arch(x86_64)
        // Intel - 优先选择 x86_64 或 Universal
        // Intel - prefer x86_64 or Universal
        if let x86Asset = assets.first(where: { $0.name.lowercased().contains("x86_64") && $0.name.hasSuffix(".dmg") }) {
            return x86Asset
        }
        if let universalAsset = assets.first(where: { $0.name.lowercased().contains("universal") && $0.name.hasSuffix(".dmg") }) {
            return universalAsset
        }
        #endif
        
        // 如果没有找到特定架构的，返回任何 DMG 文件
        // If no specific architecture found, return any DMG file
        return assets.first(where: { $0.name.hasSuffix(".dmg") })
    }
    
    /// 显示下载完成提示
    /// Show download complete alert
    private func showDownloadCompleteAlert(fileName: String) {
        let alert = NSAlert()
        alert.messageText = "下载完成 / Download Complete"
        alert.informativeText = "安装包已下载到下载目录并已打开。请按照提示完成安装。\n\nThe installer has been downloaded to Downloads folder and opened. Please follow the prompts to complete installation.\n\n文件名 / File: \(fileName)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定 / OK")
        alert.runModal()
    }
    
    /// 打开配置文件目录
    /// Open configuration directory
    func openConfigDirectory() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Selecto", isDirectory: true)
        
        // 确保目录存在
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        // 打开目录
        // Open directory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: appFolder.path)
    }
    
    // MARK: - Private Methods
    
    /// 比较版本号
    /// Compare version numbers
    /// - Parameters:
    ///   - version1: 版本1 / Version 1
    ///   - version2: 版本2 / Version 2
    /// - Returns: 版本1是否比版本2新 / Whether version 1 is newer than version 2
    private func isNewerVersion(_ version1: String, than version2: String) -> Bool {
        // 移除 'v' 前缀（如果存在）
        // Remove 'v' prefix if exists
        let v1 = version1.lowercased().hasPrefix("v") ? String(version1.dropFirst()) : version1
        let v2 = version2.lowercased().hasPrefix("v") ? String(version2.dropFirst()) : version2
        
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0
            
            if v1Value > v2Value {
                return true
            } else if v1Value < v2Value {
                return false
            }
        }
        
        return false
    }
}
