# 图片资源说明

本目录包含 PasteBox 项目的图片资源。

## 目录结构

```
docs/images/
├── screenshots/          # 应用截图
│   ├── main-interface.png       # 主界面截图
│   ├── menu-bar.png            # 菜单栏截图
│   ├── history-panel.png       # 历史面板截图
│   ├── settings-general.png    # 设置页面-常规
│   ├── settings-hotkey.png     # 设置页面-快捷键
│   ├── settings-privacy.png    # 设置页面-隐私
│   └── settings-performance.png # 设置页面-性能
├── icons/               # 图标资源
└── demo/               # 演示动图
    └── demo.gif        # 功能演示动图
```

## 截图规范

### 尺寸建议
- **主要截图**: 1200x800px 或更高
- **细节截图**: 800x600px
- **菜单栏截图**: 400x300px

### 格式要求
- 使用 PNG 格式（支持透明背景）
- 文件大小控制在 500KB 以内
- 使用有意义的文件名

### 内容建议
1. **主界面截图**: 展示应用的整体界面
2. **功能截图**: 展示核心功能的使用
3. **设置截图**: 展示配置选项
4. **演示动图**: 展示操作流程（可选）

## 使用方法

在 README.md 中引用图片：

```markdown
![主界面](docs/images/screenshots/main-interface.png)
```

或使用 HTML 标签控制大小：

```html
<img src="docs/images/screenshots/main-interface.png" alt="主界面" width="600">
```
