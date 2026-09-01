import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/project.dart';
import '../../services/firestore_service.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  final FirestoreService _firestoreService;

  ProjectNotifier(this._firestoreService) : super([]) {
    _loadProjects();
  }

  late final Box<Project> _box = Hive.box<Project>('projects');

  void _loadProjects() {
    state = _box.values.toList();
  }

  void refreshFromLocal() {
    state = _box.values.toList();
  }

  void clear() {
    state = [];
    _box.clear();
  }

  Future<void> addProject(Project project) async {
    // 1. Hive local save
    await _box.put(project.id, project);
    // 2. Riverpod state update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.saveProject(project);
  }

  Future<void> updateProject(Project project) async {
    // 1. Hive local save
    await _box.put(project.id, project);
    // 2. Riverpod state update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.saveProject(project);
  }

  Future<void> deleteProject(String id) async {
    // 1. Hive local delete
    await _box.delete(id);
    // 2. Riverpod state update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.deleteProject(id);
  }

  Future<void> updateReceivedAmount(String projectId, double additionalAmount) async {
    final index = state.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final current = state[index];
      final newReceived = (current.receivedAmount + additionalAmount).clamp(0.0, current.budget);
      final updated = current.copyWith(
        receivedAmount: newReceived,
        status: newReceived >= current.budget ? 'Completed' : current.status,
      );
      await updateProject(updated);
    }
  }

  Future<void> updateStatus(String projectId, String newStatus) async {
    final index = state.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final updated = state[index].copyWith(status: newStatus);
      await updateProject(updated);
    }
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProjectNotifier(firestoreService);
});

final projectStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final projects = ref.watch(projectProvider);

  final totalProjects = projects.length;
  final activeProjects = projects.where((p) => p.status == 'Active').length;
  final completedProjects = projects.where((p) => p.status == 'Completed').length;
  final onHoldProjects = projects.where((p) => p.status == 'On Hold').length;

  final totalBudget = projects.fold(0.0, (sum, p) => sum + p.budget);
  final totalReceived = projects.fold(0.0, (sum, p) => sum + p.receivedAmount);
  final totalPending = (totalBudget - totalReceived).clamp(0.0, double.infinity);

  return {
    'totalProjects': totalProjects,
    'activeProjects': activeProjects,
    'completedProjects': completedProjects,
    'onHoldProjects': onHoldProjects,
    'totalBudget': totalBudget,
    'totalReceived': totalReceived,
    'totalPending': totalPending,
  };
});
