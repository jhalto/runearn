import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/accounts/domain/entities/account_transfer.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({this.currentRoute = Routes.transfers, super.key});
  final String currentRoute;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const AppBackButton(),
      title: const Text('Transfers'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showTransferSheet(context),
      icon: const Icon(Icons.swap_horiz_rounded),
      label: const Text('New transfer'),
    ),
    body: const SafeArea(child: _TransfersContent()),
  );
}

class _TransfersContent extends StatelessWidget {
  const _TransfersContent();

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountBloc, AccountState>(
    builder: (context, state) {
      if (state is! AccountLoaded) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.transfers.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No transfers yet.\nMove money between accounts without creating income or expense.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      final names = {
        for (final account in state.accounts) account.id: account.name,
      };
      final accounts = {
        for (final account in state.accounts) account.id: account,
      };
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.transfers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final transfer = state.transfers[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.swap_horiz_rounded),
              ),
              title: Text(
                '${names[transfer.fromAccountId] ?? 'Unknown'} → '
                '${names[transfer.toAccountId] ?? 'Unknown'}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('d MMM yyyy').format(transfer.date)}'
                    '${transfer.note.isEmpty ? '' : ' • ${transfer.note}'}',
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _transferAmount(
                      transfer,
                      accounts[transfer.fromAccountId],
                      accounts[transfer.toAccountId],
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              trailing: PopupMenuButton<void>(
                tooltip: 'Transfer actions',
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => _confirmDelete(context, transfer),
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Future<void> _confirmDelete(
    BuildContext context,
    AccountTransfer transfer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transfer?'),
        content: const Text('Both affected account balances will be restored.'),
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
      context.read<AccountBloc>().add(DeleteTransferRequested(transfer.id));
    }
  }
}

Future<void> showTransferSheet(BuildContext context) async {
  final bloc = context.read<AccountBloc>();
  AccountState state = bloc.state;
  if (state is! AccountLoaded) {
    bloc.loadIfNeeded();
    state = await bloc.stream.firstWhere(
      (state) => state is AccountLoaded || state is AccountFailure,
    );
    if (!context.mounted) return;
  }
  if (state is! AccountLoaded) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to load accounts. Try again.')),
    );
    return;
  }
  final loaded = state;
  if (loaded.accounts.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create at least two accounts first.')),
    );
    return;
  }
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final receivedAmount = TextEditingController();
  final note = TextEditingController();
  String from = loaded.accounts.first.id;
  String to = loaded.accounts[1].id;
  DateTime date = DateTime.now();
  var isSubmitting = false;
  final currencyState = context.read<CurrencyCubit>().state;

  FinanceAccount accountFor(String id) =>
      loaded.accounts.firstWhere((account) => account.id == id);

  void updateReceivedAmount() {
    final parsed = double.tryParse(amount.text);
    if (parsed == null) {
      receivedAmount.clear();
      return;
    }
    try {
      receivedAmount.text = currencyState
          .convert(
            parsed,
            accountFor(from).currencyCode,
            accountFor(to).currencyCode,
          )
          .toStringAsFixed(2);
    } catch (_) {
      receivedAmount.clear();
    }
  }

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
                  'New transfer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                _accountField('From account', from, loaded.accounts, (value) {
                  setState(() {
                    from = value!;
                    if (to == from) {
                      to = loaded.accounts.firstWhere((a) => a.id != from).id;
                    }
                    updateReceivedAmount();
                  });
                }),
                const SizedBox(height: 12),
                _accountField('To account', to, loaded.accounts, (value) {
                  setState(() {
                    to = value!;
                    updateReceivedAmount();
                  });
                }, excludedId: from),
                const SizedBox(height: 12),
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
                  onChanged: (_) => setState(updateReceivedAmount),
                  decoration: InputDecoration(
                    labelText: 'Amount sent (${accountFor(from).currencyCode})',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    return parsed == null || parsed <= 0
                        ? 'Enter a valid amount'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                if (accountFor(from).currencyCode !=
                    accountFor(to).currencyCode) ...[
                  TextFormField(
                    controller: receivedAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          'Amount received (${accountFor(to).currencyCode})',
                      helperText:
                          'Calculated from your saved rate; adjust for fees or the actual bank rate.',
                      prefixIcon: const Icon(Icons.currency_exchange_rounded),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      return parsed == null || parsed <= 0
                          ? 'Enter the received amount'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
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
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) setState(() => date = selected);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Transfer date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('d MMM yyyy').format(date)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(key.currentState?.validate() ?? false)) return;
                          setState(() => isSubmitting = true);
                          FocusScope.of(context).unfocus();
                          final transferId = DateTime.now()
                              .microsecondsSinceEpoch
                              .toString();
                          bloc.add(
                            SaveTransferRequested(
                              AccountTransfer(
                                id: transferId,
                                fromAccountId: from,
                                toAccountId: to,
                                amount: double.parse(amount.text),
                                receivedAmount:
                                    accountFor(from).currencyCode ==
                                        accountFor(to).currencyCode
                                    ? double.parse(amount.text)
                                    : double.parse(receivedAmount.text),
                                date: date,
                                note: note.text.trim(),
                              ),
                            ),
                          );
                          final result = await bloc.stream.firstWhere(
                            (state) =>
                                state is AccountFailure ||
                                state is AccountLoaded &&
                                    state.transfers.any(
                                      (item) => item.id == transferId,
                                    ),
                          );
                          if (!context.mounted) return;
                          if (result is AccountLoaded) {
                            Navigator.pop(context);
                          } else {
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (result as AccountFailure).message,
                                ),
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz_rounded),
                  label: Text(
                    isSubmitting ? 'Transferring…' : 'Transfer money',
                  ),
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
  receivedAmount.dispose();
  note.dispose();
}

String _transferAmount(
  AccountTransfer transfer,
  FinanceAccount? from,
  FinanceAccount? to,
) {
  final source = MoneyFormatter.format(
    transfer.amount,
    from?.currencyCode ?? 'BDT',
  );
  if (from?.currencyCode == to?.currencyCode) return source;
  return '$source → ${MoneyFormatter.format(transfer.receivedAmount, to?.currencyCode ?? 'BDT')}';
}

DropdownButtonFormField<String> _accountField(
  String label,
  String value,
  List<FinanceAccount> accounts,
  ValueChanged<String?> onChanged, {
  String? excludedId,
}) => DropdownButtonFormField<String>(
  initialValue: value,
  decoration: InputDecoration(labelText: label),
  items: accounts
      .where((account) => account.id != excludedId)
      .map(
        (account) =>
            DropdownMenuItem(value: account.id, child: Text(account.name)),
      )
      .toList(),
  onChanged: onChanged,
);
