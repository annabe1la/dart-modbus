# 快速开始

## 安装开发工具

```bash
# 安装 Melos（monorepo 管理）
dart pub global activate melos

# 安装 Cider（CHANGELOG 管理）
dart pub global activate cider

# 添加全局命令到 PATH（根据你的 shell 选择配置文件）
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc  # 或重启终端
```

## 初始化项目

```bash
# 克隆项目
git clone https://github.com/yourname/dart-modbus.git
cd dart-modbus

# 使用 Melos 初始化
melos bootstrap
```

## 日常开发

### 查看所有可用命令

```bash
melos run
```

### 运行测试和检查

```bash
# 代码格式化
melos run format

# 静态分析
melos run analyze

# 运行测试
melos run test

# 完整 CI 检查
melos run ci
```

### 记录变更

开发过程中，每完成一个功能或修复一个 bug，立即记录：

```bash
# 新功能
melos run changelog:add "支持 Modbus RTU over UDP"

# Bug 修复
melos run changelog:fix "修复 TCP 连接超时问题"

# 功能变更
melos run changelog:change "优化数据转换性能"

# 查看未发布的变更
melos run changelog:show
```

### 测试模拟器

```bash
# 终端 1：启动从站
melos run simulator:slave

# 终端 2：启动主站
melos run simulator:master
```

## 版本发布

```bash
# 1. 确保所有测试通过
melos run ci

# 2. 查看即将发布的变更
melos run changelog:show

# 3. 发布版本（根据变更类型选择）
melos run version:patch   # 1.0.0 -> 1.0.1 (bug 修复)
# 或
melos run version:minor   # 1.0.0 -> 1.1.0 (新功能)
# 或
melos run version:major   # 1.0.0 -> 2.0.0 (破坏性变更)

# 4. 提交并推送
git add CHANGELOG.md pubspec.yaml pubspec.lock
git commit -m "chore(release): publish v1.1.0"
git tag v1.1.0
git push origin main --tags

# 5. 发布到 pub.dev
dart pub publish
```

## 项目结构

```
dart-modbus/
├── lib/                    # 核心库代码
│   ├── modbus.dart         # 公共 API 入口
│   └── src/                # 实现代码
├── example/                # 使用示例
├── simulator/              # 主站/从站模拟器
├── test/                   # 单元测试
├── doc/                    # 文档
│   ├── FAQ.md              # 常见问题
│   ├── MELOS_GUIDE.md      # Melos 详细指南
│   └── CHANGELOG_GUIDE.md  # CHANGELOG 管理指南
├── melos.yaml              # Melos 配置
└── CHANGELOG.md            # 变更日志
```

## 详细文档

- [Melos 使用指南](doc/MELOS_GUIDE.md) - 完整的 Melos 命令和工作流
- [CHANGELOG 管理指南](doc/CHANGELOG_GUIDE.md) - Cider 详细用法
- [FAQ](doc/FAQ.md) - 常见问题解答
- [README](README.md) - 项目概述和 API 文档

## 常用 Melos 命令速查

| 命令 | 说明 |
|------|------|
| `melos bootstrap` | 初始化项目 |
| `melos run format` | 格式化代码 |
| `melos run analyze` | 静态分析 |
| `melos run test` | 运行测试 |
| `melos run ci` | 完整 CI 检查 |
| `melos run changelog:add "..."` | 添加新功能到 CHANGELOG |
| `melos run changelog:fix "..."` | 添加修复到 CHANGELOG |
| `melos run changelog:show` | 查看未发布的变更 |
| `melos run version:patch` | 发布补丁版本 |
| `melos run simulator:slave` | 启动从站模拟器 |
| `melos run simulator:master` | 启动主站模拟器 |

## 贡献

1. Fork 项目
2. 创建功能分支：`git checkout -b feature/new-feature`
3. 开发并记录变更：`melos run changelog:add "新功能"`
4. 运行测试：`melos run ci`
5. 提交代码：`git commit -am "feat: add new feature"`
6. 推送分支：`git push origin feature/new-feature`
7. 创建 Pull Request

## 需要帮助？

- 查看 [FAQ](doc/FAQ.md)
- 阅读 [Melos 指南](doc/MELOS_GUIDE.md)
- 提交 Issue: https://github.com/yourname/dart-modbus/issues
