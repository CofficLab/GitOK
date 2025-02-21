import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Git差异查看器组件
class DiffViewer extends StatelessWidget {
  final String diffText;

  const DiffViewer({
    super.key,
    required this.diffText,
  });

  @override
  Widget build(BuildContext context) {
    final diffs = _parseDiff(diffText);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(
                  constraints.maxWidth,
                  800.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in diffs)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _getBackgroundColor(context, section.type),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                section.lineNumber,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                              child: Text(
                                _getLinePrefix(section.type),
                                style: TextStyle(
                                  color: _getPrefixColor(context, section.type),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                section.content,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DiffSection> _parseDiff(String diffText) {
    final List<DiffSection> sections = [];
    int oldLineNumber = 0;
    int newLineNumber = 0;

    // 跳过头部的 diff 信息
    final lines = diffText.split('\n');
    var startIndex = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('@@')) {
        startIndex = i + 1;
        // 解析行号信息
        final match = RegExp(r'@@ -(\d+),?\d* \+(\d+),?\d* @@').firstMatch(lines[i]);
        if (match != null) {
          oldLineNumber = int.parse(match.group(1)!);
          newLineNumber = int.parse(match.group(2)!);
        }
        break;
      }
    }

    // 处理每一行
    for (var i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;

      if (line.startsWith('+')) {
        sections.add(DiffSection(
          type: DiffType.addition,
          content: line.substring(1),
          lineNumber: '${newLineNumber++}',
        ));
      } else if (line.startsWith('-')) {
        sections.add(DiffSection(
          type: DiffType.deletion,
          content: line.substring(1),
          lineNumber: '${oldLineNumber++}',
        ));
      } else if (!line.startsWith('\\')) {
        // 忽略 "\ No newline at end of file"
        sections.add(DiffSection(
          type: DiffType.context,
          content: line.substring(1),
          lineNumber: '${newLineNumber++}',
        ));
        oldLineNumber++;
      }
    }

    return sections;
  }

  Color _getBackgroundColor(BuildContext context, DiffType type) {
    switch (type) {
      case DiffType.addition:
        return Colors.green.withOpacity(0.1);
      case DiffType.deletion:
        return Colors.red.withOpacity(0.1);
      case DiffType.context:
        return Colors.transparent;
    }
  }

  Color _getPrefixColor(BuildContext context, DiffType type) {
    switch (type) {
      case DiffType.addition:
        return Colors.green;
      case DiffType.deletion:
        return Colors.red;
      case DiffType.context:
        return Colors.grey;
    }
  }

  String _getLinePrefix(DiffType type) {
    switch (type) {
      case DiffType.addition:
        return '+';
      case DiffType.deletion:
        return '-';
      case DiffType.context:
        return ' ';
    }
  }
}

enum DiffType {
  addition,
  deletion,
  context,
}

class DiffSection {
  final DiffType type;
  final String content;
  final String lineNumber;

  DiffSection({
    required this.type,
    required this.content,
    required this.lineNumber,
  });
}
