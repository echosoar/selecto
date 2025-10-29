# UI Changes - Settings Page Enhancement

This document describes the visual changes made to the Settings page.

## Before and After

### Before
The Settings page (偏好设置) previously only had:
- Text Selection (文本选择) section with force selection toggle and excluded apps

### After
The Settings page now has THREE sections:

## 1. Text Selection Section (文本选择) - EXISTING
- Toggle: "开启强制选词" (Enable Force Selection)
- Description text
- Excluded apps list (when enabled)
- Add/remove excluded apps functionality

## 2. Configuration Section (配置) - NEW ✨
```
┌─ 配置 [folder icon] ────────────────────────┐
│                                              │
│  打开配置文件目录以查看或备份您的设置        │
│  (Open config directory to view or backup)   │
│                                              │
│  ┌──────────────────────────────────┐       │
│  │ [folder.badge.gear] 打开配置文件目录 │   │
│  └──────────────────────────────────┘       │
│                                              │
└──────────────────────────────────────────────┘
```

Button action: Opens Finder to `~/Library/Application Support/Selecto/`

## 3. Updates Section (更新) - NEW ✨
```
┌─ 更新 [arrow.down.circle icon] ──────────────┐
│                                                │
│  当前版本: 1.0                                 │
│                                                │
│  [After checking for updates:]                 │
│  最新版本: v0.1.3                              │
│  发现新版本！ (in green if newer)              │
│  or                                            │
│  您已是最新版本 (if same/older)                │
│                                                │
│  ────────────────────────────                  │
│  更新说明:                                      │
│  ┌──────────────────────────┐                 │
│  │ Release notes content... │ (scrollable)     │
│  │ ...                      │ (max 100px)      │
│  └──────────────────────────┘                 │
│                                                │
│  [Error message if any, in red]                │
│                                                │
│  ┌──────────────────┐  ┌──────────────────┐  │
│  │ [arrow.clockwise] │  │ [arrow.down.    │  │
│  │ 检查更新         │  │  circle.fill]    │  │
│  │                  │  │ 立即更新 (if     │  │
│  │ (bordered style) │  │  update avail)   │  │
│  └──────────────────┘  │ (prominent style)│  │
│                        └──────────────────┘  │
│                                                │
│  注意：更新时会保留您的授权和配置缓存          │
│  (Note: Updates preserve auth and config)     │
│                                                │
└────────────────────────────────────────────────┘
```

### Button States

**Check for Updates Button:**
- Normal state: "检查更新" with refresh icon
- Loading state: Progress indicator + "检查中..."
- Disabled during loading

**Update Now Button:**
- Only appears when `hasUpdate == true`
- Prominent style (blue/accent color)
- Opens GitHub releases page when clicked

### Dynamic UI Elements

1. **Latest Version Info**: Only shown after successful update check
2. **Update Available Badge**: Green "发现新版本！" text when update exists
3. **Up-to-date Message**: Gray "您已是最新版本" when no update
4. **Release Notes**: Expandable section with scrollable content (max 100px)
5. **Error Messages**: Red text below buttons for any errors
6. **Update Now Button**: Only visible when update is available

## Layout Structure

The Settings page uses a vertical stack with:
- Title: "偏好设置" (large title, bold)
- Spacing: 24pt between sections
- Each section uses `GroupBox` with:
  - Label with icon and text
  - Padding around content
  - Consistent internal spacing (12pt)

## Color Scheme
- Primary text: Default system color
- Secondary text: Gray/secondary color
- Success indicators: Green
- Error messages: Red
- Buttons: System bordered and prominent styles

## Icons Used
- 📁 `folder` - Configuration section
- ⚙️ `folder.badge.gear` - Open config directory button
- ⬇️ `arrow.down.circle` - Updates section
- 🔄 `arrow.clockwise` - Check updates button  
- ⬇️ `arrow.down.circle.fill` - Update now button

## Accessibility
- All buttons have proper labels
- Text is selectable where appropriate (release notes)
- Loading states clearly indicated
- Error messages clearly visible
- Proper contrast ratios maintained

## Responsive Behavior
- Layout adapts to window size
- Text wraps appropriately with `.fixedSize(horizontal: false, vertical: true)`
- Scrollable areas for long content
- Minimum width maintained for readability
