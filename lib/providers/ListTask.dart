// ignore_for_file: avoid_print
import '../models/task_model.dart';

class ListTask {
  // Biến danh sách các nhiệm vụ
  final List<TaskModel> _taskList = [];

  /// [READ] - Đọc tất cả các nhiệm vụ
  List<TaskModel> getAllTasks() {
    return _taskList;
  }

  /// [CREATE] - Phụ huynh tạo nhiệm vụ mới cho con
  void createTask(TaskModel newTask) {
    _taskList.add(newTask);
    print('Đã giao nhiệm vụ mới: ${newTask.title}');
  }

  /// [READ - EXTENSION] - Lọc danh sách các nhiệm vụ đang chờ phê duyệt
  List<TaskModel> getPendingTasks() {
    return _taskList.where((t) => t.status == 'pending_approval').toList();
  }
}