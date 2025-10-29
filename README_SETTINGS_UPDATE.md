# Settings Page Updates - Quick Reference

## 🆕 New Features Added

This PR adds two new features to the Settings (设置) page:

### 1. 📁 Open Configuration Directory

```
╔══════════════════════════════════════════════════╗
║  配置 📁                                          ║
╟──────────────────────────────────────────────────╢
║  打开配置文件目录以查看或备份您的设置              ║
║                                                  ║
║  ┌──────────────────────────────────────┐       ║
║  │  📁 打开配置文件目录                  │       ║
║  └──────────────────────────────────────┘       ║
╚══════════════════════════════════════════════════╝
```

**What it does:**
- Opens Finder to `~/Library/Application Support/Selecto/`
- Shows your configuration files (`actions.json`, etc.)
- Allows you to backup or manually edit settings

### 2. 🔄 Check for Updates

```
╔══════════════════════════════════════════════════╗
║  更新 ⬇️                                          ║
╟──────────────────────────────────────────────────╢
║  当前版本: 1.0                                    ║
║                                                  ║
║  [After checking:]                               ║
║  最新版本: v0.1.3                                ║
║  ✅ 发现新版本！                                  ║
║                                                  ║
║  ────────────────────────────                    ║
║  更新说明:                                        ║
║  ┌────────────────────────────┐                 ║
║  │ • Bug fixes                │ (scrollable)     ║
║  │ • New features             │                 ║
║  └────────────────────────────┘                 ║
║                                                  ║
║  ┌─────────────┐  ┌───────────────┐            ║
║  │ 🔄 检查更新 │  │ ⬇️ 立即更新   │            ║
║  └─────────────┘  └───────────────┘            ║
║                                                  ║
║  💡 注意：更新时会保留您的授权和配置缓存           ║
╚══════════════════════════════════════════════════╝
```

**What it does:**
- Shows current installed version
- Checks GitHub for latest release
- Displays release notes
- Opens GitHub download page when "立即更新" clicked
- **Automatically preserves all your settings and permissions**

## 🎯 How to Use

### Open Configuration Directory
1. Open Selecto
2. Click Settings (设置) in menu bar
3. Navigate to Configuration (配置) section
4. Click "打开配置文件目录"
5. Finder opens to your config folder

### Check for Updates
1. Open Selecto
2. Click Settings (设置) in menu bar
3. Navigate to Updates (更新) section
4. Click "检查更新" button
5. Wait for check to complete
6. If update available, click "立即更新"
7. Download and install from GitHub

## ✅ Configuration Preservation

**Your settings are ALWAYS preserved** during updates because:
- ✅ Configuration files stored separately from app
- ✅ UserDefaults tied to app bundle ID (not the binary)
- ✅ System permissions tied to app bundle ID
- ✅ All persist when you replace the app

Simply download the new version and replace the old app in Applications folder!

## 📱 UI Integration

The new sections are added to the Settings tab alongside:
- Authorization (授权) - System permissions
- Actions (动作) - Custom actions configuration
- Settings (设置) - Now includes Configuration + Updates ⭐NEW
- Logs (日志) - Selection history

## 🔧 Technical Details

See documentation files for complete details:
- `FEATURE_UPDATE.md` - Technical implementation
- `UI_CHANGES.md` - UI mockups and layout
- `IMPLEMENTATION_SUMMARY_SETTINGS.md` - Complete summary

## 🚀 Ready to Build

All code is complete and ready for:
1. Building with Xcode
2. Testing on macOS
3. Deployment to users

The implementation follows all existing patterns and maintains backward compatibility.
