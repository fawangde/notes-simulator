# 备忘录 v1.1.0 安装发布说明

## Release 要上传的文件

在 GitHub Release `v1.1.0` 中上传以下 3 个文件：

| 文件 | 来源 |
|------|------|
| `NotesSimulator.ipa` | `~/Desktop/备忘录模拟器/NotesSimulator.ipa` |
| `manifest.plist` | 本目录 `release/manifest.plist` |
| `install.html` | 本目录 `release/install.html` |

## Safari 安装链接（发给用户）

发布 Release 后，用户在 **iPhone Safari** 打开：

```
https://github.com/fawangde/notes-simulator/releases/download/v1.1.0/install.html
```

或直接安装（manifest）：

```
itms-services://?action=download-manifest&url=https://github.com/fawangde/notes-simulator/releases/download/v1.1.0/manifest.plist
```

## 用户安装步骤

1. 用 Safari 打开上面的 `install.html` 链接
2. 点「安装 App」
3. 设置 → 通用 → VPN 与设备管理 → 信任 **chi Xu**
4. 桌面出现「备忘录」

## 推送源码

```bash
cd ~/Projects/ios-notes-simulator
git add .
git commit -m "v1.1.0: iOS 17–18 样式、激活、时间小字等"
git push origin main
```
