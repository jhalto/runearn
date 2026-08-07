import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/domain/entities/tour_expense.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';

Future<void> showTourEditor(BuildContext context, {Tour? tour}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TourBloc>(),
        child: _TourEditor(tour: tour),
      ),
    );

Future<void> showTourCollectionEditor(
  BuildContext context,
  String tourId, {
  TourCollection? collection,
  String? initialMemberName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => BlocProvider.value(
    value: context.read<TourBloc>(),
    child: _MoneyEditor(
      tourId: tourId,
      mode: _MoneyEditorMode.collection,
      collection: collection,
      expense: null,
      initialMemberName: initialMemberName,
    ),
  ),
);

Future<void> showTourExpenseEditor(
  BuildContext context,
  String tourId, {
  TourExpense? expense,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => BlocProvider.value(
    value: context.read<TourBloc>(),
    child: _MoneyEditor(
      tourId: tourId,
      mode: _MoneyEditorMode.expense,
      collection: null,
      expense: expense,
      initialMemberName: null,
    ),
  ),
);

enum _MoneyEditorMode { collection, expense }

class _TourEditor extends StatefulWidget {
  const _TourEditor({this.tour});
  final Tour? tour;

  @override
  State<_TourEditor> createState() => _TourEditorState();
}

class _TourEditorState extends State<_TourEditor> {
  final key = GlobalKey<FormState>();
  late final String recordId =
      widget.tour?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
  late final name = TextEditingController(text: widget.tour?.name ?? '');
  late final destination = TextEditingController(
    text: widget.tour?.destination ?? '',
  );
  late final budget = TextEditingController(
    text: widget.tour?.budget.toStringAsFixed(2) ?? '',
  );
  late final note = TextEditingController(text: widget.tour?.note ?? '');
  late DateTime startDate = widget.tour?.startDate ?? DateTime.now();
  late DateTime endDate =
      widget.tour?.endDate ?? DateTime.now().add(const Duration(days: 2));
  late TourStatus status = widget.tour?.status ?? TourStatus.planned;
  bool submitting = false;

  @override
  void dispose() {
    name.dispose();
    destination.dispose();
    budget.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: widget.tour == null ? 'Plan a tour' : 'Edit tour',
    child: Form(
      key: key,
      child: Column(
        children: [
          TextFormField(
            controller: name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Tour name',
              prefixIcon: Icon(Icons.luggage_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: destination,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Planned budget',
              prefixText: '৳ ',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            validator: _positiveAmount,
          ),
          const SizedBox(height: 8),
          _DateTile(
            label: 'Start date',
            date: startDate,
            onTap: () => _pickDate(true),
          ),
          _DateTile(
            label: 'End date',
            date: endDate,
            onTap: () => _pickDate(false),
          ),
          DropdownButtonFormField<TourStatus>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: TourStatus.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_statusLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => status = value ?? status),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 20),
          _SubmitButton(
            loading: submitting,
            idleLabel: widget.tour == null ? 'Create tour' : 'Save changes',
            loadingLabel: 'Saving tour…',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate(bool start) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? startDate : endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        startDate = selected;
        if (endDate.isBefore(startDate)) endDate = startDate;
      } else {
        endDate = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!(key.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    FocusScope.of(context).unfocus();
    final bloc = context.read<TourBloc>();
    bloc.add(
      SaveTourRequested(
        Tour(
          id: recordId,
          name: name.text.trim(),
          destination: destination.text.trim(),
          startDate: startDate,
          endDate: endDate,
          budget: double.parse(budget.text),
          status: status,
          note: note.text.trim(),
        ),
      ),
    );
    final result = await bloc.stream.firstWhere(
      (state) =>
          state is TourFailure ||
          state is TourLoaded && state.tours.any((item) => item.id == recordId),
    );
    if (!mounted) return;
    _finish(result);
  }

  void _finish(TourState result) {
    if (result is TourLoaded) {
      Navigator.pop(context);
    } else {
      setState(() => submitting = false);
      _showError(context, (result as TourFailure).message);
    }
  }
}

class _MoneyEditor extends StatefulWidget {
  const _MoneyEditor({
    required this.tourId,
    required this.mode,
    required this.collection,
    required this.expense,
    required this.initialMemberName,
  });
  final String tourId;
  final _MoneyEditorMode mode;
  final TourCollection? collection;
  final TourExpense? expense;
  final String? initialMemberName;

  bool get isCollection => mode == _MoneyEditorMode.collection;

  @override
  State<_MoneyEditor> createState() => _MoneyEditorState();
}

class _MoneyEditorState extends State<_MoneyEditor> {
  final key = GlobalKey<FormState>();
  late final String recordId =
      widget.collection?.id ??
      widget.expense?.id ??
      DateTime.now().microsecondsSinceEpoch.toString();
  final titleFocusNode = FocusNode();
  final amountFocusNode = FocusNode();
  final noteFocusNode = FocusNode();
  late final title = TextEditingController(
    text:
        widget.collection?.memberName ??
        widget.initialMemberName ??
        widget.expense?.title ??
        '',
  );
  late final amount = TextEditingController(
    text:
        (widget.collection?.amount ?? widget.expense?.amount)?.toStringAsFixed(
          2,
        ) ??
        '',
  );
  late final note = TextEditingController(
    text: widget.collection?.note ?? widget.expense?.note ?? '',
  );
  late String category = widget.expense?.category ?? 'Transport';
  late DateTime date =
      widget.collection?.date ?? widget.expense?.date ?? DateTime.now();
  bool submitting = false;

  static const categories = [
    'Transport',
    'Accommodation',
    'Food',
    'Tickets',
    'Shopping',
    'Emergency',
    'Other',
  ];

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    note.dispose();
    titleFocusNode.dispose();
    amountFocusNode.dispose();
    noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingContributors = widget.isCollection
        ? _existingContributors(context)
        : const <String>[];
    return _SheetFrame(
      title: widget.isCollection ? 'Add money collection' : 'Add tour expense',
      child: Form(
        key: key,
        child: Column(
          children: [
            if (widget.isCollection)
              RawAutocomplete<String>(
                textEditingController: title,
                focusNode: titleFocusNode,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return existingContributors;
                  return existingContributors.where(
                    (name) => name.toLowerCase().contains(query),
                  );
                },
                onSelected: (_) => amountFocusNode.requestFocus(),
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            onFieldSubmitted();
                            amountFocusNode.requestFocus();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Member name',
                            hintText: 'Select existing or enter a new person',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: _required,
                        ),
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 240,
                        maxWidth: 420,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        children: options
                            .map(
                              (name) => ListTile(
                                leading: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                title: Text(name),
                                onTap: () => onSelected(name),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
              )
            else
              TextFormField(
                controller: title,
                focusNode: titleFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Expense title',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                validator: _required,
              ),
            const SizedBox(height: 12),
            if (!widget.isCollection) ...[
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  category = value ?? category;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => amountFocusNode.requestFocus(),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: amount,
              focusNode: amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _positiveAmount,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => noteFocusNode.requestFocus(),
            ),
            const SizedBox(height: 8),
            _DateTile(
              label: widget.isCollection ? 'Collection date' : 'Expense date',
              date: date,
              onTap: _pickDate,
            ),
            TextField(
              controller: note,
              focusNode: noteFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!submitting) _submit();
              },
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            _SubmitButton(
              loading: submitting,
              idleLabel: widget.isCollection
                  ? 'Save collection'
                  : 'Save expense',
              loadingLabel: widget.isCollection
                  ? 'Saving collection…'
                  : 'Saving expense…',
              icon: widget.isCollection
                  ? Icons.add_card_rounded
                  : Icons.receipt_long_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _existingContributors(BuildContext context) {
    final state = context.watch<TourBloc>().state;
    if (state is! TourLoaded) return const [];
    final names = <String, String>{};
    for (final item in state.collections) {
      if (item.tourId != widget.tourId) continue;
      final name = item.memberName.trim();
      if (name.isEmpty) continue;
      names.putIfAbsent(name.toLowerCase(), () => name);
    }
    final result = names.values.toList(growable: false);
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _submit() async {
    if (!(key.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    FocusScope.of(context).unfocus();
    final bloc = context.read<TourBloc>();
    if (widget.isCollection) {
      bloc.add(
        SaveTourCollectionRequested(
          TourCollection(
            id: recordId,
            tourId: widget.tourId,
            memberName: title.text.trim(),
            amount: double.parse(amount.text),
            date: date,
            note: note.text.trim(),
          ),
        ),
      );
    } else {
      bloc.add(
        SaveTourExpenseRequested(
          TourExpense(
            id: recordId,
            tourId: widget.tourId,
            title: title.text.trim(),
            category: category,
            amount: double.parse(amount.text),
            date: date,
            note: note.text.trim(),
          ),
        ),
      );
    }
    final result = await bloc.stream.firstWhere(
      (state) =>
          state is TourFailure ||
          state is TourLoaded &&
              (widget.isCollection
                  ? state.collections.any((item) => item.id == recordId)
                  : state.expenses.any((item) => item.id == recordId)),
    );
    if (!mounted) return;
    if (result is TourLoaded) {
      Navigator.pop(context);
    } else {
      setState(() => submitting = false);
      _showError(context, (result as TourFailure).message);
    }
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.loading,
    required this.idleLabel,
    required this.loadingLabel,
    required this.icon,
    required this.onPressed,
  });
  final bool loading;
  final String idleLabel;
  final String loadingLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: loading ? null : onPressed,
    icon: loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Text(loading ? loadingLabel : idleLabel),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.event_outlined),
    title: Text(label),
    subtitle: Text(DateFormat('d MMMM yyyy').format(date)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String? _positiveAmount(String? value) {
  final amount = double.tryParse(value ?? '');
  return amount == null || amount <= 0 ? 'Enter an amount above zero' : null;
}

String _statusLabel(TourStatus status) => switch (status) {
  TourStatus.planned => 'Planned',
  TourStatus.active => 'Active',
  TourStatus.completed => 'Completed',
  TourStatus.cancelled => 'Cancelled',
};

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
