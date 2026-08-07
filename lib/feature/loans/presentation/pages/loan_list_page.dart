import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/loans/domain/entities/loan.dart';
import 'package:runearn/feature/loans/domain/entities/loan_direction.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_bloc.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_event.dart';
import 'package:runearn/feature/loans/presentation/bloc/loan_state.dart';
import 'package:runearn/feature/loans/presentation/widgets/add_loan_sheet.dart';

class LoanListPage extends StatelessWidget {
  final LoanDirection direction;

  const LoanListPage({super.key, required this.direction});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthUnauthenticated,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const AppBackButton(),
          title: Text(direction.title),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAddLoanSheet(context, direction),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
        body: BlocConsumer<LoanBloc, LoanState>(
          listenWhen: (previous, current) => current is LoanFailure,
          listener: (context, state) {
            if (state case LoanFailure(:final message)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) => switch (state) {
            LoanInitial() ||
            LoanLoading() => const Center(child: CircularProgressIndicator()),
            LoanLoaded() => _LoanContent(direction: direction, state: state),
            LoanFailure() => _ErrorView(
              onRetry: () => context.read<LoanBloc>().add(const LoadLoans()),
            ),
          },
        ),
      ),
    );
  }
}

class _LoanContent extends StatelessWidget {
  final LoanDirection direction;
  final LoanLoaded state;

  const _LoanContent({required this.direction, required this.state});

  @override
  Widget build(BuildContext context) {
    final loans = state.forDirection(direction);
    final outstanding = state.outstandingFor(direction);
    return RefreshIndicator(
      onRefresh: () async {
        context.read<LoanBloc>().add(const LoadLoans());
        await context.read<LoanBloc>().stream.firstWhere(
          (state) => state is LoanLoaded || state is LoanFailure,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverToBoxAdapter(
              child: _SummaryCard(
                direction: direction,
                outstanding: outstanding,
                activeCount: loans
                    .where((loan) => state.remainingFor(loan) > 0)
                    .length,
              ),
            ),
          ),
          if (loans.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyView(direction: direction),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: loans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _LoanCard(
                  loan: loans[index],
                  remaining: state.remainingFor(loans[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final LoanDirection direction;
  final double outstanding;
  final int activeCount;

  const _SummaryCard({
    required this.direction,
    required this.outstanding,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Icon(
                direction == LoanDirection.lent
                    ? Icons.call_made_rounded
                    : Icons.call_received_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '৳${NumberFormat('#,##0.##').format(outstanding)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Text(
              '$activeCount active',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final double remaining;

  const _LoanCard({required this.loan, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue =
        !loan.isSettled && loan.dueAt != null && loan.dueAt!.isBefore(today);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Checkbox(
                value: loan.isSettled,
                onChanged: (_) =>
                    context.read<LoanBloc>().add(LoanSettlementChanged(loan)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loan.personName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: loan.isSettled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          '৳${NumberFormat('#,##0.##').format(remaining)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(isOverdue),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue ? theme.colorScheme.error : null,
                      ),
                    ),
                    if (loan.note.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        loan.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_LoanAction>(
                onSelected: (action) {
                  switch (action) {
                    case _LoanAction.view:
                      _openDetails(context);
                    case _LoanAction.edit:
                      showEditLoanSheet(context, loan);
                    case _LoanAction.toggleSettlement:
                      context.read<LoanBloc>().add(LoanSettlementChanged(loan));
                    case _LoanAction.delete:
                      _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _LoanAction.view,
                    child: Text('View details'),
                  ),
                  const PopupMenuItem(
                    value: _LoanAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _LoanAction.toggleSettlement,
                    child: Text(
                      loan.isSettled ? 'Mark active' : 'Mark settled',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _LoanAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(bool isOverdue) {
    final issued = DateFormat('dd MMM yyyy').format(loan.issuedAt);
    if (loan.isSettled) return 'Settled • $issued';
    if (loan.dueAt == null) return 'Added $issued';
    final due = DateFormat('dd MMM yyyy').format(loan.dueAt!);
    return '${isOverdue ? 'Overdue' : 'Due'} $due';
  }

  void _openDetails(BuildContext context) {
    Navigator.pushNamed(context, Routes.loanDetails, arguments: loan);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text('Remove the record for ${loan.personName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<LoanBloc>().add(DeleteLoanRequested(loan.id));
    }
  }
}

enum _LoanAction { view, edit, toggleSettlement, delete }

class _EmptyView extends StatelessWidget {
  final LoanDirection direction;

  const _EmptyView({required this.direction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              direction.emptyMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap Add to create your first record.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56),
            const SizedBox(height: 12),
            const Text('Could not load loans'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
