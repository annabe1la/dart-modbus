# Makefile for dart-modbus
# 提供便捷的命令别名，底层使用 Melos

.PHONY: help setup format analyze test ci clean

# 默认显示帮助
help:
	@echo "Dart Modbus - 可用命令:"
	@echo ""
	@echo "  make setup          - 安装工具并初始化项目"
	@echo "  make format         - 格式化代码"
	@echo "  make analyze        - 静态分析"
	@echo "  make test           - 运行测试"
	@echo "  make ci             - 运行完整 CI 检查"
	@echo "  make clean          - 清理构建产物"
	@echo ""
	@echo "  make tcp-slave      - 启动 TCP 从站模拟器"
	@echo "  make tcp-master     - 启动 TCP 主站模拟器"
	@echo "  make rtu-slave      - 启动 RTU 从站模拟器"
	@echo "  make rtu-master     - 启动 RTU 主站模拟器"
	@echo "  make ascii-slave    - 启动 ASCII 从站模拟器"
	@echo "  make ascii-master   - 启动 ASCII 主站模拟器"
	@echo ""
	@echo "更多命令请运行: melos run"

# 安装工具并初始化
setup:
	@echo "安装 Melos 和 Cider..."
	dart pub global activate melos
	dart pub global activate cider
	@echo "初始化项目..."
	melos bootstrap
	@echo "✓ 设置完成！"

# 代码格式化
format:
	melos run format

# 静态分析
analyze:
	melos run analyze

# 运行测试
test:
	melos run test

# 运行测试并生成覆盖率
test-coverage:
	melos run test:coverage

# 完整 CI 检查
ci:
	melos run ci

# 清理
clean:
	dart pub cache clean
	rm -rf .dart_tool build coverage

# TCP 模拟器
tcp-slave:
	melos run simulator:tcp:slave

tcp-master:
	melos run simulator:tcp:master

# RTU 模拟器
rtu-slave:
	melos run simulator:rtu:slave

rtu-master:
	melos run simulator:rtu:master

# ASCII 模拟器
ascii-slave:
	melos run simulator:ascii:slave

ascii-master:
	melos run simulator:ascii:master

# 查看 CHANGELOG
changelog:
	melos run changelog:show

# 发布补丁版本
release-patch:
	melos run version:patch

# 发布次版本
release-minor:
	melos run version:minor

# 发布主版本
release-major:
	melos run version:major
