import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/domain/entities/tour_summary.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

class TourDetailPage extends StatelessWidget {
  const TourDetailPage({required this.tourId, super.key});
  final String tourId;

  @override
  Widget build(BuildContext context) => BlocBuilder<TourBloc, TourState>(
    builder: (context, state) {
      final tour = state is TourLoaded
          ? state.tours.where((item) => item.id == tourId).firstOrNull
          : null;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const AppBackButton(),
          title: Text(tour?.name ?? 'Tour summary'),
          actions: [
            if (tour != null)
              IconButton(
                tooltip: 'Edit tour',
                onPressed: () => showTourEditor(context, tour: tour),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        floatingActionButton: tour == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddMenu(context, tour.id),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
        body: state is TourInitial || state is TourLoading
            ? const Center(child: CircularProgressIndicator())
            : tour == null || state is! TourLoaded
            ? const Center(child: Text('Tour not found'))
            : _Summary(summary: state.summaryFor(tour)),
      );
    },
  );

  Future<void> _showAddMenu(BuildContext context, String tourId) async {
    final action = await showModalBottomSheet<_TourAddAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add tour finance entry',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.add_card_rounded),
                  ),
                  title: const Text('Add money collection'),
                  subtitle: const Text('Record a payment from a contributor'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.pop(sheetContext, _TourAddAction.collection),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  title: const Text('Add tour expense'),
                  subtitle: const Text('Record spending for this tour'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      Navigator.pop(sheetContext, _TourAddAction.expense),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _TourAddAction.collection) {
      await showTourCollectionEditor(context, tourId);
    } else {
      await showTourExpenseEditor(context, tourId);
    }
  }
}

enum _TourAddAction { collection, expense }

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});
  final TourSummary summary;

  @override
  Widget build(BuildContext context) {
    final tour = summary.tour;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.destination,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${DateFormat('d MMMM y').format(tour.startDate)} – '
                  '${DateFormat('d MMMM y').format(tour.endDate)}',
                ),
                if (tour.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(tour.note),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _SummaryCard('Budget', tour.budget, Icons.wallet_outlined),
            _SummaryCard(
              'Collected',
              summary.totalCollected,
              Icons.add_card_rounded,
            ),
            _SummaryCard(
              'Expenses',
              summary.totalExpenses,
              Icons.receipt_long_outlined,
            ),
            _SummaryCard(
              'Cash available',
              summary.availableCash,
              Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: summary.budgetUsed.clamp(0, 1),
          minHeight: 10,
          borderRadius: BorderRadius.circular(8),
          color: summary.budgetRemaining < 0
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          summary.budgetRemaining >= 0
              ? '${_money(summary.budgetRemaining)} budget remaining'
              : '${_money(-summary.budgetRemaining)} over budget',
        ),
        const SizedBox(height: 20),
        _ActionCard(
          title: 'Money collections',
          subtitle:
              '${summary.collections.length} entries • '
              '${_money(summary.totalCollected)}',
          icon: Icons.group_outlined,
          onTap: () => Navigator.pushNamed(
            context,
            Routes.tourCollections,
            arguments: tour.id,
          ),
        ),
        _ActionCard(
          title: 'Tour expenses',
          subtitle:
              '${summary.expenses.length} entries • '
              '${_money(summary.totalExpenses)}',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.pushNamed(
            context,
            Routes.tourExpenses,
            arguments: tour.id,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _deleteTour(context, tour),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete tour'),
        ),
      ],
    );
  }

  Future<void> _deleteTour(BuildContext context, Tour tour) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete tour?'),
        content: const Text(
          'The tour, collections, and expense history will be removed.',
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
    if (confirmed != true || !context.mounted) return;
    context.read<TourBloc>().add(DeleteTourRequested(tour.id));
    Navigator.pop(context);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.icon);
  final String label;
  final double value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 7),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            _money(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
