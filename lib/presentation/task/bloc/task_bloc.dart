import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/model /ui_state.dart';
import '../../../domain/task/models/assignment.dart';
import '../../../domain/task/models/daily_task.dart';
import '../../../domain/task/repositories/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

@injectable
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc(this.taskRepository) : super(const TaskState()) {
    on<TaskTodayLoadRequested>(_onLoadToday);
    on<TaskConfirmationRequested>(_onRequestConfirmation);
    on<PendingConfirmationsLoadRequested>(_onLoadPending);
    on<PeerTaskConfirmed>(_onConfirmPeer);
    on<AssignmentsLoadRequested>(_onLoadAssignments);
    on<AssignmentCreateRequested>(_onCreateAssignment);
    on<AssignmentDoneToggled>(_onToggleAssignment);
  }

  /// yyyy-MM-dd id for a date.
  static String dateIdOf(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  // --- US-08: today's task ---
  Future<void> _onLoadToday(
      TaskTodayLoadRequested event, Emitter<TaskState> emit) async {
    final dateId = dateIdOf(DateTime.now());
    emit(state.copyWith(status: UIStatus.loading, dateId: dateId));
    try {
      final task = await taskRepository.getTaskForDay(
        circleId: event.circleId,
        dateId: dateId,
        uid: event.uid,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        todayTask: task,
        clearTodayTask: task == null,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  // --- US-09: record completion + request partner confirmation ---
  Future<void> _onRequestConfirmation(
      TaskConfirmationRequested event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await taskRepository.requestConfirmation(
        circleId: event.circleId,
        dateId: event.dateId,
        task: event.task,
        partnerId: event.partnerId,
      );
      final updated = event.task.copyWith(
        status: TaskStatus.pending,
        partnerConfirmed: false,
        partnerId: event.partnerId,
      );
      emit(state.copyWith(
        status: UIStatus.success,
        message: 'تم إرسال طلب التأكيد إلى الرفيقة',
        todayTask: updated,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  // --- US-10: list of pending confirmations addressed to me ---
  Future<void> _onLoadPending(
      PendingConfirmationsLoadRequested event, Emitter<TaskState> emit) async {
    final dateId = dateIdOf(DateTime.now());
    emit(state.copyWith(status: UIStatus.loading, dateId: dateId));
    try {
      final list = await taskRepository.getPendingConfirmations(
        circleId: event.circleId,
        dateId: dateId,
        partnerUid: event.partnerUid,
      );
      emit(state.copyWith(
          status: UIStatus.success, pendingConfirmations: list));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  // --- US-10: confirm a peer ---
  Future<void> _onConfirmPeer(
      PeerTaskConfirmed event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await taskRepository.confirmTask(
        circleId: event.circleId,
        dateId: event.dateId,
        studentUid: event.studentUid,
      );
      final remaining = state.pendingConfirmations
          .where((t) => t.uid != event.studentUid)
          .toList();
      emit(state.copyWith(
        status: UIStatus.success,
        message: 'تم تأكيد التسميع',
        pendingConfirmations: remaining,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  // --- US-35: assignments ---
  Future<void> _onLoadAssignments(
      AssignmentsLoadRequested event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: UIStatus.loading));
    try {
      final list = await taskRepository.getAssignmentsForStudent(
        circleId: event.circleId,
        studentId: event.studentId,
      );
      emit(state.copyWith(status: UIStatus.success, assignments: list));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onCreateAssignment(
      AssignmentCreateRequested event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: UIStatus.loading, message: ''));
    try {
      await taskRepository.createAssignment(
        circleId: event.circleId,
        assignment: event.assignment,
      );
      emit(state.copyWith(
          status: UIStatus.success, message: 'تم إنشاء التكليف'));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }

  Future<void> _onToggleAssignment(
      AssignmentDoneToggled event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.setAssignmentDone(
        circleId: event.circleId,
        assignmentId: event.assignmentId,
        done: event.done,
      );
      final updated = state.assignments
          .map((a) =>
              a.id == event.assignmentId ? a.copyWith(done: event.done) : a)
          .toList();
      emit(state.copyWith(status: UIStatus.success, assignments: updated));
    } on Exception catch (e) {
      emit(state.copyWith(
          status: UIStatus.error, message: mapExceptionToMessage(e)));
    }
  }
}
