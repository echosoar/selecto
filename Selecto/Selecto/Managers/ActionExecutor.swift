//
//  ActionExecutor.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa

/// 动作执行结果
/// Action execution result
enum ActionExecutionResult {
    case urlOpened
    case scriptOutput([String])
    case failure(String)
}

/// 动作执行器
/// Action executor
/// 负责执行各种类型的动作
/// Responsible for executing various types of actions
class ActionExecutor {
    
    // MARK: - Singleton
    
    /// 单例实例
    /// Singleton instance
    static let shared = ActionExecutor()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 执行动作
    /// Execute action
    /// - Parameters:
    ///   - action: 要执行的动作 / Action to execute
    ///   - text: 选中的文本 / Selected text
    func execute(_ action: ActionItem, with text: String, completion: @escaping (ActionExecutionResult) -> Void) {
        switch action.type {
        case .openURL:
            openURL(text, parameters: action.parameters)
            DispatchQueue.main.async {
                completion(.urlOpened)
            }
        case .executeScript:
            executeScript(text, parameters: action.parameters, completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    /// 打开 URL
    /// Open URL
    /// - Parameters:
    ///   - text: 文本 / Text
    ///   - parameters: 参数 / Parameters
    private func openURL(_ text: String, parameters: [String: String]) {
        // 如果文本本身是 URL，直接打开
        // If text itself is a URL, open it directly
        if let url = URL(string: text), url.scheme != nil {
            NSWorkspace.shared.open(url)
            return
        }
        
        // 否则使用模板
        // Otherwise use template
        if let urlTemplate = parameters["url"] {
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
            let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: encodedText)
            
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// 执行脚本
    /// Execute script
    /// - Parameters:
    ///   - text: 输入文本 / Input text
    ///   - parameters: 参数 / Parameters
    private func executeScript(_ text: String, parameters: [String: String], completion: @escaping (ActionExecutionResult) -> Void) {
        if let script = parameters["script"], !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let scriptURL = try prepareTemporaryScript(from: script, with: text)
                runScript(at: scriptURL, inputText: text, deleteAfterRun: true, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(.failure("脚本保存失败: \(error.localizedDescription)"))
                }
            }
            return
        }
        
        if let path = parameters["path"], !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let fileURL = URL(fileURLWithPath: path)
            runScript(at: fileURL, inputText: text, deleteAfterRun: false, completion: completion)
            return
        }
        
        DispatchQueue.main.async {
            completion(.failure("未配置脚本"))
        }
    }
    
    private func prepareTemporaryScript(from script: String, with text: String) throws -> URL {
        let sanitizedText = shellEscaped(text)
        var processedScript = script.replacingOccurrences(of: "{text}", with: sanitizedText)
        if !processedScript.hasSuffix("\n") {
            processedScript.append("\n")
        }
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("selecto-script-\(UUID().uuidString).sh")
        try processedScript.write(to: fileURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)
        return fileURL
    }
    
    private func runScript(at url: URL, inputText: String, deleteAfterRun: Bool, completion: @escaping (ActionExecutionResult) -> Void) {
        let process = Process()
        if deleteAfterRun {
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [url.path, inputText]
        } else {
            if url.pathExtension.isEmpty {
                process.executableURL = url
                process.arguments = [inputText]
            } else {
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = [url.path, inputText]
            }
        }
        
        var environment = ProcessInfo.processInfo.environment
        environment["SELECTO_TEXT"] = inputText
        process.environment = environment
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        process.terminationHandler = { proc in
            if deleteAfterRun {
                try? FileManager.default.removeItem(at: url)
            }
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            stdoutPipe.fileHandleForReading.closeFile()
            stderrPipe.fileHandleForReading.closeFile()
            let outputString = String(data: stdoutData, encoding: .utf8) ?? ""
            let errorString = String(data: stderrData, encoding: .utf8) ?? ""
            let exitCode = proc.terminationStatus
            DispatchQueue.main.async {
                if exitCode == 0 {
                    let lines = outputString
                        .components(separatedBy: CharacterSet.newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    completion(.scriptOutput(lines))
                } else {
                    let message = errorString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if message.isEmpty {
                        completion(.failure("脚本执行失败，退出码 \(exitCode)"))
                    } else {
                        completion(.failure(message))
                    }
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
            } catch {
                if deleteAfterRun {
                    try? FileManager.default.removeItem(at: url)
                }
                DispatchQueue.main.async {
                    completion(.failure("脚本启动失败: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func shellEscaped(_ text: String) -> String {
        let escaped = text.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
}
