import 'service_exception.dart';

/// Git操作异常类
class GitException extends ServiceException {
  final String command;
  final int exitCode;

  GitException({
    required this.command,
    required String message,
    required this.exitCode,
  }) : super(message);

  @override
  String toString() => 'GitException[$command]: $message (exit code: $exitCode)';
}
