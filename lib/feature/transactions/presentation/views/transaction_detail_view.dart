import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';

import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/services/local_receipt_service.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/views/edit_transaction_view.dart';
import 'package:runearn/feature/transactions/presentation/widgets/local_receipt_field.dart';

class TransactionDetailView extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailView({super.key, required this.transaction});

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  late Transaction transaction;

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final category = transaction.categoryName;
    final typeText = isIncome ? 'Income' : 'Expense';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Transaction Details",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    _AmountHeader(
                      amount: transaction.amount,
                      typeText: typeText,
                      isIncome: isIncome,
                      color: color,
                    ),

                    const SizedBox(height: 18),

                    _SectionCard(
                      title: 'Transaction Info',
                      children: [
                        _InfoRow(
                          icon: Icons.category_outlined,
                          title: 'Category',
                          value: transaction.isSplit
                              ? 'Split across ${transaction.splits.length} categories'
                              : category,
                          color: color,
                        ),
                        for (final split in transaction.splits)
                          _InfoRow(
                            icon: Icons.call_split_rounded,
                            title: split.categoryName,
                            value: '৳${split.amount.toStringAsFixed(2)}',
                            color: color,
                          ),
                        if (transaction.tags.isNotEmpty)
                          _InfoRow(
                            icon: Icons.sell_outlined,
                            title: 'Tags',
                            value: transaction.tags
                                .map((tag) => '#$tag')
                                .join('  '),
                            color: color,
                            maxLines: 3,
                          ),
                        _InfoRow(
                          icon: Icons.description_outlined,
                          title: 'Description',
                          value: transaction.description.trim().isEmpty
                              ? 'No description'
                              : transaction.description,
                          color: color,
                          maxLines: 3,
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Date',
                          value: DateFormat(
                            'dd MMM yyyy',
                          ).format(transaction.date),
                          color: color,
                        ),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          title: 'Time',
                          value: DateFormat('hh:mm a').format(transaction.date),
                          color: color,
                        ),
                        _InfoRow(
                          icon: isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          title: 'Type',
                          value: typeText,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Receipt',
                      children: [
                        LocalReceiptField(
                          transactionId: transaction.id,
                          path: transaction.localReceiptPath,
                          description: transaction.description,
                          onChanged: (value) {
                            final previousPath = transaction.localReceiptPath;
                            final updated = transaction.copyWith(
                              localReceiptPath: value,
                              clearLocalReceipt: value == null,
                            );
                            context.read<TransactionBloc>().add(
                              UpdateTransactionEvent(updated),
                            );
                            setState(() => transaction = updated);
                            if (previousPath != value) {
                              LocalReceiptService().delete(previousPath);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _BottomActions(
              onDelete: () => _confirmDelete(context),
              onEdit: () async {
                final updatedTransaction = await Navigator.push<Transaction>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: context.read<TransactionBloc>(),
                        ),
                        BlocProvider.value(value: context.read<AccountBloc>()),
                      ],
                      child: EditTransactionView(transaction: transaction),
                    ),
                  ),
                );

                if (updatedTransaction != null) {
                  setState(() {
                    transaction = updatedTransaction;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<TransactionBloc>();
    var isDeleting = false;
    String? errorMessage;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => PopScope(
            canPop: !isDeleting,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Delete Transaction?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This transaction will be removed from your list. '
                    'This action cannot be undone.',
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            errorMessage = null;
                          });
                          bloc.add(DeleteTransactionEvent(transaction.id));
                          final result = await bloc.stream.firstWhere(
                            (state) =>
                                state is TransactionError ||
                                state is TransactionLoaded &&
                                    state.transactions.every(
                                      (item) => item.id != transaction.id,
                                    ),
                          );
                          if (!dialogContext.mounted) return;
                          if (result is TransactionLoaded) {
                            Navigator.pop(dialogContext, true);
                            return;
                          }
                          setDialogState(() {
                            isDeleting = false;
                            errorMessage = (result as TransactionError).message;
                          });
                        },
                  child: isDeleting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (deleted != true || !mounted) return;
    await LocalReceiptService().delete(transaction.localReceiptPath);
    if (mounted) Navigator.pop(this.context);
  }
}

class _AmountHeader extends StatelessWidget {
  final double amount;
  final String typeText;
  final bool isIncome;
  final Color color;

  const _AmountHeader({
    required this.amount,
    required this.typeText,
    required this.isIncome,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            typeText.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${isIncome ? '+' : '-'}৳${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
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

class _BottomActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BottomActions({required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.10),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
