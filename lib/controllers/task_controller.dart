import 'package:get/get.dart';
import 'package:task_paven/db/db_helper.dart';
import 'package:task_paven/models/task.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = <Task>[].obs;

  Future<int> addTask({Task? task}) async {
    final id = await DBHelper.insert(task);
    await getTasks();
    return id;
  }

  Future<void> getTasks() async {
    final List<Map<String, dynamic>> tasks = await DBHelper.query();
    taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
  }

  Future<void> deleteTasks(Task task) async {
    await DBHelper.delete(task);
    await getTasks();
  }

  Future<void> deleteAllTasks() async {
    await DBHelper.deleteAll();
    await getTasks();
  }

  Future<void> markTaskAsCompleted(int id) async {
    await DBHelper.update(id);
    await getTasks();
  }
}
