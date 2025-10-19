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
   - 类型：仅支持“打开链接”与“运行脚本”
   - 启用：是否启用此动作

   **匹配条件：**
   - 输入正则表达式来限制动作的触发条件
   - 例如：`^https?://` 只匹配 URL
   - 留空表示匹配所有文本

   **参数：**
   - “打开链接”：配置 URL 模板，使用 `{text}` 作为占位符
   - “运行脚本”：在输入框中直接编写 Shell 脚本，可使用 `{text}` 或 `SELECTO_TEXT`
   - 例如：`https://www.google.com/search?q={text}`

#### 默认动作

应用预设了一个默认动作：

1. **打开 Google 搜索**
   - 使用 URL 模板在浏览器中搜索选中的文本

### 高级配置

#### 自定义链接动作

在设置中编辑“打开链接”动作，修改 URL 模板：

- **Google**: `https://www.google.com/search?q={text}`
- **Bing**: `https://www.bing.com/search?q={text}`
- **DuckDuckGo**: `https://duckduckgo.com/?q={text}`
- **百度**: `https://www.baidu.com/s?wd={text}`

#### 运行脚本小贴士

- 环境变量 `SELECTO_TEXT` 自动包含选中的原始文本
- `{text}` 占位符会在执行前被替换为安全转义后的文本
- 可以在脚本中通过 `$1` 获取第一个参数（同样为选中文本）
- 如果脚本需要第三方命令，请确认已在系统 `PATH` 中

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

#### 脚本没有执行

- 确认脚本具备可执行权限或通过临时文件运行
- 检查脚本是否依赖额外的环境变量或路径

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
   - Type: Choose between “Open Link” and “Run Script”
   - Enabled: Whether this action is enabled

   **Match Condition:**
   - Enter a regular expression to limit action trigger conditions
   - Example: `^https?://` only matches URLs
   - Leave empty to match all text

   **Parameters:**
   - “Open Link”: Configure a URL template using `{text}` as placeholder
   - “Run Script”: Write shell scripts directly; `{text}` and `SELECTO_TEXT` provide the selected text
   - Example: `https://www.google.com/search?q={text}`

#### Default Actions

The app ships with one default action:

1. **Open Google Search**
   - Launches a browser search using the selected text

### Advanced Configuration

#### Custom Link Templates

Edit an “Open Link” action in settings and modify the URL template:

- **Google**: `https://www.google.com/search?q={text}`
- **Bing**: `https://www.bing.com/search?q={text}`
- **DuckDuckGo**: `https://duckduckgo.com/?q={text}`
- **Baidu**: `https://www.baidu.com/s?wd={text}`

#### Script Tips

- The environment variable `SELECTO_TEXT` always contains the selected text
- The `{text}` placeholder is replaced with a shell-escaped version before execution
- Your script receives the selected text as the first argument (`$1`)
- Ensure external binaries used in the script are available on the system `PATH`

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

#### Script fails to execute

- Ensure the script is executable or rely on the inline script runner
- Verify required dependencies or environment variables are available

#### Performance issues

- Reduce the number of enabled actions
- Simplify regular expressions
- Close unnecessary background apps
