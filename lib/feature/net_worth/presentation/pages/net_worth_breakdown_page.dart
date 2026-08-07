import 'package:flutter/material.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/net_worth/domain/entities/net_worth_snapshot.dart';
import 'package:runearn/feature/net_worth/presentation/widgets/net_worth_snapshot_builder.dart';

class NetWorthBreakdownPage extends StatelessWidget {
  const NetWorthBreakdownPage({required this.classification, super.key});
  final AccountClassification classification;

  bool get isAssets => classification == AccountClassification.asset;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: isAssets ? Routes.netWorthAssets : Routes.netWorthLiabilities,
    title: isAssets ? 'Assets' : 'Liabilities',
    body: SafeArea(
      child: NetWorthSnapshotBuilder(
        builder: (context, snapshot) {
          final items = isAssets ? snapshot.assets : snapshot.liabilities;
          final total = isAssets
              ? snapshot.totalAssets
              : snapshot.totalLiabilities;
          final color = isAssets ? Colors.green : Colors.orange;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BreakdownHero(
                        title: isAssets ? 'Total assets' : 'Total liabilities',
                        value: total,
                        color: color,
                        subtitle: isAssets
                            ? 'What you own and money owed to you'
                            : 'What you currently owe',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isAssets ? 'Asset accounts' : 'Liability accounts',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        _EmptyBreakdown(isAssets: isAssets)
                      else
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < items.length;
                                index++
                              ) ...[
                                _ItemTile(
                                  item: items[index],
                                  total: total,
                                  color: color,
                                ),
                                if (index < items.length - 1)
                                  const Divider(height: 1, indent: 72),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class NetWorthItemDetailPage extends StatelessWidget {
  const NetWorthItemDetailPage({required this.item, super.key});
  final NetWorthItem item;

  @override
  Widget build(BuildContext context) {
    final asset = item.isAsset;
    final color = asset ? Colors.green : Colors.orange;
    final loan = item.id.startsWith('loan:');
    return AppPageScaffold(
      currentRoute: asset ? Routes.netWorthAssets : Routes.netWorthLiabilities,
      title: asset ? 'Asset Details' : 'Liability Details',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: color.withValues(alpha: .14),
                            foregroundColor: color,
                            child: Icon(_icon(item.type), size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.type.label} • ${asset ? 'Asset' : 'Liability'}',
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _money(item.value),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(asset ? 'Current asset value' : 'Amount owed'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Classification',
                          value: asset ? 'Asset' : 'Liability',
                        ),
                        const Divider(height: 1),
                        _DetailRow(label: 'Type', value: item.type.label),
                        const Divider(height: 1),
                        _DetailRow(
                          label: 'Source',
                          value: loan ? 'Loan records' : 'Accounts',
                        ),
                        const Divider(height: 1),
                        _DetailRow(
                          label: 'Net worth effect',
                          value: asset
                              ? 'Increases net worth'
                              : 'Reduces net worth',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loan
                                  ? 'This value is the outstanding loan amount '
                                        'after recorded repayments.'
                                  : 'This value includes the opening balance, '
                                        'linked transactions, and transfers.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownHero extends StatelessWidget {
  const _BreakdownHero({
    required this.title,
    required this.value,
    required this.color,
    required this.subtitle,
  });
  final String title;
  final double value;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 7),
        Text(
          _money(value),
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(subtitle, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.total,
    required this.color,
  });
  final NetWorthItem item;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : item.value / total * 100;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Icon(_icon(item.type), size: 20),
      ),
      title: Text(item.name),
      subtitle: Text('${item.type.label} • ${percentage.toStringAsFixed(1)}%'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _money(item.value),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () =>
          Navigator.pushNamed(context, Routes.netWorthDetails, arguments: item),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _EmptyBreakdown extends StatelessWidget {
  const _EmptyBreakdown({required this.isAssets});
  final bool isAssets;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        isAssets
            ? 'No asset accounts or outstanding loans given.'
            : 'No liability accounts or outstanding loans taken.',
        textAlign: TextAlign.center,
      ),
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
