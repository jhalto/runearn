import 'package:equatable/equatable.dart';

class TourCollection extends Equatable {
  const TourCollection({
    required this.id,
    required this.tourId,
    required this.memberName,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String tourId;
  final String memberName;
  final double amount;
  final DateTime date;
  final String note;

  @override
  List<Object?> get props => [id, tourId, memberName, amount, date, note];
}
