import 'package:runearn/feature/dashboard/domain/entities/dashboard_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPreferencesStore {
  static const _orderKey = 'dashboard_section_order_v1';
  static const _visibleKey = 'dashboard_section_visible_v1';

  Future<DashboardPreferences> load() async {
    final storage = await SharedPreferences.getInstance();
    final savedOrder = storage.getStringList(_orderKey) ?? const [];
    final savedVisible = storage.getStringList(_visibleKey);
    final order = <DashboardSection>[
      for (final name in savedOrder)
        if (_section(name) case final section?) section,
      for (final section in DashboardSection.values)
        if (!savedOrder.contains(section.name)) section,
    ];
    final visible = savedVisible == null
        ? DashboardSection.values.toSet()
        : savedVisible.map(_section).whereType<DashboardSection>().toSet();
    return DashboardPreferences(order: order, visible: visible);
  }

  Future<void> save(DashboardPreferences preferences) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setStringList(
      _orderKey,
      preferences.order.map((section) => section.name).toList(),
    );
    await storage.setStringList(
      _visibleKey,
      preferences.visible.map((section) => section.name).toList(),
    );
  }

  DashboardSection? _section(String name) {
    for (final section in DashboardSection.values) {
      if (section.name == name) return section;
    }
    return null;
  }
}
