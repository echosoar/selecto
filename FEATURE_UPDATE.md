# Settings Enhancement Features

This document describes the new features added to the Settings page.

## 1. Open Configuration Directory

**Location:** Settings tab → Configuration section

A new "Configuration" section has been added with a button to open the application's configuration directory. This allows users to:
- View their configuration files
- Backup their settings
- Manually edit configuration if needed

The configuration directory is located at:
```
~/Library/Application Support/Selecto/
```

This directory contains:
- `actions.json` - User's custom actions configuration
- Other application preferences stored via UserDefaults

## 2. Check for Updates

**Location:** Settings tab → Updates section

A new "Updates" section has been added with the following features:

### Features:
- **Current Version Display**: Shows the currently installed version of Selecto
- **Check for Updates Button**: Manually check for new releases on GitHub
- **Latest Version Display**: Shows the latest available version when update is found
- **Update Notification**: Displays "发现新版本！" (New version found!) when an update is available
- **Release Notes**: Displays the release notes for the latest version
- **Download Button**: "立即更新" (Update Now) button appears when an update is available
- **Progress Indicator**: Shows a loading indicator while checking for updates
- **Error Handling**: Displays error messages if the update check fails

### How it works:
1. User clicks "检查更新" (Check for Updates) button
2. The app queries the GitHub API for the latest release
3. Compares the latest version with the current version
4. If a newer version is available, shows the "立即更新" (Update Now) button
5. Clicking "立即更新" opens the GitHub releases page in the browser
6. User can download the appropriate DMG file (Universal, ARM64, or x86_64)
7. After installing the update, all existing configurations and authorizations are preserved

### Preservation of Settings:
The update process preserves:
- ✅ All custom actions in `~/Library/Application Support/Selecto/actions.json`
- ✅ Application preferences (force selection settings, excluded apps, etc.)
- ✅ System authorizations (Accessibility, Screen Recording permissions)
- ✅ Selection history settings

This is possible because:
- Configuration files are stored in the standard Application Support directory
- UserDefaults are tied to the app's bundle identifier
- System permissions are tied to the app's bundle identifier
- These are not removed when the app is updated

## Technical Implementation

### New Files:
- `Selecto/Selecto/Managers/UpdateManager.swift`: Manages update checking and configuration directory operations

### Modified Files:
- `Selecto/Selecto/Views/ContentView.swift`: Added new UI sections to PreferencesView
- `Selecto/Selecto.xcodeproj/project.pbxproj`: Added UpdateManager.swift to the Xcode project

### API Used:
- GitHub REST API: `https://api.github.com/repos/echosoar/selecto/releases/latest`
- Returns the latest release information including version, URL, and release notes

### Version Comparison:
The app uses semantic versioning comparison to determine if an update is available:
- Supports versions with or without 'v' prefix (e.g., "v1.0.0" or "1.0.0")
- Compares major, minor, and patch versions
- Correctly handles different version string lengths

## User Experience

1. **Configuration Management**: Users can now easily access their configuration directory to:
   - Backup their custom actions
   - Review their settings
   - Troubleshoot configuration issues

2. **Update Management**: Users are now in control of when to update:
   - No automatic updates - user initiates the check
   - Clear indication when updates are available
   - Release notes help users decide whether to update
   - Simple one-click access to download page

3. **Bilingual Interface**: All new features maintain the bilingual Chinese/English pattern:
   - UI elements have both Chinese and English labels
   - Comments in code are bilingual
   - User-facing messages are in Chinese (primary audience)
