import 'package:flutter/material.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/presentation/pages/loan_list_page.dart';

class MoneyBorrowedPage extends StatelessWidget {
  const MoneyBorrowedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoanListPage(direction: LoanDirection.borrowed);
  }
}
