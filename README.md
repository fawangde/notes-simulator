# 备忘录模拟（原生 iOS App）

SwiftUI 原生 iPhone 应用，模拟 iOS 备忘录、长按号码菜单与「新 iMessage 信息」界面（无真实通讯）。

## 打开项目

1. 双击或用 Xcode 打开：

   `~/Projects/ios-notes-simulator/NotesSimulator.xcodeproj`

2. **解决签名（必做）**
   - 左侧点蓝色工程 **NotesSimulator** → 中间选 **TARGETS → NotesSimulator**
   - 打开 **Signing & Capabilities**
   - 勾选 **Automatically manage signing**
   - **Team** 下拉选你的账号（Personal Team / 个人团队）
   - 若 Team 为空：菜单 **Xcode → Settings → Accounts**，点 **+** 登录 Apple ID，再回到这里选 Team
   - 若提示 Bundle ID 冲突：把 **Bundle Identifier** 改成唯一值，例如 `com.你的英文名.notesimulator`

3. 顶部选择 **iPhone 模拟器** 或已连接的真机，按 **⌘R** 运行。

## 命令行编译（可选）

```bash
cd ~/Projects/ios-notes-simulator
xcodebuild -scheme NotesSimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 使用流程

1. **首页**：选择纯文 / 图片 / 图文，配置 iMessage 气泡内容。
2. **模拟备忘录**：编辑日期、标题、正文（可粘贴含 11 位手机号的内容）。
3. **长按金黄色号码**：弹出与系统相似的菜单，点 **信息**（页面自底部滑入）。
4. 点 **✕**：iMessage 页面向下滑出关闭。

## 项目结构

| 路径 | 说明 |
|------|------|
| `NotesSimulator/` | Swift 源码 |
| `NotesSimulator.xcodeproj` | Xcode 工程 |
| `web/` | 早期网页演示（可选） |

## 系统要求

- Xcode 15+（已在 Xcode 26 验证工程格式）
- iOS 16.0+
- Swift 5
