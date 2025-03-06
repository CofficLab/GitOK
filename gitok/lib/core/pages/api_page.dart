import 'package:flutter/material.dart';
import 'package:gitok/core/models/git_project.dart';
import 'package:gitok/core/models/api_config.dart';
import 'package:gitok/plugins/api/api_service.dart';
import 'package:gitok/core/widgets/json_viewer.dart';
import 'dart:convert';

class ApiPage extends StatefulWidget {
  final GitProject project;

  const ApiPage({
    super.key,
    required this.project,
  });

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  final ApiService _apiService = ApiService();
  List<ApiConfig> _configs = [];
  ApiConfig? _selectedConfig;
  ApiEndpoint? _selectedEndpoint;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<ApiResponse> _responses = [];
  String _selectedMethod = 'GET';
  final Map<String, String> _headers = {};
  final _headerKeyController = TextEditingController();
  final _headerValueController = TextEditingController();
  final Map<String, String> _queryParams = {};
  final _queryKeyController = TextEditingController();
  final _queryValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await _apiService.loadApiConfigs(widget.project.path);
    setState(() {
      _configs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧配置列表
        SizedBox(
          width: 250,
          child: Column(
            children: [
              ListTile(
                title: const Text('API配置'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createNewConfig,
                ),
              ),
              Expanded(
                child: _configs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.api, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('还没有API配置'),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('创建配置'),
                              onPressed: _createNewConfig,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _configs.length,
                        itemBuilder: (context, index) {
                          final config = _configs[index];
                          return ExpansionTile(
                            title: Text(config.name),
                            subtitle: Text(
                              config.lastModified.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            children: [
                              ...config.endpoints.map((endpoint) {
                                return ListTile(
                                  leading: Text(
                                    endpoint.method,
                                    style: TextStyle(
                                      color: _getMethodColor(endpoint.method),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  title: Text(endpoint.name),
                                  subtitle: Text(endpoint.url),
                                  selected: _selectedEndpoint == endpoint,
                                  onTap: () {
                                    setState(() {
                                      _selectedConfig = config;
                                      _selectedEndpoint = endpoint;
                                      _loadEndpointToEditor(endpoint);
                                    });
                                  },
                                );
                              }),
                              ListTile(
                                leading: const Icon(Icons.add),
                                title: const Text('添加接口'),
                                onTap: () {
                                  setState(() {
                                    _selectedConfig = config;
                                    _selectedEndpoint = null;
                                    _clearEditor();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // 右侧编辑区域
        Expanded(
          child: _selectedConfig == null && _configs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('创建一个API配置开始测试'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('创建配置'),
                        onPressed: _createNewConfig,
                      ),
                    ],
                  ),
                )
              : _selectedConfig == null
                  ? const Center(
                      child: Text('选择一个API配置或接口开始测试'),
                    )
                  : Column(
                      children: [
                        // 请求编辑器
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    DropdownButton<String>(
                                      value: _selectedMethod,
                                      items: ['GET', 'POST', 'PUT', 'DELETE'].map((method) {
                                        return DropdownMenuItem(
                                          value: method,
                                          child: Text(
                                            method,
                                            style: TextStyle(
                                              color: _getMethodColor(method),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedMethod = value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _urlController,
                                        decoration: const InputDecoration(
                                          labelText: 'URL',
                                          hintText: 'https://api.example.com/endpoint',
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return '请输入URL';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: '接口名称',
                                    hintText: '给这个接口起个名字',
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return '请输入接口名称';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _bodyController,
                                  decoration: const InputDecoration(
                                    labelText: '请求体',
                                    hintText: '输入JSON格式的请求体',
                                  ),
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 16),
                                ExpansionTile(
                                  title: const Text('请求头'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          // 显示已添加的请求头
                                          ...(_headers.entries.map((entry) => ListTile(
                                                title: Text('${entry.key}: ${entry.value}'),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  onPressed: () {
                                                    setState(() {
                                                      _headers.remove(entry.key);
                                                    });
                                                  },
                                                ),
                                              ))),
                                          // 添加新请求头
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _headerKeyController,
                                                  decoration: const InputDecoration(
                                                    labelText: '请求头名称',
                                                    hintText: 'Content-Type',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: _headerValueController,
                                                  decoration: const InputDecoration(
                                                    labelText: '请求头值',
                                                    hintText: 'application/json',
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  if (_headerKeyController.text.isNotEmpty) {
                                                    setState(() {
                                                      _headers[_headerKeyController.text] = _headerValueController.text;
                                                      _headerKeyController.clear();
                                                      _headerValueController.clear();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ExpansionTile(
                                  title: const Text('查询参数'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          // 显示已添加的查询参数
                                          ...(_queryParams.entries.map((entry) => ListTile(
                                                title: Text('${entry.key}=${entry.value}'),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete),
                                                  onPressed: () {
                                                    setState(() {
                                                      _queryParams.remove(entry.key);
                                                    });
                                                  },
                                                ),
                                              ))),
                                          // 添加新查询参数
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _queryKeyController,
                                                  decoration: const InputDecoration(
                                                    labelText: '参数名称',
                                                    hintText: 'page',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: _queryValueController,
                                                  decoration: const InputDecoration(
                                                    labelText: '参数值',
                                                    hintText: '1',
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  if (_queryKeyController.text.isNotEmpty) {
                                                    setState(() {
                                                      _queryParams[_queryKeyController.text] =
                                                          _queryValueController.text;
                                                      _queryKeyController.clear();
                                                      _queryValueController.clear();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    FilledButton.icon(
                                      icon: const Icon(Icons.save),
                                      label: const Text('保存'),
                                      onPressed: _saveEndpoint,
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.send),
                                      label: const Text('发送'),
                                      onPressed: _sendRequest,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 响应查看器
                        Expanded(
                          child: _responses.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.history, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text('还没有请求历史'),
                                      SizedBox(height: 8),
                                      Text(
                                        '点击发送按钮开始测试接口',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _responses.length,
                                  itemBuilder: (context, index) {
                                    final response = _responses[index];
                                    return Card(
                                      margin: const EdgeInsets.all(8.0),
                                      child: ExpansionTile(
                                        title: Text(
                                          '${response.statusCode} - ${response.duration.inMilliseconds}ms',
                                          style: TextStyle(
                                            color: _getStatusColor(response.statusCode),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(response.timestamp.toString()),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Headers:'),
                                                const SizedBox(height: 8),
                                                JsonViewer(response.headers),
                                                const SizedBox(height: 16),
                                                const Text('Body:'),
                                                const SizedBox(height: 8),
                                                JsonViewer(response.body),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode < 300) return Colors.green;
    if (statusCode < 400) return Colors.orange;
    return Colors.red;
  }

  void _createNewConfig() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建API配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '配置名称',
                hintText: '给这组API起个名字',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              '提示：可以为不同的环境（开发、测试、生产）创建不同的配置',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final config = ApiConfig(
      name: name,
      endpoints: [],
      lastModified: DateTime.now(),
    );

    await _apiService.saveApiConfig(widget.project.path, config);
    await _loadConfigs();
  }

  void _clearEditor() {
    _nameController.clear();
    _urlController.clear();
    _bodyController.clear();
    _selectedMethod = 'GET';
  }

  void _loadEndpointToEditor(ApiEndpoint endpoint) {
    _nameController.text = endpoint.name;
    _urlController.text = endpoint.url;
    _bodyController.text = endpoint.body != null ? jsonEncode(endpoint.body) : '';
    _selectedMethod = endpoint.method;
    setState(() {
      _headers.clear();
      _headers.addAll(endpoint.headers);
      _queryParams.clear();
      _queryParams.addAll(endpoint.queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ));
    });
  }

  Future<void> _saveEndpoint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedConfig == null) return;

    final endpoint = ApiEndpoint(
      name: _nameController.text,
      method: _selectedMethod,
      url: _urlController.text,
      headers: Map<String, String>.from(_headers),
      queryParams: Map<String, dynamic>.from(_queryParams),
      body: _bodyController.text.isNotEmpty ? jsonDecode(_bodyController.text) : null,
    );

    final updatedEndpoints = [..._selectedConfig!.endpoints];
    if (_selectedEndpoint != null) {
      final index = updatedEndpoints.indexOf(_selectedEndpoint!);
      updatedEndpoints[index] = endpoint;
    } else {
      updatedEndpoints.add(endpoint);
    }

    final updatedConfig = ApiConfig(
      name: _selectedConfig!.name,
      endpoints: updatedEndpoints,
      lastModified: DateTime.now(),
    );

    await _apiService.saveApiConfig(widget.project.path, updatedConfig);
    await _loadConfigs();
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final endpoint = ApiEndpoint(
      name: _nameController.text,
      method: _selectedMethod,
      url: _urlController.text,
      headers: Map<String, String>.from(_headers),
      queryParams: Map<String, dynamic>.from(_queryParams),
      body: _bodyController.text.isNotEmpty ? jsonDecode(_bodyController.text) : null,
    );

    try {
      final response = await _apiService.sendRequest(endpoint);
      setState(() {
        _responses.insert(0, response);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请求失败: $e')),
      );
    }
  }
}
