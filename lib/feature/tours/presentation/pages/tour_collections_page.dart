import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/tours/domain/entities/tour_collection.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

class TourCollectionsPage extends StatelessWidget {
  const TourCollectionsPage({required this.tourId, super.key});
  final String tourId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const AppBackButton(),
      title: const Text('Money collections'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showTourCollectionEditor(context, tourId),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add collection'),
    ),
    body: BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        if (state is! TourLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = state.collections
            .where((item) => item.tourId == tourId)
            .toList();
        if (entries.isEmpty) {
          return const Center(
            child: Text('No money has been collected for this tour.'),
          );
        }
        final contributors = _groupContributors(entries);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: contributors.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final contributor = contributors[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(contributor.memberName),
                subtitle: Text(
                  '${contributor.paymentCount} '
                  '${contributor.paymentCount == 1 ? 'payment' : 'payments'}'
                  ' • Last ${DateFormat('d MMM y').format(contributor.latestDate)}',
                ),
                trailing: Text(
                  _money(contributor.total),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.tourContributorDetails,
                  arguments: (
                    tourId: tourId,
                    memberName: contributor.memberName,
                  ),
                ),
                onLongPress: () => showTourCollectionEditor(
                  context,
                  tourId,
                  initialMemberName: contributor.memberName,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

List<_ContributorSummary> _groupContributors(List<TourCollection> collections) {
  final groups = <String, List<TourCollection>>{};
  for (final item in collections) {
    final key = item.memberName.trim().toLowerCase();
    groups.putIfAbsent(key, () => []).add(item);
  }
  final result = groups.values.map((items) {
    items.sort((a, b) => b.date.compareTo(a.date));
    return _ContributorSummary(
      memberName: items.first.memberName.trim(),
      paymentCount: items.length,
      total: items.fold(0, (total, item) => total + item.amount),
      latestDate: items.first.date,
    );
  }).toList();
  result.sort((a, b) => b.total.compareTo(a.total));
  return result;
}

class _ContributorSummary {
  const _ContributorSummary({
    required this.memberName,
    required this.paymentCount,
    required this.total,
    required this.latestDate,
  });
  final String memberName;
  final int paymentCount;
  final double total;
  final DateTime latestDate;
}

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
