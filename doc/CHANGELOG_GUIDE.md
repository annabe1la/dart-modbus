# CHANGELOG 管理指南

本项目使用 [cider](https://pub.dev/packages/cider) 来管理 CHANGELOG。

## 安装 cider

```bash
dart pub global activate cider
```

确保 `$HOME/.pub-cache/bin` 在你的 PATH 中：

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## 基本用法

### 1. 添加变更记录

在开发过程中，使用以下命令记录变更：

```bash
# 添加新功能
cider log added "新增功能描述"

# 记录修改
cider log changed "修改内容描述"

# 记录弃用
cider log deprecated "弃用功能描述"

# 记录移除
cider log removed "移除内容描述"

# 记录修复
cider log fixed "修复的bug描述"

# 记录安全更新
cider log security "安全更新描述"
```

**示例：**
```bash
cider log added "支持 Modbus RTU over UDP 协议"
cider log fixed "修复 TCP 连接超时问题"
cider log changed "优化数据转换性能"
```

### 2. 查看当前未发布的变更

```bash
cider describe
```

这会显示 `[Unreleased]` 部分的所有变更。

### 3. 发布新版本

发布版本时，cider 会自动：
- 将 `[Unreleased]` 的变更移到新版本
- 更新 `pubspec.yaml` 的版本号
- 添加发布日期

```bash
# 发布补丁版本 (1.0.0 -> 1.0.1)
cider release

# 发布次版本 (1.0.0 -> 1.1.0)
cider bump minor
cider release

# 发布主版本 (1.0.0 -> 2.0.0)
cider bump major
cider release

# 发布预发布版本 (1.0.0 -> 1.0.1-dev.1)
cider bump prerelease --pre dev
cider release
```

### 4. 手动设置版本

```bash
# 设置特定版本
cider version 1.2.3

# 仅更新 pubspec.yaml，不修改 CHANGELOG
cider version 1.2.3 --keep-unreleased
```

## 工作流程示例

### 开发新功能

```bash
# 开发过程中添加变更记录
git checkout -b feature/new-feature

# 添加功能
cider log added "新增 Modbus over WebSocket 支持"

# 修复发现的问题
cider log fixed "修复 WebSocket 连接重连逻辑"

# 提交代码
git add .
git commit -m "feat: add Modbus over WebSocket support"

# 查看当前变更
cider describe
```

### 准备发布

```bash
# 1. 确保所有变更都已记录
cider describe

# 2. 选择版本类型并发布
cider bump minor  # 从 1.0.0 -> 1.1.0
cider release

# 3. 提交变更
git add CHANGELOG.md pubspec.yaml
git commit -m "chore: release version 1.1.0"
git tag v1.1.0
git push origin main --tags
```

## 变更类型说明

按照 [Keep a Changelog](https://keepachangelog.com/) 标准：

- **Added** - 新增功能
- **Changed** - 现有功能的变更
- **Deprecated** - 即将移除的功能
- **Removed** - 已移除的功能
- **Fixed** - Bug 修复
- **Security** - 安全相关的修复

## CHANGELOG 格式

cider 自动维护以下格式：

```markdown
## [Unreleased]

### Added
- 新功能1
- 新功能2

### Fixed
- 修复1

## [1.1.0] - 2025-01-23

### Added
- 已发布的功能

### Changed
- 已发布的变更
```

## 高级用法

### 自定义链接模板

编辑 `pubspec.yaml` 添加链接模板：

```yaml
name: modbus
version: 1.0.0

# Cider configuration
cider:
  link_template:
    tag: "https://github.com/yourname/dart-modbus/releases/tag/%tag%"
    diff: "https://github.com/yourname/dart-modbus/compare/%from%...%to%"
```

### 检查 CHANGELOG 格式

```bash
# 验证 CHANGELOG 格式是否正确
cider version
```

如果格式有误，cider 会报错并指出问题。

## 最佳实践

1. **及时记录** - 每次功能完成或修复 bug 后立即使用 `cider log` 记录
2. **描述清晰** - 变更描述应该简洁明了，让用户能快速理解影响
3. **分类准确** - 选择正确的变更类型（added/changed/fixed等）
4. **版本语义** - 遵循语义化版本：
   - 主版本(major): 不兼容的API变更
   - 次版本(minor): 向后兼容的功能新增
   - 补丁版本(patch): 向后兼容的问题修复
5. **发布前检查** - 使用 `cider describe` 确认所有变更都已记录

## 集成到 CI/CD

可以在 CI 中自动验证 CHANGELOG：

```yaml
# .github/workflows/changelog.yml
name: Changelog Check
on: [pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub global activate cider
      - run: cider version  # 验证格式
```

## 参考资料

- [cider 官方文档](https://pub.dev/packages/cider)
- [Keep a Changelog](https://keepachangelog.com/)
- [语义化版本](https://semver.org/lang/zh-CN/)
