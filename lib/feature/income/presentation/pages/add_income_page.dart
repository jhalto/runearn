import 'package:flutter/material.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/feature/income/presentation/pages/income_page.dart';
import 'package:runearn/feature/transactions/presentation/widgets/add_transaction_sheet.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openForm());
  }

  Future<void> _openForm() async {
    await TransactionSheet.showIncome(context);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.income);
  }

  @override
  Widget build(BuildContext context) => const IncomePage();
}
