import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/domain/services/account_balance_calculator.dart';
import 'package:runearn/feature/accounts/domain/services/credit_card_calculator.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_state.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({this.currentRoute = Routes.accounts, super.key});
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppBackButton(),
        title: const Text('Accounts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add account'),
      ),
      body: const SafeArea(child: _AccountsContent()),
    );
  }
}

class _AccountsContent extends StatelessWidget {
  const _AccountsContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AccountInitial || state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AccountFailure) {
          return Center(
            child: FilledButton.tonalIcon(
              onPressed: () =>
                  context.read<AccountBloc>().add(const LoadAccounts()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          );
        }
        final loaded = state as AccountLoaded;
        final transactionState = context.watch<TransactionBloc>().state;
        final transactions = transactionState is TransactionLoaded
            ? transactionState.transactions
            : transactionState is TransactionSyncing
            ? transactionState.transactions
            : const <Transaction>[];
        final balances = {
          for (final account in loaded.accounts)
            account.id: AccountBalanceCalculator.calculate(
              account,
              transactions,
              loaded.transfers,
            ),
        };
        return RefreshIndicator(
          onRefresh: () async {
            context.read<AccountBloc>().add(const LoadAccounts());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (loaded.accounts.any(
                (account) => !context.watch<CurrencyCubit>().state.supports(
                  account.currencyCode,
                ),
              )) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const ListTile(
                    leading: Icon(Icons.warning_amber_rounded),
                    title: Text('Exchange rate required'),
                    subtitle: Text(
                      'Some native account balances are excluded from '
                      'consolidated totals. Add their rates in Settings.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _PositionSummary(accounts: loaded.accounts, balances: balances),
              const SizedBox(height: 20),
              if (loaded.accounts.isEmpty)
                const _EmptyAccounts()
              else
                ...AccountClassification.values.map((classification) {
                  final accounts = loaded.accounts
                      .where(
                        (account) =>
                            account.type.classification == classification,
                      )
                      .toList();
                  if (accounts.isEmpty) return const SizedBox.shrink();
                  return _AccountGroup(
                    classification: classification,
                    accounts: accounts,
                    balances: balances,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _PositionSummary extends StatelessWidget {
  const _PositionSummary({required this.accounts, required this.balances});
  final List<FinanceAccount> accounts;
  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyCubit>().state;
    final colors = Theme.of(context).colorScheme;
    final assets = _total(AccountClassification.asset, currency);
    final liabilities = _total(AccountClassification.liability, currency);
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Net Worth', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              MoneyFormatter.format(
                assets - liabilities,
                currency.baseCurrency,
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    context,
                    'Assets',
                    assets,
                    currency.baseCurrency,
                  ),
                ),
                Expanded(
                  child: _metric(
                    context,
                    'Liabilities',
                    liabilities,
                    currency.baseCurrency,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _total(AccountClassification classification, CurrencyState currency) =>
      accounts
          .where((account) => account.type.classification == classification)
          .fold(
            0,
            (sum, account) =>
                sum +
                (currency.supports(account.currencyCode)
                    ? currency.toBase(
                        balances[account.id] ?? 0,
                        account.currencyCode,
                      )
                    : 0),
          );

  Widget _metric(
    BuildContext context,
    String label,
    double value,
    String currencyCode,
  ) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(
        MoneyFormatter.format(value, currencyCode),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({
    required this.classification,
    required this.accounts,
    required this.balances,
  });
  final AccountClassification classification;
  final List<FinanceAccount> accounts;
  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            classification.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < accounts.length; index++) ...[
                  ListTile(
                    leading: CircleAvatar(
                      child: Icon(_icon(accounts[index].type), size: 20),
                    ),
                    title: Text(accounts[index].name),
                    subtitle: Text(
                      '${accounts[index].type.label} • '
                      '${accounts[index].currencyCode}',
                    ),
                    trailing: Text(
                      MoneyFormatter.format(
                        balances[accounts[index].id] ?? 0,
                        accounts[index].currencyCode,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () =>
                        showAccountSheet(context, account: accounts[index]),
                  ),
                  if (accounts[index].type == FinanceAccountType.creditCard)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(72, 0, 16, 10),
                      child: Builder(
                        builder: (context) {
                          final summary = CreditCardCalculator.calculate(
                            accounts[index],
                            balances[accounts[index].id] ?? 0,
                          );
                          final due = MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(summary.paymentDueDate);
                          return Text(
                            'Due $due • Minimum '
                            '${MoneyFormatter.format(summary.minimumPayment, accounts[index].currencyCode)}'
                            ' • ${summary.utilizationPercent.toStringAsFixed(0)}% used',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  if (index != accounts.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 14),
        Text('No accounts yet', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text(
          'Add cash, bank, investment, or liability accounts.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Future<void> showAccountSheet(
  BuildContext context, {
  FinanceAccount? account,
}) async {
  final bloc = context.read<AccountBloc>();
  final key = GlobalKey<FormState>();
  final name = TextEditingController(text: account?.name);
  final balance = TextEditingController(
    text: account == null ? '' : account.balance.toStringAsFixed(2),
  );
  final note = TextEditingController(text: account?.note);
  final creditLimit = TextEditingController(
    text: account?.creditLimit?.toStringAsFixed(2) ?? '',
  );
  final statementDay = TextEditingController(
    text: account?.statementDay?.toString() ?? '',
  );
  final paymentDueDay = TextEditingController(
    text: account?.paymentDueDay?.toString() ?? '',
  );
  final minimumPercent = TextEditingController(
    text: (account?.minimumPaymentPercent ?? 5).toStringAsFixed(2),
  );
  final minimumAmount = TextEditingController(
    text: (account?.minimumPaymentAmount ?? 0).toStringAsFixed(2),
  );
  final currencyState = context.read<CurrencyCubit>().state;
  var type = account?.type ?? FinanceAccountType.cash;
  var currencyCode = account?.currencyCode ?? currencyState.baseCurrency;
  var isSubmitting = false;
  var reminderEnabled = account?.paymentReminderEnabled ?? true;
  var reminderDays = account?.paymentReminderDaysBefore ?? 3;
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
                  account == null ? 'Add account' : 'Edit account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Enter an account name'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FinanceAccountType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: FinanceAccountType.values
                      .where((value) => value.isUserCreatable || value == type)
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${value.classification.label} • ${value.label}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currencyCode,
                  decoration: const InputDecoration(
                    labelText: 'Account currency',
                    prefixIcon: Icon(Icons.currency_exchange_rounded),
                  ),
                  items: CurrencyCatalog.supported
                      .where(
                        (currency) =>
                            currencyState.supports(currency.code) ||
                            currency.code == currencyCode,
                      )
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency.code,
                          child: Text('${currency.code} — ${currency.name}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => currencyCode = value);
                    }
                  },
                ),
                if (currencyState.rates.length == 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Add exchange rates in Settings to enable more currencies.',
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: balance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    helperText:
                        'Transactions linked to this account are applied automatically',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) => double.tryParse(value ?? '') == null
                      ? 'Enter a valid balance'
                      : null,
                ),
                if (type == FinanceAccountType.creditCard) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Credit card terms',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _decimalField(
                    controller: creditLimit,
                    label: 'Credit limit',
                    requirePositive: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dayField(
                          controller: statementDay,
                          label: 'Statement day',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dayField(
                          controller: paymentDueDay,
                          label: 'Payment due day',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _decimalField(
                          controller: minimumPercent,
                          label: 'Minimum %',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _decimalField(
                          controller: minimumAmount,
                          label: 'Minimum floor',
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Payment reminder'),
                    subtitle: const Text('Notify before the due date'),
                    value: reminderEnabled,
                    onChanged: (value) =>
                        setState(() => reminderEnabled = value),
                  ),
                  if (reminderEnabled)
                    DropdownButtonFormField<int>(
                      initialValue: reminderDays,
                      decoration: const InputDecoration(
                        labelText: 'Remind me before',
                        prefixIcon: Icon(Icons.notifications_outlined),
                      ),
                      items: const [1, 2, 3, 5, 7]
                          .map(
                            (days) => DropdownMenuItem(
                              value: days,
                              child: Text('$days day${days == 1 ? '' : 's'}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => reminderDays = value);
                        }
                      },
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
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
                          final accountId =
                              account?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString();
                          bloc.add(
                            SaveAccountRequested(
                              FinanceAccount(
                                id: accountId,
                                name: name.text.trim(),
                                type: type,
                                balance: double.parse(balance.text),
                                note: note.text.trim(),
                                currencyCode: currencyCode,
                                createdAt: account?.createdAt ?? DateTime.now(),
                                creditLimit:
                                    type == FinanceAccountType.creditCard
                                    ? double.parse(creditLimit.text)
                                    : null,
                                statementDay:
                                    type == FinanceAccountType.creditCard
                                    ? int.parse(statementDay.text)
                                    : null,
                                paymentDueDay:
                                    type == FinanceAccountType.creditCard
                                    ? int.parse(paymentDueDay.text)
                                    : null,
                                minimumPaymentPercent:
                                    type == FinanceAccountType.creditCard
                                    ? double.parse(minimumPercent.text)
                                    : 5,
                                minimumPaymentAmount:
                                    type == FinanceAccountType.creditCard
                                    ? double.parse(minimumAmount.text)
                                    : 0,
                                paymentReminderEnabled:
                                    type == FinanceAccountType.creditCard &&
                                    reminderEnabled,
                                paymentReminderDaysBefore: reminderDays,
                              ),
                            ),
                          );
                          final result = await bloc.stream.firstWhere(
                            (state) =>
                                state is AccountFailure ||
                                state is AccountLoaded &&
                                    state.accounts.any(
                                      (item) => item.id == accountId,
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
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isSubmitting ? 'Saving account…' : 'Save account',
                  ),
                ),
                if (account != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete account?'),
                          content: Text(
                            'Remove ${account.name}? Existing financial '
                            'records will not be deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      bloc.add(DeleteAccountRequested(account.id));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete account'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  balance.dispose();
  note.dispose();
  creditLimit.dispose();
  statementDay.dispose();
  paymentDueDay.dispose();
  minimumPercent.dispose();
  minimumAmount.dispose();
}

Widget _dayField({
  required TextEditingController controller,
  required String label,
}) => TextFormField(
  controller: controller,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  decoration: InputDecoration(labelText: label),
  validator: (value) {
    final day = int.tryParse(value ?? '');
    return day == null || day < 1 || day > 28 ? 'Use day 1–28' : null;
  },
);

Widget _decimalField({
  required TextEditingController controller,
  required String label,
  bool requirePositive = false,
}) => TextFormField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ],
  decoration: InputDecoration(labelText: label),
  validator: (value) {
    final amount = double.tryParse(value ?? '');
    if (amount == null || amount < 0 || requirePositive && amount == 0) {
      return 'Enter a valid value';
    }
    return null;
  },
);

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
