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
    
    enum CodingKeys: String, CodingKey {
        case version = "tag_name"
        case downloadURL = "html_url"
        case releaseNotes = "body"
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
