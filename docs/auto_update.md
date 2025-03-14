# GitOK 自动更新功能

GitOK 使用 [Sparkle](https://sparkle-project.org/) 框架实现自动更新功能。本文档介绍如何设置和使用自动更新功能。

## 设置步骤

### 1. 生成 Sparkle 密钥

在开发环境中，运行以下命令生成 Sparkle 密钥：

```bash
./scripts/generate_sparkle_keys.sh
```

#### macOS

对于 macOS，该命令会生成一个 EdDSA 密钥对，并将私钥存储在钥匙串中，同时输出公钥。将公钥添加到 `macos/Runner/Info.plist` 文件中：

```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

#### Windows

对于 Windows，该命令会生成一个 DSA 密钥对，并将私钥和公钥分别保存为 `dsa_priv.pem` 和 `dsa_pub.pem` 文件。将公钥添加到 `windows/runner/Runner.rc` 文件中：

```
DSAPub      DSAPEM      "../../dsa_pub.pem"
```

### 2. 构建应用

使用 Flutter 构建应用：

```bash
flutter build macos --release
```

### 3. 签名更新

构建完成后，使用以下命令签名更新：

```bash
./scripts/sign_update.sh path/to/your.dmg
```

该命令会输出签名信息，如：

```
sparkle:edSignature="YOUR_SIGNATURE_HERE" length="FILE_SIZE"
```

### 4. 生成 appcast.xml

使用以下命令生成 appcast.xml 文件：

```bash
./scripts/generate_appcast.sh path/to/your.dmg VERSION "YOUR_SIGNATURE_HERE"
```

其中 `VERSION` 是应用版本号，如 `1.1.24`，`YOUR_SIGNATURE_HERE` 是上一步生成的签名。

### 5. 发布更新

将生成的 appcast.xml 文件和 DMG 文件上传到 GitHub Releases。

## 自动更新工作流程

GitOK 使用 GitHub Actions 自动构建和发布更新。工作流程如下：

1. 当代码推送到 `pre` 分支时，触发 `Pre Release` 工作流程
2. 工作流程会自动增加版本号，构建应用，签名更新，生成 appcast.xml 文件，并发布到 GitHub Releases
3. 用户的应用会定期检查更新，当发现新版本时，会提示用户更新

## 故障排除

### macOS

- 确保已在 `macos/Runner/Info.plist` 文件中添加了正确的 `SUPublicEDKey`
- 确保已在 `macos/Runner/Info.plist` 文件中添加了网络权限：

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.app-sandbox</key>
<false/>
```

### Windows

- 确保已在 `windows/runner/Runner.rc` 文件中添加了正确的 `DSAPub` 资源
- 确保已安装了 OpenSSL

## 参考资料

- [auto_updater 插件文档](https://pub.dev/packages/auto_updater)
- [Sparkle 文档](https://sparkle-project.org/documentation/)
- [WinSparkle 文档](https://winsparkle.org/documentation/)