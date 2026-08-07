import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:runearn/config/theme/theme_cubit.dart';
import 'package:runearn/feature/accounts/data/datasources/account_local_data_source.dart';
import 'package:runearn/feature/accounts/data/datasources/account_remote_data_source.dart';
import 'package:runearn/feature/accounts/data/repositories/account_repository_impl.dart';
import 'package:runearn/feature/accounts/domain/repositories/account_repository.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/core/notifications/finance_notification_service.dart';
import 'package:runearn/feature/currency/data/currency_preferences.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

// Auth
import 'package:runearn/feature/auth/data/data_sources/remote/auth_remote_datasource.dart';
import 'package:runearn/feature/auth/data/repository_impl/auth_remote_datasource_impl.dart';
import 'package:runearn/feature/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:runearn/feature/auth/domain/repositories/auth_repository.dart';
import 'package:runearn/feature/auth/domain/usecases/google_login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/guest_login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/login_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/logout_use_case.dart';
import 'package:runearn/feature/auth/domain/usecases/register_use_case.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/profile/data/datasources/remote/profile_remote_data_source.dart';
import 'package:runearn/feature/profile/data/repositories_impl/profile_repository_impl.dart';
import 'package:runearn/feature/profile/domain/repositories/profile_repository.dart';
import 'package:runearn/feature/profile/domain/usecases/create_or_update_user_profile_use_case.dart';
import 'package:runearn/feature/profile/domain/usecases/get_current_user_use_case.dart';
import 'package:runearn/feature/profile/domain/usecases/update_user_profile_use_case.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:runearn/feature/profile/data/services/account_deletion_service.dart';
import 'package:runearn/feature/profile/data/services/local_account_data_purger.dart';
import 'package:runearn/feature/profile/domain/repositories/account_deletion_repository.dart';
import 'package:runearn/feature/profile/presentation/cubit/account_deletion_cubit.dart';
import 'package:runearn/feature/loans/data/datasources/local/loan_local_data_source.dart';
import 'package:runearn/feature/loans/data/datasources/remote/loan_remote_data_source.dart';
import 'package:runearn/feature/loans/data/repositories/loan_repository_impl.dart';
import 'package:runearn/feature/loans/domain/repositories/loan_repository.dart';
import 'package:runearn/feature/loans/domain/usecases/add_loan.dart';
import 'package:runearn/feature/loans/domain/usecases/clear_loans.dart';
import 'package:runearn/feature/loans/domain/usecases/delete_loan.dart';
import 'package:runearn/feature/loans/domain/usecases/get_loans.dart';
import 'package:runearn/feature/loans/domain/usecases/sync_pending_loans.dart';
import 'package:runearn/feature/loans/domain/usecases/update_loan.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/settings/presentation/cubit/clear_data_cubit.dart';
import 'package:runearn/feature/budgets/data/datasources/budget_local_data_source.dart';
import 'package:runearn/feature/budgets/data/datasources/budget_remote_data_source.dart';
import 'package:runearn/feature/budgets/data/repositories/budget_repository_impl.dart';
import 'package:runearn/feature/budgets/domain/repositories/budget_repository.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/goals/data/datasources/goal_local_data_source.dart';
import 'package:runearn/feature/goals/data/datasources/goal_remote_data_source.dart';
import 'package:runearn/feature/goals/data/repositories/goal_repository_impl.dart';
import 'package:runearn/feature/goals/domain/repositories/goal_repository.dart';
import 'package:runearn/feature/goals/domain/services/goal_funding_service.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/recurring/data/datasources/recurring_local_data_source.dart';
import 'package:runearn/feature/recurring/data/datasources/recurring_remote_data_source.dart';
import 'package:runearn/feature/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:runearn/feature/recurring/domain/repositories/recurring_repository.dart';
import 'package:runearn/feature/recurring/domain/services/recurring_recording_service.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/backup/domain/services/finance_backup_service.dart';
import 'package:runearn/feature/backup/presentation/cubit/backup_cubit.dart';
import 'package:runearn/feature/tours/data/datasources/tour_local_data_source.dart';
import 'package:runearn/feature/tours/data/datasources/tour_remote_data_source.dart';
import 'package:runearn/feature/tours/data/repositories/tour_repository_impl.dart';
import 'package:runearn/feature/tours/domain/repositories/tour_repository.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';

// Transactions
import 'package:runearn/feature/transactions/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:runearn/feature/transactions/data/repositories_impl/transaction_repository_impl.dart';
import 'package:runearn/feature/transactions/domain/repositories/transaction_repository.dart';
import 'package:runearn/feature/transactions/domain/usecases/detete_transaction_use_case.dart';
import 'package:runearn/feature/transactions/domain/usecases/clear_transactions_use_case.dart';
import 'package:runearn/feature/transactions/domain/usecases/sync_pending_trasaction_use_case.dart';
import 'package:runearn/feature/transactions/domain/usecases/update_transaction_use_case.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> dependencyInjection() async {
  // External
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  // NetworkInfo
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfo(sl<Connectivity>()));
  sl.registerLazySingleton(FinanceNotificationService.new);
  sl.registerLazySingleton(CurrencyPreferences.new);
  sl.registerLazySingleton(() => CurrencyCubit(sl())..load());

  // Theme
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());

  // Auth Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl<FirebaseAuth>()),
  );

  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );

  // Auth Use Cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<GoogleLoginUseCase>(
    () => GoogleLoginUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<GuestLoginUseCase>(
    () => GuestLoginUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );
  // Auth Bloc
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      createOrUpdateUserProfileUseCase: sl<CreateOrUpdateUserProfileUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      loginUseCase: sl<LoginUseCase>(),
      googleLoginUseCase: sl<GoogleLoginUseCase>(),
      guestLoginUseCase: sl<GuestLoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
    ),
  );
  // Profile remote data source
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      firebaseAuth: FirebaseAuth.instance,
    ),
  );

  // Profile repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  // Profile use cases
  sl.registerLazySingleton(() => GetCurrentUserProfileUseCase(sl()));

  sl.registerLazySingleton(() => CreateOrUpdateUserProfileUseCase(sl()));

  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));

  // Profile bloc
  sl.registerFactory(
    () => ProfileBloc(
      getCurrentUserProfileUseCase: sl(),
      createOrUpdateUserProfileUseCase: sl(),
      updateUserProfileUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => LocalAccountDataPurger(sl()));
  sl.registerLazySingleton<AccountDeletionRepository>(
    () =>
        AccountDeletionService(auth: sl(), firestore: sl(), localPurger: sl()),
  );
  sl.registerFactory(() => AccountDeletionCubit(sl()));

  // Loans
  sl.registerLazySingleton(AccountLocalDataSource.new);
  sl.registerLazySingleton(
    () => AccountRemoteDataSource(sl<FirebaseFirestore>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(
      local: sl(),
      remote: sl(),
      auth: sl(),
      network: sl(),
    ),
  );
  sl.registerLazySingleton(() => AccountBloc(sl<AccountRepository>()));

  // Budgets
  sl.registerLazySingleton(BudgetLocalDataSource.new);
  sl.registerLazySingleton(
    () => BudgetRemoteDataSource(sl<FirebaseFirestore>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      local: sl(),
      remote: sl(),
      auth: sl(),
      network: sl(),
    ),
  );
  sl.registerLazySingleton(() => BudgetBloc(sl<BudgetRepository>()));

  // Savings goals
  sl.registerLazySingleton(GoalLocalDataSource.new);
  sl.registerLazySingleton(
    () => GoalRemoteDataSource(sl<FirebaseFirestore>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(
      local: sl(),
      remote: sl(),
      auth: sl(),
      network: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GoalFundingService(
      goals: sl<GoalRepository>(),
      accounts: sl<AccountRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => GoalBloc(sl<GoalRepository>(), sl<GoalFundingService>()),
  );

  // Recurring transactions and reminders
  sl.registerLazySingleton(RecurringLocalDataSource.new);
  sl.registerLazySingleton(
    () =>
        RecurringRemoteDataSource(sl<FirebaseFirestore>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<RecurringRepository>(
    () => RecurringRepositoryImpl(
      local: sl(),
      remote: sl(),
      auth: sl(),
      network: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => RecurringRecordingService(
      recurring: sl<RecurringRepository>(),
      transactions: sl<TransactionRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => RecurringBloc(
      sl<RecurringRepository>(),
      sl<RecurringRecordingService>(),
    ),
  );

  // Tour finance
  sl.registerLazySingleton(TourLocalDataSource.new);
  sl.registerLazySingleton(
    () => TourRemoteDataSource(sl<FirebaseFirestore>(), sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<TourRepository>(
    () => TourRepositoryImpl(
      local: sl(),
      remote: sl(),
      auth: sl(),
      network: sl(),
    ),
  );
  sl.registerLazySingleton(() => TourBloc(sl<TourRepository>()));

  // Backup and export
  sl.registerLazySingleton(
    () => FinanceBackupService(
      accounts: sl(),
      transactions: sl(),
      loans: sl(),
      budgets: sl(),
      goals: sl(),
      recurring: sl(),
      tours: sl(),
      currencyPreferences: sl(),
    ),
  );
  sl.registerFactory(() => BackupCubit(sl<FinanceBackupService>()));

  // Loans
  sl.registerLazySingleton<LoanLocalDataSource>(LoanLocalDataSourceImpl.new);
  sl.registerLazySingleton<LoanRemoteDataSource>(
    () => LoanRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<LoanRepository>(
    () => LoanRepositoryImpl(
      localDataSource: sl<LoanLocalDataSource>(),
      remoteDataSource: sl<LoanRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(() => GetLoans(sl<LoanRepository>()));
  sl.registerLazySingleton(() => AddLoan(sl<LoanRepository>()));
  sl.registerLazySingleton(() => UpdateLoan(sl<LoanRepository>()));
  sl.registerLazySingleton(() => DeleteLoan(sl<LoanRepository>()));
  sl.registerLazySingleton(() => ClearLoans(sl<LoanRepository>()));
  sl.registerLazySingleton(() => SyncPendingLoans(sl<LoanRepository>()));
  sl.registerLazySingleton(
    () => LoanBloc(
      getLoans: sl<GetLoans>(),
      addLoan: sl<AddLoan>(),
      updateLoan: sl<UpdateLoan>(),
      deleteLoan: sl<DeleteLoan>(),
      syncPendingLoans: sl<SyncPendingLoans>(),
      repository: sl<LoanRepository>(),
    ),
  );

  // Transaction Remote Data Source
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSource(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Transaction Repository
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: sl<TransactionRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Transaction Use Cases

  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));

  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(
    () => ClearTransactionsUseCase(sl<TransactionRepository>()),
  );
  sl.registerLazySingleton<SyncPendingTransactionsUseCase>(
    () => SyncPendingTransactionsUseCase(sl<TransactionRepository>()),
  );

  // Transaction Bloc
  sl.registerLazySingleton(
    () => TransactionBloc(
      sl(),
      updateTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
      syncPendingTransactionsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ClearDataCubit(
      clearLoans: sl<ClearLoans>(),
      clearTransactions: sl<ClearTransactionsUseCase>(),
    ),
  );
}
