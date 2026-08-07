import 'package:flutter/material.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/feature/expenses/presentation/pages/expense_page.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openForm());
  }

  Future<void> _openForm() async {
    await TransactionSheet.showExpense(context);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.expense);
  }

  @override
  Widget build(BuildContext context) => const ExpensePage();
}
