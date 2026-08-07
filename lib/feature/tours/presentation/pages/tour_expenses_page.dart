import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_bloc.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_event.dart';
import 'package:runearn/feature/tours/presentation/bloc/tour_state.dart';
import 'package:runearn/feature/tours/presentation/widgets/tour_editors.dart';

class TourExpensesPage extends StatelessWidget {
  const TourExpensesPage({required this.tourId, super.key});
  final String tourId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: const AppBackButton(),
      title: const Text('Tour expenses'),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showTourExpenseEditor(context, tourId),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add expense'),
    ),
    body: BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        if (state is! TourLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = state.expenses
            .where((item) => item.tourId == tourId)
            .toList();
        if (items.isEmpty) {
          return const Center(child: Text('No tour expenses recorded yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${item.category} • ${DateFormat('d MMM y').format(item.date)}',
                ),
                trailing: Text(
                  _money(item.amount),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () =>
                    showTourExpenseEditor(context, tourId, expense: item),
                onLongPress: () => context.read<TourBloc>().add(
                  DeleteTourExpenseRequested(item.id),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

String _money(double value) =>
    NumberFormat.currency(symbol: '৳', decimalDigits: 2).format(value);
