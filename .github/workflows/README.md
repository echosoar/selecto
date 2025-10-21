# GitHub Actions 自动化构建和发布配置 / GitHub Actions Automated Build and Release Configuration

## 中文说明

### 概述

本项目已配置 GitHub Actions 工作流，用于自动化构建和发布 Selecto macOS 应用程序。

### 功能特性

#### 1. 自动触发
- **触发条件**: 当有新的提交推送到 `main` 分支时自动触发
- **工作流文件**: `.github/workflows/build-release.yml`

#### 2. 版本管理
- **初始版本**: 0.1.0
- **自动递增**: 每次构建自动递增 patch 版本号
- **版本规则**: 
  - 如果没有任何 tag，从 0.1.0 开始
  - 如果存在 tag，自动递增最后一位（例如：0.1.0 → 0.1.1 → 0.1.2）
- **版本更新**: 自动更新 `Info.plist` 和 `project.pbxproj` 中的版本号

#### 3. 多架构构建
支持三种架构的构建：

- **Universal Binary (通用二进制)**: 同时支持 Apple Silicon 和 Intel 芯片
  - 使用 `lipo` 工具合并 ARM64 和 x86_64 二进制文件
  - 文件名: `Selecto-{version}-universal.dmg`

- **ARM64**: 专为 Apple Silicon (M1/M2/M3) 优化
  - 架构: `arm64`
  - 文件名: `Selecto-{version}-arm64.dmg`

- **x86_64**: 专为 Intel 芯片优化
  - 架构: `x86_64`
  - 文件名: `Selecto-{version}-x86_64.dmg`

#### 4. DMG 打包
- 每个架构都会生成对应的 DMG 安装包
- DMG 包含应用程序和 Applications 文件夹的符号链接
- 使用 UDZO 压缩格式以减小文件大小

#### 5. GitHub Release
- 自动创建 GitHub Release
- Release 标签格式: `v{version}` (例如: `v0.1.0`)
- 包含详细的发布说明（中英双语）
- 自动上传三个 DMG 文件作为附件

### 构建流程

1. **检出代码**: 使用 `actions/checkout@v4` 检出完整的 Git 历史
2. **计算版本**: 从现有 tags 中计算下一个版本号
3. **更新版本**: 更新项目文件中的版本信息
4. **构建 ARM64**: 构建 Apple Silicon 版本
5. **构建 x86_64**: 构建 Intel 版本
6. **创建通用二进制**: 使用 lipo 合并两种架构
7. **打包 DMG**: 为每种架构创建 DMG 安装包
8. **发布**: 创建 GitHub Release 并上传所有 DMG 文件

### 安全性

- 使用最小权限原则，仅授予 `contents: write` 权限
- 禁用代码签名（适用于开源项目）
- 通过 CodeQL 安全检查

### 使用方法

#### 触发构建
只需将代码推送到 `main` 分支：

```bash
git add .
git commit -m "你的提交信息"
git push origin main
```

#### 下载发布版本
1. 访问仓库的 [Releases 页面](https://github.com/echosoar/selecto/releases)
2. 选择最新版本
3. 下载适合您 Mac 的 DMG 文件
4. 双击 DMG 文件并将应用拖到 Applications 文件夹

---

## English

### Overview

This project is configured with a GitHub Actions workflow for automated building and releasing of the Selecto macOS application.

### Features

#### 1. Auto-Trigger
- **Trigger Condition**: Automatically triggered when new commits are pushed to the `main` branch
- **Workflow File**: `.github/workflows/build-release.yml`

#### 2. Version Management
- **Initial Version**: 0.1.0
- **Auto-Increment**: Automatically increments patch version with each build
- **Version Rules**: 
  - If no tags exist, starts from 0.1.0
  - If tags exist, auto-increments the last digit (e.g., 0.1.0 → 0.1.1 → 0.1.2)
- **Version Update**: Automatically updates version numbers in `Info.plist` and `project.pbxproj`

#### 3. Multi-Architecture Build
Supports three architecture builds:

- **Universal Binary**: Supports both Apple Silicon and Intel chips
  - Uses `lipo` tool to combine ARM64 and x86_64 binaries
  - Filename: `Selecto-{version}-universal.dmg`

- **ARM64**: Optimized for Apple Silicon (M1/M2/M3)
  - Architecture: `arm64`
  - Filename: `Selecto-{version}-arm64.dmg`

- **x86_64**: Optimized for Intel chips
  - Architecture: `x86_64`
  - Filename: `Selecto-{version}-x86_64.dmg`

#### 4. DMG Packaging
- Each architecture generates a corresponding DMG installer
- DMG includes the application and a symbolic link to the Applications folder
- Uses UDZO compression format to reduce file size

#### 5. GitHub Release
- Automatically creates GitHub Releases
- Release tag format: `v{version}` (e.g., `v0.1.0`)
- Includes detailed release notes (bilingual)
- Automatically uploads all three DMG files as attachments

### Build Process

1. **Checkout Code**: Uses `actions/checkout@v4` to checkout full Git history
2. **Calculate Version**: Calculates next version number from existing tags
3. **Update Version**: Updates version information in project files
4. **Build ARM64**: Builds Apple Silicon version
5. **Build x86_64**: Builds Intel version
6. **Create Universal Binary**: Uses lipo to merge both architectures
7. **Package DMG**: Creates DMG installer for each architecture
8. **Release**: Creates GitHub Release and uploads all DMG files

### Security

- Uses principle of least privilege, only grants `contents: write` permission
- Code signing disabled (suitable for open-source projects)
- Passes CodeQL security checks

### Usage

#### Trigger a Build
Simply push code to the `main` branch:

```bash
git add .
git commit -m "Your commit message"
git push origin main
```

#### Download Releases
1. Visit the repository's [Releases page](https://github.com/echosoar/selecto/releases)
2. Select the latest version
3. Download the appropriate DMG file for your Mac
4. Double-click the DMG file and drag the app to the Applications folder

### Workflow Configuration Details

- **Runner**: `macos-latest` (GitHub-hosted macOS runner)
- **Build Tool**: Xcode command-line tools (`xcodebuild`)
- **Permissions**: `contents: write` (for creating releases and pushing tags)
- **Dependencies**: 
  - `actions/checkout@v4` - Code checkout
  - `softprops/action-gh-release@v1` - Release creation

### Customization

To modify the build behavior, edit `.github/workflows/build-release.yml`:

- **Change version increment logic**: Modify the "Get latest tag and calculate next version" step
- **Add code signing**: Add signing steps with appropriate certificates and provisioning profiles
- **Modify architectures**: Change the `-arch` parameter in build steps
- **Customize DMG appearance**: Add custom background and icon positioning

### Troubleshooting

- **Build fails**: Check the Actions tab in GitHub for detailed logs
- **Version not incrementing**: Ensure tags are in the correct format (`v*.*.*`)
- **DMG not created**: Verify that the build completed successfully before DMG creation step
