# 贡献指南

感谢您对 PasteBox 项目的关注！我们欢迎各种形式的贡献，包括但不限于：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复或新功能
- 🧪 编写测试用例

## 🚀 快速开始

### 环境要求

- macOS 15.5+
- Xcode 15.0+
- Swift 5.9+
- Git

### 设置开发环境

1. Fork 本仓库到您的 GitHub 账户
2. 克隆您的 Fork：
   ```bash
   git clone git@github.com:YOUR_USERNAME/PasteBox.git
   cd PasteBox
   ```
3. 添加上游仓库：
   ```bash
   git remote add upstream git@github.com:FearlessPeople/PasteBox.git
   ```
4. 打开 `PasteBox.xcodeproj` 开始开发

## 📋 贡献流程

### 报告 Bug

1. 在提交 Bug 报告前，请先搜索现有的 [Issues](https://github.com/FearlessPeople/PasteBox/issues)
2. 如果没有找到相关问题，请创建新的 Issue
3. 使用 Bug 报告模板，提供详细信息：
   - 系统版本
   - 应用版本
   - 重现步骤
   - 预期行为
   - 实际行为
   - 截图或日志（如果适用）

### 提出功能建议

1. 搜索现有的 [Issues](https://github.com/FearlessPeople/PasteBox/issues) 确保建议未被提出
2. 创建新的 Feature Request Issue
3. 详细描述：
   - 功能的用途和价值
   - 具体的实现建议
   - 可能的替代方案

### 提交代码

1. **创建分支**：
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

2. **编写代码**：
   - 遵循项目的代码风格
   - 添加必要的注释
   - 确保代码通过所有测试

3. **运行测试**：
   ```bash
   xcodebuild test -project PasteBox.xcodeproj -scheme PasteBox
   ```

4. **提交更改**：
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   # 或
   git commit -m "fix: fix bug description"
   ```

5. **推送分支**：
   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**：
   - 在 GitHub 上创建 PR
   - 填写 PR 模板
   - 等待代码审查

## 📝 代码规范

### Swift 代码风格

- 使用 4 个空格缩进
- 遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- 使用有意义的变量和函数名
- 添加适当的文档注释

### 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

类型包括：
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式化
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

示例：
```
feat(clipboard): add support for rich text format
fix(ui): resolve menu bar icon display issue
docs: update installation instructions
```

## 🧪 测试

- 为新功能编写单元测试
- 确保所有现有测试通过
- 测试覆盖率应保持在合理水平
- 手动测试关键功能

## 📚 文档

- 更新相关的代码注释
- 如果添加新功能，更新 README.md
- 保持文档与代码同步

## 🔍 代码审查

所有的 Pull Request 都需要经过代码审查：

- 至少一个维护者的批准
- 所有 CI 检查通过
- 解决所有审查意见

## 🎯 开发建议

### 架构原则

- 保持代码模块化
- 遵循 MVVM 架构模式
- 使用依赖注入
- 保持单一职责原则

### 性能考虑

- 避免在主线程进行耗时操作
- 合理使用内存，避免内存泄漏
- 优化 UI 响应性能

### 安全性

- 遵循 macOS 沙盒要求
- 最小化权限申请
- 保护用户隐私数据

## 🤝 社区

- 保持友善和专业的态度
- 尊重不同的观点和建议
- 遵循 [行为准则](CODE_OF_CONDUCT.md)

## ❓ 获取帮助

如果您在贡献过程中遇到问题：

1. 查看现有的 [Issues](https://github.com/FearlessPeople/PasteBox/issues)
2. 在 [Discussions](https://github.com/FearlessPeople/PasteBox/discussions) 中提问
3. 联系项目维护者

感谢您的贡献！🎉
