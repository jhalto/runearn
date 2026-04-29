import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/theme/theme_cubit.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/usecases/transaction_analytics.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedIndex = 0; // 0 = monthly, 1 = weekly, 2 = yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RunEarn"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            icon: const Icon(Icons.dark_mode),
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoaded) {
            final analytics = state.analytics;
            final theme = Theme.of(context);

            final data = selectedIndex == 0
                ? analytics.monthly()
                : selectedIndex == 1
                    ? analytics.weekly()
                    : analytics.yearly();

            return Column(
              children: [
                // 💳 BALANCE CARD
                _buildBalanceCard(theme, analytics),

                const SizedBox(height: 10),

                // 💰 INCOME / EXPENSE
                _buildSummaryRow(theme, analytics),

                const SizedBox(height: 10),

                // 🔘 TOGGLE (MONTH / WEEK / YEAR)
                _buildToggle(),

                const SizedBox(height: 10),

                // 📊 ANALYTICS CARDS
                _buildAnalyticsList(data, theme),

                // 📋 TRANSACTIONS
                Expanded(
                  child: _buildTransactionList(state.transactions, theme),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ========================= UI PARTS =========================

  Widget _buildBalanceCard(ThemeData theme, analytics) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            "৳${analytics.balance.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            "Income",
            analytics.totalIncome,
            Colors.green,
            Icons.arrow_downward,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            "Expense",
            analytics.totalExpense,
            Colors.red,
            Icons.arrow_upward,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
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
                  "৳${amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["Monthly", "Weekly", "Yearly"].asMap().entries.map((e) {
        final i = e.key;
        final text = e.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ChoiceChip(
            label: Text(text),
            selected: selectedIndex == i,
            onSelected: (_) => setState(() => selectedIndex = i),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsList(List data, ThemeData theme) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final m = data[index];

          return Container(
            width: 180,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.label, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text("Income: ৳${m.income.toStringAsFixed(0)}"),
                Text("Expense: ৳${m.expense.toStringAsFixed(0)}"),
                Text(
                  "৳${m.balance.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: m.balance >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List transactions, ThemeData theme) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];

        final isIncome = t.type == TransactionType.income;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
              child: Icon(
                isIncome ? Icons.add : Icons.remove,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(t.description),
            subtitle: Text(t.category.toString().split('.').last),
            trailing: Text(
              "${isIncome ? '+' : '-'}৳${t.amount}",
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}