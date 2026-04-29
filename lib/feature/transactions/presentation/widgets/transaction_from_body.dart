import 'package:flutter/material.dart';
import 'package:runearn/core/utils/category_helper.dart';
import 'package:runearn/core/utils/date_picker_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_category.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionFormBody extends StatefulWidget {
  final TextEditingController amountController;
  final TextEditingController descController;
  final TransactionType selectedType;
  final TransactionCategory selectedCategory;
  final DateTime selectedDate;
  final Function(TransactionType) onTypeChanged;
  final Function(TransactionCategory) onCategoryChanged;
  final Function(DateTime) onDateChanged;

  const TransactionFormBody({
    super.key,
    required this.amountController,
    required this.descController,
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedDate,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onDateChanged,
  });

  @override
  State<TransactionFormBody> createState() => _TransactionFormBodyState();
}

class _TransactionFormBodyState extends State<TransactionFormBody> {
  late TransactionType selectedType;
  late TransactionCategory selectedCategory;
  late List<TransactionCategory> categories;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedType = widget.selectedType;
    selectedCategory = widget.selectedCategory;
    selectedDate = widget.selectedDate;
    categories = CategoryHelper.getByType(selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AMOUNT
        TextFormField(
          controller: widget.amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),

        // DESCRIPTION
        TextFormField(
          controller: widget.descController,
          decoration: const InputDecoration(labelText: "Description"),
        ),

        const SizedBox(height: 10),

        // TYPE
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
                    categories = CategoryHelper.getByType(selectedType);
                    selectedCategory = categories.first;
                    widget.onTypeChanged(selectedType);
                    widget.onCategoryChanged(selectedCategory);
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
                    categories = CategoryHelper.getByType(selectedType);
                    selectedCategory = categories.first;
                    widget.onTypeChanged(selectedType);
                    widget.onCategoryChanged(selectedCategory);
                  });
                },
              ),
            ),
          ],
        ),

        // CATEGORY
        InkWell(
          onTap: () {
            _showCategoryPicker(
              context,
              categories,
              selectedCategory,
              (value) {
                setState(() {
                  selectedCategory = value;
                  widget.onCategoryChanged(value);
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

        // DATE
        InkWell(
          onTap: () async {
            final picked = await DatePickerHelper.pickDate(
              context,
              initialDate: selectedDate,
            );

            if (picked != null) {
              setState(() {
                selectedDate = picked;
                widget.onDateChanged(picked);
              });
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Date",
              border: OutlineInputBorder(),
            ),
            child: Text(
              "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
            ),
          ),
        ),
      ],
    );
  }
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                                (e) => e.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ),
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
