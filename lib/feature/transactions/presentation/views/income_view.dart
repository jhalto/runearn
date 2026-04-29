import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/views/transaction_detail_view.dart';

class IncomeView extends StatelessWidget {
  const IncomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Income")),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoaded) {
            final incomes = state.transactions
                .where((t) => t.type == TransactionType.income)
                .toList();

            if (incomes.isEmpty) {
              return const Center(child: Text("No income found"));
            }

            return ListView.builder(
              itemCount: incomes.length,
              itemBuilder: (context, index) {
                final t = incomes[index];

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionDetailView(transaction: t),
                      ),
                    );
                  },
                  leading: const Icon(Icons.add, color: Colors.green),
                  title: Text(t.description),
                  subtitle: Text(t.category.toString().split('.').last),
                  trailing: Text(
                    "+৳${t.amount}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
