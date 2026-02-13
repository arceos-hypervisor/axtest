# Axtest

共享测试框架，用于测试 ArceOS Hypervisor 生态的各个 `no_std` 组件。

## 概述

本框架解决以下问题：

- **组件复用测试**：多个组件共享同一套测试逻辑
- **CI/本地一致**：本地开发测试与 CI 测试使用相同的流程
- **简单配置**：组件只需在 `.github/config.json` 中配置即可接入

### 架构

```
┌─────────────────────────────────────────────────────────────┐
│                   axtest (本仓库)                            │
│  ├── .github/workflows/integration-test.yml   # 可复用 CI   │
│  ├── scripts/run_tests.sh                     # 本地测试   │
│  ├── scripts/wrapper.sh                       # 组件包装   │
│  └── schema.json                              # 配置规范   │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
           ▼                  ▼                  ▼
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │  arm_vcpu   │    │  arm_gic    │    │  arm_psci   │
    │  (组件)     │    │  (组件)     │    │  (组件)     │
    └─────────────┘    └─────────────┘    └─────────────┘
```

## 快速开始

### 1. 在组件中创建配置文件

在组件仓库的 `.github/config.json` 中添加测试配置：

```json
{
  "component": {
    "name": "your_component",
    "crate_name": "your_component"
  },
  "test_targets": [
    {
      "name": "axvisor",
      "repo": {
        "url": "https://github.com/arceos-hypervisor/axvisor",
        "branch": "main"
      },
      "build": {
        "command": "make build A=examples/linux",
        "timeout_minutes": 15
      }
    }
  ]
}
```

### 2. 添加 CI 配置

创建 `.github/workflows/test.yml`：

```yaml
name: Test

on:
  push:
    branches: [main, master]
  pull_request:
  workflow_dispatch:

jobs:
  test:
    uses: arceos-hypervisor/axtest/.github/workflows/integration-test.yml@main
    with:
      component_repo: ${{ github.repository }}
      component_ref: ${{ github.ref }}
```

### 3. 本地测试

在组件目录中运行：

```bash
# 方式一：直接下载脚本运行
curl -sSL https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/scripts/wrapper.sh | bash -s -- --target axvisor

# 方式二：添加包装脚本到组件仓库
curl -o scripts/run_tests.sh https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/scripts/wrapper.sh
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

## 配置参考

### 完整配置示例

```json
{
  "$schema": "https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/schema.json",
  "targets": [
    "aarch64-unknown-none-softfloat"
  ],
  "rust_components": [
    "rust-src",
    "clippy",
    "rustfmt",
    "llvm-tools"
  ],
  "component": {
    "name": "arm_vcpu",
    "crate_name": "arm_vcpu",
    "description": "AArch64 virtual CPU implementation"
  },
  "test_targets": [
    {
      "name": "axvisor",
      "repo": {
        "url": "https://github.com/arceos-hypervisor/axvisor",
        "branch": "main"
      },
      "build": {
        "command": "make build A=examples/linux",
        "timeout_minutes": 15,
        "env": {
          "RUST_LOG": "debug"
        }
      }
    },
    {
      "name": "starry",
      "repo": {
        "url": "https://github.com/Starry-OS/StarryOS",
        "branch": "main"
      },
      "build": {
        "command": "make build",
        "timeout_minutes": 15
      }
    }
  ],
  "patch": {
    "section": "crates-io",
    "path_template": "../component"
  }
}
```

### 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `component.name` | ✅ | 组件显示名称 |
| `component.crate_name` | ✅ | Cargo crate 名称 |
| `test_targets[].name` | ✅ | 测试目标标识 |
| `test_targets[].repo.url` | ✅ | 测试目标仓库 URL |
| `test_targets[].repo.branch` | | Git 分支 (默认: main) |
| `test_targets[].build.command` | ✅ | 构建命令 |
| `test_targets[].build.timeout_minutes` | | 超时时间 (默认: 15) |
| `patch.path_template` | | 组件路径模板 (默认: ../..) |

## 示例：arm_vcpu 组件

`arm_vcpu` 是使用本框架的示例组件，其结构如下：

```
arm_vcpu/
├── .github/
│   ├── config.json            # 统一配置 (Rust 配置 + 测试配置)
│   └── workflows/
│       └── test.yml           # 引用共享 CI
├── scripts/
│   └── run_tests.sh           # 本地测试包装脚本
└── src/
    └── ...
```

### arm_vcpu 的 .github/config.json

```json
{
  "$schema": "https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/schema.json",
  "targets": [
    "aarch64-unknown-none-softfloat"
  ],
  "rust_components": [
    "rust-src",
    "clippy",
    "rustfmt",
    "llvm-tools"
  ],
  "component": {
    "name": "arm_vcpu",
    "crate_name": "arm_vcpu",
    "description": "AArch64 virtual CPU implementation"
  },
  "test_targets": [
    {
      "name": "axvisor",
      "repo": {
        "url": "https://github.com/arceos-hypervisor/axvisor",
        "branch": "main"
      },
      "build": {
        "command": "make build A=examples/linux",
        "timeout_minutes": 15
      }
    },
    {
      "name": "starry",
      "repo": {
        "url": "https://github.com/Starry-OS/StarryOS",
        "branch": "main"
      },
      "build": {
        "command": "make build",
        "timeout_minutes": 15
      }
    }
  ],
  "patch": {
    "path_template": "../component"
  }
}
```

### arm_vcpu 的 CI 配置

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [master, main]
  pull_request:
  workflow_dispatch:

jobs:
  test:
    uses: arceos-hypervisor/axtest/.github/workflows/integration-test.yml@main
    with:
      component_repo: ${{ github.repository }}
      component_ref: ${{ github.ref }}
```

## 本地测试脚本选项

```bash
./scripts/run_tests.sh [选项]

选项:
  -t, --target TARGET      测试目标: all, axvisor, starry (默认: all)
  -v, --verbose            详细输出
  --dry-run                仅显示命令，不执行
  --no-cleanup             不清理临时文件
  --sequential             顺序执行 (默认并行)
  -h, --help               显示帮助
```

## CI Workflow 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `component_repo` | 组件仓库 (owner/repo) | 必需 |
| `component_ref` | 组件分支或 tag | main |
| `test_framework_ref` | 测试框架版本 | main |
| `test_targets` | 测试目标 (逗号分隔) | all |
| `skip_build` | 跳过构建 | false |
| `rust_toolchain` | Rust 工具链 | nightly |

## 工作原理

### CI 测试流程

1. **编译检查**：验证组件能够正确编译
2. **集成测试**：
   - 克隆测试目标仓库 (axvisor/StarryOS)
   - 修改其 `Cargo.toml`，添加 `[patch.crates-io]` 指向组件
   - 执行构建命令
3. **结果汇总**：生成测试报告

### 本地测试流程

与 CI 相同，但在本地执行：
1. 下载或更新测试框架
2. 根据配置克隆测试目标
3. 应用 patch 并构建

## 常见问题

### Q: 如何添加新的测试目标？

在 `.github/config.json` 的 `test_targets` 数组中添加新条目：

```json
{
  "name": "new_target",
  "repo": { "url": "https://github.com/org/repo" },
  "build": { "command": "make build" }
}
```

### Q: 如何调试构建失败？

```bash
# 本地使用 verbose 模式
./scripts/run_tests.sh -v --no-cleanup

# 检查生成的文件
ls test-results/repos/
cat test-results/logs/*.log
```

### Q: patch 路径不正确怎么办？

调整 `patch.path_template`：
- `../component` - 测试框架在父目录
- `../..` - 测试框架在工作目录子目录
- 绝对路径也可以

## 目录结构

```
axtest/
├── .github/
│   └── workflows/
│       └── integration-test.yml   # 可复用 CI workflow
├── scripts/
│   ├── run_tests.sh               # 核心测试脚本
│   └── wrapper.sh                 # 组件包装脚本
├── schema.json                    # JSON Schema 配置规范
└── README.md                      # 本文档
```

## 贡献

欢迎贡献代码或提出建议！

## License

Apache-2.0
