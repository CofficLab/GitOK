/// 更新服务 - 负责检查、下载和安装应用更新
///
/// 这个服务类处理应用程序的自动更新流程，包括：
/// - 检查新版本
/// - 下载更新包
/// - 安装更新
/// - 提供更新进度和状态通知
///
/// 就像一个勤劳的快递员 📦，随时准备给你送来最新鲜的应用版本！

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as path;

/// 更新状态枚举
enum UpdateStatus {
  idle, // 空闲状态
  checking, // 检查更新中
  available, // 有可用更新
  notAvailable, // 没有可用更新
  downloading, // 下载更新中
  downloaded, // 更新已下载
  installing, // 安装更新中
  error, // 更新过程出错
}

/// 更新信息模型
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final int fileSize;
  final String sha256;
  final String releaseName;
  final DateTime releaseDate;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.sha256,
    required this.releaseName,
    required this.releaseDate,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'],
      downloadUrl: json['downloadUrl'],
      releaseNotes: json['releaseNotes'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      sha256: json['sha256'] ?? '',
      releaseName: json['releaseName'] ?? '',
      releaseDate: json['releaseDate'] != null ? DateTime.parse(json['releaseDate']) : DateTime.now(),
    );
  }
}

class UpdateService extends ChangeNotifier {
  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _updateInfo;
  double _downloadProgress = 0.0;
  String _errorMessage = '';
  Timer? _checkTimer;
  final Duration _checkInterval = const Duration(hours: 6); // 每6小时检查一次更新

  // GitHub 仓库信息
  final String _owner = 'your-github-username';
  final String _repo = 'gitok';
  final String _apiBaseUrl = 'https://api.github.com/repos';

  // 获取器
  UpdateStatus get status => _status;
  UpdateInfo? get updateInfo => _updateInfo;
  double get downloadProgress => _downloadProgress;
  String get errorMessage => _errorMessage;

  UpdateService() {
    // 应用启动时检查一次更新
    checkForUpdates();

    // 设置定时检查
    _checkTimer = Timer.periodic(_checkInterval, (_) => checkForUpdates());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  /// 检查更新
  Future<void> checkForUpdates() async {
    if (_status == UpdateStatus.checking || _status == UpdateStatus.downloading) {
      return; // 避免重复检查
    }

    try {
      _status = UpdateStatus.checking;
      notifyListeners();

      // 获取当前应用版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 获取最新版本信息
      final latestRelease = await _fetchLatestRelease();

      if (latestRelease == null) {
        _status = UpdateStatus.error;
        _errorMessage = '无法获取最新版本信息';
        notifyListeners();
        return;
      }

      // 解析版本号（去掉前缀 'v' 或 'p'）
      String latestVersion = latestRelease['tag_name'];
      if (latestVersion.startsWith('v') || latestVersion.startsWith('p')) {
        latestVersion = latestVersion.substring(1);
      }

      // 比较版本号
      if (_isNewerVersion(latestVersion, currentVersion)) {
        // 找到适合当前平台的资源
        final assets = latestRelease['assets'] as List;
        String? downloadUrl;
        int fileSize = 0;

        for (var asset in assets) {
          final name = asset['name'] as String;
          if (Platform.isMacOS && name.endsWith('.dmg')) {
            downloadUrl = asset['browser_download_url'];
            fileSize = asset['size'];
            break;
          } else if (Platform.isWindows && name.endsWith('.zip')) {
            downloadUrl = asset['browser_download_url'];
            fileSize = asset['size'];
            break;
          }
        }

        if (downloadUrl != null) {
          _updateInfo = UpdateInfo(
            version: latestVersion,
            downloadUrl: downloadUrl,
            releaseNotes: latestRelease['body'] ?? '',
            fileSize: fileSize,
            sha256: '', // GitHub API 不提供 SHA256
            releaseName: latestRelease['name'] ?? '',
            releaseDate: DateTime.parse(latestRelease['published_at']),
          );
          _status = UpdateStatus.available;
        } else {
          _status = UpdateStatus.notAvailable;
          _errorMessage = '没有找到适合当前平台的更新包';
        }
      } else {
        _status = UpdateStatus.notAvailable;
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = '检查更新失败: $e';
    } finally {
      notifyListeners();
    }
  }

  /// 下载更新
  Future<void> downloadUpdate() async {
    if (_updateInfo == null || _status == UpdateStatus.downloading) {
      return;
    }

    try {
      _status = UpdateStatus.downloading;
      _downloadProgress = 0.0;
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(_updateInfo!.downloadUrl);
      final savePath = path.join(tempDir.path, fileName);

      // 创建 HTTP 客户端
      final httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(_updateInfo!.downloadUrl));
      final response = await httpClient.send(request);

      // 获取文件总大小
      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      // 创建文件
      final file = File(savePath);
      final sink = file.openWrite();

      // 下载文件并更新进度
      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        _downloadProgress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
        notifyListeners();
      });

      // 关闭文件
      await sink.close();

      _status = UpdateStatus.downloaded;
      notifyListeners();

      // 返回下载的文件路径
      return savePath;
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = '下载更新失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 安装更新
  Future<void> installUpdate() async {
    if (_status != UpdateStatus.downloaded) {
      return;
    }

    try {
      _status = UpdateStatus.installing;
      notifyListeners();

      // 获取下载的文件
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(_updateInfo!.downloadUrl);
      final filePath = path.join(tempDir.path, fileName);

      if (Platform.isMacOS) {
        // 在 macOS 上，我们打开 DMG 文件
        Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        // 在 Windows 上，我们解压 ZIP 文件并运行安装程序
        final extractDir = await getTemporaryDirectory();
        final extractPath = path.join(extractDir.path, 'gitok_update');

        // 创建解压目录
        final directory = Directory(extractPath);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
        await directory.create(recursive: true);

        // 解压文件
        final bytes = await File(filePath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            File(path.join(extractPath, filename))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            Directory(path.join(extractPath, filename))..createSync(recursive: true);
          }
        }

        // 运行安装程序
        final installerPath = path.join(extractPath, 'GitOk-Setup.exe');
        if (await File(installerPath).exists()) {
          await Process.run(installerPath, []);
          await windowManager.close();
        } else {
          throw Exception('找不到安装程序');
        }
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = '安装更新失败: $e';
      notifyListeners();
    }
  }

  /// 重启应用以完成更新
  Future<void> restartApp() async {
    await windowManager.close();
  }

  /// 获取最新发布版本信息
  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final url = '$_apiBaseUrl/$_owner/$_repo/releases/latest';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('获取最新版本失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取最新版本出错: $e');
      return null;
    }
  }

  /// 比较版本号，检查是否有新版本
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = latestVersion.split('.').map((part) => int.parse(part)).toList();
      final current = currentVersion.split('.').map((part) => int.parse(part)).toList();

      // 确保两个列表长度相同
      while (latest.length < current.length) latest.add(0);
      while (current.length < latest.length) current.add(0);

      // 比较版本号
      for (var i = 0; i < latest.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }

      return false; // 版本相同
    } catch (e) {
      print('版本比较出错: $e');
      return false;
    }
  }
}
