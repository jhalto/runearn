import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runearn/core/utils/category_helper.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';

class TransactionSplitField extends StatefulWidget {
  const TransactionSplitField({
    required this.type,
    required this.splits,
    required this.totalProvider,
    required this.onChanged,
    super.key,
  });

  final TransactionType type;
  final List<TransactionSplit> splits;
  final double Function() totalProvider;
  final ValueChanged<List<TransactionSplit>> onChanged;

  @override
  State<TransactionSplitField> createState() => _TransactionSplitFieldState();
}

class _TransactionSplitFieldState extends State<TransactionSplitField> {
  String? _validationMessage;

  @override
  Widget build(BuildContext context) {
    if (widget.splits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.call_split_rounded),
            label: const Text('Split across categories'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Text(
                _validationMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.call_split_rounded),
                const SizedBox(width: 8),
                Text(
                  '${widget.splits.length} category splits',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit splits',
                  onPressed: () => _open(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remove splits',
                  onPressed: () => widget.onChanged(const []),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            for (final split in widget.splits)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(split.categoryName)),
                    Text(
                      '৳${split.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final total = widget.totalProvider();
    if (!total.isFinite || total <= 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (mounted) {
        setState(
          () => _validationMessage = 'Enter the transaction amount first.',
        );
      }
      return;
    }
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
    final result = await showModalBottomSheet<List<TransactionSplit>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _SplitEditor(type: widget.type, total: total, initial: widget.splits),
    );
    if (!context.mounted || result == null) return;
    widget.onChanged(result);
  }
}

class _SplitEditor extends StatefulWidget {
  const _SplitEditor({
    required this.type,
    required this.total,
    required this.initial,
  });

  final TransactionType type;
  final double total;
  final List<TransactionSplit> initial;

  @override
  State<_SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<_SplitEditor> {
  late final List<_SplitDraft> drafts;
  String? error;

  @override
  void initState() {
    super.initState();
    final categories = CategoryHelper.getByType(widget.type);
    drafts = widget.initial.isEmpty
        ? [
            _SplitDraft(categories.first, ''),
            _SplitDraft(
              categories.length > 1 ? categories[1] : categories.first,
              '',
            ),
          ]
        : widget.initial
              .map(
                (item) =>
                    _SplitDraft(item.category, item.amount.toStringAsFixed(2)),
              )
              .toList();
  }

  @override
  void dispose() {
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  double get enteredTotal => drafts.fold(
    0,
    (total, draft) => total + (double.tryParse(draft.amount.text.trim()) ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final categories = CategoryHelper.getByType(widget.type);
    final remaining = widget.total - enteredTotal;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Split transaction',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Allocate ৳${widget.total.toStringAsFixed(2)} across categories.',
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < drafts.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<TransactionCategory>(
                          initialValue: drafts[index].category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: [
                            for (final category in categories)
                              DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => drafts[index].category = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: drafts[index].amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() => error = null),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove row',
                        onPressed: drafts.length <= 2
                            ? null
                            : () {
                                final removed = drafts.removeAt(index);
                                setState(() {});
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => removed.dispose(),
                                );
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: () => setState(
                  () => drafts.add(_SplitDraft(categories.first, '')),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add category'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remaining'),
                trailing: Text(
                  '৳${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: remaining.abs() <= .01
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply split'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply() {
    final splits = drafts
        .map(
          (draft) => TransactionSplit(
            category: draft.category,
            amount: double.tryParse(draft.amount.text.trim()) ?? 0,
          ),
        )
        .toList();
    if (splits.any((item) => item.amount <= 0)) {
      setState(() => error = 'Enter an amount greater than 0 for every row.');
      return;
    }
    if ((enteredTotal - widget.total).abs() > .01) {
      setState(
        () => error =
            'Split total must equal ৳${widget.total.toStringAsFixed(2)}.',
      );
      return;
    }
    Navigator.pop<List<TransactionSplit>>(
      context,
      List<TransactionSplit>.unmodifiable(splits),
    );
  }
}

class _SplitDraft {
  _SplitDraft(this.category, String amount)
    : amount = TextEditingController(text: amount);

  TransactionCategory category;
  final TextEditingController amount;

  void dispose() => amount.dispose();
}
