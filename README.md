# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

基于 Modrinth 平台的 Minecraft 整合包构建工具，通过 `config.json` + `build.ps1` 实现可复现的 `.mrpack` 打包流程。

## ✨ 特性

- **声明式配置** — 只需填写 `modpack/config.json` 即可定义模组列表
- **自动依赖解析** — 通过 Modrinth API 拉取指定版本模组及依赖
- **SHA1 哈希校验** — 确保下载文件完整性
- **平台适配** — 支持 Fabric / Forge / NeoForge / Quilt 四种加载器
- **可选模组机制** — `optional: true` 的模组默认跳过，可通过参数启用
- **一键打包** — 生成符合 Modrinth 规范的 `.mrpack` 文件

## 📦 当前整合包

| 项目 | 详情 |
|------|------|
| **名称** | 机械动力整合包 (Fabric) |
| **Minecraft** | 1.20.1 |
| **Loader** | Fabric 0.17.2 |
| **核心模组** | Create (机械动力) |
| **模组数量** | 20 个（含可选） |

### 模组列表

| 类别 | 模组 |
|------|------|
| 框架前置 | Fabric API, Fabric Language Kotlin, libIPN |
| 核心 | Create (Fabric), Create: Steam 'n' Rails (可选) |
| 联机 | e4mc |
| 领地 | Open Parties and Claims |
| 地图 | JourneyMap |
| 辅助 | JEI, Jade, AppleSkin, Mouse Tweaks, Clumps, Controlling, Searchables, Just Enough Resources, Inventory Profiles Next |
| 优化 | Sodium, Lithium, FerriteCore, ModernFix |

## 🚀 快速开始

### 前置要求

- Windows 系统（构建脚本为 PowerShell 5.1）
- 网络连接（需访问 Modrinth API）

### 构建整合包

```powershell
# 基础构建（跳过可选模组）
.\modpack\build.ps1

# 包含可选模组
.\modpack\build.ps1 -IncludeOptional

# 指定输出名称
.\modpack\build.ps1 -PackName "my-custom-pack"
```

构建产物 `.mrpack` 位于 `modpack/build/` 目录。

### 安装整合包

1. 下载并安装 [Prism Launcher](https://prismlauncher.org/) 或 [Modrinth App](https://modrinth.com/app)
2. 将 `.mrpack` 文件拖入启动器窗口
3. 启动器将自动安装 Minecraft、加载器和所有模组

## 📁 项目结构

```text
.
├── LICENSE                 # MIT 许可证
├── .gitignore
├── modpack/
│   ├── config.json         # 整合包配置（模组列表、版本、加载器）
│   ├── build.ps1           # 构建脚本（PowerShell 5.1）
│   └── overrides/          # 覆盖文件
│       ├── config/         # 模组配置
│       ├── server.properties
│       └── README.md       # 用户使用说明（中文）
└── skill/                  # AI 辅助构建 Skill 定义
    ├── SKILL.md            # Skill 核心定义与工作流
    └── agents/             # Agent 配置
```

## 🛠 自定义整合包

编辑 `modpack/config.json`：

```json
{
  "formatVersion": 1,
  "game": "minecraft",
  "versionId": "1.20.1",
  "name": "我的整合包",
  "summary": "整合包简介",
  "dependencies": {
    "minecraft": "1.20.1",
    "fabric-loader": "0.17.2"
  },
  "mods": [
    {
      "name": "Fabric API",
      "slug": "fabric-api",
      "platform": "modrinth",
      "side": "both",
      "note": "Fabric 前置依赖"
    }
  ]
}
```

## 📄 许可证

[MIT](LICENSE) © 2025 Aknirex
