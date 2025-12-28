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
                runScript(at: scriptURL, inputText: text, deleteAfterRun: true, jsonPath: parameters["jsonPath"], completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(.failure("脚本保存失败: \(error.localizedDescription)"))
                }
            }
            return
        }
        
        if let path = parameters["path"], !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let fileURL = URL(fileURLWithPath: path)
            runScript(at: fileURL, inputText: text, deleteAfterRun: false, jsonPath: parameters["jsonPath"], completion: completion)
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
    
    private func runScript(at url: URL, inputText: String, deleteAfterRun: Bool, jsonPath: String?, completion: @escaping (ActionExecutionResult) -> Void) {
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
                    // 尝试提取 JSON 路径
                    // Try to extract JSON path
                    if let path = jsonPath, !path.isEmpty, !stdoutData.isEmpty {
                        let processedLines = self.processResponseData(stdoutData, jsonPath: path)
                        completion(.scriptOutput(processedLines))
                    } else {
                        let lines = outputString
                            .components(separatedBy: CharacterSet.newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        completion(.scriptOutput(lines))
                    }
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
        
        // 替换 URL 中的 {text} 占位符 (URL 编码)
        // Replace {text} placeholder in URL (URL encode)
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = urlTemplate.replacingOccurrences(of: "{text}", with: encodedText)
        
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
        
        // JSON 转义文本
        // JSON escape text for headers and body
        let jsonEscapedText = jsonEscape(text)
        
        // 添加请求头
        // Add headers
        if let headersJSON = parameters["headers"], !headersJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let headersString = headersJSON.replacingOccurrences(of: "{text}", with: jsonEscapedText)
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
                let bodyString = bodyJSON.replacingOccurrences(of: "{text}", with: jsonEscapedText)
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
            
            if let data = data, !data.isEmpty {
                let jsonPath = parameters["jsonPath"]
                let processedLines = self.processResponseData(data, jsonPath: jsonPath)
                responseLines.append(contentsOf: processedLines)
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    completion(.httpResponse(responseLines))
                } else {
                    let errorDetail = responseLines.dropFirst().joined(separator: "\n")
                    completion(.failure("HTTP \(httpResponse.statusCode): \(errorDetail)"))
                }
            }
        }
        
        task.resume()
    }
    
    /// JSON 转义文本
    /// Escape text for JSON
    private func jsonEscape(_ text: String) -> String {
        // 使用 JSONSerialization 来正确转义字符串
        // Use JSONSerialization to properly escape the string
        if let jsonData = try? JSONSerialization.data(withJSONObject: [text]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // 移除数组的方括号，只保留转义后的字符串（包括引号）
            // Remove array brackets, keep only the escaped string (with quotes)
            let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let inner = trimmed.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                // 移除字符串的引号，因为在 JSON 模板中已经有引号
                // Remove quotes from string, as they already exist in JSON template
                if inner.hasPrefix("\"") && inner.hasSuffix("\"") {
                    return String(inner.dropFirst().dropLast())
                }
                return inner
            }
        }
        // 如果失败，手动转义
        // Manual escape if JSONSerialization fails
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    /// 处理 HTTP 响应数据
    /// Process HTTP response data
    private func processResponseData(_ data: Data, jsonPath: String? = nil) -> [String] {
        guard let responseString = String(data: data, encoding: .utf8) else {
            return []
        }
        
        // 尝试格式化 JSON
        // Try to format JSON
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
            // 如果提供了 JSON 路径，提取指定值
            // If JSON path is provided, extract the specified value
            if let path = jsonPath, !path.isEmpty {
                if let extractedValue = extractValueFromJSON(jsonObject, path: path) {
                    return formatExtractedValue(extractedValue)
                } else {
                    return ["路径 '\(path)' 未找到或无效"]
                }
            }
            
            // 否则返回格式化的完整 JSON
            // Otherwise return formatted full JSON
            if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                // 保留所有行以维持 JSON 格式
                // Keep all lines to maintain JSON formatting
                return prettyString.components(separatedBy: .newlines)
            }
        }
        
        // 返回原始响应，保留所有行
        // Return raw response, preserving all lines
        return responseString.components(separatedBy: .newlines)
    }
    
    /// 从 JSON 对象中提取指定路径的值
    /// Extract value from JSON object using dot notation path
    /// - Parameters:
    ///   - json: JSON 对象 / JSON object
    ///   - path: 路径（如 "a.b.c" 或 "a.0.c"）/ Path (e.g., "a.b.c" or "a.0.c")
    /// - Returns: 提取的值 / Extracted value
    private func extractValueFromJSON(_ json: Any, path: String) -> Any? {
        let components = path.components(separatedBy: ".")
        var current: Any = json
        
        for component in components {
            // 检查是否为数组索引
            // Check if it's an array index
            if let index = Int(component) {
                guard let array = current as? [Any], index >= 0, index < array.count else {
                    return nil
                }
                current = array[index]
            } else {
                // 字典键
                // Dictionary key
                guard let dict = current as? [String: Any], let value = dict[component] else {
                    return nil
                }
                current = value
            }
        }
        
        return current
    }
    
    /// 格式化提取的值为字符串数组
    /// Format extracted value to string array
    private func formatExtractedValue(_ value: Any) -> [String] {
        if let string = value as? String {
            return [string]
        } else if let number = value as? NSNumber {
            return [number.stringValue]
        } else if let bool = value as? Bool {
            return [bool ? "true" : "false"]
        } else if let array = value as? [Any] {
            // 格式化数组
            // Format array
            if let jsonData = try? JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString.components(separatedBy: .newlines)
            }
            return ["[数组, \(array.count) 项]"]
        } else if let dict = value as? [String: Any] {
            // 格式化字典
            // Format dictionary
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString.components(separatedBy: .newlines)
            }
            return ["[对象]"]
        }
        return [String(describing: value)]
    }
}
