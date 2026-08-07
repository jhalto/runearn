import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_state.dart';
import 'package:runearn/feature/goals/domain/entities/financial_goal.dart';
import 'package:runearn/feature/goals/domain/entities/goal_contribution.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_event.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_state.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({this.currentRoute = Routes.goals, super.key});
  final String currentRoute;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: currentRoute,
    title: 'Savings Goals',
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showGoalEditor(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('New goal'),
    ),
    body: SafeArea(
      child: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is GoalInitial || state is GoalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalFailure) {
            return Center(
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    context.read<GoalBloc>().add(const LoadGoals()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }
          return _GoalsContent(state: state as GoalLoaded);
        },
      ),
    ),
  );
}

class _GoalsContent extends StatelessWidget {
  const _GoalsContent({required this.state});
  final GoalLoaded state;

  @override
  Widget build(BuildContext context) {
    final target = state.goals.fold<double>(
      0,
      (total, goal) => total + goal.targetAmount,
    );
    final saved = state.goals.fold<double>(
      0,
      (total, goal) => total + state.savedFor(goal.id),
    );
    return RefreshIndicator(
      onRefresh: () async => context.read<GoalBloc>().add(const LoadGoals()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050
              ? 3
              : constraints.maxWidth >= 700
              ? 2
              : 1;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GoalsSummary(
                        target: target,
                        saved: saved,
                        completed: state.goals.where(state.isCompleted).length,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Your goals',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (state.goals.isEmpty)
                        const _EmptyGoals()
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 245,
                              ),
                          itemCount: state.goals.length,
                          itemBuilder: (context, index) {
                            final goal = state.goals[index];
                            return _GoalCard(
                              goal: goal,
                              saved: state.savedFor(goal.id),
                              onOpen: () => _showGoalDetails(
                                context,
                                goal,
                                state.contributionsFor(goal.id),
                              ),
                              onContribute: () =>
                                  _showContributionEditor(context, goal),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsSummary extends StatelessWidget {
  const _GoalsSummary({
    required this.target,
    required this.saved,
    required this.completed,
  });
  final double target;
  final double saved;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL SAVED',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _money(saved),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _summaryMetric('Total target', _money(target))),
              Expanded(child: _summaryMetric('Completed', '$completed goals')),
              Expanded(
                child: _summaryMetric(
                  'Remaining',
                  _money((target - saved).clamp(0, double.infinity)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.saved,
    required this.onOpen,
    required this.onContribute,
  });
  final FinancialGoal goal;
  final double saved;
  final VoidCallback onOpen;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final ratio = goal.targetAmount <= 0 ? 0.0 : saved / goal.targetAmount;
    final completed = ratio >= 1;
    final colors = Theme.of(context).colorScheme;
    final deadlineText = goal.deadline == null
        ? 'No deadline'
        : DateFormat('d MMM yyyy').format(goal.deadline!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: completed
                        ? Colors.green.withValues(alpha: .14)
                        : colors.primaryContainer,
                    child: Icon(
                      completed ? Icons.check_rounded : Icons.flag_outlined,
                      color: completed ? Colors.green : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _money(saved),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text('of ${_money(goal.targetAmount)}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 9,
                borderRadius: BorderRadius.circular(8),
                color: completed ? Colors.green : colors.primary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(child: Text(deadlineText)),
                  Text('${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onContribute,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add savings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first goal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          const Text(
            'Track an emergency fund, a purchase, education, travel, or any future target.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Future<void> showGoalEditor(BuildContext context, {FinancialGoal? goal}) async {
  final name = TextEditingController(text: goal?.name ?? '');
  final amount = TextEditingController(
    text: goal?.targetAmount.toStringAsFixed(2) ?? '',
  );
  final note = TextEditingController(text: goal?.note ?? '');
  final key = GlobalKey<FormState>();
  final bloc = context.read<GoalBloc>();
  var deadline = goal?.deadline;
  var isSubmitting = false;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    goal == null ? 'Create savings goal' : 'Edit savings goal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Goal name',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (value) => value?.trim().isEmpty == true
                        ? 'Enter a goal name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Target amount',
                      prefixText: '৳ ',
                      prefixIcon: Icon(Icons.savings_outlined),
                    ),
                    validator: (value) {
                      final number = double.tryParse(value ?? '');
                      return number == null || number <= 0
                          ? 'Enter an amount greater than zero'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Deadline'),
                    subtitle: Text(
                      deadline == null
                          ? 'Optional'
                          : DateFormat('d MMMM yyyy').format(deadline!),
                    ),
                    trailing: deadline == null
                        ? const Icon(Icons.chevron_right_rounded)
                        : IconButton(
                            onPressed: () =>
                                setSheetState(() => deadline = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 36500),
                        ),
                      );
                      if (selected != null) {
                        setSheetState(() => deadline = selected);
                      }
                    },
                  ),
                  TextFormField(
                    controller: note,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!key.currentState!.validate()) return;
                            setSheetState(() => isSubmitting = true);
                            FocusScope.of(context).unfocus();
                            final goalId =
                                goal?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toString();
                            bloc.add(
                              SaveGoalRequested(
                                FinancialGoal(
                                  id: goalId,
                                  name: name.text.trim(),
                                  targetAmount: double.parse(amount.text),
                                  createdAt: goal?.createdAt ?? DateTime.now(),
                                  deadline: deadline,
                                  note: note.text.trim(),
                                ),
                              ),
                            );
                            final result = await bloc.stream.firstWhere(
                              (state) =>
                                  state is GoalFailure ||
                                  state is GoalLoaded &&
                                      state.goals.any(
                                        (item) => item.id == goalId,
                                      ),
                            );
                            if (!context.mounted) return;
                            if (result is GoalLoaded) {
                              Navigator.pop(sheetContext);
                            } else {
                              setSheetState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    (result as GoalFailure).message,
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
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      isSubmitting
                          ? 'Saving goal…'
                          : goal == null
                          ? 'Create goal'
                          : 'Save changes',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // The modal future completes when pop starts, before its form is fully
  // unmounted. Keep the controllers alive through the reverse animation.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  name.dispose();
  amount.dispose();
  note.dispose();
}

Future<void> _showContributionEditor(
  BuildContext context,
  FinancialGoal goal,
) async {
  final amount = TextEditingController();
  final note = TextEditingController();
  final key = GlobalKey<FormState>();
  final bloc = context.read<GoalBloc>();
  final accountBloc = context.read<AccountBloc>()..loadIfNeeded();
  final accountState = accountBloc.state;
  final fundingAccounts = accountState is AccountLoaded
      ? accountState.accounts
            .where(
              (account) =>
                  account.type.classification == AccountClassification.asset &&
                  !account.id.startsWith('goal_account_'),
            )
            .toList(growable: false)
      : const <FinanceAccount>[];
  String? sourceAccountId = fundingAccounts.isEmpty
      ? null
      : fundingAccounts.first.id;
  var isSubmitting = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add savings',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(goal.name),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: sourceAccountId,
                decoration: const InputDecoration(
                  labelText: 'From account',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: fundingAccounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(
                          '${account.name} • ${account.currencyCode}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: fundingAccounts.isEmpty
                    ? null
                    : (value) => setSheetState(() => sourceAccountId = value),
                validator: (value) =>
                    value == null ? 'Choose a funding account' : null,
              ),
              if (fundingAccounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Add a cash, bank, wallet, or savings account first.',
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '৳ ',
                ),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  return number == null || number <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!key.currentState!.validate()) return;
                        setSheetState(() => isSubmitting = true);
                        FocusScope.of(context).unfocus();
                        final contributionId = DateTime.now()
                            .microsecondsSinceEpoch
                            .toString();
                        final goalAccountId = 'goal_account_${goal.id}';
                        bloc.add(
                          AddGoalContributionRequested(
                            goal,
                            GoalContribution(
                              id: contributionId,
                              goalId: goal.id,
                              amount: double.parse(amount.text),
                              date: DateTime.now(),
                              note: note.text.trim(),
                              sourceAccountId: sourceAccountId,
                              goalAccountId: goalAccountId,
                              transferId: 'goal_transfer_$contributionId',
                            ),
                          ),
                        );
                        final result = await bloc.stream.firstWhere(
                          (state) =>
                              state is GoalFailure ||
                              state is GoalLoaded &&
                                  state.contributions.any(
                                    (item) => item.id == contributionId,
                                  ),
                        );
                        if (!context.mounted) return;
                        if (result is GoalLoaded) {
                          accountBloc.add(const LoadAccounts());
                          Navigator.pop(sheetContext);
                        } else {
                          setSheetState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text((result as GoalFailure).message),
                            ),
                          );
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(isSubmitting ? 'Adding savings…' : 'Add savings'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // Avoid disposing controllers while the closing sheet can still rebuild.
  await Future<void>.delayed(const Duration(milliseconds: 350));
  amount.dispose();
  note.dispose();
}

Future<void> _showGoalDetails(
  BuildContext context,
  FinancialGoal goal,
  List<GoalContribution> contributions,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      maxChildSize: .94,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showGoalEditor(context, goal: goal);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: sheetContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete goal?'),
                      content: const Text(
                        'The goal and its contribution history will be removed.',
                      ),
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
                    context.read<GoalBloc>().add(DeleteGoalRequested(goal.id));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (goal.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(goal.note),
          ],
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showContributionEditor(context, goal);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add savings'),
          ),
          const SizedBox(height: 20),
          Text(
            'Contribution history',
            style: Theme.of(
              sheetContext,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (contributions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No savings added yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < contributions.length;
                    index++
                  ) ...[
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.add_rounded),
                      ),
                      title: Text(_money(contributions[index].amount)),
                      subtitle: Text(
                        contributions[index].note.isEmpty
                            ? DateFormat(
                                'd MMM yyyy',
                              ).format(contributions[index].date)
                            : '${DateFormat('d MMM yyyy').format(contributions[index].date)}'
                                  ' • ${contributions[index].note}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete contribution',
                        onPressed: () {
                          context.read<GoalBloc>().add(
                            DeleteGoalContributionRequested(
                              contributions[index],
                            ),
                          );
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                    if (index < contributions.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _summaryMetric(String label, String value) => Column(
  children: [
    Text(label, style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 3),
    Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  ],
);

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
