/// Git提交信息模型
///
/// 用于存储Git提交的相关信息，包括：
/// - 提交哈希值
/// - 作者信息
/// - 提交时间
/// - 提交信息
class CommitInfo {
  final String hash;
  final String author;
  final DateTime date;
  final String message;

  CommitInfo({
    required this.hash,
    required this.author,
    required this.date,
    required this.message,
  });
}
