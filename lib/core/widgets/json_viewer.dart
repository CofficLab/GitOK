import 'package:flutter/material.dart';
import 'dart:convert';

class JsonViewer extends StatelessWidget {
  final dynamic json;
  final bool isRoot;

  const JsonViewer(this.json, {super.key, this.isRoot = true});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        _formatJson(json),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatJson(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
