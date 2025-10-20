//
//  ToolbarView.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa

/// 工具栏视图代理协议
/// Toolbar view delegate protocol
protocol ToolbarViewDelegate: AnyObject {
    /// 点击动作按钮
    /// Action button clicked
    func didClickAction(_ action: ActionItem, selectedText: String)
}

/// 工具栏视图
/// Toolbar view
/// 显示动作按钮的实际视图
/// Actual view that displays action buttons
class ToolbarView: NSView {
    
    // MARK: - Properties
    
    /// 代理对象
    /// Delegate object
    weak var delegate: ToolbarViewDelegate?
    
    /// 当前选中的文本
    /// Currently selected text
    private var selectedText: String = ""
    
    /// 主堆栈视图
    /// Main stack view
    private var mainStackView: NSStackView!
    
    /// 按钮堆栈视图
    /// Button stack view
    private var buttonStackView: NSStackView!
    
    /// 状态视图容器
    /// Container for loading state
    private var statusStackView: NSStackView!
    
    /// 进度指示器
    /// Spinner indicator
    private var progressIndicator: NSProgressIndicator!
    
    /// 状态文本
    /// Status label
    private var statusLabel: NSTextField!
    
    /// 结果展示堆栈
    /// Stack for script output rows
    private var resultsStackView: NSStackView!
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Public Methods
    
    /// 更新动作列表
    /// Update action list
    /// - Parameters:
    ///   - actions: 动作列表 / Action list
    ///   - selectedText: 选中的文本 / Selected text
    func updateActions(_ actions: [ActionItem], selectedText: String) {
        self.selectedText = selectedText
        
        // 清除现有按钮
        // Clear existing buttons
        clearStatus()
        buttonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新按钮
        // Add new buttons
        for action in actions {
            let button = createActionButton(for: action)
            buttonStackView.addArrangedSubview(button)
        }
    }
    
    /// 显示脚本执行中的状态
    /// Show loading state while executing script
    /// - Parameter message: 状态消息 / Status message
    func showLoading(message: String) {
        statusLabel.stringValue = message
        statusStackView.isHidden = false
        progressIndicator.startAnimation(nil)
        clearResults()
    }
    
    /// 隐藏加载状态
    /// Hide loading state
    func hideLoading() {
        progressIndicator.stopAnimation(nil)
        statusStackView.isHidden = true
    }
    
    /// 展示脚本输出
    /// Display script output lines
    /// - Parameter lines: 输出行 / Output lines
    func showScriptOutput(_ lines: [String]) {
        let contentLines = lines.isEmpty ? ["脚本执行完成，但没有输出"] : lines
        populateResults(with: contentLines, isError: false)
    }
    
    /// 展示错误消息
    /// Display error message
    /// - Parameter message: 错误内容 / Error message
    func showError(_ message: String) {
        populateResults(with: [message], isError: true)
    }
    
    // MARK: - Private Methods
    
    /// 设置视图
    /// Setup view
    private func setupView() {
        wantsLayer = true
        
        // 设置背景
        // Setup background
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        mainStackView = NSStackView()
        mainStackView.orientation = .vertical
        mainStackView.spacing = 10
        mainStackView.alignment = .leading
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        
        buttonStackView = NSStackView()
        buttonStackView.orientation = .horizontal
        buttonStackView.spacing = 8
        buttonStackView.alignment = .centerY
        buttonStackView.distribution = .gravityAreas
        mainStackView.addArrangedSubview(buttonStackView)
        
        statusStackView = NSStackView()
        statusStackView.orientation = .horizontal
        statusStackView.spacing = 6
        statusStackView.alignment = .centerY
        statusStackView.isHidden = true
        
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isDisplayedWhenStopped = false
        statusStackView.addArrangedSubview(progressIndicator)
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail
        statusStackView.addArrangedSubview(statusLabel)
        
        mainStackView.addArrangedSubview(statusStackView)
        
        resultsStackView = NSStackView()
        resultsStackView.orientation = .vertical
        resultsStackView.spacing = 6
        resultsStackView.alignment = .leading
        resultsStackView.isHidden = true
        mainStackView.addArrangedSubview(resultsStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    /// 创建动作按钮
    /// Create action button
    /// - Parameter action: 动作项 / Action item
    /// - Returns: 按钮 / Button
    private func createActionButton(for action: ActionItem) -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .rounded
        button.title = action.displayName
        button.target = self
        button.action = #selector(actionButtonClicked(_:))
        button.tag = action.id.hashValue
        
        // 保存动作引用
        // Save action reference
        objc_setAssociatedObject(button, &AssociatedKeys.action, action, .OBJC_ASSOCIATION_RETAIN)
        
        return button
    }
    
    /// 清除状态和结果
    /// Clear status and results views
    private func clearStatus() {
        hideLoading()
        clearResults()
    }
    
    private func clearResults() {
        resultsStackView.arrangedSubviews.forEach { view in
            resultsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        resultsStackView.isHidden = true
    }
    
    private func populateResults(with lines: [String], isError: Bool) {
        hideLoading()
        clearResults()
        let limitedLines = Array(lines.prefix(10))
        for line in limitedLines {
            let row = createResultRow(text: line, isError: isError)
            resultsStackView.addArrangedSubview(row)
        }
        resultsStackView.isHidden = false
    }
    
    private func createResultRow(text: String, isError: Bool) -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.alignment = .centerY
        container.spacing = 8
        
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = isError ? NSColor.systemRed : NSColor.labelColor
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.allowsDefaultTighteningForTruncation = true
        container.addArrangedSubview(label)
        
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        container.addArrangedSubview(spacer)
        
        let copyButton: NSButton
        if let symbol = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "复制") {
            copyButton = NSButton(image: symbol, target: self, action: #selector(copyResult(_:)))
        } else {
            copyButton = NSButton(title: "复制", target: self, action: #selector(copyResult(_:)))
        }
        copyButton.isBordered = false
        copyButton.toolTip = "复制"
        copyButton.contentTintColor = NSColor.secondaryLabelColor
        copyButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        objc_setAssociatedObject(copyButton, &AssociatedKeys.resultText, text, .OBJC_ASSOCIATION_RETAIN)
        container.addArrangedSubview(copyButton)
        
        return container
    }
    
    @objc private func copyResult(_ sender: NSButton) {
        guard let text = objc_getAssociatedObject(sender, &AssociatedKeys.resultText) as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// 动作按钮点击处理
    /// Action button click handler
    @objc private func actionButtonClicked(_ sender: NSButton) {
        guard let action = objc_getAssociatedObject(sender, &AssociatedKeys.action) as? ActionItem else {
            return
        }
        
        delegate?.didClickAction(action, selectedText: selectedText)
    }
}

// MARK: - Associated Keys

/// 关联键
/// Associated keys
private struct AssociatedKeys {
    static var action: UInt8 = 0
    static var resultText: UInt8 = 0
}
