/// 快捷键设置组件
///
/// 用于配置应用的全局快捷键
/// 支持自定义快捷键组合
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeySetting extends StatefulWidget {
  const HotkeySetting({super.key});

  @override
  State<HotkeySetting> createState() => _HotkeySettingState();
}

class _HotkeySettingState extends State<HotkeySetting> {
  HotKey? _currentHotkey;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentHotkey();
  }

  Future<void> _loadCurrentHotkey() async {
    // 这里可以从设置中加载已保存的快捷键
    setState(() {
      _currentHotkey = HotKey(
        key: LogicalKeyboardKey.digit1,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷键设置',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 30),
        const Text(
          '设置用于将应用带到前台的全局快捷键：',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isRecording ? '请按下新的快捷键组合...' : '当前快捷键: ${_formatHotkey(_currentHotkey)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isRecording ? _cancelRecording : _startRecording,
                      child: Text(_isRecording ? '取消' : '修改快捷键'),
                    ),
                  ],
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '提示：按下想要设置的键位组合，然后点击保存',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatHotkey(HotKey? hotkey) {
    if (hotkey == null) return '未设置';

    final List<String> parts = [];

    if (hotkey.modifiers?.contains(HotKeyModifier.alt) ?? false) {
      parts.add('Alt');
    }
    if (hotkey.modifiers?.contains(HotKeyModifier.control) ?? false) {
      parts.add('Ctrl');
    }
    if (hotkey.modifiers?.contains(HotKeyModifier.meta) ?? false) {
      parts.add('⌘');
    }
    if (hotkey.modifiers?.contains(HotKeyModifier.shift) ?? false) {
      parts.add('Shift');
    }

    parts.add(hotkey.key.keyLabel);

    return parts.join(' + ');
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    // 这里添加录制快捷键的逻辑
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
    });
  }
}
