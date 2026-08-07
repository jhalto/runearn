import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_event.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';

/// Clears all in-memory, user-scoped presentation state.
///
/// Local database records are not deleted. Repositories remain responsible for
/// reading only records belonging to the newly authenticated Firebase user.
void resetFinanceSessionCache(ProfileBloc profileBloc) {
  sl<AccountBloc>().resetForLogout();
  sl<TransactionBloc>().resetForLogout();
  sl<LoanBloc>().resetForLogout();
  sl<BudgetBloc>().resetForLogout();
  sl<GoalBloc>().resetForLogout();
  sl<RecurringBloc>().resetForLogout();
  sl<TourBloc>().resetForLogout();
  profileBloc.add(ResetProfileEvent());
}
