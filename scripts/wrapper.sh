#!/bin/bash
#
# 组件测试包装脚本
# 复制此脚本到组件的 scripts/ 目录即可使用
#
# 用法:
#   curl -o scripts/run_tests.sh https://raw.githubusercontent.com/arceos-hypervisor/hypervisor-test-framework/main/scripts/wrapper.sh
#   chmod +x scripts/run_tests.sh
#   ./scripts/run_tests.sh
#

set -e

FRAMEWORK_REPO="${HYPVISOR_TEST_FRAMEWORK_REPO:-https://github.com/arceos-hypervisor/hypervisor-test-framework}"
FRAMEWORK_BRANCH="${HYPVISOR_TEST_FRAMEWORK_BRANCH:-main}"
FRAMEWORK_CACHE="${HYPVISOR_TEST_FRAMEWORK_CACHE:-$HOME/.cache/hypervisor-test-framework}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 下载或更新测试框架
download_framework() {
    log "获取测试框架..."
    
    mkdir -p "$(dirname "$FRAMEWORK_CACHE")"
    
    if [ -d "$FRAMEWORK_CACHE" ]; then
        (cd "$FRAMEWORK_CACHE" && git pull -q 2>/dev/null) || true
    else
        git clone --depth 1 -b "$FRAMEWORK_BRANCH" "$FRAMEWORK_REPO" "$FRAMEWORK_CACHE"
    fi
    
    log_success "测试框架就绪"
}

# 运行测试
run_tests() {
    exec "$FRAMEWORK_CACHE/scripts/run_tests.sh" \
        --component-dir "$COMPONENT_DIR" \
        "$@"
}

# 主函数
main() {
    download_framework
    run_tests "$@"
}

main "$@"
