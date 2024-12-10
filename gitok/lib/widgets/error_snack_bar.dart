import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required String message,
  }) : super(
          content: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: message));
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(message),
                ),
                const Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 10),
        );
}
