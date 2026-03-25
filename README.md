# LookInside

LookInside 是一个 macOS UI 调试工具，用于检查运行在 iOS 模拟器或 USB 连接真机上的 iOS 应用视图层级。

本仓库包含：

- macOS 桌面应用（[`LookInside/`](LookInside/)）
- 共享检查库（[`Sources/`](Sources/)）
- 命令行工具 `lookinside`（[`Sources/LookInsideCLI`](Sources/LookInsideCLI)）

LookInside 是 [Lookin](https://github.com/CocoaUIInspector/Lookin) 的社区续作，保留了兼容模块名（`LookinServer`、`LookinShared`、`LookinCore`）以降低迁移成本。

## 环境要求

- macOS 11+
- Xcode 及命令行工具
- 已集成 [LookinServer](https://github.com/QMUI/LookinServer) 的可调试 iOS 应用

## 构建

```bash
swift build -c release --product lookinside
```

产物路径为 `.build/release/lookinside`，单文件独立运行，可直接拷贝给其他 macOS 11+ 的机器使用，无需额外依赖。

## 使用流程

### 第一步：在 iOS 应用中集成 LookinServer

在 `Podfile` 中添加：

```ruby
pod 'LookinServer'
```

执行 `pod install` 后，将应用运行到模拟器或 USB 连接的真机上。

### 第二步：发现目标设备

```bash
# 模拟器
lookinside list

# USB 真机
lookinside list --transport usb

# JSON 格式输出
lookinside list --format json --transport usb
```

输出示例：

```json
[
  {
    "appInfoIdentifier" : 1774438131,
    "appName" : "MyApp",
    "bundleIdentifier" : "com.example.myapp",
    "deviceDescription" : "iPhone",
    "deviceID" : "10",
    "osDescription" : "18.0",
    "port" : 47175,
    "serverReadableVersion" : "1.2.8",
    "serverVersion" : 0,
    "targetID" : "usb:10:47175:1774438131",
    "transport" : "usb"
  }
]
```

记录输出中的 `targetID`，后续命令均需要它。

### 第三步：获取视图层级

**文本树（直观易读）：**

```bash
lookinside hierarchy --target usb:10:47175:1774438131
```

输出示例：

```
- UIWindow#2 [keyWindow] frame={0, 0, 402, 874}
  - UITransitionView#8 frame={0, 0, 402, 874}
    - _UIMultiLayer#9 frame={0, 0, 402, 874}
      - UILayoutContainerView#13 frame={0, 0, 402, 874}
        - UINavigationTransitionView#18 frame={0, 0, 402, 874}
          - UIViewControllerWrapperView#20 frame={0, 0, 402, 874}
            - UIView#22 frame={0, 0, 402, 874}
              - PagerView#25 frame={0, 0, 402, 874}
                - UITableView#64 frame={0, 116, 402, 631}
```

**JSON 格式（适合程序解析或 AI 分析）：**

```bash
lookinside hierarchy --target usb:10:47175:1774438131 --format json
```

输出示例：

```json
{
  "app": {
    "appName": "MyApp",
    "bundleIdentifier": "com.example.myapp",
    "deviceDescription": "iPhone",
    "osDescription": "18.0",
    "screenWidth": 402,
    "screenHeight": 874,
    "screenScale": 3,
    "serverReadableVersion": "1.2.8"
  },
  "displayItems": [
    {
      "className": "UIWindow",
      "oid": 2,
      "frame": { "x": 0, "y": 0, "width": 402, "height": 874 },
      "alpha": 1,
      "isHidden": false,
      "representedAsKeyWindow": true,
      "children": [ ... ]
    }
  ]
}
```

输出内容较大时，建议写入文件：

```bash
lookinside hierarchy --target <targetID> --format json --output /tmp/hierarchy.json
```

### 第四步：导出快照

```bash
# JSON 文件（供其他工具消费）
lookinside export --target <targetID> --output /tmp/snapshot.json

# LookInside 归档文件（可在桌面应用中打开）
lookinside export --target <targetID> --output /tmp/snapshot.lookinside
```

## 配合 AI 使用

将层级数据输出到文件，发给 AI 助手分析：

```bash
# 一步获取并保存
lookinside hierarchy --target $(lookinside list --transport usb --ids-only) \
  --format json --output /tmp/hierarchy.json
```

将 `/tmp/hierarchy.json` 提供给 AI 后，AI 可以根据 `className`、`frame`、`alpha`、`isHidden` 以及嵌套的 `children` 结构，完整理解当前界面状态。

### Claude Code Skill

本仓库为 Claude Code 提供了内置 Skill，位于 [`skills/lookinside-cli`](skills/lookinside-cli)。

安装：

```bash
mkdir -p "${CLAUDE_HOME:-$HOME/.claude}/skills"
ln -sfn "$PWD/skills/lookinside-cli" "${CLAUDE_HOME:-$HOME/.claude}/skills/lookinside-cli"
```

安装后，Claude Code 可自动完成设备发现、层级抓取和快照导出等操作。

## 命令速查

| 命令 | 说明 |
|------|------|
| `lookinside list` | 发现可检查的应用 |
| `lookinside inspect --target <id>` | 查看目标设备元信息 |
| `lookinside hierarchy --target <id>` | 获取实时视图层级 |
| `lookinside export --target <id> --output <path>` | 导出层级快照 |

常用选项：`--format text\|json`、`--transport simulator\|usb`、`--output <path>`

## 许可证

GPL-3.0，详见 [`LICENSE`](LICENSE)。第三方组件许可证见 [`Resources/Licenses/`](Resources/Licenses/)。
