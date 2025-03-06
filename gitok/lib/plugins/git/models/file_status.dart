/// Git文件状态模型
///
/// 表示Git工作区中单个文件的状态信息，包括：
/// - 文件路径
/// - 状态标记（M:修改, A:新增, D:删除等）
class FileStatus {
  final String path;
  final String status;

  FileStatus(this.path, this.status);
}
