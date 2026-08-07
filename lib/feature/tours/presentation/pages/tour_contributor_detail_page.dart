import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

class TourContributorDetailPage extends StatelessWidget {
  const TourContributorDetailPage({
    required this.tourId,
    required this.memberName,
    super.key,
  });

  final String tourId;
  final String memberName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const AppBackButton(),
      title: Text(memberName),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showTourCollectionEditor(
        context,
        tourId,
        initialMemberName: memberName,
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add payment'),
    ),
    body: BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        if (state is! TourLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final normalizedName = memberName.trim().toLowerCase();
        final payments =
            state.collections
                .where(
                  (item) =>
                      item.tourId == tourId &&
                      item.memberName.trim().toLowerCase() == normalizedName,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final total = payments.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${payments.length} '
                            '${payments.length == 1 ? 'payment' : 'payments'}',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total paid',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _money(total),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Contribution history',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No contribution history found.'),
                ),
              )
            else
              ...payments.map(
                (payment) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(_money(payment.amount)),
                    subtitle: Text(
                      '${DateFormat('d MMMM y').format(payment.date)}'
                      '${payment.note.isEmpty ? '' : '\n${payment.note}'}',
                    ),
                    isThreeLine: payment.note.isNotEmpty,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          showTourCollectionEditor(
                            context,
                            tourId,
                            collection: payment,
                          );
                        } else {
                          _deletePayment(context, payment);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => showTourCollectionEditor(
                      context,
                      tourId,
                      collection: payment,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _deletePayment(
    BuildContext context,
    TourCollection payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contribution?'),
        content: Text(
          '${_money(payment.amount)} from ${payment.memberName} will be removed.',
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
      context.read<TourBloc>().add(DeleteTourCollectionRequested(payment.id));
    }
  }
}

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
