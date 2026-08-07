import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/net_worth/domain/entities/net_worth_snapshot.dart';
import 'package:runearn/feature/net_worth/domain/services/net_worth_calculator.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';

class NetWorthPage extends StatelessWidget {
  const NetWorthPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: Routes.netWorth,
    title: 'Net Worth',
    body: SafeArea(
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, accountState) => BlocBuilder<LoanBloc, LoanState>(
          builder: (context, loanState) =>
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, transactionState) => _NetWorthBody(
                  accountState: accountState,
                  loanState: loanState,
                  transactionState: transactionState,
                ),
              ),
        ),
      ),
    ),
  );
}

class _NetWorthBody extends StatelessWidget {
  const _NetWorthBody({
    required this.accountState,
    required this.loanState,
    required this.transactionState,
  });

  final AccountState accountState;
  final LoanState loanState;
  final TransactionState transactionState;

  @override
  Widget build(BuildContext context) {
    final accounts = accountState is AccountLoaded
        ? accountState as AccountLoaded
        : null;
    final loans = loanState is LoanLoaded ? loanState as LoanLoaded : null;
    final transactions = switch (transactionState) {
      TransactionLoaded state => state.transactions,
      TransactionSyncing state => state.transactions,
      _ => null,
    };

    if (accountState is AccountFailure ||
        loanState is LoanFailure ||
        transactionState is TransactionError) {
      return _ErrorState(onRetry: () => _refresh(context));
    }
    if (accounts == null || loans == null || transactions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currency = context.watch<CurrencyCubit>().state;
    final snapshot = NetWorthCalculator.calculate(
      accounts: accounts.accounts,
      transactions: transactions,
      transfers: accounts.transfers,
      loans: loans.loans,
      payments: loans.payments,
      toBase: (amount, code) =>
          currency.supports(code) ? currency.toBase(amount, code) : 0,
      baseCurrency: currency.baseCurrency,
    );
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NetWorthHero(snapshot: snapshot),
                      const SizedBox(height: 16),
                      _CompositionCard(snapshot: snapshot),
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BreakdownCard(
                                title: 'Assets',
                                total: snapshot.totalAssets,
                                items: snapshot.assets,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _BreakdownCard(
                                title: 'Liabilities',
                                total: snapshot.totalLiabilities,
                                items: snapshot.liabilities,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _BreakdownCard(
                          title: 'Assets',
                          total: snapshot.totalAssets,
                          items: snapshot.assets,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _BreakdownCard(
                          title: 'Liabilities',
                          total: snapshot.totalLiabilities,
                          items: snapshot.liabilities,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    context.read<AccountBloc>().add(const LoadAccounts());
    context.read<LoanBloc>().add(const LoadLoans());
    context.read<TransactionBloc>().add(const LoadTransactions());
  }
}

class _NetWorthHero extends StatelessWidget {
  const _NetWorthHero({required this.snapshot});
  final NetWorthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final negative = snapshot.netWorth < 0;
    final accent = negative ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: .72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'YOUR NET WORTH',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(snapshot.netWorth),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assets minus liabilities',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Assets',
                  value: snapshot.totalAssets,
                  icon: Icons.trending_up_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.netWorthAssets),
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white24),
              Expanded(
                child: _HeroMetric(
                  label: 'Liabilities',
                  value: snapshot.totalLiabilities,
                  icon: Icons.trending_down_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.netWorthLiabilities),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final double value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                Text(
                  _money(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.snapshot});
  final NetWorthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final combined = snapshot.totalAssets + snapshot.totalLiabilities;
    final assetShare = combined == 0 ? .5 : snapshot.totalAssets / combined;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Financial position',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (assetShare * 1000).round().clamp(1, 999),
                      child: Container(color: Colors.green),
                    ),
                    Expanded(
                      flex: ((1 - assetShare) * 1000).round().clamp(1, 999),
                      child: Container(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              combined == 0
                  ? 'Add an asset or liability account to begin tracking.'
                  : snapshot.netWorth >= 0
                  ? 'Your assets currently cover your liabilities.'
                  : 'Your liabilities currently exceed your assets.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.total,
    required this.items,
    required this.color,
  });
  final String title;
  final double total;
  final List<NetWorthItem> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  title == 'Assets'
                      ? Icons.savings_outlined
                      : Icons.credit_card_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _money(total),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              IconButton(
                tooltip: 'View all $title',
                onPressed: () => Navigator.pushNamed(
                  context,
                  title == 'Assets'
                      ? Routes.netWorthAssets
                      : Routes.netWorthLiabilities,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No ${title.toLowerCase()} yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (var index = 0; index < items.length; index++) ...[
            _BreakdownTile(item: items[index], total: total, color: color),
            if (index < items.length - 1) const Divider(height: 1, indent: 68),
          ],
      ],
    ),
  );
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.item,
    required this.total,
    required this.color,
  });
  final NetWorthItem item;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (item.value / total * 100);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Icon(_icon(item.type), size: 20),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.type.label} • ${percentage.toStringAsFixed(1)}%'),
      trailing: Text(
        _money(item.value),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onTap: () =>
          Navigator.pushNamed(context, Routes.netWorthDetails, arguments: item),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.tonalIcon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Try again'),
    ),
  );
}

IconData _icon(FinanceAccountType type) => switch (type) {
  FinanceAccountType.cash => Icons.payments_outlined,
  FinanceAccountType.bank => Icons.account_balance_outlined,
  FinanceAccountType.mobileWallet => Icons.phone_android_rounded,
  FinanceAccountType.savings => Icons.savings_outlined,
  FinanceAccountType.investment => Icons.show_chart_rounded,
  FinanceAccountType.otherAsset => Icons.inventory_2_outlined,
  FinanceAccountType.loanGiven => Icons.call_made_rounded,
  FinanceAccountType.loanTaken => Icons.call_received_rounded,
  FinanceAccountType.creditCard => Icons.credit_card_rounded,
  FinanceAccountType.lineOfCredit => Icons.credit_score_outlined,
  FinanceAccountType.mortgage => Icons.home_outlined,
  FinanceAccountType.otherLiability => Icons.request_quote_outlined,
  FinanceAccountType.income => Icons.trending_up_rounded,
  FinanceAccountType.expense => Icons.trending_down_rounded,
  FinanceAccountType.equity => Icons.balance_rounded,
};

String _money(double value) => MoneyFormatter.formatBase(value);
