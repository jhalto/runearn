import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_payment.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';
import 'package:runearn/feature/loans/domain/services/loan_balance_calculator.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/loans/presentation/widgets/add_loan_sheet.dart';

class LoanDetailPage extends StatelessWidget {
  const LoanDetailPage({required this.initialLoan, super.key});

  final Loan initialLoan;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoanBloc, LoanState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final loan = state is LoanLoaded
            ? _findLoan(state.loans, initialLoan.id)
            : initialLoan;
        if (loan == null) {
          return const Scaffold(
            body: Center(child: Text('This loan no longer exists.')),
          );
        }
        final loaded = state is LoanLoaded ? state : null;
        final payments = loaded?.paymentsFor(loan.id) ?? const <LoanPayment>[];
        return _LoanDetailScaffold(
          loan: loan,
          payments: payments,
          balance:
              loaded?.balanceFor(loan) ??
              LoanBalanceCalculator.calculate(loan, payments),
        );
      },
    );
  }

  Loan? _findLoan(List<Loan> loans, String id) {
    for (final loan in loans) {
      if (loan.id == id) return loan;
    }
    return null;
  }
}

class _LoanDetailScaffold extends StatelessWidget {
  const _LoanDetailScaffold({
    required this.loan,
    required this.payments,
    required this.balance,
  });

  final Loan loan;
  final List<LoanPayment> payments;
  final LoanBalance balance;

  @override
  Widget build(BuildContext context) {
    final isLent = loan.direction == LoanDirection.lent;
    final colors = Theme.of(context).colorScheme;
    final accent = isLent ? colors.primary : colors.tertiary;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue =
        !loan.isSettled && loan.dueAt != null && loan.dueAt!.isBefore(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loan details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit loan',
            onPressed: () => showEditLoanSheet(context, loan),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<_DetailAction>(
            onSelected: (action) {
              switch (action) {
                case _DetailAction.toggleSettlement:
                  context.read<LoanBloc>().add(LoanSettlementChanged(loan));
                case _DetailAction.delete:
                  _confirmDelete(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _DetailAction.toggleSettlement,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    loan.isSettled
                        ? Icons.replay_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  title: Text(loan.isSettled ? 'Mark active' : 'Mark settled'),
                ),
              ),
              const PopupMenuItem(
                value: _DetailAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoanHero(
                          loan: loan,
                          accent: accent,
                          overdue: overdue,
                          remaining: balance.outstanding,
                        ),
                        if (loan.interestMethod != LoanInterestMethod.none) ...[
                          const SizedBox(height: 18),
                          _DetailSection(
                            title: 'Interest and payoff',
                            children: [
                              _DetailRow(
                                icon: Icons.percent_rounded,
                                label: 'Interest method',
                                value:
                                    '${loan.interestMethod.label} • '
                                    '${loan.annualInterestRate.toStringAsFixed(2)}% yearly',
                                accent: accent,
                              ),
                              _DetailRow(
                                icon: Icons.trending_up_rounded,
                                label: 'Accrued interest',
                                value:
                                    '৳${NumberFormat('#,##0.##').format(balance.accruedInterest)}',
                                accent: accent,
                              ),
                              _DetailRow(
                                icon: Icons.calculate_outlined,
                                label: 'Total due',
                                value:
                                    '৳${NumberFormat('#,##0.##').format(balance.totalDue)}',
                                accent: accent,
                              ),
                              _DetailRow(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Outstanding',
                                value:
                                    '৳${NumberFormat('#,##0.##').format(balance.outstanding)}',
                                accent: accent,
                              ),
                            ],
                          ),
                        ],
                        if (loan.dueAt != null) ...[
                          const SizedBox(height: 18),
                          _DetailSection(
                            title: 'Repayment reminder',
                            children: [
                              _DetailRow(
                                icon: loan.reminderEnabled
                                    ? Icons.notifications_active_outlined
                                    : Icons.notifications_off_outlined,
                                label: 'Status',
                                value: loan.reminderEnabled
                                    ? loan.reminderDaysBefore == 0
                                          ? 'On the due date'
                                          : '${loan.reminderDaysBefore} day${loan.reminderDaysBefore == 1 ? '' : 's'} before and when overdue'
                                    : 'Disabled',
                                accent: accent,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        _DetailSection(
                          title: 'Loan information',
                          children: [
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: isLent ? 'Borrower' : 'Lender',
                              value: loan.personName,
                              accent: accent,
                            ),
                            _DetailRow(
                              icon: Icons.account_balance_outlined,
                              label: 'Account',
                              value:
                                  '${loan.accountType.classification.label} • '
                                  '${loan.accountType.label}',
                              accent: accent,
                            ),
                            _DetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: isLent ? 'Given on' : 'Taken on',
                              value: _formatDate(loan.issuedAt),
                              accent: accent,
                            ),
                            _DetailRow(
                              icon: Icons.event_outlined,
                              label: 'Due date',
                              value: loan.dueAt == null
                                  ? 'No due date'
                                  : _formatDate(loan.dueAt!),
                              valueColor: overdue ? colors.error : null,
                              accent: accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _PaymentHistory(
                          payments: payments,
                          loan: loan,
                          remaining: balance.outstanding,
                        ),
                        const SizedBox(height: 18),
                        _DetailSection(
                          title: 'Note',
                          children: [
                            _DetailRow(
                              icon: Icons.notes_rounded,
                              label: 'Description',
                              value: loan.note.trim().isEmpty
                                  ? 'No note added'
                                  : loan.note.trim(),
                              accent: accent,
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _BottomActions(
              onEdit: () => showEditLoanSheet(context, loan),
              onAddPayment: balance.outstanding <= 0
                  ? null
                  : () => _showAddPaymentSheet(
                      context,
                      loan,
                      balance.outstanding,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text(
          'The loan record for ${loan.personName} will be removed. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<LoanBloc>().add(DeleteLoanRequested(loan.id));
    Navigator.pop(context);
  }

  static String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }
}

class _LoanHero extends StatelessWidget {
  const _LoanHero({
    required this.loan,
    required this.accent,
    required this.overdue,
    required this.remaining,
  });

  final Loan loan;
  final Color accent;
  final bool overdue;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final status = loan.isSettled
        ? 'Settled'
        : overdue
        ? 'Overdue'
        : 'Active';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                loan.direction == LoanDirection.lent
                    ? Icons.call_made_rounded
                    : Icons.call_received_rounded,
                color: onAccent,
              ),
              const SizedBox(width: 8),
              Text(
                loan.direction.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '৳${NumberFormat('#,##0.##').format(remaining)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: onAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ৳${NumberFormat('#,##0.##').format(loan.amount)} remaining',
            style: theme.textTheme.bodySmall?.copyWith(color: onAccent),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: onAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
    this.maxLines = 2,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({
    required this.payments,
    required this.loan,
    required this.remaining,
  });

  final List<LoanPayment> payments;
  final Loan loan;
  final double remaining;

  @override
  Widget build(BuildContext context) {
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
                    'Payment history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (remaining > 0)
                  TextButton.icon(
                    onPressed: () =>
                        _showAddPaymentSheet(context, loan, remaining),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Payment'),
                  ),
              ],
            ),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No payments recorded yet.'),
              )
            else
              ...payments.map(
                (payment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.payments_outlined),
                  ),
                  title: Text(
                    '৳${NumberFormat('#,##0.##').format(payment.amount)}',
                  ),
                  subtitle: Text(
                    '${DateFormat('d MMM yyyy').format(payment.date)}'
                    '${payment.note.isEmpty ? '' : ' • ${payment.note}'}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete payment',
                    onPressed: () => _confirmDelete(context, payment),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LoanPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text(
          'The payment will be removed and the outstanding balance restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoanBloc>().add(DeleteLoanPaymentRequested(payment));
    }
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onEdit, required this.onAddPayment});

  final VoidCallback onEdit;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddPayment,
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(
                    onAddPayment == null ? 'Fully paid' : 'Add payment',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddPaymentSheet(
  BuildContext context,
  Loan loan,
  double remaining,
) async {
  final bloc = context.read<LoanBloc>();
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  final now = DateTime.now();
  var date = loan.issuedAt.isAfter(now) ? loan.issuedAt : now;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Remaining: ৳${NumberFormat('#,##0.##').format(remaining)}',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Payment amount',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (parsed > remaining) {
                      return 'Payment exceeds the remaining balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: loan.issuedAt,
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) setState(() => date = selected);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('d MMM yyyy').format(date)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    if (!(key.currentState?.validate() ?? false)) return;
                    bloc.add(
                      AddLoanPaymentRequested(
                        LoanPayment(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          loanId: loan.id,
                          amount: double.parse(amount.text),
                          date: date,
                          note: note.text.trim(),
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  amount.dispose();
  note.dispose();
}

enum _DetailAction { toggleSettlement, delete }
