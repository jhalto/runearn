import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/core/utils/category_helper.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/recurring/domain/entities/recurrence_frequency.dart';
import 'package:runearn/feature/recurring/domain/entities/recurring_transaction.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_event.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_state.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({this.currentRoute = Routes.recurring, super.key});
  final String currentRoute;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: currentRoute,
    title: 'Bills & Recurring',
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showRecurringEditor(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add schedule'),
    ),
    body: SafeArea(
      child: BlocConsumer<RecurringBloc, RecurringState>(
        listener: (context, state) {
          if (state is RecurringFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is RecurringInitial || state is RecurringLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RecurringFailure) {
            return Center(
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    context.read<RecurringBloc>().add(const LoadRecurring()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }
          return _RecurringContent(state: state as RecurringLoaded);
        },
      ),
    ),
  );
}

class _RecurringContent extends StatelessWidget {
  const _RecurringContent({required this.state});
  final RecurringLoaded state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdue = state.overdueAt(now).length;
    final monthlyExpenses = state.active
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.frequency == RecurrenceFrequency.monthly,
        )
        .fold<double>(0, (total, item) => total + item.amount);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<RecurringBloc>().add(const LoadRecurring()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReminderSummary(
                    active: state.active.length,
                    overdue: overdue,
                    monthlyExpenses: monthlyExpenses,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scheduled items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.items.isEmpty)
                    const _EmptyRecurring()
                  else
                    for (final item in state.items)
                      _RecurringCard(
                        item: item,
                        onComplete: () => _complete(context, item),
                        onEdit: () => showRecurringEditor(context, item: item),
                        onToggle: () => context.read<RecurringBloc>().add(
                          SaveRecurringRequested(
                            item.copyWith(isActive: !item.isActive),
                          ),
                        ),
                        onDelete: () => _delete(context, item),
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

class _ReminderSummary extends StatelessWidget {
  const _ReminderSummary({
    required this.active,
    required this.overdue,
    required this.monthlyExpenses,
  });
  final int active;
  final int overdue;
  final double monthlyExpenses;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: overdue > 0 ? colors.errorContainer : colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(child: _metric(context, 'Active', '$active')),
            Expanded(child: _metric(context, 'Overdue', '$overdue')),
            Expanded(
              child: _metric(context, 'Monthly bills', _money(monthlyExpenses)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.onComplete,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final RecurringTransaction item;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final due = DateTime(
      item.nextDue.year,
      item.nextDue.month,
      item.nextDue.day,
    );
    final current = DateTime(today.year, today.month, today.day);
    final overdue = item.isActive && due.isBefore(current);
    final color = item.type == TransactionType.expense
        ? Theme.of(context).colorScheme.error
        : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              foregroundColor: color,
              child: Icon(
                item.type == TransactionType.expense
                    ? Icons.receipt_long_outlined
                    : Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (!item.isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Chip(
                            label: Text('Paused'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  Text('${item.categoryName} • ${item.frequency.label}'),
                  const SizedBox(height: 4),
                  Text(
                    overdue
                        ? 'Overdue • ${DateFormat('d MMM yyyy').format(item.nextDue)}'
                        : 'Due ${DateFormat('d MMM yyyy').format(item.nextDue)}',
                    style: TextStyle(
                      color: overdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: overdue ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(item.amount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                if (item.isActive)
                  TextButton(
                    onPressed: onComplete,
                    child: const Text('Mark paid'),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggle();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(item.isActive ? 'Pause' : 'Resume'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecurring extends StatelessWidget {
  const _EmptyRecurring();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(
            Icons.event_repeat_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No recurring items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          const Text(
            'Add rent, subscriptions, salary, or other repeating payments.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Future<void> _complete(BuildContext context, RecurringTransaction item) async {
  if (item.accountId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit this schedule and select an account.'),
      ),
    );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        item.type == TransactionType.expense
            ? 'Mark bill as paid?'
            : 'Record recurring income?',
      ),
      content: Text(
        '${_money(item.amount)} will be added to your transactions today.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final now = DateTime.now();
  final recurringBloc = context.read<RecurringBloc>();
  final transactionBloc = context.read<TransactionBloc>();
  recurringBloc.add(RecordRecurringRequested(item, recordedAt: now));
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Recording transaction…')),
          ],
        ),
      ),
    ),
  );
  final result = await recurringBloc.stream.firstWhere(
    (state) =>
        state is RecurringFailure ||
        state is RecurringLoaded &&
            state.items.any(
              (candidate) =>
                  candidate.id == item.id &&
                  candidate.nextDue.isAfter(item.nextDue),
            ),
  );
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (result is RecurringLoaded) {
    transactionBloc.add(const LoadTransactions());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recurring transaction recorded')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text((result as RecurringFailure).message)),
    );
  }
}

Future<void> _delete(BuildContext context, RecurringTransaction item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete recurring item?'),
      content: Text('${item.title} will no longer create reminders.'),
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
    context.read<RecurringBloc>().add(DeleteRecurringRequested(item.id));
  }
}

Future<void> showRecurringEditor(
  BuildContext context, {
  RecurringTransaction? item,
}) async {
  final recurringBloc = context.read<RecurringBloc>();
  final accountsState = context.read<AccountBloc>().state;
  final transactionState = context.read<TransactionBloc>().state;
  final accounts = accountsState is AccountLoaded
      ? accountsState.accounts
            .where(
              (account) =>
                  account.type.classification == AccountClassification.asset ||
                  account.type.classification ==
                      AccountClassification.liability,
            )
            .toList(growable: false)
      : const <FinanceAccount>[];
  final transactions = switch (transactionState) {
    TransactionLoaded state => state.transactions,
    TransactionSyncing state => state.transactions,
    _ => const <Transaction>[],
  };
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SafeArea(
      child: BlocProvider.value(
        value: recurringBloc,
        child: _RecurringEditor(
          item: item,
          accounts: accounts,
          transactions: transactions,
        ),
      ),
    ),
  );
}

class _RecurringEditor extends StatefulWidget {
  const _RecurringEditor({
    required this.accounts,
    required this.transactions,
    this.item,
  });
  final RecurringTransaction? item;
  final List<FinanceAccount> accounts;
  final List<Transaction> transactions;

  @override
  State<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<_RecurringEditor> {
  final key = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.item?.title ?? '');
  late final amount = TextEditingController(
    text: widget.item?.amount.toStringAsFixed(2) ?? '',
  );
  late final note = TextEditingController(text: widget.item?.note ?? '');
  late TransactionType type = widget.item?.type ?? TransactionType.expense;
  late TransactionCategory category =
      widget.item?.category ?? CategoryHelper.getByType(type).first;
  late String? customCategory = widget.item?.customCategory;
  late String? accountId =
      widget.item?.accountId ??
      (widget.accounts.isEmpty ? null : widget.accounts.first.id);
  late RecurrenceFrequency frequency =
      widget.item?.frequency ?? RecurrenceFrequency.monthly;
  late DateTime due = widget.item?.nextDue ?? DateTime.now();
  bool isSubmitting = false;

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      ...CategoryHelper.getByType(type).map((value) => value.label),
      ...widget.transactions
          .where((transaction) => transaction.type == type)
          .map((transaction) => transaction.categoryName),
    }.toList()..sort();
    final selectedCategory = customCategory ?? category.label;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.item == null
                    ? 'Add recurring item'
                    : 'Edit recurring item',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.trending_down_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.trending_up_rounded),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) => setState(() {
                  type = value.first;
                  category = CategoryHelper.getByType(type).first;
                  customCategory = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: title,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '৳ ',
                ),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  return number == null || number <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(growable: false),
                onChanged: (name) {
                  if (name == null) return;
                  final standard = CategoryHelper.getByType(
                    type,
                  ).where((value) => value.label == name);
                  setState(() {
                    if (standard.isNotEmpty) {
                      category = standard.first;
                      customCategory = null;
                    } else {
                      category = TransactionCategory.other;
                      customCategory = name;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    widget.accounts.any((account) => account.id == accountId)
                    ? accountId
                    : null,
                decoration: const InputDecoration(labelText: 'Account'),
                items: widget.accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => accountId = value),
                validator: (_) =>
                    accountId == null ? 'Select an account' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: RecurrenceFrequency.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) =>
                    setState(() => frequency = value ?? frequency),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Next due date'),
                subtitle: Text(DateFormat('d MMMM yyyy').format(due)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: due,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 36500)),
                  );
                  if (selected != null) setState(() => due = selected);
                },
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isSubmitting ? null : _save,
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  isSubmitting ? 'Saving schedule…' : 'Save schedule',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    FocusScope.of(context).unfocus();
    final bloc = context.read<RecurringBloc>();
    final itemId =
        widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    bloc.add(
      SaveRecurringRequested(
        RecurringTransaction(
          id: itemId,
          title: title.text.trim(),
          amount: double.parse(amount.text),
          type: type,
          category: category,
          customCategory: customCategory,
          accountId: accountId,
          frequency: frequency,
          nextDue: due,
          note: note.text.trim(),
          isActive: widget.item?.isActive ?? true,
        ),
      ),
    );
    final result = await bloc.stream.firstWhere(
      (state) =>
          state is RecurringFailure ||
          state is RecurringLoaded &&
              state.items.any((item) => item.id == itemId),
    );
    if (!mounted) return;
    if (result is RecurringLoaded) {
      Navigator.pop(context);
    } else {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as RecurringFailure).message)),
      );
    }
  }
}

Widget _metric(BuildContext context, String label, String value) => Column(
  children: [
    Text(label, style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 4),
    Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    ),
  ],
);

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
