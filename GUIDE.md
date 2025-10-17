# Build & Usage Guide | 构建和使用指南

[English](#english) | [中文](#中文)

---

## 中文

### 快速开始

#### 环境要求

- macOS 12.0 (Monterey) 或更高版本
- Xcode 14.0 或更高版本

#### 构建步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/echosoar/selecto.git
   cd selecto
   ```

2. **打开 Xcode 项目**
   ```bash
   open Selecto/Selecto.xcodeproj
   ```

3. **选择构建目标**
   - 在 Xcode 中，选择 "Selecto" scheme
   - 选择 "My Mac" 作为目标设备

4. **构建并运行**
   - 按 `Cmd + R` 运行应用
   - 或选择菜单：Product → Run

#### 首次运行

首次运行时，应用会请求必要的权限：

1. **辅助功能权限**
   - 会弹出系统提示
   - 点击"打开系统偏好设置"
   - 在"安全性与隐私" → "隐私" → "辅助功能"中勾选 Selecto

2. **屏幕录制权限**（macOS 10.15+）
   - 同样在"安全性与隐私" → "隐私" → "屏幕录制"中勾选 Selecto

3. **重启应用**
   - 授权后需要重启应用才能生效

### 使用说明

#### 基本使用

1. **启动应用**
   - 应用会在菜单栏显示 📝 图标
   - 应用在后台运行，不显示主窗口

2. **选择文本**
   - 在任何应用中用鼠标选择一段文本
   - 稍等片刻，工具栏会自动出现在选中文本上方

3. **使用功能**
   - 点击工具栏上的按钮执行相应操作
   - 工具栏会在 10 秒后自动隐藏

#### 配置动作

1. **打开设置**
   - 点击菜单栏的 Selecto 图标
   - 选择"设置 (Settings)"

2. **管理动作**
   - **添加新动作**：点击左上角的 "+" 按钮
   - **编辑动作**：在列表中选中动作，右键选择"编辑"
   - **删除动作**：在列表中选中动作，右键选择"删除"
   - **排序动作**：拖动动作调整顺序

3. **配置动作参数**

   **基本信息：**
   - 名称：内部使用的动作标识符
   - 显示名称：在工具栏上显示的名称
   - 类型：选择动作类型（复制、搜索、翻译等）
   - 启用：是否启用此动作

   **匹配条件：**
   - 输入正则表达式来限制动作的触发条件
   - 例如：`^https?://` 只匹配 URL
   - 留空表示匹配所有文本

   **参数：**
   - 对于搜索、翻译等类型，需要配置 URL 模板
   - 使用 `{text}` 作为占位符，会被替换为选中的文本
   - 例如：`https://www.google.com/search?q={text}`

#### 默认动作

应用自带三个默认动作：

1. **复制 (Copy)**
   - 将选中的文本复制到剪贴板

2. **搜索 (Search)**
   - 使用 Google 搜索选中的文本

3. **翻译 (Translate)**
   - 使用 Google 翻译翻译选中的文本

### 高级配置

#### 自定义搜索引擎

在设置中编辑"搜索"动作，修改 URL 模板：

- **Google**: `https://www.google.com/search?q={text}`
- **Bing**: `https://www.bing.com/search?q={text}`
- **DuckDuckGo**: `https://duckduckgo.com/?q={text}`
- **百度**: `https://www.baidu.com/s?wd={text}`

#### 正则表达式示例

- **匹配 URL**: `^https?://.*`
- **匹配邮箱**: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- **匹配中文**: `[\u4e00-\u9fa5]+`
- **匹配英文单词**: `^[a-zA-Z]+$`
- **匹配数字**: `^\d+$`

### 故障排除

#### 工具栏不出现

1. 检查辅助功能权限是否已授权
2. 尝试重启应用
3. 在设置中检查动作是否启用
4. 检查匹配条件是否过于严格

#### 无法复制到剪贴板

- 检查应用是否有剪贴板访问权限
- 某些应用可能禁止外部访问剪贴板

#### 性能问题

- 减少启用的动作数量
- 简化正则表达式
- 关闭不需要的后台应用

---

## English

### Quick Start

#### Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later

#### Build Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/echosoar/selecto.git
   cd selecto
   ```

2. **Open Xcode project**
   ```bash
   open Selecto/Selecto.xcodeproj
   ```

3. **Select build target**
   - In Xcode, select the "Selecto" scheme
   - Select "My Mac" as the target device

4. **Build and run**
   - Press `Cmd + R` to run the app
   - Or select menu: Product → Run

#### First Run

On first run, the app will request necessary permissions:

1. **Accessibility Permission**
   - A system prompt will appear
   - Click "Open System Preferences"
   - Check Selecto in "Security & Privacy" → "Privacy" → "Accessibility"

2. **Screen Recording Permission** (macOS 10.15+)
   - Similarly, check Selecto in "Security & Privacy" → "Privacy" → "Screen Recording"

3. **Restart the app**
   - The app needs to be restarted after authorization

### Usage Instructions

#### Basic Usage

1. **Launch the app**
   - The app will show a 📝 icon in the menu bar
   - The app runs in the background without showing a main window

2. **Select text**
   - Select text with your mouse in any application
   - Wait a moment, the toolbar will automatically appear above the selected text

3. **Use features**
   - Click buttons on the toolbar to execute corresponding actions
   - The toolbar will automatically hide after 10 seconds

#### Configure Actions

1. **Open settings**
   - Click the Selecto icon in the menu bar
   - Select "Settings"

2. **Manage actions**
   - **Add new action**: Click the "+" button in the top left
   - **Edit action**: Select action in the list, right-click and choose "Edit"
   - **Delete action**: Select action in the list, right-click and choose "Delete"
   - **Sort actions**: Drag actions to adjust order

3. **Configure action parameters**

   **Basic Information:**
   - Name: Internal action identifier
   - Display Name: Name shown on the toolbar
   - Type: Select action type (copy, search, translate, etc.)
   - Enabled: Whether this action is enabled

   **Match Condition:**
   - Enter a regular expression to limit action trigger conditions
   - Example: `^https?://` only matches URLs
   - Leave empty to match all text

   **Parameters:**
   - For search, translate, etc., configure URL template
   - Use `{text}` as placeholder, will be replaced with selected text
   - Example: `https://www.google.com/search?q={text}`

#### Default Actions

The app comes with three default actions:

1. **Copy**
   - Copy selected text to clipboard

2. **Search**
   - Search selected text with Google

3. **Translate**
   - Translate selected text with Google Translate

### Advanced Configuration

#### Custom Search Engines

Edit the "Search" action in settings and modify the URL template:

- **Google**: `https://www.google.com/search?q={text}`
- **Bing**: `https://www.bing.com/search?q={text}`
- **DuckDuckGo**: `https://duckduckgo.com/?q={text}`
- **Baidu**: `https://www.baidu.com/s?wd={text}`

#### Regular Expression Examples

- **Match URL**: `^https?://.*`
- **Match Email**: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- **Match Chinese**: `[\u4e00-\u9fa5]+`
- **Match English words**: `^[a-zA-Z]+$`
- **Match Numbers**: `^\d+$`

### Troubleshooting

#### Toolbar doesn't appear

1. Check if Accessibility permission is granted
2. Try restarting the app
3. Check if actions are enabled in settings
4. Check if match conditions are too restrictive

#### Cannot copy to clipboard

- Check if the app has clipboard access permission
- Some apps may block external clipboard access

#### Performance issues

- Reduce the number of enabled actions
- Simplify regular expressions
- Close unnecessary background apps
