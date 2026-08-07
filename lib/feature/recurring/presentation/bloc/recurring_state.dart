import 'package:equatable/equatable.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';

sealed class RecurringState extends Equatable {
  const RecurringState();
  @override
  List<Object?> get props => const [];
}

final class RecurringInitial extends RecurringState {
  const RecurringInitial();
}

final class RecurringLoading extends RecurringState {
  const RecurringLoading();
}

final class RecurringLoaded extends RecurringState {
  RecurringLoaded(List<RecurringTransaction> items)
    : items = List.unmodifiable(items);
  final List<RecurringTransaction> items;

  List<RecurringTransaction> get active =>
      items.where((item) => item.isActive).toList(growable: false);

  List<RecurringTransaction> overdueAt(DateTime now) => active
      .where((item) => _dateOnly(item.nextDue).isBefore(_dateOnly(now)))
      .toList(growable: false);

  @override
  List<Object?> get props => [items];
}

final class RecurringFailure extends RecurringState {
  const RecurringFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
