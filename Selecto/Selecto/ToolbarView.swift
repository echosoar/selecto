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
    
    /// 按钮堆栈视图
    /// Button stack view
    private var stackView: NSStackView!
    
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
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新按钮
        // Add new buttons
        for action in actions {
            let button = createActionButton(for: action)
            stackView.addArrangedSubview(button)
        }
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
        
        // 创建堆栈视图
        // Create stack view
        stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.alignment = .centerY
        stackView.distribution = .gravityAreas
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        // 设置约束
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
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
    static var action = "action"
}
