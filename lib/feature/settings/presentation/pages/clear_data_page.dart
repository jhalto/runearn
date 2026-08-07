import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/settings/presentation/cubit/clear_data_cubit.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';

class ClearDataPage extends StatelessWidget {
  const ClearDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      currentRoute: Routes.clearData,
      title: 'Clear Data',
      body: BlocConsumer<ClearDataCubit, ClearDataState>(
        listener: (context, state) {
          if (state case ClearDataSucceeded(:final target)) {
            if (target == ClearDataTarget.loans) {
              context.read<LoanBloc>().add(const LoadLoans());
            } else {
              context.read<TransactionBloc>().add(const LoadTransactions());
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${target.label} cleared')));
          }
          if (state case ClearDataFailed(:final message)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final activeTarget = state is ClearDataInProgress
              ? state.target
              : null;
          final isBusy = activeTarget != null;
          return PopScope(
            canPop: !isBusy,
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: isBusy,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Clearing removes records from this account '
                                  'and synchronizes the deletion. This action '
                                  'cannot be undone inside the app.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          title: const Text('Create a backup first'),
                          subtitle: const Text(
                            'Export a copy before deleting financial records.',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.backup),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Choose what to clear',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _ClearDataTile(
                        target: ClearDataTarget.loans,
                        icon: Icons.handshake_outlined,
                        description: 'Clear all loans given and loans taken.',
                        activeTarget: activeTarget,
                      ),
                      _ClearDataTile(
                        target: ClearDataTarget.income,
                        icon: Icons.trending_up_rounded,
                        description: 'Clear income while keeping expenses.',
                        activeTarget: activeTarget,
                      ),
                      _ClearDataTile(
                        target: ClearDataTarget.expenses,
                        icon: Icons.trending_down_rounded,
                        description: 'Clear expenses while keeping income.',
                        activeTarget: activeTarget,
                      ),
                      _ClearDataTile(
                        target: ClearDataTarget.transactions,
                        icon: Icons.receipt_long_outlined,
                        description:
                            'Clear all income and expense transactions.',
                        activeTarget: activeTarget,
                      ),
                    ],
                  ),
                ),
                if (activeTarget != null)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .35),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 14),
                              Text('Clearing ${activeTarget.label}...'),
                              const SizedBox(height: 4),
                              const Text('Do not close the app.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClearDataTile extends StatelessWidget {
  final ClearDataTarget target;
  final IconData icon;
  final String description;
  final ClearDataTarget? activeTarget;

  const _ClearDataTile({
    required this.target,
    required this.icon,
    required this.description,
    required this.activeTarget,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = activeTarget != null;
    final isActive = activeTarget == target;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(target.label),
        subtitle: Text(description),
        trailing: isActive
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
        enabled: !isBusy,
        onTap: () => _confirm(context),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final account = authState is AuthAuthenticated
        ? authState.user.email ??
              authState.user.displayName ??
              (authState.user.isAnonymous ? 'Guest account' : 'Current account')
        : 'Current account';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ClearConfirmationDialog(
        target: target,
        description: description,
        account: account,
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ClearDataCubit>().clear(target);
    }
  }
}

class _ClearConfirmationDialog extends StatefulWidget {
  const _ClearConfirmationDialog({
    required this.target,
    required this.description,
    required this.account,
  });

  final ClearDataTarget target;
  final String description;
  final String account;

  @override
  State<_ClearConfirmationDialog> createState() =>
      _ClearConfirmationDialogState();
}

class _ClearConfirmationDialogState extends State<_ClearConfirmationDialog> {
  final controller = TextEditingController();
  bool acknowledged = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return AlertDialog(
      icon: Icon(
        Icons.gpp_maybe_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text('Permanently clear ${target.label.toLowerCase()}?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.description),
              const SizedBox(height: 12),
              Text(
                'Account: ${widget.account}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: acknowledged,
                title: const Text(
                  'I understand this deletion cannot be undone.',
                ),
                onChanged: (value) =>
                    setState(() => acknowledged = value ?? false),
              ),
              const SizedBox(height: 8),
              Text(
                'Type ${target.confirmationPhrase} to continue:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: target.confirmationPhrase,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed:
              acknowledged &&
                  controller.text.trim() == target.confirmationPhrase
              ? () => Navigator.pop(context, true)
              : null,
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Permanently clear'),
        ),
      ],
    );
  }
}
