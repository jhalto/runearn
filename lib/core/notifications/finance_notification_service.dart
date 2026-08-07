import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/services/credit_card_calculator.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/services/loan_balance_calculator.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FinanceNotificationService {
  FinanceNotificationService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _payloadPrefix = 'finance-reminder:';
  static const _permissionKey = 'finance_notification_permission_requested';
  static const _overdueKeyPrefix = 'finance_overdue_notified:';
  static const _notificationHour = 9;

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'finance_reminders',
      'Finance reminders',
      channelDescription: 'Upcoming and overdue bill and loan reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_wallet'),
      iOS: darwin,
      macOS: darwin,
      linux: LinuxInitializationSettings(defaultActionName: 'Open RunEarn'),
      windows: WindowsInitializationSettings(
        appName: 'RunEarn',
        appUserModelId: 'JhaltoLab.RunEarn',
        guid: '17dc1f51-d548-48df-b7d4-44ff57e16f02',
      ),
    );
    try {
      await _notifications.initialize(settings: settings);
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> requestPermissionOnce() async {
    if (!_initialized) await initialize();
    if (!_initialized) return;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_permissionKey) == true) return;

    bool? granted;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        granted = await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      case TargetPlatform.iOS:
        granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case TargetPlatform.macOS:
        granted = await _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        granted = true;
    }
    if (granted != null) {
      await preferences.setBool(_permissionKey, true);
    }
  }

  Future<void> reschedule({
    required String userId,
    required List<RecurringTransaction> recurring,
    required List<Loan> loans,
    required List<FinanceAccount> accounts,
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    await _cancelFinanceReminders();
    final now = tz.TZDateTime.now(tz.local);
    final preferences = await SharedPreferences.getInstance();

    for (final item in recurring.where((item) => item.isActive)) {
      final due = _atReminderTime(item.nextDue);
      final payload = '${_payloadPrefix}bill:${item.id}';
      await _scheduleOrNotifyOverdue(
        userId: userId,
        itemKey: 'bill:${item.id}',
        due: due,
        now: now,
        upcomingId: _notificationId('bill:${item.id}', 1),
        dueId: _notificationId('bill:${item.id}', 2),
        upcomingTitle: 'Bill due tomorrow',
        dueTitle: 'Bill payment due',
        overdueTitle: 'Bill payment overdue',
        body: '${item.title} - ${_money(item.amount)}',
        payload: payload,
        preferences: preferences,
      );
    }

    for (final loan in loans.where(
      (loan) => !loan.isSettled && loan.dueAt != null && loan.reminderEnabled,
    )) {
      final due = _atReminderTime(loan.dueAt!);
      final action = loan.direction == LoanDirection.lent
          ? 'Collect from'
          : 'Repay to';
      final projected = LoanBalanceCalculator.calculate(
        loan,
        const [],
        asOf: loan.dueAt,
      ).totalDue;
      await _scheduleOrNotifyOverdue(
        userId: userId,
        itemKey: 'loan:${loan.id}',
        due: due,
        now: now,
        upcomingId: _notificationId('loan:${loan.id}', 1),
        dueId: _notificationId('loan:${loan.id}', 2),
        upcomingTitle: 'Loan due tomorrow',
        dueTitle: 'Loan payment due',
        overdueTitle: 'Loan payment overdue',
        body: '$action ${loan.personName} - ${_money(projected)}',
        payload: '${_payloadPrefix}loan:${loan.id}',
        preferences: preferences,
        upcomingDaysBefore: loan.reminderDaysBefore,
      );
    }

    for (final account in accounts.where(
      (account) =>
          account.type == FinanceAccountType.creditCard &&
          account.paymentReminderEnabled &&
          account.paymentDueDay != null,
    )) {
      final summary = CreditCardCalculator.calculate(account, account.balance);
      final due = _atReminderTime(summary.paymentDueDate);
      await _scheduleOrNotifyOverdue(
        userId: userId,
        itemKey: 'credit-card:${account.id}',
        due: due,
        now: now,
        upcomingId: _notificationId('credit-card:${account.id}', 1),
        dueId: _notificationId('credit-card:${account.id}', 2),
        upcomingTitle: 'Credit card payment upcoming',
        dueTitle: 'Credit card payment due',
        overdueTitle: 'Credit card payment overdue',
        body: '${account.name} - minimum ${_money(summary.minimumPayment)}',
        payload: '${_payloadPrefix}credit-card:${account.id}',
        preferences: preferences,
        upcomingDaysBefore: account.paymentReminderDaysBefore,
      );
    }
  }

  Future<void> cancelFinanceReminders() async {
    if (!_initialized) return;
    await _cancelFinanceReminders();
  }

  Future<void> _scheduleOrNotifyOverdue({
    required String userId,
    required String itemKey,
    required tz.TZDateTime due,
    required tz.TZDateTime now,
    required int upcomingId,
    required int dueId,
    required String upcomingTitle,
    required String dueTitle,
    required String overdueTitle,
    required String body,
    required String payload,
    required SharedPreferences preferences,
    int upcomingDaysBefore = 1,
  }) async {
    final upcoming = due.subtract(Duration(days: upcomingDaysBefore));
    if (upcomingDaysBefore > 0 && upcoming.isAfter(now)) {
      await _schedule(
        id: upcomingId,
        when: upcoming,
        title: upcomingTitle,
        body: body,
        payload: payload,
      );
    }
    if (due.isAfter(now)) {
      await _schedule(
        id: dueId,
        when: due,
        title: dueTitle,
        body: body,
        payload: payload,
      );
      return;
    }

    final overdueKey =
        '$_overdueKeyPrefix$userId:$itemKey:${due.year}-${due.month}-${due.day}';
    if (preferences.getBool(overdueKey) == true) return;
    await _notifications.show(
      id: dueId,
      title: overdueTitle,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
    await preferences.setBool(overdueKey, true);
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
  }) => _notifications.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: when,
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  Future<void> _cancelFinanceReminders() async {
    final pending = await _notifications.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload?.startsWith(_payloadPrefix) == true) {
        await _notifications.cancel(id: notification.id);
      }
    }
  }

  tz.TZDateTime _atReminderTime(DateTime date) => tz.TZDateTime(
    tz.local,
    date.year,
    date.month,
    date.day,
    _notificationHour,
  );

  int _notificationId(String value, int slot) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return ((hash % 100000000) * 10) + slot;
  }

  String _money(double amount) => 'BDT ${amount.toStringAsFixed(2)}';
}
