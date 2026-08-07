import 'package:equatable/equatable.dart';

enum TourStatus { planned, active, completed, cancelled }

class Tour extends Equatable {
  const Tour({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.status,
    this.note = '',
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final TourStatus status;
  final String note;

  @override
  List<Object?> get props => [
    id,
    name,
    destination,
    startDate,
    endDate,
    budget,
    status,
    note,
  ];
}
