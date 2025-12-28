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
    case httpResponse([String])
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
        case .http:
            executeHTTPRequest(text, parameters: action.parameters, completion: completion)
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
    
    /// 执行 HTTP 请求
    /// Execute HTTP request
    /// - Parameters:
    ///   - text: 输入文本 / Input text
    ///   - parameters: 参数 / Parameters
    private func executeHTTPRequest(_ text: String, parameters: [String: String], completion: @escaping (ActionExecutionResult) -> Void) {
        guard let urlTemplate = parameters["url"], !urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                completion(.failure("未配置 URL"))
            }
            return
        }
        
        // 替换 URL 中的 {text} 占位符
        // Replace {text} placeholder in URL
        let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: text)
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(.failure("无效的 URL: \(urlString)"))
            }
            return
        }
        
        // 获取 HTTP 方法，默认为 GET
        // Get HTTP method, default to GET
        let method = parameters["method"]?.uppercased() ?? "GET"
        
        // 创建请求
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        
        // 添加请求头
        // Add headers
        if let headersJSON = parameters["headers"], !headersJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let headersString = headersJSON.replacingOccurrences(of: "{text}", with: text)
                if let headersData = headersString.data(using: .utf8),
                   let headers = try JSONSerialization.jsonObject(with: headersData) as? [String: String] {
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure("请求头 JSON 解析失败: \(error.localizedDescription)"))
                }
                return
            }
        }
        
        // 添加请求体（POST/PUT）
        // Add request body (POST/PUT)
        if method == "POST" || method == "PUT" {
            if let bodyJSON = parameters["body"], !bodyJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let bodyString = bodyJSON.replacingOccurrences(of: "{text}", with: text)
                if let bodyData = bodyString.data(using: .utf8) {
                    request.httpBody = bodyData
                    if request.value(forHTTPHeaderField: "Content-Type") == nil {
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                }
            }
        }
        
        // 发起请求
        // Execute request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure("请求失败: \(error.localizedDescription)"))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure("无效的响应"))
                }
                return
            }
            
            var responseLines: [String] = []
            responseLines.append("状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                // 尝试格式化 JSON
                // Try to format JSON
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    responseLines.append(contentsOf: prettyString.components(separatedBy: .newlines).filter { !$0.isEmpty })
                } else {
                    responseLines.append(contentsOf: responseString.components(separatedBy: .newlines).filter { !$0.isEmpty })
                }
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    completion(.httpResponse(responseLines))
                } else {
                    completion(.failure("HTTP \(httpResponse.statusCode): " + (responseLines.dropFirst().joined(separator: "\n"))))
                }
            }
        }
        
        task.resume()
    }
}
