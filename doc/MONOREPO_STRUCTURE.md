# Monorepo 项目结构说明

本项目采用 monorepo 结构，使用 Melos 进行管理。

## 📁 目录结构

```
dart-modbus/                          # 根目录（工作区）
├── packages/                         # 所有包的目录
│   ├── dart_modbus/                  # 核心 Modbus 库包
│   │   ├── lib/                      # 库源代码
│   │   │   ├── modbus.dart           # 公共 API 入口
│   │   │   └── src/                  # 内部实现
│   │   │       ├── client.dart       # 客户端接口
│   │   │       ├── client_tcp.dart   # TCP 客户端
│   │   │       ├── client_rtu.dart   # RTU 客户端
│   │   │       ├── client_ascii.dart # ASCII 客户端
│   │   │       ├── server_tcp.dart   # TCP 服务器
│   │   │       ├── data_converter.dart # 数据转换
│   │   │       ├── register_map.dart # 寄存器映射
│   │   │       └── ...
│   │   ├── test/                     # 单元测试
│   │   │   ├── crc_test.dart
│   │   │   ├── lrc_test.dart
│   │   │   └── data_converter_test.dart
│   │   ├── example/                  # 使用示例
│   │   │   ├── client_tcp_example.dart
│   │   │   ├── client_rtu_example.dart
│   │   │   └── ...
│   │   ├── pubspec.yaml              # 包依赖配置
│   │   ├── CHANGELOG.md              # 变更日志
│   │   ├── README.md                 # 包说明文档
│   │   └── LICENSE                   # 许可证
│   │
│   └── modbus_simulator/             # 模拟器工具包
│       ├── bin/                      # 可执行文件
│       │   ├── slave_simulator.dart  # 从站模拟器
│       │   └── master_simulator.dart # 主站模拟器
│       ├── config/                   # 配置文件
│       │   └── device_config.yaml    # 设备配置示例
│       ├── pubspec.yaml              # 包依赖（依赖 dart_modbus）
│       └── README.md                 # 使用说明
│
├── doc/                              # 共享文档
│   ├── FAQ.md                        # 常见问题
│   ├── MELOS_GUIDE.md                # Melos 使用指南
│   ├── CHANGELOG_GUIDE.md            # CHANGELOG 管理指南
│   └── MONOREPO_STRUCTURE.md         # 本文档
│
├── melos.yaml                        # Melos 配置文件
├── pubspec.yaml                      # 工作区根依赖
├── Makefile                          # 便捷命令
├── QUICK_START.md                    # 快速开始指南
├── README.md                         # 项目总览
├── CHANGELOG.md                      # 工作区变更日志
└── LICENSE                           # 许可证

```

## 📦 包说明

### dart_modbus

**发布状态**: ✅ 可发布到 pub.dev
**用途**: 核心 Modbus 协议实现库
**依赖**: `yaml: ^3.1.0`

这是可以独立发布和使用的 Dart 包，提供完整的 Modbus 协议支持。

**安装方式**:
```yaml
dependencies:
  dart_modbus: ^1.0.0
```

### modbus_simulator

**发布状态**: ❌ 不发布（`publish_to: none`）
**用途**: 开发和测试工具
**依赖**: `dart_modbus`（本地路径依赖）

这是内部工具包，用于开发和测试 Modbus 通信。不会发布到 pub.dev。

**使用方式**:
```bash
# 通过 Melos 运行
melos run simulator:slave
melos run simulator:master

# 或直接运行
dart run packages/modbus_simulator/bin/slave_simulator.dart
```

## 🔗 包依赖关系

```
modbus_simulator
    └─> dart_modbus (path: ../dart_modbus)
```

modbus_simulator 依赖本地的 dart_modbus 包。

## 🛠️ 工作流程

### 开发核心库（dart_modbus）

```bash
# 进入包目录
cd packages/dart_modbus

# 运行测试
dart test

# 或者在根目录使用 Melos
melos run test --scope=dart_modbus
```

### 开发模拟器（modbus_simulator）

```bash
# 在根目录运行模拟器
melos run simulator:slave

# 或进入包目录
cd packages/modbus_simulator
dart run bin/slave_simulator.dart
```

### 添加新包

1. 在 `packages/` 下创建新目录
2. 创建 `pubspec.yaml`
3. Melos 会自动识别（因为 `melos.yaml` 中配置了 `packages/**`）
4. 运行 `melos bootstrap`

## 📝 版本管理策略

### dart_modbus 版本

- 遵循语义化版本（Semantic Versioning）
- 每次发布更新 `packages/dart_modbus/CHANGELOG.md`
- 更新 `packages/dart_modbus/pubspec.yaml` 版本号

### modbus_simulator 版本

- 版本号跟随工作区（不独立发布）
- 不需要严格的版本管理
- 变更记录在根目录 `CHANGELOG.md`

### 使用 Cider 管理版本

```bash
# 在 dart_modbus 包目录下
cd packages/dart_modbus
cider log added "新功能描述"
cider bump minor
cider release
```

## 🔄 Melos 命令映射

| 命令 | 作用域 | 说明 |
|------|--------|------|
| `melos run test` | 所有包 | 运行所有测试 |
| `melos run analyze` | 所有包 | 静态分析 |
| `melos run format` | 所有包 | 格式化代码 |
| `melos run simulator:slave` | modbus_simulator | 启动从站 |
| `melos run example:tcp` | dart_modbus | 运行 TCP 示例 |

### 使用作用域过滤

```bash
# 仅在 dart_modbus 包中运行测试
melos run test --scope=dart_modbus

# 在所有包中运行命令
melos exec -- dart analyze

# 排除某些包
melos exec --ignore=modbus_simulator -- dart pub upgrade
```

## 🚀 发布流程

### 发布 dart_modbus 到 pub.dev

```bash
# 1. 切换到包目录
cd packages/dart_modbus

# 2. 确保所有测试通过
dart test

# 3. 更新版本和 CHANGELOG
cider bump minor
cider release

# 4. 提交变更
git add CHANGELOG.md pubspec.yaml
git commit -m "chore(dart_modbus): release v1.1.0"

# 5. 发布到 pub.dev
dart pub publish

# 6. 打标签
git tag dart_modbus-v1.1.0
git push origin main --tags
```

## 💡 最佳实践

### 1. 包独立性

- 每个包应该能够独立测试和构建
- dart_modbus 不应依赖 modbus_simulator
- 保持清晰的依赖边界

### 2. 共享代码

如果需要在多个包之间共享代码：
- 创建新的共享包（如 `packages/shared/`）
- 或将共享代码放在 dart_modbus 中作为公共 API

### 3. 文档维护

- 每个包有自己的 README.md
- 根目录 README.md 提供总览
- 详细文档放在 `doc/` 目录

### 4. 测试策略

- 核心库（dart_modbus）需要完整的单元测试
- 模拟器（modbus_simulator）可以有简单的集成测试
- 使用 `melos run ci` 运行完整测试套件

## 🔍 常见问题

### Q: 为什么要使用 monorepo？

**A**:
- 统一管理相关的多个包
- 共享配置和工具
- 方便跨包开发和测试
- 简化依赖管理

### Q: modbus_simulator 为什么不发布？

**A**:
- 这是开发工具，不是库
- 用户可以直接克隆仓库使用
- 避免 pub.dev 上的包泛滥

### Q: 如何在 modbus_simulator 中使用最新的 dart_modbus？

**A**:
modbus_simulator 通过路径依赖使用本地的 dart_modbus：
```yaml
dependencies:
  dart_modbus:
    path: ../dart_modbus
```
任何对 dart_modbus 的修改会立即在 modbus_simulator 中生效。

### Q: 可以添加更多包吗？

**A**:
可以！只需在 `packages/` 下创建新目录，Melos 会自动识别。例如：
- `packages/modbus_gateway` - 网关实现
- `packages/modbus_web` - Web 界面
- `packages/modbus_cli` - 命令行工具

## 📚 参考资料

- [Melos 官方文档](https://melos.invertase.dev/)
- [Monorepo 最佳实践](https://monorepo.tools/)
- [Dart 包开发指南](https://dart.dev/guides/libraries/create-library-packages)
