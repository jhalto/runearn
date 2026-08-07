import 'package:equatable/equatable.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';

sealed class RecurringEvent extends Equatable {
  const RecurringEvent();
  @override
  List<Object?> get props => const [];
}

final class LoadRecurring extends RecurringEvent {
  const LoadRecurring();
}

final class SaveRecurringRequested extends RecurringEvent {
  const SaveRecurringRequested(this.item);
  final RecurringTransaction item;
  @override
  List<Object?> get props => [item];
}

final class DeleteRecurringRequested extends RecurringEvent {
  const DeleteRecurringRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class RecordRecurringRequested extends RecurringEvent {
  const RecordRecurringRequested(this.item, {this.recordedAt});
  final RecurringTransaction item;
  final DateTime? recordedAt;

  @override
  List<Object?> get props => [item, recordedAt];
}

final class SyncRecurringRequested extends RecurringEvent {
  const SyncRecurringRequested();
}

final class ResetRecurring extends RecurringEvent {
  const ResetRecurring();
}
