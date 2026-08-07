import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/feature/accounts/domain/entities/financial_position.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/budgets/domain/services/budget_progress_calculator.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_state.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_state.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_state.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_state.dart';
import 'package:runearn/feature/net_worth/presentation/widgets/net_worth_snapshot_builder.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/views/daily_view.dart';
import 'package:runearn/feature/transactions/presentation/views/monthly_view.dart';
import 'package:runearn/feature/transactions/presentation/views/transaction_detail_view.dart';
import 'package:runearn/feature/transactions/presentation/views/weekly_view.dart';
import 'package:runearn/feature/transactions/presentation/views/yearly_view.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:runearn/core/global_widgets/app_navigation_panel.dart';
import 'package:runearn/core/navigation/module_add_action.dart';
import 'package:runearn/feature/dashboard/data/dashboard_preferences_store.dart';
import 'package:runearn/feature/dashboard/domain/entities/dashboard_preferences.dart';
import 'package:runearn/feature/dashboard/domain/entities/financial_health_report.dart';
import 'package:runearn/feature/dashboard/domain/services/financial_health_calculator.dart';
import 'package:runearn/feature/dashboard/presentation/widgets/financial_health_card.dart';

const _offlineMessage =
    "You're offline. Your data will sync automatically when you're online again.";

String _dashboardErrorMessage(String message) {
  final normalized = message.toLowerCase();
  final isNetworkError =
      normalized.contains('404') ||
      normalized.contains('network') ||
      normalized.contains('socket') ||
      normalized.contains('connection') ||
      normalized.contains('host lookup') ||
      normalized.contains('unavailable') ||
      normalized.contains('offline');

  return isNetworkError
      ? _offlineMessage
      : 'Unable to load your data. Please try again.';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const double _desktopBreakpoint = 1100;

  int selectedIndex = 0; // 0 = monthly, 1 = weekly, 2 = yearly
  final PageController _typePageController = PageController();
  final DashboardPreferencesStore _preferencesStore =
      DashboardPreferencesStore();
  DashboardPreferences _preferences = DashboardPreferences.defaults();

  @override
  void initState() {
    super.initState();
    _loadDashboardPreferences();
  }

  Future<void> _loadDashboardPreferences() async {
    final preferences = await _preferencesStore.load();
    if (mounted) setState(() => _preferences = preferences);
  }

  void _navigate(String route, {bool closeDrawer = false}) {
    if (closeDrawer) {
      Navigator.pop(context);
    }
    if (route == Routes.home) return;
    Navigator.pushNamed(context, route);
  }

  AnalyticsLabel _formatAnalyticsLabel(String label, int selectedIndex) {
    try {
      // Daily label example: 2026-05-25
      if (selectedIndex == 0) {
        final date = DateTime.parse(label);

        return AnalyticsLabel(
          title: DateFormat('EEEE').format(date), // Monday
          subtitle: DateFormat('dd MMM yyyy').format(date), // 25 May 2026
        );
      }

      // Weekly label example: 2026-W21
      // Weekly label example: 2026-W21
      if (selectedIndex == 1) {
        final parts = label.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);

        final startDate = _getIsoWeekStartDate(year, week);
        final endDate = startDate.add(const Duration(days: 6));

        return AnalyticsLabel(
          title: 'Week $week',
          subtitle:
              '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
        );
      }

      // Monthly label example: 2026-05
      if (selectedIndex == 2) {
        final date = DateTime.parse('$label-01');

        return AnalyticsLabel(
          title: DateFormat('MMMM').format(date), // May
          subtitle: DateFormat('yyyy').format(date), // 2026
        );
      }

      // Yearly label example: 2026
      return AnalyticsLabel(title: 'Year', subtitle: label);
    } catch (_) {
      return AnalyticsLabel(title: label, subtitle: '');
    }
  }

  IconData _analyticsIcon(int index) {
    switch (index) {
      case 0:
        return Icons.today_rounded;
      case 1:
        return Icons.calendar_view_week_rounded;
      case 2:
        return Icons.calendar_month_rounded;
      case 3:
        return Icons.bar_chart_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }

  @override
  void dispose() {
    _typePageController.dispose();
    super.dispose();
  }

  Future<void> _showDashboardCustomizer() async {
    var draft = _preferences;
    final result = await showModalBottomSheet<DashboardPreferences>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Customize dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Drag to reorder and hide sections you do not need.',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: draft.order.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setSheetState(() {
                        final order = [...draft.order];
                        final section = order.removeAt(oldIndex);
                        order.insert(newIndex, section);
                        draft = draft.copyWith(order: order);
                      });
                    },
                    itemBuilder: (context, index) {
                      final section = draft.order[index];
                      final visible = draft.visible.contains(section);
                      return SwitchListTile.adaptive(
                        key: ValueKey(section),
                        secondary: const Icon(Icons.drag_handle_rounded),
                        title: Text(section.label),
                        value: visible,
                        onChanged: section == DashboardSection.overview
                            ? null
                            : (value) {
                                setSheetState(() {
                                  final next = {...draft.visible};
                                  value
                                      ? next.add(section)
                                      : next.remove(section);
                                  draft = draft.copyWith(visible: next);
                                });
                              },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => setSheetState(
                          () => draft = DashboardPreferences.defaults(),
                        ),
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, draft),
                        child: const Text('Save layout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _preferences = result);
    await _preferencesStore.save(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.login,
              (route) => false,
            );
          }

          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_dashboardErrorMessage(state.message)),
              ),
            );
          }
        },
        builder: (context, authState) {
          final bool isLoggingOut = authState is AuthLoading;
          final profileState = context.watch<ProfileBloc>().state;
          final cachedName = profileState is ProfileLoaded
              ? profileState.user.name.trim()
              : '';
          final String currentUserName = cachedName.isNotEmpty
              ? cachedName
              : authState is AuthAuthenticated
              ? authState.user.displayName ??
                    authState.user.email?.split('@').first ??
                    'User'
              : 'Guest';
          final loanPosition = context
              .select<LoanBloc, ({double loanGiven, double loanTaken})>((bloc) {
                final state = bloc.state;
                if (state is! LoanLoaded) {
                  return (loanGiven: 0, loanTaken: 0);
                }
                return (
                  loanGiven: state.outstandingFor(LoanDirection.lent),
                  loanTaken: state.outstandingFor(LoanDirection.borrowed),
                );
              });
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
              final dashboard = Scaffold(
                drawer: isDesktop
                    ? null
                    : AppNavigationPanel(
                        currentRoute: Routes.home,
                        drawer: true,
                        onNavigate: (route) {
                          _navigate(route, closeDrawer: true);
                        },
                        onLogout: () {
                          context.read<AuthBloc>().add(LogoutEvent());
                        },
                      ),
                appBar: AppBar(
                  automaticallyImplyLeading: !isDesktop,
                  title: Text(
                    "Hi, $currentUserName",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Customize dashboard',
                      icon: const Icon(Icons.dashboard_customize_outlined),
                      onPressed: _showDashboardCustomizer,
                    ),
                    IconButton(
                      tooltip: 'Profile',
                      icon: const Icon(Icons.person_outline_rounded),
                      onPressed: () => _navigate(Routes.profile),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _navigate(Routes.settings),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SafeArea(
                  child: BlocBuilder<TransactionBloc, TransactionState>(
                    builder: (context, state) {
                      if (state is TransactionLoaded ||
                          state is TransactionSyncing) {
                        final bool isSyncing = state is TransactionSyncing;

                        final transactions = state is TransactionLoaded
                            ? state.transactions
                            : (state as TransactionSyncing).transactions;

                        final currency = context.watch<CurrencyCubit>().state;
                        final accountState = context.watch<AccountBloc>().state;
                        final accountCurrencies = accountState is AccountLoaded
                            ? {
                                for (final account in accountState.accounts)
                                  account.id: account.currencyCode,
                              }
                            : const <String, String>{};
                        final convertedTransactions = transactions
                            .map(
                              (transaction) => transaction.copyWith(
                                amount: () {
                                  final code =
                                      accountCurrencies[transaction
                                          .accountId] ??
                                      currency.baseCurrency;
                                  return currency.supports(code)
                                      ? currency.toBase(
                                          transaction.amount,
                                          code,
                                        )
                                      : 0.0;
                                }(),
                              ),
                            )
                            .toList(growable: false);
                        final analytics = TransactionAnalytics(
                          convertedTransactions,
                        );

                        final theme = Theme.of(context);

                        return Stack(
                          children: [
                            _buildCommandCenter(
                              theme: theme,
                              analytics: analytics,
                              transactions: convertedTransactions,
                              loanGiven: loanPosition.loanGiven,
                              loanTaken: loanPosition.loanTaken,
                            ),
                            if (isSyncing)
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        );
                      }

                      if (state is TransactionError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _dashboardErrorMessage(state.message),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
    
              );
              return Stack(
                children: [
                  if (isDesktop)
                    Row(
                      children: [
                        SizedBox(
                          width: 260,
                          child: AppNavigationPanel(
                            currentRoute: Routes.home,
                            onNavigate: _navigate,
                            onLogout: () {
                              context.read<AuthBloc>().add(LogoutEvent());
                            },
                          ),
                        ),
                        Expanded(child: dashboard),
                      ],
                    )
                  else
                    dashboard,
                  if (isLoggingOut)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Logging out...',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ========================= UI PARTS =========================

  Widget _buildCommandCenter({
    required ThemeData theme,
    required TransactionAnalytics analytics,
    required List<Transaction> transactions,
    required double loanGiven,
    required double loanTaken,
  }) {
    return NetWorthSnapshotBuilder(
      builder: (context, snapshot) {
        final now = DateTime.now();
        final monthTransactions = transactions.where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        );
        final monthIncome = monthTransactions
            .where((item) => item.type == TransactionType.income)
            .fold<double>(0, (total, item) => total + item.amount);
        final monthExpense = monthTransactions
            .where((item) => item.type == TransactionType.expense)
            .fold<double>(0, (total, item) => total + item.amount);

        final budgetState = context.watch<BudgetBloc>().state;
        final budgetProgress = budgetState is BudgetLoaded
            ? BudgetProgressCalculator.calculate(
                budgetState.budgets,
                transactions,
                now,
              )
            : const [];
        final budgetLimit = budgetProgress.fold<double>(
          0,
          (total, item) => total + item.effectiveLimit,
        );
        final budgetSpent = budgetProgress.fold<double>(
          0,
          (total, item) => total + item.spent,
        );

        final goalState = context.watch<GoalBloc>().state;
        final goalTarget = goalState is GoalLoaded
            ? goalState.goals.fold<double>(
                0,
                (total, goal) => total + goal.targetAmount,
              )
            : 0.0;
        final goalSaved = goalState is GoalLoaded
            ? goalState.goals.fold<double>(
                0,
                (total, goal) => total + goalState.savedFor(goal.id),
              )
            : 0.0;

        final recurringState = context.watch<RecurringBloc>().state;
        final dueCount = recurringState is RecurringLoaded
            ? recurringState.active.length
            : 0;
        final overdueCount = recurringState is RecurringLoaded
            ? recurringState.overdueAt(now).length
            : 0;
        final health = FinancialHealthCalculator.calculate(
          monthlyIncome: monthIncome,
          monthlyExpense: monthExpense,
          assets: snapshot.totalAssets,
          liabilities: snapshot.totalLiabilities,
          budgetLimit: budgetLimit,
          budgetSpent: budgetSpent,
          overdueObligations: overdueCount,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildDashboardSections(
                    theme: theme,
                    analytics: analytics,
                    transactions: transactions,
                    health: health,
                    netWorth: snapshot.netWorth,
                    assets: snapshot.totalAssets,
                    liabilities: snapshot.totalLiabilities,
                    monthIncome: monthIncome,
                    monthExpense: monthExpense,
                    budgetLimit: budgetLimit,
                    budgetSpent: budgetSpent,
                    goalTarget: goalTarget,
                    goalSaved: goalSaved,
                    dueCount: dueCount,
                    overdueCount: overdueCount,
                    loanGiven: loanGiven,
                    loanTaken: loanTaken,
                  ),
                  /*children: [
                    _DashboardFinancialHero(
                      netWorth: snapshot.netWorth,
                      assets: snapshot.totalAssets,
                      liabilities: snapshot.totalLiabilities,
                      monthCashFlow: monthIncome - monthExpense,
                      onOpen: () => _navigate(Routes.netWorth),
                    ),
                    const SizedBox(height: 16),
                    const _DashboardQuickActions(),
                    const SizedBox(height: 22),
                    _DashboardSectionHeader(
                      title: 'This month',
                      actionLabel: 'Open reports',
                      onAction: () => _navigate(Routes.reports),
                    ),
                    const SizedBox(height: 10),
                    _MonthlyCashFlowCard(
                      income: monthIncome,
                      expense: monthExpense,
                    ),
                    const SizedBox(height: 22),
                    const _DashboardSectionHeader(title: 'Financial plan'),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 950
                            ? 4
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: columns == 1 ? 2.5 : 1.65,
                          children: [
                            _DashboardFeatureCard(
                              title: 'Budgets',
                              value: budgetLimit == 0
                                  ? 'No limits set'
                                  : '${_money(budgetSpent)} of ${_money(budgetLimit)}',
                              detail: budgetLimit == 0
                                  ? 'Create monthly spending limits'
                                  : '${((budgetSpent / budgetLimit) * 100).clamp(0, 999).toStringAsFixed(0)}% used',
                              icon: Icons.savings_outlined,
                              color:
                                  budgetSpent > budgetLimit && budgetLimit > 0
                                  ? theme.colorScheme.error
                                  : Colors.teal,
                              onTap: () => _navigate(Routes.budgets),
                            ),
                            _DashboardFeatureCard(
                              title: 'Savings goals',
                              value: goalTarget == 0
                                  ? 'No goals yet'
                                  : '${_money(goalSaved)} saved',
                              detail: goalTarget == 0
                                  ? 'Plan your next financial milestone'
                                  : '${_money((goalTarget - goalSaved).clamp(0, double.infinity))} remaining',
                              icon: Icons.flag_outlined,
                              color: Colors.indigo,
                              onTap: () => _navigate(Routes.goals),
                            ),
                            _DashboardFeatureCard(
                              title: 'Bills & recurring',
                              value: '$dueCount active',
                              detail: overdueCount == 0
                                  ? 'No overdue reminders'
                                  : '$overdueCount overdue',
                              icon: Icons.event_repeat_outlined,
                              color: overdueCount > 0
                                  ? theme.colorScheme.error
                                  : Colors.blue,
                              onTap: () => _navigate(Routes.recurring),
                            ),
                            _DashboardFeatureCard(
                              title: 'Loans',
                              value: '${_money(loanGiven)} given',
                              detail: '${_money(loanTaken)} taken',
                              icon: Icons.handshake_outlined,
                              color: Colors.orange,
                              onTap: () => _navigate(Routes.moneyLent),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _DashboardSectionHeader(
                      title: 'Transaction activity',
                      actionLabel: 'View all',
                      onAction: () => _goToAnalyticsDetails(selectedIndex),
                    ),
                    const SizedBox(height: 8),
                    _buildToggle(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 430,
                      child: PageView(
                        controller: _typePageController,
                        onPageChanged: (index) =>
                            setState(() => selectedIndex = index),
                        children: [
                          _buildAnalyticsList(
                            analytics.daily(),
                            transactions,
                            theme,
                            0,
                          ),
                          _buildAnalyticsList(
                            analytics.weekly(),
                            transactions,
                            theme,
                            1,
                          ),
                          _buildAnalyticsList(
                            analytics.monthly(),
                            transactions,
                            theme,
                            2,
                          ),
                          _buildAnalyticsList(
                            analytics.yearly(),
                            transactions,
                            theme,
                            3,
                          ),
                        ],
                      ),
                    ),
                  ],*/
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDashboardSections({
    required ThemeData theme,
    required TransactionAnalytics analytics,
    required List<Transaction> transactions,
    required FinancialHealthReport health,
    required double netWorth,
    required double assets,
    required double liabilities,
    required double monthIncome,
    required double monthExpense,
    required double budgetLimit,
    required double budgetSpent,
    required double goalTarget,
    required double goalSaved,
    required int dueCount,
    required int overdueCount,
    required double loanGiven,
    required double loanTaken,
  }) {
    final sections = <DashboardSection, Widget>{
      DashboardSection.overview: _DashboardFinancialHero(
        netWorth: netWorth,
        assets: assets,
        liabilities: liabilities,
        monthCashFlow: monthIncome - monthExpense,
        onOpen: () => _navigate(Routes.netWorth),
      ),
      DashboardSection.health: FinancialHealthCard(report: health),
      DashboardSection.quickActions: const _DashboardQuickActions(),
      DashboardSection.cashFlow: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardSectionHeader(
            title: 'This month',
            actionLabel: 'Open reports',
            onAction: () => _navigate(Routes.reports),
          ),
          const SizedBox(height: 10),
          _MonthlyCashFlowCard(income: monthIncome, expense: monthExpense),
        ],
      ),
      DashboardSection.financialPlan: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DashboardSectionHeader(title: 'Financial plan'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 950
                  ? 4
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 2.5 : 1.65,
                children: [
                  _DashboardFeatureCard(
                    title: 'Budgets',
                    value: budgetLimit == 0
                        ? 'No limits set'
                        : '${_money(budgetSpent)} of ${_money(budgetLimit)}',
                    detail: budgetLimit == 0
                        ? 'Create monthly spending limits'
                        : '${((budgetSpent / budgetLimit) * 100).clamp(0, 999).toStringAsFixed(0)}% used',
                    icon: Icons.savings_outlined,
                    color: budgetSpent > budgetLimit && budgetLimit > 0
                        ? theme.colorScheme.error
                        : Colors.teal,
                    onTap: () => _navigate(Routes.budgets),
                  ),
                  _DashboardFeatureCard(
                    title: 'Savings goals',
                    value: goalTarget == 0
                        ? 'No goals yet'
                        : '${_money(goalSaved)} saved',
                    detail: goalTarget == 0
                        ? 'Plan your next financial milestone'
                        : '${_money((goalTarget - goalSaved).clamp(0, double.infinity))} remaining',
                    icon: Icons.flag_outlined,
                    color: Colors.indigo,
                    onTap: () => _navigate(Routes.goals),
                  ),
                  _DashboardFeatureCard(
                    title: 'Bills & recurring',
                    value: '$dueCount active',
                    detail: overdueCount == 0
                        ? 'No overdue reminders'
                        : '$overdueCount overdue',
                    icon: Icons.event_repeat_outlined,
                    color: overdueCount > 0
                        ? theme.colorScheme.error
                        : Colors.blue,
                    onTap: () => _navigate(Routes.recurring),
                  ),
                  _DashboardFeatureCard(
                    title: 'Loans',
                    value: '${_money(loanGiven)} given',
                    detail: '${_money(loanTaken)} taken',
                    icon: Icons.handshake_outlined,
                    color: Colors.orange,
                    onTap: () => _navigate(Routes.moneyLent),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      DashboardSection.activity: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardSectionHeader(
            title: 'Transaction activity',
            actionLabel: 'View all',
            onAction: () => _goToAnalyticsDetails(selectedIndex),
          ),
          const SizedBox(height: 8),
          _buildToggle(),
          const SizedBox(height: 8),
          SizedBox(
            height: 430,
            child: PageView(
              controller: _typePageController,
              onPageChanged: (index) => setState(() => selectedIndex = index),
              children: [
                _buildAnalyticsList(analytics.daily(), transactions, theme, 0),
                _buildAnalyticsList(analytics.weekly(), transactions, theme, 1),
                _buildAnalyticsList(
                  analytics.monthly(),
                  transactions,
                  theme,
                  2,
                ),
                _buildAnalyticsList(analytics.yearly(), transactions, theme, 3),
              ],
            ),
          ),
        ],
      ),
    };
    return [
      for (final section in _preferences.order)
        if (_preferences.visible.contains(section)) ...[
          sections[section]!,
          const SizedBox(height: 22),
        ],
    ];
  }

  Widget _buildBalanceCard(
    ThemeData theme,
    analytics,
    double loanGiven,
    double loanTaken,
  ) {
    final availableBalance = analytics.balance - loanGiven + loanTaken;
    final position = FinancialPosition(
      cash: availableBalance,
      loanGiven: loanGiven,
      loanTaken: loanTaken,
    );
    final isNegative = position.netWorth < 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative
              ? [Colors.red, Colors.redAccent]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : theme.colorScheme.primary)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            MoneyFormatter.formatBase(availableBalance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PositionValue(
                  label: 'Assets',
                  value: position.totalAssets,
                ),
              ),
              Expanded(
                child: _PositionValue(
                  label: 'Liabilities',
                  value: position.totalLiabilities,
                ),
              ),
              Expanded(
                child: _PositionValue(
                  label: 'Net Worth',
                  value: position.netWorth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _summaryCard(
            onTap: () => Navigator.pushNamed(context, Routes.income),
            "Income",
            analytics.totalIncome,
            Colors.green,
            Icons.arrow_downward,
          ),

          const SizedBox(width: 10),
          _summaryCard(
            onTap: () => Navigator.pushNamed(context, Routes.expense),
            "Expense",
            analytics.totalExpense,
            Colors.red,
            Icons.arrow_upward,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    double amount,
    Color color,
    IconData icon, {
    GestureTapCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    MoneyFormatter.formatBase(amount),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["Daily", "Weekly", "Monthly", "Yearly"].asMap().entries.map((
          e,
        ) {
          final i = e.key;
          final text = e.value;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(text),
              selected: selectedIndex == i,
              onSelected: (_) {
                setState(() => selectedIndex = i);

                _typePageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _goToAnalyticsDetails(int index) {
    Widget page;

    switch (index) {
      case 0:
        page = const DailyView();
        break;
      case 1:
        page = const WeeklyView();
        break;
      case 2:
        page = const MonthlyView();
        break;
      case 3:
        page = const YearlyView();
        break;
      default:
        page = const DailyView();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<TransactionBloc>()),
            BlocProvider.value(value: context.read<AccountBloc>()),
          ],
          child: page,
        ),
      ),
    );
  }

  Widget _buildAnalyticsList(
    List data,
    List transactions,
    ThemeData theme,
    int periodIndex,
  ) {
    if (data.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _goToAnalyticsDetails(periodIndex),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
          ),
          child: const Center(child: Text("No analytics data")),
        ),
      );
    }

    return PageView.builder(
      padEnds: false,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final m = data[index];
        final labelData = _formatAnalyticsLabel(m.label, periodIndex);

        final relatedTransactions = _filterTransactionsByLabel(
          transactions,
          m.label,
          periodIndex,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _goToAnalyticsDetails(periodIndex),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _analyticsIcon(periodIndex),
                            color: theme.colorScheme.primary,
                            size: 21,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labelData.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                labelData.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: _buildTransactionList(relatedTransactions, theme),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _miniAnalyticsAmount(
                            title: "Income",
                            amount: m.income,
                            color: Colors.green,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _miniAnalyticsAmount(
                            title: "Expense",
                            amount: m.expense,
                            color: Colors.red,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: m.balance >= 0
                            ? Colors.green.withOpacity(0.08)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${m.balance >= 0 ? '+' : '-'}"
                        "${MoneyFormatter.formatBase(m.balance.abs())}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: m.balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardFinancialHero extends StatelessWidget {
  const _DashboardFinancialHero({
    required this.netWorth,
    required this.assets,
    required this.liabilities,
    required this.monthCashFlow,
    required this.onOpen,
  });

  final double netWorth;
  final double assets;
  final double liabilities;
  final double monthCashFlow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final negative = netWorth < 0;
    final accent = negative ? colors.error : colors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: .72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'NET WORTH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Text(
                    'View details',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _money(netWorth),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'This month cash flow: '
                '${monthCashFlow >= 0 ? '+' : '-'}${_money(monthCashFlow.abs())}',
                style: TextStyle(
                  color: monthCashFlow >= 0
                      ? Colors.greenAccent.shade100
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _HeroValue(
                      label: 'Assets',
                      value: assets,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  Container(width: 1, height: 42, color: Colors.white24),
                  Expanded(
                    child: _HeroValue(
                      label: 'Liabilities',
                      value: liabilities,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: Colors.white70, size: 19),
      const SizedBox(width: 7),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              _money(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DashboardQuickActions extends StatelessWidget {
  const _DashboardQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'Add income',
        Icons.add_circle_outline_rounded,
        Colors.green,
        Routes.addIncome,
      ),
      (
        'Add expense',
        Icons.remove_circle_outline_rounded,
        Theme.of(context).colorScheme.error,
        Routes.addExpense,
      ),
      ('Transfer', Icons.swap_horiz_rounded, Colors.blue, Routes.addTransfer),
      (
        'Add account',
        Icons.account_balance_wallet_outlined,
        Colors.indigo,
        Routes.addAccount,
      ),
      ('Add goal', Icons.flag_outlined, Colors.purple, Routes.addGoal),
      (
        'Add reminder',
        Icons.event_repeat_outlined,
        Colors.orange,
        Routes.addRecurring,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 850
                ? 6
                : width >= 520
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => showModuleAddAction(context, action.$4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: action.$3.withValues(alpha: .12),
                        foregroundColor: action.$3,
                        child: Icon(action.$2, size: 21),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        action.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({required this.report});

  final FinancialHealthReport report;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (report.score) {
      >= 80 => Colors.green,
      >= 60 => Colors.teal,
      >= 40 => Colors.orange,
      _ => colors.error,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: SizedBox.square(
          dimension: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: report.score / 100,
                strokeWidth: 6,
                color: color,
                backgroundColor: color.withValues(alpha: .15),
              ),
              Center(
                child: Text(
                  '${report.score}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Financial health • ${report.label}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Tap to see the score breakdown'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          for (final indicator in report.indicators) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(indicator.label)),
                Text(
                  '${indicator.score}/${indicator.maximum}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: indicator.score / indicator.maximum,
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                indicator.detail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (report.recommendations.isNotEmpty) ...[
            const Divider(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recommended next steps',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            for (final recommendation in report.recommendations)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_rounded, size: 18, color: color),
                    const SizedBox(width: 5),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _MonthlyCashFlowCard extends StatelessWidget {
  const _MonthlyCashFlowCard({required this.income, required this.expense});
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final cashFlow = income - expense;
    final total = income + expense;
    final incomeShare = total == 0 ? .5 : income / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CashFlowValue(
                    label: 'Income',
                    value: income,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _CashFlowValue(
                    label: 'Expenses',
                    value: expense,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _CashFlowValue(
                    label: 'Cash flow',
                    value: cashFlow,
                    color: cashFlow < 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 9,
                child: Row(
                  children: [
                    Expanded(
                      flex: (incomeShare * 1000).round().clamp(1, 999),
                      child: Container(color: Colors.green),
                    ),
                    Expanded(
                      flex: ((1 - incomeShare) * 1000).round().clamp(1, 999),
                      child: Container(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowValue extends StatelessWidget {
  const _CashFlowValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        _money(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _DashboardFeatureCard extends StatelessWidget {
  const _DashboardFeatureCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .12),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PositionValue extends StatelessWidget {
  const _PositionValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          MoneyFormatter.formatBase(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _money(double value) => MoneyFormatter.formatBase(value);

List _filterTransactionsByLabel(
  List transactions,
  String label,
  int periodIndex,
) {
  final range = _getDateRangeFromLabel(label, periodIndex);

  return transactions.where((t) {
    final date = DateTime(t.date.year, t.date.month, t.date.day);

    return !date.isBefore(range.start) && date.isBefore(range.end);
  }).toList();
}

_DateRange _getDateRangeFromLabel(String label, int periodIndex) {
  // Daily: 2026-05-25
  if (periodIndex == 0) {
    final date = DateTime.parse(label);

    return _DateRange(
      start: DateTime(date.year, date.month, date.day),
      end: DateTime(date.year, date.month, date.day + 1),
    );
  }

  // Weekly: 2026-W22
  if (periodIndex == 1) {
    final parts = label.split('-W');
    final year = int.parse(parts[0]);
    final week = int.parse(parts[1]);

    final start = _getIsoWeekStartDate(year, week);

    return _DateRange(start: start, end: start.add(const Duration(days: 7)));
  }

  // Monthly: 2026-05
  if (periodIndex == 2) {
    final date = DateTime.parse('$label-01');

    return _DateRange(
      start: DateTime(date.year, date.month, 1),
      end: DateTime(date.year, date.month + 1, 1),
    );
  }

  // Yearly: 2026
  final year = int.parse(label);

  return _DateRange(start: DateTime(year, 1, 1), end: DateTime(year + 1, 1, 1));
}

String _formatCategory(String value) {
  if (value.isEmpty) return "General";

  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

Widget _buildTransactionList(List transactions, ThemeData theme) {
  if (transactions.isEmpty) {
    return Center(
      child: Text(
        "No transactions in this period",
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  return ListView.separated(
    padding: EdgeInsets.zero,
    itemCount: transactions.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final t = transactions[index];
      final isIncome = t.type == TransactionType.income;
      final category = t.categoryName;

      return Material(
        color: isIncome
            ? Colors.green.withOpacity(0.06)
            : Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<TransactionBloc>()),
                    BlocProvider.value(value: context.read<AccountBloc>()),
                  ],
                  child: TransactionDetailView(transaction: t),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCategory(category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.description.isEmpty
                            ? "No description"
                            : t.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  "${isIncome ? '+' : '-'}"
                  "${MoneyFormatter.formatBase(t.amount)}",
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AnalyticsLabel {
  final String title;
  final String subtitle;

  AnalyticsLabel({required this.title, required this.subtitle});
}

Widget _miniAnalyticsAmount({
  required String title,
  required double amount,
  required Color color,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                MoneyFormatter.formatBase(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

DateTime _getIsoWeekStartDate(int year, int week) {
  final jan4 = DateTime(year, 1, 4);
  final weekOneMonday = jan4.subtract(Duration(days: jan4.weekday - 1));

  return weekOneMonday.add(Duration(days: (week - 1) * 7));
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
