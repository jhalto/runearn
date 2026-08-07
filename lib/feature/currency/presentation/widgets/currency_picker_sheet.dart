import 'package:flutter/material.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';

Future<String?> showCurrencyPickerSheet(
  BuildContext context, {
  required List<CurrencyDefinition> currencies,
  required String selectedCode,
  required String title,
}) {
  var query = '';
  final sorted = List<CurrencyDefinition>.of(currencies)
    ..sort((left, right) => left.name.compareTo(right.name));
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final matches = sorted
            .where((currency) => currency.matches(query))
            .toList(growable: false);
        return FractionallySizedBox(
          heightFactor: .88,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search country, currency, or code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: matches.isEmpty
                      ? const Center(
                          child: Text('No matching currencies found.'),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: matches.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final currency = matches[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  currency.symbol,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                ),
                              ),
                              title: Text(
                                '${currency.code} — ${currency.name}',
                              ),
                              subtitle: currency.countries.isEmpty
                                  ? null
                                  : Text(
                                      currency.countryLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: currency.code == selectedCode
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.pop<String>(
                                sheetContext,
                                currency.code,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
