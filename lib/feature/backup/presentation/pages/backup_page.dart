import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/di/injection_container.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_bloc.dart';
import 'package:runearn/feature/accounts/presentation/bloc/account_event.dart';
import 'package:runearn/feature/backup/data/backup_file_service.dart';
import 'package:runearn/feature/backup/domain/entities/backup_result.dart';
import 'package:runearn/feature/backup/presentation/cubit/backup_cubit.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_bloc.dart';
import 'package:runearn/feature/budgets/presentation/bloc/budget_event.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_bloc.dart';
import 'package:runearn/feature/goals/presentation/bloc/goal_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_bloc.dart';
import 'package:runearn/feature/recurring/presentation/bloc/recurring_event.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';

enum _ExportAction { share, save }

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final importController = TextEditingController();
  final backupPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final restorePasswordController = TextEditingController();
  bool showBackupPassword = false;
  bool showRestorePassword = false;
  String? selectedBackupName;
  _ExportAction exportAction = _ExportAction.share;
  final BackupFileService fileService = const BackupFileService();

  @override
  void dispose() {
    importController.dispose();
    backupPasswordController.dispose();
    confirmPasswordController.dispose();
    restorePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      currentRoute: Routes.backup,
      title: 'Backup & Export',
      body: SafeArea(
        child: BlocConsumer<BackupCubit, BackupState>(
          listener: (context, state) async {
            if (state case BackupTextReady(:final text, :final format)) {
              try {
                final csv = format == 'Transactions CSV';
                final requestedAction = exportAction;
                final completed = requestedAction == _ExportAction.save
                    ? await fileService.saveExport(content: text, csv: csv)
                    : await _shareExport(text, csv);
                exportAction = _ExportAction.share;
                if (!completed) return;
                backupPasswordController.clear();
                confirmPasswordController.clear();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      requestedAction == _ExportAction.save
                          ? '$format saved successfully'
                          : '$format file created successfully',
                    ),
                  ),
                );
              } catch (error) {
                exportAction = _ExportAction.share;
                if (!context.mounted) return;
                _showMessage(context, _errorMessage(error));
              }
            }
            if (state case BackupRestored(:final result)) {
              _reloadFinanceState();
              importController.clear();
              restorePasswordController.clear();
              setState(() => selectedBackupName = null);
              await _showRestoreResult(context, result);
              if (!context.mounted) return;
            }
            if (state case BackupFailed(:final message)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            final working = state is BackupWorking;
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SecurityNotice(),
                            const SizedBox(height: 12),
                            const _BackupCoverageCard(),
                            const SizedBox(height: 18),
                            Text(
                              'Create a backup',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create an encrypted file that you can save locally, '
                              'send to another device, or keep in cloud storage.',
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: backupPasswordController,
                              enabled: !working,
                              obscureText: !showBackupPassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: 'Backup password',
                                helperText: 'At least 10 characters',
                                prefixIcon: const Icon(Icons.password_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () =>
                                        showBackupPassword = !showBackupPassword,
                                  ),
                                  icon: Icon(
                                    showBackupPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: confirmPasswordController,
                              enabled: !working,
                              obscureText: !showBackupPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onSubmitted: (_) => _createBackup(context),
                              decoration: const InputDecoration(
                                labelText: 'Confirm backup password',
                                prefixIcon: Icon(Icons.password_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ActionCard(
                              icon: Icons.enhanced_encryption_outlined,
                              title: 'Encrypted full backup',
                              description:
                                  'Protects accounts, transactions, loans, budgets, '
                                  'goals, contributions, and recurring schedules '
                                  'with your password.',
                              buttonLabel: 'Create & share backup',
                              buttonIcon: Icons.ios_share_rounded,
                              onPressed: working
                                  ? null
                                  : () => _createBackup(context),
                              secondaryButtonLabel: 'Save to device',
                              secondaryButtonIcon: Icons.download_rounded,
                              onSecondaryPressed: working
                                  ? null
                                  : () => _createBackup(
                                      context,
                                      action: _ExportAction.save,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            _ActionCard(
                              icon: Icons.table_view_outlined,
                              title: 'Transaction CSV',
                              description:
                                  'Creates a spreadsheet-compatible transaction '
                                  'file for reporting or archiving. CSV is not encrypted.',
                              buttonLabel: 'Export CSV file',
                              buttonIcon: Icons.file_download_outlined,
                              onPressed: working
                                  ? null
                                  : context.read<BackupCubit>().exportCsv,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Restore a backup',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Paste a RunEarn encrypted backup below and enter its '
                              'password. Older plaintext backups can still be '
                              'restored during this migration period.',
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final chooseFileButton = OutlinedButton.icon(
                                  onPressed: working
                                      ? null
                                      : () => _chooseBackupFile(context),
                                  icon: const Icon(Icons.folder_open_rounded),
                                  label: const Text('Choose backup file'),
                                );
                                final pasteButton = OutlinedButton.icon(
                                  onPressed: working
                                      ? null
                                      : () => _pasteBackup(context),
                                  icon: const Icon(Icons.content_paste_rounded),
                                  label: const Text('Paste'),
                                );
        
                                if (constraints.maxWidth < 440) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      chooseFileButton,
                                      const SizedBox(height: 10),
                                      pasteButton,
                                    ],
                                  );
                                }
        
                                return Row(
                                  children: [
                                    Expanded(child: chooseFileButton),
                                    const SizedBox(width: 10),
                                    Expanded(child: pasteButton),
                                  ],
                                );
                              },
                            ),
                            if (selectedBackupName != null) ...[
                              const SizedBox(height: 10),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                leading: const Icon(
                                  Icons.insert_drive_file_outlined,
                                ),
                                title: Text(
                                  selectedBackupName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: const Text('Ready to validate'),
                                trailing: IconButton(
                                  tooltip: 'Remove file',
                                  onPressed: working
                                      ? null
                                      : () => setState(() {
                                          selectedBackupName = null;
                                          importController.clear();
                                        }),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: importController,
                              minLines: selectedBackupName == null ? 5 : 2,
                              maxLines: selectedBackupName == null ? 10 : 3,
                              enabled: !working,
                              readOnly: selectedBackupName != null,
                              decoration: InputDecoration(
                                labelText: 'Backup content',
                                hintText:
                                    'Choose a .runearn file or paste backup JSON',
                                alignLabelWithHint: true,
                                helperText: selectedBackupName == null
                                    ? 'Encrypted .runearn and legacy JSON backups are supported'
                                    : 'Loaded from $selectedBackupName',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: restorePasswordController,
                              enabled: !working,
                              obscureText: !showRestorePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Backup password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => showRestorePassword =
                                        !showRestorePassword,
                                  ),
                                  icon: Icon(
                                    showRestorePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: working
                                  ? null
                                  : () => _confirmRestore(context),
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('Validate and restore'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (state case BackupWorking(:final operation))
                  ColoredBox(
                    color: Colors.black.withValues(alpha: .25),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 14),
                              Text(operation),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final source = importController.text.trim();
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste a JSON backup first')),
      );
      return;
    }
    if (source.length > BackupFileService.maxImportBytes) {
      _showMessage(context, 'Backup files must be smaller than 25 MB.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text(
          'The backup will be validated first. Matching record IDs will be '
          'updated and new records will be added. Current unmatched records '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<BackupCubit>().restore(
        source,
        restorePasswordController.text,
      );
    }
  }

  Future<void> _chooseBackupFile(BuildContext context) async {
    try {
      final picked = await fileService.pickBackup();
      if (picked == null || !mounted) return;
      setState(() {
        selectedBackupName = picked.name;
        importController.text = picked.content;
      });
    } catch (error) {
      if (context.mounted) _showMessage(context, _errorMessage(error));
    }
  }

  Future<void> _pasteBackup(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!context.mounted) return;
    if (text.isEmpty) {
      _showMessage(context, 'Clipboard does not contain a backup.');
      return;
    }
    setState(() {
      selectedBackupName = null;
      importController.text = text;
    });
  }

  Future<bool> _shareExport(String text, bool csv) async {
    await fileService.shareExport(content: text, csv: csv);
    return true;
  }

  void _createBackup(
    BuildContext context, {
    _ExportAction action = _ExportAction.share,
  }) {
    final password = backupPasswordController.text;
    if (password.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a backup password with at least 10 characters'),
        ),
      );
      return;
    }
    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup passwords do not match')),
      );
      return;
    }
    exportAction = action;
    context.read<BackupCubit>().createBackup(password);
  }
}

class _SecurityNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Local financial values are encrypted with a device-protected '
              'key. Backups use a separate password that RunEarn cannot '
              'recover. Keep that password somewhere safe.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _BackupCoverageCard extends StatelessWidget {
  const _BackupCoverageCard();

  static const labels = [
    'Accounts & transfers',
    'Income & expenses',
    'Loans & repayments',
    'Budgets & goals',
    'Bills & recurring',
    'Tours',
    'Currency settings',
  ];

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Included in a full backup',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels)
                Chip(
                  avatar: const Icon(Icons.check_rounded, size: 17),
                  label: Text(label),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    this.onSecondaryPressed,
  });
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onPressed;
  final String? secondaryButtonLabel;
  final IconData? secondaryButtonIcon;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final primary = FilledButton.tonalIcon(
                      onPressed: onPressed,
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                    );
                    final secondaryLabel = secondaryButtonLabel;
                    final secondaryIcon = secondaryButtonIcon;
                    if (secondaryLabel == null || secondaryIcon == null) {
                      return primary;
                    }
                    final secondary = OutlinedButton.icon(
                      onPressed: onSecondaryPressed,
                      icon: Icon(secondaryIcon),
                      label: Text(secondaryLabel),
                    );
                    if (constraints.maxWidth < 520) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          primary,
                          const SizedBox(height: 10),
                          secondary,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: primary),
                        const SizedBox(width: 10),
                        Expanded(child: secondary),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showRestoreResult(
  BuildContext context,
  BackupResult result,
) async {
  final rows = <(String, int)>[
    ('Accounts', result.accounts),
    ('Transfers', result.transfers),
    ('Transactions', result.transactions),
    ('Loans', result.loans),
    ('Loan payments', result.loanPayments),
    ('Budgets', result.budgets),
    ('Goals', result.goals),
    ('Goal contributions', result.goalContributions),
    ('Recurring schedules', result.recurring),
    ('Tours', result.tours),
    ('Tour collections', result.tourCollections),
    ('Tour expenses', result.tourExpenses),
  ].where((row) => row.$2 > 0).toList(growable: false);
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.check_circle_outline_rounded),
      title: const Text('Restore completed'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${result.total} records were restored successfully.'),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.$1)),
                      Text(
                        row.$2.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _errorMessage(Object error) =>
    error.toString().replaceFirst('FormatException: ', '');

void _reloadFinanceState() {
  sl<AccountBloc>().add(const LoadAccounts());
  sl<TransactionBloc>().add(const LoadTransactions());
  sl<LoanBloc>().add(const LoadLoans());
  sl<BudgetBloc>().add(const LoadBudgets());
  sl<GoalBloc>().add(const LoadGoals());
  sl<RecurringBloc>().add(const LoadRecurring());
  sl<TourBloc>().add(const LoadTours());
  sl<CurrencyCubit>().load();
}
