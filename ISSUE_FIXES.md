# 问题修复说明 / Issue Fixes Summary

本文档详细说明了针对以下四个问题的修复方案。

This document details the fixes for the following four issues.

---

## 问题 1: DMG 显示已损坏 / Issue 1: DMG Shows as Damaged

### 问题描述 / Problem Description

通过 release 下载的 DMG 文件，安装后显示应用已损坏，无法打开。

DMG files downloaded from releases show the app as "damaged" after installation and cannot be opened.

### 根本原因 / Root Cause

构建流程中使用了 `CODE_SIGNING_REQUIRED=NO` 和 `CODE_SIGNING_ALLOWED=NO`，导致应用完全未签名。macOS 从互联网下载的未签名应用会被 Gatekeeper 标记为已损坏。

The build workflow used `CODE_SIGNING_REQUIRED=NO` and `CODE_SIGNING_ALLOWED=NO`, resulting in completely unsigned applications. macOS Gatekeeper marks unsigned apps downloaded from the internet as "damaged".

### 解决方案 / Solution

1. **修改构建配置**：将 `CODE_SIGN_IDENTITY` 设置为 `"-"`（ad-hoc 签名）而不是完全禁用签名。

   **Modified build configuration**: Set `CODE_SIGN_IDENTITY` to `"-"` (ad-hoc signing) instead of completely disabling signing.

2. **为所有构建添加签名步骤**：
   - Universal binary: 在合并后使用 `codesign --force --deep --sign -` 签名
   - ARM64 build: 在创建 DMG 前签名
   - x86_64 build: 在创建 DMG 前签名

   **Added signing steps for all builds**:
   - Universal binary: Sign after merging with `codesign --force --deep --sign -`
   - ARM64 build: Sign before creating DMG
   - x86_64 build: Sign before creating DMG

3. **更新发布说明**：添加了如果仍然提示"已损坏"时的解决方法：
   ```bash
   xattr -cr /Applications/Selecto.app
   ```
   然后右键点击应用并选择"打开"。

   **Updated release notes**: Added workaround if "damaged" warning still appears:
   ```bash
   xattr -cr /Applications/Selecto.app
   ```
   Then right-click the app and select "Open".

### 技术细节 / Technical Details

Ad-hoc 签名（`codesign -s -`）提供基本的代码签名，虽然不能通过 Apple 公证，但能防止 macOS 将应用标记为已损坏。这对于开源项目是一个很好的折中方案，因为完整的签名和公证需要付费的 Apple Developer 账号。

Ad-hoc signing (`codesign -s -`) provides basic code signing. While it cannot be notarized by Apple, it prevents macOS from marking the app as damaged. This is a good compromise for open source projects since full signing and notarization require a paid Apple Developer account.

### 修改的文件 / Modified Files
- `.github/workflows/build-release.yml`

---

## 问题 2: 关闭窗口后程序仍在 Dock 中 / Issue 2: App Remains in Dock After Closing Window

### 问题描述 / Problem Description

点击"显示控制面板"打开主程序后，点击关闭按钮时，程序图标仍然保留在 Dock 中，而不是隐藏到后台。

After clicking "Show Control Panel" to open the main program, clicking the close button keeps the program icon in the Dock instead of hiding it to the background.

### 根本原因 / Root Cause

应用在显示控制面板时切换到 `.regular` 激活策略（在 Dock 中显示），但关闭窗口时没有切换回 `.accessory` 策略（不在 Dock 中显示）。

The app switches to `.regular` activation policy (visible in Dock) when showing the control panel, but doesn't switch back to `.accessory` policy (hidden from Dock) when the window is closed.

### 解决方案 / Solution

1. **实现 NSWindowDelegate**：为 AppDelegate 添加 NSWindowDelegate 协议实现。

   **Implemented NSWindowDelegate**: Added NSWindowDelegate protocol implementation to AppDelegate.

2. **设置窗口代理**：在 `showControlPanel()` 方法中设置主窗口的 delegate。

   **Set window delegate**: Set the main window's delegate in `showControlPanel()` method.

3. **处理窗口关闭事件**：实现 `windowShouldClose(_:)` 方法：
   - 调用 `window.orderOut(nil)` 隐藏窗口
   - 调用 `NSApp.setActivationPolicy(.accessory)` 从 Dock 中移除图标
   - 返回 `false` 阻止窗口实际关闭（保持窗口对象存在，下次可以重新显示）

   **Handle window close event**: Implemented `windowShouldClose(_:)` method:
   - Call `window.orderOut(nil)` to hide the window
   - Call `NSApp.setActivationPolicy(.accessory)` to remove icon from Dock
   - Return `false` to prevent actual window closure (keep window object for reuse)

### 技术细节 / Technical Details

```swift
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }
}
```

这种方法确保了：
- 用户体验：点击关闭按钮时，应用从 Dock 中消失，回到后台运行
- 性能：窗口对象不会被销毁，下次显示时不需要重新创建
- 状态保持：窗口的状态（如当前标签页）会被保留

This approach ensures:
- User experience: Clicking close button removes app from Dock and returns to background operation
- Performance: Window object is not destroyed, no need to recreate on next show
- State preservation: Window state (like current tab) is preserved

### 修改的文件 / Modified Files
- `Selecto/Selecto/AppDelegate.swift`

---

## 问题 3: AppleScript 授权应该在授权面板中 / Issue 3: AppleScript Authorization Should Be in Permissions Panel

### 问题描述 / Problem Description

Apple Script 在执行时会弹出授权框，用户体验不好。应该将其放在授权面板里面让用户主动授权。

AppleScript shows an authorization dialog when executed, which is poor user experience. It should be in the authorization panel for users to grant permission proactively.

### 根本原因 / Root Cause

虽然 Info.plist 中已经有 `NSAppleEventsUsageDescription` 描述，但授权界面（PermissionsView）中没有显示自动化权限选项，用户无法提前知道这个权限的存在和用途。

Although `NSAppleEventsUsageDescription` exists in Info.plist, the Permissions view doesn't show the automation permission option, so users cannot proactively understand its existence and purpose.

### 解决方案 / Solution

1. **扩展 PermissionType 枚举**：添加 `.automation` 权限类型。

   **Extended PermissionType enum**: Added `.automation` permission type.

2. **添加权限检查方法**：在 PermissionManager 中添加 `checkAutomationPermission()` 方法。
   - 注意：由于 macOS 不提供直接检测 AppleScript 权限的 API，此方法总是返回 true
   - 实际的授权弹窗会在首次使用 AppleScript 时由系统自动触发

   **Added permission check method**: Added `checkAutomationPermission()` in PermissionManager.
   - Note: Since macOS doesn't provide a direct API to detect AppleScript permission, this method always returns true
   - The actual authorization dialog will be triggered by the system on first AppleScript use

3. **更新系统偏好设置链接**：添加自动化权限的系统偏好设置 URL。

   **Updated system preferences link**: Added system preferences URL for automation permission.

4. **更新授权界面**：在 PermissionsView 中添加自动化权限卡片，说明其用途（用于从 Chrome 等浏览器获取选中文本）。

   **Updated permissions UI**: Added automation permission card in PermissionsView, explaining its purpose (for getting selected text from browsers like Chrome).

### 技术细节 / Technical Details

权限卡片内容：
- **标题**：自动化 (AppleScript)
- **描述**：允许 Selecto 使用 AppleScript 获取文本（Chrome 等浏览器）
- **图标**：terminal
- **操作**：打开系统偏好设置中的"隐私与安全性 -> 自动化"面板

Permission card details:
- **Title**: 自动化 (AppleScript)
- **Description**: 允许 Selecto 使用 AppleScript 获取文本（Chrome 等浏览器）
- **Icon**: terminal
- **Action**: Opens "Privacy & Security -> Automation" in System Preferences

### 修改的文件 / Modified Files
- `Selecto/Selecto/Managers/PermissionManager.swift`
- `Selecto/Selecto/Views/ContentView.swift`

---

## 问题 4: 强制复制需要验证是否真正获取到文本 / Issue 4: Forced Copy Needs to Validate Text Capture

### 问题描述 / Problem Description

通过执行"复制到剪贴板"获取用户选择的数据时，需要判断复制操作是否真正获取到文本。用户可能只是拖动鼠标但没有选择文本，此时不应该把用户之前的剪贴板内容作为当次选择的内容。

When getting user-selected data through "copy to clipboard", need to verify if the copy operation actually captured text. Users might just drag the mouse without selecting text, and shouldn't use previous clipboard content as the current selection.

### 根本原因 / Root Cause

原来的 AppleScript 实现：
1. 保存当前剪贴板内容
2. 模拟 Cmd+C
3. 读取剪贴板
4. 恢复原剪贴板
5. 返回读取到的内容

如果用户只是拖动鼠标没有选择文本，Cmd+C 不会改变剪贴板，但脚本仍然会返回旧的剪贴板内容，导致误判。

Original AppleScript implementation:
1. Save current clipboard
2. Simulate Cmd+C
3. Read clipboard
4. Restore original clipboard
5. Return the read content

If user just drags mouse without selecting text, Cmd+C won't change clipboard, but the script still returns old clipboard content, causing false positives.

### 解决方案 / Solution

改进 AppleScript 逻辑，比较复制前后的剪贴板内容：

Improved AppleScript logic to compare clipboard content before and after copy:

```applescript
set previousClipboard to (the clipboard as record)
set previousText to ""
try
    set previousText to (the clipboard as text)
end try
tell application "System Events"
    keystroke "c" using {command down}
end tell
delay 0.05
set newText to ""
try
    set newText to (the clipboard as text)
end try
set the clipboard to previousClipboard
if newText is equal to previousText then
    return ""
else
    return newText
end if
```

### 工作流程 / Workflow

1. **保存原始剪贴板**：保存完整的剪贴板记录（支持多种格式）

   **Save original clipboard**: Save complete clipboard record (supports multiple formats)

2. **获取原始文本**：尝试读取剪贴板中的文本内容（可能为空）

   **Get original text**: Try to read text content from clipboard (may be empty)

3. **执行复制操作**：模拟 Cmd+C

   **Execute copy**: Simulate Cmd+C

4. **获取新文本**：读取复制后的剪贴板文本内容

   **Get new text**: Read clipboard text after copy

5. **恢复原始剪贴板**：恢复用户的原始剪贴板内容

   **Restore original clipboard**: Restore user's original clipboard content

6. **比较并返回**：
   - 如果新文本等于旧文本，说明没有选择新内容，返回空字符串
   - 如果不同，返回新文本

   **Compare and return**:
   - If new text equals old text, no new selection was made, return empty string
   - If different, return the new text

### 技术细节 / Technical Details

使用 `try-end try` 块来安全处理剪贴板可能为空或不包含文本的情况。

Use `try-end try` blocks to safely handle cases where clipboard may be empty or doesn't contain text.

空字符串返回后，`getSelectedTextViaForcedCopy()` 方法会返回 nil，这样就不会错误地触发工具栏显示。

When empty string is returned, the `getSelectedTextViaForcedCopy()` method returns nil, preventing false toolbar triggers.

### 修改的文件 / Modified Files
- `Selecto/Selecto/SelectionMonitor.swift`

---

## 测试建议 / Testing Recommendations

### 测试问题 1：DMG 安装 / Test Issue 1: DMG Installation

1. 从 GitHub Releases 下载 DMG 文件
2. 双击打开 DMG
3. 拖动 Selecto.app 到 Applications 文件夹
4. 尝试打开应用
5. 如果提示"已损坏"，执行 `xattr -cr /Applications/Selecto.app`
6. 右键点击应用，选择"打开"
7. 验证应用正常启动

1. Download DMG from GitHub Releases
2. Double-click to open DMG
3. Drag Selecto.app to Applications folder
4. Try to open the app
5. If "damaged" warning appears, run `xattr -cr /Applications/Selecto.app`
6. Right-click the app and select "Open"
7. Verify the app launches normally

### 测试问题 2：窗口隐藏 / Test Issue 2: Window Hiding

1. 启动 Selecto
2. 点击状态栏图标，选择"显示控制面板"
3. 验证 Dock 中出现 Selecto 图标
4. 点击窗口的关闭按钮（红色按钮）
5. 验证：
   - 窗口关闭
   - Dock 中的 Selecto 图标消失
   - 状态栏图标仍然存在
   - 应用仍在后台运行
6. 再次点击"显示控制面板"，验证窗口重新出现且保持之前的状态

1. Launch Selecto
2. Click status bar icon, select "Show Control Panel"
3. Verify Selecto icon appears in Dock
4. Click window close button (red button)
5. Verify:
   - Window closes
   - Selecto icon disappears from Dock
   - Status bar icon remains
   - App still runs in background
6. Click "Show Control Panel" again, verify window reappears with previous state

### 测试问题 3：自动化权限 / Test Issue 3: Automation Permission

1. 打开 Selecto 控制面板
2. 切换到"授权"标签页
3. 验证显示三个权限卡片：
   - 辅助功能
   - 屏幕录制
   - 自动化 (AppleScript)
4. 点击"自动化 (AppleScript)"的"授权"按钮
5. 验证系统偏好设置打开到"隐私与安全性 -> 自动化"面板
6. 在 Chrome 中选择文本，触发 AppleScript 执行
7. 验证系统显示授权请求对话框（首次）
8. 授予权限后，验证后续操作不再显示对话框

1. Open Selecto control panel
2. Switch to "Authorization" tab
3. Verify three permission cards are shown:
   - Accessibility
   - Screen Recording
   - Automation (AppleScript)
4. Click "Authorize" button for "Automation (AppleScript)"
5. Verify System Preferences opens to "Privacy & Security -> Automation" panel
6. Select text in Chrome to trigger AppleScript execution
7. Verify system shows authorization request dialog (first time)
8. After granting permission, verify subsequent operations don't show dialog

### 测试问题 4：剪贴板验证 / Test Issue 4: Clipboard Validation

测试需要在启用"强制选词"功能的情况下进行：

Testing requires "Force Selection" to be enabled:

1. **测试场景 1：正常选择文本**
   - 复制一段文本 "AAA" 到剪贴板
   - 在支持 AX API 的应用（如 Notes）中选择文本 "BBB"
   - 验证工具栏显示，选择的文本是 "BBB"
   - 验证剪贴板内容仍是 "AAA"（原始内容被恢复）

   **Test Scenario 1: Normal text selection**
   - Copy text "AAA" to clipboard
   - Select text "BBB" in an app that supports AX API (like Notes)
   - Verify toolbar shows, selected text is "BBB"
   - Verify clipboard content is still "AAA" (original content restored)

2. **测试场景 2：仅拖动鼠标不选择文本**
   - 复制一段文本 "AAA" 到剪贴板
   - 在应用中点击并拖动鼠标，但不选择任何文本
   - 验证工具栏不显示
   - 验证剪贴板内容仍是 "AAA"

   **Test Scenario 2: Just drag mouse without selecting text**
   - Copy text "AAA" to clipboard
   - Click and drag mouse in app without selecting any text
   - Verify toolbar doesn't show
   - Verify clipboard content is still "AAA"

3. **测试场景 3：选择后取消选择**
   - 复制一段文本 "AAA" 到剪贴板
   - 选择一段文本然后立即点击其他地方取消选择
   - 验证工具栏不显示
   - 验证剪贴板内容仍是 "AAA"

   **Test Scenario 3: Select then deselect**
   - Copy text "AAA" to clipboard
   - Select text then immediately click elsewhere to deselect
   - Verify toolbar doesn't show
   - Verify clipboard content is still "AAA"

4. **测试场景 4：连续选择不同文本**
   - 复制一段文本 "AAA" 到剪贴板
   - 选择文本 "BBB"，验证工具栏显示 "BBB"
   - 选择文本 "CCC"，验证工具栏更新为 "CCC"
   - 验证剪贴板内容仍是 "AAA"

   **Test Scenario 4: Select different text consecutively**
   - Copy text "AAA" to clipboard
   - Select text "BBB", verify toolbar shows "BBB"
   - Select text "CCC", verify toolbar updates to "CCC"
   - Verify clipboard content is still "AAA"

---

## 总结 / Summary

这四个问题的修复涵盖了：
1. **构建和分发**：改进了代码签名流程，提升了应用的可靠性和用户体验
2. **用户界面**：改善了窗口管理行为，使应用更好地集成到 macOS 系统中
3. **权限管理**：完善了权限授权流程，让用户能够主动了解和管理权限
4. **功能可靠性**：修复了文本选择检测的误判问题，提高了功能的准确性

These four fixes cover:
1. **Build and Distribution**: Improved code signing process for better app reliability and user experience
2. **User Interface**: Improved window management behavior for better macOS system integration
3. **Permission Management**: Enhanced permission authorization flow for proactive user control
4. **Feature Reliability**: Fixed false positives in text selection detection for improved accuracy

所有修改都遵循了最小化改动的原则，只修改了必要的文件和代码，确保了代码的稳定性和可维护性。

All modifications follow the principle of minimal changes, only modifying necessary files and code, ensuring code stability and maintainability.
