import 'package:flutter/material.dart';
import 'package:gitok/core/models/promo_config.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ElementPropertiesPanel extends StatelessWidget {
  final PromoElement element;
  final Function(PromoElement) onElementUpdated;

  const ElementPropertiesPanel({
    super.key,
    required this.element,
    required this.onElementUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${element.type} 属性', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildProperties(context),
        ],
      ),
    );
  }

  Widget _buildProperties(BuildContext context) {
    switch (element.type) {
      case 'text':
        return _buildTextProperties(context);
      case 'image':
        return _buildImageProperties(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextProperties(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: '文本内容'),
          controller: TextEditingController(text: element.properties['text'] as String),
          onChanged: (value) {
            final updatedElement = PromoElement(
              type: element.type,
              x: element.x,
              y: element.y,
              width: element.width,
              height: element.height,
              rotation: element.rotation,
              properties: {
                ...element.properties,
                'text': value,
              },
            );
            onElementUpdated(updatedElement);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('字体大小'),
            Expanded(
              child: Slider(
                value: element.properties['fontSize'] as double,
                min: 10,
                max: 100,
                onChanged: (value) {
                  final updatedElement = PromoElement(
                    type: element.type,
                    x: element.x,
                    y: element.y,
                    width: element.width,
                    height: element.height,
                    rotation: element.rotation,
                    properties: {
                      ...element.properties,
                      'fontSize': value,
                    },
                  );
                  onElementUpdated(updatedElement);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('颜色'),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('选择颜色'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: Color(element.properties['color'] as int),
                        onColorChanged: (color) {
                          final updatedElement = PromoElement(
                            type: element.type,
                            x: element.x,
                            y: element.y,
                            width: element.width,
                            height: element.height,
                            rotation: element.rotation,
                            properties: {
                              ...element.properties,
                              'color': color.value,
                            },
                          );
                          onElementUpdated(updatedElement);
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(element.properties['color'] as int),
                  border: Border.all(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageProperties(BuildContext context) {
    return Column(
      children: [
        Text('图片路径: ${element.properties['imagePath']}'),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('旋转'),
            Expanded(
              child: Slider(
                value: element.rotation,
                min: 0,
                max: 6.28,
                onChanged: (value) {
                  final updatedElement = PromoElement(
                    type: element.type,
                    x: element.x,
                    y: element.y,
                    width: element.width,
                    height: element.height,
                    rotation: value,
                    properties: element.properties,
                  );
                  onElementUpdated(updatedElement);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
