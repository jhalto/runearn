import 'package:equatable/equatable.dart';

class TourExpense extends Equatable {
  const TourExpense({
    required this.id,
    required this.tourId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String tourId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  @override
  List<Object?> get props => [id, tourId, title, category, amount, date, note];
}
