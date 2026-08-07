import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';

Map<String, dynamic> tourToMap(Tour item, String userId) => {
  'id': item.id,
  'userId': userId,
  'name': item.name,
  'destination': item.destination,
  'startDate': item.startDate.toUtc().toIso8601String(),
  'endDate': item.endDate.toUtc().toIso8601String(),
  'budget': item.budget,
  'status': item.status.name,
  'note': item.note,
};

Tour tourFromMap(Map<String, dynamic> map) => Tour(
  id: map['id'] as String,
  name: map['name'] as String,
  destination: map['destination'] as String,
  startDate: DateTime.parse(map['startDate'] as String).toLocal(),
  endDate: DateTime.parse(map['endDate'] as String).toLocal(),
  budget: (map['budget'] as num).toDouble(),
  status: TourStatus.values.firstWhere(
    (value) => value.name == map['status'],
    orElse: () => TourStatus.planned,
  ),
  note: map['note'] as String? ?? '',
);

Map<String, dynamic> collectionToMap(TourCollection item, String userId) => {
  'id': item.id,
  'userId': userId,
  'tourId': item.tourId,
  'memberName': item.memberName,
  'amount': item.amount,
  'date': item.date.toUtc().toIso8601String(),
  'note': item.note,
};

TourCollection collectionFromMap(Map<String, dynamic> map) => TourCollection(
  id: map['id'] as String,
  tourId: map['tourId'] as String,
  memberName: map['memberName'] as String,
  amount: (map['amount'] as num).toDouble(),
  date: DateTime.parse(map['date'] as String).toLocal(),
  note: map['note'] as String? ?? '',
);

Map<String, dynamic> expenseToMap(TourExpense item, String userId) => {
  'id': item.id,
  'userId': userId,
  'tourId': item.tourId,
  'title': item.title,
  'category': item.category,
  'amount': item.amount,
  'date': item.date.toUtc().toIso8601String(),
  'note': item.note,
};

TourExpense expenseFromMap(Map<String, dynamic> map) => TourExpense(
  id: map['id'] as String,
  tourId: map['tourId'] as String,
  title: map['title'] as String,
  category: map['category'] as String,
  amount: (map['amount'] as num).toDouble(),
  date: DateTime.parse(map['date'] as String).toLocal(),
  note: map['note'] as String? ?? '',
);
