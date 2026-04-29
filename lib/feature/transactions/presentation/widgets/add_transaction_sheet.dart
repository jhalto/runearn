import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/core/utils/category_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_category.dart';
import '../../domain/entities/transaction_type.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

void showAddTransactionSheet(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final bloc = context.read<TransactionBloc>();

  final amountController = TextEditingController();
  final descController = TextEditingController();

  TransactionType selectedType = TransactionType.expense;
  TransactionCategory selectedCategory = TransactionCategory.food;
  List<TransactionCategory> categories = CategoryHelper.getByType(selectedType);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter amount";
                        }
                        return null;
                      },
                    ),

                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text("Income"),
                            value: TransactionType.income,
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                                categories = CategoryHelper.getByType(
                                  selectedType,
                                );
                                selectedCategory = categories.first;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text("Expense"),
                            value: TransactionType.expense,
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                                categories = CategoryHelper.getByType(
                                  selectedType,
                                );
                                selectedCategory = categories.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // DropdownButtonFormField<TransactionCategory>(
                    //   value: categories.contains(selectedCategory)
                    //       ? selectedCategory
                    //       : null,
                    //   items: categories.map((e) {
                    //     return DropdownMenuItem(value: e, child: Text(e.name));
                    //   }).toList(),
                    //   onChanged: (value) {
                    //     setState(() {
                    //       selectedCategory = value!;
                    //     });
                    //   },
                    //   decoration: const InputDecoration(labelText: "Category"),
                    // ),
                    InkWell(
                      onTap: () {
                        _showCategoryPicker(
                          context,
                          categories,
                          selectedCategory,
                          (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        );
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(selectedCategory.name),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

                        final description = descController.text.trim().isEmpty
                            ? "No Description"
                            : descController.text.trim();

                        bloc.add(
                          AddTransactionEvent(
                            Transaction(
                              id: DateTime.now().toString(),
                              amount: double.parse(amountController.text),
                              type: selectedType,
                              category: selectedCategory,
                              description: description,
                              date: DateTime.now(),
                            ),
                          ),
                        );

                        Navigator.pop(context);
                      },
                      child: const Text("Add Transaction"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

void _showCategoryPicker(
  BuildContext context,
  List<TransactionCategory> categories,
  TransactionCategory selected,
  Function(TransactionCategory) onSelected,
) {
  final searchController = TextEditingController();
  List<TransactionCategory> filtered = List.from(categories);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Select Category",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    // 🔍 SEARCH
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search category...",
                      ),
                      onChanged: (value) {
                        setState(() {
                          filtered = categories
                              .where(
                                (e) => e.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .toList();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // 📋 LIST (NO FIXED HEIGHT)
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];

                          return ListTile(
                            title: Text(item.name),
                            trailing: item == selected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              onSelected(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}