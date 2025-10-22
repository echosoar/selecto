# 鼠标拖拽 Bug 修复说明 / Mouse Drag Bug Fix

## 问题描述 / Problem Description

### 中文
当用户不选择任何文本，只是按下鼠标拖拽后再释放时，工具栏仍会弹出。这是因为在某些应用中，当辅助功能API无法获取选中文本时，系统会使用强制复制功能（模拟 Cmd+C）来获取文本。如果用户只是拖拽鼠标但没有选中任何文本，系统会读取到剪贴板中之前的内容，导致工具栏错误地显示。

### English
When a user drags the mouse without selecting any text, the toolbar still appears. This happens because in some applications, when the Accessibility API fails to get selected text, the system uses forced copy (simulating Cmd+C) to retrieve text. If the user just drags the mouse without selecting anything, the system reads the old clipboard content, causing the toolbar to appear incorrectly.

## 解决方案 / Solution

### 中文
修改了 `SelectionMonitor.swift` 中的 `getSelectedTextViaForcedCopy()` 方法，实现了以下逻辑：

1. **复制前**：读取并保存当前剪贴板中的文本内容
2. **执行复制**：模拟执行 Cmd+C 复制操作
3. **复制后**：再次读取剪贴板中的文本内容
4. **内容比较**：对比复制前后的剪贴板内容
   - 如果内容相同：说明没有选中新文本，返回 nil（不显示工具栏）
   - 如果内容不同：说明确实选中了新文本，返回该文本（显示工具栏）
5. **恢复剪贴板**：将剪贴板内容恢复为原始内容

这个过程非常快速（约 50 毫秒），不会影响用户的正常复制操作。

### English
Modified the `getSelectedTextViaForcedCopy()` method in `SelectionMonitor.swift` with the following logic:

1. **Before Copy**: Read and save the current clipboard text content
2. **Execute Copy**: Simulate Cmd+C copy operation
3. **After Copy**: Read the clipboard text content again
4. **Compare Content**: Compare clipboard content before and after
   - If content is the same: No new text was selected, return nil (don't show toolbar)
   - If content is different: New text was selected, return the text (show toolbar)
5. **Restore Clipboard**: Restore the clipboard to its original content

This process is very fast (about 50ms) and won't interfere with the user's normal copy operations.

## 技术细节 / Technical Details

### AppleScript 改进 / AppleScript Improvements

```applescript
# 之前的实现 / Previous Implementation
set previousClipboard to (the clipboard as record)
tell application "System Events"
    keystroke "c" using {command down}
end tell
delay 0.05
set selectedText to (the clipboard as text)
set the clipboard to previousClipboard
return selectedText

# 新的实现 / New Implementation
set previousClipboard to (the clipboard as record)
set previousText to ""
try
    set previousText to (the clipboard as text)
end try
tell application "System Events"
    keystroke "c" using {command down}
end tell
delay 0.05
set selectedText to ""
try
    set selectedText to (the clipboard as text)
end try
set the clipboard to previousClipboard
return {previousText, selectedText}
```

### Swift 代码改进 / Swift Code Improvements

```swift
// 解析返回的列表：{previousText, selectedText}
// Parse the returned list: {previousText, selectedText}
guard descriptor.numberOfItems == 2,
      let previousTextDescriptor = descriptor.atIndex(1),
      let selectedTextDescriptor = descriptor.atIndex(2) else {
    return nil
}

let previousText = previousTextDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
let selectedText = selectedTextDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

// 如果剪贴板内容在复制前后相同，说明没有选中新文本
// If clipboard content is the same before and after copy, no new text was selected
if previousText == selectedText {
    return nil
}
```

## 测试场景 / Test Scenarios

### 场景 1：空剪贴板 + 无选择 / Scenario 1: Empty Clipboard + No Selection
- **操作**：剪贴板为空，用户拖拽鼠标但不选择文本
- **结果**：`previousText = ""`, `selectedText = ""` → 相同 → 不显示工具栏 ✓

### 场景 2：有内容剪贴板 + 无选择 / Scenario 2: Non-empty Clipboard + No Selection
- **操作**：剪贴板有内容 "old"，用户拖拽鼠标但不选择文本
- **结果**：`previousText = "old"`, `selectedText = "old"` → 相同 → 不显示工具栏 ✓

### 场景 3：有内容剪贴板 + 有选择 / Scenario 3: Non-empty Clipboard + New Selection
- **操作**：剪贴板有内容 "old"，用户选择新文本 "new"
- **结果**：`previousText = "old"`, `selectedText = "new"` → 不同 → 显示工具栏 ✓

### 场景 4：空剪贴板 + 有选择 / Scenario 4: Empty Clipboard + New Selection
- **操作**：剪贴板为空，用户选择新文本 "new"
- **结果**：`previousText = ""`, `selectedText = "new"` → 不同 → 显示工具栏 ✓

## 性能影响 / Performance Impact

- **延迟**：约 50 毫秒（由 AppleScript 中的 `delay 0.05` 决定）
- **用户体验**：几乎无感知，不会影响正常使用
- **资源消耗**：最小，仅在强制复制功能启用时才会执行此逻辑

## 修改的文件 / Modified Files

- `Selecto/Selecto/SelectionMonitor.swift`

## 兼容性 / Compatibility

此修复向后兼容，不会影响现有功能。对于不使用强制复制功能的用户（`forceSelectionEnabled = false`），此代码路径不会被执行。

This fix is backward compatible and doesn't affect existing functionality. For users who don't use forced selection (`forceSelectionEnabled = false`), this code path won't be executed.
