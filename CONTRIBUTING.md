# Contributing to Selecto | 为 Selecto 做贡献

[English](#english) | [中文](#中文)

---

## 中文

感谢您对 Selecto 项目的关注！我们欢迎各种形式的贡献。

### 如何贡献

#### 报告问题

如果您发现了 bug 或有功能建议：

1. 在 [Issues](https://github.com/echosoar/selecto/issues) 页面搜索是否已有相关问题
2. 如果没有，创建一个新的 issue
3. 提供尽可能详细的信息：
   - 问题描述
   - 复现步骤
   - 期望行为
   - 实际行为
   - macOS 版本
   - Selecto 版本

#### 提交代码

1. **Fork 仓库**
   ```bash
   # 在 GitHub 上点击 Fork 按钮
   ```

2. **克隆您的 Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/selecto.git
   cd selecto
   ```

3. **创建分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

4. **进行更改**
   - 遵循代码规范（见下文）
   - 添加必要的注释（中英双语）
   - 确保代码可以编译通过

5. **提交更改**
   ```bash
   git add .
   git commit -m "描述您的更改"
   ```

6. **推送到您的 Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **创建 Pull Request**
   - 在 GitHub 上打开您的 Fork
   - 点击 "New Pull Request"
   - 填写 PR 描述

### 代码规范

#### Swift 代码风格

- 使用 4 个空格缩进
- 每行不超过 120 个字符
- 使用有意义的变量和函数名
- 遵循 Swift API 设计指南

#### 注释规范

所有公开的类、方法和重要逻辑都应有中英双语注释：

```swift
/// 动作管理器
/// Action manager
/// 负责管理和存储用户配置的动作
/// Responsible for managing and storing user-configured actions
class ActionManager {
    // ...
}
```

#### 文件结构

每个 Swift 文件应遵循以下结构：

```swift
//
//  FileName.swift
//  Selecto
//
//  Created by Your Name on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation

// MARK: - Type Definition

// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods
```

### 项目结构

```
Selecto/
├── AppDelegate.swift           # 应用程序入口
├── SelectionMonitor.swift      # 文本选择监控
├── ToolbarWindowController.swift  # 工具栏控制器
├── ToolbarView.swift           # 工具栏视图
├── SettingsWindowController.swift # 设置窗口控制器
├── Models/                     # 数据模型
│   └── ActionItem.swift
├── Managers/                   # 管理器类
│   ├── ActionManager.swift
│   ├── ActionExecutor.swift
│   └── PermissionManager.swift
└── Views/                      # 视图组件
    └── SettingsView.swift
```

### 添加新功能

如果您要添加新功能：

1. 在 issue 中讨论您的想法
2. 确保功能符合项目目标
3. 编写清晰的代码和注释
4. 更新相关文档

### 测试

在提交 PR 前，请确保：

- [ ] 代码可以编译通过
- [ ] 应用可以正常启动
- [ ] 新功能正常工作
- [ ] 没有引入新的 bug
- [ ] 性能没有明显下降

### 文档

如果您的更改影响用户使用：

- 更新 README.md
- 更新 GUIDE.md
- 必要时添加示例

---

## English

Thank you for your interest in the Selecto project! We welcome contributions of all kinds.

### How to Contribute

#### Reporting Issues

If you find a bug or have a feature request:

1. Search [Issues](https://github.com/echosoar/selecto/issues) to see if it's already reported
2. If not, create a new issue
3. Provide as much detail as possible:
   - Problem description
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - macOS version
   - Selecto version

#### Contributing Code

1. **Fork the repository**
   ```bash
   # Click the Fork button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/selecto.git
   cd selecto
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

4. **Make changes**
   - Follow code style guidelines (see below)
   - Add necessary comments (bilingual Chinese/English)
   - Ensure code compiles

5. **Commit changes**
   ```bash
   git add .
   git commit -m "Describe your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Open your fork on GitHub
   - Click "New Pull Request"
   - Fill in PR description

### Code Style

#### Swift Code Style

- Use 4 spaces for indentation
- Lines should not exceed 120 characters
- Use meaningful variable and function names
- Follow Swift API Design Guidelines

#### Comment Guidelines

All public classes, methods, and important logic should have bilingual comments:

```swift
/// 动作管理器
/// Action manager
/// 负责管理和存储用户配置的动作
/// Responsible for managing and storing user-configured actions
class ActionManager {
    // ...
}
```

#### File Structure

Each Swift file should follow this structure:

```swift
//
//  FileName.swift
//  Selecto
//
//  Created by Your Name on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Foundation

// MARK: - Type Definition

// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods
```

### Project Structure

```
Selecto/
├── AppDelegate.swift           # Application entry point
├── SelectionMonitor.swift      # Text selection monitoring
├── ToolbarWindowController.swift  # Toolbar controller
├── ToolbarView.swift           # Toolbar view
├── SettingsWindowController.swift # Settings window controller
├── Models/                     # Data models
│   └── ActionItem.swift
├── Managers/                   # Manager classes
│   ├── ActionManager.swift
│   ├── ActionExecutor.swift
│   └── PermissionManager.swift
└── Views/                      # View components
    └── SettingsView.swift
```

### Adding New Features

If you want to add a new feature:

1. Discuss your idea in an issue
2. Ensure the feature aligns with project goals
3. Write clear code and comments
4. Update relevant documentation

### Testing

Before submitting a PR, ensure:

- [ ] Code compiles
- [ ] App launches properly
- [ ] New features work correctly
- [ ] No new bugs introduced
- [ ] No significant performance degradation

### Documentation

If your changes affect user experience:

- Update README.md
- Update GUIDE.md
- Add examples if necessary

### Questions?

Feel free to ask questions in issues or discussions.

We appreciate your contributions!
