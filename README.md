# PasteBox - macOS 剪贴板管理器

一个功能完整、简洁高效的 macOS 原生剪贴板管理应用，使用 Swift 和 SwiftUI 开发。

## 📸 应用截图

### 主界面
<img src="docs/images/screenshots/main-interface.png" alt="PasteBox 主界面" width="700">

*PasteBox 主界面展示了简洁的剪贴板历史管理界面*

### 菜单栏集成
<img src="docs/images/screenshots/menu-bar.png" alt="菜单栏集成" width="400">

*应用完美集成到 macOS 菜单栏，一键访问*

### 历史面板
<img src="docs/images/screenshots/history-panel.png" alt="剪贴板历史面板" width="600">

*强大的历史面板支持搜索、过滤和快速复制*

### 设置界面
<div align="center">
  <img src="docs/images/screenshots/settings-general.png" alt="常规设置" width="45%">
  <img src="docs/images/screenshots/settings-hotkey.png" alt="快捷键设置" width="45%">
</div>

*左：常规设置页面 | 右：快捷键配置页面*

### 功能演示
<img src="docs/images/demo/demo.gif" alt="功能演示" width="600">

*PasteBox 核心功能演示动画*

## 🚀 主要功能

### 核心功能
- **自动监听剪贴板**：实时监听并保存用户复制的所有内容
- **多种数据类型支持**：
  - 纯文本
  - 富文本（RTF/HTML）
  - 图片（PNG、JPEG等格式）
  - 文件路径
  - URL链接
  - 其他二进制数据类型

### 快捷键功能
- **全局快捷键**：默认 `Cmd+Shift+V` 快速唤起历史面板
- **自定义快捷键**：支持用户自定义快捷键组合
- **快捷键录制**：直观的快捷键录制界面

### 历史面板
- **时间排序**：按时间倒序显示剪贴板历史
- **内容预览**：
  - 文本显示前几行
  - 图片显示缩略图
  - 文件显示路径和名称
- **一键复制**：点击任意历史项目直接复制到系统剪贴板
- **搜索过滤**：支持实时搜索和按类型过滤
- **收藏功能**：标记重要的剪贴板项目
- **批量管理**：支持删除单个或批量删除历史记录

### 设置页面
- **历史记录管理**：
  - 保存数量限制（默认1000项）
  - 自动清理过期记录（默认30天）
  - 手动清理和优化存储
- **应用设置**：
  - 开机自动启动
  - 菜单栏/Dock显示选项
  - 声音效果开关
- **隐私保护**：
  - 排除特定应用（如密码管理器）
  - 常见敏感应用预设
- **性能监控**：
  - 实时内存使用监控
  - 性能报告生成
  - 存储优化工具

## 🏗️ 技术架构

### 核心组件
- **ClipboardMonitor**：剪贴板监听服务
- **PersistenceManager**：数据持久化管理
- **SettingsManager**：应用设置管理
- **WindowManager**：窗口管理服务
- **PerformanceMonitor**：性能监控服务

### 数据模型
- **ClipboardItem**：剪贴板项目数据模型
- **ClipboardDataDocument**：导入导出文档格式
- **HotkeyConfiguration**：快捷键配置模型

### UI组件
- **MenuBarView**：菜单栏界面
- **ClipboardHistoryView**：历史面板主界面
- **SettingsView**：设置页面（包含多个标签页）

## 🛠️ 技术特性

### 性能优化
- **异步处理**：剪贴板监听和数据处理使用后台队列
- **内存管理**：
  - 大文件自动压缩（图片尺寸限制）
  - 内存使用监控和自动清理
  - 项目大小限制（50MB）
- **存储优化**：
  - 重复内容检测
  - 过期数据自动清理
  - 存储空间优化

### 用户体验
- **现代化UI**：遵循 macOS Human Interface Guidelines
- **深色模式支持**：自动适配系统主题
- **流畅动画**：使用 SwiftUI 动画效果
- **直观交互**：悬停效果、右键菜单、拖拽支持

### 安全性
- **沙盒应用**：完全符合 macOS 沙盒要求
- **权限控制**：最小化权限申请
- **隐私保护**：支持排除敏感应用

## 📦 项目结构

```
PasteBox/
├── PasteBox/
│   ├── Models/
│   │   ├── ClipboardItem.swift          # 剪贴板项目数据模型
│   │   └── ClipboardDataDocument.swift  # 导入导出文档
│   ├── Services/
│   │   ├── ClipboardMonitor.swift       # 剪贴板监听服务
│   │   ├── PersistenceManager.swift     # 数据持久化管理
│   │   ├── SettingsManager.swift        # 设置管理
│   │   ├── WindowManager.swift          # 窗口管理
│   │   └── PerformanceMonitor.swift     # 性能监控
│   ├── Views/
│   │   ├── MenuBarView.swift            # 菜单栏视图
│   │   ├── ClipboardHistoryView.swift   # 历史面板
│   │   └── SettingsView.swift           # 设置页面
│   ├── PasteBoxApp.swift                # 应用入口
│   ├── ContentView.swift                # 主内容视图
│   └── Assets.xcassets                  # 资源文件
├── PasteBoxTests/                       # 单元测试
└── PasteBoxUITests/                     # UI测试
```

## 🧪 测试

项目包含完整的单元测试，覆盖主要功能：
- 剪贴板项目创建和管理
- 数据持久化
- 设置管理
- 性能测试

运行测试：
```bash
xcodebuild test -project PasteBox.xcodeproj -scheme PasteBox
```

## 🚀 构建和运行

### 系统要求
- macOS 15.5+
- Xcode 15.0+
- Swift 5.9+

### 构建步骤
1. 克隆项目：
   ```bash
   git clone git@github.com:FearlessPeople/PasteBox.git
   cd PasteBox
   ```
2. 打开 `PasteBox.xcodeproj`
3. 选择目标设备（Mac）
4. 点击运行按钮或使用 `Cmd+R`

### 权限设置
应用需要以下权限：
- 辅助功能权限（用于全局快捷键）
- 文件访问权限（用于导入导出）

## 📝 使用说明

1. **首次启动**：应用会出现在菜单栏，开始监听剪贴板
2. **查看历史**：点击菜单栏图标或使用快捷键 `Cmd+Shift+V`
3. **复制内容**：在历史面板中点击任意项目
4. **搜索过滤**：使用搜索框或类型过滤器
5. **设置配置**：通过菜单栏或历史面板访问设置

## 🔧 自定义配置

### 快捷键设置
1. 打开设置页面
2. 切换到"快捷键"标签
3. 点击快捷键区域开始录制
4. 按下新的快捷键组合

### 隐私设置
1. 打开设置页面
2. 切换到"隐私"标签
3. 添加要排除的应用包标识符

## 🎯 未来计划

- [ ] iCloud 同步支持
- [ ] 更多文件格式支持
- [ ] 插件系统
- [ ] 多语言支持
- [ ] 主题自定义

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细的贡献指南。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- [GitHub 仓库](https://github.com/FearlessPeople/PasteBox)
- [问题反馈](https://github.com/FearlessPeople/PasteBox/issues)
- [功能请求](https://github.com/FearlessPeople/PasteBox/issues/new?template=feature_request.md)
