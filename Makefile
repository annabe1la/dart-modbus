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
	@echo "  make slave          - 启动从站模拟器"
	@echo "  make master         - 启动主站模拟器"
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

# 启动从站模拟器
slave:
	melos run simulator:slave

# 启动主站模拟器
master:
	melos run simulator:master

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
