import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/core/notifications/finance_notification_service.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_state.dart';

class FinanceReminderListener extends StatefulWidget {
  const FinanceReminderListener({required this.child, super.key});

  final Widget child;

  @override
  State<FinanceReminderListener> createState() =>
      _FinanceReminderListenerState();
}

class _FinanceReminderListenerState extends State<FinanceReminderListener>
    with WidgetsBindingObserver {
  StreamSubscription<RecurringState>? _recurringSubscription;
  StreamSubscription<LoanState>? _loanSubscription;
  StreamSubscription<AccountState>? _accountSubscription;
  Timer? _debounce;
  bool _scheduling = false;
  bool _scheduleAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recurringSubscription = sl<RecurringBloc>().stream.listen((state) {
      if (state is RecurringLoaded) _queueSchedule();
    });
    _loanSubscription = sl<LoanBloc>().stream.listen((state) {
      if (state is LoanLoaded) _queueSchedule();
    });
    _accountSubscription = sl<AccountBloc>().stream.listen((state) {
      if (state is AccountLoaded) _queueSchedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAndSchedule();
    }
  }

  void onAuthChanged(AuthState state) {
    if (state is AuthAuthenticated) {
      unawaited(sl<FinanceNotificationService>().requestPermissionOnce());
      _loadAndSchedule();
    } else if (state is AuthUnauthenticated) {
      _debounce?.cancel();
      unawaited(sl<FinanceNotificationService>().cancelFinanceReminders());
    }
  }

  void _loadAndSchedule() {
    if (!mounted || context.read<AuthBloc>().state is! AuthAuthenticated) {
      return;
    }
    sl<RecurringBloc>().loadIfNeeded();
    sl<LoanBloc>().loadIfNeeded();
    sl<AccountBloc>().loadIfNeeded();
    _queueSchedule();
  }

  void _queueSchedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _schedule);
  }

  Future<void> _schedule() async {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    final recurringState = sl<RecurringBloc>().state;
    final loanState = sl<LoanBloc>().state;
    final accountState = sl<AccountBloc>().state;
    if (authState is! AuthAuthenticated ||
        recurringState is! RecurringLoaded ||
        loanState is! LoanLoaded ||
        accountState is! AccountLoaded) {
      return;
    }
    if (_scheduling) {
      _scheduleAgain = true;
      return;
    }

    _scheduling = true;
    try {
      await sl<FinanceNotificationService>().reschedule(
        userId: authState.user.uid,
        recurring: recurringState.items,
        loans: loanState.loans,
        accounts: accountState.accounts,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not schedule finance reminders: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _scheduling = false;
      if (_scheduleAgain) {
        _scheduleAgain = false;
        _queueSchedule();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _recurringSubscription?.cancel();
    _loanSubscription?.cancel();
    _accountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (_, state) => onAuthChanged(state),
    child: widget.child,
  );
}
