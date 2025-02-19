import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:gitok/models/api_config.dart';
import 'package:gitok/utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Logger _logger = Logger();

  Future<void> saveApiConfig(String projectPath, ApiConfig config) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'apis'));
    await configDir.create(recursive: true);

    final file = File(path.join(configDir.path, '${config.name}.json'));
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<List<ApiConfig>> loadApiConfigs(String projectPath) async {
    final configDir = Directory(path.join(projectPath, '.gitok', 'apis'));
    if (!await configDir.exists()) {
      return [];
    }

    final configs = <ApiConfig>[];
    await for (final file in configDir.list()) {
      if (file.path.endsWith('.json')) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          configs.add(ApiConfig.fromJson(json));
        } catch (e) {
          print('Error loading API config: $e');
        }
      }
    }
    return configs;
  }

  Future<ApiResponse> sendRequest(ApiEndpoint endpoint) async {
    _logger.info('发送请求: ${endpoint.url}');
    var urlStr = endpoint.url.trim();

    // 确保URL以http或https开头
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }

    // 验证URL格式
    try {
      var uri = Uri.parse(urlStr);
      if (uri.host.isEmpty) {
        throw FormatException('URL必须包含有效的主机名');
      }

      // 添加查询参数
      if (endpoint.queryParams.isNotEmpty) {
        uri = uri.replace(
          queryParameters: {
            ...uri.queryParameters,
            ...endpoint.queryParams.map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          },
        );
      }

      final stopwatch = Stopwatch()..start();

      // 创建请求
      final request = http.Request(endpoint.method, uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          ...endpoint.headers,
        });

      // 添加请求体
      if (endpoint.body != null) {
        request.body = jsonEncode(endpoint.body);
      }

      try {
        final streamedResponse = await request.send();
        final body = await streamedResponse.stream.bytesToString();
        final httpResponse = http.Response(body, streamedResponse.statusCode);
        stopwatch.stop();

        _logger.info('请求成功: ${httpResponse.statusCode}');
        return ApiResponse(
          timestamp: DateTime.now(),
          statusCode: httpResponse.statusCode,
          headers: httpResponse.headers,
          body: _parseResponseBody(httpResponse),
          duration: stopwatch.elapsed,
        );
      } catch (e) {
        _logger.error('请求失败', e);
        throw Exception('请求失败: ${e.toString()}');
      }
    } catch (e) {
      throw Exception('无效的URL: ${e.toString()}');
    }
  }

  dynamic _parseResponseBody(http.Response response) {
    final contentType = response.headers['content-type'];
    if (contentType?.contains('application/json') ?? false) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }
    return response.body;
  }
}
