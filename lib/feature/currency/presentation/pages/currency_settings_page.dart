import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';
import 'package:runearn/feature/currency/domain/services/money_formatter.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/currency/presentation/widgets/currency_picker_sheet.dart';

class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const AppBackButton(),
      title: const Text('Currencies'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editRate(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add rate'),
    ),
    body: SafeArea(
      child: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final rates = state.rates.values.toList()
            ..sort(
              (left, right) => left.currencyCode.compareTo(right.currencyCode),
            );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Base currency',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Dashboard totals, reports, and net worth are converted '
                        'into this currency.',
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final value = await showCurrencyPickerSheet(
                            context,
                            currencies: CurrencyCatalog.supported,
                            selectedCode: state.baseCurrency,
                            title: 'Select base currency',
                          );
                          if (value == null || !context.mounted) return;
                          try {
                            if (!state.rates.containsKey(value)) {
                              final added = await _editRate(
                                context,
                                initialCode: value,
                              );
                              if (!added || !context.mounted) return;
                            }
                            await context.read<CurrencyCubit>().setBaseCurrency(
                              value,
                            );
                          } catch (error) {
                            if (context.mounted) _showError(context, error);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.public_rounded),
                            labelText: 'Base currency',
                            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                          ),
                          child: Text(_currencyLabel(state.baseCurrency)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Exchange rates',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Each rate means 1 unit of that currency equals the shown '
                '${state.baseCurrency} amount.',
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (var index = 0; index < rates.length; index++) ...[
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            CurrencyCatalog.find(
                              rates[index].currencyCode,
                            ).symbol,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(_currencyLabel(rates[index].currencyCode)),
                        subtitle: Text(
                          rates[index].currencyCode == state.baseCurrency
                              ? 'Base currency'
                              : 'Updated ${DateFormat('d MMM y, h:mm a').format(rates[index].updatedAt.toLocal())}',
                        ),
                        trailing: Text(
                          rates[index].currencyCode == state.baseCurrency
                              ? '1.00'
                              : MoneyFormatter.format(
                                  rates[index].rateToBase,
                                  state.baseCurrency,
                                ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onTap: rates[index].currencyCode == state.baseCurrency
                            ? null
                            : () => _editRate(
                                context,
                                initialCode: rates[index].currencyCode,
                              ),
                      ),
                      if (index != rates.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<bool> _editRate(BuildContext context, {String? initialCode}) async {
  final cubit = context.read<CurrencyCubit>();
  final state = cubit.state;
  final isExisting =
      initialCode != null && state.rates.containsKey(initialCode);
  final available = CurrencyCatalog.supported
      .where(
        (currency) =>
            currency.code != state.baseCurrency &&
            (initialCode == currency.code ||
                !state.rates.containsKey(currency.code)),
      )
      .toList(growable: false);
  if (available.isEmpty && initialCode == null) {
    _showError(context, 'All supported currencies already have rates.');
    return false;
  }
  var code = initialCode ?? available.first.code;
  final controller = TextEditingController(
    text: state.rates[code]?.rateToBase.toString(),
  );
  final key = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        title: Text(isExisting ? 'Update exchange rate' : 'Add exchange rate'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: initialCode != null
                    ? null
                    : () async {
                        final value = await showCurrencyPickerSheet(
                          context,
                          currencies: available,
                          selectedCode: code,
                          title: 'Choose currency',
                        );
                        if (value == null || !context.mounted) return;
                        setState(() {
                          code = value;
                          controller.clear();
                        });
                      },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    suffixIcon: initialCode == null
                        ? const Icon(Icons.search_rounded)
                        : null,
                  ),
                  child: Text(_currencyLabel(code)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,8}')),
                ],
                decoration: InputDecoration(
                  labelText: '1 $code equals',
                  suffixText: state.baseCurrency,
                  helperText: 'Use the rate from your bank or trusted source.',
                ),
                validator: (value) {
                  final rate = double.tryParse(value ?? '');
                  return rate == null || rate <= 0
                      ? 'Enter a rate greater than zero'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save rate'),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    try {
      await cubit.setRate(code, double.parse(controller.text));
    } catch (error) {
      if (context.mounted) _showError(context, error);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
      return false;
    }
  }
  // showDialog completes as soon as pop starts, while its exit animation can
  // still paint the text field for a short time.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return saved == true;
}

String _currencyLabel(String code) {
  final currency = CurrencyCatalog.find(code);
  return '${currency.code} — ${currency.name}';
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
  );
}
