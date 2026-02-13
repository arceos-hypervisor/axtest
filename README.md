# Axtest

共享测试框架，用于测试 ArceOS Hypervisor 生态的各个 `no_std` 组件。

## 概述

本框架解决以下问题：

- **组件复用测试**：多个组件共享同一套测试逻辑
- **CI/本地一致**：本地开发测试与 CI 测试使用相同的流程
- **零配置**：默认测试目标内置，无需配置文件

### 架构

```
┌─────────────────────────────────────────────────────────────┐
│                   axtest (本仓库)                            │
│  ├── .github/workflows/test.yml               # 可复用 CI   │
│  ├── tests.sh                                 # 本地测试   │
│  └── wrapper.sh                               # 组件包装   │
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

### 1. 添加 CI 配置

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
    uses: arceos-hypervisor/axtest/.github/workflows/test.yml@main
```

**说明**：默认测试目标为 `axvisor` 和 `starry`，无需额外配置。

### 2. 本地测试

在组件目录中运行：

```bash
# 方式一：直接下载脚本运行
curl -sSL https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/wrapper.sh | bash -s -- --target axvisor

# 方式二：添加包装脚本到组件仓库
curl -o scripts/run_tests.sh https://raw.githubusercontent.com/arceos-hypervisor/axtest/main/wrapper.sh
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

## 默认测试目标

框架内置以下测试目标，与 `axci/.github/workflows/test.yml` 保持一致：

| 目标 | 仓库 | 构建命令 |
|------|------|----------|
| axvisor | arceos-hypervisor/axvisor | `make build A=examples/linux` |
| starry | Starry-OS/StarryOS | `make build` |

## 高级配置（可选）

如需自定义测试目标，可在组件目录创建 `.github/config.json`：

```json
{
  "component": {
    "name": "your_component",
    "crate_name": "your_component"
  },
  "test_targets": [
    {
      "name": "custom_target",
      "repo": {
        "url": "https://github.com/org/repo",
        "branch": "main"
      },
      "build": {
        "command": "make build",
        "timeout_minutes": 15
      }
    }
  ]
}
```

### 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `component.name` | | 组件显示名称（默认从目录名获取） |
| `component.crate_name` | | Cargo crate 名称（默认从 Cargo.toml 获取） |
| `test_targets[].name` | ✅ | 测试目标标识 |
| `test_targets[].repo.url` | ✅ | 测试目标仓库 URL |
| `test_targets[].repo.branch` | | Git 分支 (默认: main) |
| `test_targets[].build.command` | ✅ | 构建命令 |
| `test_targets[].build.timeout_minutes` | | 超时时间 (默认: 15) |
| `patch.path_template` | | 组件路径模板 (默认: ../component) |

## 本地测试脚本选项

```bash
./tests.sh [选项]

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
| `crate_name` | 组件 crate 名称 | 自动检测 |
| `test_targets` | 测试目标 (逗号分隔) | all |
| `skip_build` | 跳过构建 | false |

## 工作原理

### 测试流程

1. 克隆测试目标仓库 (axvisor/StarryOS)
2. 修改其 `Cargo.toml`，添加 `[patch.crates-io]` 指向组件
3. 执行构建命令

### 本地测试与 CI 一致性

本地测试脚本 `tests.sh` 使用与 `axci/.github/workflows/test.yml` 相同的默认测试目标，无需额外配置即可运行。

## 常见问题

### Q: 如何调试构建失败？

```bash
# 本地使用 verbose 模式
./tests.sh -v --no-cleanup

# 检查生成的文件
ls test-results/repos/
cat test-results/logs/*.log
```

### Q: 如何只测试单个目标？

```bash
./tests.sh --target axvisor
```

## 目录结构

```
axtest/
├── .github/
│   └── workflows/
│       └── test.yml                # 可复用 CI workflow
├── tests.sh                        # 本地测试脚本
├── wrapper.sh                      # 组件包装脚本
└── README.md                       # 本文档
```

## 贡献

欢迎贡献代码或提出建议！

## License

Apache-2.0
