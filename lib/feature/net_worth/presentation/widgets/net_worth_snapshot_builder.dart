import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/net_worth/domain/entities/net_worth_snapshot.dart';
import 'package:runearn/feature/net_worth/domain/services/net_worth_calculator.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

class NetWorthSnapshotBuilder extends StatelessWidget {
  const NetWorthSnapshotBuilder({required this.builder, super.key});
  final Widget Function(BuildContext context, NetWorthSnapshot snapshot)
  builder;

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountBloc, AccountState>(
    builder: (context, accountState) => BlocBuilder<LoanBloc, LoanState>(
      builder: (context, loanState) =>
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, transactionState) {
              if (accountState is AccountFailure ||
                  loanState is LoanFailure ||
                  transactionState is TransactionError) {
                return const Center(
                  child: Text('Unable to calculate your financial position.'),
                );
              }
              if (accountState is! AccountLoaded || loanState is! LoanLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              final transactions = switch (transactionState) {
                TransactionLoaded state => state.transactions,
                TransactionSyncing state => state.transactions,
                _ => null,
              };
              if (transactions == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final currency = context.watch<CurrencyCubit>().state;
              return builder(
                context,
                NetWorthCalculator.calculate(
                  accounts: accountState.accounts,
                  transactions: transactions,
                  transfers: accountState.transfers,
                  loans: loanState.loans,
                  payments: loanState.payments,
                  toBase: (amount, code) => currency.supports(code)
                      ? currency.toBase(amount, code)
                      : 0,
                  baseCurrency: currency.baseCurrency,
                ),
              );
            },
          ),
    ),
  );
}
