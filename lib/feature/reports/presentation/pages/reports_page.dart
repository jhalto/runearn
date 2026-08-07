import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/reports/domain/entities/financial_report.dart';
import 'package:runearn/feature/reports/domain/services/financial_report_calculator.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int months = 6;
  late DateTime endMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool showExpenses = true;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: Routes.reports,
    title: 'Reports & Insights',
    body: SafeArea(
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          final transactions = switch (state) {
            TransactionLoaded value => value.transactions,
            TransactionSyncing value => value.transactions,
            _ => null,
          };
          if (state is TransactionError) {
            return Center(
              child: FilledButton.tonalIcon(
                onPressed: () => context.read<TransactionBloc>().add(
                  const LoadTransactions(),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }
          if (transactions == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final currency = context.watch<CurrencyCubit>().state;
          final accountState = context.watch<AccountBloc>().state;
          final accountCurrencies = accountState is AccountLoaded
              ? {
                  for (final account in accountState.accounts)
                    account.id: account.currencyCode,
                }
              : const <String, String>{};
          final report = FinancialReportCalculator.calculate(
            transactions: transactions,
            endMonth: endMonth,
            monthCount: months,
            amountInBase: (transaction) {
              final code =
                  accountCurrencies[transaction.accountId] ??
                  currency.baseCurrency;
              return currency.supports(code)
                  ? currency.toBase(transaction.amount, code)
                  : 0;
            },
          );
          return _ReportContent(
            report: report,
            currencyCode: currency.baseCurrency,
            months: months,
            endMonth: endMonth,
            showExpenses: showExpenses,
            onMonthsChanged: (value) => setState(() => months = value),
            onMovePeriod: (offset) => setState(
              () => endMonth = DateTime(endMonth.year, endMonth.month + offset),
            ),
            onInsightTypeChanged: (expense) =>
                setState(() => showExpenses = expense),
          );
        },
      ),
    ),
  );
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.report,
    required this.months,
    required this.endMonth,
    required this.showExpenses,
    required this.onMonthsChanged,
    required this.onMovePeriod,
    required this.onInsightTypeChanged,
    required this.currencyCode,
  });
  final FinancialReport report;
  final int months;
  final DateTime endMonth;
  final bool showExpenses;
  final ValueChanged<int> onMonthsChanged;
  final ValueChanged<int> onMovePeriod;
  final ValueChanged<bool> onInsightTypeChanged;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async =>
        context.read<TransactionBloc>().add(const LoadTransactions()),
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportControls(
                    months: months,
                    endMonth: endMonth,
                    onMonthsChanged: onMonthsChanged,
                    onMovePeriod: onMovePeriod,
                  ),
                  const SizedBox(height: 16),
                  _SummaryGrid(report: report, currencyCode: currencyCode),
                  const SizedBox(height: 16),
                  _TrendCard(report: report, currencyCode: currencyCode),
                  const SizedBox(height: 16),
                  if (constraints.maxWidth >= 850)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CategoryCard(
                            report: report,
                            showExpenses: showExpenses,
                            onChanged: onInsightTypeChanged,
                            currencyCode: currencyCode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MonthlyTable(
                            report: report,
                            currencyCode: currencyCode,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _CategoryCard(
                      report: report,
                      showExpenses: showExpenses,
                      onChanged: onInsightTypeChanged,
                      currencyCode: currencyCode,
                    ),
                    const SizedBox(height: 16),
                    _MonthlyTable(report: report, currencyCode: currencyCode),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportControls extends StatelessWidget {
  const _ReportControls({
    required this.months,
    required this.endMonth,
    required this.onMonthsChanged,
    required this.onMovePeriod,
  });
  final int months;
  final DateTime endMonth;
  final ValueChanged<int> onMonthsChanged;
  final ValueChanged<int> onMovePeriod;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 10,
    children: [
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 3, label: Text('3M')),
          ButtonSegment(value: 6, label: Text('6M')),
          ButtonSegment(value: 12, label: Text('1Y')),
        ],
        selected: {months},
        onSelectionChanged: (selection) => onMonthsChanged(selection.first),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous period',
            onPressed: () => onMovePeriod(-months),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${DateFormat('MMM yyyy').format(DateTime(endMonth.year, endMonth.month - months + 1))}'
            ' – ${DateFormat('MMM yyyy').format(endMonth)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Next period',
            onPressed: () => onMovePeriod(months),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    ],
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report, required this.currencyCode});
  final FinancialReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 500
          ? 2
          : 1;
      final cards = [
        _SummaryCardData(
          'Income',
          _money(report.totalIncome, currencyCode),
          Icons.trending_up_rounded,
          Colors.green,
        ),
        _SummaryCardData(
          'Expenses',
          _money(report.totalExpense, currencyCode),
          Icons.trending_down_rounded,
          Theme.of(context).colorScheme.error,
        ),
        _SummaryCardData(
          'Net cash flow',
          _money(report.netCashFlow, currencyCode),
          Icons.account_balance_wallet_outlined,
          report.netCashFlow < 0
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
        _SummaryCardData(
          'Savings rate',
          '${report.savingsRate.toStringAsFixed(1)}%',
          Icons.savings_outlined,
          report.savingsRate < 0 ? Colors.orange : Colors.teal,
        ),
      ];
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 125,
        ),
        itemCount: cards.length,
        itemBuilder: (_, index) => _SummaryCard(data: cards[index]),
      );
    },
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});
  final _SummaryCardData data;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: data.color.withValues(alpha: .12),
            foregroundColor: data.color,
            child: Icon(data.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.report, required this.currencyCode});
  final FinancialReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final maximum = report.periods.fold<double>(
      0,
      (value, period) => [
        value,
        period.income,
        period.expense,
      ].reduce((a, b) => a > b ? a : b),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Income vs expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _Legend(color: Colors.green, label: 'Income'),
                const SizedBox(width: 12),
                _Legend(
                  color: Theme.of(context).colorScheme.error,
                  label: 'Expense',
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 210,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final period in report.periods)
                    Expanded(
                      child: _MonthBars(
                        period: period,
                        maximum: maximum,
                        currencyCode: currencyCode,
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
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({
    required this.period,
    required this.maximum,
    required this.currencyCode,
  });
  final ReportPeriod period;
  final double maximum;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 170.0;
    double height(double value) => maximum == 0
        ? 2
        : (value / maximum * chartHeight).clamp(2, chartHeight);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Tooltip(
                    message: 'Income ${_money(period.income, currencyCode)}',
                    child: Container(
                      width: 18,
                      height: height(period.income),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Tooltip(
                    message: 'Expense ${_money(period.expense, currencyCode)}',
                    child: Container(
                      width: 18,
                      height: height(period.expense),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            DateFormat('MMM').format(period.month),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.report,
    required this.showExpenses,
    required this.onChanged,
    required this.currencyCode,
  });
  final FinancialReport report;
  final bool showExpenses;
  final ValueChanged<bool> onChanged;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final categories = showExpenses
        ? report.expenseCategories
        : report.incomeCategories;
    final total = categories.fold<double>(
      0,
      (value, category) => value + category.amount,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Category insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('Expense')),
                    ButtonSegment(value: false, label: Text('Income')),
                  ],
                  selected: {showExpenses},
                  onSelectionChanged: (value) => onChanged(value.first),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No category data for this period.'),
              )
            else
              for (final category in categories.take(8)) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _money(category.amount, currencyCode),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : category.amount / total,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(7),
                  color: showExpenses
                      ? Theme.of(context).colorScheme.error
                      : Colors.green,
                ),
                const SizedBox(height: 5),
                Text(
                  '${total == 0 ? '0.0' : (category.amount / total * 100).toStringAsFixed(1)}%'
                  ' • ${category.transactionCount} transactions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({required this.report, required this.currencyCode});
  final FinancialReport report;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monthly cash flow',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const Divider(height: 1),
        for (var index = report.periods.length - 1; index >= 0; index--) ...[
          ListTile(
            title: Text(
              DateFormat('MMMM yyyy').format(report.periods[index].month),
            ),
            subtitle: Text(
              'Income ${_money(report.periods[index].income, currencyCode)}'
              ' • Expense ${_money(report.periods[index].expense, currencyCode)}',
            ),
            trailing: Text(
              _money(report.periods[index].cashFlow, currencyCode),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: report.periods[index].cashFlow < 0
                    ? Theme.of(context).colorScheme.error
                    : Colors.green,
              ),
            ),
          ),
          if (index > 0) const Divider(height: 1, indent: 16),
        ],
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _SummaryCardData {
  const _SummaryCardData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _money(double value, String currencyCode) =>
    MoneyFormatter.format(value, currencyCode);
