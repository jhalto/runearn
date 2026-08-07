import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/search/domain/entities/saved_transaction_filter.dart';
import 'package:runearn/feature/search/domain/entities/transaction_filter.dart';
import 'package:runearn/feature/search/presentation/cubit/transaction_search_cubit.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/transactions/presentation/views/transaction_detail_view.dart';

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => context.read<TransactionSearchCubit>().updateQuery(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      currentRoute: Routes.transactionSearch,
      title: 'Search Transactions',
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded) {
            context.read<TransactionSearchCubit>().setTransactions(
              state.transactions,
            );
          } else if (state is TransactionSyncing) {
            context.read<TransactionSearchCubit>().setTransactions(
              state.transactions,
            );
          }
        },
        child: BlocConsumer<TransactionSearchCubit, TransactionSearchState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            if (state.message == null) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
            context.read<TransactionSearchCubit>().messageShown();
          },
          builder: (context, state) {
            if (_searchController.text != state.filter.query) {
              _searchController.value = TextEditingValue(
                text: state.filter.query,
                selection: TextSelection.collapsed(
                  offset: state.filter.query.length,
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'Search description, category, or tag',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: state.filter.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<TransactionSearchCubit>()
                                    .updateQuery('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                _SearchActions(state: state),
                if (state.savedFilters.isNotEmpty)
                  _SavedFilters(filters: state.savedFilters),
                _ResultSummary(state: state),
                Expanded(
                  child: state.results.isEmpty
                      ? _EmptyResults(hasFilter: state.filter.isActive)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: state.results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) =>
                              _TransactionResult(item: state.results[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchActions extends StatelessWidget {
  const _SearchActions({required this.state});
  final TransactionSearchState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openFilters(context, state),
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                state.filter.activeFilterCount == 0
                    ? 'Filters'
                    : 'Filters (${state.filter.activeFilterCount})',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Save current filter',
            onPressed: state.filter.activeFilterCount == 0
                ? null
                : () => _saveFilter(context),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          if (state.filter.isActive) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Clear all filters',
              onPressed: () => context.read<TransactionSearchCubit>().clear(),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    TransactionSearchState state,
  ) async {
    final transactionState = context.read<TransactionBloc>().state;
    final transactions = transactionState is TransactionLoaded
        ? transactionState.transactions
        : transactionState is TransactionSyncing
        ? transactionState.transactions
        : const <Transaction>[];
    final accountState = context.read<AccountBloc>().state;
    final accounts = accountState is AccountLoaded
        ? accountState.accounts
        : const <FinanceAccount>[];
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(
        initial: state.filter,
        transactions: transactions,
        accounts: accounts,
      ),
    );
    if (result != null && context.mounted) {
      context.read<TransactionSearchCubit>().updateFilter(result);
    }
  }

  Future<void> _saveFilter(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _SaveFilterDialog(),
    );
    if (name?.trim().isNotEmpty == true && context.mounted) {
      await context.read<TransactionSearchCubit>().saveCurrent(name!);
    }
  }
}

class _SaveFilterDialog extends StatefulWidget {
  const _SaveFilterDialog();

  @override
  State<_SaveFilterDialog> createState() => _SaveFilterDialogState();
}

class _SaveFilterDialogState extends State<_SaveFilterDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save filter'),
    content: TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (value) => Navigator.pop(context, value),
      decoration: const InputDecoration(
        labelText: 'Filter name',
        hintText: 'e.g. Business expenses',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

class _SavedFilters extends StatelessWidget {
  const _SavedFilters({required this.filters});
  final List<SavedTransactionFilter> filters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final saved = filters[index];
          return InputChip(
            avatar: const Icon(Icons.bookmark_outline, size: 18),
            label: Text(saved.name),
            onPressed: () =>
                context.read<TransactionSearchCubit>().applySaved(saved),
            onDeleted: () =>
                context.read<TransactionSearchCubit>().deleteSaved(saved.id),
          );
        },
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.state});
  final TransactionSearchState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          Text(
            '${state.results.length} result${state.results.length == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(
            'Total ৳${NumberFormat('#,##0.##').format(state.total)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionResult extends StatelessWidget {
  const _TransactionResult({required this.item});
  final Transaction item;

  @override
  Widget build(BuildContext context) {
    final income = item.type == TransactionType.income;
    final color = income ? Colors.green : Colors.red;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<TransactionBloc>()),
                BlocProvider.value(value: context.read<AccountBloc>()),
              ],
              child: TransactionDetailView(transaction: item),
            ),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            income ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color,
          ),
        ),
        title: Text(
          item.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            item.categoryName,
            DateFormat('dd MMM yyyy').format(item.date),
            if (item.tags.isNotEmpty)
              item.tags.take(2).map((tag) => '#$tag').join(' '),
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${income ? '+' : '-'}৳${NumberFormat('#,##0.##').format(item.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 54),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'No matching transactions' : 'No transactions yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 8),
            const Text(
              'Try removing a filter or using a broader search.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.transactions,
    required this.accounts,
  });

  final TransactionFilter initial;
  final List<Transaction> transactions;
  final List<FinanceAccount> accounts;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TransactionFilter filter = widget.initial;
  late final TextEditingController minimum = TextEditingController(
    text: filter.minimumAmount?.toString() ?? '',
  );
  late final TextEditingController maximum = TextEditingController(
    text: filter.maximumAmount?.toString() ?? '',
  );

  @override
  void dispose() {
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        widget.transactions
            .expand(
              (item) => item.categoryAllocations.map(
                (allocation) => allocation.categoryName.toLowerCase(),
              ),
            )
            .toSet()
            .toList()
          ..sort();
    final tags =
        widget.transactions.expand((item) => item.tags).toSet().toList()
          ..sort();
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
                'Filter transactions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                  ),
                ],
                selected: {filter.type},
                onSelectionChanged: (value) => setState(() {
                  final type = value.first;
                  filter = filter.copyWith(type: type, clearType: type == null);
                }),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<TransactionSort>(
                initialValue: filter.sort,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                items: [
                  for (final sort in TransactionSort.values)
                    DropdownMenuItem(value: sort, child: Text(sort.label)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => filter = filter.copyWith(sort: value));
                  }
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minimum,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Minimum amount',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maximum,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maximum amount',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: filter.from != null && filter.to != null
                        ? DateTimeRange(start: filter.from!, end: filter.to!)
                        : null,
                  );
                  if (range != null) {
                    setState(
                      () => filter = filter.copyWith(
                        from: range.start,
                        to: range.end,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  filter.from == null
                      ? 'Any date'
                      : '${DateFormat('dd MMM yy').format(filter.from!)} – '
                            '${DateFormat('dd MMM yy').format(filter.to!)}',
                ),
              ),
              if (filter.from != null)
                TextButton(
                  onPressed: () => setState(
                    () => filter = filter.copyWith(
                      clearFrom: true,
                      clearTo: true,
                    ),
                  ),
                  child: const Text('Clear date range'),
                ),
              if (categories.isNotEmpty) ...[
                const _FilterLabel('Categories'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final category in categories)
                      FilterChip(
                        label: Text(category),
                        selected: filter.categoryNames.contains(category),
                        onSelected: (selected) => setState(() {
                          final updated = {...filter.categoryNames};
                          selected
                              ? updated.add(category)
                              : updated.remove(category);
                          filter = filter.copyWith(categoryNames: updated);
                        }),
                      ),
                  ],
                ),
              ],
              if (widget.accounts.isNotEmpty) ...[
                const _FilterLabel('Accounts'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final account in widget.accounts)
                      FilterChip(
                        label: Text(account.name),
                        selected: filter.accountIds.contains(account.id),
                        onSelected: (selected) => setState(() {
                          final updated = {...filter.accountIds};
                          selected
                              ? updated.add(account.id)
                              : updated.remove(account.id);
                          filter = filter.copyWith(accountIds: updated);
                        }),
                      ),
                  ],
                ),
              ],
              if (tags.isNotEmpty) ...[
                const _FilterLabel('Tags (all selected tags must match)'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in tags)
                      FilterChip(
                        label: Text('#$tag'),
                        selected: filter.tags.contains(tag),
                        onSelected: (selected) => setState(() {
                          final updated = {...filter.tags};
                          selected ? updated.add(tag) : updated.remove(tag);
                          filter = filter.copyWith(tags: updated);
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        filter = TransactionFilter(query: filter.query);
                        minimum.clear();
                        maximum.clear();
                      }),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final result = filter.copyWith(
                          minimumAmount: double.tryParse(minimum.text),
                          clearMinimumAmount: minimum.text.trim().isEmpty,
                          maximumAmount: double.tryParse(maximum.text),
                          clearMaximumAmount: maximum.text.trim().isEmpty,
                        );
                        Navigator.pop(context, result);
                      },
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}
