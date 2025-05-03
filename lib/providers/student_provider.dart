import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/repositories/student_repository.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final studentListProvider = FutureProvider<List<Student>>((ref) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  final appUser = await ref.watch(userProvider.future);

  if (appUser == null) return [];

  if (appUser.isParent() && appUser.linkedStudents != null) {
    return await studentRepository.getStudentsByIds(appUser.linkedStudents!);
  } else if (appUser.isOperator() && appUser.school != null) {
    return await studentRepository.getStudentsBySchool(appUser.school!);
  } else if (appUser.isAdmin()) {
    return await studentRepository.getAllStudents();
  }

  return [];
});

final studentByQrProvider = FutureProvider.family<Student?, String>((ref, qrCodeId) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return await studentRepository.getStudentByQrCode(qrCodeId);
});

final studentByIdProvider = FutureProvider.family<Student?, String>((ref, studentId) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return await studentRepository.getStudentById(studentId);
});

class StudentNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repository;

  StudentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    try {
      final students = await _repository.getAllStudents();
      state = AsyncValue.data(students);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final studentNotifierProvider = StateNotifierProvider<StudentNotifier, AsyncValue<List<Student>>>(
      (ref) => StudentNotifier(ref.watch(studentRepositoryProvider)),
);