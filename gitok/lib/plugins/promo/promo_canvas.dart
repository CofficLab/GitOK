import 'package:flutter/material.dart';
import 'package:gitok/plugins/promo/promo_config.dart';
import 'dart:io';

class PromoCanvas extends StatefulWidget {
  final String? backgroundImage;
  final List<PromoElement> elements;
  final Function(PromoElement, int) onElementUpdated;
  final Function(int) onElementSelected;
  final int? selectedIndex;

  const PromoCanvas({
    super.key,
    this.backgroundImage,
    required this.elements,
    required this.onElementUpdated,
    required this.onElementSelected,
    this.selectedIndex,
  });

  @override
  State<PromoCanvas> createState() => _PromoCanvasState();
}

class _PromoCanvasState extends State<PromoCanvas> {
  final _canvasKey = GlobalKey();
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _canvasSize = box.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _canvasKey,
      color: Colors.grey[200],
      child: Stack(
        children: [
          // 背景图片
          if (widget.backgroundImage != null)
            Image.file(
              File(widget.backgroundImage!),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),

          // 元素层
          ...widget.elements.asMap().entries.map((entry) {
            final index = entry.key;
            final element = entry.value;
            return Positioned(
              left: element.x,
              top: element.y,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final updatedElement = PromoElement(
                    type: element.type,
                    x: (element.x + details.delta.dx).clamp(0, _canvasSize.width - element.width),
                    y: (element.y + details.delta.dy).clamp(0, _canvasSize.height - element.height),
                    width: element.width,
                    height: element.height,
                    rotation: element.rotation,
                    properties: element.properties,
                  );
                  widget.onElementUpdated(updatedElement, index);
                },
                onTap: () => widget.onElementSelected(index),
                child: Container(
                  width: element.width,
                  height: element.height,
                  decoration: BoxDecoration(
                    border: index == widget.selectedIndex ? Border.all(color: Colors.blue, width: 2) : null,
                  ),
                  child: Transform.rotate(
                    angle: element.rotation,
                    child: _buildElement(element),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildElement(PromoElement element) {
    switch (element.type) {
      case 'text':
        return Text(
          element.properties['text'] as String,
          style: TextStyle(
            fontSize: element.properties['fontSize'] as double,
            color: Color(element.properties['color'] as int),
          ),
        );
      case 'image':
        return Image.file(
          File(element.properties['imagePath'] as String),
          fit: BoxFit.contain,
        );
      default:
        return const SizedBox();
    }
  }
}
