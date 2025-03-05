import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitok/widgets/recorder.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:preference_list/preference_list.dart';
import 'package:window_manager/window_manager.dart';

class ExampleIntent extends Intent {}

class ExampleAction extends Action<ExampleIntent> {
  @override
  void invoke(covariant ExampleIntent intent) {
    BotToast.showText(text: 'ExampleAction invoked');
  }
}

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> with WindowListener {
  List<HotKey> _registeredHotKeyList = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setupGlobalHotkey();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _setupGlobalHotkey() async {
    final hotKey = HotKey(
      key: LogicalKeyboardKey.space,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) async {
          await _bringToFront();
        },
      );

      setState(() {
        _registeredHotKeyList = hotKeyManager.registeredHotKeyList;
      });

      BotToast.showText(text: '已注册全局热键 Alt+Space 用于将应用带到前台');
    } catch (e) {
      BotToast.showText(text: '注册全局热键失败: $e');
    }
  }

  Future<void> _bringToFront() async {
    try {
      await windowManager.show();
      await windowManager.focus();

      BotToast.showText(text: '应用已成功回到前台');
    } catch (e) {
      if (kDebugMode) {
        print('将窗口带到前台失败: $e');
      }
    }
  }

  void _keyDownHandler(HotKey hotKey) {
    String log = 'keyDown ${hotKey.debugName} (${hotKey.scope})';
    BotToast.showText(text: log);
    if (kDebugMode) {
      print(log);
    }
  }

  void _keyUpHandler(HotKey hotKey) {
    String log = 'keyUp   ${hotKey.debugName} (${hotKey.scope})';
    BotToast.showText(text: log);
    if (kDebugMode) {
      print(log);
    }
  }

  Future<void> _handleHotKeyRegister(HotKey hotKey) async {
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: _keyDownHandler,
      keyUpHandler: _keyUpHandler,
    );
    setState(() {
      _registeredHotKeyList = hotKeyManager.registeredHotKeyList;
    });
  }

  Future<void> _handleHotKeyUnregister(HotKey hotKey) async {
    await hotKeyManager.unregister(hotKey);
    setState(() {
      _registeredHotKeyList = hotKeyManager.registeredHotKeyList;
    });
  }

  Future<void> _handleClickRegisterNewHotKey() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RecordHotKeyDialog(
          onHotKeyRecorded: (newHotKey) => _handleHotKeyRegister(newHotKey),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          title: const Text('REGISTERED HOTKEY LIST'),
          children: [
            for (var registeredHotKey in _registeredHotKeyList)
              PreferenceListItem(
                padding: const EdgeInsets.all(12),
                title: Row(
                  children: [
                    HotKeyVirtualView(hotKey: registeredHotKey),
                    const SizedBox(width: 10),
                    Text(
                      registeredHotKey.scope.toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                accessoryView: SizedBox(
                  width: 40,
                  height: 40,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    onPressed: () => _handleHotKeyUnregister(registeredHotKey),
                  ),
                ),
              ),
            PreferenceListItem(
              title: Text(
                'Register a new HotKey',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              accessoryView: Container(),
              onTap: () {
                _handleClickRegisterNewHotKey();
              },
            ),
          ],
        ),
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: Text(
                'Unregister all HotKeys',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              accessoryView: Container(),
              onTap: () async {
                await hotKeyManager.unregisterAll();
                _registeredHotKeyList = hotKeyManager.registeredHotKeyList;
                setState(() {});
              },
            ),
          ],
        ),
        PreferenceListSection(
          title: const Text('窗口控制'),
          children: [
            PreferenceListItem(
              title: Text(
                '将应用带到前台',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              accessoryView: Container(),
              onTap: _bringToFront,
            ),
            PreferenceListItem(
              title: const Text(
                '全局热键: Alt+Space',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              accessoryView: Container(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ExampleIntent: ExampleAction(),
      },
      child: GlobalShortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.keyA, alt: true): ExampleIntent(),
        },
        child: _build(context),
      ),
    );
  }
}
