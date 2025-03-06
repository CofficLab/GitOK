import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class PresetIconsPicker extends StatelessWidget {
  final Function(String) onIconSelected;

  const PresetIconsPicker({
    super.key,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _loadPresetIcons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载预设图标失败: ${snapshot.error}'));
        }

        final icons = snapshot.data!;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: icons.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => onIconSelected(icons[index]),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(icons[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<String>> _loadPresetIcons() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    return manifestMap.keys.where((String key) => key.startsWith('assets/icons/basic/')).toList();
  }
}
