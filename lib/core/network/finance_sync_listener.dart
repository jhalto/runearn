import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_event.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_event.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';

class FinanceSyncListener extends StatefulWidget {
  final Widget child;

  const FinanceSyncListener({required this.child, super.key});

  @override
  State<FinanceSyncListener> createState() => _FinanceSyncListenerState();
}

class _FinanceSyncListenerState extends State<FinanceSyncListener>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = sl<NetworkInfo>().onConnectionChanged.listen((isOnline) {
      if (isOnline) _syncIfAuthenticated();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncIfAuthenticated();
    }
  }

  void _syncIfAuthenticated() {
    if (!mounted) return;
    if (context.read<AuthBloc>().state is! AuthAuthenticated) return;
    sl<TransactionBloc>().add(const SyncPendingTransactionsEvent());
    sl<LoanBloc>().add(const SyncPendingLoansRequested());
    sl<AccountBloc>().add(const SyncAccountsRequested());
    sl<BudgetBloc>().add(const SyncBudgetsRequested());
    sl<GoalBloc>().add(const SyncGoalsRequested());
    sl<RecurringBloc>().add(const SyncRecurringRequested());
    sl<TourBloc>().add(const SyncToursRequested());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
