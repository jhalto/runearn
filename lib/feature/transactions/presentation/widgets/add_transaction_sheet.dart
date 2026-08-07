import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/utils/category_helper.dart';
import 'package:runearn/core/utils/date_picker_helper.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_category.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_split.dart';
import '../../domain/services/local_receipt_service.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import 'local_receipt_field.dart';
import 'transaction_tags_field.dart';
import 'transaction_split_field.dart';

class TransactionSheet {
  const TransactionSheet._();

  static Future<void> showIncome(BuildContext context) {
    return showAddTransactionSheet(
      context,
      initialType: TransactionType.income,
      allowTypeChange: false,
    );
  }

  static Future<void> showExpense(BuildContext context) {
    return showAddTransactionSheet(
      context,
      initialType: TransactionType.expense,
      allowTypeChange: false,
    );
  }
}

/// Backward-compatible launcher for existing Income UI call sites.
Future<void> showAddIncomeSheet(BuildContext context) {
  return TransactionSheet.showIncome(context);
}

/// Backward-compatible launcher for existing Expense UI call sites.
Future<void> showAddExpenseSheet(BuildContext context) {
  return TransactionSheet.showExpense(context);
}

Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionType initialType = TransactionType.expense,
  bool allowTypeChange = true,
}) async {
  DateTime selectedDate = DateTime.now();
  final formKey = GlobalKey<FormState>();
  final bloc = context.read<TransactionBloc>();
  final accountBloc = context.read<AccountBloc>();

  final amountController = TextEditingController();
  final descController = TextEditingController();
  final amountFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();

  TransactionType selectedType = initialType;
  TransactionCategory selectedCategory = CategoryHelper.getByType(
    initialType,
  ).first;
  String? selectedCustomCategory;
  String? selectedAccountId;
  List<TransactionCategory> categories = CategoryHelper.getByType(selectedType);
  bool isSubmitting = false;
  final transactionId = DateTime.now().microsecondsSinceEpoch.toString();
  String? localReceiptPath;
  List<String> tags = const [];
  List<TransactionSplit> splits = const [];
  bool didSave = false;

  Future<void> submit(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    if (isSubmitting) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(amountController.text);
    if (amount == null) return;
    final splitTotal = splits.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    if (splits.isNotEmpty && (splitTotal - amount).abs() > .01) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text('Split amounts must equal the transaction amount.'),
        ),
      );
      return;
    }

    setSheetState(() => isSubmitting = true);
    FocusScope.of(sheetContext).unfocus();

    final description = descController.text.trim().isEmpty
        ? "No Description"
        : descController.text.trim();

    bloc.add(
      AddTransactionEvent(
        Transaction(
          id: transactionId,
          amount: amount,
          type: selectedType,
          category: selectedCategory,
          customCategory: selectedCustomCategory,
          accountId: selectedAccountId,
          description: description,
          date: selectedDate,
          localReceiptPath: localReceiptPath,
          tags: tags,
          splits: splits,
        ),
      ),
    );

    final result = await bloc.stream.firstWhere(
      (state) =>
          state is TransactionError ||
          state is TransactionLoaded &&
              state.transactions.any((item) => item.id == transactionId),
    );

    if (!sheetContext.mounted) return;
    if (result is TransactionLoaded) {
      didSave = true;
      Navigator.pop(sheetContext);
      return;
    }

    setSheetState(() => isSubmitting = false);
    final message = (result as TransactionError).message;
    ScaffoldMessenger.of(
      sheetContext,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: accountBloc),
          ],
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: amountController,
                            focusNode: amountFocusNode,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              descriptionFocusNode.requestFocus();
                            },
                            decoration: const InputDecoration(
                              labelText: "Amount",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter amount";
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return "Enter a valid amount";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: descController,
                            focusNode: descriptionFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(context, setState),
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (allowTypeChange)
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile(
                                    title: const Text("Income"),
                                    value: TransactionType.income,
                                    groupValue: selectedType,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedType = value!;
                                        categories = CategoryHelper.getByType(
                                          selectedType,
                                        );
                                        selectedCategory = categories.first;
                                        selectedCustomCategory = null;
                                        splits = const [];
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile(
                                    title: const Text("Expense"),
                                    value: TransactionType.expense,
                                    groupValue: selectedType,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedType = value!;
                                        categories = CategoryHelper.getByType(
                                          selectedType,
                                        );
                                        selectedCategory = categories.first;
                                        selectedCustomCategory = null;
                                        splits = const [];
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Type',
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedType == TransactionType.income
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedType == TransactionType.income
                                        ? 'Income'
                                        : 'Expense',
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          BlocBuilder<AccountBloc, AccountState>(
                            builder: (context, accountState) {
                              final accounts = accountState is AccountLoaded
                                  ? accountState.accounts
                                        .where(_canUseForTransactions)
                                        .toList()
                                  : const <FinanceAccount>[];
                              if (selectedAccountId == null &&
                                  accounts.isNotEmpty) {
                                selectedAccountId = accounts.first.id;
                              }
                              return DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'account-${accounts.map((e) => e.id).join()}-'
                                  '$selectedAccountId',
                                ),
                                initialValue:
                                    accounts.any(
                                      (account) =>
                                          account.id == selectedAccountId,
                                    )
                                    ? selectedAccountId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Account',
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                hint: Text(
                                  accounts.isEmpty
                                      ? 'Create an account first'
                                      : 'Select account',
                                ),
                                items: accounts
                                    .map(
                                      (account) => DropdownMenuItem(
                                        value: account.id,
                                        child: Text(
                                          '${account.name} • ${account.currencyCode}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: accounts.isEmpty
                                    ? null
                                    : (value) => setState(
                                        () => selectedAccountId = value,
                                      ),
                                validator: (_) => selectedAccountId == null
                                    ? 'Select an account'
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          InkWell(
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              final selection = await _showCategoryPicker(
                                context,
                                selectedType,
                                categories,
                                selectedCategory,
                                selectedCustomCategory,
                              );
                              if (selection == null || !context.mounted) return;
                              setState(() {
                                selectedCategory = selection.category;
                                selectedCustomCategory =
                                    selection.customCategory;
                              });
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                selectedCustomCategory ??
                                    selectedCategory.label,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          TransactionSplitField(
                            type: selectedType,
                            splits: splits,
                            totalProvider: () =>
                                double.tryParse(amountController.text) ?? 0,
                            onChanged: (value) =>
                                setState(() => splits = value),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await DatePickerHelper.pickDate(
                                context,
                                initialDate: selectedDate,
                              );

                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Date",
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          LocalReceiptField(
                            transactionId: transactionId,
                            path: localReceiptPath,
                            description: descController.text,
                            onChanged: (value) =>
                                setState(() => localReceiptPath = value),
                          ),
                          const SizedBox(height: 16),
                          TransactionTagsField(
                            tags: tags,
                            onChanged: (value) => setState(() => tags = value),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => submit(context, setState),
                            child: isSubmitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Add Transaction"),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  } finally {
    if (!didSave) {
      await LocalReceiptService().delete(localReceiptPath);
    }
    // Modal routes can still be animating for a frame after their future
    // completes. Delay disposal so text fields are never painted with disposed
    // controllers/focus nodes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    amountController.dispose();
    descController.dispose();
    amountFocusNode.dispose();
    descriptionFocusNode.dispose();
  }
}

Future<_CategorySelection?> _showCategoryPicker(
  BuildContext context,
  TransactionType type,
  List<TransactionCategory> categories,
  TransactionCategory selected,
  String? selectedCustomCategory,
) async {
  final preferences = await SharedPreferences.getInstance();
  final preferenceKey = 'custom_transaction_categories_${type.name}';
  final customCategories = List<String>.of(
    preferences.getStringList(preferenceKey) ?? const [],
  );
  var query = '';

  if (!context.mounted) return null;

  final result = await showModalBottomSheet<_CategorySelection>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (modalContext) {
      return SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: StatefulBuilder(
            builder: (context, setState) {
              final normalizedQuery = query.toLowerCase();
              final builtInMatches = categories
                  .where(
                    (category) =>
                        category.label.toLowerCase().contains(normalizedQuery),
                  )
                  .toList();
              final customMatches = customCategories
                  .where(
                    (category) =>
                        category.toLowerCase().contains(normalizedQuery),
                  )
                  .toList();
              final allNames = [
                ...categories.map((category) => category.label),
                ...customCategories,
              ];
              final canAdd =
                  query.isNotEmpty &&
                  !allNames.any(
                    (name) => name.toLowerCase() == normalizedQuery,
                  );

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Select or add category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔍 SEARCH
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search or enter a new category...",
                      ),
                      onChanged: (value) {
                        setState(() => query = value.trim());
                      },
                    ),

                    const SizedBox(height: 10),

                    // 📋 LIST (NO FIXED HEIGHT)
                    Expanded(
                      child: ListView(
                        children: [
                          if (canAdd)
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: Text('Add "$query"'),
                              subtitle: Text('New ${type.name} category'),
                              onTap: () async {
                                final categoryName = _formatCustomCategory(
                                  query,
                                );
                                customCategories.add(categoryName);
                                try {
                                  await preferences.setStringList(
                                    preferenceKey,
                                    customCategories,
                                  );
                                } catch (error, stackTrace) {
                                  debugPrint(
                                    'Could not persist custom category: '
                                    '$error\n$stackTrace',
                                  );
                                }
                                if (!context.mounted) return;
                                Navigator.pop(
                                  context,
                                  _CategorySelection(
                                    category: TransactionCategory.other,
                                    customCategory: categoryName,
                                  ),
                                );
                              },
                            ),
                          ...builtInMatches.map(
                            (category) => ListTile(
                              title: Text(category.label),
                              trailing:
                                  selectedCustomCategory == null &&
                                      category == selected
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  _CategorySelection(category: category),
                                );
                              },
                            ),
                          ),
                          ...customMatches.map(
                            (category) => ListTile(
                              leading: const Icon(Icons.label_outline),
                              title: Text(category),
                              trailing: category == selectedCustomCategory
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  _CategorySelection(
                                    category: TransactionCategory.other,
                                    customCategory: category,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!canAdd &&
                              builtInMatches.isEmpty &&
                              customMatches.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('No categories found')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
  return result;
}

class _CategorySelection {
  const _CategorySelection({required this.category, this.customCategory});

  final TransactionCategory category;
  final String? customCategory;
}

bool _canUseForTransactions(FinanceAccount account) {
  return account.type.classification == AccountClassification.asset ||
      account.type.classification == AccountClassification.liability;
}

String _formatCustomCategory(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
