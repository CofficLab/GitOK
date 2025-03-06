import 'package:flutter/material.dart';
import 'package:gitok/core/models/git_project.dart';
import 'package:gitok/core/models/app_icon_config.dart';
import 'package:gitok/core/services/icon_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gitok/core/widgets/icon/icon_preview.dart';
import 'package:gitok/core/widgets/preset_icons_picker.dart';

class IconPage extends StatefulWidget {
  final GitProject project;

  const IconPage({
    super.key,
    required this.project,
  });

  @override
  State<IconPage> createState() => _IconPageState();
}

class _IconPageState extends State<IconPage> {
  final IconService _iconService = IconService();
  List<AppIconConfig> _configs = [];
  AppIconConfig? _selectedConfig;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cornerRadiusController = TextEditingController();
  final _borderWidthController = TextEditingController();
  final _paddingController = TextEditingController();

  String? _imagePath;
  Color _backgroundColor = Colors.white;
  bool _hasBorder = false;
  Color _borderColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await _iconService.loadIconConfigs(widget.project.path);
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
                title: const Text('图标配置'),
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
                          _loadConfigToForm(config);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '配置名称',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return '请输入配置名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 图片选择
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('选择图片'),
                        onPressed: _pickImage,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.style),
                        label: const Text('预设图标'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Text('选择预设图标'),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: PresetIconsPicker(
                                        onIconSelected: (path) {
                                          setState(() {
                                            _imagePath = path;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_imagePath != null) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text(_imagePath!, overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 样式设置
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cornerRadiusController,
                          decoration: const InputDecoration(
                            labelText: '圆角半径',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _paddingController,
                          decoration: const InputDecoration(
                            labelText: '内边距',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 背景色
                  Row(
                    children: [
                      const Text('背景色：'),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _pickBackgroundColor,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            border: Border.all(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 边框设置
                  Row(
                    children: [
                      Checkbox(
                        value: _hasBorder,
                        onChanged: (value) {
                          setState(() {
                            _hasBorder = value ?? false;
                          });
                        },
                      ),
                      const Text('显示边框'),
                      if (_hasBorder) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _borderWidthController,
                            decoration: const InputDecoration(
                              labelText: '边框宽度',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _pickBorderColor,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _borderColor,
                              border: Border.all(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 预览区域
                  const Text('预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_imagePath != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconPreview(
                          config: AppIconConfig(
                            name: _nameController.text,
                            imagePath: _imagePath!,
                            cornerRadius: double.tryParse(_cornerRadiusController.text) ?? 0,
                            backgroundColor: _backgroundColor,
                            hasBorder: _hasBorder,
                            borderColor: _borderColor,
                            borderWidth: double.tryParse(_borderWidthController.text) ?? 1,
                            padding: double.tryParse(_paddingController.text) ?? 0,
                            lastModified: DateTime.now(),
                          ),
                          size: 128,
                          platform: 'macOS',
                        ),
                        IconPreview(
                          config: AppIconConfig(
                            name: _nameController.text,
                            imagePath: _imagePath!,
                            cornerRadius: double.tryParse(_cornerRadiusController.text) ?? 0,
                            backgroundColor: _backgroundColor,
                            hasBorder: _hasBorder,
                            borderColor: _borderColor,
                            borderWidth: double.tryParse(_borderWidthController.text) ?? 1,
                            padding: double.tryParse(_paddingController.text) ?? 0,
                            lastModified: DateTime.now(),
                          ),
                          size: 60,
                          platform: 'iOS',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('保存配置'),
                        onPressed: _saveConfig,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.build),
                        label: const Text('生成图标'),
                        onPressed: _generateIcons,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _imagePath = result.files.single.path;
      });
    }
  }

  void _pickBackgroundColor() async {
    final color = await showColorPicker(
      context: context,
      initialColor: _backgroundColor,
    );
    if (color != null) {
      setState(() {
        _backgroundColor = color;
      });
    }
  }

  void _pickBorderColor() async {
    final color = await showColorPicker(
      context: context,
      initialColor: _borderColor,
    );
    if (color != null) {
      setState(() {
        _borderColor = color;
      });
    }
  }

  void _createNewConfig() {
    setState(() {
      _selectedConfig = null;
      _nameController.clear();
      _cornerRadiusController.clear();
      _borderWidthController.clear();
      _paddingController.clear();
      _imagePath = null;
      _backgroundColor = Colors.white;
      _hasBorder = false;
      _borderColor = Colors.black;
    });
  }

  void _loadConfigToForm(AppIconConfig config) {
    _nameController.text = config.name;
    _cornerRadiusController.text = config.cornerRadius.toString();
    _borderWidthController.text = config.borderWidth.toString();
    _paddingController.text = config.padding.toString();
    _imagePath = config.imagePath;
    _backgroundColor = config.backgroundColor;
    _hasBorder = config.hasBorder;
    _borderColor = config.borderColor;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择图片')),
      );
      return;
    }

    final config = AppIconConfig(
      name: _nameController.text,
      imagePath: _imagePath!,
      cornerRadius: double.tryParse(_cornerRadiusController.text) ?? 0,
      backgroundColor: _backgroundColor,
      hasBorder: _hasBorder,
      borderColor: _borderColor,
      borderWidth: double.tryParse(_borderWidthController.text) ?? 1,
      padding: double.tryParse(_paddingController.text) ?? 0,
      lastModified: DateTime.now(),
    );

    await _iconService.saveIconConfig(widget.project.path, config);
    await _loadConfigs();
  }

  Future<void> _generateIcons() async {
    if (_selectedConfig == null) return;

    try {
      await _iconService.generateIcons(widget.project.path, _selectedConfig!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图标生成成功')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图标生成失败: $e')),
      );
    }
  }
}

Future<Color?> showColorPicker({
  required BuildContext context,
  required Color initialColor,
}) async {
  return showDialog<Color>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('选择颜色'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: initialColor,
          onColorChanged: (color) => initialColor = color,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, initialColor),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
