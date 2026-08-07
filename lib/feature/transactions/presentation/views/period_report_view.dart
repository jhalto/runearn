import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/views/transaction_detail_view.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class PeriodReportView extends StatefulWidget {
  final ReportPeriod period;

  const PeriodReportView({super.key, required this.period});

  @override
  State<PeriodReportView> createState() => _PeriodReportViewState();
}

class _PeriodReportViewState extends State<PeriodReportView> {
  String _getAppBarTitle(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'Daily Report';

      case ReportPeriod.weekly:
        return 'Weekly Report';

      case ReportPeriod.monthly:
        return 'Monthly Report';

      case ReportPeriod.yearly:
        return 'Yearly Report';
    }
  }

  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(widget.period, selectedDate);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(widget.period),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoaded) {
            final analytics = state.analytics;

            final List rawData = switch (widget.period) {
              ReportPeriod.daily => analytics.daily(),
              ReportPeriod.weekly => analytics.weekly(),
              ReportPeriod.monthly => analytics.monthly(),
              ReportPeriod.yearly => analytics.yearly(),
            };

            final List data = _filterDataBySelectedDate(rawData);

            final totalIncome = data.fold<double>(
              0,
              (sum, item) => sum + item.income,
            );

            final totalExpense = data.fold<double>(
              0,
              (sum, item) => sum + item.expense,
            );

            final balance = totalIncome - totalExpense;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ReportHeader(
                    config: config,
                    period: widget.period,
                    selectedDate: selectedDate,
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    balance: balance,
                    onPickDate: _pickDate,
                    onClearDate: () {
                      setState(() {
                        selectedDate = null;
                      });
                    },
                  ),
                ),

                if (data.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyReportState(
                      config: config,
                      hasSelectedDate: selectedDate != null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    sliver: SliverList.separated(
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final label = _formatLabel(item.label, widget.period);

                        final range = _getDateRangeFromLabel(
                          item.label,
                          widget.period,
                        );

                        final filteredTransactions = _filterTransactionsByRange(
                          state.transactions,
                          range.start,
                          range.end,
                        );

                        return _ReportTile(
                          title: label.title,
                          subtitle: label.subtitle,
                          income: item.income,
                          expense: item.expense,
                          config: config,
                          transactions: filteredTransactions,
                        );
                      },
                    ),
                  ),
              ],
            );
          }

          if (state is TransactionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return const _ReportLoadingState();
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: _getDatePickerTitle(widget.period),
    );

    if (!mounted || pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String _getDatePickerTitle(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return 'Choose a day';
      case ReportPeriod.weekly:
        return 'Choose any date from the week';
      case ReportPeriod.monthly:
        return 'Choose any date from the month';
      case ReportPeriod.yearly:
        return 'Choose any date from the year';
    }
  }

  List _filterDataBySelectedDate(List rawData) {
    final date = selectedDate ?? DateTime.now();

    final keys = _getSelectedDateKeys(date, widget.period);

    return rawData.where((item) {
      return keys.contains(item.label);
    }).toList();
  }

  Set<String> _getSelectedDateKeys(DateTime date, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        return {DateFormat('yyyy-MM-dd').format(date)};

      case ReportPeriod.weekly:
        final weekInfo = _getIsoWeekInfo(date);

        return {
          '${weekInfo.year}-W${weekInfo.week}',
          '${weekInfo.year}-W${weekInfo.week.toString().padLeft(2, '0')}',
        };

      case ReportPeriod.monthly:
        return {DateFormat('yyyy-MM').format(date)};

      case ReportPeriod.yearly:
        return {date.year.toString()};
    }
  }

  _IsoWeekInfo _getIsoWeekInfo(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final weekYear = thursday.year;

    final firstThursday = DateTime(weekYear, 1, 4);
    final firstWeekThursday = firstThursday.add(
      Duration(days: 4 - firstThursday.weekday),
    );

    final week = 1 + (thursday.difference(firstWeekThursday).inDays ~/ 7);

    return _IsoWeekInfo(year: weekYear, week: week);
  }

  _ReportConfig _getConfig(ReportPeriod period, DateTime? pickedDate) {
    final date = pickedDate ?? DateTime.now();

    switch (period) {
      case ReportPeriod.daily:
        return _ReportConfig(
          title: DateFormat('dd MMM yyyy').format(date),
          subtitle: DateFormat('EEEE').format(date),
          info: "Stay on top of today's money flow",
          icon: Icons.today_rounded,
          primaryColor: const Color(0xFF2563EB),
          secondaryColor: const Color(0xFF60A5FA),
        );

      case ReportPeriod.weekly:
        final weekInfo = _getIsoWeekInfo(date);
        final start = _getIsoWeekStartDate(weekInfo.year, weekInfo.week);
        final end = start.add(const Duration(days: 6));

        return _ReportConfig(
          title: 'Week ${weekInfo.week}, ${weekInfo.year}',
          subtitle:
              '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
          info: "See how your week is shaping up",
          icon: Icons.calendar_view_week_rounded,
          primaryColor: const Color(0xFF7C3AED),
          secondaryColor: const Color(0xFFA78BFA),
        );

      case ReportPeriod.monthly:
        return _ReportConfig(
          title: DateFormat('MMMM yyyy').format(date),
          subtitle: pickedDate == null
              ? 'Current monthly report'
              : 'Selected monthly report',
          info: 'Track trends and plan smarter this month',
          icon: Icons.calendar_month_rounded,
          primaryColor: const Color(0xFF0891B2),
          secondaryColor: const Color(0xFF22D3EE),
        );

      case ReportPeriod.yearly:
        return _ReportConfig(
          title: date.year.toString(),
          subtitle: pickedDate == null
              ? 'Current yearly report'
              : 'Selected yearly report',
          info: 'Discover your financial growth story',
          icon: Icons.bar_chart_rounded,
          primaryColor: const Color(0xFFEA580C),
          secondaryColor: const Color(0xFFFB923C),
        );
    }
  }

  _FormattedLabel _formatLabel(String label, ReportPeriod period) {
    try {
      switch (period) {
        case ReportPeriod.daily:
          final date = DateTime.parse(label);

          return _FormattedLabel(
            title: DateFormat('EEEE').format(date),
            subtitle: DateFormat('dd MMM yyyy').format(date),
          );

        case ReportPeriod.weekly:
          final range = _getDateRangeFromLabel(label, period);
          final start = DateFormat('dd MMM yyyy').format(range.start);
          final end = DateFormat(
            'dd MMM yyyy',
          ).format(range.end.subtract(const Duration(days: 1)));

          final parts = label.split('-W');
          final week = parts.length > 1 ? parts[1] : '';

          return _FormattedLabel(
            title: 'Week $week',
            subtitle: '$start - $end',
          );

        case ReportPeriod.monthly:
          final date = DateTime.parse('$label-01');

          return _FormattedLabel(
            title: DateFormat('MMMM').format(date),
            subtitle: DateFormat('yyyy').format(date),
          );

        case ReportPeriod.yearly:
          return _FormattedLabel(title: label, subtitle: 'Yearly summary');
      }
    } catch (_) {
      return _FormattedLabel(title: label, subtitle: '');
    }
  }

  _DateRange _getDateRangeFromLabel(String label, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.daily:
        final start = DateTime.parse(label);

        return _DateRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(start.year, start.month, start.day + 1),
        );

      case ReportPeriod.weekly:
        final parts = label.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);

        final start = _getIsoWeekStartDate(year, week);

        return _DateRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );

      case ReportPeriod.monthly:
        final date = DateTime.parse('$label-01');

        return _DateRange(
          start: DateTime(date.year, date.month, 1),
          end: DateTime(date.year, date.month + 1, 1),
        );

      case ReportPeriod.yearly:
        final year = int.parse(label);

        return _DateRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year + 1, 1, 1),
        );
    }
  }

  DateTime _getIsoWeekStartDate(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final weekOneMonday = jan4.subtract(Duration(days: jan4.weekday - 1));

    return weekOneMonday.add(Duration(days: (week - 1) * 7));
  }

  List _filterTransactionsByRange(
    List transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions.where((transaction) {
      final transactionDate = _getTransactionDate(transaction);

      return !transactionDate.isBefore(start) && transactionDate.isBefore(end);
    }).toList();
  }

  DateTime _getTransactionDate(dynamic transaction) {
    final value = transaction.date;

    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is String) {
      final date = DateTime.parse(value);
      return DateTime(date.year, date.month, date.day);
    }

    throw Exception('Transaction date field is missing or invalid');
  }
}

class _PeriodPickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodPickerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.10)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.35)
                    : theme.dividerColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final _ReportConfig config;
  final ReportPeriod period;
  final DateTime? selectedDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _ReportHeader({
    required this.config,
    required this.period,
    required this.selectedDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final hasSelectedDate = selectedDate != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.primaryColor, config.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            config.info,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    if (hasSelectedDate)
                      GestureDetector(
                        onTap: onClearDate,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Net Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${isPositive ? '+' : '-'}৳${balance.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _HeaderMiniCard(
                  title: 'Income',
                  amount: totalIncome,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMiniCard(
                  title: 'Expense',
                  amount: totalExpense,
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _HeaderMiniCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.02),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.26)),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color.withOpacity(0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '৳${amount.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double income;
  final double expense;
  final _ReportConfig config;
  final List transactions;

  const _ReportTile({
    required this.title,
    required this.subtitle,
    required this.income,
    required this.expense,
    required this.config,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.primaryColor.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row(
            //   children: [
            //     Container(
            //       height: 46,
            //       width: 46,
            //       decoration: BoxDecoration(
            //         color: config.primaryColor.withOpacity(0.10),
            //         borderRadius: BorderRadius.circular(15),
            //       ),
            //       child: Icon(config.icon, color: config.primaryColor),
            //     ),

            //     const SizedBox(width: 14),

            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             title,
            //             maxLines: 1,
            //             overflow: TextOverflow.ellipsis,
            //             style: theme.textTheme.titleSmall?.copyWith(
            //               fontWeight: FontWeight.w800,
            //             ),
            //           ),
            //           if (subtitle.isNotEmpty) ...[
            //             const SizedBox(height: 4),
            //             Text(
            //               subtitle,
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //               style: theme.textTheme.bodySmall?.copyWith(
            //                 color: Colors.grey,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //             ),
            //           ],
            //         ],
            //       ),
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 16),

            // Row(
            //   children: [
            //     Expanded(
            //       child: _AmountInfoCard(
            //         title: 'Income',
            //         amount: income,
            //         color: Colors.green,
            //         icon: Icons.arrow_downward_rounded,
            //       ),
            //     ),
            //     const SizedBox(width: 10),
            //     Expanded(
            //       child: _AmountInfoCard(
            //         title: 'Expense',
            //         amount: expense,
            //         color: Colors.red,
            //         icon: Icons.arrow_upward_rounded,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 16),

            _TransactionListPreview(transactions: transactions),
          ],
        ),
      ),
    );
  }
}

class _TransactionListPreview extends StatelessWidget {
  final List transactions;

  const _TransactionListPreview({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'No transactions found for this period',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Transactions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${transactions.length} item${transactions.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...transactions.map((t) {
          final isIncome = t.type == TransactionType.income;
          final category = t.categoryName;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isIncome
                  ? Colors.green.withOpacity(0.06)
                  : Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(
                            value: context.read<TransactionBloc>(),
                          ),
                          BlocProvider.value(
                            value: context.read<AccountBloc>(),
                          ),
                        ],
                        child: TransactionDetailView(transaction: t),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: isIncome
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isIncome ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatCategory(category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.description.isEmpty
                                  ? 'No description'
                                  : t.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        '${isIncome ? '+' : '-'}৳${t.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  static String _formatCategory(String value) {
    if (value.isEmpty) return 'General';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}

class _EmptyReportState extends StatelessWidget {
  final _ReportConfig config;
  final bool hasSelectedDate;

  const _EmptyReportState({
    required this.config,
    required this.hasSelectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: config.primaryColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.primaryColor, size: 42),
            ),

            const SizedBox(height: 18),

            Text(
              'No report data found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasSelectedDate
                  ? 'No data found for the selected ${config.title.toLowerCase()}. Tap the date above and choose another date.'
                  : 'Your ${config.title.toLowerCase()} data will appear here once transactions are available.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportLoadingState extends StatelessWidget {
  const _ReportLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ReportConfig {
  final String title;
  final String subtitle;
  final String info;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const _ReportConfig({
    required this.title,
    required this.subtitle,
    required this.info,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class _FormattedLabel {
  final String title;
  final String subtitle;

  const _FormattedLabel({required this.title, required this.subtitle});
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}

class _IsoWeekInfo {
  final int year;
  final int week;

  const _IsoWeekInfo({required this.year, required this.week});
}
