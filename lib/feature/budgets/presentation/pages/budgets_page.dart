import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/core/utils/category_helper.dart';
import 'package:runearn/feature/budgets/domain/entities/budget.dart';
import 'package:runearn/feature/budgets/domain/entities/budget_progress.dart';
import 'package:runearn/feature/budgets/domain/services/budget_progress_calculator.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_event.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_state.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: Routes.budgets,
    title: 'Budgets',
    actions: [
      IconButton(
        tooltip: 'Budget templates',
        onPressed: () => _showTemplates(context),
        icon: const Icon(Icons.library_books_outlined),
      ),
    ],
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openEditor(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add budget'),
    ),
    body: SafeArea(
      child: BlocConsumer<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, budgetState) =>
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, transactionState) {
                final budgets = budgetState is BudgetLoaded
                    ? budgetState.budgets
                    : null;
                final transactions = switch (transactionState) {
                  TransactionLoaded state => state.transactions,
                  TransactionSyncing state => state.transactions,
                  _ => null,
                };
                if (budgets == null || transactions == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final progress = BudgetProgressCalculator.calculate(
                  budgets,
                  transactions,
                  month,
                );
                return _BudgetContent(
                  month: month,
                  progress: progress,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onEdit: (item) => _openEditor(context, budget: item.budget),
                  onDelete: (item) => _delete(context, item.budget),
                );
              },
            ),
      ),
    ),
  );

  void _changeMonth(int offset) =>
      setState(() => month = DateTime(month.year, month.month + offset));

  void _openEditor(BuildContext context, {Budget? budget}) {
    final budgetBloc = context.read<BudgetBloc>();
    final budgetState = budgetBloc.state;
    final transactionState = context.read<TransactionBloc>().state;
    final budgets = budgetState is BudgetLoaded
        ? budgetState.budgets
        : const <Budget>[];
    final transactions = switch (transactionState) {
      TransactionLoaded state => state.transactions,
      TransactionSyncing state => state.transactions,
      _ => const <Transaction>[],
    };
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: BlocProvider.value(
          value: budgetBloc,
          child: _BudgetEditor(
            month: month,
            budget: budget,
            budgets: budgets,
            transactions: transactions,
          ),
        ),
      ),
    );
  }

  Future<void> _showTemplates(BuildContext context) async {
    final state = context.read<BudgetBloc>().state;
    if (state is! BudgetLoaded) return;
    final templates = state.budgets
        .where((budget) => budget.isTemplate)
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Budget templates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (templates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No templates yet. Choose “Reusable template” when '
                    'adding a budget.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final template in templates)
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline_rounded),
                    title: Text(
                      template.templateName.isEmpty
                          ? template.categoryName
                          : template.templateName,
                    ),
                    subtitle: Text(
                      '${template.categoryName} • ${_money(template.limit)}',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _applyTemplate(context, template);
                      },
                      child: const Text('Use'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyTemplate(BuildContext context, Budget template) {
    final state = context.read<BudgetBloc>().state;
    if (state is! BudgetLoaded) return;
    final existing = state.budgets.cast<Budget?>().firstWhere(
      (budget) =>
          !budget!.isTemplate &&
          budget.categoryName.toLowerCase() ==
              template.categoryName.toLowerCase() &&
          budget.month.year == month.year &&
          budget.month.month == month.month,
      orElse: () => null,
    );
    context.read<BudgetBloc>().add(
      SaveBudgetRequested(
        Budget(
          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          categoryName: template.categoryName,
          limit: template.limit,
          month: month,
          rolloverEnabled: template.rolloverEnabled,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template.categoryName} budget applied')),
    );
  }

  Future<void> _delete(BuildContext context, Budget budget) async {
    final budgetBloc = context.read<BudgetBloc>();
    var deleting = false;
    String? errorMessage;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> deleteBudget() async {
            if (deleting) return;
            setDialogState(() {
              deleting = true;
              errorMessage = null;
            });
            budgetBloc.add(DeleteBudgetRequested(budget.id));
            final result = await budgetBloc.stream.firstWhere(
              (state) =>
                  state is BudgetFailure ||
                  state is BudgetLoaded &&
                      !state.budgets.any((item) => item.id == budget.id),
            );
            if (!dialogContext.mounted) return;
            if (result is BudgetLoaded) {
              Navigator.pop(dialogContext, true);
              return;
            }
            setDialogState(() {
              deleting = false;
              errorMessage = (result as BudgetFailure).message;
            });
          }

          return PopScope(
            canPop: !deleting,
            child: AlertDialog(
              title: const Text('Delete budget?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remove the ${budget.categoryName} spending limit?'),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: deleting ? null : deleteBudget,
                  icon: deleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(deleting ? 'Deleting…' : 'Delete'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${budget.categoryName} budget deleted')),
      );
    }
  }
}

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.month,
    required this.progress,
    required this.onPrevious,
    required this.onNext,
    required this.onEdit,
    required this.onDelete,
  });
  final DateTime month;
  final List<BudgetProgress> progress;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<BudgetProgress> onEdit;
  final ValueChanged<BudgetProgress> onDelete;

  @override
  Widget build(BuildContext context) {
    final limit = progress.fold<double>(
      0,
      (total, item) => total + item.effectiveLimit,
    );
    final spent = progress.fold<double>(0, (total, item) => total + item.spent);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<BudgetBloc>().add(const LoadBudgets()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        onPressed: onPrevious,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      SizedBox(
                        width: 170,
                        child: Text(
                          DateFormat('MMMM yyyy').format(month),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        onPressed: onNext,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BudgetSummary(limit: limit, spent: spent),
                  const SizedBox(height: 20),
                  Text(
                    'Category limits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (progress.isEmpty)
                    const _EmptyBudgets()
                  else
                    for (final item in progress)
                      _BudgetCard(
                        progress: item,
                        onEdit: () => onEdit(item),
                        onDelete: () => onDelete(item),
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

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.limit, required this.spent});
  final double limit;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final over = spent > limit && limit > 0;
    return Card(
      color: over ? colors.errorContainer : colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              'Monthly spending plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _money(limit - spent),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: over ? colors.error : null,
              ),
            ),
            Text(over ? 'over budget' : 'remaining'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _metric(context, 'Budget', limit)),
                Expanded(child: _metric(context, 'Spent', spent)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });
  final BudgetProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final warning = progress.ratio >= .8;
    final color = progress.isOverBudget
        ? colors.error
        : warning
        ? Colors.orange
        : colors.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: .12),
                    foregroundColor: color,
                    child: const Icon(Icons.category_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.budget.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${_money(progress.spent)} of '
                          '${_money(progress.effectiveLimit)}',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.ratio.clamp(0, 1),
                minHeight: 9,
                borderRadius: BorderRadius.circular(8),
                color: color,
              ),
              const SizedBox(height: 8),
              if (progress.rolledOver > 0) ...[
                Text(
                  '${_money(progress.rolledOver)} rolled over',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                progress.isOverBudget
                    ? '${_money(-progress.remaining)} over limit'
                    : '${_money(progress.remaining)} remaining',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({
    required this.month,
    required this.budgets,
    required this.transactions,
    this.budget,
  });
  final DateTime month;
  final Budget? budget;
  final List<Budget> budgets;
  final List<Transaction> transactions;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final formKey = GlobalKey<FormState>();
  late final amountController = TextEditingController(
    text: widget.budget?.limit.toStringAsFixed(2) ?? '',
  );
  late final templateNameController = TextEditingController(
    text: widget.budget?.templateName ?? '',
  );
  late String category =
      widget.budget?.categoryName ?? _categories(widget.transactions).first;
  bool isSubmitting = false;
  late bool rolloverEnabled = widget.budget?.rolloverEnabled ?? false;
  late bool isTemplate = widget.budget?.isTemplate ?? false;

  @override
  void dispose() {
    amountController.dispose();
    templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.budget == null ? 'Add monthly budget' : 'Edit budget',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(DateFormat('MMMM yyyy').format(widget.month)),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('Monthly budget'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.bookmark_outline_rounded),
                label: Text('Reusable template'),
              ),
            ],
            selected: {isTemplate},
            onSelectionChanged: (values) =>
                setState(() => isTemplate = values.first),
          ),
          const SizedBox(height: 14),
          if (isTemplate) ...[
            TextFormField(
              controller: templateNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Template name',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (value) =>
                  isTemplate && (value?.trim().isEmpty ?? true)
                  ? 'Enter a template name'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: 'Expense category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _categories(widget.transactions)
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(growable: false),
            onChanged: widget.budget == null
                ? (value) => setState(() => category = value ?? category)
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Spending limit',
              prefixText: '৳ ',
              prefixIcon: Icon(Icons.speed_rounded),
            ),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              return amount == null || amount <= 0
                  ? 'Enter an amount greater than zero'
                  : null;
            },
            onFieldSubmitted: (_) {
              if (!isSubmitting) _save();
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Roll over unused money'),
            subtitle: const Text(
              'Add last month’s unused amount to this category',
            ),
            value: rolloverEnabled,
            onChanged: (value) => setState(() => rolloverEnabled = value),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isSubmitting ? null : _save,
            icon: isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              isSubmitting
                  ? 'Saving budget…'
                  : widget.budget == null
                  ? 'Add budget'
                  : 'Save changes',
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    FocusScope.of(context).unfocus();
    final existing = widget.budgets.cast<Budget?>().firstWhere(
      (item) =>
          !isTemplate &&
          !item!.isTemplate &&
          item.categoryName.toLowerCase() == category.toLowerCase() &&
          item.month.year == widget.month.year &&
          item.month.month == widget.month.month,
      orElse: () => null,
    );
    final budget = Budget(
      id:
          widget.budget?.id ??
          existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      categoryName: category,
      limit: double.parse(amountController.text),
      month: DateTime(widget.month.year, widget.month.month),
      rolloverEnabled: rolloverEnabled,
      isTemplate: isTemplate,
      templateName: isTemplate ? templateNameController.text.trim() : '',
    );
    final bloc = context.read<BudgetBloc>();
    bloc.add(SaveBudgetRequested(budget));
    final result = await bloc.stream.firstWhere(
      (state) =>
          state is BudgetFailure ||
          state is BudgetLoaded &&
              state.budgets.any((item) => item.id == budget.id),
    );
    if (!mounted) return;
    if (result is BudgetLoaded) {
      Navigator.pop(context);
    } else {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as BudgetFailure).message)),
      );
    }
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No budgets for this month',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Set category limits to control spending and catch overspending early.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

List<String> _categories(Iterable<Transaction> transactions) {
  final names = <String>{
    ...CategoryHelper.getByType(
      TransactionType.expense,
    ).map((category) => category.label),
    ...transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .expand(
          (transaction) => transaction.categoryAllocations.map(
            (allocation) => allocation.categoryName,
          ),
        ),
  }.toList()..sort();
  return names;
}

Widget _metric(BuildContext context, String label, double value) => Column(
  children: [
    Text(label, style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 3),
    Text(_money(value), style: const TextStyle(fontWeight: FontWeight.w800)),
  ],
);

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
