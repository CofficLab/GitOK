/// 服务异常基类
class ServiceException implements Exception {
  final String message;
  final String? details;

  ServiceException(this.message, {this.details});

  @override
  String toString() => 'ServiceException: $message${details != null ? '\nDetails: $details' : ''}';
}
