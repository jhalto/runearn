import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/theme/app_theme.dart';
import 'package:runearn/core/theme/theme_cubit.dart';
import 'package:runearn/feature/transactions/data/datasources/transaction_db.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/views/home_view.dart';
import 'feature/transactions/data/repositories_impl/transaction_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 REQUIRED FOR WINDOWS / LINUX / MAC
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
   await TransactionDB.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) =>
              TransactionBloc(TransactionRepositoryImpl())
                ..add(LoadTransactions()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RunEarn',
          darkTheme: AppTheme.dark,
          theme: AppTheme.light,
          themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,

          home: HomeView(),
        );
      },
    );
  }
}
