# Quick Start | 快速开始

## 🚀 For Users | 用户指南

### Installation | 安装

```bash
# Clone the repository
git clone https://github.com/echosoar/selecto.git
cd selecto

# Open in Xcode
open Selecto/Selecto.xcodeproj
```

### First Run | 首次运行

1. In Xcode, select **Product → Run** (or press `Cmd + R`)
2. Grant **Accessibility** permission when prompted
3. Grant **Screen Recording** permission when prompted
4. Restart the app

### Basic Usage | 基本使用

1. Look for the 📝 icon in your menu bar
2. Select any text in any application
3. A toolbar will appear above your selection
4. Click buttons to perform actions (Copy, Search, Translate)

## 🛠️ For Developers | 开发者指南

### Project Structure | 项目结构

```
Selecto/
├── AppDelegate.swift              # App entry, coordinates components
├── SelectionMonitor.swift         # Monitors text selection system-wide
├── ToolbarWindowController.swift  # Manages floating toolbar window
├── ToolbarView.swift              # Renders toolbar UI
├── SettingsWindowController.swift # Manages settings window
├── Models/
│   └── ActionItem.swift          # Data model for actions
├── Managers/
│   ├── ActionManager.swift       # CRUD for actions
│   ├── ActionExecutor.swift      # Executes actions
│   └── PermissionManager.swift   # Handles system permissions
└── Views/
    └── SettingsView.swift        # SwiftUI settings interface
```

### Key Classes | 核心类

| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `AppDelegate` | App lifecycle | `applicationDidFinishLaunching` |
| `SelectionMonitor` | Text selection | `startMonitoring()`, `getSelectedTextViaAccessibility()` |
| `ToolbarWindowController` | Toolbar display | `showToolbar()`, `hideToolbar()` |
| `ActionManager` | Config management | `getMatchingActions()`, `addAction()` |
| `ActionExecutor` | Action execution | `execute(_:with:)` |
| `PermissionManager` | Permissions | `checkAccessibilityPermission()` |

### Architecture Flow | 架构流程

```
User selects text
       ↓
SelectionMonitor detects via Accessibility API
       ↓
Calls delegate: AppDelegate.didDetectTextSelection()
       ↓
ActionManager.getMatchingActions(for: text)
       ↓
ToolbarWindowController.showToolbar(with: actions)
       ↓
User clicks button
       ↓
ActionExecutor.execute(action, with: text)
```

### Adding a New Action Type | 添加新动作类型

1. **Add to enum** in `ActionItem.swift`:
```swift
enum ActionType: String, Codable {
    case myNewAction = "myAction"
}
```

2. **Implement execution** in `ActionExecutor.swift`:
```swift
func execute(_ action: ActionItem, with text: String) {
    switch action.type {
    case .myNewAction:
        performMyAction(text, parameters: action.parameters)
    // ...
    }
}

private func performMyAction(_ text: String, parameters: [String: String]) {
    // Your implementation here
}
```

3. **Add UI** in `SettingsView.swift` if needed

### Testing | 测试

Manual testing checklist:
- [ ] Build succeeds without errors
- [ ] App launches and shows menu bar icon
- [ ] Permission dialogs appear on first run
- [ ] Text selection triggers toolbar
- [ ] Toolbar buttons execute actions correctly
- [ ] Settings window opens and saves changes
- [ ] App persists configuration across restarts

### Performance Tips | 性能提示

- Selection monitoring uses a 0.5s timer to balance responsiveness and CPU
- Regex compilation is done on-demand but could be cached
- Toolbar auto-hides after 10 seconds to reduce clutter
- Settings window is lazily initialized

## 📚 Documentation | 文档

- [README.md](README.md) - Overview and features
- [GUIDE.md](GUIDE.md) - Detailed usage instructions
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and patterns
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What was built

## 🔧 Common Issues | 常见问题

### Toolbar doesn't appear
- Check Accessibility permission in System Preferences
- Ensure at least one action is enabled
- Check that text is actually selected (not just focused)

### Can't compile
- Requires macOS 12.0+ deployment target
- Requires Xcode 14.0+
- Check that all files are included in the target

### Settings don't persist
- Check Application Support directory permissions
- Look for errors in Console.app

## 🎯 Next Steps | 下一步

1. **For Users:**
   - Customize actions in Settings
   - Add your own search engines
   - Create custom actions with scripts

2. **For Developers:**
   - Add unit tests
   - Implement additional action types
   - Add app icon and polish UI
   - Package as distributable .app

## 💡 Tips | 提示

- Use regex `^https?://` to create actions that only trigger for URLs
- The `{text}` placeholder in URL templates gets replaced with selected text
- Actions are matched in order, so put more specific ones first
- You can disable actions temporarily without deleting them

## 🐛 Debugging | 调试

Enable verbose logging:
```swift
// Add to AppDelegate.swift
override init() {
    super.init()
    print("Debug: App initialized")
}
```

Check the Console.app for runtime logs:
- Filter by process name: "Selecto"
- Look for permission-related errors
- Check for regex compilation errors

---

**Ready to build?** Just run `Cmd + R` in Xcode! 🚀
