# macOS 内置盘空间治理

一个可通过 Skills CLI 安装的 Agent Skill，用来帮助 macOS 用户长期治理紧张的内置磁盘空间。

它不是“清理垃圾”的脚本，而是一套让数据有序流动的治理方法：先看见压力，再按热度、风险和可恢复性决定留在内置盘、归档到外置存储，还是安全迁移路径。

## 道：先建立秩序，而不是先删除文件

> 内置盘是热工作台，不是仓库；外置盘 / SMB 是冷库，不是活体系统盘。磁盘治理的本质，是让数据按热度、风险、可恢复性有秩序地流动。

这套 skill 的判断原则：

- **空间紧张不是一次性清理问题，而是文件生命周期问题。** 文件会创建、使用、沉淀、归档、删除；缺的是节奏。
- **内置盘只放正在发生的事。** 当前项目、活跃 app 数据、近期文档、必要缓存应该留在本机。
- **外置盘 / SMB 放已经沉淀的资料。** 旧下载、会议录像、导出文件、历史素材、旧交付物适合成为冷数据。
- **路径是契约。** 有些路径必须保持真实目录，有些路径可以软链，有些路径只能通过 app 官方方式迁移。
- **自动化先做提醒和 dry-run。** 删除、移源文件、创建软链、定时执行变更都必须先说明影响、验证方式和回滚方式。

## 术：三层治理动作

### 1. 先看见：定时提醒检查

适合所有用户。只做报告，不自动移动或删除。

- 定期检查内置盘剩余空间和主要增长目录。
- 用 `ncdu -x` 或 `scripts/triage.sh` 建立基线。
- 设置阈值，例如“低于 60 GB 提醒”或“Downloads 超过 20 GB 提醒”。

### 2. 再流动：不可软链的周期归档

适合 Downloads、会议录像、导出目录、扫描件、工程交付物等持续增长的目录。

- 源目录继续是真实本地目录，新文件仍正常落入内置盘。
- 冷文件按年龄阈值归档到 `/Volumes/...`。
- 先 dry-run 展示会移动什么，再确认是否执行。

### 3. 最后重构：可软链的永久迁移

适合大模型、数据集、只读素材库等用户可控、低频、读多写少的大目录。

- 先复制到外置盘 / SMB。
- 把原目录改名为备份。
- 在原路径创建软链。
- 保留备份，直到重启 / 重新挂载后验证正常。

不建议软链 Photos、Mail、Messages、iCloud / Dropbox / OneDrive / Google Drive 根目录、Docker 磁盘镜像、VM、数据库、活跃源码仓库。

## 它解决什么

- 非技术办公室白领：下载、桌面、文档、会议录像、导出文件的长期治理。
- 技术工程师：缓存、构建产物、包管理器、模拟器、Docker、模型、数据集、仓库产物。
- 外置存储：已挂载在 `/Volumes/...` 的 SMB 私有云或外接磁盘。
- 三类治理动作：定时提醒检查、不可软链的周期归档、可软链的永久迁移。
- 工具优先级：`ncdu -x` 做同文件系统审计，`rsync` 做 dry-run-first 的归档和迁移。

## 安装

使用 Skills CLI 安装：

```bash
npx skills add -g nickhoo555/macos-disk-space-governor --skill macos-disk-space-governor
```

或使用 pnpm：

```bash
pnpm dlx skills add -g nickhoo555/macos-disk-space-governor --skill macos-disk-space-governor
```

本地 checkout 测试：

```bash
npx skills add . --skill macos-disk-space-governor
```

## 仓库结构

```text
skills/
└── macos-disk-space-governor/
    ├── SKILL.md
    ├── agents/openai.yaml
    ├── references/
    │   ├── long-term-governance.md
    │   └── playbooks.md
    └── scripts/
        ├── periodic_archive.sh
        ├── relocate_with_symlink.sh
        ├── rsync_archive.sh
        └── triage.sh
```

## 安全立场

默认只读审计和 dry-run；真正删除、迁移、定时执行变更、创建软链前，都必须明确说明影响、验证方式和回滚方式，并得到确认。
