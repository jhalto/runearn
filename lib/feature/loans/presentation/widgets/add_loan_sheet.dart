import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/domain/entities/loan_interest_method.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';

Future<void> showAddLoanSheet(
  BuildContext context,
  LoanDirection direction,
) async {
  final bloc = context.read<LoanBloc>();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SafeArea(
      top: false,
      child: _AddLoanForm(bloc: bloc, direction: direction),
    ),
  );
}

Future<void> showEditLoanSheet(BuildContext context, Loan loan) async {
  final bloc = context.read<LoanBloc>();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SafeArea(
      top: false,
      child: _AddLoanForm(
        bloc: bloc,
        direction: loan.direction,
        existingLoan: loan,
      ),
    ),
  );
}

class _AddLoanForm extends StatefulWidget {
  final LoanBloc bloc;
  final LoanDirection direction;
  final Loan? existingLoan;

  const _AddLoanForm({
    required this.bloc,
    required this.direction,
    this.existingLoan,
  });

  @override
  State<_AddLoanForm> createState() => _AddLoanFormState();
}

class _AddLoanFormState extends State<_AddLoanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _personController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _interestRateController;
  late DateTime _issuedAt;
  DateTime? _dueAt;
  bool _isSubmitting = false;
  late LoanInterestMethod _interestMethod;
  late bool _reminderEnabled;
  late int _reminderDaysBefore;

  bool get _isEditing => widget.existingLoan != null;

  @override
  void initState() {
    super.initState();
    final loan = widget.existingLoan;
    _personController = TextEditingController(text: loan?.personName);
    _amountController = TextEditingController(
      text: loan == null ? null : _formatAmount(loan.amount),
    );
    _noteController = TextEditingController(text: loan?.note);
    _interestRateController = TextEditingController(
      text: loan == null || loan.annualInterestRate == 0
          ? ''
          : _formatAmount(loan.annualInterestRate),
    );
    _issuedAt = loan?.issuedAt ?? DateTime.now();
    _dueAt = loan?.dueAt;
    _interestMethod = loan?.interestMethod ?? LoanInterestMethod.none;
    _reminderEnabled = loan?.reminderEnabled ?? true;
    _reminderDaysBefore = loan?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing
                  ? 'Edit ${widget.direction.title}'
                  : 'Add ${widget.direction.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _personController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Person',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the person’s name'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LoanInterestMethod>(
              initialValue: _interestMethod,
              decoration: const InputDecoration(
                labelText: 'Interest calculation',
                prefixIcon: Icon(Icons.percent_rounded),
              ),
              items: [
                for (final method in LoanInterestMethod.values)
                  DropdownMenuItem(value: method, child: Text(method.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _interestMethod = value);
                }
              },
            ),
            if (_interestMethod != LoanInterestMethod.none) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _interestRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Annual interest rate',
                  suffixText: '% per year',
                  prefixIcon: Icon(Icons.trending_up_rounded),
                ),
                validator: (value) {
                  if (_interestMethod == LoanInterestMethod.none) return null;
                  final rate = double.tryParse(value?.trim() ?? '');
                  if (rate == null || rate <= 0 || rate > 100) {
                    return 'Enter an annual rate between 0 and 100';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a valid amount'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Date',
              value: _issuedAt,
              onTap: () => _pickDate(
                initialDate: _issuedAt,
                onSelected: (date) {
                  setState(() {
                    _issuedAt = date;
                    if (_dueAt != null && _dueAt!.isBefore(date)) {
                      _dueAt = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Due date (optional)',
              value: _dueAt,
              onTap: () => _pickDate(
                initialDate: _dueAt ?? _issuedAt,
                firstDate: _issuedAt,
                onSelected: (date) => setState(() => _dueAt = date),
              ),
              onClear: _dueAt == null
                  ? null
                  : () => setState(() => _dueAt = null),
            ),
            if (_dueAt != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repayment reminder'),
                subtitle: const Text(
                  'Notify before the due date and when overdue',
                ),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),
              if (_reminderEnabled)
                DropdownButtonFormField<int>(
                  initialValue: _reminderDaysBefore,
                  decoration: const InputDecoration(
                    labelText: 'Remind me before',
                    prefixIcon: Icon(Icons.notifications_active_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('On due date only')),
                    DropdownMenuItem(value: 1, child: Text('1 day before')),
                    DropdownMenuItem(value: 3, child: Text('3 days before')),
                    DropdownMenuItem(value: 7, child: Text('7 days before')),
                    DropdownMenuItem(value: 14, child: Text('14 days before')),
                    DropdownMenuItem(value: 30, child: Text('30 days before')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _reminderDaysBefore = value);
                    }
                  },
                ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
              label: Text(
                _isSubmitting
                    ? 'Saving loan…'
                    : _isEditing
                    ? 'Save changes'
                    : 'Save loan',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();
    final existing = widget.existingLoan;
    final loan = Loan(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      personName: _personController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      direction: widget.direction,
      note: _noteController.text.trim(),
      issuedAt: _issuedAt,
      dueAt: _dueAt,
      isSettled: existing?.isSettled ?? false,
      interestMethod: _interestMethod,
      annualInterestRate: _interestMethod == LoanInterestMethod.none
          ? 0
          : double.parse(_interestRateController.text.trim()),
      reminderEnabled: _dueAt != null && _reminderEnabled,
      reminderDaysBefore: _reminderDaysBefore,
    );
    widget.bloc.add(
      existing == null ? AddLoanRequested(loan) : UpdateLoanRequested(loan),
    );
    final result = await widget.bloc.stream.firstWhere(
      (state) =>
          state is LoanFailure ||
          state is LoanLoaded && state.loans.any((item) => item.id == loan.id),
    );
    if (!mounted) return;
    if (result is LoanLoaded) {
      Navigator.pop(context);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((result as LoanFailure).message)));
    }
  }

  static String _formatAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(
          value == null ? 'Not set' : DateFormat('dd MMM yyyy').format(value!),
        ),
      ),
    );
  }
}
