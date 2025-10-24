# Melos 使用指南

本项目使用 [Melos](https://melos.invertase.dev/) 进行 monorepo 管理，并集成 [cider](https://pub.dev/packages/cider) 来管理 CHANGELOG。

## 安装

```bash
# 安装 Melos
dart pub global activate melos

# 安装 cider
dart pub global activate cider

# 确保全局 bin 目录在 PATH 中
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## 初始化项目

```bash
# 首次克隆项目后，运行：
melos bootstrap
```

这会自动运行 `dart pub get` 并设置项目。

## 常用命令

### 开发工作流

```bash
# 代码格式化
melos run format

# 静态分析
melos run analyze

# 运行测试
melos run test

# 运行测试并生成覆盖率
melos run test:coverage

# 完整 CI 检查（格式化检查 + 分析 + 测试）
melos run ci
```

### CHANGELOG 管理

```bash
# 添加新功能
melos run changelog:add "支持 Modbus over UDP"

# 添加 bug 修复
melos run changelog:fix "修复 TCP 连接超时问题"

# 添加变更
melos run changelog:change "优化数据转换性能"

# 查看未发布的变更
melos run changelog:show
```

**其他 CHANGELOG 类型：**
```bash
# 手动使用 cider
dart pub global run cider log deprecated "即将弃用的 API"
dart pub global run cider log removed "已移除的功能"
dart pub global run cider log security "安全相关修复"
```

### 版本发布

```bash
# 发布前检查
melos run prerelease

# 发布补丁版本 (1.0.0 -> 1.0.1)
melos run version:patch

# 发布次版本 (1.0.0 -> 1.1.0)
melos run version:minor

# 发布主版本 (1.0.0 -> 2.0.0)
melos run version:major
```

发布后需要手动提交和推送：

```bash
git add CHANGELOG.md pubspec.yaml pubspec.lock
git commit -m "chore(release): publish v1.1.0"
git tag v1.1.0
git push origin main --tags
```

### 运行示例

```bash
# TCP 客户端示例
melos run example:tcp

# RTU 客户端示例
melos run example:rtu

# 数据转换示例
melos run example:conversion

# 寄存器映射示例
melos run example:register
```

### 模拟器

```bash
# 启动从站模拟器（在终端1）
melos run simulator:slave

# 启动主站模拟器（在终端2）
melos run simulator:master
```

## 完整开发流程示例

### 1. 开发新功能

```bash
# 创建功能分支
git checkout -b feature/new-feature

# 开发代码...

# 运行测试
melos run test

# 格式化代码
melos run format

# 记录变更
melos run changelog:add "新增 Modbus over WebSocket 支持"

# 提交代码
git add .
git commit -m "feat: add Modbus over WebSocket support"
```

### 2. 修复 Bug

```bash
# 创建修复分支
git checkout -b fix/connection-timeout

# 修复代码...

# 运行测试
melos run test

# 记录修复
melos run changelog:fix "修复 TCP 连接超时导致的崩溃问题"

# 提交代码
git commit -am "fix: resolve TCP connection timeout crash"
```

### 3. 发布新版本

```bash
# 切换到主分支
git checkout main
git pull origin main

# 发布前完整检查
melos run prerelease

# 查看即将发布的变更
melos run changelog:show

# 发布版本（根据变更类型选择）
melos run version:minor  # 如果有新功能
# 或
melos run version:patch  # 如果只有 bug 修复

# 提交并推送
git add .
git commit -m "chore(release): publish v1.1.0"
git tag v1.1.0
git push origin main --tags

# 发布到 pub.dev
dart pub publish
```

## 自定义脚本

你可以在 `melos.yaml` 中添加自定义脚本：

```yaml
scripts:
  my-script:
    run: echo "Hello, Melos!"
    description: 我的自定义脚本
```

然后运行：

```bash
melos run my-script
```

## Melos 配置说明

### 包管理

`melos.yaml` 中的 `packages` 配置指定了哪些目录包含 Dart 包：

```yaml
packages:
  - .              # 当前根目录
  - packages/*     # packages 目录下的所有包
```

### 脚本命令

所有脚本定义在 `scripts` 部分：

```yaml
scripts:
  script-name:
    run: command to execute
    description: 脚本描述
```

## 高级用法

### 并行执行

对于 monorepo 中的多个包，可以并行执行命令：

```bash
# 在所有包中运行命令
melos exec -- dart analyze

# 在所有包中运行测试
melos exec -- dart test
```

### 选择性执行

```bash
# 只在特定包中运行
melos exec --scope=modbus -- dart test

# 排除某些包
melos exec --ignore=modbus_simulator -- dart analyze
```

### 依赖图

```bash
# 查看包依赖关系
melos list --graph
```

## CI/CD 集成

### GitHub Actions 示例

创建 `.github/workflows/ci.yml`：

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install Melos
        run: dart pub global activate melos

      - name: Bootstrap
        run: melos bootstrap

      - name: Run CI
        run: melos run ci
```

## 常见问题

### Q: melos 命令找不到？

**A:** 确保 `$HOME/.pub-cache/bin` 在你的 PATH 中：

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

添加到 `~/.zshrc` 或 `~/.bashrc` 中永久生效。

### Q: 如何查看所有可用的脚本？

**A:** 运行：

```bash
melos run
```

这会列出所有定义的脚本及其描述。

### Q: 如何添加新的包到 monorepo？

**A:**

1. 在 `packages/` 目录下创建新包
2. 更新 `melos.yaml` 中的 `packages` 配置
3. 运行 `melos bootstrap`

### Q: 版本发布后如何回滚？

**A:**

```bash
# 删除本地标签
git tag -d v1.1.0

# 删除远程标签
git push --delete origin v1.1.0

# 手动编辑 CHANGELOG.md 和 pubspec.yaml 恢复版本
```

## 最佳实践

1. **每次功能完成后立即记录 CHANGELOG**
   ```bash
   melos run changelog:add "功能描述"
   ```

2. **发布前运行完整检查**
   ```bash
   melos run prerelease
   ```

3. **保持脚本简洁易懂**
   - 给每个脚本添加清晰的描述
   - 使用有意义的脚本名称

4. **版本发布流程标准化**
   - 使用 `melos run version:*` 命令
   - 遵循语义化版本规范

5. **CI/CD 中使用 Melos**
   - 利用 `melos run ci` 统一 CI 流程
   - 确保所有检查都通过后再合并

## 参考资料

- [Melos 官方文档](https://melos.invertase.dev/)
- [Cider 文档](https://pub.dev/packages/cider)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [语义化版本](https://semver.org/lang/zh-CN/)
