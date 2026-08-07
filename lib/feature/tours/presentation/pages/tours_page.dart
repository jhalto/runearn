import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_page_scaffold.dart';
import 'package:runearn/feature/tours/domain/entities/tour.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

class ToursPage extends StatelessWidget {
  const ToursPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    currentRoute: Routes.tours,
    title: 'Tours',
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showTourEditor(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Plan tour'),
    ),
    body: BlocConsumer<TourBloc, TourState>(
      listenWhen: (_, current) => current is TourFailure,
      listener: (context, state) {
        if (state case TourFailure(:final message)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) => switch (state) {
        TourInitial() ||
        TourLoading() => const Center(child: CircularProgressIndicator()),
        TourFailure() => _Failure(
          onRetry: () => context.read<TourBloc>().add(const LoadTours()),
        ),
        TourLoaded() when state.tours.isEmpty => const _EmptyTours(),
        TourLoaded() => RefreshIndicator(
          onRefresh: () async {
            context.read<TourBloc>().add(const LoadTours());
            await context.read<TourBloc>().stream.firstWhere(
              (state) => state is TourLoaded || state is TourFailure,
            );
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.tours.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tour = state.tours[index];
              final summary = state.summaryFor(tour);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.tourDetails,
                    arguments: tour.id,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(child: Icon(_statusIcon(tour.status))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tour.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${tour.destination} • '
                                    '${DateFormat('d MMM').format(tour.startDate)}–'
                                    '${DateFormat('d MMM y').format(tour.endDate)}',
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Collected',
                                value: summary.totalCollected,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Spent',
                                value: summary.totalExpenses,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Cash left',
                                value: summary.availableCash,
                                color: summary.availableCash < 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      Text(
        _money(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _EmptyTours extends StatelessWidget {
  const _EmptyTours();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore_rounded, size: 58),
          SizedBox(height: 14),
          Text('No tours planned yet'),
          SizedBox(height: 6),
          Text(
            'Create a tour to manage collections, spending, and remaining cash.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Try again'),
    ),
  );
}

IconData _statusIcon(TourStatus status) => switch (status) {
  TourStatus.planned => Icons.event_available_outlined,
  TourStatus.active => Icons.flight_takeoff_rounded,
  TourStatus.completed => Icons.check_circle_outline_rounded,
  TourStatus.cancelled => Icons.cancel_outlined,
};

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
