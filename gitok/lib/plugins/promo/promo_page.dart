import 'package:flutter/material.dart';
import 'package:gitok/plugins/git/git_project.dart';
import 'package:gitok/plugins/promo/promo_config.dart';
import 'package:gitok/plugins/promo/promo_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gitok/core/widgets/promo/promo_canvas.dart';
import 'package:gitok/core/widgets/element_properties_panel.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class PromoPage extends StatefulWidget {
  final GitProject project;

  const PromoPage({
    super.key,
    required this.project,
  });

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final PromoService _promoService = PromoService();
  List<PromoConfig> _configs = [];
  PromoConfig? _selectedConfig;
  final _nameController = TextEditingController();
  String? _backgroundImage;
  final List<PromoElement> _elements = [];
  int? _selectedElementIndex;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await _promoService.loadPromoConfigs(widget.project.path);
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
          width: 200,
          child: Column(
            children: [
              ListTile(
                title: const Text('宣传图配置'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createNewConfig,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _configs.length,
                  itemBuilder: (context, index) {
                    final config = _configs[index];
                    return ListTile(
                      title: Text(config.name),
                      subtitle: Text(
                        config.lastModified.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      selected: _selectedConfig?.name == config.name,
                      onTap: () {
                        setState(() {
                          _selectedConfig = config;
                          _loadConfigToEditor(config);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 右侧编辑区域
        Expanded(
          child: Column(
            children: [
              // 工具栏
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('背景图片'),
                      onPressed: _pickBackgroundImage,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.text_fields),
                      label: const Text('添加文本'),
                      onPressed: _addTextElement,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('添加图片'),
                      onPressed: _addImageElement,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                      onPressed: _saveConfig,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text('导出'),
                      onPressed: _exportPromo,
                    ),
                  ],
                ),
              ),

              // 编辑区域
              Expanded(
                child: _buildEditor(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Row(
      children: [
        // 编辑画布
        Expanded(
          child: PromoCanvas(
            backgroundImage: _backgroundImage,
            elements: _elements,
            selectedIndex: _selectedElementIndex,
            onElementUpdated: (element, index) {
              setState(() {
                _elements[index] = element;
              });
            },
            onElementSelected: (index) {
              setState(() {
                _selectedElementIndex = index;
              });
            },
          ),
        ),

        // 属性面板
        if (_selectedElementIndex != null && _selectedElementIndex! < _elements.length)
          ElementPropertiesPanel(
            element: _elements[_selectedElementIndex!],
            onElementUpdated: (element) {
              setState(() {
                _elements[_selectedElementIndex!] = element;
              });
            },
          ),
      ],
    );
  }

  void _createNewConfig() {
    setState(() {
      _selectedConfig = null;
      _nameController.clear();
      _backgroundImage = null;
      _elements.clear();
    });
  }

  void _loadConfigToEditor(PromoConfig config) {
    setState(() {
      _nameController.text = config.name;
      _backgroundImage = config.backgroundImage;
      _elements
        ..clear()
        ..addAll(config.elements);
    });
  }

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _backgroundImage = result.files.single.path;
      });
    }
  }

  void _addTextElement() {
    setState(() {
      _elements.add(
        PromoElement(
          type: 'text',
          x: 0,
          y: 0,
          width: 200,
          height: 50,
          properties: {
            'text': '新文本',
            'fontSize': 20.0,
            'color': Colors.black.value,
          },
        ),
      );
    });
  }

  void _addImageElement() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _elements.add(
          PromoElement(
            type: 'image',
            x: 0,
            y: 0,
            width: 200,
            height: 200,
            properties: {
              'imagePath': result.files.single.path,
            },
          ),
        );
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_backgroundImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择背景图片')),
      );
      return;
    }

    // 弹出对话框输入配置名称
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存配置'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '配置名称',
            hintText: '请输入配置名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                Navigator.pop(context, _nameController.text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final config = PromoConfig(
      name: name,
      backgroundImage: _backgroundImage!,
      elements: _elements,
      lastModified: DateTime.now(),
    );

    await _promoService.savePromoConfig(widget.project.path, config);
    await _loadConfigs();
  }

  Future<void> _exportPromo() async {
    if (_selectedConfig == null) return;

    // 让用户选择保存目录
    final outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择导出目录',
    );

    if (outputPath == null) return;

    try {
      // 创建当前配置的导出目录
      final configDir = Directory(path.join(outputPath, _selectedConfig!.name));
      await configDir.create(recursive: true);

      // 导出图片
      await _promoService.exportPromo(configDir.path, _selectedConfig!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出到: ${configDir.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }
}
