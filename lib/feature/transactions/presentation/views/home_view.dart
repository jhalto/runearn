import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/theme/theme_cubit.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/usecases/monthly_analytics.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("RunEarn"),

        actions: [
          IconButton(
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoaded) {
            final transactions = state.transactions;

            double balance = 0;

            for (var t in transactions) {
              if (t.type == TransactionType.income) {
                balance += t.amount;
              } else {
                balance -= t.amount;
              }
            }

            // ✅ STEP 1: CURRENT MONTH KEY
            final now = DateTime.now();
            final currentMonthKey =
                "${now.year}-${now.month.toString().padLeft(2, '0')}";

            // ✅ STEP 2: BUILD MONTHLY DATA
            final monthly = MonthlyAnalyticsBuilder.build(transactions);

            final currentMonth = monthly.firstWhere(
              (m) => m.month == currentMonthKey,
              orElse: () => MonthlyAnalytics(
                month: currentMonthKey,
                income: 0,
                expense: 0,
              ),
            );

            return Column(
              children: [
                // 💰 BALANCE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.green,
                  child: Text(
                    "Balance: ৳$balance",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 📅 MONTHLY ANALYTICS LIST
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: monthly.length,
                    itemBuilder: (context, index) {
                      final m = monthly[index];

                      final theme = Theme.of(context);

                      return Container(
                        width: double.maxFinite,
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "📅 ${m.month}",
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text("Income: ৳${m.income}"),
                            Text("Expense: ৳${m.expense}"),
                            const SizedBox(height: 6),
                            Text(
                              "Balance: ৳${m.balance}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.balance >= 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 📋 LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];

                      return ListTile(
                        title: Text(t.description),
                        subtitle: Text(t.category.name),
                        trailing: Text(
                          "${t.type == TransactionType.income ? '+' : '-'}${t.amount}",
                          style: TextStyle(
                            color: t.type == TransactionType.income
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddTransactionSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
