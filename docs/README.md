# GitHub Pages 安装（与 ZGzaishaAPP 相同方式）

上一个项目能装，是因为用了 **GitHub Pages**，不是 GitHub Release。

| 方式 | 结果 |
|------|------|
| `github.com/.../releases/download/...` | Safari 当文件下载 ❌ |
| `fawangde.github.io/notes-simulator/...` | 正常 OTA 安装 ✅ |

## 首次：开启 Pages

1. 打开 https://github.com/fawangde/notes-simulator/settings/pages
2. **Build and deployment → Source**：Deploy from a branch
3. **Branch**：`main` → 文件夹选 **`/docs`** → Save
4. 等 1～2 分钟，出现 `Your site is live at https://fawangde.github.io/notes-simulator/`

## 每次发新版

```bash
cp ~/Desktop/备忘录模拟器/NotesSimulator.ipa ~/Projects/ios-notes-simulator/docs/NotesSimulator.ipa
cd ~/Projects/ios-notes-simulator
git add docs/
git commit -m "v1.1.0: 更新安装包"
GIT_HTTP_VERSION=1.1 git push origin main
```

如有版本变化，同步改 `docs/DistributionSummary.plist` 里的 `bundle-version` 和 `index.html` 文案。

## 发给测试人员

**安装页：**

```
https://fawangde.github.io/notes-simulator/
```

**即点即装：**

```
itms-services://?action=download-manifest&url=https://fawangde.github.io/notes-simulator/DistributionSummary.plist
```

iPhone **Safari** 打开 → 点「安装 App」→ 信任 **chi Xu**。
