import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_category.dart';
import 'package:runearn/feature/transactions/domain/entities/transaction_type.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:runearn/feature/transactions/presentation/bloc/transaction_event.dart';
import 'package:runearn/feature/transactions/presentation/widgets/transaction_from_body.dart';

void showEditTransactionSheet(
  BuildContext context,
  Transaction t,
) {
  final formKey = GlobalKey<FormState>();
  final bloc = context.read<TransactionBloc>();

  final amountController =
      TextEditingController(text: t.amount.toString());

  final descController =
      TextEditingController(text: t.description);

  TransactionType selectedType = t.type;
  TransactionCategory selectedCategory = t.category;
  DateTime selectedDate = t.date;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransactionFormBody(
                amountController: amountController,
                descController: descController,
                selectedType: selectedType,
                selectedCategory: selectedCategory,
                selectedDate: selectedDate,
                onTypeChanged: (v) => selectedType = v,
                onCategoryChanged: (v) => selectedCategory = v,
                onDateChanged: (v) => selectedDate = v,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  bloc.add(
                    UpdateTransactionEvent(
                      t.copyWith(
                        amount: double.parse(amountController.text),
                        type: selectedType,
                        category: selectedCategory,
                        description: descController.text,
                        date: selectedDate,
                      ),
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Update Transaction"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

