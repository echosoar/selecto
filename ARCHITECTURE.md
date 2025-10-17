# Architecture | 架构文档

[English](#english) | [中文](#中文)

---

## 中文

### 概览

Selecto 是一个采用经典 MVC 架构模式的 macOS 应用程序，结合了 AppKit 和 SwiftUI 框架。

### 核心组件

```
┌─────────────────────────────────────────────────────────┐
│                      AppDelegate                         │
│                   (应用程序入口点)                         │
└────────────┬────────────────────────────────┬───────────┘
             │                                │
             ▼                                ▼
    ┌────────────────┐              ┌─────────────────┐
    │ SelectionMonitor│              │PermissionManager│
    │  (选择监控器)    │              │  (权限管理器)    │
    └────────┬───────┘              └─────────────────┘
             │
             │ 检测到文本选择
             │ (Text Selection Detected)
             ▼
    ┌────────────────────┐
    │  ActionManager     │
    │   (动作管理器)      │
    └─────────┬──────────┘
              │
              │ 获取匹配的动作
              │ (Get Matching Actions)
              ▼
    ┌─────────────────────────┐
    │ ToolbarWindowController │
    │   (工具栏窗口控制器)       │
    └──────────┬──────────────┘
               │
               │ 显示工具栏
               │ (Show Toolbar)
               ▼
    ┌──────────────────┐
    │   ToolbarView    │
    │   (工具栏视图)    │
    └──────────────────┘
               │
               │ 用户点击动作
               │ (User Clicks Action)
               ▼
    ┌──────────────────┐
    │  ActionExecutor  │
    │   (动作执行器)    │
    └──────────────────┘
```

### 组件详解

#### 1. AppDelegate

**职责：**
- 应用程序生命周期管理
- 初始化核心组件
- 管理状态栏菜单
- 协调各组件之间的通信

**关键方法：**
```swift
func applicationDidFinishLaunching(_ aNotification: Notification)
func applicationWillTerminate(_ aNotification: Notification)
```

#### 2. SelectionMonitor

**职责：**
- 监控系统级文本选择事件
- 使用 Accessibility API 获取选中的文本
- 通过代理模式通知文本选择变化

**工作原理：**
1. 监听鼠标和键盘事件
2. 定期检查文本选择状态
3. 使用 AXUIElement 获取选中的文本和位置
4. 通知代理对象

**性能优化：**
- 使用定时器避免过度检查
- 缓存当前选择以避免重复处理
- 异步处理以不阻塞主线程

#### 3. ToolbarWindowController

**职责：**
- 管理浮动工具栏窗口
- 计算工具栏位置
- 处理工具栏显示和隐藏
- 实现自动隐藏机制

**窗口特性：**
- 无边框窗口
- 浮动在所有窗口之上
- 半透明背景
- 自动跟随鼠标位置

#### 4. ToolbarView

**职责：**
- 渲染工具栏按钮
- 处理用户交互
- 动态更新按钮列表

**UI 设计：**
- 使用 NSStackView 布局
- 圆角、阴影等视觉效果
- 响应式按钮大小

#### 5. ActionManager

**职责：**
- 管理用户配置的动作列表
- 持久化动作配置
- 根据文本匹配动作
- 提供 CRUD 操作接口

**数据持久化：**
- 使用 JSON 格式存储
- 保存在 Application Support 目录
- 支持导入导出

#### 6. ActionExecutor

**职责：**
- 执行不同类型的动作
- 处理 URL 模板替换
- 执行系统操作（复制、打开 URL 等）
- 显示执行结果通知

**支持的动作类型：**
- 复制到剪贴板
- 搜索
- 翻译
- 打开 URL
- 执行脚本
- 自定义动作

#### 7. PermissionManager

**职责：**
- 检查系统权限状态
- 请求必要的权限
- 引导用户授权
- 提供权限状态查询

**需要的权限：**
- Accessibility（辅助功能）
- Screen Recording（屏幕录制，macOS 10.15+）

#### 8. SettingsWindowController & SettingsView

**职责：**
- 提供用户配置界面
- 使用 SwiftUI 构建现代化 UI
- 支持动作的增删改查
- 实时预览配置效果

### 数据流

#### 文本选择流程

```
用户选择文本
    │
    ▼
SelectionMonitor 检测到选择
    │
    ▼
获取选中的文本和位置
    │
    ▼
ActionManager 查找匹配的动作
    │
    ▼
ToolbarWindowController 显示工具栏
    │
    ▼
用户点击动作按钮
    │
    ▼
ActionExecutor 执行动作
    │
    ▼
显示结果（复制、打开 URL 等）
```

#### 配置保存流程

```
用户修改设置
    │
    ▼
SettingsView 更新 UI 状态
    │
    ▼
ActionManager 保存到内存
    │
    ▼
持久化到磁盘 (JSON)
```

### 设计模式

#### 1. 单例模式 (Singleton)

```swift
class ActionManager {
    static let shared = ActionManager()
    private init() {}
}
```

**使用场景：**
- ActionManager
- ActionExecutor
- PermissionManager

**优点：**
- 全局唯一实例
- 简化访问方式
- 集中管理状态

#### 2. 代理模式 (Delegate)

```swift
protocol SelectionMonitorDelegate: AnyObject {
    func didDetectTextSelection(text: String, bounds: CGRect)
    func didCancelTextSelection()
}
```

**使用场景：**
- SelectionMonitor ← AppDelegate
- ToolbarView ← ToolbarWindowController

**优点：**
- 松耦合
- 灵活的事件通知
- 易于测试

#### 3. MVC 模式

- **Model**: ActionItem, 配置数据
- **View**: ToolbarView, SettingsView
- **Controller**: AppDelegate, ToolbarWindowController, SettingsWindowController

#### 4. MVVM 模式 (SwiftUI 部分)

SettingsView 使用 SwiftUI 的 MVVM 模式：
- Model: ActionItem
- View: SettingsView
- ViewModel: 通过 @State 和 @Binding 实现

### 线程模型

#### 主线程

- UI 更新
- 用户交互处理
- 窗口管理

#### 后台线程

- 文件 I/O（配置读写）
- 正则表达式匹配
- 脚本执行

### 性能优化策略

#### 1. 延迟加载

- 设置窗口仅在需要时创建
- 工具栏按需显示

#### 2. 缓存

- 缓存当前选择的文本
- 缓存正则表达式编译结果

#### 3. 事件节流

- 使用定时器限制检查频率
- 避免过度触发

#### 4. 内存管理

- 使用 weak 引用避免循环引用
- 及时释放不需要的资源

### 安全考虑

#### 1. 权限隔离

- 仅请求必要的权限
- 清晰说明权限用途

#### 2. 数据保护

- 配置文件存储在用户目录
- 不收集用户数据

#### 3. 代码注入防护

- 谨慎处理用户输入
- 正则表达式异常处理

### 扩展性

#### 添加新的动作类型

1. 在 ActionType 枚举中添加新类型
2. 在 ActionExecutor 中实现执行逻辑
3. 在 SettingsView 中添加配置 UI

#### 添加新的匹配条件

1. 扩展 ActionItem 模型
2. 修改 matches(text:) 方法
3. 更新 UI 配置界面

---

## English

### Overview

Selecto is a macOS application built with the classic MVC architecture pattern, combining AppKit and SwiftUI frameworks.

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                      AppDelegate                         │
│                  (Application Entry)                     │
└────────────┬────────────────────────────────┬───────────┘
             │                                │
             ▼                                ▼
    ┌────────────────┐              ┌─────────────────┐
    │ SelectionMonitor│              │PermissionManager│
    │                │              │                 │
    └────────┬───────┘              └─────────────────┘
             │
             │ Text Selection Detected
             │
             ▼
    ┌────────────────────┐
    │  ActionManager     │
    │                    │
    └─────────┬──────────┘
              │
              │ Get Matching Actions
              │
              ▼
    ┌─────────────────────────┐
    │ ToolbarWindowController │
    │                         │
    └──────────┬──────────────┘
               │
               │ Show Toolbar
               │
               ▼
    ┌──────────────────┐
    │   ToolbarView    │
    │                  │
    └──────────────────┘
               │
               │ User Clicks Action
               │
               ▼
    ┌──────────────────┐
    │  ActionExecutor  │
    │                  │
    └──────────────────┘
```

### Component Details

#### 1. AppDelegate

**Responsibilities:**
- Application lifecycle management
- Initialize core components
- Manage status bar menu
- Coordinate communication between components

**Key Methods:**
```swift
func applicationDidFinishLaunching(_ aNotification: Notification)
func applicationWillTerminate(_ aNotification: Notification)
```

#### 2. SelectionMonitor

**Responsibilities:**
- Monitor system-wide text selection events
- Use Accessibility API to get selected text
- Notify text selection changes via delegate pattern

**How It Works:**
1. Listen to mouse and keyboard events
2. Periodically check text selection state
3. Use AXUIElement to get selected text and position
4. Notify delegate object

**Performance Optimization:**
- Use timer to avoid excessive checking
- Cache current selection to avoid duplicate processing
- Asynchronous processing to avoid blocking main thread

#### 3. ToolbarWindowController

**Responsibilities:**
- Manage floating toolbar window
- Calculate toolbar position
- Handle toolbar show/hide
- Implement auto-hide mechanism

**Window Features:**
- Borderless window
- Float above all windows
- Semi-transparent background
- Auto-follow mouse position

#### 4. ToolbarView

**Responsibilities:**
- Render toolbar buttons
- Handle user interactions
- Dynamically update button list

**UI Design:**
- Use NSStackView for layout
- Rounded corners, shadows, etc.
- Responsive button sizes

#### 5. ActionManager

**Responsibilities:**
- Manage user-configured action list
- Persist action configuration
- Match actions based on text
- Provide CRUD operation interface

**Data Persistence:**
- Store in JSON format
- Save in Application Support directory
- Support import/export

#### 6. ActionExecutor

**Responsibilities:**
- Execute different types of actions
- Handle URL template replacement
- Execute system operations (copy, open URL, etc.)
- Show execution result notifications

**Supported Action Types:**
- Copy to clipboard
- Search
- Translate
- Open URL
- Execute script
- Custom action

#### 7. PermissionManager

**Responsibilities:**
- Check system permission status
- Request necessary permissions
- Guide user authorization
- Provide permission status query

**Required Permissions:**
- Accessibility
- Screen Recording (macOS 10.15+)

#### 8. SettingsWindowController & SettingsView

**Responsibilities:**
- Provide user configuration interface
- Build modern UI with SwiftUI
- Support CRUD operations for actions
- Real-time preview of configuration effects

### Data Flow

#### Text Selection Flow

```
User selects text
    │
    ▼
SelectionMonitor detects selection
    │
    ▼
Get selected text and position
    │
    ▼
ActionManager finds matching actions
    │
    ▼
ToolbarWindowController shows toolbar
    │
    ▼
User clicks action button
    │
    ▼
ActionExecutor executes action
    │
    ▼
Show result (copy, open URL, etc.)
```

#### Configuration Save Flow

```
User modifies settings
    │
    ▼
SettingsView updates UI state
    │
    ▼
ActionManager saves to memory
    │
    ▼
Persist to disk (JSON)
```

### Design Patterns

#### 1. Singleton Pattern

```swift
class ActionManager {
    static let shared = ActionManager()
    private init() {}
}
```

**Usage:**
- ActionManager
- ActionExecutor
- PermissionManager

**Advantages:**
- Globally unique instance
- Simplified access
- Centralized state management

#### 2. Delegate Pattern

```swift
protocol SelectionMonitorDelegate: AnyObject {
    func didDetectTextSelection(text: String, bounds: CGRect)
    func didCancelTextSelection()
}
```

**Usage:**
- SelectionMonitor ← AppDelegate
- ToolbarView ← ToolbarWindowController

**Advantages:**
- Loose coupling
- Flexible event notification
- Easy to test

#### 3. MVC Pattern

- **Model**: ActionItem, configuration data
- **View**: ToolbarView, SettingsView
- **Controller**: AppDelegate, ToolbarWindowController, SettingsWindowController

#### 4. MVVM Pattern (SwiftUI Part)

SettingsView uses SwiftUI's MVVM pattern:
- Model: ActionItem
- View: SettingsView
- ViewModel: Implemented via @State and @Binding

### Threading Model

#### Main Thread

- UI updates
- User interaction handling
- Window management

#### Background Threads

- File I/O (configuration read/write)
- Regular expression matching
- Script execution

### Performance Optimization Strategies

#### 1. Lazy Loading

- Settings window created only when needed
- Toolbar shown on demand

#### 2. Caching

- Cache currently selected text
- Cache compiled regular expressions

#### 3. Event Throttling

- Use timer to limit check frequency
- Avoid excessive triggering

#### 4. Memory Management

- Use weak references to avoid retain cycles
- Release unneeded resources promptly

### Security Considerations

#### 1. Permission Isolation

- Request only necessary permissions
- Clearly explain permission purposes

#### 2. Data Protection

- Configuration files stored in user directory
- No user data collection

#### 3. Code Injection Protection

- Carefully handle user input
- Exception handling for regular expressions

### Extensibility

#### Adding New Action Types

1. Add new type in ActionType enum
2. Implement execution logic in ActionExecutor
3. Add configuration UI in SettingsView

#### Adding New Match Conditions

1. Extend ActionItem model
2. Modify matches(text:) method
3. Update UI configuration interface
