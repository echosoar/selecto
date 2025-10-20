# 修复说明 / Fix Summary

## 问题 1: 多显示器位置计算不正确 / Issue 1: Incorrect Position Calculation with Multiple Monitors

### 问题描述 / Problem Description
当使用多个显示器时，选中文本后工具栏的位置计算不正确。

When using multiple monitors, the toolbar position calculation is incorrect after selecting text.

### 根本原因 / Root Cause
macOS 使用两种不同的坐标系统：
- **辅助功能 API (Accessibility API)**: 原点 (0,0) 在主显示器的左上角，Y 轴向下递增
- **AppKit**: 原点 (0,0) 在主显示器的左下角，Y 轴向上递增

之前的代码在多显示器场景下无法正确转换这两种坐标系统。

macOS uses two different coordinate systems:
- **Accessibility API**: Origin (0,0) is at the top-left of the primary screen, with Y increasing downward
- **AppKit**: Origin (0,0) is at the bottom-left of the primary screen, with Y increasing upward

The previous code failed to correctly convert between these coordinate systems in multi-monitor scenarios.

### 解决方案 / Solution
修改了 `SelectionMonitor.swift` 中的 `normalizeBounds` 函数，使用主显示器的高度进行坐标转换：

Modified the `normalizeBounds` function in `SelectionMonitor.swift` to use the primary screen's height for coordinate conversion:

```swift
let convertedY = primaryScreen.frame.height - bounds.origin.y - bounds.height
```

这种方法在单显示器和多显示器配置下都能正确工作。

This approach works correctly in both single-monitor and multi-monitor configurations.

### 修改的文件 / Modified Files
- `Selecto/Selecto/SelectionMonitor.swift`

---

## 问题 2: 动作编辑后不自动刷新 / Issue 2: Action Panel Doesn't Auto-Refresh After Editing

### 问题描述 / Problem Description
在设置中编辑并保存动作后，工具栏不会自动刷新显示更新后的动作。

After editing and saving an action in settings, the toolbar doesn't automatically refresh to show the updated action.

### 根本原因 / Root Cause
缺少动作更新的通知机制，工具栏无法知道动作配置已更改。

There was no notification mechanism for action updates, so the toolbar couldn't know when action configurations changed.

### 解决方案 / Solution
实现了一个完整的通知系统：

Implemented a complete notification system:

1. **在 ActionManager 中添加通知** / **Added Notification in ActionManager**:
   - 定义了 `actionsDidUpdate` 通知
   - 在添加、更新、删除或重排序动作时发送通知
   
   - Defined `actionsDidUpdate` notification
   - Posts notification when actions are added, updated, deleted, or reordered

2. **在 AppDelegate 中监听通知** / **Listen for Notifications in AppDelegate**:
   - 订阅 `actionsDidUpdate` 通知
   - 保存当前选择的文本和边界
   - 收到通知时，如果有选中文本，重新评估匹配的动作并刷新工具栏
   
   - Subscribes to `actionsDidUpdate` notification
   - Saves current selected text and bounds
   - When notified, re-evaluates matching actions and refreshes toolbar if text is selected

### 修改的文件 / Modified Files
- `Selecto/Selecto/Managers/ActionManager.swift`
- `Selecto/Selecto/AppDelegate.swift`

---

## 测试建议 / Testing Recommendations

### 测试多显示器位置 / Testing Multi-Monitor Position
1. 连接第二个显示器
2. 在不同显示器上选择文本
3. 验证工具栏出现在选中文本的正确位置

1. Connect a second monitor
2. Select text on different monitors
3. Verify toolbar appears at the correct position above selected text

### 测试动作刷新 / Testing Action Refresh
1. 选择一段文本以显示工具栏
2. 保持文本选中状态，打开设置面板
3. 编辑一个动作（修改名称、参数等）
4. 保存修改
5. 验证工具栏自动更新显示修改后的动作

1. Select text to display the toolbar
2. Keep text selected and open settings panel
3. Edit an action (modify name, parameters, etc.)
4. Save changes
5. Verify toolbar automatically updates with modified action

---

## 技术细节 / Technical Details

### 坐标系统转换 / Coordinate System Conversion
```swift
// 辅助功能坐标 -> AppKit 坐标
// Accessibility coordinates -> AppKit coordinates
let convertedY = primaryScreen.frame.height - bounds.origin.y - bounds.height
```

### 通知机制 / Notification Mechanism
```swift
// 发送通知 / Post notification
NotificationCenter.default.post(name: .actionsDidUpdate, object: nil)

// 接收通知 / Receive notification
NotificationCenter.default.addObserver(
    self,
    selector: #selector(actionsDidUpdate),
    name: .actionsDidUpdate,
    object: nil
)
```
