# Ad Hoc 安装页（Firebase Hosting）

GitHub Release 会把 `install.html` / `manifest.plist` 当文件下载，**不能**用于 iPhone OTA 安装。  
请用 Firebase Hosting 发布安装页（Content-Type 正确、Safari 能正常打开）。

## 每次发新版

1. 把导出的 IPA 复制到这里：

   ```bash
   cp ~/Desktop/备忘录模拟器/NotesSimulator.ipa hosting/public/NotesSimulator.ipa
   ```

2. 如有版本变化，改 `hosting/public/index.html` 和 `manifest.plist` 里的版本号。

3. 部署：

   ```bash
   cd ~/Projects/ios-notes-simulator
   firebase login
   firebase deploy --only hosting
   ```

## 发给测试人员的链接

- 安装页：https://notes-simulator.web.app/
- 即点即装：`itms-services://?action=download-manifest&url=https://notes-simulator.web.app/manifest.plist`

GitHub Release 仍可只上传 `.ipa` 作备份；**安装请用上面 Firebase 链接**。
