import 'package:equatable/equatable.dart';

enum DashboardSection {
  overview('Financial overview'),
  health('Financial health'),
  quickActions('Quick actions'),
  cashFlow('Monthly cash flow'),
  financialPlan('Financial plan'),
  activity('Transaction activity');

  const DashboardSection(this.label);
  final String label;
}

class DashboardPreferences extends Equatable {
  const DashboardPreferences({required this.order, required this.visible});

  factory DashboardPreferences.defaults() => DashboardPreferences(
    order: DashboardSection.values,
    visible: DashboardSection.values.toSet(),
  );

  final List<DashboardSection> order;
  final Set<DashboardSection> visible;

  DashboardPreferences copyWith({
    List<DashboardSection>? order,
    Set<DashboardSection>? visible,
  }) => DashboardPreferences(
    order: List.unmodifiable(order ?? this.order),
    visible: Set.unmodifiable(visible ?? this.visible),
  );

  @override
  List<Object?> get props => [order, visible];
}
