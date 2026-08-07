import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/pages/accounts_page.dart';
import 'package:runearn/feature/accounts/presentation/pages/transfers_page.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/feature/auth/presentation/views/login_view.dart';
import 'package:runearn/feature/auth/presentation/views/register_view.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/budgets/presentation/pages/budgets_page.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/pages/goals_page.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/pages/recurring_page.dart';
import 'package:runearn/feature/reports/presentation/pages/reports_page.dart';
import 'package:runearn/feature/backup/presentation/cubit/backup_cubit.dart';
import 'package:runearn/feature/backup/presentation/pages/backup_page.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/presentation/pages/loan_detail_page.dart';
import 'package:runearn/feature/loans/presentation/pages/money_borrowed_page.dart';
import 'package:runearn/feature/loans/presentation/pages/money_lent_page.dart';
import 'package:runearn/feature/net_worth/presentation/pages/net_worth_page.dart';
import 'package:runearn/feature/net_worth/presentation/pages/net_worth_breakdown_page.dart';
import 'package:runearn/feature/net_worth/domain/entities/net_worth_snapshot.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/profile/presentation/pages/profile_page.dart';
import 'package:runearn/feature/profile/presentation/cubit/account_deletion_cubit.dart';
import 'package:runearn/feature/settings/presentation/pages/settings_page.dart';
import 'package:runearn/feature/settings/presentation/pages/clear_data_page.dart';
import 'package:runearn/feature/settings/presentation/cubit/clear_data_cubit.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/pages/tour_collections_page.dart';
import 'package:runearn/feature/tours/presentation/pages/tour_contributor_detail_page.dart';
import 'package:runearn/feature/tours/presentation/pages/tour_detail_page.dart';
import 'package:runearn/feature/tours/presentation/pages/tour_expenses_page.dart';
import 'package:runearn/feature/tours/presentation/pages/tours_page.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';
import 'package:runearn/feature/dashboard/presentation/pages/dashboard_page.dart';
import 'package:runearn/feature/expenses/presentation/pages/add_expense_page.dart';
import 'package:runearn/feature/expenses/presentation/pages/expense_page.dart';
import 'package:runearn/feature/income/presentation/pages/add_income_page.dart';
import 'package:runearn/feature/income/presentation/pages/income_page.dart';
import 'package:runearn/feature/currency/presentation/pages/currency_settings_page.dart';
import 'package:runearn/feature/search/data/saved_filter_store.dart';
import 'package:runearn/feature/search/presentation/cubit/transaction_search_cubit.dart';
import 'package:runearn/feature/search/presentation/pages/transaction_search_page.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';

class AppRoutes {
  const AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (context) => const LoginView());
      case Routes.register:
        return MaterialPageRoute(builder: (context) => const RegisterView());

      case Routes.home:
        return _dashboardRoute();
      case Routes.netWorth:
        return _netWorthRoute();
      case Routes.netWorthAssets:
        return _netWorthRoute(
          const NetWorthBreakdownPage(
            classification: AccountClassification.asset,
          ),
        );
      case Routes.netWorthLiabilities:
        return _netWorthRoute(
          const NetWorthBreakdownPage(
            classification: AccountClassification.liability,
          ),
        );
      case Routes.netWorthDetails:
        final item = settings.arguments;
        if (item is NetWorthItem) {
          return _netWorthRoute(NetWorthItemDetailPage(item: item));
        }
        return _invalidArgumentsRoute('Net worth details');
      case Routes.budgets:
        final budgetBloc = sl<BudgetBloc>()..loadIfNeeded();
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: budgetBloc),
              BlocProvider.value(value: transactionBloc),
            ],
            child: const BudgetsPage(),
          ),
        );
      case Routes.goals:
        final bloc = sl<GoalBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) =>
              BlocProvider.value(value: bloc, child: const GoalsPage()),
        );
      case Routes.addGoal:
        final bloc = sl<GoalBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: _OpenOnFirstFrame(
              onOpen: showGoalEditor,
              child: const GoalsPage(currentRoute: Routes.addGoal),
            ),
          ),
        );
      case Routes.recurring:
        final recurringBloc = sl<RecurringBloc>()..loadIfNeeded();
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        final accountBloc = sl<AccountBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: recurringBloc),
              BlocProvider.value(value: transactionBloc),
              BlocProvider.value(value: accountBloc),
            ],
            child: const RecurringPage(),
          ),
        );
      case Routes.addRecurring:
        final recurringBloc = sl<RecurringBloc>()..loadIfNeeded();
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        final accountBloc = sl<AccountBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: recurringBloc),
              BlocProvider.value(value: transactionBloc),
              BlocProvider.value(value: accountBloc),
            ],
            child: _OpenOnFirstFrame(
              onOpen: showRecurringEditor,
              child: const RecurringPage(currentRoute: Routes.addRecurring),
            ),
          ),
        );
      case Routes.reports:
        return _transactionRoute(const ReportsPage());
      case Routes.tours:
        return _tourRoute(const ToursPage());
      case Routes.addTour:
        final bloc = sl<TourBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: _OpenOnFirstFrame(
              onOpen: showTourEditor,
              child: const ToursPage(),
            ),
          ),
        );
      case Routes.tourDetails:
        final id = settings.arguments;
        return id is String
            ? _tourRoute(TourDetailPage(tourId: id))
            : _invalidArgumentsRoute('Tour details');
      case Routes.tourCollections:
        final id = settings.arguments;
        return id is String
            ? _tourRoute(TourCollectionsPage(tourId: id))
            : _invalidArgumentsRoute('Tour collections');
      case Routes.tourContributorDetails:
        final arguments = settings.arguments;
        if (arguments case (
          tourId: String tourId,
          memberName: String memberName,
        )) {
          return _tourRoute(
            TourContributorDetailPage(tourId: tourId, memberName: memberName),
          );
        }
        return _invalidArgumentsRoute('Tour contributor details');
      case Routes.tourExpenses:
        final id = settings.arguments;
        return id is String
            ? _tourRoute(TourExpensesPage(tourId: id))
            : _invalidArgumentsRoute('Tour expenses');
      case Routes.accounts:
        final accountBloc = sl<AccountBloc>()..loadIfNeeded();
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc),
              BlocProvider.value(value: transactionBloc),
            ],
            child: const AccountsPage(),
          ),
        );
      case Routes.addAccount:
        final accountBloc = sl<AccountBloc>()..loadIfNeeded();
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: accountBloc),
              BlocProvider.value(value: transactionBloc),
            ],
            child: _OpenOnFirstFrame(
              onOpen: showAccountSheet,
              child: const AccountsPage(currentRoute: Routes.addAccount),
            ),
          ),
        );
      case Routes.transfers:
        final bloc = sl<AccountBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) =>
              BlocProvider.value(value: bloc, child: const TransfersPage()),
        );
      case Routes.addTransfer:
        final bloc = sl<AccountBloc>()..loadIfNeeded();
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: _OpenOnFirstFrame(
              onOpen: showTransferSheet,
              child: const TransfersPage(currentRoute: Routes.addTransfer),
            ),
          ),
        );
      case Routes.income:
        return _transactionRoute(const IncomePage());
      case Routes.addIncome:
        return _transactionRoute(const AddIncomePage());
      case Routes.expense:
        return _transactionRoute(const ExpensePage());
      case Routes.addExpense:
        return _transactionRoute(const AddExpensePage());
      case Routes.transactionSearch:
        final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
        final accountBloc = sl<AccountBloc>()..loadIfNeeded();
        final current = transactionBloc.state;
        final transactions = current is TransactionLoaded
            ? current.transactions
            : current is TransactionSyncing
            ? current.transactions
            : const <Transaction>[];
        final searchCubit = TransactionSearchCubit(SavedFilterStore())
          ..initialize(transactions);
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: transactionBloc),
              BlocProvider.value(value: accountBloc),
              BlocProvider.value(value: searchCubit),
            ],
            child: const TransactionSearchPage(),
          ),
        );
      case Routes.moneyLent:
        return _loanRoute(const MoneyLentPage());
      case Routes.moneyBorrowed:
        return _loanRoute(const MoneyBorrowedPage());
      case Routes.loanDetails:
        final loan = settings.arguments;
        if (loan is Loan) {
          return _loanRoute(LoanDetailPage(initialLoan: loan));
        }
        return _invalidArgumentsRoute('Loan details');
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case Routes.settings:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AccountDeletionCubit>(),
            child: const SettingsPage(),
          ),
        );
      case Routes.clearData:
        return _clearDataRoute();
      case Routes.backup:
        return _backupRoute();
      case Routes.currencies:
        return MaterialPageRoute(builder: (_) => const CurrencySettingsPage());

      default:
        return MaterialPageRoute(builder: (_) => const LoginView());
    }
  }

  static MaterialPageRoute<void> _transactionRoute(Widget child) {
    final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
    final accountBloc = sl<AccountBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: transactionBloc),
          BlocProvider.value(value: accountBloc),
        ],
        child: child,
      ),
    );
  }

  static MaterialPageRoute<void> _tourRoute(Widget child) {
    final bloc = sl<TourBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: child),
    );
  }

  static MaterialPageRoute<void> _dashboardRoute() {
    final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
    final loanBloc = sl<LoanBloc>()..loadIfNeeded();
    final accountBloc = sl<AccountBloc>()..loadIfNeeded();
    final budgetBloc = sl<BudgetBloc>()..loadIfNeeded();
    final goalBloc = sl<GoalBloc>()..loadIfNeeded();
    final recurringBloc = sl<RecurringBloc>()..loadIfNeeded();
    final tourBloc = sl<TourBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: transactionBloc),
          BlocProvider.value(value: loanBloc),
          BlocProvider.value(value: accountBloc),
          BlocProvider.value(value: budgetBloc),
          BlocProvider.value(value: goalBloc),
          BlocProvider.value(value: recurringBloc),
          BlocProvider.value(value: tourBloc),
        ],
        child: const DashboardPage(),
      ),
    );
  }

  static MaterialPageRoute<void> _netWorthRoute([
    Widget child = const NetWorthPage(),
  ]) {
    final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
    final loanBloc = sl<LoanBloc>()..loadIfNeeded();
    final accountBloc = sl<AccountBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: transactionBloc),
          BlocProvider.value(value: loanBloc),
          BlocProvider.value(value: accountBloc),
        ],
        child: child,
      ),
    );
  }

  static MaterialPageRoute<void> _loanRoute(Widget child) {
    final bloc = sl<LoanBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: child),
    );
  }

  static MaterialPageRoute<void> _clearDataRoute() {
    final transactionBloc = sl<TransactionBloc>()..loadIfNeeded();
    final loanBloc = sl<LoanBloc>()..loadIfNeeded();
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: transactionBloc),
          BlocProvider.value(value: loanBloc),
          BlocProvider(create: (_) => sl<ClearDataCubit>()),
        ],
        child: const ClearDataPage(),
      ),
    );
  }

  static MaterialPageRoute<void> _backupRoute() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<BackupCubit>(),
        child: const BackupPage(),
      ),
    );
  }

  static MaterialPageRoute<void> _invalidArgumentsRoute(String page) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(page)),
        body: const Center(child: Text('The requested record is unavailable.')),
      ),
    );
  }
}

class _OpenOnFirstFrame extends StatefulWidget {
  const _OpenOnFirstFrame({required this.child, required this.onOpen});
  final Widget child;
  final Future<void> Function(BuildContext) onOpen;

  @override
  State<_OpenOnFirstFrame> createState() => _OpenOnFirstFrameState();
}

class _OpenOnFirstFrameState extends State<_OpenOnFirstFrame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpen(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
