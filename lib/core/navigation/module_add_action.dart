import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/pages/accounts_page.dart';
import 'package:runearn/feature/accounts/presentation/pages/transfers_page.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/pages/goals_page.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/widgets/add_loan_sheet.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/pages/recurring_page.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

typedef _AddAction = Future<void> Function(BuildContext context);

bool isModuleAddRoute(String route) => switch (route) {
  Routes.addIncome ||
  Routes.addExpense ||
  Routes.addAccount ||
  Routes.addTransfer ||
  Routes.addGoal ||
  Routes.addRecurring => true,
  Routes.addLoanGiven || Routes.addLoanTaken => true,
  Routes.addTour => true,
  _ => false,
};

Future<void> showModuleAddAction(BuildContext context, String route) {
  final Widget launcher = switch (route) {
    Routes.addIncome => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<TransactionBloc>()..loadIfNeeded()),
        BlocProvider.value(value: sl<AccountBloc>()..loadIfNeeded()),
      ],
      child: const _AddActionLauncher(onOpen: TransactionSheet.showIncome),
    ),
    Routes.addExpense => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<TransactionBloc>()..loadIfNeeded()),
        BlocProvider.value(value: sl<AccountBloc>()..loadIfNeeded()),
      ],
      child: const _AddActionLauncher(onOpen: TransactionSheet.showExpense),
    ),
    Routes.addAccount => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AccountBloc>()..loadIfNeeded()),
        BlocProvider.value(value: sl<TransactionBloc>()..loadIfNeeded()),
      ],
      child: const _AddActionLauncher(onOpen: showAccountSheet),
    ),
    Routes.addTransfer => BlocProvider.value(
      value: sl<AccountBloc>()..loadIfNeeded(),
      child: const _AddActionLauncher(onOpen: showTransferSheet),
    ),
    Routes.addGoal => BlocProvider.value(
      value: sl<GoalBloc>()..loadIfNeeded(),
      child: const _AddActionLauncher(onOpen: showGoalEditor),
    ),
    Routes.addRecurring => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<RecurringBloc>()..loadIfNeeded()),
        BlocProvider.value(value: sl<TransactionBloc>()..loadIfNeeded()),
        BlocProvider.value(value: sl<AccountBloc>()..loadIfNeeded()),
      ],
      child: const _AddActionLauncher(onOpen: showRecurringEditor),
    ),
    Routes.addLoanGiven => BlocProvider.value(
      value: sl<LoanBloc>()..loadIfNeeded(),
      child: const _AddActionLauncher(onOpen: _showAddLoanGiven),
    ),
    Routes.addLoanTaken => BlocProvider.value(
      value: sl<LoanBloc>()..loadIfNeeded(),
      child: const _AddActionLauncher(onOpen: _showAddLoanTaken),
    ),
    Routes.addTour => BlocProvider.value(
      value: sl<TourBloc>()..loadIfNeeded(),
      child: const _AddActionLauncher(onOpen: showTourEditor),
    ),
    _ => throw ArgumentError.value(route, 'route', 'Unsupported add action'),
  };

  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => launcher,
    ),
  );
}

Future<void> _showAddLoanGiven(BuildContext context) =>
    showAddLoanSheet(context, LoanDirection.lent);

Future<void> _showAddLoanTaken(BuildContext context) =>
    showAddLoanSheet(context, LoanDirection.borrowed);

class _AddActionLauncher extends StatefulWidget {
  const _AddActionLauncher({required this.onOpen});

  final _AddAction onOpen;

  @override
  State<_AddActionLauncher> createState() => _AddActionLauncherState();
}

class _AddActionLauncherState extends State<_AddActionLauncher> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    await widget.onOpen(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
      type: MaterialType.transparency,
      child: IgnorePointer(child: SizedBox.expand()),
    );
  }
}
