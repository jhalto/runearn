import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';

import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_split.dart';
import 'package:runearn/feature/transactions/domain/services/local_receipt_service.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/widgets/local_receipt_field.dart';
import 'package:runearn/feature/transactions/presentation/widgets/transaction_tags_field.dart';
import 'package:runearn/feature/transactions/presentation/widgets/transaction_split_field.dart';

class EditTransactionView extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionView({super.key, required this.transaction});

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _selectedType;
  late dynamic _selectedCategory;
  String? _customCategory;
  String? _selectedAccountId;
  late DateTime _selectedDate;
  String? _localReceiptPath;
  late List<String> _tags;
  late List<TransactionSplit> _splits;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(0),
    );

    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );

    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _customCategory = widget.transaction.customCategory;
    _selectedAccountId = widget.transaction.accountId;
    _selectedDate = widget.transaction.date;
    _localReceiptPath = widget.transaction.localReceiptPath;
    _tags = List.of(widget.transaction.tags);
    _splits = List.of(widget.transaction.splits);
  }

  List<TransactionCategory> get _incomeCategories => const [
    TransactionCategory.salary,
    TransactionCategory.freelance,
    TransactionCategory.business,
    TransactionCategory.commission,
    TransactionCategory.bonus,
    TransactionCategory.overtime,
    TransactionCategory.tips,
    TransactionCategory.investment,
    TransactionCategory.dividend,
    TransactionCategory.interest,
    TransactionCategory.rentIncome,
    TransactionCategory.assetSale,
    TransactionCategory.cryptoProfit,
    TransactionCategory.stockProfit,
    TransactionCategory.gift,
    TransactionCategory.refund,
    TransactionCategory.cashback,
    TransactionCategory.reward,
    TransactionCategory.prize,
    TransactionCategory.allowance,
    TransactionCategory.pension,
    TransactionCategory.grant,
    TransactionCategory.scholarship,
    TransactionCategory.loanReceived,
    TransactionCategory.debtCollected,
    TransactionCategory.insuranceClaim,
    TransactionCategory.taxRefund,
    TransactionCategory.other,
  ];

  List<TransactionCategory> get _expenseCategories => const [
    TransactionCategory.food,
    TransactionCategory.groceries,
    TransactionCategory.restaurant,
    TransactionCategory.coffee,
    TransactionCategory.transport,
    TransactionCategory.fuel,
    TransactionCategory.parking,
    TransactionCategory.rideSharing,
    TransactionCategory.vehicleMaintenance,
    TransactionCategory.rent,
    TransactionCategory.mortgage,
    TransactionCategory.utilities,
    TransactionCategory.electricity,
    TransactionCategory.water,
    TransactionCategory.gas,
    TransactionCategory.internet,
    TransactionCategory.phone,
    TransactionCategory.homeMaintenance,
    TransactionCategory.shopping,
    TransactionCategory.clothing,
    TransactionCategory.personalCare,
    TransactionCategory.entertainment,
    TransactionCategory.subscriptions,
    TransactionCategory.travel,
    TransactionCategory.hotel,
    TransactionCategory.vacation,
    TransactionCategory.healthcare,
    TransactionCategory.medicine,
    TransactionCategory.doctor,
    TransactionCategory.hospital,
    TransactionCategory.fitness,
    TransactionCategory.insurance,
    TransactionCategory.education,
    TransactionCategory.tuition,
    TransactionCategory.books,
    TransactionCategory.course,
    TransactionCategory.examFee,
    TransactionCategory.family,
    TransactionCategory.childCare,
    TransactionCategory.pets,
    TransactionCategory.donation,
    TransactionCategory.charity,
    TransactionCategory.religious,
    TransactionCategory.wedding,
    TransactionCategory.event,
    TransactionCategory.savings,
    TransactionCategory.investmentExpense,
    TransactionCategory.loanRepayment,
    TransactionCategory.debtPayment,
    TransactionCategory.creditCardPayment,
    TransactionCategory.bankFee,
    TransactionCategory.tax,
    TransactionCategory.fine,
    TransactionCategory.penalty,
    TransactionCategory.office,
    TransactionCategory.software,
    TransactionCategory.hosting,
    TransactionCategory.domain,
    TransactionCategory.marketing,
    TransactionCategory.staffSalary,
    TransactionCategory.businessTravel,
    TransactionCategory.transfer,
    TransactionCategory.adjustment,
    TransactionCategory.other,
  ];

  List<TransactionCategory> get _currentCategories {
    return _selectedType == TransactionType.income
        ? _incomeCategories
        : _expenseCategories;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = _selectedType == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Transaction',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    children: [
                      _EditHeader(
                        amountController: _amountController,
                        isIncome: isIncome,
                        color: color,
                      ),

                      const SizedBox(height: 18),

                      _SectionCard(
                        title: 'Transaction Type',
                        child: Row(
                          children: [
                            Expanded(
                              child: _TypeSelector(
                                title: 'Income',
                                icon: Icons.arrow_downward_rounded,
                                color: Colors.green,
                                selected:
                                    _selectedType == TransactionType.income,
                                onTap: () {
                                  setState(() {
                                    _selectedType = TransactionType.income;
                                    _splits = const [];

                                    if (!_incomeCategories.contains(
                                      _selectedCategory,
                                    )) {
                                      _selectedCategory =
                                          _incomeCategories.first;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TypeSelector(
                                title: 'Expense',
                                icon: Icons.arrow_upward_rounded,
                                color: Colors.red,
                                selected:
                                    _selectedType == TransactionType.expense,
                                onTap: () {
                                  setState(() {
                                    _selectedType = TransactionType.expense;
                                    _splits = const [];

                                    if (!_expenseCategories.contains(
                                      _selectedCategory,
                                    )) {
                                      _selectedCategory =
                                          _expenseCategories.first;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _SectionCard(
                        title: 'Details',
                        child: Column(
                          children: [
                            _InputField(
                              controller: _descriptionController,
                              label: 'Description',
                              icon: Icons.description_outlined,
                              color: color,
                              maxLines: 3,
                              validator: null,
                            ),

                            const SizedBox(height: 14),

                            BlocBuilder<AccountBloc, AccountState>(
                              builder: (context, accountState) {
                                final accounts = accountState is AccountLoaded
                                    ? accountState.accounts
                                          .where(
                                            (account) =>
                                                account.type.classification ==
                                                    AccountClassification
                                                        .asset ||
                                                account.type.classification ==
                                                    AccountClassification
                                                        .liability,
                                          )
                                          .toList()
                                    : const <FinanceAccount>[];
                                return DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'account-${accounts.map((e) => e.id).join()}-'
                                    '$_selectedAccountId',
                                  ),
                                  initialValue:
                                      accounts.any(
                                        (account) =>
                                            account.id == _selectedAccountId,
                                      )
                                      ? _selectedAccountId
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Account',
                                    prefixIcon: Icon(
                                      Icons.account_balance_wallet_outlined,
                                    ),
                                  ),
                                  items: accounts
                                      .map(
                                        (account) => DropdownMenuItem(
                                          value: account.id,
                                          child: Text(account.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _selectedAccountId = value,
                                  ),
                                  validator: (_) => _selectedAccountId == null
                                      ? 'Select an account'
                                      : null,
                                );
                              },
                            ),

                            const SizedBox(height: 14),

                            _CategoryField(
                              value:
                                  _customCategory ??
                                  (_selectedCategory is TransactionCategory
                                      ? (_selectedCategory
                                                as TransactionCategory)
                                            .label
                                      : _formatCategory(
                                          _selectedCategory
                                              .toString()
                                              .split('.')
                                              .last,
                                        )),
                              color: color,
                              onTap: _showCategoryPicker,
                            ),

                            const SizedBox(height: 14),
                            TransactionSplitField(
                              type: _selectedType,
                              splits: _splits,
                              totalProvider: () =>
                                  double.tryParse(_amountController.text) ?? 0,
                              onChanged: (value) =>
                                  setState(() => _splits = value),
                            ),
                            const SizedBox(height: 14),

                            _DateField(
                              date: _selectedDate,
                              color: color,
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 14),
                            LocalReceiptField(
                              transactionId: widget.transaction.id,
                              path: _localReceiptPath,
                              description: _descriptionController.text,
                              onChanged: (value) =>
                                  setState(() => _localReceiptPath = value),
                            ),
                            const SizedBox(height: 14),
                            TransactionTagsField(
                              tags: _tags,
                              onChanged: (value) =>
                                  setState(() => _tags = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _BottomSaveButton(color: color, onSave: _updateTransaction),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _showCategoryPicker() async {
    final categories = _currentCategories;

    final selected = await showModalBottomSheet<TransactionCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: Theme.of(context).cardColor,
                title: Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: category == _selectedCategory
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedCategory = selected;
      _customCategory = null;
    });
  }

  void _updateTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final splitTotal = _splits.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    if (_splits.isNotEmpty && (splitTotal - amount).abs() > .01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Split amounts must equal the transaction amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedTransaction = widget.transaction.copyWith(
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      customCategory: _customCategory,
      clearCustomCategory: _customCategory == null,
      accountId: _selectedAccountId,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      localReceiptPath: _localReceiptPath,
      clearLocalReceipt: _localReceiptPath == null,
      tags: _tags,
      splits: _splits,
    );

    context.read<TransactionBloc>().add(
      UpdateTransactionEvent(updatedTransaction),
    );
    if (widget.transaction.localReceiptPath != _localReceiptPath) {
      LocalReceiptService().delete(widget.transaction.localReceiptPath);
    }

    Navigator.pop(context, updatedTransaction);
  }

  static String _formatCategory(String value) {
    if (value.isEmpty) return 'General';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}

class _EditHeader extends StatelessWidget {
  final TextEditingController amountController;
  final bool isIncome;
  final Color color;

  const _EditHeader({
    required this.amountController,
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

          const Text(
            'AMOUNT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
              cursorColor: Colors.green,
              decoration: InputDecoration(
                prefixText: '৳',
                prefixStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.65),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount <= 0) {
                  return 'Enter valid amount';
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
          child,
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSelector({
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: selected ? color : Colors.grey,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: color.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.4),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _CategoryField({
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerTile(
      icon: Icons.category_outlined,
      title: 'Category',
      value: value,
      color: color,
      onTap: onTap,
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  const _DateField({
    required this.date,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerTile(
      icon: Icons.calendar_today_outlined,
      title: 'Date',
      value: DateFormat('dd MMM yyyy').format(date),
      color: color,
      onTap: onTap,
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSaveButton extends StatelessWidget {
  final Color color;
  final VoidCallback onSave;

  const _BottomSaveButton({required this.color, required this.onSave});

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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Update Transaction'),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
